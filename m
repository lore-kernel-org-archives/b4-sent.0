From: =?utf-8?q?Alexandru_Andrie=C8=99?= <alex.andries.aa@gmail.com>
Date: Thu, 19 Nov 2026 00:16:52 +0100
Subject: [PATCH 3/3] power: supply: qcom_battmgr: fix negative temperature
 values
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261119-upstream-qcom-battmgr-fixes-v1-v1-3-ca83700c08c1@gmail.com>
References: <20261119-upstream-qcom-battmgr-fixes-v1-v1-0-ca83700c08c1@gmail.com>
In-Reply-To: <20261119-upstream-qcom-battmgr-fixes-v1-v1-0-ca83700c08c1@gmail.com>
To: Sebastian Reichel <sre@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>
Cc: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 linux-pm@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, stable@vger.kernel.org, 
 =?utf-8?q?Alexandru_Andrie=C8=99?= <alex.andries.aa@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795043834; l=2126;
 i=alex.andries.aa@gmail.com; s=20261118; h=from:subject:message-id;
 bh=rbeD9/hqy2iLa1zbMjhzXGTU00ckT0RtHpgBQ16AH5I=;
 b=JsoY8sFr/LIOpNR9zSCmVSlbAT0y8+na0ABBLTwEaUCcTDISlTl8LFCGx31mJICe5nVIy0Qtu
 UutV5/Wakh1DN2wEzee4AH33SDAS4fJv78X+dVsfRO+4EeM1fQs9uu1
X-Developer-Key: i=alex.andries.aa@gmail.com; a=ed25519;
 pk=kNAqgavfB7uUd1mA8o8TszhGxzyqBwY71PGO/oK4v84=
X-Endpoint-Received: by B4 Relay for alex.andries.aa@gmail.com/20261118 with auth_id=1564
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Firmware reports battery temperature in signed hundredths of a degree
Celsius, scaled to tenths of a degree for POWER_SUPPLY_PROP_TEMP.
Passing it as unsigned int to DIV_ROUND_CLOSEST(..., 10) in both
qcom_battmgr_sc8280xp_convert_temp() and qcom_battmgr_sm8350_callback()
turns sub-zero values (e.g. -5.00 C, 0xfffffe0c) into 429496680 instead
of -50.

Change status.temperature and qcom_battmgr_sc8280xp_convert_temp() to
int, and cast the SM8350 BATT_TEMP payload to s32 before dividing.

Tested at 35.0 C on a Xiaomi MIX 4 (SM8350); the SC8280XP path and
sub-zero temperatures were not hardware-tested.

Fixes: 29e8142b5623 ("power: supply: Introduce Qualcomm PMIC GLINK power supply")
Cc: stable@vger.kernel.org
Signed-off-by: Alexandru Andrieș <alex.andries.aa@gmail.com>
---
 drivers/power/supply/qcom_battmgr.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/power/supply/qcom_battmgr.c b/drivers/power/supply/qcom_battmgr.c
index 83e67d22c432..98b658ff6beb 100644
--- a/drivers/power/supply/qcom_battmgr.c
+++ b/drivers/power/supply/qcom_battmgr.c
@@ -278,7 +278,7 @@ struct qcom_battmgr_status {
 	int power_now;
 	unsigned int voltage_now;
 	unsigned int voltage_ocv;
-	unsigned int temperature;
+	int temperature;
 	unsigned int resistance;
 	unsigned int soh_percent;
 
@@ -1250,7 +1250,7 @@ static unsigned int qcom_battmgr_sc8280xp_parse_technology(const char *chemistry
 	return POWER_SUPPLY_TECHNOLOGY_UNKNOWN;
 }
 
-static unsigned int qcom_battmgr_sc8280xp_convert_temp(unsigned int temperature)
+static int qcom_battmgr_sc8280xp_convert_temp(int temperature)
 {
 	return DIV_ROUND_CLOSEST(temperature, 10);
 }
@@ -1467,7 +1467,7 @@ static void qcom_battmgr_sm8350_callback(struct qcom_battmgr *battmgr,
 			break;
 		case BATT_TEMP:
 			val = le32_to_cpu(resp->intval.value);
-			battmgr->status.temperature = DIV_ROUND_CLOSEST(val, 10);
+			battmgr->status.temperature = DIV_ROUND_CLOSEST((s32)val, 10);
 			break;
 		case BATT_TECHNOLOGY:
 			battmgr->info.technology = le32_to_cpu(resp->intval.value);

-- 
2.56.1

