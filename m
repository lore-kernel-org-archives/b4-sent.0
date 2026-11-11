From: Mani Tofigh <mt4022@columbia.edu>
Date: Wed, 11 Nov 2026 16:51:43 -0500
Subject: [PATCH] f2fs: don't fall back to the older checkpoint on a read
 error
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-f2fs-cp-read-error-v1-1-a30ede66e589@columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMOw6DQAxF0a0g17HETPgo2UqUAowNTgHIJggJs
 fdM4HWneHcHZ1N2eGY7GK/qOo0J4ZYBDc3YM2qXDDGPVUhDieJIMxo3HbLZZCj3R1tToKqQEtJ
 xNhbdzujrfdm/7Ydp+ZfgOH5OPmHEdgAAAA==
X-Change-ID: 20261111-f2fs-cp-read-error-f39b7c1c64f5
To: Jaegeuk Kim <jaegeuk@kernel.org>, Chao Yu <chao@kernel.org>
Cc: linux-f2fs-devel@lists.sourceforge.net, linux-kernel@vger.kernel.org, 
 tz2294@columbia.edu, stable@kernel.org, Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794433902; l=3204;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=XjX2qFti2q+oUj8LyAqSc1Ajj/P6RtOkjfwWfSeWPYg=;
 b=uWMZPqjz0pg/OiaLYsHX47sNdInhj4oH1koQiqWYRL6KI2YMQwvz5qlixoz9L39oAbk09Vqv3
 rkZRDjTRdzlCW0fofOTdYcvkxxuU5JPtxryOEPhjR20GrcPBoPF5+dF
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

One read error on the newest checkpoint pack at mount rolls f2fs back to
the older checkpoint for good.  Everything synced since then is lost,
even if the error was transient.

get_checkpoint_version() returns -EIO when a cp block can't be read, and
validate_checkpoint() treats that like a bad CRC.
f2fs_get_valid_checkpoint() then mounts the other pack, and the next
checkpoint overwrites the pack it couldn't read.  E.g., with a dm error
target over the first block of the newest pack for the mount only:

  write OLD; sync; write NEW; sync; <power cut>
  mount /dev/mapper/err /mnt   # mounts the older checkpoint
  umount /mnt
  mount /dev/ram0 /mnt         # NEW is missing

Return -EIO from validate_checkpoint() and fail the mount instead, as we
already do when a payload block of the chosen pack can't be read.  We
can't tell which pack is newer without reading it, so a read error on
the older pack fails the mount too.  A bad CRC or version mismatch still
falls back to the other pack.  With the fix, the mount fails and NEW is
there on the next mount.

This bug was identified and confirmed with the help of a deterministic
hypervisor currently under development.  The C reproducer below however
hits it every time.

Fixes: 7735730d39d7 ("f2fs: fix to propagate error from __get_meta_page()")
Cc: stable@kernel.org
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
Reproducer: https://github.com/manitofigh/files/blob/main/linux-repros/f2fscpeio.c
---
 fs/f2fs/checkpoint.c | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/fs/f2fs/checkpoint.c b/fs/f2fs/checkpoint.c
index a9a2b9d93231..cbedd3e1399f 100644
--- a/fs/f2fs/checkpoint.c
+++ b/fs/f2fs/checkpoint.c
@@ -1178,6 +1178,8 @@ static struct f2fs_cached_block *validate_checkpoint(struct f2fs_sb_info *sbi,
 
 	err = get_checkpoint_version(sbi, cp_addr, &cp_block,
 					&cp_entry_1, version);
+	if (err == -EIO)
+		return ERR_PTR(err);
 	if (err)
 		return NULL;
 
@@ -1193,6 +1195,10 @@ static struct f2fs_cached_block *validate_checkpoint(struct f2fs_sb_info *sbi,
 	cp_addr += cp_blocks - 1;
 	err = get_checkpoint_version(sbi, cp_addr, &cp_block,
 					&cp_entry_2, version);
+	if (err == -EIO) {
+		f2fs_put_cache(cp_entry_1, true);
+		return ERR_PTR(err);
+	}
 	if (err)
 		goto invalid_cp;
 	cur_version = *version;
@@ -1231,11 +1237,19 @@ int f2fs_get_valid_checkpoint(struct f2fs_sb_info *sbi)
 	 */
 	cp_start_blk_no = le32_to_cpu(fsb->cp_blkaddr);
 	cp1 = validate_checkpoint(sbi, cp_start_blk_no, &cp1_version);
+	if (IS_ERR(cp1)) {
+		err = PTR_ERR(cp1);
+		goto free_fail_no_cp;
+	}
 
 	/* The second checkpoint pack should start at the next segment */
 	cp_start_blk_no += ((unsigned long long)1) <<
 				le32_to_cpu(fsb->log_blocks_per_seg);
 	cp2 = validate_checkpoint(sbi, cp_start_blk_no, &cp2_version);
+	if (IS_ERR(cp2)) {
+		err = PTR_ERR(cp2);
+		goto free_fail_no_cp;
+	}
 
 	if (cp1 && cp2) {
 		if (ver_after(cp2_version, cp1_version))

---
base-commit: 648bdfa9bae3850908df31617e5922e0683d5fff
change-id: 20261111-f2fs-cp-read-error-f39b7c1c64f5

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

