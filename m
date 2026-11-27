From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Fri, 27 Nov 2026 22:03:31 +0300
Subject: [PATCH] i2c: cs75xx: Disable the controller before releasing its
 IRQ
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-i2c-cs75xx-irq-teardown-v1-1-f6acd781af04@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQrCQAxA0auUrA00gWnBq4iLMY0aF1NNqg6U3
 t1Rl2/x/wqhbhqw71ZwfVnYXBpo14Fcc7ko2tQM3PNAxCMaC0qMqVY0f+Ci2af5XTDlfmCVRIk
 YWn13PVv9nQ/Hv+N5uqks3x1s2wdEWE97ewAAAA==
X-Change-ID: 20261127-i2c-cs75xx-irq-teardown-5a062ec51512
To: Andi Shyti <andi.shyti@kernel.org>
Cc: linux-i2c@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795806210; l=2481;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=H8bWwANLWzhb+hTYvLCYBcRvBSWNfP9Xtsa2d31C1Nk=;
 b=qmgG547+jw6GW3bGVGWtiElxcn0Eg/+RbwUnQ8zCGD0lg1HRXszHaKksLpZWE8u8Abjn/nER4
 GxHNK5Wd9TrC1oldyPens+dZ/PQa64RtS3x+6C8T1R4qWLJ+wBOB89X
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Managed resources are released in reverse registration order. Registering
the disable action before the IRQ causes free_irq() to run while the
controller is still enabled during probe failure or driver removal.

Register the disable action after devm_request_irq() so that the adapter
is removed first, then the interrupt source is disabled, and finally the
handler is freed and synchronized before the clock and mapping disappear.
Disable the controller explicitly if requesting the IRQ fails.

Fixes: 3fdb0e8ef0d4 ("i2c: Add Cortina Systems CS75xx I2C controller driver")
Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
This is a focused follow-up to the driver accepted in i2c/i2c as
3fdb0e8ef0d4, rather than a reroll of the complete I2C series.

Move the managed disable action after the IRQ registration, and disable
the configured controller explicitly if requesting the IRQ fails. The
adapter is removed before the source is disabled, then free_irq() drains
any handler before the clock and register mapping are released.

The driver postimage matches the correction already compiled in native
ARM and OpenWrt 6.18.64 builds and installed on Almond+. Focused tests
using the actual cleanup source cover successful teardown, request_irq
failure, action-registration failure and adapter-registration failure.
No hardware fault injection is claimed.
---
 drivers/i2c/busses/i2c-cs75xx.c | 11 +++++++----
 1 file changed, 7 insertions(+), 4 deletions(-)

diff --git a/drivers/i2c/busses/i2c-cs75xx.c b/drivers/i2c/busses/i2c-cs75xx.c
index 49a14f27b..c5365448c 100644
--- a/drivers/i2c/busses/i2c-cs75xx.c
+++ b/drivers/i2c/busses/i2c-cs75xx.c
@@ -344,12 +344,15 @@ static int cs75xx_i2c_probe(struct platform_device *pdev)
 	writel(0, i2c->base + CS75XX_I2C_IE);
 	writel(CS75XX_I2C_INT_DONE, i2c->base + CS75XX_I2C_INT);
 
-	ret = devm_add_action_or_reset(dev, cs75xx_i2c_disable, i2c);
-	if (ret)
-		return ret;
-
 	ret = devm_request_irq(dev, i2c->irq, cs75xx_i2c_isr, 0, dev_name(dev),
 			       i2c);
+	if (ret) {
+		cs75xx_i2c_disable(i2c);
+		return ret;
+	}
+
+	/* Quiesce the source before devres releases the interrupt handler. */
+	ret = devm_add_action_or_reset(dev, cs75xx_i2c_disable, i2c);
 	if (ret)
 		return ret;
 

---
base-commit: 3fdb0e8ef0d477ce4b9a9c5ebd370e64d7ae4ed8
change-id: 20261127-i2c-cs75xx-irq-teardown-5a062ec51512

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

