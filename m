From: David Heidelberg <david@ixit.cz>
Date: Thu, 03 Sep 2026 16:42:05 +0200
Subject: [PATCH v2] mfd: wcd934x: set DMA mask on parent to silence "DMA
 mask not set"
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260903-wcd-dma-v2-1-189cff560a28@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2WNwQ6CMBAFf4Xs2RraAhZP/ofhAO0iayKQFitK+
 u+2ePQ4ybx5Gzi0hA7O2QYWPTmaxgjikIEe2vGGjExkELmociUke2nDzKNlnakER5S1UieI9my
 xp3UvXZsfu2d3R72keTIGcstk3/uV58n7r3rOOKtLLIpW8lLr/kIrLUf9gSaE8AWA+Hi8rgAAA
 A==
X-Change-ID: 20260823-wcd-dma-bd621ee39887
To: Lee Jones <lee@kernel.org>, Thomas Tai <thomas.tai@oracle.com>, 
 Konrad Rzeszutek Wilk <konrad.wilk@oracle.com>
Cc: mfd@lists.linux.dev, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, stable@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2047; i=david@ixit.cz;
 h=from:subject:message-id; bh=e4yf9rBUgYZaQShtQ8iyZHTpSxzA2vYCFo3z/MlZY7k=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqmYdDchD6Bd3Yl6ccNGcFCf3Ai6x3Lw/D3jIDW
 2YJIeSNfW2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCapmHQwAKCRBgAj/E00kg
 ckh8EACFNiPKRLYjFzbw35XOYudJEilTISA7Ga/oT9BQJkjVL96HVhfEuDvanfZ355eFGPQL3tg
 wQYAyXODxcVpS/KmkIbka04Ac+avStrbOHsHP9UbgZLaS9i9G2rhQuDOEMqo2mwRCFd5WnVzpEU
 ZKnk92+t2tpAPj2mbRERBkB2MEadp1rLei9r4jeMp87U5m7iPAlCGBLSv5MI5gGIKO0AHiJ5EKz
 OWm2SqAcJklTDxJO6cCfUdFbhXWPna5Bf4rlotAaQexTbLiYp9lv6wUaNkOWWU+so0HMW/YQUOD
 yYjzEU9bFxPywa7+xv/Wm9LMmCBSQQ5YQI999nLfm1F9/vauNphJ7JDSl7UpcT9Vgqlm0EglXJS
 9qkVGc+sHI+/dDaVwKgkDONY/XHn04ASfCTIZVDYDWxdTCCvhAwbxHaTI9wZiV8NaI/UmAsDvDo
 Pl/tQPcTp42DeJe4xN2olti6LZ7YwHd828Qvopuw08zvn2wsN4Jv70mcEnJ9KFwWip2ApFYP6fc
 v6ICk3KHfbgAQuaGyy4v0RxF40qKFfKEObApfeDg9c3V6eohDlYXO4BMlen2R/7VBeDiG3PaGRh
 pzE+cetTpYuDjEJFZulaaXZz4o7DzfJX0bcN+W825JJYh+R8BTLMIrpvaE10tcJDJBh0zwgT8CH
 wwjTx069DSMe2fA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The wcd934x MFD parent (a slim_device) never initializes its
dma_mask/coherent_dma_mask. When the DT-aware children pass through
of_dma_configure() this triggers the "DMA mask not set" warning for
each child.

Cc: stable@vger.kernel.org
Fixes: f959dcd6ddfd ("dma-direct: Fix potential NULL pointer dereference")
Assisted-by: tencent:hy3
Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v2:
- Use dma_coerce_mask_and_coherent. (Lee)
- Link to v1: https://patch.msgid.link/20260823-wcd-dma-v1-1-95e44a315ccf@ixit.cz
---
 drivers/mfd/wcd934x.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/mfd/wcd934x.c b/drivers/mfd/wcd934x.c
index 3c3080e8c8cf7..853edda9b6da7 100644
--- a/drivers/mfd/wcd934x.c
+++ b/drivers/mfd/wcd934x.c
@@ -1,12 +1,13 @@
 // SPDX-License-Identifier: GPL-2.0
 // Copyright (c) 2019, Linaro Limited
 
 #include <linux/clk.h>
+#include <linux/dma-mapping.h>
 #include <linux/gpio/consumer.h>
 #include <linux/interrupt.h>
 #include <linux/kernel.h>
 #include <linux/mfd/core.h>
 #include <linux/mfd/wcd934x/registers.h>
 #include <linux/mfd/wcd934x/wcd934x.h>
 #include <linux/module.h>
 #include <linux/of.h>
@@ -212,16 +213,21 @@ static int wcd934x_slim_status(struct slim_device *sdev,
 static int wcd934x_slim_probe(struct slim_device *sdev)
 {
 	struct device *dev = &sdev->dev;
 	struct device_node *np = dev->of_node;
 	struct wcd934x_ddata *ddata;
 	struct gpio_desc *reset_gpio;
 	int ret;
 
+	ret = dma_coerce_mask_and_coherent(dev, DMA_BIT_MASK(32));
+	if (ret)
+		return dev_err_probe(dev, ret,
+				     "Failed to set dma mask\n");
+
 	ddata = devm_kzalloc(dev, sizeof(*ddata), GFP_KERNEL);
 	if (!ddata)
 		return	-ENOMEM;
 
 	ddata->irq = of_irq_get(np, 0);
 	if (ddata->irq < 0)
 		return dev_err_probe(ddata->dev, ddata->irq,
 				     "Failed to get IRQ\n");

---
base-commit: 7079a12d7506b07fb53b54a664bfad5fa9b16d70
change-id: 20260823-wcd-dma-bd621ee39887

Best regards,
--  
David Heidelberg <david@ixit.cz>

