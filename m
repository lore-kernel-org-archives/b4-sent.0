From: Bernd Schubert <bernd@bsbernd.com>
Date: Mon, 15 Jun 2026 12:25:56 +0200
Subject: [PATCH v5] fuse: clear ent->fuse_req in commit_fetch error path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260615-fuse-io-uring-race-fixes-v5-1-8a360f055f0b@bsbernd.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/43PwQ6CMAwG4FchOzvTjYHMk+9hPJTRyQ6C2YRoC
 O9u8aLGhHj82/xf00kkioGS2GeTiDSGFPqOQ7HJhGuxO5MMDWehQZdQqEr6IfGsl0MM3VlGdCR
 9uFOShd2VYDQ0Gklw/RrpteD28cS5DenWx8fr0qiW6R/oqCTIvHSWaqywVtWhTjXFrtm6/iIWd
 tSflF2hNFOEBeRl48k4+qXyN8XYCpUz5ZXT2oJBr+CXMp/U2oNmodAogMoioPqm5nl+AgG2Rty
 jAQAA
X-Change-ID: 20260518-fuse-io-uring-race-fixes-59760420d2ae
To: Bernd Schubert <bernd@bsbernd.com>, 
 Joanne Koong <joannelkoong@gmail.com>, Miklos Szeredi <miklos@szeredi.hu>
Cc: fuse-devel@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Zhenghang Xiao <kipreyyy@gmail.com>, 
 Shuvam Pandey <shuvampandey1@gmail.com>, Berkant Koc <me@berkoc.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=2103; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=NDmmBuvBA5uUNdQI4TRQ677gpt32rjgzb2l1ZiLAF0Y=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLL0L5sYXNcJa3yaectTd4Vo8tyoc+aL3dvuTJV/k526Y
 LaLTumMjlIWBjEOBlkxRZYuiT22U/7xyap9XX8dZg4rE8gQBi5OAZhI7n+GPzyLn3WLr5+tdu/6
 puf80yWcZLjfn7wX11q86eJmf2XzqjWMDNMOv/vaGr/kqTij6plnBafqvOc9kDhy+oHUhZgOCaF
 F6pwA
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Zhenghang Xiao <kipreyyy@gmail.com>

fuse_uring_commit_fetch() error path called fuse_request_end(req) without
clearing ent->fuse_req when fuse_ring_ent_set_commit() fails. The
still-pending fuse_uring_send_in_task() task-work later dereferences the
dangling pointer through fuse_uring_prepare_send(), causing a
use-after-free.

End the request with fuse_uring_req_end(), which handles all conditions
already.

Annotation/edition by Bernd: The UAF should be fixed by other means already
and actually has to be avoided that way.
Just checking for ent->fuse_req == NULL in fuse_uring_send_in_task()
would be prone to race conditions, because if malicious userspace
would commit requests that have passed the NULL check, but are
in doing args copy, it would still trigger a use-after-free.
Setting ent->fuse_req = NULL in fuse_uring_commit_fetch() still
makes sense, though.

Reported-by: Shuvam Pandey <shuvampandey1@gmail.com>
Reported-by: Berkant Koc <me@berkoc.com>
Signed-off-by: Zhenghang Xiao <kipreyyy@gmail.com>
Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
This is to fix race conditions reported by Berkant and Zhenghang.

Changes in v5:
- Rebased against Miklos' for-next branch - all except one patch already
  picked up
- Use fuse_uring_req_end() instead of hand coding what it does
---
 fs/fuse/dev_uring.c | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index ba5edf5d01b3..77c8cec43d9c 100644
--- a/fs/fuse/dev_uring.c
+++ b/fs/fuse/dev_uring.c
@@ -1003,9 +1003,7 @@ static int fuse_uring_commit_fetch(struct io_uring_cmd *cmd, int issue_flags,
 		pr_info_ratelimited("qid=%d commit_id %llu state %d",
 				    queue->qid, commit_id, ent->state);
 		spin_unlock(&queue->lock);
-		req->out.h.error = err;
-		clear_bit(FR_SENT, &req->flags);
-		fuse_request_end(req);
+		fuse_uring_req_end(ent, req, err);
 		return err;
 	}
 

---
base-commit: bb43b4c7ea2a8265141aa93240f3f0ca71d85c0e
change-id: 20260518-fuse-io-uring-race-fixes-59760420d2ae

Best regards,
--  
Bernd Schubert <bernd@bsbernd.com>

