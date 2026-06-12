From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 12 Jun 2026 14:29:06 -0500
Subject: [PATCH v2] exfat: bound uniname advance in exfat_find_dir_entry()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260612-b4-disp-d3abc2b6-v2-1-258241593ae4@proton.me>
X-B4-Tracking: v=1; b=H4sIAAFeLGoC/x3MQQqAIBBA0avIrBuwKY26SrRInWo2JQoRhHdPW
 r7F/y9kTsIZJvVC4luyXGcFNQr8sZ47o4RqIE1W25bQ9RgkRwzd6jw5i2PHvjV6NDRoqFlMvMn
 zL+ellA8WSXibYgAAAA==
To: Namjae Jeon <linkinjeon@kernel.org>
Cc: linux-kernel@vger.kernel.org, Yuezhang Mo <yuezhang.mo@sony.com>, 
 linux-fsdevel@vger.kernel.org, Sungjong Seo <sj1557.seo@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781292545; l=2822;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=LNI0kDtHH/W947OqR+LGmsyVeZLd+/2r2AH7hli3KHs=;
 b=cgaTm+fV7pbhuoeL/7pnvudtRyaS1AIPu1BLMoAhGy3lx+FAgOmkGRpdN6ZNBbdbpHM7AHumD
 A0rRjgwvwrECnz7lh7cgNeEAqjuN33287vk4cwh/p6aUEuYzJS1sKZ2
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In exfat_find_dir_entry(), each TYPE_EXTEND (file name) entry advances the
output pointer by a fixed amount while the loop guard only tracks the
accumulated name length:

	if (++order == 2)
		uniname = p_uniname->name;
	else
		uniname += EXFAT_FILE_NAME_LEN;
	len = exfat_extract_uni_name(ep, entry_uniname);
	name_len += len;
	unichar = *(uniname+len);
	*(uniname+len) = 0x0;

uniname grows by EXFAT_FILE_NAME_LEN (15) per name entry, but name_len
grows only by the actual extracted length, which is shorter when a name
fragment contains an early NUL.  The only guard is
`name_len >= MAX_NAME_LENGTH`, so a crafted directory with many short
name fragments lets uniname run far past the
p_uniname->name[MAX_NAME_LENGTH + 3] buffer while name_len stays small,
causing an out-of-bounds read and write at *(uniname+len).

The sibling extractor exfat_get_uniname_from_ext_entry() already stops
on a short fragment (the lockstep `len != EXFAT_FILE_NAME_LEN` guard
added in commit d42334578eba ("exfat: check if filename entries exceeds
max filename length")); exfat_find_dir_entry() never got the
equivalent.  Track the per-entry write offset as a count and reject a
fragment once the offset, or the offset plus the extracted length, would
exceed MAX_NAME_LENGTH, before forming the output pointer.

Fixes: ca06197382bd ("exfat: add directory operations")
Cc: stable@vger.kernel.org
Suggested-by: Namjae Jeon <linkinjeon@kernel.org>
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 fs/exfat/dir.c | 13 ++++++++-----
 1 file changed, 8 insertions(+), 5 deletions(-)

diff --git a/fs/exfat/dir.c b/fs/exfat/dir.c
index 5a85a8ec0cc0..4fd4ec52b8c0 100644
--- a/fs/exfat/dir.c
+++ b/fs/exfat/dir.c
@@ -1069,6 +1069,7 @@ int exfat_find_dir_entry(struct super_block *sb, struct exfat_inode_info *ei,
 
 			if (entry_type == TYPE_EXTEND) {
 				unsigned short entry_uniname[16], unichar;
+				unsigned int offset;
 
 				if (step != DIRENT_STEP_NAME ||
 				    name_len >= MAX_NAME_LENGTH) {
@@ -1077,13 +1078,15 @@ int exfat_find_dir_entry(struct super_block *sb, struct exfat_inode_info *ei,
 					continue;
 				}
 
-				if (++order == 2)
-					uniname = p_uniname->name;
-				else
-					uniname += EXFAT_FILE_NAME_LEN;
-
+				offset = (++order - 2) * EXFAT_FILE_NAME_LEN;
 				len = exfat_extract_uni_name(ep, entry_uniname);
 				brelse(bh);
+				if (offset > MAX_NAME_LENGTH ||
+				    len > MAX_NAME_LENGTH - offset) {
+					step = DIRENT_STEP_FILE;
+					continue;
+				}
+				uniname = p_uniname->name + offset;
 				name_len += len;
 
 				unichar = *(uniname+len);

---
base-commit: 56221100f0d37227621217a8551f5dcdda0fb768
change-id: 20260612-b4-disp-d3abc2b6-93ec15095270

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

