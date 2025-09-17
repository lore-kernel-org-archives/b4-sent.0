From: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
Date: Wed, 17 Sep 2025 18:15:17 +0800
Subject: [PATCH v5 4/9] power: supply: qcom_battmgr: Add state_of_health
 property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250917-qcom_battmgr_update-v5-4-270ade9ffe13@oss.qualcomm.com>
References: <20250917-qcom_battmgr_update-v5-0-270ade9ffe13@oss.qualcomm.com>
In-Reply-To: <20250917-qcom_battmgr_update-v5-0-270ade9ffe13@oss.qualcomm.com>
To: Sebastian Reichel <sre@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Cc: Subbaraman Narayanamurthy <subbaraman.narayanamurthy@oss.qualcomm.com>, 
 David Collins <david.collins@oss.qualcomm.com>, 
 =?utf-8?q?Gy=C3=B6rgy_Kurucz?= <me@kuruczgy.com>, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 kernel@oss.qualcomm.com, devicetree@vger.kernel.org, 
 linux-usb@vger.kernel.org, Fenglin Wu <fenglin.wu@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758104128; l=2199;
 i=fenglin.wu@oss.qualcomm.com; s=20240327; h=from:subject:message-id;
 bh=J+Tofx9OY3dW9voQAra7xP6gCfAfzWclJNIDuOa+XFI=;
 b=ngXgVYDJhqidf9rMnPZQg35NeTizCPuVsJQvmVrsTMvqWqmLmecbunugfRjnn1vcRyJVfL2Bp
 /y/dIla1UdNCp7e7l4nmfXD74OaSE7B9mFu8T3MV3+kRsigTTOd13Gk
X-Developer-Key: i=fenglin.wu@oss.qualcomm.com; a=ed25519;
 pk=BF8SA4IVDk8/EBCwlBehKtn2hp6kipuuAuDAHh9s+K4=
X-Endpoint-Received: by B4 Relay for fenglin.wu@oss.qualcomm.com/20240327 with auth_id=406
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add state_of_health property to read battery health percentage from
battery management firmware.

Signed-off-by: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
---
 drivers/power/supply/qcom_battmgr.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/drivers/power/supply/qcom_battmgr.c b/drivers/power/supply/qcom_battmgr.c
index 6026266907c9dfd902240d451a0d1c50fa5dbc59..8d66f4dc95e3c141788189799b6e371e293d1d54 100644
--- a/drivers/power/supply/qcom_battmgr.c
+++ b/drivers/power/supply/qcom_battmgr.c
@@ -256,6 +256,7 @@ struct qcom_battmgr_status {
 	unsigned int voltage_ocv;
 	unsigned int temperature;
 	unsigned int resistance;
+	unsigned int soh_percent;
 
 	unsigned int discharge_time;
 	unsigned int charge_time;
@@ -421,6 +422,7 @@ static const u8 sm8350_bat_prop_map[] = {
 	[POWER_SUPPLY_PROP_TIME_TO_FULL_AVG] = BATT_TTF_AVG,
 	[POWER_SUPPLY_PROP_TIME_TO_EMPTY_AVG] = BATT_TTE_AVG,
 	[POWER_SUPPLY_PROP_INTERNAL_RESISTANCE] = BATT_RESISTANCE,
+	[POWER_SUPPLY_PROP_STATE_OF_HEALTH] = BATT_SOH,
 	[POWER_SUPPLY_PROP_POWER_NOW] = BATT_POWER_NOW,
 };
 
@@ -588,6 +590,9 @@ static int qcom_battmgr_bat_get_property(struct power_supply *psy,
 	case POWER_SUPPLY_PROP_INTERNAL_RESISTANCE:
 		val->intval = battmgr->status.resistance;
 		break;
+	case POWER_SUPPLY_PROP_STATE_OF_HEALTH:
+		val->intval = battmgr->status.soh_percent;
+		break;
 	case POWER_SUPPLY_PROP_TIME_TO_EMPTY_AVG:
 		val->intval = battmgr->status.discharge_time;
 		break;
@@ -672,6 +677,7 @@ static const enum power_supply_property sm8350_bat_props[] = {
 	POWER_SUPPLY_PROP_TIME_TO_FULL_AVG,
 	POWER_SUPPLY_PROP_TIME_TO_EMPTY_AVG,
 	POWER_SUPPLY_PROP_INTERNAL_RESISTANCE,
+	POWER_SUPPLY_PROP_STATE_OF_HEALTH,
 	POWER_SUPPLY_PROP_POWER_NOW,
 };
 
@@ -1141,6 +1147,9 @@ static void qcom_battmgr_sm8350_callback(struct qcom_battmgr *battmgr,
 		case BATT_CAPACITY:
 			battmgr->status.percent = le32_to_cpu(resp->intval.value) / 100;
 			break;
+		case BATT_SOH:
+			battmgr->status.soh_percent = le32_to_cpu(resp->intval.value);
+			break;
 		case BATT_VOLT_OCV:
 			battmgr->status.voltage_ocv = le32_to_cpu(resp->intval.value);
 			break;

-- 
2.34.1

