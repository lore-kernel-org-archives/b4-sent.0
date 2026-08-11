From: Robin Snyders <robin@snyders.xyz>
Date: Wed, 12 Aug 2026 01:29:59 +0200
Subject: [PATCH 2/5] power: supply: qcom_smbx: test battery health status
 bits
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260812-qcom-smbx-fixes-v1-2-eb48246be599@snyders.xyz>
References: <20260812-qcom-smbx-fixes-v1-0-eb48246be599@snyders.xyz>
In-Reply-To: <20260812-qcom-smbx-fixes-v1-0-eb48246be599@snyders.xyz>
To: Casey Connolly <casey.connolly@linaro.org>, 
 Sebastian Reichel <sre@kernel.org>
Cc: Robin Snyders <robin@snyders.xyz>, linux-arm-msm@vger.kernel.org, 
 linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786491008; l=1862;
 i=robin@snyders.xyz; s=default; h=from:subject:message-id;
 bh=pib+eZmrfk0+6cRSQ4e+JEOtgsEfLbNvhWGtFGr9m90=;
 b=w/5tI2HuuIkwX3Q6/U4R7y/mIW6GutHQBKyGhxnzi4Tfe6EaJuJoXxpbFLvQec1QcQsPCAqEG
 g8z1kmplFtpAmAxvgRKv4b5ZXUMH90WQp/O3vDA3qvyiuHtoST8zalH
X-Developer-Key: i=robin@snyders.xyz; a=ed25519;
 pk=Mdk5dNn+Tkcy7BWexDxBLR/s1BNz8WdqDPnr3qtYBIU=
X-Endpoint-Received: by B4 Relay for robin@snyders.xyz/default with auth_id=938
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

BATTERY_CHARGER_STATUS_2 contains independent status and fault bits.
Switching on the complete register only recognizes a fault when it is the
sole asserted bit, and can report a healthy battery when another status
bit is set at the same time.

Test the relevant fault bits in priority order, matching the Qualcomm
downstream driver handling.

Fixes: 8648aeb5d7b7 ("power: supply: add Qualcomm PMI8998 SMB2 Charger driver")
Cc: stable@vger.kernel.org
Signed-off-by: Robin Snyders <robin@snyders.xyz>
---
 drivers/power/supply/qcom_smbx.c | 22 ++++++++--------------
 1 file changed, 8 insertions(+), 14 deletions(-)

diff --git a/drivers/power/supply/qcom_smbx.c b/drivers/power/supply/qcom_smbx.c
index e6f2328f295c7..0e50d81aefc2a 100644
--- a/drivers/power/supply/qcom_smbx.c
+++ b/drivers/power/supply/qcom_smbx.c
@@ -632,26 +632,20 @@ static int smb_get_prop_health(struct smb_chip *chip, int *val)
 		return rc;
 	}
 
-	switch (stat) {
-	case CHARGER_ERROR_STATUS_BAT_OV_BIT:
+	if (stat & CHARGER_ERROR_STATUS_BAT_OV_BIT)
 		*val = POWER_SUPPLY_HEALTH_OVERVOLTAGE;
-		return 0;
-	case BAT_TEMP_STATUS_TOO_COLD_BIT:
+	else if (stat & BAT_TEMP_STATUS_TOO_COLD_BIT)
 		*val = POWER_SUPPLY_HEALTH_COLD;
-		return 0;
-	case BAT_TEMP_STATUS_TOO_HOT_BIT:
+	else if (stat & BAT_TEMP_STATUS_TOO_HOT_BIT)
 		*val = POWER_SUPPLY_HEALTH_OVERHEAT;
-		return 0;
-	case BAT_TEMP_STATUS_COLD_SOFT_LIMIT_BIT:
+	else if (stat & BAT_TEMP_STATUS_COLD_SOFT_LIMIT_BIT)
 		*val = POWER_SUPPLY_HEALTH_COOL;
-		return 0;
-	case BAT_TEMP_STATUS_HOT_SOFT_LIMIT_BIT:
+	else if (stat & BAT_TEMP_STATUS_HOT_SOFT_LIMIT_BIT)
 		*val = POWER_SUPPLY_HEALTH_WARM;
-		return 0;
-	default:
+	else
 		*val = POWER_SUPPLY_HEALTH_GOOD;
-		return 0;
-	}
+
+	return 0;
 }
 
 static int smb_get_property(struct power_supply *psy,

-- 
2.54.0

