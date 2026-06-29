From: Yu-Che Hsieh <yc_hsieh@aspeedtech.com>
Date: Mon, 29 Jun 2026 14:48:58 +0800
Subject: [PATCH 1/4] ipmi: bt-bmc: Use bitfield helpers for register
 definitions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260629-aspeed-bt-bmc-multichannel-v1-1-fc23ee337f7a@aspeedtech.com>
References: <20260629-aspeed-bt-bmc-multichannel-v1-0-fc23ee337f7a@aspeedtech.com>
In-Reply-To: <20260629-aspeed-bt-bmc-multichannel-v1-0-fc23ee337f7a@aspeedtech.com>
To: Corey Minyard <corey@minyard.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>
Cc: openipmi-developer@lists.sourceforge.net, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, Yu-Che Hsieh <yc_hsieh@aspeedtech.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782715772; l=3925;
 i=yc_hsieh@aspeedtech.com; s=20260629; h=from:subject:message-id;
 bh=HQw8rGJUsM6loLGP55U5cgMUUCPUOKcrGTqHI8TGeyw=;
 b=Mg57Y/Vn2ocHuNlZAZqksIQ0vRHfMU0JKXY0uL/knqv7c4ICD8NzGXdCdiFClN9xhS/Yheusc
 B5G083PbCmYD71NYrV8XV1FsDJV8yyawcP2dzWurZPGlGsjI8mi6jI7
X-Developer-Key: i=yc_hsieh@aspeedtech.com; a=ed25519;
 pk=kLxUeF7g6teciq79it9N3tYNgp3yCspZ+AHlYSnZ0gs=
X-Endpoint-Received: by B4 Relay for yc_hsieh@aspeedtech.com/20260629 with auth_id=844
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use BIT(), GENMASK(), and FIELD_PREP() for the BT register definitions

and register field programming.

This makes the register layout easier to read and prepares the driver

for later changes that need to program the BT_CR0 fields from device

configuration.

Signed-off-by: Yu-Che Hsieh <yc_hsieh@aspeedtech.com>
---
 drivers/char/ipmi/bt-bmc.c | 72 ++++++++++++++++++++++++----------------------
 1 file changed, 37 insertions(+), 35 deletions(-)

diff --git a/drivers/char/ipmi/bt-bmc.c b/drivers/char/ipmi/bt-bmc.c
index a179d4797011..f3c67272502f 100644
--- a/drivers/char/ipmi/bt-bmc.c
+++ b/drivers/char/ipmi/bt-bmc.c
@@ -15,6 +15,7 @@
 #include <linux/poll.h>
 #include <linux/sched.h>
 #include <linux/timer.h>
+#include <linux/bitfield.h>
 
 /*
  * This is a BMC device used to communicate to the host
@@ -24,33 +25,34 @@
 #define BT_IO_BASE	0xe4
 #define BT_IRQ		10
 
-#define BT_CR0		0x0
-#define   BT_CR0_IO_BASE		16
-#define   BT_CR0_IRQ			12
-#define   BT_CR0_EN_CLR_SLV_RDP		0x8
-#define   BT_CR0_EN_CLR_SLV_WRP		0x4
-#define   BT_CR0_ENABLE_IBT		0x1
-#define BT_CR1		0x4
-#define   BT_CR1_IRQ_H2B	0x01
-#define   BT_CR1_IRQ_HBUSY	0x40
-#define BT_CR2		0x8
-#define   BT_CR2_IRQ_H2B	0x01
-#define   BT_CR2_IRQ_HBUSY	0x40
-#define BT_CR3		0xc
-#define BT_CTRL		0x10
-#define   BT_CTRL_B_BUSY		0x80
-#define   BT_CTRL_H_BUSY		0x40
-#define   BT_CTRL_OEM0			0x20
-#define   BT_CTRL_SMS_ATN		0x10
-#define   BT_CTRL_B2H_ATN		0x08
-#define   BT_CTRL_H2B_ATN		0x04
-#define   BT_CTRL_CLR_RD_PTR		0x02
-#define   BT_CTRL_CLR_WR_PTR		0x01
-#define BT_BMC2HOST	0x14
-#define BT_INTMASK	0x18
-#define   BT_INTMASK_B2H_IRQEN		0x01
-#define   BT_INTMASK_B2H_IRQ		0x02
-#define   BT_INTMASK_BMC_HWRST		0x80
+#define BT_CR0			0x0
+#define   BT_CR0_IO_BASE	GENMASK(31, 16)
+#define   BT_CR0_SIRQ		GENMASK(15, 12)
+#define   BT_CR0_SIRQ_TYPE	GENMASK(11, 10)
+#define   BT_CR0_EN_CLR_SLV_RDP	BIT(3)
+#define   BT_CR0_EN_CLR_SLV_WRP	BIT(2)
+#define   BT_CR0_ENABLE_IBT	BIT(0)
+#define BT_CR1			0x4
+#define   BT_CR1_IRQ_EN_HBUSY	BIT(6)
+#define   BT_CR1_IRQ_EN_H2B	BIT(0)
+#define BT_CR2			0x8
+#define   BT_CR2_IRQ_STS_HBUSY	BIT(6)
+#define   BT_CR2_IRQ_STS_H2B	BIT(0)
+#define BT_CR3			0xc
+#define BT_CTRL			0x10
+#define   BT_CTRL_B_BUSY	BIT(7)
+#define   BT_CTRL_H_BUSY	BIT(6)
+#define   BT_CTRL_OEM0		BIT(5)
+#define   BT_CTRL_SMS_ATN	BIT(4)
+#define   BT_CTRL_B2H_ATN	BIT(3)
+#define   BT_CTRL_H2B_ATN	BIT(2)
+#define   BT_CTRL_CLR_RD_PTR	BIT(1)
+#define   BT_CTRL_CLR_WR_PTR	BIT(0)
+#define BT_BMC2HOST		0x14
+#define BT_INTMASK		0x18
+#define   BT_INTMASK_BMC_HWRST	BIT(7)
+#define   BT_INTMASK_B2H_IRQ	BIT(1)
+#define   BT_INTMASK_B2H_IRQEN	BIT(0)
 
 #define BT_BMC_BUFFER_SIZE 256
 
@@ -361,7 +363,7 @@ static irqreturn_t bt_bmc_irq(int irq, void *arg)
 
 	reg = readl(bt_bmc->base + BT_CR2);
 
-	reg &= BT_CR2_IRQ_H2B | BT_CR2_IRQ_HBUSY;
+	reg &= BT_CR2_IRQ_STS_H2B | BT_CR2_IRQ_STS_HBUSY;
 	if (!reg)
 		return IRQ_NONE;
 
@@ -398,7 +400,7 @@ static int bt_bmc_config_irq(struct bt_bmc *bt_bmc,
 	 * message to the BT buffer
 	 */
 	reg = readl(bt_bmc->base + BT_CR1);
-	reg |= BT_CR1_IRQ_H2B | BT_CR1_IRQ_HBUSY;
+	reg |= BT_CR1_IRQ_EN_H2B | BT_CR1_IRQ_EN_HBUSY;
 	writel(reg, bt_bmc->base + BT_CR1);
 
 	return 0;
@@ -447,12 +449,12 @@ static int bt_bmc_probe(struct platform_device *pdev)
 		add_timer(&bt_bmc->poll_timer);
 	}
 
-	writel((BT_IO_BASE << BT_CR0_IO_BASE) |
-		     (BT_IRQ << BT_CR0_IRQ) |
-		     BT_CR0_EN_CLR_SLV_RDP |
-		     BT_CR0_EN_CLR_SLV_WRP |
-		     BT_CR0_ENABLE_IBT,
-		bt_bmc->base + BT_CR0);
+	writel(FIELD_PREP(BT_CR0_IO_BASE, BT_IO_BASE) |
+	       FIELD_PREP(BT_CR0_SIRQ, BT_IRQ) |
+	       BT_CR0_EN_CLR_SLV_RDP |
+	       BT_CR0_EN_CLR_SLV_WRP |
+	       BT_CR0_ENABLE_IBT,
+	       bt_bmc->base + BT_CR0);
 
 	clr_b_busy(bt_bmc);
 

-- 
2.34.1

