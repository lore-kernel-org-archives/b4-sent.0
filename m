From: David Heidelberg <david@ixit.cz>
Date: Sun, 31 May 2026 15:08:14 +0200
Subject: [PATCH WIP v5 6/9] media: qcom: camss: csiphy-3ph: Update Gen2
 v1.1 MIPI CSI-2 C-PHY init
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260531-qcom-cphy-v5-6-6be0f62b4d65@ixit.cz>
References: <20260531-qcom-cphy-v5-0-6be0f62b4d65@ixit.cz>
In-Reply-To: <20260531-qcom-cphy-v5-0-6be0f62b4d65@ixit.cz>
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, Petr Hodina <phodina@protonmail.com>, 
 Casey Connolly <casey.connolly@linaro.org>, "Dr. Git" <drgitx@gmail.com>, 
 Cory Keitz <ckeitz@amazon.com>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Joel Selvaraj <foss@joelselvaraj.com>, Kieran Bingham <kbingham@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, linux-media@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3860; i=david@ixit.cz;
 h=from:subject:message-id; bh=0qnzO19xgIcmqRH00F7JZkTLiVzhMJPwNn5Ze/smDMg=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqHDK6Aocv0y3fmQKDsNuU7KhsS73Z27PMgXREc
 bZnIQfthTGJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCahwyugAKCRBgAj/E00kg
 cqS1D/9wia8qwdNFo+dAuRruNuNxrNdaH94pjH//ZQiGd3m/fS8pMIgDvMlBidzHKoJ4Vy3OjkK
 pPxkvK2UE4y9Wsw8LxBnopM8jFHHoBOc6c9i+5uICvkZ9hrgeS0V1Y7YFTEJFk4P0bpfnu1rrUH
 IK0srEazKnxySZrsGAJIr8AN4Qv6J+19JZVq9dhRdckTMMiGrfRggtpaWE61irijR27WON/lvEg
 DkXlXCmIHmONxwSp0yLJz4Wd45EYnrMzeiIa8yrO5y3TF6EO5SQp7ztwH1tcP8ocS9S1KgkIqFd
 TVv8YdTkK8lutC6FY7pw34TLcDqe7PJJZn2fN+ohlnhDY6Mf+zmX0b2LukWUQRIXC/yC5p4czCf
 o2zvBgX2I99KUOhyeyRj1HALVQ7FalrU+xTMJ+sxoBetfuKyoH7YC+I11hLGVsRPN6nmN/gfqoI
 zpsvJo98m4kaHVQ6IhPqMzjK+etYgnffmPPC0WI55VaV6hwXAnpiL2K07IfW5OWzdWGMcKR5wHY
 v81GXW/H4yLSvE067fvBT2Dy7hxpkFhDG7gTyNjjEdV61lK2xUhH9zFG1pZ51erq8vjRhw6c1Ue
 z2xpgzDZEWgR8eqCS1UYD/6jUoyZ9sNVKrcWUqnFopNp14GbdhW2qTf8YbnXjCWso4TuP44rIKc
 QKRJaYuu3ltIslg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These values should improve C-PHY behaviour. Should match most recent
Qualcomm code.

Acked-by: Cory Keitz <ckeitz@amazon.com>
Suggested-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../media/platform/qcom/camss/camss-csiphy-3ph-1-0.c   | 18 +++++++++---------
 1 file changed, 9 insertions(+), 9 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
index d837fcf7cd2f0..9a0f009c033bb 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
@@ -220,19 +220,19 @@ csiphy_lane_regs lane_regs_sdm845[] = {
 	{0x0660, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0664, 0x7F, 0x00, CSIPHY_DEFAULT_PARAMS},
 };
 
 /* GEN2 1.0 3PH */
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
 	{0x0114, 0x20, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0150, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0118, 0x3e, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x011c, 0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0120, 0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
@@ -240,19 +240,19 @@ csiphy_lane_regs lane_regs_sdm845_3ph[] = {
 	{0x0128, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x012c, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0144, 0x12, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0160, 0x02, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x01cc, 0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
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
 	{0x0314, 0x20, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0350, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0318, 0x3e, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x031c, 0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0320, 0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
@@ -260,19 +260,19 @@ csiphy_lane_regs lane_regs_sdm845_3ph[] = {
 	{0x0328, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x032c, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0344, 0x12, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0360, 0x02, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x03cc, 0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
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
 	{0x0514, 0x20, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0550, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0518, 0x3e, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x051c, 0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0520, 0x41, 0x00, CSIPHY_DEFAULT_PARAMS},

-- 
2.53.0

