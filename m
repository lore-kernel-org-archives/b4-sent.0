From: David Heidelberg <david@ixit.cz>
Date: Wed, 29 Jul 2026 22:20:02 +0200
Subject: [PATCH RESEND v9 7/9] media: qcom: camss: csiphy-3ph: Update Gen2
 v1.1 MIPI CSI-2 C-PHY init
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260729-qcom-cphy-v9-7-1f8d9fdab037@ixit.cz>
References: <20260729-qcom-cphy-v9-0-1f8d9fdab037@ixit.cz>
In-Reply-To: <20260729-qcom-cphy-v9-0-1f8d9fdab037@ixit.cz>
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Bryan O'Donoghue <bod@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, Petr Hodina <phodina@protonmail.com>, 
 "Dr. Git" <drgitx@gmail.com>, Cory Keitz <ckeitz@amazon.com>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Nihal Kumar Gupta <nihal.gupta@oss.qualcomm.com>
Cc: Frank Li <Frank.Li@nxp.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Kieran Bingham <kbingham@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, linux-media@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=6215; i=david@ixit.cz;
 h=from:subject:message-id; bh=bHMX4//aWDpheSP2KzZh84W22nyuHR1zfC/sMVCosog=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqamB176ElwPuo7PUbvrIL+2Dzn/PcxQnw6MIaK
 XPBV+uNsqyJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCampgdQAKCRBgAj/E00kg
 cgWuEACv6nhUu7x63+oXJFH1J7TSMnfSM9VPmagIThM/ev4Js76N5q2uLVYnLDcK5FbaYtxpIlt
 lgWc/Hy+NXD+akNUbfqkLChS+dtY2z2pbOhLbbv0GfPGciCbhci8eWt8RYI8EwcC4E0SQBD8YsM
 ffAGWNF199MKO0c0hOEti3mcFmNycg4oVD+OkFf5TruIqYg+RxnOvbxOomTdmWkuYRgPrl/FNJb
 foKrZuIk/I2u+GUxldNF12pFRQQYOq/BoGV9TsyOSE6jfEBmdaZ9xbmmrdaCn3N1hpLjCsw9dR5
 3fh2Sda6qSWZfmRytHPvzIdLt7gEGXCakWq1JgQB07/4AkX65uRgypBmTR2qsDcR12DjeBrVzyf
 BxjExABrzf6G23dH4EC9HHR5D8r0Y+M+n51h0SGBG10rJ0LQa7ORQ9Ka5fqpl21GqKu9ywrp7DI
 BKIdd1Tmqbxxmf1rmHOpNGSQlxjzXFC7yzjVycnk7aYN1u/SIuZVpwr9vSC4UfD0dDtFexmSc+x
 1E+m7ISUymth66rGdOuba6SPTO23bRt3kLvxTy0wkIJDWTkmIbpnGN+anw0z3p6HUdi1VJ9HPmd
 2iZ80OJtuY/JdG3ALWPBuU2iiILJ3a/+C86PFnVgHkCJIFsTuVU1jGa/33q8ojT9LqZXEjhkHOq
 nAeuBk9xiHHK4Aw==
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
 .../media/platform/qcom/camss/camss-csiphy-3ph-1-0.c  | 19 +++++++++----------
 1 file changed, 9 insertions(+), 10 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
index 83de89a88dbb1..25a3554ef2016 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
@@ -227,19 +227,19 @@ csiphy_lane_regs lane_regs_sdm845[] = {
 	{0x0660, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0664, 0x7F, 0x00, CSIPHY_DEFAULT_PARAMS},
 };
 
 /* GEN2 1.0 3PH */
 /* 3 entries: 3 lanes (C-PHY) */
 static const struct
 csiphy_lane_regs lane_regs_sdm845_3ph[] = {
-	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(23), 0x43, 0x00, CSIPHY_DEFAULT_PARAMS},
-	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(26), 0xa0, 0x00, CSIPHY_DEFAULT_PARAMS},
-	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(27), 0x25, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(23), 0x63, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(26), 0xac, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(27), 0xa5, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(1),  0x06, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(3),  0x12, 0x00, CSIPHY_SETTLE_CNT_LOWER_BYTE},
 	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(2),  0x00, 0x00, CSIPHY_SETTLE_CNT_HIGHER_BYTE},
 	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(5),  0x20, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(20), 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(6),  0x3e, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(7),  0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(8),  0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
@@ -247,19 +247,19 @@ csiphy_lane_regs lane_regs_sdm845_3ph[] = {
 	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(10), 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(11), 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(17), 0x12, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(24), 0x02, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(51), 0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(25), 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN1_CSI_3PH_CTRLn_ADDR(55), 0x51, 0x00, CSIPHY_DEFAULT_PARAMS},
 
-	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(23), 0x43, 0x00, CSIPHY_DEFAULT_PARAMS},
-	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(26), 0xa0, 0x00, CSIPHY_DEFAULT_PARAMS},
-	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(27), 0x25, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(23), 0x63, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(26), 0xac, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(27), 0xa5, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(1),  0x06, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(3),  0x12, 0x00, CSIPHY_SETTLE_CNT_LOWER_BYTE},
 	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(2),  0x00, 0x00, CSIPHY_SETTLE_CNT_HIGHER_BYTE},
 	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(5),  0x20, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(20), 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(6),  0x3e, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(7),  0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(8),  0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
@@ -267,36 +267,35 @@ csiphy_lane_regs lane_regs_sdm845_3ph[] = {
 	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(10), 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(11), 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(17), 0x12, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(24), 0x02, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(51), 0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(25), 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN3_CSI_3PH_CTRLn_ADDR(55), 0x51, 0x00, CSIPHY_DEFAULT_PARAMS},
 
-	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(23), 0x43, 0x00, CSIPHY_DEFAULT_PARAMS},
-	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(26), 0xa0, 0x00, CSIPHY_DEFAULT_PARAMS},
-	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(27), 0x25, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(23), 0x63, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(26), 0xac, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(27), 0xa5, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(1),  0x06, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(3),  0x12, 0x00, CSIPHY_SETTLE_CNT_LOWER_BYTE},
 	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(2),  0x00, 0x00, CSIPHY_SETTLE_CNT_HIGHER_BYTE},
 	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(5),  0x20, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(20), 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(6),  0x3e, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(7),  0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(8),  0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(9),  0x7f, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(10), 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(11), 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(17), 0x12, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(24), 0x02, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(51), 0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(25), 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{CSIPHY_LN5_CSI_3PH_CTRLn_ADDR(55), 0x51, 0x00, CSIPHY_DEFAULT_PARAMS},
-
 };
 
 /* GEN2 1.1 2PH */
 static const struct
 csiphy_lane_regs lane_regs_sc8280xp[] = {
 	{0x0004, 0x0C, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x002C, 0x01, 0x00, CSIPHY_DEFAULT_PARAMS},
 	{0x0034, 0x0F, 0x00, CSIPHY_DEFAULT_PARAMS},

-- 
2.53.0

