From: David Heidelberg <david@ixit.cz>
Date: Sat, 21 Nov 2026 23:37:58 +0100
Subject: [PATCH v3 04/12] power: supply: qcom_smbx: Stop clearing software
 control select
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-pmi8998-vbus-v3-4-91ba2e61a877@ixit.cz>
References: <20261121-pmi8998-vbus-v3-0-91ba2e61a877@ixit.cz>
In-Reply-To: <20261121-pmi8998-vbus-v3-0-91ba2e61a877@ixit.cz>
To: Abel Vesa <abelvesa@kernel.org>, 
 Alexey Minnekhanov <alexeymin@minlexx.ru>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Markus Rathgeb <maggu2810@mailbox.org>, Rob Herring <robh@kernel.org>, 
 Robin Snyders <robin@snyders.xyz>, Sebastian Reichel <sre@kernel.org>, 
 Wesley Cheng <quic_wcheng@quicinc.com>
Cc: Richard Acayan <mailingradian@gmail.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 devicetree@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2354; i=david@ixit.cz;
 h=from:subject:message-id; bh=6d4asV1zW1ZVePGq0BeaT1hbifcETG4K6ZzsSB440gQ=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrAh1at/9Ag9Gs97NDXSbrqiKQfpjhzNIn6pcDx
 M26XnW6/82JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawIdWgAKCRBgAj/E00kg
 crc4D/40jWzfWyb8sl71g/6Gr37FlRGj8Tmmw/Hd82UENxIxy2/UAPZhf2hQ5VWuYW5D62Geh9H
 bh/xyC9+KUPHzOnFXO0l8h+SrS83reM+TLefrq66/F1NpiHhlWI+iQIz1LEPWo5rHdyyQLs2aDN
 s9C+Tp2oc2Qa+McF2ISl6Dv216gkgiRWejHcQQJv57CtDLufDD4EH6LfbT6bDPqkVZ+cfTahJ6a
 bWBik00/sy4B/73XutHbY/IgKQ3nATxMTSe/C8fnzj8M256brgMkD/x8pmSCPL4fw5SbTRDk99j
 M0X9q52S8A9u5in9DAWelVOCUNzsSb5x1v/1Pn86Zj7eDnKGqSlP7tUaYCo9NJ9cuPzZoTKDIEZ
 VELT45N2rnw6nbpzP6KFPQfR6RgCQFL0VOwCSm8wTtmsOjGfq17QQHCGKdS8v5cWet31F/ZNI+e
 mmwAAuB/LYS3Aiep9D+bFDVdNL/dHcQ3Kck2NkJ94LFqP0ShIvQ/YPLnxWriL35ypMPsJY17YBA
 ytva9pA4/IdO/vjckbNf6nOIPvq5de+QvczNgE/hlrnCM5dY4kExg4ZpN5H6qrj5rordu9luT2G
 xozMU2gB3JkEhGNis0/pjfIequllMKgCYVxGm2ns+2FXe//eBpUttlUTuqvYcXLq1HKjkTOWl/W
 +xTJJUJtZghlRvA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Charger should not touch OTG block registers now handled by the vbus
driver. This change stops clearing OTG_EN_SRC_CFG_BIT (software control
select).

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/power/supply/qcom_smbx.c | 14 --------------
 1 file changed, 14 deletions(-)

diff --git a/drivers/power/supply/qcom_smbx.c b/drivers/power/supply/qcom_smbx.c
index c6188c915703a..a4f5ffd3cd6e5 100644
--- a/drivers/power/supply/qcom_smbx.c
+++ b/drivers/power/supply/qcom_smbx.c
@@ -96,28 +96,16 @@
 #define USBIN_ICL_CHANGE_RT_STS_BIT			BIT(6)
 #define USBIN_SOURCE_CHANGE_RT_STS_BIT			BIT(5)
 #define USBIN_PLUGIN_RT_STS_BIT				BIT(4)
 #define USBIN_OV_RT_STS_BIT				BIT(3)
 #define USBIN_UV_RT_STS_BIT				BIT(2)
 #define USBIN_LT_3P6V_RT_STS_BIT			BIT(1)
 #define USBIN_COLLAPSE_RT_STS_BIT			BIT(0)
 
-#define OTG_CFG						0x153
-#define OTG_RESERVED_MASK				GENMASK(7, 6)
-#define DIS_OTG_ON_TLIM_BIT				BIT(5)
-#define QUICKSTART_OTG_FASTROLESWAP_BIT			BIT(4)
-#define INCREASE_DFP_TIME_BIT				BIT(3)
-#define ENABLE_OTG_IN_DEBUG_MODE_BIT			BIT(2)
-#define OTG_EN_SRC_CFG_BIT				BIT(1)
-#define CONCURRENT_MODE_CFG_BIT				BIT(0)
-
-#define OTG_ENG_OTG_CFG					0x1C0
-#define ENG_BUCKBOOST_HALT1_8_MODE_BIT			BIT(0)
-
 #define APSD_STATUS					0x307
 #define APSD_STATUS_7_BIT				BIT(7)
 #define HVDCP_CHECK_TIMEOUT_BIT				BIT(6)
 #define SLOW_PLUGIN_TIMEOUT_BIT				BIT(5)
 #define ENUMERATION_DONE_BIT				BIT(4)
 #define VADP_CHANGE_DONE_AFTER_AUTH_BIT			BIT(3)
 #define QC_AUTH_DONE_STATUS_BIT				BIT(2)
 #define QC_CHARGER_BIT					BIT(1)
@@ -811,18 +799,16 @@ static const struct smb_init_register smb_init_seq[] = {
 	  .val = VCONN_EN_SRC_BIT },
 	/*
 	 * Disable Type-C factory mode and stay in Attached.SRC state when VCONN
 	 * over-current happens
 	 */
 	{ .addr = TYPE_C_CFG,
 	  .mask = FACTORY_MODE_DETECTION_EN_BIT | VCONN_OC_CFG_BIT,
 	  .val = 0 },
-	/* Configure VBUS for software control */
-	{ .addr = OTG_CFG, .mask = OTG_EN_SRC_CFG_BIT, .val = 0 },
 	/*
 	 * Use VBAT to determine the recharge threshold when battery is full
 	 * rather than the state of charge.
 	 */
 	{ .addr = FG_UPDATE_CFG_2_SEL,
 	  .mask = SOC_LT_CHG_RECHARGE_THRESH_SEL_BIT |
 		  VBT_LT_CHG_RECHARGE_THRESH_SEL_BIT,
 	  .val = VBT_LT_CHG_RECHARGE_THRESH_SEL_BIT },

-- 
2.55.0

