From: Carl Lee <carl.lee@amd.com>
Date: Wed, 04 Feb 2026 16:33:51 +0800
Subject: [PATCH] nfc: nxp-nci: remove interrupt trigger type
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260204-fc-nxp-nci-remove-interrupt-trigger-type-v1-1-3bde91593173@amd.com>
X-B4-Tracking: v=1; b=H4sIAG4Eg2kC/x2NQQqDMBAAvyJ7diEmpUq/UjxoXOMeXMMmiiL+v
 aHHgWHmhkTKlOBT3aB0cOJNCjR1BX4ZJBDyVBissW9jzQtnj3JGFM+otG5HESST6h4zZuUQSDF
 fkXBq285ZN7qxa6DkotLM53/17Z/nB0Gg9zl6AAAA
X-Change-ID: 20260204-fc-nxp-nci-remove-interrupt-trigger-type-d778323b3b81
To: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, carl.lee@amd.com, 
 peter.shen@amd.com, colin.huang2@amd.com
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770194040; l=1133;
 i=carl.lee@amd.com; s=20260203; h=from:subject:message-id;
 bh=S4f9MfSDtarUqVAH0McJX6bzbyZME7KFSQONWKA1FKQ=;
 b=kpvwuOZRaUjemIlIPFCMTW7vpbW0JUD/LrDbcg514SQKKMI40tTfdyIdYQKgh0Z56NMQvofGs
 co6KmX6FiEWBOEfien2vOMEhBLCiZNVJ/A2p6Bo35geoLGMTa/E5Iwn
X-Developer-Key: i=carl.lee@amd.com; a=ed25519;
 pk=pyq7QaQvoxMg806KVkRwpCbiah+7ncWr4MBpK1AEyjA=
X-Endpoint-Received: by B4 Relay for carl.lee@amd.com/20260203 with auth_id=623
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For NXP NCI devices (e.g. PN7150), the interrupt is level-triggered and
active high, not edge-triggered.

Using IRQF_TRIGGER_RISING in the driver can cause interrupts to fail
to trigger correctly.

Remove IRQF_TRIGGER_RISING and rely on the IRQ trigger type configured
via Device Tree.

Signed-off-by: Carl Lee <carl.lee@amd.com>
---
 drivers/nfc/nxp-nci/i2c.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/nfc/nxp-nci/i2c.c b/drivers/nfc/nxp-nci/i2c.c
index 049662ffdf97..6a5ce8ff91f0 100644
--- a/drivers/nfc/nxp-nci/i2c.c
+++ b/drivers/nfc/nxp-nci/i2c.c
@@ -305,7 +305,7 @@ static int nxp_nci_i2c_probe(struct i2c_client *client)
 
 	r = request_threaded_irq(client->irq, NULL,
 				 nxp_nci_i2c_irq_thread_fn,
-				 IRQF_TRIGGER_RISING | IRQF_ONESHOT,
+				 IRQF_ONESHOT,
 				 NXP_NCI_I2C_DRIVER_NAME, phy);
 	if (r < 0)
 		nfc_err(&client->dev, "Unable to register IRQ handler\n");

---
base-commit: 4c87cdd0328495759f6e9f9f4e1e53ef8032a76f
change-id: 20260204-fc-nxp-nci-remove-interrupt-trigger-type-d778323b3b81

Best regards,
-- 
Carl Lee <carl.lee@amd.com>

