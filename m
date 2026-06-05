From: Bernd Schubert <bernd@bsbernd.com>
Date: Sat, 06 Jun 2026 00:13:06 +0200
Subject: [PATCH RESEND v3 1/4] fuse: Avoid use-after-free in
 fuse_uring_async_stop_queues
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260606-fuse-io-uring-race-fixes-v3-1-6fdf5e5b3437@bsbernd.com>
References: <20260606-fuse-io-uring-race-fixes-v3-0-6fdf5e5b3437@bsbernd.com>
In-Reply-To: <20260606-fuse-io-uring-race-fixes-v3-0-6fdf5e5b3437@bsbernd.com>
To: Pavel Begunkov <asml.silence@gmail.com>, 
 Luis Henriques <luis@igalia.com>, Joanne Koong <joannelkoong@gmail.com>, 
 fuse-devel@lists.linux.dev
Cc: Miklos Szeredi <mszeredi@redhat.com>, Berkant Koc <me@berkoc.com>, 
 Zhenghang Xiao <kipreyyy@gmail.com>, Bernd Schubert <bernd@bsbernd.com>, 
 stable@kernel.org
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=1442; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=X2I4I+6k4VRNTubfnToFcPaR3hqdHMhFlXLJDCyP2XY=;
 b=kA0DAAgWMvNp7peNQvwByyZiAGojSf7IAbUqifyXmN2ExQoiAsoBRSmBOowCh3B3/B4GUzghN
 oh1BAAWCAAdFiEEihi8PZT+Dh0m9a/XMvNp7peNQvwFAmojSf4ACgkQMvNp7peNQvw1WwD/XKnz
 0hPUlNtLF8bBYvf6Z/4rYjrr/wE7aLWVG3sBhwwBAKBt4X77YYyF1f1LjjgQMAIYFRwiW5pBEND
 k+DzTi/YI
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
---
 fs/fuse/dev_uring.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index e467b23e6895..c96d72250830 100644
--- a/fs/fuse/dev_uring.c
+++ b/fs/fuse/dev_uring.c
@@ -465,7 +465,10 @@ static void fuse_uring_async_stop_queues(struct work_struct *work)
 		schedule_delayed_work(&ring->async_teardown_work,
 				      FUSE_URING_TEARDOWN_INTERVAL);
 	} else {
+		struct fuse_chan *chan = ring->chan;
+
 		wake_up_all(&ring->stop_waitq);
+		fuse_conn_put(chan->conn);
 	}
 }
 
@@ -477,6 +480,9 @@ void fuse_uring_stop_queues(struct fuse_ring *ring)
 	fuse_uring_teardown_all_queues(ring);
 
 	if (atomic_read(&ring->queue_refs) > 0) {
+		struct fuse_chan *chan = ring->chan;
+
+		fuse_conn_get(chan->conn);
 		ring->teardown_time = jiffies;
 		INIT_DELAYED_WORK(&ring->async_teardown_work,
 				  fuse_uring_async_stop_queues);

-- 
2.53.0

