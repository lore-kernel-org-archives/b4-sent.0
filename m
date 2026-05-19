From: Carl Lee <carl.lee@amd.com>
Date: Tue, 19 May 2026 17:32:53 +0800
Subject: [PATCH v5] nfc: nxp-nci: i2c: use rising-edge IRQ on ACPI systems
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260519-nfc-nxp-nci-i2c-restore-irq-trigger-fallback-v5-1-1a826cfbc128@amd.com>
X-B4-Tracking: v=1; b=H4sIAEQuDGoC/53NQW7DIBCF4atErDsVAxjjrnqPqgsMgzNqglMcW
 aki3704mzpLd/kQ8/13MVFhmsTb4S4KzTzxmOtoXg4iHH0eCDjWLZRUVmpEyClAvl0gBwZWAQp
 N17HUb+UbroWHgQokfzr1PnxBiL4zqtEyWCkqeSmU+PbIfXzWfeT1+OdRn3F9/WdoRkDoSMkWj
 UGM7bs/x9cwnsWamdWWVjtpVWltlTYutclr+UzrP7pBu5PWK9323vSWOunsM222dLeTNpV2jZP
 RETqJG3pZll9X+str9wEAAA==
X-Change-ID: 20260311-nfc-nxp-nci-i2c-restore-irq-trigger-fallback-cda942530c60
To: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, krzk@kernel.org, carl.lee@amd.com, 
 peter.shen@amd.com, colin.huang2@amd.com, kuba@kernel.org, david@ixit.cz, 
 luca.stefani.ge1@gmail.com, brgl@kernel.org, mpearson@squebb.ca
Cc: Mark Pearson <mpearson-lenovo@squebb.ca>, 
 Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779183174; l=3788;
 i=carl.lee@amd.com; s=20260203; h=from:subject:message-id;
 bh=AuJE8naMhN8VuJ0Xkt3hE9rAU8BuKShRUpf+0Ld/H78=;
 b=+nkcf9jeJ6vKQ5w1r1mJahWWd1a9UhYHs8pHNRr6OI7EWQ0ABp+xQ5psnJJzSPb06KK5Gdaqc
 m0/zySMbxyMA8Bphn4KY3AcN9/huCEfkvZaBPiR8o0HFZjkI0SHiQGS
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

Fixes: 57be33f85e36 ("nfc: nxp-nci: remove interrupt trigger type")
Cc: stable@vger.kernel.org

Tested-by: Luca Stefani <luca.stefani.ge1@gmail.com>
Tested-by: Mark Pearson <mpearson-lenovo@squebb.ca>
Tested-by: Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>
Reviewed-by: Mark Pearson <mpearson-lenovo@squebb.ca>
Reviewed-by: Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>
Signed-off-by: Carl Lee <carl.lee@amd.com>
---
Some ACPI-based platforms report incorrect IRQ trigger types,
which can lead to interrupt storms.

Use rising-edge IRQ on ACPI systems to avoid this regression,
while keeping firmware-provided trigger types on non-ACPI systems.
---
Changes in v5:
- Add missing Reviewed-by and Tested-by tags
- No functional changes
- Link to v4: https://lore.kernel.org/r/20260519-nfc-nxp-nci-i2c-restore-irq-trigger-fallback-v4-1-8580d8e18016@amd.com

Changes in v4:
- Add Fixes tag
- Add Cc: stable@vger.kernel.org
- Link to v3: https://lore.kernel.org/r/20260516-nfc-nxp-nci-i2c-restore-irq-trigger-fallback-v3-1-37ba4b6e9086@amd.com

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

