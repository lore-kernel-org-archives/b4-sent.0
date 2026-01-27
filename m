From: Jiucheng Xu <jiucheng.xu@amlogic.com>
Date: Tue, 27 Jan 2026 17:34:10 +0800
Subject: [PATCH] ext4: EXT4_I(sbi->s_buddy_cache)->i_state_flags is not
 initialized
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260127-origin-dev-v1-1-cafda25e307f@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAJGGeGkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDQyMz3fyizPTMPN2U1DJdyzQLE0Nj0yRLU1NTJaCGgqLUtMwKsGHRsbW
 1AP5MSmpcAAAA
X-Change-ID: 20260126-origin-dev-9f84135b9555
To: Theodore Ts'o <tytso@mit.edu>, 
 Andreas Dilger <adilger.kernel@dilger.ca>
Cc: linux-ext4@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, jianxin.pan@amlogic.com, tuan.zhang@amlogic.com, 
 Jiucheng Xu <jiucheng.xu@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769506451; l=1571;
 i=jiucheng.xu@amlogic.com; s=20250821; h=from:subject:message-id;
 bh=YWP7kPJlOX7OLc+FLI3fR6NkrBzeRbLZcst1TTgNbyA=;
 b=f0Hg3TtsLr4287r90uzc7VGPUI1SUs5bqUrBtUn0WdVP0MYcsg5XZQwNcCvU3XErB11/1f/8P
 cICYbUnQQV3AkdS2lTKlDEsb0lpCMgqXWLVd5Gxs1uM4b8id+zxkTWr
X-Developer-Key: i=jiucheng.xu@amlogic.com; a=ed25519;
 pk=Q18IjkdWCCuncSplyu+dYqIrm+n42glvoLFJTQqpb2o=
X-Endpoint-Received: by B4 Relay for jiucheng.xu@amlogic.com/20250821 with auth_id=498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The i_state_flags originates from an inode that was previously
destroyed and then allocated to s_buddy_cache; it requires
reinitialization.

The relevant log during umount is shown below:

EXT4-fs (mmcblk0p28): unmounting filesystem xxx-xxx
EXT4-fs (mmcblk0p28): Inode 1 (39878178): inode tracked as orphan!
39878178: 1411f3c7 e0182705 78cc454d ac11f000  .....'..ME.x....
da10433b: 1a2e0146 792e03d0 9c2a04d1 0c788ad3  F......y..*...x.
a91573cf: 44270388 4f4202ea 721a12ea 340cbce0  ..'D..BO...r...4
89cb2f37: 0d13f000 4f270414 1a0b01f0 4f880fe0  ......'O.......O
810e3bc2: 3f0c02f0 482b0009 02e048d0 83f43f2a  ...?..+H.H..*?..
3f37c9f7: 02880aaf 00000000 00000000 00000000  ................

Signed-off-by: Jiucheng Xu <jiucheng.xu@amlogic.com>
---
 fs/ext4/mballoc.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/fs/ext4/mballoc.c b/fs/ext4/mballoc.c
index dbc82b65f810fed89da7fa7149d3a05de6f107d6..20b07b2bea31ea81ffbd0b4ace3a7b218c8f4dd5 100644
--- a/fs/ext4/mballoc.c
+++ b/fs/ext4/mballoc.c
@@ -3521,6 +3521,9 @@ static int ext4_mb_init_backend(struct super_block *sb)
 	sbi->s_buddy_cache->i_ino = EXT4_BAD_INO;
 	EXT4_I(sbi->s_buddy_cache)->i_disksize = 0;
 	ext4_set_inode_mapping_order(sbi->s_buddy_cache);
+#if (BITS_PER_LONG < 64)
+	ext4_clear_state_flags(EXT4_I(sbi->s_buddy_cache));
+#endif
 
 	for (i = 0; i < ngroups; i++) {
 		cond_resched();

---
base-commit: 4f5e8e6f012349a107531b02eed5b5ace6181449
change-id: 20260126-origin-dev-9f84135b9555

Best regards,
-- 
Jiucheng Xu <jiucheng.xu@amlogic.com>

