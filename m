From: Carl Lee <carl.lee@amd.com>
Date: Thu, 05 Feb 2026 19:11:39 +0800
Subject: [PATCH v2] nfc: nxp-nci: remove interrupt trigger type
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260205-fc-nxp-nci-remove-interrupt-trigger-type-v2-1-79d2ed4a7e42@amd.com>
X-B4-Tracking: v=1; b=H4sIAOp6hGkC/52NQQ6CMBBFr0K6dgxtVcCV9zAsoB1gFpRmWhsI4
 e5WjuDy/fy8t4uATBjEs9gFY6JAi8ugLoUwU+dGBLKZhSrVo1TlDQYDbvXgDAHjvKR8cBGZPz5
 CZBpHZIibR7BVVWule93XUmSdZxxoPVPvNvNEIS68neUkf+sfkSRBgu4tNvLeaFnpVzfbq1lm0
 R7H8QVULrAt3gAAAA==
X-Change-ID: 20260204-fc-nxp-nci-remove-interrupt-trigger-type-d778323b3b81
To: Krzysztof Kozlowski <krzk@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, carl.lee@amd.com, 
 peter.shen@amd.com, colin.huang2@amd.com
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770289904; l=1554;
 i=carl.lee@amd.com; s=20260203; h=from:subject:message-id;
 bh=6cKyct/VkHp4Ohfqh26SnglO2MibPS/8UbUTT3sCa1U=;
 b=NnsLioUF8YJNdbbB9wQ/BjoGWcuoLJL4n+sH8aY91LxSbHLePZxwMVHiAmrMnK7jZRf6VFl3w
 VLb8qS58IQoDxY1HDePigdq/zOcncqba3ybJyyee2NOg+F+kF6n2uW6
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
This v2 of the series includes Krzysztof Kozlowski in the review list
for NXP-NCI NFC.

This series removes IRQF_TRIGGER_RISING in nxp-nci driver,
relying on the IRQ trigger type specified via Device Tree.
---
Changes in v2:
- Include Krzysztof Kozlowski in the review list for NXP-NCI NFC.
- Link to v1: https://lore.kernel.org/r/20260204-fc-nxp-nci-remove-interrupt-trigger-type-v1-1-3bde91593173@amd.com
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

