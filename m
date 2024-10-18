From: Abdelrahman Youssef <abdelrahmanyossef12@gmail.com>
Date: Fri, 18 Oct 2024 14:45:55 +0300
Subject: [PATCH v2 1/2] include: Include <linux/math.h> to resolve implicit
 declaration of do_div()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241018-errors_fixes-v2-1-7f49d5a0087b@gmail.com>
References: <20241018-errors_fixes-v2-0-7f49d5a0087b@gmail.com>
In-Reply-To: <20241018-errors_fixes-v2-0-7f49d5a0087b@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Abdelrahman Youssef <abdelrahmanyossef12@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729251992; l=635;
 i=abdelrahmanyossef12@gmail.com; s=20241017; h=from:subject:message-id;
 bh=Rb70qzcuQUIaMnaJEd4Gx4jHBmI+WLf8+wqc2p3rTjA=;
 b=5qdHq8blmCqll3bHxGNYSM5wEFc3njlwl+Ayrz9H3hedGAyjB32/Wi/8ILWzMnvhkNWqrWnvF
 GNkb9vIY15CDIFvNvbCj5TfJqadQepl09a8nv1/VEkoexdrHBle67nH
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

-- 
2.43.0

