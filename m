From: Jiucheng Xu <jiucheng.xu@amlogic.com>
Date: Wed, 11 Mar 2026 15:22:34 +0800
Subject: [PATCH] erofs: use GFP_NOIO in endio decompression path of erofs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260311-origin-dev-v1-1-40524ef07ff0@amlogic.com>
X-B4-Tracking: v=1; b=H4sIADkYsWkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDY0ND3fyizPTMPN2U1DJdw2RLMzNTc0sLIwMTJaCGgqLUtMwKsGHRsbW
 1AF5jXR5cAAAA
X-Change-ID: 20260311-origin-dev-1c9665798204
To: Gao Xiang <xiang@kernel.org>, Chao Yu <chao@kernel.org>, 
 Yue Hu <zbestahu@gmail.com>, Jeffle Xu <jefflexu@linux.alibaba.com>, 
 Sandeep Dhavale <dhavale@google.com>, Hongbo Li <lihongbo22@huawei.com>, 
 Chunhai Guo <guochunhai@vivo.com>
Cc: linux-erofs@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 jianxin.pan@amlogic.com, tuan.zhang@amlogic.com, 
 Jiucheng Xu <jiucheng.xu@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773213766; l=1783;
 i=jiucheng.xu@amlogic.com; s=20250821; h=from:subject:message-id;
 bh=M0DxC1YSsNeUXU4lWpQgPmCwcDRu1aw6juBcKAOFoVM=;
 b=ugKwv1rm6H2qLye79IJSJ4l//Zmqe9nzUqXC6/9IrEJa+VRQ1DSlVFZTgzZXXk8PfbtMAiR1X
 pJ2N00kgkSRCJW4cJ4EGDTq+vIS5vsU2wTZkgsUJGoXqxxYaw/ekjFY
X-Developer-Key: i=jiucheng.xu@amlogic.com; a=ed25519;
 pk=Q18IjkdWCCuncSplyu+dYqIrm+n42glvoLFJTQqpb2o=
X-Endpoint-Received: by B4 Relay for jiucheng.xu@amlogic.com/20250821 with auth_id=498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The endio decompression path of erofs calls vm_map_ram(). Due to
insufficient memory, this function may generate memory swapping I/O,
which can cause submit_bio_wait to deadlock in some scenarios.

Trimmed down the call stack, as follows:

f2fs_submit_read_io
  submit_bio                      //bio_list is initialized.
    mmc_blk_mq_recovery
      z_erofs_endio
        vm_map_ram
          __pte_alloc_kernel
            __alloc_pages_direct_reclaim
              shrink_folio_list
                __swap_writepage
                  submit_bio_wait  //bio_list is non-NULL, hang!!!

Use memalloc_noio_{save,restore}() to wrap up this path.

Signed-off-by: Jiucheng Xu <jiucheng.xu@amlogic.com>
---
 fs/erofs/zdata.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/fs/erofs/zdata.c b/fs/erofs/zdata.c
index 3977e42b9516861bf3d59c072b6b8aaa6898dd8a..fe8121df9ef2f2404fc6e3f0fbbd6367f9ec2c67 100644
--- a/fs/erofs/zdata.c
+++ b/fs/erofs/zdata.c
@@ -1445,6 +1445,7 @@ static void z_erofs_decompress_kickoff(struct z_erofs_decompressqueue *io,
 				       int bios)
 {
 	struct erofs_sb_info *const sbi = EROFS_SB(io->sb);
+	int gfp_flag;
 
 	/* wake up the caller thread for sync decompression */
 	if (io->sync) {
@@ -1477,7 +1478,9 @@ static void z_erofs_decompress_kickoff(struct z_erofs_decompressqueue *io,
 			sbi->sync_decompress = EROFS_SYNC_DECOMPRESS_FORCE_ON;
 		return;
 	}
+	gfp_flag = memalloc_noio_save();
 	z_erofs_decompressqueue_work(&io->u.work);
+	memalloc_noio_restore(gfp_flag);
 }
 
 static void z_erofs_fill_bio_vec(struct bio_vec *bvec,

---
base-commit: 11439c4635edd669ae435eec308f4ab8a0804808
change-id: 20260311-origin-dev-1c9665798204

Best regards,
-- 
Jiucheng Xu <jiucheng.xu@amlogic.com>

