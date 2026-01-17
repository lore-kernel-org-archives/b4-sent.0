From: David Heidelberg <david@ixit.cz>
Date: Sat, 17 Jan 2026 16:36:18 +0100
Subject: [PATCH v3 3/8] media: qcom: camss: Prepare CSID for C-PHY support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260117-qcom-cphy-v3-3-8ce76a06f7db@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2138; i=david@ixit.cz;
 h=from:subject:message-id; bh=VE5OUEM0X//rg3dmLrS4SJXKFfJ1U9PcL8DiivLtXg0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpa6xzITwS/qRe5tCt5L/y7dS4eFjQyWEM91iFf
 Ze39edfJGeJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaWuscwAKCRBgAj/E00kg
 cgmCD/4+0b1str0cfp4PXBJrESYb8LEnUw1FKC0yicVMLpcrdojfw1/yBTNJ6nY/7uJ1QsU5C/I
 FgTK+htUhY4Lejj7qrl5PZQe9x49m1N57X2b14SKGTek1khbctUmDgLxAs+0AhQZZgNzcPySgNc
 znU3cZFNwfBLMzE4mCwAkMoU68maAqOwNnACf9iA0aMn5WeL/hbtxnaHaPT1bB6lL+3Zw2nUpsX
 W+1QXus9kXgUEDajcszgUG52QcfNsIliYH0aYAa/2BCZPGwNN8pwxEOSDkF7rIbU8A88PuNLwY1
 YGNH99dsgnO9XuZjPcbnKuuTadaQSN8Okvmk6q9cmb6C/nKsVWLM8IiB51nQF0np3w9n7Qvnu9M
 4wBXuujEN6TnQaBCvcpRcWq0QBbN74hCJ8yYihTXEIYl2+BCv/MMBl4O47vmH92ARjCXsPrWrfq
 CMrUEuJjrEUECsT3+gJn805C/LvWTZBDZqAIPpNGd/rm3TRsSMjyIz80CJIcwVKdyHb2DT/RI2n
 er3xig6JevPz4MX3tdcKC9/yG/ioP0CoeyeTS4d059XO59tCHZmlExsbin/zhNWWx1aICgqtswX
 GLxLDe/XheHIJZZdkFLZoOATcAC7OcjX4HWRjq8hXedp+H2NwbX4e9wdLTVXLKSvJ6peOT9FHr8
 IzlNlbo/MJjbIjw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Inherit C-PHY information from CSIPHY, so we can configure CSID
properly.

CSI2_RX_CFG0_PHY_TYPE_SEL must be set to 1, when C-PHY mode is used.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/media/platform/qcom/camss/camss-csid-gen2.c | 1 +
 drivers/media/platform/qcom/camss/camss-csid.c      | 1 +
 drivers/media/platform/qcom/camss/camss-csid.h      | 1 +
 3 files changed, 3 insertions(+)

diff --git a/drivers/media/platform/qcom/camss/camss-csid-gen2.c b/drivers/media/platform/qcom/camss/camss-csid-gen2.c
index 2a1746dcc1c5b..033036ae28a4f 100644
--- a/drivers/media/platform/qcom/camss/camss-csid-gen2.c
+++ b/drivers/media/platform/qcom/camss/camss-csid-gen2.c
@@ -183,6 +183,7 @@ static void __csid_configure_rx(struct csid_device *csid,
 	val = (lane_cnt - 1) << CSI2_RX_CFG0_NUM_ACTIVE_LANES;
 	val |= phy->lane_assign << CSI2_RX_CFG0_DL0_INPUT_SEL;
 	val |= phy->csiphy_id << CSI2_RX_CFG0_PHY_NUM_SEL;
+	val |= csid->phy.cphy << CSI2_RX_CFG0_PHY_TYPE_SEL;
 	writel_relaxed(val, csid->base + CSID_CSI2_RX_CFG0);
 
 	val = 1 << CSI2_RX_CFG1_PACKET_ECC_CORRECTION_EN;
diff --git a/drivers/media/platform/qcom/camss/camss-csid.c b/drivers/media/platform/qcom/camss/camss-csid.c
index ed1820488c987..b50b0cfe280c1 100644
--- a/drivers/media/platform/qcom/camss/camss-csid.c
+++ b/drivers/media/platform/qcom/camss/camss-csid.c
@@ -1275,6 +1275,7 @@ static int csid_link_setup(struct media_entity *entity,
 		csid->phy.csiphy_id = csiphy->id;
 
 		lane_cfg = &csiphy->cfg.csi2->lane_cfg;
+		csid->phy.cphy = (lane_cfg->phy_cfg == V4L2_MBUS_CSI2_CPHY);
 		csid->phy.lane_cnt = lane_cfg->num_data;
 		csid->phy.lane_assign = csid_get_lane_assign(lane_cfg);
 	}
diff --git a/drivers/media/platform/qcom/camss/camss-csid.h b/drivers/media/platform/qcom/camss/camss-csid.h
index aedc96ed84b2f..a82db31bd2335 100644
--- a/drivers/media/platform/qcom/camss/camss-csid.h
+++ b/drivers/media/platform/qcom/camss/camss-csid.h
@@ -70,6 +70,7 @@ struct csid_phy_config {
 	u32 lane_assign;
 	u32 en_vc;
 	u8 need_vc_update;
+	bool cphy;
 };
 
 struct csid_device;

-- 
2.51.0

