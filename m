From: Xiubo Li <xiubo.li@clyso.com>
Date: Tue, 14 Jul 2026 16:13:43 +0800
Subject: [PATCH 1/2] ceph: fix UAF in __kick_flushing_caps() on cf entry
 freed during unlock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260714-ceph-uaf-fixes-v1-1-5c7603c181d5@clyso.com>
References: <20260714-ceph-uaf-fixes-v1-0-5c7603c181d5@clyso.com>
In-Reply-To: <20260714-ceph-uaf-fixes-v1-0-5c7603c181d5@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784016823; l=2921;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=tlJhoiuAEKQm//eDIvba9hTyNJLYASywp02PhL5yfYc=;
 b=a3toyJf6mIBd3CkBovwuabNbbtDjqEROsqRM3iqQhrEUj/ZEDRKPQC+YF+9dBTrTsrl/qPLLL
 FUj/df/BwHKBUhI7wFEhj5kX9FWUCWi/aSs7VdgMUQUlGe2j9ymX2DR
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

list_for_each_entry() iterates ci->i_cap_flush_list but drops
i_ceph_lock to send cap messages.  During the unlock window,
handle_cap_flush_ack() can acquire i_ceph_lock, detach cf entries
with tid <= flush_tid from the list, release i_ceph_lock, and free
them via ceph_free_cap_flush() outside any lock.  When the original
thread reacquires i_ceph_lock and the for-loop macro advances via
cf = list_next_entry(cf, i_list), it dereferences cf->i_list.next
on freed memory.

The race timeline:

  __kick_flushing_caps()              handle_cap_flush_ack()
  -----------------------             -----------------------
  holds i_ceph_lock        <---
  iterates to cf (tid=10)
  prepares FLUSH message
  drops i_ceph_lock        <---
  __send_cap() ── FLUSH(tid=10)
	                              MDS sends FLUSH_ACK(tid=10)
                           --->       acquires i_ceph_lock
                                      cf->tid(10) <= flush_tid(10),
                                      detaches cf from i_cap_flush_list
                                      drops i_ceph_lock
                                      ceph_free_cap_flush(cf) <- frees it!
  acquires i_ceph_lock     <---
  for-loop advances:
    cf = list_next_entry(cf, i_list)
      -- UAF on freed cf->i_list.next

The cf was just sent by __kick_flushing_caps itself via __send_cap().
The MDS may respond with FLUSH_ACK quickly enough that
handle_cap_flush_ack() frees cf before __kick_flushing_caps can
finish the iteration.

Fix by converting to a manual while loop: save the next pointer
under i_ceph_lock before dropping it, then use the saved pointer
after reacquiring, so the potentially-freed cf is never accessed again.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/caps.c | 11 +++++++++--
 1 file changed, 9 insertions(+), 2 deletions(-)

diff --git a/fs/ceph/caps.c b/fs/ceph/caps.c
index f8d898ad091e..358ee4f14524 100644
--- a/fs/ceph/caps.c
+++ b/fs/ceph/caps.c
@@ -2626,9 +2626,14 @@ static void __kick_flushing_caps(struct ceph_mds_client *mdsc,
 		}
 	}
 
-	list_for_each_entry(cf, &ci->i_cap_flush_list, i_list) {
-		if (cf->tid < first_tid)
+	cf = list_first_entry(&ci->i_cap_flush_list, struct ceph_cap_flush, i_list);
+	while (&cf->i_list != &ci->i_cap_flush_list) {
+		struct ceph_cap_flush *next;
+
+		if (cf->tid < first_tid) {
+			cf = list_next_entry(cf, i_list);
 			continue;
+		}
 
 		cap = ci->i_auth_cap;
 		if (!(cap && cap->session == session)) {
@@ -2638,6 +2643,7 @@ static void __kick_flushing_caps(struct ceph_mds_client *mdsc,
 		}
 
 		first_tid = cf->tid + 1;
+		next = list_next_entry(cf, i_list);
 
 		if (!cf->is_capsnap) {
 			struct cap_msg_args arg;
@@ -2678,6 +2684,7 @@ static void __kick_flushing_caps(struct ceph_mds_client *mdsc,
 		}
 
 		spin_lock(&ci->i_ceph_lock);
+		cf = next;
 	}
 }
 

-- 
2.53.0

