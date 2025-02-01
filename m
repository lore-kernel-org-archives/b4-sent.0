From: David Dgien <dgienda125@gmail.com>
Date: Fri, 31 Jan 2025 22:59:08 -0500
Subject: [PATCH] kbuild: Use uname for BAREBOX_COMPILE_HOST
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250131-hostname-fix-v1-1-8d7ae619fcf4@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAucnWcC/x2MQQqAIBAAvyJ7TnANsfpKdJDccg9paEQQ/j3pO
 AMzLxTKTAUm8UKmmwun2AA7AWtwcSfJvjFopY3CHmVI5YruILnxIw1atHbwflQGWnJmavrfzUu
 tH17sbo5eAAAA
X-Change-ID: 20250131-hostname-fix-5171778dd905
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: David Dgien <dgienda125@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1738382352; l=1525;
 i=dgienda125@gmail.com; s=20250126; h=from:subject:message-id;
 bh=xhq+3Us3jV+l4WYQJZs4XD7JPkB7pB6UeKbnNdxDEBc=;
 b=piTPCB7bQwQvnVKV6FbnS2xB4f5sAVpzHhAblH70JHdeYyzL+3xCQtXEWxBpXcKOBAWPtEhdz
 UbvwgYjZ+cwBCfOK1d0ZtiS82DIsXPdN2L1rV8PZSezQ16cXYCo7Rml
X-Developer-Key: i=dgienda125@gmail.com; a=ed25519;
 pk=zPhfl/eH2iShpaIksvU8MCg11Il6Dx2oW7WYAzpKbo0=
X-Endpoint-Received: by B4 Relay for dgienda125@gmail.com/20250126 with auth_id=332
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adoption of Linux Commit:

| commit 1e66d50ad3a1dbf0169b14d502be59a4b1213149
| Author: Chris Down <chris@chrisdown.name>
| Date:   Tue Oct 20 10:34:59 2020 +0100
|
|     kbuild: Use uname for LINUX_COMPILE_HOST detection
|
|     `hostname` may not be present on some systems as it's not mandated by
|     POSIX/SUSv4. This isn't just a theoretical problem: on Arch Linux,
|     `hostname` is provided by `inetutils`, which isn't part of the base
|     distribution.
|
|         ./scripts/mkcompile_h: line 38: hostname: command not found
|
|     Use `uname -n` instead, which is more likely to be available (and
|     mandated by standards).
|
|     Signed-off-by: Chris Down <chris@chrisdown.name>
|     Signed-off-by: Masahiro Yamada <masahiroy@kernel.org>

Signed-off-by: David Dgien <dgienda125@gmail.com>
---
 scripts/mkcompile_h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/scripts/mkcompile_h b/scripts/mkcompile_h
index 49aadc153d44995c23ccc5bc604c2370384387ae..0cc6aa8f0585767435fc6c8537b878925a81a691 100755
--- a/scripts/mkcompile_h
+++ b/scripts/mkcompile_h
@@ -46,7 +46,7 @@ else
 	BAREBOX_COMPILE_BY=$KBUILD_BUILD_USER
 fi
 if test -z "$KBUILD_BUILD_HOST"; then
-	BAREBOX_COMPILE_HOST=`hostname`
+	BAREBOX_COMPILE_HOST=`uname -n`
 else
 	BAREBOX_COMPILE_HOST=$KBUILD_BUILD_HOST
 fi

---
base-commit: b2a15c383ddc4f31792e48e395a425e5c3658dd1
change-id: 20250131-hostname-fix-5171778dd905

Best regards,
-- 
David Dgien <dgienda125@gmail.com>

