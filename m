From: Daniel Palmer <daniel.palmer@sony.com>
Date: Fri, 25 Jul 2025 14:30:57 +0900
Subject: [PATCH] fbdev: Fix typo in Kconfig text for FB_DEVICE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250725-fbdev-typo-v1-1-f9fd1418cb51@sony.com>
X-B4-Tracking: v=1; b=H4sIAJAWg2gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDcyNT3bSklNQy3ZLKgnxdSwMDE9NkoyTDlORUJaCGgqLUtMwKsGHRsbW
 1AGLSkX1cAAAA
To: Simona Vetter <simona@ffwll.ch>, Helge Deller <deller@gmx.de>
Cc: linux-fbdev@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, Daniel Palmer <daniel.palmer@sony.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753421457; l=983;
 i=daniel.palmer@sony.com; s=20250610; h=from:subject:message-id;
 bh=ExcVPhfNsQdjthV2mryqOJJS7Mv9bAw31RooTp1/9aE=;
 b=K1ZHosEZoz9tKEb4ZtvEiu5I9COHbZQUNZ1Ax+1a5WQiczG05QpKkNOLMfVNUM1Rnp9eQB2Jb
 JoGBo9hTltABbyO7ZRyv1Z6BAYpNMwHkC3qN2PPCiAON80fYIPGOBbE
X-Developer-Key: i=daniel.palmer@sony.com; a=ed25519;
 pk=dbwvNAF3zvjUZOTEPBh6uYWrBnOi7OPuXkoDcmmS8aY=
X-Endpoint-Received: by B4 Relay for daniel.palmer@sony.com/20250610 with auth_id=430
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Seems like someone hit 'c' when they meant to hit 'd'.

Signed-off-by: Daniel Palmer <daniel.palmer@sony.com>
---
 drivers/video/fbdev/core/Kconfig | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/video/fbdev/core/Kconfig b/drivers/video/fbdev/core/Kconfig
index 4abe12db7594..413cbfac569d 100644
--- a/drivers/video/fbdev/core/Kconfig
+++ b/drivers/video/fbdev/core/Kconfig
@@ -31,7 +31,7 @@ config FB_DEVICE
 	default FB
 	help
 	  Say Y here if you want the legacy /dev/fb* device file and
-	  interfaces within sysfs anc procfs. It is only required if you
+	  interfaces within sysfs and procfs. It is only required if you
 	  have userspace programs that depend on fbdev for graphics output.
 	  This does not affect the framebuffer console. If unsure, say N.
 

---
base-commit: e04c78d86a9699d136910cfc0bdcf01087e3267e
change-id: 20250725-fbdev-typo-90045c2b1dce

Best regards,
-- 
Daniel Palmer <daniel.palmer@sony.com>

