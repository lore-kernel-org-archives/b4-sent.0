From: Carl Lee <carl.lee@amd.com>
Date: Sat, 16 May 2026 19:55:18 +0800
Subject: [PATCH v3] nfc: nxp-nci: i2c: use rising-edge IRQ on ACPI systems
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260516-nfc-nxp-nci-i2c-restore-irq-trigger-fallback-v3-1-37ba4b6e9086@amd.com>
X-B4-Tracking: v=1; b=H4sIACVbCGoC/52NzQ6CMBAGX4X07Jp2W0E9+R7GQ+0PbISChRAM4
 d0tXPSqx9nsNzOz3kVyPTtnM4tupJ7akEDuMmYqHUoHZBMz5JhzKQQEbyBMHQRDQGggun5oY3q
 LTxgilaWL4HVd37V5gLH6pPAguck5S8ouOk/TlrveEle0jl9bfRTr9c/QKEDAySEvhFJC2OKiG
 7s3bcPWzIjfavxRjUktc5Tq6AuvJf+ol2V5AyxLRqVBAQAA
X-Change-ID: 20260311-nfc-nxp-nci-i2c-restore-irq-trigger-fallback-cda942530c60
To: netdev@vger.kernel.org, linux-kernel@vger.kernel.org
Cc: Carl Lee <carl.lee@amd.com>, krzk@kernel.org, carl.lee@amd.com, 
 peter.shen@amd.com, colin.huang2@amd.com, kuba@kernel.org, david@ixit.cz, 
 luca.stefani.ge1@gmail.com, brgl@kernel.org, mpearson@squebb.ca
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778932520; l=3257;
 i=carl.lee@amd.com; s=20260203; h=from:subject:message-id;
 bh=AMSt9loXPyaoOpf5Py15SrUAJJFo8zGMLjoVxukd9fM=;
 b=e8EQLMWG6SkcKINegth5pIbCvRerCIZ38zgG62J9x+VNmzI8PCoOO/6oiL+tPg0EpWcZkk0Nm
 DACZRtwbQc7BCNz+cmTy412m4yDEbV7F+7D9KVfqmuIGFDlula/QlE3
X-Developer-Key: i=carl.lee@amd.com; a=ed25519;
 pk=pyq7QaQvoxMg806KVkRwpCbiah+7ncWr4MBpK1AEyjA=
X-Endpoint-Received: by B4 Relay for carl.lee@amd.com/20260203 with auth_id=623
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some ACPI-based platforms report incorrect IRQ trigger types (e.g.
IRQF_TRIGGER_HIGH), which can lead to interrupt storms.

Use the historically working rising-edge trigger on ACPI systems to
avoid this regression.

Device Tree-based systems continue to use the firmware-provided
trigger type.

Signed-off-by: Carl Lee <carl.lee@amd.com>
---
Some ACPI-based platforms report incorrect IRQ trigger types,
which can lead to interrupt storms.

Use rising-edge IRQ on ACPI systems to avoid this regression,
while keeping firmware-provided trigger types on non-ACPI systems.

Cc: netdev@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: krzk@kernel.org
Cc: carl.lee@amd.com
Cc: peter.shen@amd.com
Cc: colin.huang2@amd.com
Cc: kuba@kernel.org
Cc: david@ixit.cz
Cc: luca.stefani.ge1@gmail.com
Cc: brgl@kernel.org
Cc: mpearson@squebb.ca
---
Changes in v3:
- Use rising-edge IRQ on ACPI systems to avoid interrupt storms
- Keep using firmware-provided trigger type on non-ACPI systems
- Refine commit message to focus on regression on ACPI platforms
- Link to v2: https://lore.kernel.org/r/20260312-nfc-nxp-nci-i2c-restore-irq-trigger-fallback-v2-1-362348f7fa30@amd.com

Changes in v2:
- Add missing <linux/irq.h> include for irq_get_trigger_type().
- Link to v1: https://lore.kernel.org/r/20260311-nfc-nxp-nci-i2c-restore-irq-trigger-fallback-v1-1-9e20714411d7@amd.com
---
 drivers/nfc/nxp-nci/i2c.c | 21 ++++++++++++++++++++-
 1 file changed, 20 insertions(+), 1 deletion(-)

diff --git a/drivers/nfc/nxp-nci/i2c.c b/drivers/nfc/nxp-nci/i2c.c
index 6a5ce8ff91f0..266dc231c47d 100644
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
@@ -267,6 +268,7 @@ static int nxp_nci_i2c_probe(struct i2c_client *client)
 {
 	struct device *dev = &client->dev;
 	struct nxp_nci_i2c_phy *phy;
+	unsigned long irqflags;
 	int r;
 
 	if (!i2c_check_functionality(client->adapter, I2C_FUNC_I2C)) {
@@ -303,9 +305,26 @@ static int nxp_nci_i2c_probe(struct i2c_client *client)
 	if (r < 0)
 		return r;
 
+	/*
+	 * ACPI platforms may report incorrect IRQ trigger types
+	 * (e.g. level-high), which can lead to interrupt storms.
+	 *
+	 * Use the historically stable rising-edge trigger for ACPI devices.
+	 *
+	 * On non-ACPI systems (e.g. Device Tree), prefer the firmware-
+	 * provided trigger type, falling back to rising-edge if not set.
+	 */
+	if (ACPI_COMPANION(dev)) {
+		irqflags = IRQF_TRIGGER_RISING;
+	} else {
+		irqflags = irq_get_trigger_type(client->irq);
+		if (!irqflags)
+			irqflags = IRQF_TRIGGER_RISING;
+	}
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

