From: Bernd Schubert <bernd@bsbernd.com>
Date: Mon, 18 May 2026 18:37:32 +0200
Subject: [PATCH 4/4] fuse: clear ent->fuse_req in commit_fetch error path
 to prevent UAF
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260518-fuse-io-uring-race-fixes-v1-4-36c9eba8ab18@bsbernd.com>
References: <20260518-fuse-io-uring-race-fixes-v1-0-36c9eba8ab18@bsbernd.com>
In-Reply-To: <20260518-fuse-io-uring-race-fixes-v1-0-36c9eba8ab18@bsbernd.com>
To: security@kernel.org, Pavel Begunkov <asml.silence@gmail.com>, 
 Luis Henriques <luis@igalia.com>, Joanne Koong <joannelkoong@gmail.com>
Cc: Miklos Szeredi <mszeredi@redhat.com>, Berkant Koc <me@berkoc.com>, 
 Zhenghang Xiao <kipreyyy@gmail.com>, Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=2192; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=QXHsYHkg1AHGACfazD67qWVoeoE/9gkwVjuPl49Kwxs=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLK4HQI2y7+X7zc+/9pG0YBr/T6ur3ELLIKyLujsvFR0f
 AHfNIP7HaUsDGIcDLJiiixdEntsp/zjk1X7uv46zBxWJpAhDFycAjCRvG8M/6O0mFs3c/tI+C45
 9mqu1cU9h3QOsk/uyW+dvnHDbKdzE9Yy/JV7fHWTHhfP6YOM2VXhnAv/sPnunWX7+VK3/TS28lK
 xvQwA
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Zhenghang Xiao <kipreyyy@gmail.com>

fuse_uring_commit_fetch() error path calls fuse_request_end(req) without
clearing ent->fuse_req when fuse_ring_ent_set_commit() fails. The
still-pending fuse_uring_send_in_task() task-work later dereferences the
dangling pointer through fuse_uring_prepare_send(), causing a
use-after-free.

Clear ent->fuse_req under queue->lock in the error path, matching the
pattern in fuse_uring_req_end(). Add a NULL check in
fuse_uring_send_in_task() so the entry is gracefully recycled if the
request was detached.

Annotation/edition by Bernd: The UAF should be fixed by other means already
and actually has to be avoided that way.
Just checking for ent->fuse_req == NULL in fuse_uring_send_in_task()
would be prone to race conditions, because if malicious userspace
would commit requests that have passed the NULL check, but are
in doing args copy, it would still trigger a use-after-free.
Setting ent->fuse_req = NULL in fuse_uring_commit_fetch() still
makes sense, though. And an additional sanity check in
fuse_uring_send_in_task() does not hurt either.

Also reported by: Berkant Koc <me@berkoc.com>

Fixes: c090c8abae4b ("fuse: Add io-uring sqe commit and fetch support")
Signed-off-by: Zhenghang Xiao <kipreyyy@gmail.com>
Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 fs/fuse/dev_uring.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index ebbfec9a0014..5a8e54cf004f 100644
--- a/fs/fuse/dev_uring.c
+++ b/fs/fuse/dev_uring.c
@@ -931,6 +931,7 @@ static int fuse_uring_commit_fetch(struct io_uring_cmd *cmd, int issue_flags,
 	if (err != 0) {
 		pr_info_ratelimited("qid=%d commit_id %llu state %d",
 				    queue->qid, commit_id, ent->state);
+		ent->fuse_req = NULL;
 		spin_unlock(&queue->lock);
 		req->out.h.error = err;
 		clear_bit(FR_SENT, &req->flags);
@@ -1229,6 +1230,8 @@ static void fuse_uring_send_in_task(struct io_tw_req tw_req, io_tw_token_t tw)
 	int err;
 
 	if (!tw.cancel) {
+		if (WARN_ON_ONCE(!ent->fuse_req))
+			return;
 		err = fuse_uring_prepare_send(ent, ent->fuse_req);
 		if (err) {
 			fuse_uring_next_fuse_req(ent, queue, issue_flags);

-- 
2.53.0

