From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 12 Jun 2026 11:40:23 +0200
Subject: [PATCH] nvme: unmap the data buffer when metadata mapping fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260612-jag-fixes-v1-1-24423dc8afdb@kernel.org>
X-B4-Tracking: v=1; b=H4sIAAbUK2oC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDM0Mj3azEdN20zIrUYl2zJBNTy9REQ7MUU2MloPqColSwBFB5dGxtLQA
 lPQ6SWwAAAA==
X-Change-ID: 20260612-jag-fixes-6b459ea16d53
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>
Cc: Daniel Gomez <da.gomez@kernel.org>, linux-nvme@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1844;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=dvvJGP8seoXJbEB71BwDcA4pq9Th3sDnGpORJL37W/Y=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGor1A9zkZhR0quHNS7DbnQa0qQrZeirRUPDJ
 WfxBHF28lrPUokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqK9QPAAoJELqXzVK3
 lkFP0ocMAIDSLx7nSaxQ7ggaIDFrId2MZPWz9f1Rw6YK1Vj1JiUN264k04uTf2mRv21tas1tQtX
 9+CXnCc4F8USqxZyfeZ32om1CDVOpzr5vuDtIiE/bPl+uhxTvysgMpzOVEAl9Z+JzmvpSClrOct
 StKUznKNkQOKPFoWh7Cx0/ZdI68xILH9k6k1SE7XkaP0Z7MAqxhRXjyfcKE79z7Se8LTNqNfNgf
 L6LJp9FnTBcfC9Pnjjuwfr19lXKNNi7ynWQlzF9lsbqEpqk+r5rXbvBAhXB6YfrczfiuaGoaRSO
 n52pY3PYFWIJtKNIzN+VJixbHJ8gAy+aKa7XiwMaSch37xE1kOSHO7S3+om9bxceXBHnah8pJCE
 KIUJ0zXwweFDIrtJ+u7Ym86EZ6JmO9J207BKWr+etachqxg7x38WxLU8lfSAMSCHyjbzFNV41Y+
 wNBlR+pALmcjIwQmHpwYlNvOaBw6aV8Mt1wh/t+CQCijwfrKuqbUkS/RNeTvHskzKBhGME+DvC5
 +Q=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit d0d1d522316e ("blk-map: provide the bdev to bio if one exists")
dropped the "bio = req->bio" assignment in nvme_map_user_request(), but
left the local bio variable initialized to NULL and still used it in the
out_unmap error path.  The "if (bio)" test is therefore always false, so
a failure of blk_rq_integrity_map_user() no longer unmaps the already
mapped data buffer.  The callers only call blk_mq_free_request(), which
does not unmap user pages, leaking the bio and its pinned user pages.

Use req->bio directly to unmap the data buffer on the error path, and
drop the now unused local variable.

Fixes: d0d1d522316e ("blk-map: provide the bdev to bio if one exists")

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
Did we forget to unmap?
---
 drivers/nvme/host/ioctl.c | 5 ++---
 1 file changed, 2 insertions(+), 3 deletions(-)

diff --git a/drivers/nvme/host/ioctl.c b/drivers/nvme/host/ioctl.c
index 9597a87cf05dc32a7eb0373485f575502c32a105..9ae3c0aadfb8f35790c8e57619d1af69ca41af0c 100644
--- a/drivers/nvme/host/ioctl.c
+++ b/drivers/nvme/host/ioctl.c
@@ -122,7 +122,6 @@ static int nvme_map_user_request(struct request *req, u64 ubuffer,
 	bool supports_metadata = bdev && blk_get_integrity(bdev->bd_disk);
 	struct nvme_ctrl *ctrl = nvme_req(req)->ctrl;
 	bool has_metadata = meta_buffer && meta_len;
-	struct bio *bio = NULL;
 	int ret;
 
 	if (!nvme_ctrl_sgl_supported(ctrl))
@@ -154,8 +153,8 @@ static int nvme_map_user_request(struct request *req, u64 ubuffer,
 	return ret;
 
 out_unmap:
-	if (bio)
-		blk_rq_unmap_user(bio);
+	if (req->bio)
+		blk_rq_unmap_user(req->bio);
 	return ret;
 }
 

---
base-commit: adeac771f4901bb66267eaddb9fcc538925f92a4
change-id: 20260612-jag-fixes-6b459ea16d53

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

