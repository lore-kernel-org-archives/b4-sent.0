From: David Heidelberg <david@ixit.cz>
Date: Sun, 01 Mar 2026 01:51:21 +0100
Subject: [PATCH WIP v4 2/9] media: qcom: camss: csiphy-3ph: Use odd bits
 for configuring C-PHY lanes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260301-qcom-cphy-v4-2-e53316d2cc65@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=6462; i=david@ixit.cz;
 h=from:subject:message-id; bh=rTZ6J47ECLprwfYBbP1bL6C5zsfu9IOrZXbtNtbAtRE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpo42Ia0lUzfipazsv1Oav0fS036ikiRXyb0U8Y
 a45SqFWpZqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaaONiAAKCRBgAj/E00kg
 cnKyD/kBcPvEkQr9EKloaXvPwIsl0uMcHp6YzzE1Ck34Q0csuq02ujan3aNTR8YbK7ArMz2wE2k
 80IBOAHRwejUoGfEiYxDRMhR+Wmxs3t96mDYkxcD1CSr0cKA4SZPdceK5Ik0fXqhGHdWmsFjvtM
 04Fq5A5+Oam7oV7lgmejAwf6MhStkZ2leBAWdFa81BBlIulej/cBNwqCoPf+T64QSrkF237rXJx
 yj1Fi1j6qcaThqd/6uj5W0WNdFemRueiHPUkRs3Iaf+H6nBQIlSJB02CjIXkCjIMnhw5ekt57lN
 1TRnCa+Vl84ZMfzHysDdDnTL6nSmG2IiYwbdQ025LmjW48PYty9XNBcDAOHudB9MausQ6QiuJ6K
 i5WUstgD/Zrgx/kR2lh8PYu8VsyKELuaBcvTditWk50JqTXZ7oZVhS/KYxMvUJ9LQnLw00hBeGn
 EwVnH+U321xcHj1ZtY2M1dY5IOYlamruykDRkJIuruptTACYeQTyk6gLVyN3wcqycTOWkpCU/IN
 sXhX+aKKP3B/+N5Z22A1szFhcJZNuek0nkECTuB/TjBEXV1lRwPCN2MnvpLCTbTOIuSkEWiTCfX
 l4HAEOqOIRhX29PkL5F9j1zZcuftrd6YV4ATfrbn14lVyXAowSJ6qKaY52RO33lh+FY5KGrLoXx
 xmRrXZRfIzK74Ug==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

So far, only D-PHY mode was supported, which uses even bits when enabling
or masking lanes. For C-PHY configuration, the hardware instead requires
using the odd bits.

Since there can be unrecognized configuration allow returning failure.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../platform/qcom/camss/camss-csiphy-2ph-1-0.c     |  8 ++--
 .../platform/qcom/camss/camss-csiphy-3ph-1-0.c     | 49 +++++++++++++++++-----
 drivers/media/platform/qcom/camss/camss-csiphy.c   |  5 +--
 drivers/media/platform/qcom/camss/camss-csiphy.h   |  6 +--
 4 files changed, 48 insertions(+), 20 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy-2ph-1-0.c b/drivers/media/platform/qcom/camss/camss-csiphy-2ph-1-0.c
index 9d67e7fa6366a..bb4b91f69616b 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy-2ph-1-0.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy-2ph-1-0.c
@@ -94,9 +94,9 @@ static u8 csiphy_settle_cnt_calc(s64 link_freq, u32 timer_clk_rate)
 	return settle_cnt;
 }
 
-static void csiphy_lanes_enable(struct csiphy_device *csiphy,
-				struct csiphy_config *cfg,
-				s64 link_freq, u8 lane_mask)
+static int csiphy_lanes_enable(struct csiphy_device *csiphy,
+			       struct csiphy_config *cfg,
+			       s64 link_freq, u8 lane_mask)
 {
 	struct csiphy_lanes_cfg *c = &cfg->csi2->lane_cfg;
 	u8 settle_cnt;
@@ -132,6 +132,8 @@ static void csiphy_lanes_enable(struct csiphy_device *csiphy,
 		writel_relaxed(0x3f, csiphy->base +
 			       CAMSS_CSI_PHY_INTERRUPT_CLEARn(l));
 	}
+
+	return 0;
 }
 
 static void csiphy_lanes_disable(struct csiphy_device *csiphy,
diff --git a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
index 4154832745525..cf83c9e062b81 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
@@ -14,6 +14,7 @@
 #include <linux/delay.h>
 #include <linux/interrupt.h>
 #include <linux/io.h>
+#include <linux/media-bus-format.h>
 
 #define CSIPHY_3PH_LNn_CFG1(n)			(0x000 + 0x100 * (n))
 #define CSIPHY_3PH_LNn_CFG1_SWI_REC_DLY_PRG	(BIT(7) | BIT(6))
@@ -993,13 +994,22 @@ static void csiphy_gen2_config_lanes(struct csiphy_device *csiphy,
 
 static u8 csiphy_get_lane_mask(struct csiphy_lanes_cfg *lane_cfg)
 {
-	u8 lane_mask;
-	int i;
+	u8 lane_mask = 0;
 
-	lane_mask = CSIPHY_3PH_CMN_CSI_COMMON_CTRL5_CLK_ENABLE;
+	switch (lane_cfg->phy_cfg) {
+	case V4L2_MBUS_CSI2_CPHY:
+		for (int i = 0; i < lane_cfg->num_data; i++)
+			lane_mask |= BIT(lane_cfg->data[i].pos + 1);
+		break;
+	case V4L2_MBUS_CSI2_DPHY:
+		lane_mask = CSIPHY_3PH_CMN_CSI_COMMON_CTRL5_CLK_ENABLE;
 
-	for (i = 0; i < lane_cfg->num_data; i++)
-		lane_mask |= 1 << lane_cfg->data[i].pos;
+		for (int i = 0; i < lane_cfg->num_data; i++)
+			lane_mask |= BIT(lane_cfg->data[i].pos);
+		break;
+	default:
+		break;
+	}
 
 	return lane_mask;
 }
@@ -1027,10 +1037,11 @@ static bool csiphy_is_gen2(u32 version)
 	return ret;
 }
 
-static void csiphy_lanes_enable(struct csiphy_device *csiphy,
-				struct csiphy_config *cfg,
-				s64 link_freq, u8 lane_mask)
+static int csiphy_lanes_enable(struct csiphy_device *csiphy,
+			       struct csiphy_config *cfg,
+			       s64 link_freq, u8 lane_mask)
 {
+	struct device *dev = csiphy->camss->dev;
 	struct csiphy_lanes_cfg *c = &cfg->csi2->lane_cfg;
 	struct csiphy_device_regs *regs = csiphy->regs;
 	u8 settle_cnt;
@@ -1039,9 +1050,23 @@ static void csiphy_lanes_enable(struct csiphy_device *csiphy,
 
 	settle_cnt = csiphy_settle_cnt_calc(link_freq, csiphy->timer_clk_rate);
 
-	val = CSIPHY_3PH_CMN_CSI_COMMON_CTRL5_CLK_ENABLE;
-	for (i = 0; i < c->num_data; i++)
-		val |= BIT(c->data[i].pos * 2);
+	val = 0;
+
+	switch (c->phy_cfg) {
+	case V4L2_MBUS_CSI2_CPHY:
+		for (i = 0; i < c->num_data; i++)
+			val |= BIT((c->data[i].pos * 2) + 1);
+		break;
+	case V4L2_MBUS_CSI2_DPHY:
+		val = CSIPHY_3PH_CMN_CSI_COMMON_CTRL5_CLK_ENABLE;
+
+		for (i = 0; i < c->num_data; i++)
+			val |= BIT(c->data[i].pos * 2);
+		break;
+	default:
+		dev_err(dev, "Unsupported bus type %d\n", c->phy_cfg);
+		return -EINVAL;
+	}
 
 	writel_relaxed(val, csiphy->base +
 		       CSIPHY_3PH_CMN_CSI_COMMON_CTRLn(regs->offset, 5));
@@ -1068,6 +1093,8 @@ static void csiphy_lanes_enable(struct csiphy_device *csiphy,
 		writel_relaxed(0, csiphy->base +
 			       CSIPHY_3PH_CMN_CSI_COMMON_CTRLn(regs->offset, i));
 	}
+
+	return 0;
 }
 
 static void csiphy_lanes_disable(struct csiphy_device *csiphy,
diff --git a/drivers/media/platform/qcom/camss/camss-csiphy.c b/drivers/media/platform/qcom/camss/camss-csiphy.c
index 62623393f4144..938600f3defe1 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy.c
@@ -265,6 +265,7 @@ static int csiphy_set_power(struct v4l2_subdev *sd, int on)
 static int csiphy_stream_on(struct csiphy_device *csiphy)
 {
 	struct csiphy_config *cfg = &csiphy->cfg;
+	const struct csiphy_hw_ops *ops = csiphy->res->hw_ops;
 	s64 link_freq;
 	u8 lane_mask = csiphy->res->hw_ops->get_lane_mask(&cfg->csi2->lane_cfg);
 	u8 bpp = csiphy_get_bpp(csiphy->res->formats->formats, csiphy->res->formats->nformats,
@@ -295,9 +296,7 @@ static int csiphy_stream_on(struct csiphy_device *csiphy)
 		wmb();
 	}
 
-	csiphy->res->hw_ops->lanes_enable(csiphy, cfg, link_freq, lane_mask);
-
-	return 0;
+	return ops->lanes_enable(csiphy, cfg, link_freq, lane_mask);
 }
 
 /*
diff --git a/drivers/media/platform/qcom/camss/camss-csiphy.h b/drivers/media/platform/qcom/camss/camss-csiphy.h
index d198171700e73..21cf2ce931c1d 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy.h
+++ b/drivers/media/platform/qcom/camss/camss-csiphy.h
@@ -73,9 +73,9 @@ struct csiphy_hw_ops {
 	void (*hw_version_read)(struct csiphy_device *csiphy,
 				struct device *dev);
 	void (*reset)(struct csiphy_device *csiphy);
-	void (*lanes_enable)(struct csiphy_device *csiphy,
-			     struct csiphy_config *cfg,
-			     s64 link_freq, u8 lane_mask);
+	int (*lanes_enable)(struct csiphy_device *csiphy,
+			    struct csiphy_config *cfg,
+			    s64 link_freq, u8 lane_mask);
 	void (*lanes_disable)(struct csiphy_device *csiphy,
 			      struct csiphy_config *cfg);
 	irqreturn_t (*isr)(int irq, void *dev);

-- 
2.51.0

