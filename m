From: David Heidelberg <david@ixit.cz>
Date: Thu, 04 Dec 2025 17:32:40 +0100
Subject: [PATCH WIP v2 6/8] media: qcom: camss: csiphy-3ph: Add Gen2 v1.2.1
 MIPI CSI-2 C-PHY init
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251204-qcom-cphy-v2-6-6b35ef8b071e@ixit.cz>
References: <20251204-qcom-cphy-v2-0-6b35ef8b071e@ixit.cz>
In-Reply-To: <20251204-qcom-cphy-v2-0-6b35ef8b071e@ixit.cz>
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, Petr Hodina <phodina@protonmail.com>, 
 Casey Connolly <casey.connolly@linaro.org>, "Dr. Git" <drgitx@gmail.com>
Cc: Joel Selvaraj <foss@joelselvaraj.com>, 
 Kieran Bingham <kbingham@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, linux-media@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=6570; i=david@ixit.cz;
 h=from:subject:message-id; bh=tcUchcKgUbRaI+bwtzZif78m969iCdfhbBQ0ea28s98=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpMbet2uvctsyO/Dj8incukx6TQVtdJPO7J6RvK
 ULLmnEpZsWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaTG3rQAKCRBgAj/E00kg
 crdCD/wL7uEwTfvA2Lguk1nGOwKyNeU+gSnYFJYty7oM/bX7Ay1PvEOyluA7pNcIbO0yWy25KGC
 jq2JoTLVQsdmvzRx/cwhTl3nLCFbwILDEe62RBMxVx1pRJW/jWruBnYTSXUbNN5MHjo0v3xzDfl
 ukKp0Zo/LVzH08yjhLY4DN6uOSlsMbMYm7zk8UVRSlm4dps+4EJANr/datgtzZd3bi837rhWoCT
 p7o1eyMUj8MIwt4yX26cXcYKTS1f76oFGZ8IReKXrSo9OwQlM5CuQ+QL4Fc5WqBCueL+l+eVIfE
 K0nTuN74scbcI3VMP6K20lib5uBSTzrpCsUJnyOjXKAk3VRs3uG7jiVz9VkaFBG21+/l3urbv61
 8BuHrBkJgMsRo/DEVVUf9mWAgbv1idBo5pad9nV8ENfCTpIfI1ONIYNJZ2pQmXGdDNXeYHJ3WLD
 Bkso9JlxsBZvjysTToTLfTovOHPf2wp84Zk0jQuI/oRGkHX4aMxePsqTaasOfFni4h8sxjhK1zM
 2Ow2PLcpn+f3AGJqb2wVqSckuwy12onzxhXLA2pZMwrIcereI13SL4k3koAHoHbbc2nhKX2IePh
 /OYxv8c3Wp6xDA30+qMCtInxIlJAqQ24G1eoL26J+9s+6CaRh7kKguwopW4rQxMa7pbLA9BFHL3
 SINGWfI6iAJZ7Ww==
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
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../platform/qcom/camss/camss-csiphy-3ph-1-0.c     | 114 ++++++++++++++++++++-
 1 file changed, 112 insertions(+), 2 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
index 7121aa97a19c4..6d6dd54c5ac9c 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
@@ -547,6 +547,111 @@ csiphy_lane_regs lane_regs_qcm2290[] = {
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
@@ -1122,8 +1227,13 @@ static void csiphy_lanes_enable(struct csiphy_device *csiphy,
 		break;
 	case CAMSS_7280:
 	case CAMSS_8250:
-		regs->lane_regs = &lane_regs_sm8250[0];
-		regs->lane_array_size = ARRAY_SIZE(lane_regs_sm8250);
+		if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {
+			regs->lane_regs = &lane_regs_sm8250_3ph[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sm8250_3ph);
+		} else { /* V4L2_MBUS_CSI2_DPHY */
+			regs->lane_regs = &lane_regs_sm8250[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sm8250);
+		}
 		break;
 	case CAMSS_8280XP:
 		regs->lane_regs = &lane_regs_sc8280xp[0];

-- 
2.51.0

