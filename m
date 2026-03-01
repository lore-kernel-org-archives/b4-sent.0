From: David Heidelberg <david@ixit.cz>
Date: Sun, 01 Mar 2026 01:51:26 +0100
Subject: [PATCH WIP v4 7/9] media: qcom: camss: csiphy-3ph: Add Gen2 v1.2.1
 MIPI CSI-2 C-PHY init
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260301-qcom-cphy-v4-7-e53316d2cc65@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=6434; i=david@ixit.cz;
 h=from:subject:message-id; bh=F68FYZ/9PYHBEJYRHtnB6O4AcY4Jp6F2NvaXkH1GcAU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpo42JaLghH4/F0XNWTLQaL4YwTEhrfOBEeLIC0
 IBZN5KLnqKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaaONiQAKCRBgAj/E00kg
 ck68EACGeZcrAv/Jo98t7Ja1QBAVIjjMgWL7PEYMiCNopE1kvQxklzrbKdjgG3P94y3KmNF/MDv
 2Zfsh5hlYmO40TzUr8K++xJluXomWx7djS7hrJxeZ0DC/J5T0AHtiyvjEYX0X2SsaDfJmc0K/EV
 nXj/KtelFi/jTKJC7y9yyhRUyD3pE+mxmUhgFpZPmlurgOH/W8KrLV/xhQDpRm02VmRPG6Vn+Tp
 DrA3Nz03Ywy67mrX1VInWZ0R6+PXcqAx6o8eVj+mzUsDrGNWCh3xON8lxohsb66TGLfz6jfjGe8
 fCBbGhJUP0Fr7Tkhn1y2jlncptihV9KVjRVx+0Ne1eeuWy6Vp2i0YNPEYrej/7cwp7mpcyE4h8C
 5xuu3nQaoRiz6fjA8Noh4CaOkazUxRr8vKCeHU1/lVzMnucOGA75rCemsupLf0+FhK20AxGKMSc
 s/cMnMWCm8ggJRMcJjhF4jcDBUgRnrtv05EwwPWJqbOmpCkXhjNXSOQA+xkKF0PQfcxsvRufhIK
 dxBUhyjwTwaxn1yQHyCw5N6EmfnrximDhaLHJ55JVJk8yLRDXQub7jiTZRREo5UnOr+DArz/KXL
 HmQHyZrN/2Erhof6bbdp7AfvIqd7l2uUfskCu0QecqlH/B/KUqh2hszt8M/gDJPKsmqFQLgrrq5
 CwbJVMfdJlG6A0A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Luca Weiss <luca.weiss@fairphone.com>

Add a PHY configuration sequence for the sm8250 which uses a Qualcomm
Gen 2 version 1.2.1 CSI-2 PHY.

The PHY can be configured as two phase or three phase in C-PHY or D-PHY
mode. This configuration supports three-phase C-PHY mode.

Signed-off-by: Luca Weiss <luca.weiss@fairphone.com>
Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../platform/qcom/camss/camss-csiphy-3ph-1-0.c     | 112 ++++++++++++++++++++-
 1 file changed, 111 insertions(+), 1 deletion(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
index c612192ee727a..e48f5c1290173 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
@@ -550,6 +550,113 @@ csiphy_lane_regs lane_regs_qcm2290[] = {
 	{0x0664, 0x3f, 0x00, CSIPHY_DEFAULT_PARAMS},
 };
 
+/* GEN2 1.2.1 3PH */
+/* 3 entries: 3 lanes (C-PHY) */
+static const struct
+csiphy_lane_regs lane_regs_sm8250_3ph[] = {
+	{0x0990, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0994, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0998, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0990, 0x08, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0994, 0x08, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0998, 0x1a, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x098c, 0xaf, 0x01, CSIPHY_DEFAULT_PARAMS},
+	{0x015c, 0x46, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0168, 0xa0, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0104, 0x06, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x010c, 0x12, 0x00, CSIPHY_SETTLE_CNT_LOWER_BYTE},
+	{0x0108, 0x00, 0x00, CSIPHY_SETTLE_CNT_HIGHER_BYTE},
+	{0x0114, 0x20, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0150, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0188, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x018c, 0x7f, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0190, 0x7f, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0118, 0x3e, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x011c, 0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0120, 0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0124, 0x7f, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0128, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x012c, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0160, 0x02, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x01cc, 0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x01dc, 0x50, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0984, 0x20, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0988, 0x05, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0980, 0x60, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x09ac, 0x35, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x09b0, 0x01, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0800, 0x0e, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0884, 0x01, 0x00, CSIPHY_DEFAULT_PARAMS},
+
+	{0x0a90, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0a94, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0a98, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0a90, 0x08, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0a94, 0x08, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0a98, 0x1a, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0a8c, 0xaf, 0x01, CSIPHY_DEFAULT_PARAMS},
+	{0x035c, 0x46, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0368, 0xa0, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0304, 0x06, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x030c, 0x12, 0x00, CSIPHY_SETTLE_CNT_LOWER_BYTE},
+	{0x0308, 0x00, 0x00, CSIPHY_SETTLE_CNT_HIGHER_BYTE},
+	{0x0314, 0x20, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0350, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0388, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x038c, 0x7f, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0390, 0x7f, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0318, 0x3e, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x031c, 0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0320, 0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0324, 0x7f, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0328, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x032c, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0360, 0x02, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x03cc, 0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x03dc, 0x50, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0a84, 0x20, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0a88, 0x05, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0a80, 0x60, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0aac, 0x35, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0ab0, 0x01, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0800, 0x0e, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0884, 0x01, 0x00, CSIPHY_DEFAULT_PARAMS},
+
+	{0x0b90, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0b94, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0b98, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0b90, 0x08, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0b94, 0x08, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0b98, 0x1a, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0b8c, 0xaf, 0x01, CSIPHY_DEFAULT_PARAMS},
+	{0x055c, 0x46, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0568, 0xa0, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0504, 0x06, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x050c, 0x12, 0x00, CSIPHY_SETTLE_CNT_LOWER_BYTE},
+	{0x0508, 0x00, 0x00, CSIPHY_SETTLE_CNT_HIGHER_BYTE},
+	{0x0514, 0x20, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0550, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0588, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x058c, 0x7f, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0590, 0x7f, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0518, 0x3e, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x051c, 0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0520, 0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0524, 0x7f, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0528, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x052c, 0x00, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0560, 0x02, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x05cc, 0x41, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x05dc, 0x50, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0b84, 0x20, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0b88, 0x05, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0b80, 0x60, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0bac, 0x35, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0bb0, 0x01, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0800, 0x0e, 0x00, CSIPHY_DEFAULT_PARAMS},
+	{0x0884, 0x01, 0x00, CSIPHY_DEFAULT_PARAMS},
+};
+
 /* GEN2 2.1.2 2PH DPHY mode */
 static const struct
 csiphy_lane_regs lane_regs_sm8550[] = {
@@ -1134,7 +1241,10 @@ static int csiphy_lanes_enable(struct csiphy_device *csiphy,
 		break;
 	case CAMSS_7280:
 	case CAMSS_8250:
-		{
+		if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {
+			regs->lane_regs = &lane_regs_sm8250_3ph[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sm8250_3ph);
+		} else {
 			regs->lane_regs = &lane_regs_sm8250[0];
 			regs->lane_array_size = ARRAY_SIZE(lane_regs_sm8250);
 		}

-- 
2.51.0

