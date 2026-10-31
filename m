From: David Heidelberg <david@ixit.cz>
Date: Sat, 31 Oct 2026 16:04:59 +0100
Subject: [PATCH 02/11] power: supply: qcom_smbx: Do not interfere with vbus
 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261031-pmi8998-vbus-v1-2-4d805e5a0f27@ixit.cz>
References: <20261031-pmi8998-vbus-v1-0-4d805e5a0f27@ixit.cz>
In-Reply-To: <20261031-pmi8998-vbus-v1-0-4d805e5a0f27@ixit.cz>
To: Alexey Minnekhanov <alexeymin@minlexx.ru>, 
 Robin Snyders <robin@snyders.xyz>, Liam Girdwood <lgirdwood@gmail.com>, 
 Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Wesley Cheng <quic_wcheng@quicinc.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Sebastian Reichel <sre@kernel.org>
Cc: Richard Acayan <mailingradian@gmail.com>, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 linux-pm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2282; i=david@ixit.cz;
 h=from:subject:message-id; bh=dUkU3R9RyGH/loLEEUiFubUZ7mMUCTgOR92p1j1B+OM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq5gOvGdpqmOloYmuL0212waKARR5qo3EmQUcJt
 en3iUVZ5OCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCauYDrwAKCRBgAj/E00kg
 cjIlD/9rofNJQD8SD3e06jMVuKiEh7lpCYsDtNsDrDQne7M8fm6dHd7DSytF4OeDVKuHy7TojMJ
 4pvvBpNY+18QbCYhbGKmMWyBSjjvjxmZyHkYn0p1JGKmEJIlCGx3PPzQRwds2HU3RrrYBP3epBF
 x/5SYUuqAx/iOmPGVDoRBvFbJc8oTGY9JU+/kFJQEznKcvc13VQBbdopus3Vo0HatZk6lTbj4UU
 LzFQC7luRdogqVEjoAYAaQNibwZEnNR1pULpskULFNTdckGpIJzLajuiyfNvO02pquYoMr7oElT
 k4w2meJulMk2nQNNhtp1KFTgt5CtwvsV1woQZPpHsMjc92bekgAeVJgSg3Fil4MvEyT2fk3jpBk
 XYt1onoxCebfNj1V/2+kXUv0RVx9rEm/hbbAH7IxQMRGZbCdpwbh163YVSssaUY0fP9um2hAup+
 ovO3xAKnJpr4QCDEXHKau6u6XWToyM8Zajvo3YyFQOm7vtTd1dx+/Z87t7pjNbMRJRcpw5+bRYm
 ZT7qtx/zIN9F1M25UBuGbnfZ939o32R+D5DP/I1HFjJAb1+vAboGzHZ+CfpWywQq0KZLRzWvJOj
 KOomUtHQAJ2ue0EX1f6YxHBkNhMGuymNxZcdR/ZDVvJjYSiSs7z2vkYkfJ8oL0CF7owMgfxCsbR
 9Slqu/WinEHwKTw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Charger should not touch bits handled by OTG block handled by the vbus
driver.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/power/supply/qcom_smbx.c | 14 --------------
 1 file changed, 14 deletions(-)

diff --git a/drivers/power/supply/qcom_smbx.c b/drivers/power/supply/qcom_smbx.c
index 52bb5a6eb145d..9c071a79a16c2 100644
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
@@ -804,18 +792,16 @@ static const struct smb_init_register smb_init_seq[] = {
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

