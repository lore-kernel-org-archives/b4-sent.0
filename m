From: Bernd Schubert <bernd@bsbernd.com>
Date: Sat, 06 Jun 2026 00:13:07 +0200
Subject: [PATCH RESEND v3 2/4] fuse: Avoid queue->stopped races and
 set/read that value under lock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260606-fuse-io-uring-race-fixes-v3-2-6fdf5e5b3437@bsbernd.com>
References: <20260606-fuse-io-uring-race-fixes-v3-0-6fdf5e5b3437@bsbernd.com>
In-Reply-To: <20260606-fuse-io-uring-race-fixes-v3-0-6fdf5e5b3437@bsbernd.com>
To: Pavel Begunkov <asml.silence@gmail.com>, 
 Luis Henriques <luis@igalia.com>, Joanne Koong <joannelkoong@gmail.com>, 
 fuse-devel@lists.linux.dev
Cc: Miklos Szeredi <mszeredi@redhat.com>, Berkant Koc <me@berkoc.com>, 
 Zhenghang Xiao <kipreyyy@gmail.com>, Bernd Schubert <bernd@bsbernd.com>, 
 stable@kernel.org, xlabai <xlabai@tencent.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=1859; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=HWo5fJlGlAXo6f941AhH0kCP6r4ltinB9EOcrReIqzo=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLKUPf97sRrK+wv/F9JyXXXaT47tf2aqzussP812gazL8
 S9+Zk/sKGVhEONgkBVTZOmS2GM75R+frNrX9ddh5rAygQxh4OIUgIkcu8jI8PDU2RPLfqTN42Hb
 +rUsqU9dSs16/sWd51OzDh2O1T+/xorhf0l6hLLjOc/vZx/+yc64mXvv9qTZtnJLf59k8H129LO
 MMDMA
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There are several readers of queue->stopped that check the value
under lock, but fuse_uring_commit_fetch() did not and actually
the value was not set under the lock in fuse_uring_abort_end_requests()
either. Especially in fuse_uring_commit_fetch it is important
to check under a lock, because due to races 'struct fuse_req'
might be freed with fuse_request_end, but another thread/cpu
might already do teardown work.

Cc: stable@kernel.org # 6.14
Fixes: 4a9bfb9b6850fec ("fuse: {io-uring} Handle teardown of ring entries")
Reported-by: Berkant Koc <me@berkoc.com>
Reported-by: xlabai <xlabai@tencent.com>
Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 fs/fuse/dev_uring.c | 10 +++++++---
 1 file changed, 7 insertions(+), 3 deletions(-)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index c96d72250830..c24a0b5b5357 100644
--- a/fs/fuse/dev_uring.c
+++ b/fs/fuse/dev_uring.c
@@ -130,10 +130,9 @@ void fuse_uring_abort_end_requests(struct fuse_ring *ring)
 		if (!queue)
 			continue;
 
-		queue->stopped = true;
-
 		WARN_ON_ONCE(fch->max_background != UINT_MAX);
 		spin_lock(&queue->lock);
+		queue->stopped = true;
 		spin_lock(&fch->bg_lock);
 		fuse_uring_flush_bg(queue);
 		spin_unlock(&fch->bg_lock);
@@ -902,10 +901,15 @@ static int fuse_uring_commit_fetch(struct io_uring_cmd *cmd, int issue_flags,
 		return err;
 	fpq = &queue->fpq;
 
-	if (!READ_ONCE(fch->connected) || READ_ONCE(queue->stopped))
+	if (!READ_ONCE(fch->connected))
 		return err;
 
 	spin_lock(&queue->lock);
+	if (unlikely(queue->stopped)) {
+		spin_unlock(&queue->lock);
+		return err;
+	}
+
 	/* Find a request based on the unique ID of the fuse request
 	 * This should get revised, as it needs a hash calculation and list
 	 * search. And full struct fuse_pqueue is needed (memory overhead).

-- 
2.53.0

