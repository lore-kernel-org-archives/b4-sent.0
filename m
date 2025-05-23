From: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
Date: Fri, 23 May 2025 09:39:20 +0800
Subject: [PATCH 3/5] power: supply: qcom_battmgr: Add resistance power
 supply property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250523-qcom_battmgr_update-v1-3-2bb6d4e0a56e@oss.qualcomm.com>
References: <20250523-qcom_battmgr_update-v1-0-2bb6d4e0a56e@oss.qualcomm.com>
In-Reply-To: <20250523-qcom_battmgr_update-v1-0-2bb6d4e0a56e@oss.qualcomm.com>
To: Sebastian Reichel <sre@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>
Cc: Subbaraman Narayanamurthy <subbaraman.narayanamurthy@oss.qualcomm.com>, 
 David Collins <david.collins@oss.qualcomm.com>, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 kernel@oss.qualcomm.com, Fenglin Wu <fenglin.wu@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747964381; l=2437;
 i=fenglin.wu@oss.qualcomm.com; s=20240327; h=from:subject:message-id;
 bh=0cVLEmmNpliBpNUD0QR9vZL+uf2t1nTBnEIcltQ8698=;
 b=jpqwx5MLqkI4ZFF269xLqE2xi+JC60fDH00wkb/t5d0qBQ6/tjXby2FafeOj6V5k/CQy0Wa5v
 B6qxFMyF8RjAfJcYinA8+y5gddd4hmPsueB1y78KNKJwyjrlW7desSF
X-Developer-Key: i=fenglin.wu@oss.qualcomm.com; a=ed25519;
 pk=BF8SA4IVDk8/EBCwlBehKtn2hp6kipuuAuDAHh9s+K4=
X-Endpoint-Received: by B4 Relay for fenglin.wu@oss.qualcomm.com/20240327 with auth_id=406
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add power supply property to get battery resistance from the battery
management firmware.

Signed-off-by: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
---
 drivers/power/supply/qcom_battmgr.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/drivers/power/supply/qcom_battmgr.c b/drivers/power/supply/qcom_battmgr.c
index fe27676fbc7cd12292caa6fb3b5b46a18c426e6d..bc521f60f67fa427cc03b51c44adaeb46ae746f5 100644
--- a/drivers/power/supply/qcom_battmgr.c
+++ b/drivers/power/supply/qcom_battmgr.c
@@ -2,6 +2,7 @@
 /*
  * Copyright (c) 2019-2020, The Linux Foundation. All rights reserved.
  * Copyright (c) 2022, Linaro Ltd
+ * Copyright (c) 2025 Qualcomm Innovation Center, Inc. All rights reserved.
  */
 #include <linux/auxiliary_bus.h>
 #include <linux/module.h>
@@ -254,6 +255,7 @@ struct qcom_battmgr_status {
 	unsigned int voltage_now;
 	unsigned int voltage_ocv;
 	unsigned int temperature;
+	unsigned int resistance;
 
 	unsigned int discharge_time;
 	unsigned int charge_time;
@@ -418,6 +420,7 @@ static const u8 sm8350_bat_prop_map[] = {
 	[POWER_SUPPLY_PROP_MODEL_NAME] = BATT_MODEL_NAME,
 	[POWER_SUPPLY_PROP_TIME_TO_FULL_AVG] = BATT_TTF_AVG,
 	[POWER_SUPPLY_PROP_TIME_TO_EMPTY_AVG] = BATT_TTE_AVG,
+	[POWER_SUPPLY_PROP_RESISTANCE] = BATT_RESISTANCE,
 	[POWER_SUPPLY_PROP_POWER_NOW] = BATT_POWER_NOW,
 };
 
@@ -582,6 +585,9 @@ static int qcom_battmgr_bat_get_property(struct power_supply *psy,
 	case POWER_SUPPLY_PROP_TEMP:
 		val->intval = battmgr->status.temperature;
 		break;
+	case POWER_SUPPLY_PROP_RESISTANCE:
+		val->intval = battmgr->status.resistance;
+		break;
 	case POWER_SUPPLY_PROP_TIME_TO_EMPTY_AVG:
 		val->intval = battmgr->status.discharge_time;
 		break;
@@ -665,6 +671,7 @@ static const enum power_supply_property sm8350_bat_props[] = {
 	POWER_SUPPLY_PROP_MODEL_NAME,
 	POWER_SUPPLY_PROP_TIME_TO_FULL_AVG,
 	POWER_SUPPLY_PROP_TIME_TO_EMPTY_AVG,
+	POWER_SUPPLY_PROP_RESISTANCE,
 	POWER_SUPPLY_PROP_POWER_NOW,
 };
 
@@ -1174,6 +1181,9 @@ static void qcom_battmgr_sm8350_callback(struct qcom_battmgr *battmgr,
 		case BATT_TTE_AVG:
 			battmgr->status.discharge_time = le32_to_cpu(resp->intval.value);
 			break;
+		case BATT_RESISTANCE:
+			battmgr->status.resistance = le32_to_cpu(resp->intval.value);
+			break;
 		case BATT_POWER_NOW:
 			battmgr->status.power_now = le32_to_cpu(resp->intval.value);
 			break;

-- 
2.34.1

