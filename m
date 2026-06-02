From: David Heidelberg <david@ixit.cz>
Date: Wed, 03 Jun 2026 01:30:39 +0200
Subject: [PATCH v6 1/8] media: qcom: camss: csiphy: Introduce PHY
 configuration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260603-qcom-cphy-v6-1-e50de0b557a8@ixit.cz>
References: <20260603-qcom-cphy-v6-0-e50de0b557a8@ixit.cz>
In-Reply-To: <20260603-qcom-cphy-v6-0-e50de0b557a8@ixit.cz>
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Bryan O'Donoghue <bod@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, Petr Hodina <phodina@protonmail.com>, 
 "Dr. Git" <drgitx@gmail.com>, Cory Keitz <ckeitz@amazon.com>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Kieran Bingham <kbingham@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, linux-media@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2386; i=david@ixit.cz;
 h=from:subject:message-id; bh=KqK7CczWYX/iIrUS5Nv8VtWWkWE2d7OmmtIR810fNRE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqH2eqIY7n1nYt0dC+7KaI6/rvWxHbk90teL16L
 FoElXc/9iuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCah9nqgAKCRBgAj/E00kg
 cqr6D/0UyrGMxN8RIkODM7OEU3BX1HeqrVc+JAqk+QGldd6wy9xOFU/c/Gz/r7NqtKrnClDOcbI
 8kNaOSWQDX0BqcKEBm5XUDbuA2TkNyvxQa14B3JYwHKz4heijzwhdktrwA6Feu3rRnHRtmY4irb
 bCV51YZmrisDh/Xnjp2JyFVDA7vo+ZLY7WRGaARbmhr0hZde3ITLReVnYa0jWkm5Voc3eNp4NpM
 jAZXWcSQunJuTeg/Yz7mmJJsvD4RLm2M3VTT7beqHjVtr1XeCXhvBzlPU8bLb6JuiC3Z0wWXT+q
 /iTTO2TLxmYPGF/U9aPIyu7K6Aq8cEE2KLDTb3JCuCYph8Q1qV6cFSQTnV6+jTYXGnQCUFM3pvE
 BYFl6XICOTH6un+DQhlKUV/nNL0kZ+8/sHoiVkFECPr+EQYL+Ra6uW2e5BcrPr/LIvoIso0CbVI
 HwNSYlWC6WKIF1+8l+j3/FH2Yte9+b4GPR8V/lIn1CLyv9eAcCxJHvUwlzLLJGZoF0BAicF02sY
 z5zP7tk8ayL6FaJay6Y86vlQ4yJB+FC9PlAQ+5ZHBaTU704k8bMB/vV+3dE/9dSYGGmYoHlcUyc
 vU1LGbaoAtzQ9J4R8OwDPAA6mdzla1BfB9j4thYecShQT+pcAYfUBfTq0r3nzQIlpL9Oa6fVPim
 t3wxbakRiryAFLw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Read PHY configuration from the device-tree bus-type and save it into
the csiphy structure for later use.

For C-PHY, skip clock line configuration, as there is none.

Acked-by: Cory Keitz <ckeitz@amazon.com>
Reviewed-by: Bryan O'Donoghue <bod@kernel.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/media/platform/qcom/camss/camss-csiphy.h | 2 ++
 drivers/media/platform/qcom/camss/camss.c        | 8 ++++++--
 2 files changed, 8 insertions(+), 2 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy.h b/drivers/media/platform/qcom/camss/camss-csiphy.h
index 9d9657b82f748..2ebb307be18ba 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy.h
+++ b/drivers/media/platform/qcom/camss/camss-csiphy.h
@@ -25,21 +25,23 @@
 
 struct csiphy_lane {
 	u8 pos;
 	u8 pol;
 };
 
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
 };
 
 struct csiphy_csi2_cfg {
 	struct csiphy_lanes_cfg lane_cfg;
 };
diff --git a/drivers/media/platform/qcom/camss/camss.c b/drivers/media/platform/qcom/camss/camss.c
index 2123f6388e3d7..072c428e25166 100644
--- a/drivers/media/platform/qcom/camss/camss.c
+++ b/drivers/media/platform/qcom/camss/camss.c
@@ -4761,19 +4761,23 @@ static int camss_parse_endpoint_node(struct device *dev,
 	if (vep.bus_type != V4L2_MBUS_CSI2_DPHY) {
 		dev_err(dev, "Unsupported bus type %d\n", vep.bus_type);
 		return -EINVAL;
 	}
 
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
 				   GFP_KERNEL);
 	if (!lncfg->data)
 		return -ENOMEM;
 
 	for (i = 0; i < lncfg->num_data; i++) {

-- 
2.53.0

