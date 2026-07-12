From: Roman Vivchar <rva333@protonmail.com>
Date: Sun, 12 Jul 2026 09:26:36 +0300
Subject: [PATCH] iio: adc: mt6323: remove unused header
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260712-mt6323-adc-rm-header-v1-1-d96395d1a323@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBG4auQWTsJTLUYr2JYlPZHxgQ0UzQkh
 Ltbdfkt3tsowxSZLtVGhrdmfcwFzaGiOIb5BtZUTFKLr9tGeFq8E8chRbaJR4QEY39yaAecj5I
 ilfRpGHT9ba/d3/nV3xGX74v2/QMdiVPweAAAAA==
X-Change-ID: 20260712-mt6323-adc-rm-header-653e7fe842dc
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@baylibre.com>, 
 linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783837615; l=887;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=4AfmdH97pxmA7NGkEcbGJbdXmNTkYLKIx6MU+gfb9S8=;
 b=bb5KN3ABVq20sUCeCrgmAdVq9DUtWjUEDn0Z/GsgayOaPBYwEcqAUNghEqJiXpdx/neq9Zy3B
 gnnMxpawH8IDS8mtOv9ueHAQjFbRTGkbZY597sUts0aFjDyxrO6tuko
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove unused mod_devicetable.h header.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
A small cleanup for mt6323 auxadc driver.

This patch is based on top of iio/togreg branch.
---
 drivers/iio/adc/mt6323-auxadc.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/drivers/iio/adc/mt6323-auxadc.c b/drivers/iio/adc/mt6323-auxadc.c
index c450fb6f09cb..4f73ac42abb7 100644
--- a/drivers/iio/adc/mt6323-auxadc.c
+++ b/drivers/iio/adc/mt6323-auxadc.c
@@ -11,7 +11,6 @@
 #include <linux/cleanup.h>
 #include <linux/delay.h>
 #include <linux/iio/iio.h>
-#include <linux/mod_devicetable.h>
 #include <linux/module.h>
 #include <linux/mutex.h>
 #include <linux/platform_device.h>

---
base-commit: 2e2f2de7532cbbc2269de8be20ec709606c6e79b
change-id: 20260712-mt6323-adc-rm-header-653e7fe842dc

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

