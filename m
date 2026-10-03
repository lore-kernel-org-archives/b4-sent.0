From: Fabricio Akio <fabricioakio@gmail.com>
Date: Sat, 03 Oct 2026 16:45:22 -0300
Subject: [PATCH 2/4] power: supply: qcom_smbx: report charger state changes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261003-qcom-smbx-chg-state-change-v1-2-fffaef446932@gmail.com>
References: <20261003-qcom-smbx-chg-state-change-v1-0-fffaef446932@gmail.com>
In-Reply-To: <20261003-qcom-smbx-chg-state-change-v1-0-fffaef446932@gmail.com>
To: Casey Connolly <casey.connolly@linaro.org>, 
 Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Robin Snyders <robin@snyders.xyz>, David Heidelberg <david@ixit.cz>, 
 phone-devel@vger.kernel.org, Richard Acayan <mailingradian@gmail.com>, 
 linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791056720; l=1869;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=mpUf1RzVaBKlKxheQ+DSBomKvGODFWLew/V/Uw/UXeA=;
 b=koB/E7NznvJGzmAjNhPhr9v+r/QMVbWuCoPbapD9kH4RQJ+6njuatmj1jpYeGLv2F258zqoZu
 j75NSHx0sw/C9UZh/moZBJkHuZ/vkMQ2b+7/fMvLsAwA2N5puBhdK2b
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Nothing notifies consumers when the charging state changes on its own,
as when a charge completes, so they can keep a stale status.

Request the chg-state-change interrupt when the device tree provides
it, and notify consumers when it fires.

Fixes: 8648aeb5d7b7 ("power: supply: add Qualcomm PMI8998 SMB2 Charger driver")
Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
 drivers/power/supply/qcom_smbx.c | 24 ++++++++++++++++++++++++
 1 file changed, 24 insertions(+)

diff --git a/drivers/power/supply/qcom_smbx.c b/drivers/power/supply/qcom_smbx.c
index f5557b8cc92a..3738eb8638bc 100644
--- a/drivers/power/supply/qcom_smbx.c
+++ b/drivers/power/supply/qcom_smbx.c
@@ -762,6 +762,15 @@ static irqreturn_t smb_handle_usb_icl_change(int irq, void *data)
 	return IRQ_HANDLED;
 }
 
+static irqreturn_t smb_handle_chg_state_change(int irq, void *data)
+{
+	struct smb_chip *chip = data;
+
+	power_supply_changed(chip->chg_psy);
+
+	return IRQ_HANDLED;
+}
+
 static irqreturn_t smb_handle_wdog_bark(int irq, void *data)
 {
 	struct smb_chip *chip = data;
@@ -1078,6 +1087,21 @@ static int smb_probe(struct platform_device *pdev)
 	if (rc < 0)
 		return rc;
 
+	/* Optional: not every device tree lists it */
+	irq = platform_get_irq_byname_optional(pdev, "chg-state-change");
+	if (irq > 0) {
+		rc = devm_request_threaded_irq(chip->dev, irq, NULL,
+					       smb_handle_chg_state_change,
+					       IRQF_ONESHOT, "chg-state-change",
+					       chip);
+		if (rc < 0)
+			return dev_err_probe(chip->dev, rc,
+					     "Couldn't request irq chg-state-change\n");
+	} else if (irq != -ENXIO) {
+		return dev_err_probe(chip->dev, irq,
+				     "Couldn't get irq chg-state-change\n");
+	}
+
 	devm_device_init_wakeup(chip->dev);
 
 	rc = devm_pm_set_wake_irq(chip->dev, chip->cable_irq);

-- 
2.55.0

