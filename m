From: David Heidelberg <david@ixit.cz>
Date: Thu, 04 Dec 2025 17:32:41 +0100
Subject: [PATCH WIP v2 7/8] media: qcom: camss: csiphy-3ph: C-PHY needs own
 lane configuration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251204-qcom-cphy-v2-7-6b35ef8b071e@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3333; i=david@ixit.cz;
 h=from:subject:message-id; bh=wbIQ6Ecj4wb9GDskxbpQu5QF2zKRS8sSbJFfBe0x2TA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpMbetd8v/yjEvP1o+sLSzIMRSIM9tVDlys2CAf
 3lSHLzUfEyJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaTG3rQAKCRBgAj/E00kg
 cgpgD/sFQSUlh2CaJiY5XFpIXxppoSIWoQgAvO3hMY5mdfUIY55IKkeSZDBqRgxMaFtgrpALS3r
 qi1iZ6bk7EiheUcWnBkx7KDigWFLg4mbsvp8vCahVfXt7PKy21aLml/JCk6IV0yPX6CTpTY6Ltj
 M4WbXA3TYQCur68zkVmRbGwei7gtJfZd9K/ZNq7KNDnQSkcZCVJB8OM5HLlEU+YqOx/LTS3FMn3
 yaTCg1gH/iRdQa/DO8+QCHZ1xvyha11RwDr1hMBK3OHAfdh1FmEP0gxebuh853g19q5tuXpZcRE
 FUi/Qnj+PVRcZZHJoK7W2kVhaYslZe0XgSq8oVGtVb16TgtwvQMcx1SKjct28Y8emb3yJ/bQ8Bz
 SnTRiT2sCwTTXUF/67+Y/3seWi5YWgE5eWXmES1YltVANR+iaMF/ZIMtUj5x+52tuftdWMDVDvU
 HPu9j1EHxIj1KuNFHmvwlJ8C1o9+X5aZt/CuXyQyCAcNmvZgSxNOtuS/kDYjiX0K44HZPlvpcQa
 2DZpBeMDIzsQ+KwzxZ6sgz3F527SuwUJhcEjOnZmlOI+O1xy0Ybs2J5WspEser5/D68iC52FfkF
 sPbyFtIxvH9oeORYi5M0KJ0ZbscElbi4DjU4/r2wSGDtviVHA7LvEwZH/5Yv2eQ4p83idIQTa1r
 aXRttiHa8qR2Tsg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make sure we have proper lane registers definition in-place for each
generation, otherwise C-PHY won't work.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../platform/qcom/camss/camss-csiphy-3ph-1-0.c     | 48 ++++++++++++++++------
 1 file changed, 36 insertions(+), 12 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
index 6d6dd54c5ac9c..c957f7dbfb243 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
@@ -1222,8 +1222,12 @@ static void csiphy_lanes_enable(struct csiphy_device *csiphy,
 		}
 		break;
 	case CAMSS_2290:
-		regs->lane_regs = &lane_regs_qcm2290[0];
-		regs->lane_array_size = ARRAY_SIZE(lane_regs_qcm2290);
+		if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {
+			dev_err(dev, "Missing lane_regs definition for %d\n", c->phy_cfg);
+		} else { /* V4L2_MBUS_CSI2_DPHY */
+			regs->lane_regs = &lane_regs_qcm2290[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_qcm2290);
+		}
 		break;
 	case CAMSS_7280:
 	case CAMSS_8250:
@@ -1236,25 +1240,45 @@ static void csiphy_lanes_enable(struct csiphy_device *csiphy,
 		}
 		break;
 	case CAMSS_8280XP:
-		regs->lane_regs = &lane_regs_sc8280xp[0];
-		regs->lane_array_size = ARRAY_SIZE(lane_regs_sc8280xp);
+		if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {
+			dev_err(dev, "Missing lane_regs definition for %d\n", c->phy_cfg);
+		} else { /* V4L2_MBUS_CSI2_DPHY */
+			regs->lane_regs = &lane_regs_sc8280xp[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sc8280xp);
+		}
 		break;
 	case CAMSS_X1E80100:
-		regs->lane_regs = &lane_regs_x1e80100[0];
-		regs->lane_array_size = ARRAY_SIZE(lane_regs_x1e80100);
+		if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {
+			dev_err(dev, "Missing lane_regs definition for %d\n", c->phy_cfg);
+		} else { /* V4L2_MBUS_CSI2_DPHY */
+			regs->lane_regs = &lane_regs_x1e80100[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_x1e80100);
+		}
 		break;
 	case CAMSS_8550:
-		regs->lane_regs = &lane_regs_sm8550[0];
-		regs->lane_array_size = ARRAY_SIZE(lane_regs_sm8550);
+		if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {
+			dev_err(dev, "Missing lane_regs definition for %d\n", c->phy_cfg);
+		} else { /* V4L2_MBUS_CSI2_DPHY */
+			regs->lane_regs = &lane_regs_sm8550[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sm8550);
+		}
 		break;
 	case CAMSS_8650:
-		regs->lane_regs = &lane_regs_sm8650[0];
-		regs->lane_array_size = ARRAY_SIZE(lane_regs_sm8650);
+		if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {
+			dev_err(dev, "Missing lane_regs definition for %d\n", c->phy_cfg);
+		} else { /* V4L2_MBUS_CSI2_DPHY */
+			regs->lane_regs = &lane_regs_sm8650[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sm8650);
+		}
 		break;
 	case CAMSS_8300:
 	case CAMSS_8775P:
-		regs->lane_regs = &lane_regs_sa8775p[0];
-		regs->lane_array_size = ARRAY_SIZE(lane_regs_sa8775p);
+		if (c->phy_cfg == V4L2_MBUS_CSI2_CPHY) {
+			dev_err(dev, "Missing lane_regs definition for %d\n", c->phy_cfg);
+		} else { /* V4L2_MBUS_CSI2_DPHY */
+			regs->lane_regs = &lane_regs_sa8775p[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sa8775p);
+		}
 		break;
 	default:
 		break;

-- 
2.51.0

