From: George Neacsu <geocausa@gmail.com>
Date: Fri, 16 Oct 2026 15:56:13 +0100
Subject: [PATCH v3 3/6] phy: qcom-mipi-csi2: Rename the D-PHY init sequence
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-x1e-cphy-rfc-v3-3-40a346a72153@gmail.com>
References: <20261016-x1e-cphy-rfc-v3-0-40a346a72153@gmail.com>
In-Reply-To: <20261016-x1e-cphy-rfc-v3-0-40a346a72153@gmail.com>
To: Bryan O'Donoghue <bod@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 David Heidelberg <david@ixit.cz>
Cc: Neil Armstrong <neil.armstrong@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Nihal Kumar Gupta <nihal.gupta@oss.qualcomm.com>, 
 Vikram Sharma <vikram.sharma@oss.qualcomm.com>, 
 Suresh Vankadara <svankada@qti.qualcomm.com>, tjose@qti.qualcomm.com, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, linux-phy@lists.infradead.org, 
 linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 George Neacsu <geocausa@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792162570; l=2374;
 i=geocausa@gmail.com; s=20261015; h=from:subject:message-id;
 bh=A4f3txo8ZFwqS2VX8XxM7L9p+S6DusnZS+18o4BDeVo=;
 b=lT1vBk//aXrLmPNBTm9/YQvSEQMRYuLIq8DU7UAvDwJdIpXcyQjiRehgHz7JXb1AwGolvY6GR
 fusquOScyt2DJHUDKvT7iqKB5BL0Klej8XGWBwjT3DHZA5XFKCQfpFt
X-Developer-Key: i=geocausa@gmail.com; a=ed25519;
 pk=KyQk/iWbxsikewDBh0SwlHI51RvAqahD3loqmRp9DVI=
X-Endpoint-Received: by B4 Relay for geocausa@gmail.com/20261015 with auth_id=1199
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The init sequence and its size describe the D-PHY mode only. Call them
dphy_init_seq and dphy_lane_array_size, so that a C-PHY sequence can sit
next to them under matching names.

No functional change.

Suggested-by: Bryan O'Donoghue <bod@kernel.org>
Reviewed-by: Bryan O'Donoghue <bryan.odonoghue@linaro.org>
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: George Neacsu <geocausa@gmail.com>
---
 drivers/phy/qualcomm/phy-qcom-mipi-csi2-3ph-dphy.c | 8 ++++----
 drivers/phy/qualcomm/phy-qcom-mipi-csi2.h          | 4 ++--
 2 files changed, 6 insertions(+), 6 deletions(-)

diff --git a/drivers/phy/qualcomm/phy-qcom-mipi-csi2-3ph-dphy.c b/drivers/phy/qualcomm/phy-qcom-mipi-csi2-3ph-dphy.c
index 966d79c98f..b2d4ec3e81 100644
--- a/drivers/phy/qualcomm/phy-qcom-mipi-csi2-3ph-dphy.c
+++ b/drivers/phy/qualcomm/phy-qcom-mipi-csi2-3ph-dphy.c
@@ -246,8 +246,8 @@ phy_qcom_mipi_csi2_gen2_config_lanes(struct mipi_csi2phy_device *csi2phy,
 				     u8 settle_cnt)
 {
 	const struct mipi_csi2phy_device_regs *regs = csi2phy_dev_to_regs(csi2phy);
-	const struct mipi_csi2phy_lane_regs *r = regs->init_seq;
-	int i, array_size = regs->lane_array_size;
+	const struct mipi_csi2phy_lane_regs *r = regs->dphy_init_seq;
+	int i, array_size = regs->dphy_lane_array_size;
 	u32 val;
 
 	for (i = 0; i < array_size; i++, r++) {
@@ -372,8 +372,8 @@ static struct mipi_csi2_genpd x1e_genpds[] = {
 const struct mipi_csi2phy_soc_cfg mipi_csi2_dphy_4nm_x1e = {
 	.ops = &phy_qcom_mipi_csi2_ops_3ph_1_0,
 	.reg_info = {
-		.init_seq = lane_regs_x1e80100,
-		.lane_array_size = ARRAY_SIZE(lane_regs_x1e80100),
+		.dphy_init_seq = lane_regs_x1e80100,
+		.dphy_lane_array_size = ARRAY_SIZE(lane_regs_x1e80100),
 		.common_regs_offset = 0x1000,
 	},
 	.supply_names = (const char **)x1e_supplies,
diff --git a/drivers/phy/qualcomm/phy-qcom-mipi-csi2.h b/drivers/phy/qualcomm/phy-qcom-mipi-csi2.h
index 7e55ae0073..0d6031a4d8 100644
--- a/drivers/phy/qualcomm/phy-qcom-mipi-csi2.h
+++ b/drivers/phy/qualcomm/phy-qcom-mipi-csi2.h
@@ -48,8 +48,8 @@ struct mipi_csi2phy_lane_regs {
 };
 
 struct mipi_csi2phy_device_regs {
-	const struct mipi_csi2phy_lane_regs *init_seq;
-	const int lane_array_size;
+	const struct mipi_csi2phy_lane_regs *dphy_init_seq;
+	const int dphy_lane_array_size;
 	const u32 common_regs_offset;
 };
 

-- 
2.53.0

