From: David Heidelberg <david@ixit.cz>
Date: Thu, 04 Dec 2025 17:32:35 +0100
Subject: [PATCH WIP v2 1/8] media: qcom: camss: csiphy: Introduce PHY
 configuration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251204-qcom-cphy-v2-1-6b35ef8b071e@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2442; i=david@ixit.cz;
 h=from:subject:message-id; bh=xEPoDiy43IGVbS6hFNBkYfzUa5KA1Mw5KmgqffUeD6M=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpMbesc0tnVqr8cwPWlSiKcumYfxuzqIBw0NK6/
 RHWgXEXgRqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaTG3rAAKCRBgAj/E00kg
 csg0EAC6bEUcxHMUs9HLM6R7beX56GcmLnId0ppw1WPOdqf3B5rCR0rMjXEXmEYW254tKeV2wdj
 QcrZc0xPVZcJGBq/+dfR8bA+Ox32uTRuxRbB2OiTGgDlNtGbjdsK50gJuKcpL7wuJvy5XeVsJL1
 ZrUvTTRJph4LkgfbnTk0uqM6np3ZnnGn65pKFAMU2IxiaDFCAM7xIrgTTQo9H2Y7IwnMtag2PGR
 yXDUKaasAfStJWB29TV1xdx9x7ExXrhAOrIMRpkW7c1pejrpjiaftdR0HgYADUGpyVkRgJCpo06
 pUNXLecS/Itf1woDLgQhgfLss6zzjce2YhoVqKbAKhq+SyKTyXjsLEGrJM9e10iCID8WMb2O02n
 /yL9ku9xRuKY631d1Ix4CipAfCGo36Hi/jgvMpKIeo3Fqg0AGDPJT6FrGDl9SPeMx10OMUwPdeJ
 4WNxDBkKr2CnfUm5o90iwv8bwFTYDLlukEguerLjBa42HLLhyLLpofjxIYsOnr48bqvePxwWNwM
 TlawIvsVykbZhVEXNrqLB76L0cfV0RT6DGfhlse7q9j1jdwEYuouTXB++uT3CIud3eb+swP8VT8
 cDebvDNWJWwsWXq+KSuWM0munN1LcUzcSt7rsgAH2bGGGxm4psk1GkAluTyrwy4k85CFB5Pfgjs
 slK4G+k3Ig6NZKA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Read PHY configuration from the device-tree bus-type and save it into the csiphy
structure for later use.

For C-PHY, skip clock line configuration, as there is none.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/media/platform/qcom/camss/camss-csiphy.h |  2 ++
 drivers/media/platform/qcom/camss/camss.c        | 18 +++++++++++-------
 2 files changed, 13 insertions(+), 7 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy.h b/drivers/media/platform/qcom/camss/camss-csiphy.h
index 895f80003c441..8dcd933b151ec 100644
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
index fcc2b2c3cba07..414646760ae6b 100644
--- a/drivers/media/platform/qcom/camss/camss.c
+++ b/drivers/media/platform/qcom/camss/camss.c
@@ -4043,11 +4043,11 @@ static int camss_of_parse_endpoint_node(struct device *dev,
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
@@ -4055,9 +4055,13 @@ static int camss_of_parse_endpoint_node(struct device *dev,
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

