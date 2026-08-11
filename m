From: Robin Snyders <robin@snyders.xyz>
Date: Tue, 11 Aug 2026 22:35:06 +0200
Subject: [PATCH 3/3] power: supply: qcom_smbx: program AICL rerun time
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-submit-qcom-smbx-send-v1-v1-3-feec6cfa123a@snyders.xyz>
References: <20260811-submit-qcom-smbx-send-v1-v1-0-feec6cfa123a@snyders.xyz>
In-Reply-To: <20260811-submit-qcom-smbx-send-v1-v1-0-feec6cfa123a@snyders.xyz>
To: Casey Connolly <casey.connolly@linaro.org>, 
 Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Robin Snyders <robin@snyders.xyz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786480511; l=1368;
 i=robin@snyders.xyz; s=default; h=from:subject:message-id;
 bh=KqL6fkAKus1VfXlFaQFE4bSn/EnAURWbYSu61RmyM78=;
 b=O/bMHtYUWLUrjPRkO7HCQ0p5EH47F5WETJrS8QTvN+SIi3L34vlRH8pxEuNWoTDO+iNNtikJH
 GLuD8HZHzDOAo/OQ6e7nNYpywWBvPpvkeoVoFDmSIBNCIz7rJO3pVt5
X-Developer-Key: i=robin@snyders.xyz; a=ed25519;
 pk=Mdk5dNn+Tkcy7BWexDxBLR/s1BNz8WdqDPnr3qtYBIU=
X-Endpoint-Received: by B4 Relay for robin@snyders.xyz/default with auth_id=938
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Casey Connolly <casey.connolly@linaro.org>

The bootloader-provided automatic input current limit rerun interval is
not a stable software interface. Program a consistent three-second
interval during probe. This is required at least on SMB5 hardware.

Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Signed-off-by: Robin Snyders <robin@snyders.xyz>
---
 drivers/power/supply/qcom_smbx.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/drivers/power/supply/qcom_smbx.c b/drivers/power/supply/qcom_smbx.c
index 09d9e0f95cb5..9e3e240b6813 100644
--- a/drivers/power/supply/qcom_smbx.c
+++ b/drivers/power/supply/qcom_smbx.c
@@ -374,6 +374,7 @@ enum smb_generation {
 
 #define AICL_RERUN_TIME_CFG				0x661
 #define AICL_RERUN_TIME_MASK				GENMASK(1, 0)
+#define AICL_RERUN_TIME_3_SECS				0
 
 #define STAT_CFG					0x690
 #define STAT_SW_OVERRIDE_VALUE_BIT			BIT(7)
@@ -1384,6 +1385,14 @@ static int smb_probe(struct platform_device *pdev)
 
 	platform_set_drvdata(pdev, chip);
 
+	rc = regmap_write_bits(chip->regmap,
+			       chip->base + AICL_RERUN_TIME_CFG,
+			       AICL_RERUN_TIME_MASK,
+			       AICL_RERUN_TIME_3_SECS);
+	if (rc < 0)
+		return dev_err_probe(chip->dev, rc,
+				     "could not set AICL rerun time\n");
+
 	if (chip->gen == SMB5) {
 		rc = regmap_update_bits(chip->regmap,
 					chip->base + CHARGING_ENABLE_CMD,

-- 
2.54.0

