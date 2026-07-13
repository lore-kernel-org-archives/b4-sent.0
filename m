From: Xiubo Li <xiubo.li@clyso.com>
Date: Mon, 13 Jul 2026 17:46:11 +0800
Subject: [PATCH 5/5] ceph: narrow mdsc->mutex scope in
 replay_unsafe_requests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260713-ceph-mdsc-mutex-optimization-v1-5-9ae5ac135c34@clyso.com>
References: <20260713-ceph-mdsc-mutex-optimization-v1-0-9ae5ac135c34@clyso.com>
In-Reply-To: <20260713-ceph-mdsc-mutex-optimization-v1-0-9ae5ac135c34@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783936018; l=1786;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=Sl0B6kcMz6zymOkZ4jEEs/Wx0+iGbBxBQZu85Is5ZhM=;
 b=eB7ysIYOWFeALC2JWW2za+3YIQIvxnyN7J24eSXDLed8j+2xYBOGtjjT0pUbRqjT14oqmBoZn
 IVZwxMEuHRUApPT1pqHUVclVKxwNbNJPg9rqcA+QT1Z/mILKfNh5CJq
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__send_request() is lockless so holding mdsc->mutex across the
replay loop only serializes the list iteration itself.  Collect
the unsafe list entries under the mutex, then replay them without
it.  The old-request tree walk uses xa_for_each() which is
internally locked.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/mds_client.c | 16 ++++++++++++++--
 1 file changed, 14 insertions(+), 2 deletions(-)

diff --git a/fs/ceph/mds_client.c b/fs/ceph/mds_client.c
index ef54d19ace2a..6c5a8c651d3e 100644
--- a/fs/ceph/mds_client.c
+++ b/fs/ceph/mds_client.c
@@ -4673,12 +4673,25 @@ static void replay_unsafe_requests(struct ceph_mds_client *mdsc,
 {
 	struct ceph_mds_request *req, *nreq;
 	unsigned long idx;
+	LIST_HEAD(replay_list);
 
 	doutc(mdsc->fsc->client, "mds%d\n", session->s_mds);
 
+	/* collect unsafe requests under the mutex */
 	mutex_lock(&mdsc->mutex);
-	list_for_each_entry_safe(req, nreq, &session->s_unsafe, r_unsafe_item)
+	list_for_each_entry_safe(req, nreq, &session->s_unsafe,
+				 r_unsafe_item) {
+		ceph_mdsc_get_request(req);
+		list_move(&req->r_unsafe_item, &replay_list);
+	}
+	mutex_unlock(&mdsc->mutex);
+
+	/* replay unsafe requests — __send_request is lockless */
+	list_for_each_entry_safe(req, nreq, &replay_list, r_unsafe_item) {
 		__send_request(session, req, true);
+		list_del_init(&req->r_unsafe_item);
+		ceph_mdsc_put_request(req);
+	}
 
 	/*
 	 * also re-send old requests when MDS enters reconnect stage. So that MDS
@@ -4699,7 +4712,6 @@ static void replay_unsafe_requests(struct ceph_mds_client *mdsc,
 
 		__send_request(session, req, true);
 	}
-	mutex_unlock(&mdsc->mutex);
 }
 
 static int send_reconnect_partial(struct ceph_reconnect_state *recon_state)

-- 
2.53.0

