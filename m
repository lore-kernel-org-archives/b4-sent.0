From: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
Date: Wed, 17 Sep 2025 18:15:16 +0800
Subject: [PATCH v5 3/9] power: supply: qcom_battmgr: Add resistance power
 supply property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250917-qcom_battmgr_update-v5-3-270ade9ffe13@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758104128; l=2467;
 i=fenglin.wu@oss.qualcomm.com; s=20240327; h=from:subject:message-id;
 bh=qFMmKwGjAYDQaWpF4fZvL+OO1QDC0goTFTZPyo/iQsQ=;
 b=LGtrOwVCH8GU29tX00F/p/pfnmJCYFnJuLa10sNpEAu4DGcrhmuJeOOIrrRWOo7NELg77Lw5F
 KjkQuhdXvC8AFnngZWuTUy6bgxJON+fh1t+8avcuvqc0RP2tG7uyra6
X-Developer-Key: i=fenglin.wu@oss.qualcomm.com; a=ed25519;
 pk=BF8SA4IVDk8/EBCwlBehKtn2hp6kipuuAuDAHh9s+K4=
X-Endpoint-Received: by B4 Relay for fenglin.wu@oss.qualcomm.com/20240327 with auth_id=406
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add power supply property to get battery internal resistance from
the battery management firmware.

Signed-off-by: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
---
 drivers/power/supply/qcom_battmgr.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/drivers/power/supply/qcom_battmgr.c b/drivers/power/supply/qcom_battmgr.c
index fe27676fbc7cd12292caa6fb3b5b46a18c426e6d..6026266907c9dfd902240d451a0d1c50fa5dbc59 100644
--- a/drivers/power/supply/qcom_battmgr.c
+++ b/drivers/power/supply/qcom_battmgr.c
@@ -2,6 +2,7 @@
 /*
  * Copyright (c) 2019-2020, The Linux Foundation. All rights reserved.
  * Copyright (c) 2022, Linaro Ltd
+ * Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
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
+	[POWER_SUPPLY_PROP_INTERNAL_RESISTANCE] = BATT_RESISTANCE,
 	[POWER_SUPPLY_PROP_POWER_NOW] = BATT_POWER_NOW,
 };
 
@@ -582,6 +585,9 @@ static int qcom_battmgr_bat_get_property(struct power_supply *psy,
 	case POWER_SUPPLY_PROP_TEMP:
 		val->intval = battmgr->status.temperature;
 		break;
+	case POWER_SUPPLY_PROP_INTERNAL_RESISTANCE:
+		val->intval = battmgr->status.resistance;
+		break;
 	case POWER_SUPPLY_PROP_TIME_TO_EMPTY_AVG:
 		val->intval = battmgr->status.discharge_time;
 		break;
@@ -665,6 +671,7 @@ static const enum power_supply_property sm8350_bat_props[] = {
 	POWER_SUPPLY_PROP_MODEL_NAME,
 	POWER_SUPPLY_PROP_TIME_TO_FULL_AVG,
 	POWER_SUPPLY_PROP_TIME_TO_EMPTY_AVG,
+	POWER_SUPPLY_PROP_INTERNAL_RESISTANCE,
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

