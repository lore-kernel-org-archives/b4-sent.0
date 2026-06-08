From: Bernd Schubert <bernd@bsbernd.com>
Date: Mon, 08 Jun 2026 23:03:43 +0200
Subject: [PATCH v4 1/4] fuse: Avoid use-after-free in
 fuse_uring_async_stop_queues
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260608-fuse-io-uring-race-fixes-v4-1-fa410089a0a1@bsbernd.com>
References: <20260608-fuse-io-uring-race-fixes-v4-0-fa410089a0a1@bsbernd.com>
In-Reply-To: <20260608-fuse-io-uring-race-fixes-v4-0-fa410089a0a1@bsbernd.com>
To: fuse-devel@lists.linux.dev, Pavel Begunkov <asml.silence@gmail.com>, 
 Luis Henriques <luis@igalia.com>, Joanne Koong <joannelkoong@gmail.com>
Cc: Miklos Szeredi <mszeredi@redhat.com>, Berkant Koc <me@berkoc.com>, 
 Zhenghang Xiao <kipreyyy@gmail.com>, Bernd Schubert <bernd@bsbernd.com>, 
 stable@kernel.org
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=1359; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=fClfSeFNZbN84Rlj6vwX+jm39G5aYdFCQYhhYlWFOCk=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLLU9YyXq777uvVfPrsNB1f4IZPwMAnHfs78fCZW2bh3W
 hcOlBV3lLIwiHEwyIopsnRJ7LGd8o9PVu3r+uswc1iZQIYwcHEKwESKMhgZ2lTuq0Vz79v9LeP5
 lxmhd/nrPTmnbFDxmXz73ZSzPc93XmNkWPyXxSqy/Wh2/8ZbejcZxSKSn8/dvn/H7PJuSYtiPZE
 JPAA=
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

fuse_uring_async_stop_queues() might run when the last reference
on ring->queue_refs was already dropped.

In order to avoid an early destruction a reference on struct fuse_conn
is now taken before starting fuse_uring_async_stop_queues() and that
reference is only released when that delayed work queue terminates.

Fixes: 4a9bfb9b6850 ("fuse: {io-uring} Handle teardown of ring entries")
Cc: stable@kernel.org # 6.14
Reported-by: Berkant Koc <me@berkoc.com>
Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
Reviewed-by: Joanne Koong <joannelkoong@gmail.com>
---
 fs/fuse/dev_uring.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index e467b23e6895..d658ef6877a4 100644
--- a/fs/fuse/dev_uring.c
+++ b/fs/fuse/dev_uring.c
@@ -466,6 +466,7 @@ static void fuse_uring_async_stop_queues(struct work_struct *work)
 				      FUSE_URING_TEARDOWN_INTERVAL);
 	} else {
 		wake_up_all(&ring->stop_waitq);
+		fuse_conn_put(ring->chan->conn);
 	}
 }
 
@@ -477,6 +478,7 @@ void fuse_uring_stop_queues(struct fuse_ring *ring)
 	fuse_uring_teardown_all_queues(ring);
 
 	if (atomic_read(&ring->queue_refs) > 0) {
+		fuse_conn_get(ring->chan->conn);
 		ring->teardown_time = jiffies;
 		INIT_DELAYED_WORK(&ring->async_teardown_work,
 				  fuse_uring_async_stop_queues);

-- 
2.53.0

