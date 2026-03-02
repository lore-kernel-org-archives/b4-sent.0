From: Jiucheng Xu <jiucheng.xu@amlogic.com>
Date: Mon, 02 Mar 2026 10:51:03 +0800
Subject: [PATCH] block: avoild hang when bio_list is non-NULL in
 submit_bio_wait()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260302-for-next-v1-1-eb9339e8dc99@amlogic.com>
X-B4-Tracking: v=1; b=H4sIABb7pGkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDIyMT3bT8It281IoS3ZQ0szQDo2RjM0uTFCWg8oKi1LTMCrBR0bG1tQA
 I0PQ8WgAAAA==
X-Change-ID: 20260224-for-next-df6f02c3694d
To: Jens Axboe <axboe@kernel.dk>
Cc: linux-block@vger.kernel.org, linux-kernel@vger.kernel.org, 
 jianxin.pan@amlogic.com, tuan.zhang@amlogic.com, 
 Jiucheng Xu <jiucheng.xu@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772419870; l=1659;
 i=jiucheng.xu@amlogic.com; s=20250821; h=from:subject:message-id;
 bh=umq++sfYBrcQgzncaR6KD4RDdLQo6hXzgnvNht92JHc=;
 b=X4RjgRRm6Nf1/IzXU5/a0BXUn8bhim1Iv+n8TXxQpemJztwPBKYqS1YR+PYAsHBQI8wb+Ky9E
 e7RVwpTFwg8CPn//V6Q8dE0FjNN2kt+krfZ6ZZLFPp9hSxEcEzWQ9zw
X-Developer-Key: i=jiucheng.xu@amlogic.com; a=ed25519;
 pk=Q18IjkdWCCuncSplyu+dYqIrm+n42glvoLFJTQqpb2o=
X-Endpoint-Received: by B4 Relay for jiucheng.xu@amlogic.com/20250821 with auth_id=498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When current->bio_list is non-NULL in submit_bio_wait(),
submit_bio_noacct_nocheck appends bio to bio_list but skips IO
submission, causing submit_bio_wait() to hang indefinitely.

Fix this by temporarily backup bio_list, setting bio_list to
NULL before calling submit_bio(), then restoring bio_list
after submit_bio() returns.

I've trimmed down the call stack, as follows:

f2fs_submit_read_io
  submit_bio
    mmc_blk_mq_recovery
      z_erofs_endio
        vm_map_ram
          __pte_alloc_kernel
            __alloc_pages_direct_reclaim
              shrink_folio_list
                __swap_writepage
                  submit_bio_wait  hang!!!

Signed-off-by: Jiucheng Xu <jiucheng.xu@amlogic.com>
---
 block/bio.c | 13 +++++++++++--
 1 file changed, 11 insertions(+), 2 deletions(-)

diff --git a/block/bio.c b/block/bio.c
index d80d5d26804e32944bcfe4506ca190033308844f..22c8769722cc89620c239310a0f3d4924de68cf9 100644
--- a/block/bio.c
+++ b/block/bio.c
@@ -1505,8 +1505,17 @@ int submit_bio_wait(struct bio *bio)
 	bio->bi_private = &done;
 	bio->bi_end_io = submit_bio_wait_endio;
 	bio->bi_opf |= REQ_SYNC;
-	submit_bio(bio);
-	blk_wait_io(&done);
+	if (!current->bio_list) {
+		submit_bio(bio);
+		blk_wait_io(&done);
+	} else {
+		struct bio_list *tmp = current->bio_list;
+
+		current->bio_list = NULL;
+		submit_bio(bio);
+		blk_wait_io(&done);
+		current->bio_list = tmp;
+	}
 
 	return blk_status_to_errno(bio->bi_status);
 }

---
base-commit: 8c5f40a3ba43ae9a26991f0e4a01a3a06e8958fc
change-id: 20260224-for-next-df6f02c3694d

Best regards,
-- 
Jiucheng Xu <jiucheng.xu@amlogic.com>

