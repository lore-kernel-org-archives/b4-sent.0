From: Jiucheng Xu <jiucheng.xu@amlogic.com>
Date: Thu, 18 Sep 2025 03:32:42 +0000
Subject: [PATCH] f2fs: Use mapping->gfp_mask to get file cache for writing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250918-origin-dev-v1-1-8d9877df9e77@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAFl9y2gC/x3MQQqAIBBA0avIrBtQwaiuEi0sR5uNhoIE4t2Tl
 m/xf4NCmanAJhpkqlw4xQE1CbhuGwMhu2HQUhu5Kokpc+CIjiou1ng/n0TKaxjBk8nz+8/2o/c
 PLoFscVwAAAA=
X-Change-ID: 20250910-origin-dev-8a5ff6bee1f2
To: Jaegeuk Kim <jaegeuk@kernel.org>, Chao Yu <chao@kernel.org>
Cc: linux-f2fs-devel@lists.sourceforge.net, linux-kernel@vger.kernel.org, 
 tuan.zhang@amlogic.com, jianxin.pan@amlogic.com, 
 Jiucheng Xu <jiucheng.xu@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758166370; l=1204;
 i=jiucheng.xu@amlogic.com; s=20250821; h=from:subject:message-id;
 bh=Cfox4dJD5Z2I7UJ/AEjRgz28jZFDDgARsCgPQjW/S2A=;
 b=Tt6i/YFFmrIxDb3zDxPDh8BLNgR4ijbjwG/tkeEdWisUTLHUlLWv8JzFkU0BNDud+e04A9d1f
 U6Q8769JzCRCiUr5cpMFT+GqDKx2k6WOhaq6ElusJ12hhH59FX8Uyn/
X-Developer-Key: i=jiucheng.xu@amlogic.com; a=ed25519;
 pk=Q18IjkdWCCuncSplyu+dYqIrm+n42glvoLFJTQqpb2o=
X-Endpoint-Received: by B4 Relay for jiucheng.xu@amlogic.com/20250821 with auth_id=498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On 32-bit architectures, when GFP_NOFS is used, the file cache for write
operations cannot be allocated from the highmem and CMA.

Since mapping->gfp_mask is set to GFP_HIGHUSER_MOVABLE during inode
allocation, using mapping_gfp_mask(mapping) as the GFP flag of getting file
cache for writing is more efficient for 32-bit architectures.

Signed-off-by: Jiucheng Xu <jiucheng.xu@amlogic.com>
---
 fs/f2fs/data.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/fs/f2fs/data.c b/fs/f2fs/data.c
index 7961e0ddfca3aaa332b7dbd4985ae7766551834f..9fbc41f9accb2626da22754f1a424da4805ca823 100644
--- a/fs/f2fs/data.c
+++ b/fs/f2fs/data.c
@@ -3587,7 +3587,8 @@ static int f2fs_write_begin(const struct kiocb *iocb,
 	 * Will wait that below with our IO control.
 	 */
 	folio = __filemap_get_folio(mapping, index,
-				FGP_LOCK | FGP_WRITE | FGP_CREAT, GFP_NOFS);
+				FGP_LOCK | FGP_WRITE | FGP_CREAT,
+				mapping_gfp_mask(mapping));
 	if (IS_ERR(folio)) {
 		err = PTR_ERR(folio);
 		goto fail;

---
base-commit: c872b6279cd26762339ff02513e2a3f16149a6f1
change-id: 20250910-origin-dev-8a5ff6bee1f2

Best regards,
-- 
Jiucheng Xu <jiucheng.xu@amlogic.com>

