From: Xiubo Li <xiubo.li@clyso.com>
Date: Fri, 27 Nov 2026 10:14:56 +0100
Subject: [PATCH] libceph: re-target OSD requests on PG merges
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261127-libceph-pg-merge-retarget-v1-1-2427758cdd1c@clyso.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWM0QrCMBAEf6XcswfJgUb9FfGhTbftidZwSUUo/
 XejPi3DMrNShikynZuVDC/N+pwr+F1DcWrnEax9ZRInB+8l8F27iDRxGvkBq7+htHULh/3p6MQ
 NoRdQ9ZNh0Pevfbn+OS/dDbF8g7RtH/2TqJl9AAAA
X-Change-ID: 20261127-libceph-pg-merge-retarget-7598020f7d2e
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: =?utf-8?q?Niclas_M=C3=BCller?= <n.mueller@mueller-it.de>, 
 ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795770898; l=7315;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=Zado0TAGrUK3dd3ptM/7zluOKnbbQeVWAwqIQJArbzQ=;
 b=2yIneOIi09i31RVhpoWGU9jt4sbVo/gZAE5X8/UvhOs2icbE+g7wuQr6JKl3O+YWyw9AI5rwQ
 0jaC4HgyYf7CQdm/5Vl8YG2bnYf5zaaQEk03hv4digM9UhsmiLLNk63
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

calc_target() only recomputes t->spgid for a regular request when the
primary changes, when the epoch being processed is the pool's
last_force_request_resend epoch, or when the request's PG is split.
A PG merge (pg_num decrease) is not detected at all:
ceph_pg_is_split() returns false when the new pg_num is not larger,
and ceph_is_new_interval(), which compares pg_num, is only evaluated
for linger requests.

The monitor bumps last_force_op_resend_prenautilus, which is what the
client decodes into last_force_request_resend, on every merge step, so
most of the time force_resend covers the merge.  But it only fires on
that exact epoch, and it is easily lost:

- When one MOSDMap carries several incrementals, a request that is
  re-targeted on an earlier epoch is moved to need_resend and is not
  scanned again for the later epochs of the same message.
  kick_requests() then calls calc_target() once more against the
  newest map, which is past the force resend epoch of the last merge
  step, so the merge goes unnoticed.

- A client that falls far behind, e.g. an idle mount, may get a full
  map and never process the force resend epoch at all.

If the merge target has the same primary as the merged-away source
PG, the request keeps the spgid of a PG that no longer exists.  The
OSD drops such ops, as it expects the client to resend them to the
merge target, and the request is resent to the same OSD with the same
stale spgid forever:

  REQUESTS 3 homeless 0
  260  osd1  4.173fada4  4.24  [1,2,0]/1  [1,2,0]/1  e451
       10000000231.00000000  0x40001c  12  read

while pool 4 has pg_num 32 and 4.24 has been merged into 4.4.  This is
easy to hit with a mount that stays idle while pg_num goes from 128 to
32, and then reads.

Do what the userspace Objecter has been doing since the merge support
was added: treat the request's PG being a merge source or a merge
target like a split, recompute the target and resend.  Also count
merges as a new interval in ceph_is_new_interval(), matching
PastIntervals::is_new_interval().

Cc: stable@vger.kernel.org
Fixes: 7de030d6b10a ("libceph: resend on PG splits if OSD has RESEND_ON_SPLIT")
Reported-by: Niclas Müller <n.mueller@mueller-it.de>
Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
A kernel client never re-targets an in-flight OSD request after a PG
merge if the merge target has the same primary, so the request is
resent forever to a PG that no longer exists and the read hangs.

Reproduced on a vstart cluster with a mount left idle while the data
pool went from 128 to 32 PGs: before the patch 2-3 of 200 reads hang
(both when the client applies every incremental map and when it jumps
to a full map), after it 200/200 complete.
---
 include/linux/ceph/osdmap.h |  4 ++++
 net/ceph/osd_client.c       | 13 ++++++++-----
 net/ceph/osdmap.c           | 24 ++++++++++++++++++++++++
 3 files changed, 36 insertions(+), 5 deletions(-)

diff --git a/include/linux/ceph/osdmap.h b/include/linux/ceph/osdmap.h
index 5553019c3f07..0644a410b4c0 100644
--- a/include/linux/ceph/osdmap.h
+++ b/include/linux/ceph/osdmap.h
@@ -272,6 +272,10 @@ void ceph_osds_copy(struct ceph_osds *dest, const struct ceph_osds *src);
 
 bool ceph_pg_is_split(const struct ceph_pg *pgid, u32 old_pg_num,
 		      u32 new_pg_num);
+bool ceph_pg_is_merge_source(const struct ceph_pg *pgid, u32 old_pg_num,
+			     u32 new_pg_num);
+bool ceph_pg_is_merge_target(const struct ceph_pg *pgid, u32 old_pg_num,
+			     u32 new_pg_num);
 bool ceph_is_new_interval(const struct ceph_osds *old_acting,
 			  const struct ceph_osds *new_acting,
 			  const struct ceph_osds *old_up,
diff --git a/net/ceph/osd_client.c b/net/ceph/osd_client.c
index 22a793a4bdc8..3adb9e6394eb 100644
--- a/net/ceph/osd_client.c
+++ b/net/ceph/osd_client.c
@@ -1595,7 +1595,7 @@ static enum calc_target_result calc_target(struct ceph_osd_client *osdc,
 	bool force_resend = false;
 	bool unpaused = false;
 	bool legacy_change = false;
-	bool split = false;
+	bool split_or_merge = false;
 	bool sort_bitwise = ceph_osdmap_flag(osdc, CEPH_OSDMAP_SORTBITWISE);
 	bool recovery_deletes = ceph_osdmap_flag(osdc,
 						 CEPH_OSDMAP_RECOVERY_DELETES);
@@ -1672,9 +1672,12 @@ static enum calc_target_result calc_target(struct ceph_osd_client *osdc,
 			ceph_osds_changed(&t->acting, &acting,
 					  t->used_replica || any_change);
 	if (t->pg_num)
-		split = ceph_pg_is_split(&last_pgid, t->pg_num, pi->pg_num);
+		split_or_merge =
+		    ceph_pg_is_split(&last_pgid, t->pg_num, pi->pg_num) ||
+		    ceph_pg_is_merge_source(&last_pgid, t->pg_num, pi->pg_num) ||
+		    ceph_pg_is_merge_target(&last_pgid, t->pg_num, pi->pg_num);
 
-	if (legacy_change || force_resend || split) {
+	if (legacy_change || force_resend || split_or_merge) {
 		t->pgid = pgid; /* struct */
 		ceph_pg_to_primary_shard(osdc->osdmap, pi, &pgid, &t->spgid);
 		ceph_osds_copy(&t->acting, &acting);
@@ -1706,14 +1709,14 @@ static enum calc_target_result calc_target(struct ceph_osd_client *osdc,
 		}
 	}
 
-	if (unpaused || legacy_change || force_resend || split)
+	if (unpaused || legacy_change || force_resend || split_or_merge)
 		ct_res = CALC_TARGET_NEED_RESEND;
 	else
 		ct_res = CALC_TARGET_NO_ACTION;
 
 out:
 	dout("%s t %p -> %d%d%d%d ct_res %d osd%d\n", __func__, t, unpaused,
-	     legacy_change, force_resend, split, ct_res, t->osd);
+	     legacy_change, force_resend, split_or_merge, ct_res, t->osd);
 	return ct_res;
 }
 
diff --git a/net/ceph/osdmap.c b/net/ceph/osdmap.c
index a946724d4ef7..0d418af9c5f6 100644
--- a/net/ceph/osdmap.c
+++ b/net/ceph/osdmap.c
@@ -2358,6 +2358,28 @@ bool ceph_pg_is_split(const struct ceph_pg *pgid, u32 old_pg_num,
 	return false;
 }
 
+/*
+ * Returns true if @pgid is a merge source going from @old_pg_num to
+ * @new_pg_num, i.e. it doesn't exist anymore and its objects now live
+ * in one of its ancestors.
+ */
+bool ceph_pg_is_merge_source(const struct ceph_pg *pgid, u32 old_pg_num,
+			     u32 new_pg_num)
+{
+	return pgid->seed < old_pg_num && pgid->seed >= new_pg_num;
+}
+
+/*
+ * Returns true if @pgid is a merge target going from @old_pg_num to
+ * @new_pg_num, i.e. one or more of its children were merged into it.
+ */
+bool ceph_pg_is_merge_target(const struct ceph_pg *pgid, u32 old_pg_num,
+			     u32 new_pg_num)
+{
+	return pgid->seed < new_pg_num &&
+	       ceph_pg_is_split(pgid, new_pg_num, old_pg_num);
+}
+
 bool ceph_is_new_interval(const struct ceph_osds *old_acting,
 			  const struct ceph_osds *new_acting,
 			  const struct ceph_osds *old_up,
@@ -2379,6 +2401,8 @@ bool ceph_is_new_interval(const struct ceph_osds *old_acting,
 	       old_size != new_size ||
 	       old_min_size != new_min_size ||
 	       ceph_pg_is_split(pgid, old_pg_num, new_pg_num) ||
+	       ceph_pg_is_merge_source(pgid, old_pg_num, new_pg_num) ||
+	       ceph_pg_is_merge_target(pgid, old_pg_num, new_pg_num) ||
 	       old_sort_bitwise != new_sort_bitwise ||
 	       old_recovery_deletes != new_recovery_deletes;
 }

---
base-commit: 3f90412e989cb381d4bf96260468f5c7b2d08655
change-id: 20261127-libceph-pg-merge-retarget-7598020f7d2e

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

