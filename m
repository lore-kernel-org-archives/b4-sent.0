From: Xiubo Li <xiubo.li@clyso.com>
Date: Thu, 08 Oct 2026 03:28:02 +0200
Subject: [PATCH] ceph: check the caps of a closed file after
 caps_wanted_delay_min
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261008-ceph-cap-idle-release-v1-1-86e7a8bf36d0@clyso.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM0QqCQBCF4VeRuW5glcjoVcSLcTybE2LLTkogv
 ntbXX4Hzr+TIxucbtVOGZu5PZeC+lSRTrLcwTYWUxOaSx3ClRVpYpVU9hmcMUMcLGOM57aNqgI
 q35QR7f3rdv3fvg4P6Osbo+P4ACg/dn95AAAA
X-Change-ID: 20261008-ceph-cap-idle-release-adff477fccae
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791422960; l=9360;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=OclocnO6rE4KxWh+A36R6LcdaImZDTRAwTsJ6wxrIfc=;
 b=nEN2CbtzibM0U71oKuytrfYFNCuRvwdWj1ZxLT6YnFFctRMuyjLSzO/OM/XtrgNdB0DkdUz9e
 SLxXlgiwPLLBSNwbB05rSb9EftWKIgyiCSnLDpFSVlztDVb4e0393ZW
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__ceph_caps_file_wanted() stops wanting the caps of a closed file once
its last read or write is caps_wanted_delay_min (5s) old, but nothing
checks its caps again before caps_wanted_delay_max (60s): closing does
not call ceph_check_caps(), and the inode waits on cap_delay_list,
whose check has always come at caps_wanted_delay_max.

Meanwhile the MDS keeps us the loner, so each stat from another client
of a file we created first waits for the MDS to revoke our exclusive
caps.  This is what makes mdtest-easy-stat in IO500 on kernel clients
swing between 3.6k and 100k stats/s from run to run.

Queue a regular file that still holds exclusive or write caps for a cap
check caps_wanted_delay_min after its last close, on a list of its own,
as cap_delay_list is in caps_wanted_delay_max order.  The check gives
back what it already gives back at caps_wanted_delay_max (shared caps
and the page cache caps stay), only earlier.  Directories and open
files are not affected.

Two noshare kernel mounts on one VM, 1 MDS: 20000 empty files created
on A, statted by path on B after a wait.  Caps messages are the ones A
sends, revokes are the ones the MDS sends A:

  +--------+------+---------------+---------------+---------------+
  |        |      | in the wait   | in the stat                   |
  | kernel | wait | caps msgs     | stats/s       | revokes       |
  +--------+------+---------------+---------------+---------------+
  | before |  15s |             0 |     374 - 435 | 11164 - 11730 |
  | after  |  15s |         20000 | 18680 - 24027 |             0 |
  | before |   3s |             0 |     328 - 342 | 13727 - 14538 |
  | after  |   3s |      0 - 3010 |   2238 - 3216 |     963 - 996 |
  +--------+------+---------------+---------------+---------------+

The caps go back in the background before the stat instead of one
revoke per file during it; with a 3s wait most of them still go back
while the stat runs.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
Tested on 7.2 against a vstart cluster with two noshare kernel mounts,
see the numbers in the commit message.  The same stall shows up in the
IO500 mdtest-easy-stat phase on kernel clients.
---
 fs/ceph/caps.c       | 95 ++++++++++++++++++++++++++++++++++++++++++++++------
 fs/ceph/mds_client.c |  2 ++
 fs/ceph/mds_client.h |  3 +-
 3 files changed, 88 insertions(+), 12 deletions(-)

diff --git a/fs/ceph/caps.c b/fs/ceph/caps.c
index 8e582cbcfc6b..b1e29e92920f 100644
--- a/fs/ceph/caps.c
+++ b/fs/ceph/caps.c
@@ -537,6 +537,42 @@ static void __cap_delay_requeue(struct ceph_mds_client *mdsc,
 	}
 }
 
+/*
+ * Queue the inode of a file that was just closed for a cap check
+ * caps_wanted_delay_min seconds from now, when __ceph_caps_file_wanted()
+ * stops wanting the caps it was opened for.  These inodes go on a list of
+ * their own, as cap_delay_list is in caps_wanted_delay_max order.
+ *
+ * Caller holds i_ceph_lock
+ *    -> we take mdsc->cap_delay_lock
+ */
+static void __cap_delay_requeue_idle(struct ceph_mds_client *mdsc,
+				     struct ceph_inode_info *ci)
+{
+	struct inode *inode = &ci->netfs.inode;
+	struct ceph_mount_options *opt = mdsc->fsc->mount_options;
+
+	if (mdsc->stopping)
+		return;
+	spin_lock(&mdsc->cap_delay_lock);
+	if (!list_empty(&ci->i_cap_delay_list)) {
+		if (ci->i_ceph_flags & CEPH_I_FLUSH)
+			goto no_change;
+		list_del_init(&ci->i_cap_delay_list);
+	}
+	/*
+	 * Round up, so that the check does not come before the last
+	 * read or write is caps_wanted_delay_min seconds old.
+	 */
+	ci->i_hold_caps_max = round_jiffies_up(jiffies +
+					       opt->caps_wanted_delay_min * HZ);
+	doutc(mdsc->fsc->client, "%p %llx.%llx at %lu\n", inode,
+	      ceph_vinop(inode), ci->i_hold_caps_max);
+	list_add_tail(&ci->i_cap_delay_list, &mdsc->cap_idle_delay_list);
+no_change:
+	spin_unlock(&mdsc->cap_delay_lock);
+}
+
 /*
  * Queue an inode for immediate writeback.  Mark inode with I_FLUSH,
  * indicating we should send a cap message to flush dirty metadata
@@ -4720,29 +4756,28 @@ void ceph_handle_caps(struct ceph_mds_session *session,
 }
 
 /*
- * Delayed work handler to process end of delayed cap release LRU list.
+ * Process the expired end of one delayed cap list, whose entries were
+ * queued @hold jiffies before they expire.
  *
  * If new caps are added to the list while processing it, these won't get
  * processed in this run.  In this case, the ci->i_hold_caps_max will be
  * returned so that the work can be scheduled accordingly.
  */
-unsigned long ceph_check_delayed_caps(struct ceph_mds_client *mdsc)
+static unsigned long check_delayed_caps_list(struct ceph_mds_client *mdsc,
+					     struct list_head *list,
+					     unsigned long hold,
+					     unsigned long loop_start)
 {
 	struct ceph_client *cl = mdsc->fsc->client;
 	struct inode *inode;
 	struct ceph_inode_info *ci;
-	struct ceph_mount_options *opt = mdsc->fsc->mount_options;
-	unsigned long delay_max = opt->caps_wanted_delay_max * HZ;
-	unsigned long loop_start = jiffies;
 	unsigned long delay = 0;
 
-	doutc(cl, "begin\n");
 	spin_lock(&mdsc->cap_delay_lock);
-	while (!list_empty(&mdsc->cap_delay_list)) {
-		ci = list_first_entry(&mdsc->cap_delay_list,
-				      struct ceph_inode_info,
+	while (!list_empty(list)) {
+		ci = list_first_entry(list, struct ceph_inode_info,
 				      i_cap_delay_list);
-		if (time_before(loop_start, ci->i_hold_caps_max - delay_max)) {
+		if (time_before(loop_start, ci->i_hold_caps_max - hold)) {
 			doutc(cl, "caps added recently.  Exiting loop");
 			delay = ci->i_hold_caps_max;
 			break;
@@ -4771,8 +4806,33 @@ unsigned long ceph_check_delayed_caps(struct ceph_mds_client *mdsc)
 			break;
 	}
 	spin_unlock(&mdsc->cap_delay_lock);
+
+	return delay;
+}
+
+/*
+ * Delayed work handler to process end of delayed cap release LRU lists:
+ * the closed files waiting for caps_wanted_delay_min, then the inodes
+ * waiting for caps_wanted_delay_max.
+ */
+unsigned long ceph_check_delayed_caps(struct ceph_mds_client *mdsc)
+{
+	struct ceph_client *cl = mdsc->fsc->client;
+	struct ceph_mount_options *opt = mdsc->fsc->mount_options;
+	unsigned long loop_start = jiffies;
+	unsigned long delay, idle_delay;
+
+	doutc(cl, "begin\n");
+	idle_delay = check_delayed_caps_list(mdsc, &mdsc->cap_idle_delay_list,
+					     opt->caps_wanted_delay_min * HZ,
+					     loop_start);
+	delay = check_delayed_caps_list(mdsc, &mdsc->cap_delay_list,
+					opt->caps_wanted_delay_max * HZ,
+					loop_start);
 	doutc(cl, "done\n");
 
+	if (idle_delay && (!delay || time_before(idle_delay, delay)))
+		delay = idle_delay;
 	return delay;
 }
 
@@ -4906,8 +4966,21 @@ void ceph_put_fmode(struct ceph_inode_info *ci, int fmode, int count)
 			is_closed = false;
 	}
 
-	if (is_closed)
+	if (is_closed) {
 		percpu_counter_dec(&mdsc->metric.opened_inodes);
+		/*
+		 * A closed file stops wanting its caps once its last read
+		 * or write is caps_wanted_delay_min old, but nothing checks
+		 * its caps again before caps_wanted_delay_max runs out.
+		 * Until then the MDS keeps it the loner and has to revoke
+		 * the exclusive caps from us first when another client
+		 * looks at the file, e.g. stats a file we just created.
+		 * Check again after caps_wanted_delay_min instead.
+		 */
+		if (S_ISREG(ci->netfs.inode.i_mode) &&
+		    (__ceph_caps_issued(ci, NULL) & CEPH_CAP_ANY_WR))
+			__cap_delay_requeue_idle(mdsc, ci);
+	}
 	spin_unlock(&ci->i_ceph_lock);
 }
 
diff --git a/fs/ceph/mds_client.c b/fs/ceph/mds_client.c
index baa9e4ad38c5..a1feae6bd9b6 100644
--- a/fs/ceph/mds_client.c
+++ b/fs/ceph/mds_client.c
@@ -6406,6 +6406,7 @@ int ceph_mdsc_init(struct ceph_fs_client *fsc)
 	INIT_DELAYED_WORK(&mdsc->delayed_work, delayed_work);
 	mdsc->last_renew_caps = jiffies;
 	INIT_LIST_HEAD(&mdsc->cap_delay_list);
+	INIT_LIST_HEAD(&mdsc->cap_idle_delay_list);
 #ifdef CONFIG_DEBUG_FS
 	INIT_LIST_HEAD(&mdsc->cap_wait_list);
 #endif
@@ -6879,6 +6880,7 @@ void ceph_mdsc_close_sessions(struct ceph_mds_client *mdsc)
 		}
 	}
 	WARN_ON(!list_empty(&mdsc->cap_delay_list));
+	WARN_ON(!list_empty(&mdsc->cap_idle_delay_list));
 	mutex_unlock(&mdsc->mutex);
 
 	ceph_cleanup_snapid_map(mdsc);
diff --git a/fs/ceph/mds_client.h b/fs/ceph/mds_client.h
index d4d620fb8417..863cdb8d588a 100644
--- a/fs/ceph/mds_client.h
+++ b/fs/ceph/mds_client.h
@@ -540,8 +540,9 @@ struct ceph_mds_client {
 	struct delayed_work    delayed_work;  /* delayed work */
 	unsigned long    last_renew_caps;  /* last time we renewed our caps */
 	struct list_head cap_delay_list;   /* caps with delayed release */
+	struct list_head cap_idle_delay_list;  /* caps of closed files */
 	struct list_head cap_unlink_delay_list;  /* caps with delayed release for unlink */
-	spinlock_t       cap_delay_lock;   /* protects cap_delay_list and cap_unlink_delay_list */
+	spinlock_t       cap_delay_lock;   /* protects the three lists above */
 	struct list_head snap_flush_list;  /* cap_snaps ready to flush */
 	spinlock_t       snap_flush_lock;
 

---
base-commit: c3112e7db4e561edeba02de2dca0ca620e44e84b
change-id: 20261008-ceph-cap-idle-release-adff477fccae

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

