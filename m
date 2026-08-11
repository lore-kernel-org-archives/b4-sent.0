From: Robin Snyders <robin@snyders.xyz>
Date: Wed, 12 Aug 2026 01:30:02 +0200
Subject: [PATCH 5/5] power: supply: qcom_smbx: notify battery overvoltage
 recovery
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260812-qcom-smbx-fixes-v1-5-eb48246be599@snyders.xyz>
References: <20260812-qcom-smbx-fixes-v1-0-eb48246be599@snyders.xyz>
In-Reply-To: <20260812-qcom-smbx-fixes-v1-0-eb48246be599@snyders.xyz>
To: Casey Connolly <casey.connolly@linaro.org>, 
 Sebastian Reichel <sre@kernel.org>
Cc: Robin Snyders <robin@snyders.xyz>, linux-arm-msm@vger.kernel.org, 
 linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786491008; l=1644;
 i=robin@snyders.xyz; s=default; h=from:subject:message-id;
 bh=U5NNbxKVGqkekK9ViQGXFAmK/qusgcI2nUh+9IqA1SU=;
 b=jtO6+0+lZixYfh8+WaM38GISaisUrZaUD5Z+Re84+d+Gs8/4CMMAjTQGDS84TFFC4Z7Mhw1qe
 jBEMqh+Oyy8B9Lk6G1oXfEjJJd4kgNC9UH4dEXykmrZXevoo6jU/tyO
X-Developer-Key: i=robin@snyders.xyz; a=ed25519;
 pk=Mdk5dNn+Tkcy7BWexDxBLR/s1BNz8WdqDPnr3qtYBIU=
X-Endpoint-Received: by B4 Relay for robin@snyders.xyz/default with auth_id=938
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The battery-overvoltage IRQ is configured for both edges, but its handler
only notifies the power-supply core while the fault bit is asserted. The
falling edge therefore does not publish the recovered health and status.
The handler also ignores register-read failures before testing status.

Handle read errors, log only an asserted fault, and notify the
power-supply core after every successful edge read.

Fixes: 8648aeb5d7b7 ("power: supply: add Qualcomm PMI8998 SMB2 Charger driver")
Cc: stable@vger.kernel.org
Signed-off-by: Robin Snyders <robin@snyders.xyz>
---
 drivers/power/supply/qcom_smbx.c | 12 +++++++++---
 1 file changed, 9 insertions(+), 3 deletions(-)

diff --git a/drivers/power/supply/qcom_smbx.c b/drivers/power/supply/qcom_smbx.c
index 55ffe9857e494..f5557b8cc92ae 100644
--- a/drivers/power/supply/qcom_smbx.c
+++ b/drivers/power/supply/qcom_smbx.c
@@ -722,16 +722,22 @@ static irqreturn_t smb_handle_batt_overvoltage(int irq, void *data)
 {
 	struct smb_chip *chip = data;
 	unsigned int status;
+	int rc;
 
-	regmap_read(chip->regmap, chip->base + BATTERY_CHARGER_STATUS_2,
-		    &status);
+	rc = regmap_read(chip->regmap,
+			 chip->base + BATTERY_CHARGER_STATUS_2, &status);
+	if (rc < 0) {
+		dev_err(chip->dev, "Couldn't read charger status: %d\n", rc);
+		return IRQ_HANDLED;
+	}
 
 	if (status & CHARGER_ERROR_STATUS_BAT_OV_BIT) {
 		/* The hardware stops charging automatically */
 		dev_err(chip->dev, "battery overvoltage detected\n");
-		power_supply_changed(chip->chg_psy);
 	}
 
+	power_supply_changed(chip->chg_psy);
+
 	return IRQ_HANDLED;
 }
 

-- 
2.54.0

