From: Ivan Nestlerode <ivan.nestlerode@sonos.com>
Date: Tue, 21 Jul 2026 16:37:06 -0400
Subject: [PATCH] mpg123: fix lack of NEON usage on aarch64
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260721-fix_mpg123_aarch64_neon-v1-1-b5cc73ff9d10@sonos.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQqAIBAAvxJ7TnBXMegrEWK11h6yUIgg+nvSc
 WBmHiichQv0zQOZLylypArYNjBvIa2sZKkMpMnpjlBFuf1+rkjGh5DnzVmf+EjK2KjNYggni1D
 rM3NV//Mwvu8HgFbqemkAAAA=
X-Change-ID: 20260721-fix_mpg123_aarch64_neon-34f03d321b41
To: openembedded-core@lists.openembedded.org
Cc: Ivan Nestlerode <ivan.nestlerode@sonos.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784666237; l=1526;
 i=ivan.nestlerode@sonos.com; s=20260504; h=from:subject:message-id;
 bh=KVry7zihjl+u7ivKUjf42xSXaxtMInvV9UYsERPzfmU=;
 b=umktnFQ56Cc/ymX0hg/W0L6PY9LmKxOA5sdM5EHuI3ggXf8FeFG96+e9OQ1rCTgXK/4m7BSqD
 hA611+9u8RiBOP+ugS+ZKN3yrv/N1VXX4g0oekHBSrn0Wo0SH7Hpq2n
X-Developer-Key: i=ivan.nestlerode@sonos.com; a=ed25519;
 pk=kcjfcLwbjs7Fqv95W59a7YVW52AGAkgpAOoPa23YKXU=
X-Endpoint-Received: by B4 Relay for ivan.nestlerode@sonos.com/20260504 with auth_id=767
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fixes [YOCTO #16359]

mpg123 supports specific --with-cpu= configure options to use NEON
instructions, but this recipe was not using any of these on aarch64.
The problem is that it was only keying off of whether TUNE_FEATURES
contains "neon". aarch64 never puts "neon" into TUNE_FEATURES so it
has to be checked separately.

Use --with-cpu=neon64 on aarch64.

Signed-off-by: Ivan Nestlerode <ivan.nestlerode@sonos.com>
---
The mpg123 recipe has a bug on aarch64 that makes it not use NEON.
This patch series fixes that bug.
---
 meta/recipes-multimedia/mpg123/mpg123_1.33.6.bb | 1 +
 1 file changed, 1 insertion(+)

diff --git a/meta/recipes-multimedia/mpg123/mpg123_1.33.6.bb b/meta/recipes-multimedia/mpg123/mpg123_1.33.6.bb
index f07e6dbcd3..7fa048c9fc 100644
--- a/meta/recipes-multimedia/mpg123/mpg123_1.33.6.bb
+++ b/meta/recipes-multimedia/mpg123/mpg123_1.33.6.bb
@@ -42,6 +42,7 @@ EXTRA_OECONF = " \
     --enable-largefile \
     --with-audio='${AUDIOMODS}' \
     ${@bb.utils.contains('TUNE_FEATURES', 'neon', '--with-cpu=neon', '', d)} \
+    ${@bb.utils.contains('TUNE_FEATURES', 'aarch64', '--with-cpu=neon64', '', d)} \
     ${@bb.utils.contains('TUNE_FEATURES', 'altivec', '--with-cpu=altivec', '', d)} \
     ${@bb.utils.contains('TARGET_FPU', 'soft', '--with-cpu=generic_nofpu', '', d)} \
 "

---
base-commit: a4eb7bc2a750f76d9772eb88b7afb2b801bd1250
change-id: 20260721-fix_mpg123_aarch64_neon-34f03d321b41

Best regards,
-- 
Ivan Nestlerode <ivan.nestlerode@sonos.com>

