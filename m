From: Abdelrahman Youssef <abdelrahmanyossef12@gmail.com>
Date: Thu, 17 Oct 2024 02:47:04 +0300
Subject: [PATCH] include: Include <linux/math.h> to resolve implicit
 declaration of do_div()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241017-errors_fixes-v1-1-4c4d1a2c124d@gmail.com>
X-B4-Tracking: v=1; b=H4sIAHdQEGcC/x3LTQqAIBBA4avIrBNULKWrREQ/U81GYwYikO6et
 Px4vAKCTCjQqwKMNwnlVGEbBes5pwM1bdXgjPPW2KCRObNMOz0oOlrnY2jbJXYe6nIx/qEew/i
 +H3enpCZeAAAA
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>, a.fatoum@barebox.org
Cc: Abdelrahman Youssef <abdelrahmanyossef12@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729122427; l=804;
 i=abdelrahmanyossef12@gmail.com; s=20241017; h=from:subject:message-id;
 bh=SL4Jnbv0eQHh33Eqw+TV7qtnrard+veW5iL6Gj6kRdk=;
 b=6w4Lbv/50gpfajdS91lbxehqvkajt1Rg0hHNxutXa2l9eUSueN5eQqs/F6B3/qjZrpdzeQp4e
 0Il7sqc3r0/CseTe80r1z1P9j2yn4N5UWZc5p+wHciVHnkwN3/vUnP9
X-Developer-Key: i=abdelrahmanyossef12@gmail.com; a=ed25519;
 pk=ayjFVDSRo1qKm+PGih8rsNvcMQvJ4ROQWuZWrYU8ujc=
X-Endpoint-Received: by B4 Relay for abdelrahmanyossef12@gmail.com/20241017 with auth_id=251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

I was testing barebox with randconfig, so I got a warning (treated as an error) : implicit declaration of do_div().
So <linux/math.h> needs to included.

Signed-off-by: Abdelrahman Youssef <abdelrahmanyossef12@gmail.com>
---
 include/linux/ktime.h | 1 +
 1 file changed, 1 insertion(+)

diff --git a/include/linux/ktime.h b/include/linux/ktime.h
index ea368b8802..2b9a91d540 100644
--- a/include/linux/ktime.h
+++ b/include/linux/ktime.h
@@ -21,6 +21,7 @@
 #ifndef _LINUX_KTIME_H
 #define _LINUX_KTIME_H
 
+#include <linux/math.h>
 #include <linux/time.h>
 #include <clock.h>
 #include <linux/bug.h>

---
base-commit: 9d47ff66c3892c5a6ddd4704993365a797fbeb68
change-id: 20241017-errors_fixes-81248755b864

Best regards,
-- 
Abdelrahman Youssef <abdelrahmanyossef12@gmail.com>

