From: Carl Lee <carl.lee@amd.com>
Date: Thu, 12 Mar 2026 10:51:35 +0800
Subject: [PATCH v2] nfc: nxp-nci: i2c: restore IRQ trigger fallback
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260312-nfc-nxp-nci-i2c-restore-irq-trigger-fallback-v2-1-362348f7fa30@amd.com>
X-B4-Tracking: v=1; b=H4sIADYqsmkC/52NQQ6CMBBFr0K6dkxbEIIr72FY1GGAiVBwSgiGc
 HcLR3D5fv7/b1OBhCmoe7IpoYUDjz6CvSQKO+dbAq4jK6ttrlNjwDcIfp3AIwNbBKEwjxJr8oF
 ZuG1JoHF9/3L4BqxdmdlbqjHXKl5OQg2vp+5ZRe74GH9P+2KO9E/RYsBASVYXJsuMqYuHG+orj
 oOq9n3/ATh69MPmAAAA
X-Change-ID: 20260311-nfc-nxp-nci-i2c-restore-irq-trigger-fallback-cda942530c60
To: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, krzk@kernel.org, 
 carl.lee@amd.com, peter.shen@amd.com, colin.huang2@amd.com
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773283900; l=2295;
 i=carl.lee@amd.com; s=20260203; h=from:subject:message-id;
 bh=Vskvtr24ptKC6LYyjgFk7UbMzLWgrMQ1oXC18gOpBqg=;
 b=fgpkQ7Jh4s1/VnsV0T85utz6z5laWDnSt2PuOdU3vp1k+uGP182z4IZX4PHVblA73ft9IStqP
 KuuoJGKE75YAz8BeDX9JggIx2HF7/voaXQJujC7O15gzWyhgYroZP8I
X-Developer-Key: i=carl.lee@amd.com; a=ed25519;
 pk=pyq7QaQvoxMg806KVkRwpCbiah+7ncWr4MBpK1AEyjA=
X-Endpoint-Received: by B4 Relay for carl.lee@amd.com/20260203 with auth_id=623
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver previously relied on IRQF_TRIGGER_RISING when requesting
the interrupt. This was removed to rely on the trigger type provided
by firmware.

However, some platforms do not propagate the interrupt trigger type
to the IRQ descriptor, resulting in interrupts not being triggered.

Use the trigger type provided by firmware when available and fall
back to the historically used rising-edge trigger otherwise.

Signed-off-by: Carl Lee <carl.lee@amd.com>
---
Changes in v2:
- Add missing <linux/irq.h> include for irq_get_trigger_type().
- Link to v1: https://lore.kernel.org/r/20260311-nfc-nxp-nci-i2c-restore-irq-trigger-fallback-v1-1-9e20714411d7@amd.com
---
 drivers/nfc/nxp-nci/i2c.c | 12 +++++++++++-
 1 file changed, 11 insertions(+), 1 deletion(-)

diff --git a/drivers/nfc/nxp-nci/i2c.c b/drivers/nfc/nxp-nci/i2c.c
index 6a5ce8ff91f0..7aaab92c616c 100644
--- a/drivers/nfc/nxp-nci/i2c.c
+++ b/drivers/nfc/nxp-nci/i2c.c
@@ -16,6 +16,7 @@
 #include <linux/delay.h>
 #include <linux/i2c.h>
 #include <linux/interrupt.h>
+#include <linux/irq.h>
 #include <linux/module.h>
 #include <linux/nfc.h>
 #include <linux/gpio/consumer.h>
@@ -268,6 +269,7 @@ static int nxp_nci_i2c_probe(struct i2c_client *client)
 	struct device *dev = &client->dev;
 	struct nxp_nci_i2c_phy *phy;
 	int r;
+	unsigned long irqflags;
 
 	if (!i2c_check_functionality(client->adapter, I2C_FUNC_I2C)) {
 		nfc_err(&client->dev, "Need I2C_FUNC_I2C\n");
@@ -303,9 +305,17 @@ static int nxp_nci_i2c_probe(struct i2c_client *client)
 	if (r < 0)
 		return r;
 
+	/* Prefer the trigger type configured by firmware.
+	 * Some platforms do not provide it, so fall back to the
+	 * historically used rising-edge trigger.
+	 */
+	irqflags = irq_get_trigger_type(client->irq);
+	if (!irqflags)
+		irqflags = IRQF_TRIGGER_RISING;
+
 	r = request_threaded_irq(client->irq, NULL,
 				 nxp_nci_i2c_irq_thread_fn,
-				 IRQF_ONESHOT,
+				 irqflags | IRQF_ONESHOT,
 				 NXP_NCI_I2C_DRIVER_NAME, phy);
 	if (r < 0)
 		nfc_err(&client->dev, "Unable to register IRQ handler\n");

---
base-commit: 7109a2155340cc7b21f27e832ece6df03592f2e8
change-id: 20260311-nfc-nxp-nci-i2c-restore-irq-trigger-fallback-cda942530c60

Best regards,
-- 
Carl Lee <carl.lee@amd.com>

