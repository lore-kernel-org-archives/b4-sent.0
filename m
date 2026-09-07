From: Jiucheng Xu <jiucheng.xu@amlogic.com>
Date: Mon, 07 Sep 2026 19:35:42 +0800
Subject: [PATCH] f2fs: force out-place update for all writes on compressed
 file
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260907-origin-dev-v1-1-85ae7ebc8c98@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAI2hnmoC/03MQQrCMBCF4auUWRvJjBqDq95DugjpmA7YRhIJS
 sndjcWFy//B+1bInIQzXLoVEhfJEpcWuOvAT24JrGRsDaTJaItWxSRBFjVyUZqtNwcmPJ4ctMM
 j8U1eG3YdWk+SnzG9N7vgd/0xZP6ZggqVJ6QzOkuode/mewzi9z7OMNRaP6PQm9qmAAAA
X-Change-ID: 20260818-origin-dev-0e8c63e2145a
To: Jaegeuk Kim <jaegeuk@kernel.org>, Chao Yu <chao@kernel.org>
Cc: linux-f2fs-devel@lists.sourceforge.net, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, jianxin.pan@amlogic.com, tao.zeng@amlogic.com, 
 tuan.zhang@amlogic.com, Jiucheng Xu <jiucheng.xu@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788780945; l=2497;
 i=jiucheng.xu@amlogic.com; s=20250821; h=from:subject:message-id;
 bh=YNrmwUC6hZBgGF3yjLDcDf3MEef/HpM3lXoE8cXM+oc=;
 b=2QKUyokgLLcsjxunR6k7wQ0huDmzz9QlttyBun5ZhJCS8hhFtf0fT5/2MtvQZv6XkjvH1SZt1
 xqgZwn86I2+BJAHh+YZhlRgzQj05jHztIJ+/JhOUkSZjkvKltWETVXa
X-Developer-Key: i=jiucheng.xu@amlogic.com; a=ed25519;
 pk=Q18IjkdWCCuncSplyu+dYqIrm+n42glvoLFJTQqpb2o=
X-Endpoint-Received: by B4 Relay for jiucheng.xu@amlogic.com/20250821 with auth_id=498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For compressed file, compressed write may fail and fall back to raw
write.

-Thread A                                         - Thread B
  - f2fs_write_multi_pages                          - f2fs_down_write(&sbi->cp_rwsem);
   - f2fs_write_compressed_pages                    - ...
    - f2fs_trylock_op                               - ...
     - f2fs_down_read_trylock(&sbi->cp_rwsem);      - ...
   - f2fs_write_raw_pages                           - ...

Thread B acquires the lock first, which causes Thread A to fail lock
acquisition and fall back to raw-data write.
IPU_FORCE is enabled on small-capacity storage devices (< 16GB),
so f2fs_write_raw_pages() overwrites the original compressed data
in-place.

The in-memory node has been updated with raw-data addresses, while the
node metadata stored on eMMC still remains in compressed state.
If a power-cut occurs before the node is flushed to disk, on-disk
inconsistency arises: disk data is raw, yet metadata treats it as a
compressed cluster, leading to decompression failure.

To eliminate this risk completely, force out-place update for all
write operations on compressed file.

Signed-off-by: Jiucheng Xu <jiucheng.xu@amlogic.com>
---
- Link to v1: https://lore.kernel.org/r/20260826-origin-dev-v1-1-c21271a82100@amlogic.com
---
 fs/f2fs/data.c | 10 ++++++----
 1 file changed, 6 insertions(+), 4 deletions(-)

diff --git a/fs/f2fs/data.c b/fs/f2fs/data.c
index 6ae0eb37d20f96ed51a8124f59ba90dabf632fb5..aaeea561dcd30681b9b37f2f6f0493ed58ec2fe0 100644
--- a/fs/f2fs/data.c
+++ b/fs/f2fs/data.c
@@ -2973,10 +2973,12 @@ bool f2fs_should_update_outplace(struct inode *inode, struct f2fs_io_info *fio)
 		return true;
 	if (f2fs_used_in_atomic_write(inode))
 		return true;
-	/* rewrite low ratio compress data w/ OPU mode to avoid fragmentation */
-	if (f2fs_compressed_file(inode) &&
-		F2FS_OPTION(sbi).compress_mode == COMPR_MODE_USER &&
-		is_inode_flag_set(inode, FI_ENABLE_COMPRESS))
+	/*
+	 * rewrite low ratio compress data w/ OPU mode to avoid fragmentation.
+	 * If IO comes from compressed write path and fallback to raw write,
+	 * force out‑place to prevent metadata‑data inconsistency.
+	 */
+	if (f2fs_compressed_file(inode))
 		return true;
 
 	/* swap file is migrating in aligned write mode */

---
base-commit: 0a1703eba23707e3b2edfa2a2329352e7abc0ffa
change-id: 20260818-origin-dev-0e8c63e2145a

Best regards,
-- 
Jiucheng Xu <jiucheng.xu@amlogic.com>

