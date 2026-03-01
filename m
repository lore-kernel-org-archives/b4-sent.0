From: David Heidelberg <david@ixit.cz>
Date: Sun, 01 Mar 2026 01:51:20 +0100
Subject: [PATCH WIP v4 1/9] media: qcom: camss: csiphy: Introduce PHY
 configuration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260301-qcom-cphy-v4-1-e53316d2cc65@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2436; i=david@ixit.cz;
 h=from:subject:message-id; bh=fhIzjHIhntdawDvw/VMdM6pBEENvqjYRoy0HoF3mVWw=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpo42I6Y/aJq6dhwi6AWhqxIqqSSAg9MDiUQ6Z7
 w2eVnWyC4WJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaaONiAAKCRBgAj/E00kg
 chmmD/9EXYIok2Wx8kEYQRiyPR6DvpnA3q42iNGQ6YoEFAQQ1ldoIDM2xlig9HGdFHYzOScGn5w
 qatBjeQhr4T76qFgHq5CJ5VeoNNbkNZFt26uc3CyD1kO2KP41BhtJtJneRywbZ8ixUUQaozy93k
 KyN+cZejjcLPwCyfIZKHx8Echcv1SxGo5S0+klqUXg8DIqKzyqrPSWEkrreKGuQOUE1j7VyKScT
 IGcWzYN6TieHngJEdseApXKzkubAT1ukVNSZr/VHAqxfcrvHMKiVLdZcN548h6y+UPcD+rFN0Yh
 wkc86PfSC9Vx2vqa0RkIfNIGON2SjtSeyGG5ak0kuc9ihsOc/E93DH0EajeuXGf2/7AKiDsGPQ+
 h9RTLHpAHeeUa7dNerApyz6U6d55rtDBRmW3MWQ2pLKp12+V2buNxp0QBKjQJ1zZxG24ZTtOiNe
 BKcCJuh47oSutsQwxUpjcuVD2ViICIaSVtyoh6F9e/9GfhIp4tsu7WPxUZhqfPufJam3ULxnhms
 s+6li9EqNO2mrWWtfJNvsKEvSGPx2zSk9zaI8FRFBjGP6EKEzqHS5l7yQ84sRLLUYI0qx1POTac
 1OKmo7mc8x8wr7QThN41s0CMXxUmxBhTytO6HbD1QHWthyTBU6wVtEm5ibNm8aM25OF8+tcL+jf
 AhlHcNSA/jx88dw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Read PHY configuration from the device-tree bus-type and save it into
the csiphy structure for later use.

For C-PHY, skip clock line configuration, as there is none.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/media/platform/qcom/camss/camss-csiphy.h |  2 ++
 drivers/media/platform/qcom/camss/camss.c        | 18 +++++++++++-------
 2 files changed, 13 insertions(+), 7 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy.h b/drivers/media/platform/qcom/camss/camss-csiphy.h
index 2d5054819df7f..d198171700e73 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy.h
+++ b/drivers/media/platform/qcom/camss/camss-csiphy.h
@@ -28,11 +28,13 @@ struct csiphy_lane {
 
 /**
  * struct csiphy_lanes_cfg - CSIPHY lanes configuration
+ * @phy_cfg:  interface selection (C-PHY or D-PHY)
  * @num_data: number of data lanes
  * @data:     data lanes configuration
  * @clk:      clock lane configuration (only for D-PHY)
  */
 struct csiphy_lanes_cfg {
+	enum v4l2_mbus_type phy_cfg;
 	int num_data;
 	struct csiphy_lane *data;
 	struct csiphy_lane clk;
diff --git a/drivers/media/platform/qcom/camss/camss.c b/drivers/media/platform/qcom/camss/camss.c
index 00b87fd9afbd8..ea0c8cf3cd806 100644
--- a/drivers/media/platform/qcom/camss/camss.c
+++ b/drivers/media/platform/qcom/camss/camss.c
@@ -4411,11 +4411,11 @@ static int camss_parse_endpoint_node(struct device *dev,
 	if (ret)
 		return ret;
 
-	/*
-	 * Most SoCs support both D-PHY and C-PHY standards, but currently only
-	 * D-PHY is supported in the driver.
-	 */
-	if (vep.bus_type != V4L2_MBUS_CSI2_DPHY) {
+	switch (vep.bus_type) {
+	case V4L2_MBUS_CSI2_CPHY:
+	case V4L2_MBUS_CSI2_DPHY:
+		break;
+	default:
 		dev_err(dev, "Unsupported bus type %d\n", vep.bus_type);
 		return -EINVAL;
 	}
@@ -4423,9 +4423,13 @@ static int camss_parse_endpoint_node(struct device *dev,
 	csd->interface.csiphy_id = vep.base.port;
 
 	mipi_csi2 = &vep.bus.mipi_csi2;
-	lncfg->clk.pos = mipi_csi2->clock_lane;
-	lncfg->clk.pol = mipi_csi2->lane_polarities[0];
 	lncfg->num_data = mipi_csi2->num_data_lanes;
+	lncfg->phy_cfg = vep.bus_type;
+
+	if (lncfg->phy_cfg != V4L2_MBUS_CSI2_CPHY) {
+		lncfg->clk.pos = mipi_csi2->clock_lane;
+		lncfg->clk.pol = mipi_csi2->lane_polarities[0];
+	}
 
 	lncfg->data = devm_kcalloc(dev,
 				   lncfg->num_data, sizeof(*lncfg->data),

-- 
2.51.0

