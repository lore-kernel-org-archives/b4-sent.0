From: David Heidelberg <david@ixit.cz>
Date: Thu, 03 Sep 2026 17:21:43 +0200
Subject: [PATCH v3 2/2] mfd: wcd934x: Set DMA mask on parent to silence
 "DMA mask not set"
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260903-wcd-dma-v3-2-d3920c6563c4@ixit.cz>
References: <20260903-wcd-dma-v3-0-d3920c6563c4@ixit.cz>
In-Reply-To: <20260903-wcd-dma-v3-0-d3920c6563c4@ixit.cz>
To: Lee Jones <lee@kernel.org>, Thomas Tai <thomas.tai@oracle.com>, 
 Konrad Rzeszutek Wilk <konrad.wilk@oracle.com>, 
 Krzysztof Kozlowski <krzk@kernel.org>
Cc: mfd@lists.linux.dev, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1747; i=david@ixit.cz;
 h=from:subject:message-id; bh=+jf79yN1zUgXzjDmHs7E5jVLsQgShz2xeoJgQRyV0nk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqmZCGC74jkKcRqYI+KIpkzQzzouBxogzrGouI4
 Bg7xHzj2tyJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCapmQhgAKCRBgAj/E00kg
 chW0D/0dO90yGzd+dl3Bak97oiqfv3C7BL9qT93cMbjpaFs6Pq8ViK/aR1Q1nTWzss5kuZqT/p0
 w0q7a0N+zz/kD42zamGCY+DElJ5OxIz7cWl76rkEfAm2/ACm1f62j1M9j6t9UgC9lq0o9QGFb2m
 oU11VHG6kS/fi9f3aquwSCVGQwzjcBZhZH7DbN8FQMT64js6yevWGmqo11/eovaIrxgM6Ypygfz
 OjdhQItSbRYLn2yiHwWuUWR/WaP11Kn8Lc8m5iZvjcPquK/wt4PC3oGTgx6cjUn0VGdZXfNO3KO
 fsVaPLUSDuCGxkAck+BNa0Z7Bdfw5P4Ftj6KnVJUEKdtU4HuX5IUnoYjrICrc1+irvv3f0AryYG
 w9cHY3XFUZy6wv9bmabWT8czAf0lEGl0LTJtKoREaVH0vWkEnCDYZVjIRMG3zBtL0ts9hgfbzwJ
 p09Snc1+Dc+3c9jY1e0K8/oWDfD9ko5g0FkH3ZVxqoj9+RI/Kz50ttf1qKMuxRXl/SAhHC5+74V
 rF0e8a2+tvYyfAlxeHLLvSGVGX77Ky0jF2GfcN1DNbqfQznUcR3fQ4UC2tY+4k9PPhoMrHRftsr
 Q9gRzHyAv5caEQr4Pkk6DyeQaV+WXTkkl5AeR/kiWZVZTWlYsJSPjqtGgWjptA/80DhOGC+qXC0
 IpamZC5Jm3DOk8A==
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
 drivers/mfd/wcd934x.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/mfd/wcd934x.c b/drivers/mfd/wcd934x.c
index 3a939e7ad3da5..fc17c39791301 100644
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
 		return dev_err_probe(dev, ddata->irq,
 				     "Failed to get IRQ\n");

-- 
2.55.0

