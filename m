From: David Heidelberg <david@ixit.cz>
Date: Sat, 17 Jan 2026 16:36:16 +0100
Subject: [PATCH v3 1/8] media: qcom: camss: csiphy: Introduce PHY
 configuration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260117-qcom-cphy-v3-1-8ce76a06f7db@ixit.cz>
References: <20260117-qcom-cphy-v3-0-8ce76a06f7db@ixit.cz>
In-Reply-To: <20260117-qcom-cphy-v3-0-8ce76a06f7db@ixit.cz>
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
 h=from:subject:message-id; bh=mQVMyUAqZChIt7A9c/SYnHbFFHnHmz7GAPKyVmtGOoM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpa6xzxGDJZ3mmtQVncbRDgsQ27+lgn37KiiyGu
 wyjz8yF7bOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaWuscwAKCRBgAj/E00kg
 crN+EACuLya4+/XMUY4t0rfm29bG8EUuGEpch/rxS82NT+XxNaLj4lhD0FAb6GHnIfaC8s7U0pa
 G3cvhmXPilXzTwV4C9F5cS2s4kcr4Rsu35IHb4UnTqO60NPdqzkQiCpg/PLE/mlFCcKa7vb1kb8
 lWxk307bhFzbXxsEV47dF8uB2u0LgowgLOk2jU6DZ+XE1CzEBXgM7a8BsUvmDEnxzCkA7RzYdVM
 +HdXzsgaFhmmBdRT+3pUsAEtBbWfuX2LH6Utnc/y24UxFKeDwuz8maKARdEx7fbcxCwuv8UTC3a
 +mCzj5v7uHcPCBCrz8Eqhl4MiIg4PkjnzO7DuI6rJ00y4aEnb/VI9vFx7hhJO6h79c4zLSbRRtD
 Z4HneoGvQ6kOczplakt6N4/FwVui0KEdzcF/IQhzHXHyUA8alJBRK8t86u7OFYgEmK1326UtJx+
 XFrikQGY8F9lZQSU4ccExX9gzrBK4DlgHisaQ29MywbxLfjrAPHAGke7uSb5z7q/t+hZ2UWG9cA
 H7cbiQVeZNfLt9MQPVcjt1cRYpFxn2pBNyIfatSCCv2qs3xBeaetLivDTApxGI5vmWK/u3AUyie
 vqurtHIIMboXc9M8FITR6Q8LZLITjq/hRNXt4lxUxmJkk/iQaJR8nzu8fMGq0ZpDtSskVn7BM1H
 2AlR2FYn/k1Yggw==
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

