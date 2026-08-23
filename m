From: David Heidelberg <david@ixit.cz>
Date: Sun, 23 Aug 2026 12:18:46 +0200
Subject: [PATCH] mfd: wcd934x: set DMA mask on parent to silence "DMA mask
 not set"
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260823-wcd-dma-v1-1-95e44a315ccf@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDCyNj3fLkFN2U3ETdpBQzI8PUVGNLCwtzJaDqgqLUtMwKsEnRsRB+cWl
 SVmpyCUi7Um0tACVF4qVrAAAA
X-Change-ID: 20260823-wcd-dma-bd621ee39887
To: Lee Jones <lee@kernel.org>, Thomas Tai <thomas.tai@oracle.com>, 
 Konrad Rzeszutek Wilk <konrad.wilk@oracle.com>
Cc: mfd@lists.linux.dev, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, stable@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1873; i=david@ixit.cz;
 h=from:subject:message-id; bh=+yZV0yAzUP//COgwea2L7HsDDH8oBkgszVtJRU6JO78=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqiskJtyAhDlPxeiHVZWm51nydba6sUveI5NDd6
 1VGzK6kJ+qJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaorJCQAKCRBgAj/E00kg
 cmTkEADEeY4NllOg/3iSQJ708Hp/0muay7InorawmJzkvi1Foivu8zScHDsfxuL09oxEl/q59iG
 s3BRCI9SZeSrA69UnAQnnnCuf/JE/Y1KmEO4ODvmjb0jU2T0987mu9QiNCNUm/5B9ajno3z4iCN
 K405jXYHiGU/LebT4RKDpKlaG3qmRRGgIudR27oLJkKSyG8QC0qEloge2WoGWEaPtsrqbQg5NzI
 6mfPIvg+dnKgTZ/Piz9cqVCPtBQiQFKnQ+R7suQ8VtqeDJQlLDyJyInHpvpwJyNvuifCpCFVn6g
 mKOKS0wYkUgE5gA7aAJh4eosXj7b+lL5PJ6cTYISuRBpQkTuIuRDXWOQnymSAmC8A0O0w8vssEF
 8aTMdcwx6XSzHr+gU9zIcMTEbLP5EMBXSXgC+tsqmBb0aGxk3vzOa/oMKgKbJLe/2SokI2tlxXa
 ZE2t4cOE5oF5iIL7tCyIBjRFDB0bmWmFbYAYFxhkXA6XS5hZjp44s3thrv3pU3TDmyWyJgGPzld
 puhLOv4n9EB2tPbUNFFCRoBXB823eeZCgXzxzJvYI295o8ndkbYhJhl6hiY+zcI4Cvweqetq+wN
 WxwP3b3p/h8izpKNYl6nu7CQzDE7Uwc1XOvWql2beM+OVA8l76EgSDcrS5/c2hWhA8IXIYBiruR
 0xhPPQH40bxRY7Q==
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
index 3c3080e8c8cf7..70ee13791d52b 100644
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
 
+	if (!dev->dma_mask) {
+		dev->dma_mask = &dev->coherent_dma_mask;
+		dev->coherent_dma_mask = DMA_BIT_MASK(32);
+	}
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

