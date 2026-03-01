From: David Heidelberg <david@ixit.cz>
Date: Sun, 01 Mar 2026 01:51:25 +0100
Subject: [PATCH WIP v4 6/9] media: qcom: camss: csiphy-3ph: Update Gen2
 v1.1 MIPI CSI-2 CPHY init
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260301-qcom-cphy-v4-6-e53316d2cc65@ixit.cz>
References: <20260301-qcom-cphy-v4-0-e53316d2cc65@ixit.cz>
In-Reply-To: <20260301-qcom-cphy-v4-0-e53316d2cc65@ixit.cz>
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, Petr Hodina <phodina@protonmail.com>, 
 Casey Connolly <casey.connolly@linaro.org>, "Dr. Git" <drgitx@gmail.com>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Joel Selvaraj <foss@joelselvaraj.com>, Kieran Bingham <kbingham@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, linux-media@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2425; i=david@ixit.cz;
 h=from:subject:message-id; bh=L+ePL0W59bohGVuAyXyN3A8pdfQMeFCc6aBkc+w6klo=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpo42JddaQgNU/8hWg3u46NZcGPb+f0jmBLnMtv
 OA4qQbONCaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaaONiQAKCRBgAj/E00kg
 cjw2D/4n6b3wsxCe/FrsaPnJlrR7iTc83xSoM2wKxpg8wYKQiiDlvmRLc10zrqGgs+9Pga3Z5zg
 /KR/P90l3cg0WP56VC+zMvalcmiBYMtRjPtQVrgejO8rjJH5U+MeBJe/AoijPj0hKL3eTcKqJgk
 FvCw9TCd5/OVj/HISpHaTJWRpPmguGklzaWxpykjjTjv9J8P4c/+b5CJivGTfsvMxWleOUxgURF
 tsgD2NOcUN8QpTQH1eLqXt5MUgSWqr48R9V1A1uOCYf6pSmMABrP7BuG8odiZxIdHoYQUhvXrbf
 Lot2fLlRBUw9OOElcrQhvBwboalJ4A5TptRPBCOpdwWCiU6D0Ux9zTv7Qc0PEN+8SGah1qE8x7E
 7GxKkW9rmEggB2sdHC984H9786cwiOlBR3uwPUt/gJz+nNqW5aKlm2wudCAeKGOk9ANChP5NepS
 HX08MtOZrooVZa+0VIVkJR9BABfQ1K+eBWUIGgLhhJCKN3wNaSGUR57AETVL2XfOHG4/BNAKHHW
 ZuIEPyQwwc6tdffuUMtDTxS8jOzmky6pdeOx7O9BA0Euz6PeATOfLCc1VLZYWtVHBXHPZDDEcBU
 BQP1QmHywEvRijjJew5cmRqS15Aps7UrLaRyMJrrwCrZWIX++DQArWUuW+U0VGbKfrrPhRRQ26b
 tuSyv18qPoU4OKA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These values should improve C-PHY behaviour. Should match most recent
Qualcomm code.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../media/platform/qcom/camss/camss-csiphy-3ph-1-0.c   | 18 +++++++++---------
 1 file changed, 9 insertions(+), 9 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
index 5482fb5163e17..c612192ee727a 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
@@ -225,9 +225,9 @@ csiphy_lane_regs lane_regs_sdm845[] = {
 /* 3 entries: 3 lanes (C-PHY) */
 static const struct
 csiphy_lane_regs lane_regs_sdm845_3ph[] = {
-	{0x015c, 0x43, 0x00, CSIPHY_DEFAULT_PARAMS},
-	{0x0168, 0xa0, 0x00, CSIPHY_DEFAULT_PARAMS},
-	{0x016c, 0x25, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x015c, 0x63, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0168, 0xac, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x016c, 0xa5, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0104, 0x06, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x010c, 0x12, 0x00, CSIPHY_SETTLE_CNT_LOWER_BYTE},
 	{0x0108, 0x00, 0x00, CSIPHY_SETTLE_CNT_HIGHER_BYTE},
@@ -245,9 +245,9 @@ csiphy_lane_regs lane_regs_sdm845_3ph[] = {
 	{0x0164, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x01dc, 0x51, 0x00, CSIPHY_DEFAULT_PARAMS},
 
-	{0x035c, 0x43, 0x00, CSIPHY_DEFAULT_PARAMS},
-	{0x0368, 0xa0, 0x00, CSIPHY_DEFAULT_PARAMS},
-	{0x036c, 0x25, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x035c, 0x63, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0368, 0xac, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x036c, 0xa5, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0304, 0x06, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x030c, 0x12, 0x00, CSIPHY_SETTLE_CNT_LOWER_BYTE},
 	{0x0308, 0x00, 0x00, CSIPHY_SETTLE_CNT_HIGHER_BYTE},
@@ -265,9 +265,9 @@ csiphy_lane_regs lane_regs_sdm845_3ph[] = {
 	{0x0364, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x03dc, 0x51, 0x00, CSIPHY_DEFAULT_PARAMS},
 
-	{0x055c, 0x43, 0x00, CSIPHY_DEFAULT_PARAMS},
-	{0x0568, 0xa0, 0x00, CSIPHY_DEFAULT_PARAMS},
-	{0x056c, 0x25, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x055c, 0x63, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0568, 0xac, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x056c, 0xa5, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0504, 0x06, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x050c, 0x12, 0x00, CSIPHY_SETTLE_CNT_LOWER_BYTE},
 	{0x0508, 0x00, 0x00, CSIPHY_SETTLE_CNT_HIGHER_BYTE},

-- 
2.51.0

