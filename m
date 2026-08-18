From: Xiubo Li <xiubo.li@clyso.com>
Date: Tue, 18 Aug 2026 03:58:12 -0700
Subject: [PATCH v5 5/5] ceph: narrow mdsc->mutex scope in
 replay_unsafe_requests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260818-ceph-mdsc-mutex-optimization-v5-5-7d335a3a1d0b@clyso.com>
References: <20260818-ceph-mdsc-mutex-optimization-v5-0-7d335a3a1d0b@clyso.com>
In-Reply-To: <20260818-ceph-mdsc-mutex-optimization-v5-0-7d335a3a1d0b@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787050693; l=3299;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=009BuODFeGOWGowR2RIFqNz08B1zIvCBUcUg2e3fczI=;
 b=AkP0sUdKpopnSZb06tylp8FhPUG8APSbnzUbaOI6jBqdKO0+qUZUcXXEagY5QcVq2cu/T+Ps4
 ff5lUMYPfQ6AQ8wNRjfU3GPlUUsrS+Uau2v10a+OxuPTXOFvuAc/gFM
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently replay_unsafe_requests() holds mdsc->mutex across the
entire function, including the __send_request() calls.  Since
__send_request() is lockless and the async cap-release helper
schedules deferred work, neither needs the mutex.

Collect the unsafe-list entries and the matching old xarray
entries into local lists under mdsc->mutex, taking a reference on
each, then replay them outside the mutex.  Taking a reference
ensures a concurrent reply handler can complete and unregister a
request without invalidating the local list or the iterator.

Unsafe requests remain on session->s_unsafe; r_aux_item serves
only as a walk-list link.  This keeps them tracked as unsafe
until the MDS replies, so a later reconnect can replay them again
and cleanup_session_requests() can still abort them on session
teardown.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/mds_client.c | 42 +++++++++++++++++++++++++++++++++++++-----
 1 file changed, 37 insertions(+), 5 deletions(-)

diff --git a/fs/ceph/mds_client.c b/fs/ceph/mds_client.c
index c624f80aa5fd..5310bb27b353 100644
--- a/fs/ceph/mds_client.c
+++ b/fs/ceph/mds_client.c
@@ -4732,13 +4732,30 @@ static void replay_unsafe_requests(struct ceph_mds_client *mdsc,
 {
 	struct ceph_mds_request *req, *nreq;
 	unsigned long idx;
+	LIST_HEAD(unsafe_list);
+	LIST_HEAD(old_list);
 
 	doutc(mdsc->fsc->client, "mds%d\n", session->s_mds);
 
+	/*
+	 * Collect unsafe and old requests under mdsc->mutex, then
+	 * replay them without it: __send_request() is lockless and
+	 * ceph_mdsc_release_dir_caps_async() schedules work.
+	 */
 	mutex_lock(&mdsc->mutex);
-	list_for_each_entry_safe(req, nreq, &session->s_unsafe, r_unsafe_item)
+	list_for_each_entry_safe(req, nreq, &session->s_unsafe,
+				 r_unsafe_item) {
+		ceph_mdsc_get_request(req);
 		req->r_attempts++;
-		__send_request(session, req, true);
+		/*
+		 * Keep the request on s_unsafe: r_aux_item is only a
+		 * walk list.  The request must stay tracked as unsafe
+		 * until the MDS replies, so that a later reconnect can
+		 * replay it again and cleanup_session_requests() can
+		 * still abort it on session teardown.
+		 */
+		list_add_tail(&req->r_aux_item, &unsafe_list);
+	}
 
 	/*
 	 * also re-send old requests when MDS enters reconnect stage. So that MDS
@@ -4755,12 +4772,27 @@ static void replay_unsafe_requests(struct ceph_mds_client *mdsc,
 		if (req->r_session->s_mds != session->s_mds)
 			continue;
 
-		ceph_mdsc_release_dir_caps_async(req);
-
+		ceph_mdsc_get_request(req);
 		req->r_attempts++;
-		__send_request(session, req, true);
+		list_add_tail(&req->r_aux_item, &old_list);
 	}
+
 	mutex_unlock(&mdsc->mutex);
+
+	/* replay unsafe requests */
+	list_for_each_entry_safe(req, nreq, &unsafe_list, r_aux_item) {
+		list_del_init(&req->r_aux_item);
+		__send_request(session, req, true);
+		ceph_mdsc_put_request(req);
+	}
+
+	/* replay old requests */
+	list_for_each_entry_safe(req, nreq, &old_list, r_aux_item) {
+		list_del_init(&req->r_aux_item);
+		ceph_mdsc_release_dir_caps_async(req);
+		__send_request(session, req, true);
+		ceph_mdsc_put_request(req);
+	}
 }
 
 static int send_reconnect_partial(struct ceph_reconnect_state *recon_state)

-- 
2.53.0

