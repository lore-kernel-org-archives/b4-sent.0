From: Fabricio Akio <fabricioakio@gmail.com>
Date: Fri, 09 Oct 2026 17:45:41 -0300
Subject: [PATCH] interconnect: qcom: sdm660: Enable keep_alive and
 sync_state
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261009-sdm660-icc-sync-state-v1-1-77b8d2501cb2@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQrCMBCF4auUWTswCRoaryIu6mRqp9AomShK6
 d2NunnwLd6/gklRMTh2KxR5quktN7hdBzwN+SqoqRk8+eCIIlpaQiBUZrR3blOHKkgh9ikevBv
 3DO17LzLq69c9nf+2x2UWrt8YbNsH7Hl9cnkAAAA=
X-Change-ID: 20261009-sdm660-icc-sync-state-0698d9521f4c
To: Georgi Djakov <djakov@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>
Cc: AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Krzysztof Kozlowski <krzk@kernel.org>, 
 Alexey Minnekhanov <alexeymin@postmarketos.org>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Martin Botka <martin.botka@somainline.org>, linux-arm-msm@vger.kernel.org, 
 linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791578744; l=3835;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=I6FZICF6sWxIWjC/karjpr0hJtPbBkE7vMKoHoT2/KI=;
 b=Qjski/AvzPL+FBrKuw+xgtHZ9lyEj98SObL44VXbgHIGZciAb+MzmGuz6LgXNy58DYjBVwq7W
 hntLr2Qx8BvBZYBrpBnDlM2LVPklydy+RwiJW7XmJIGxB7cw8252Cfi
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The interconnect core starts every node at INT_MAX and only lowers it in
icc_sync_state(), which this driver never hooks up. Every bus therefore
stays at its maximum rate, in the active and the sleep set.

Hook up icc_sync_state(). Releasing those votes also drops buses that no
driver votes for, so enable keep_alive on the providers with a bus clock,
as QCM2290 does: it keeps a minimum active-set vote and leaves the sleep
set free.

On a Motorola Moto X4 (SDM630) with the screen off, this takes the
battery current from 117 mA to 68 mA.

Fixes: f80a1d414328 ("interconnect: qcom: Add SDM660 interconnect provider driver")
Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
Konrad Dybcio included the sync_state hook-up for this driver in a 2021
fix of its paths [1], Marijn Suijten posted it alone the same year [2],
and Krzysztof Kozlowski for eight Qualcomm drivers in 2022 [3]. Georgi's
concern then was that buses with no bandwidth user would be turned off
at sync state. keep_alive, added since for that case, keeps a minimum
active-set vote on them; QCM2290 and SM6115 use it on all their buses.

Tested on a Motorola Moto X4 (SDM630), whose board file is not in
mainline yet, on the sdm660-mainline tree, with sdm630.dtsi's
interconnect paths as they are in mainline: all six providers synced;
the eMMC, the SD card and the USB gadget worked, and the phone
suspended and resumed.

[1] https://lore.kernel.org/r/20210728222033.52500-1-konrad.dybcio@somainline.org
[2] https://lore.kernel.org/r/20210904111452.248804-1-marijn.suijten@somainline.org
[3] https://lore.kernel.org/r/20220427145616.523557-1-krzysztof.kozlowski@linaro.org
---
 drivers/interconnect/qcom/sdm660.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/interconnect/qcom/sdm660.c b/drivers/interconnect/qcom/sdm660.c
index d8c979a12235..82dd0b916e1f 100644
--- a/drivers/interconnect/qcom/sdm660.c
+++ b/drivers/interconnect/qcom/sdm660.c
@@ -1514,6 +1514,7 @@ static const struct qcom_icc_desc sdm660_a2noc = {
 	.intf_clocks = a2noc_intf_clocks,
 	.num_intf_clocks = ARRAY_SIZE(a2noc_intf_clocks),
 	.regmap_cfg = &sdm660_a2noc_regmap_config,
+	.keep_alive = true,
 };
 
 static struct qcom_icc_node * const sdm660_bimc_nodes[] = {
@@ -1542,6 +1543,7 @@ static const struct qcom_icc_desc sdm660_bimc = {
 	.bus_clk_desc = &bimc_clk,
 	.regmap_cfg = &sdm660_bimc_regmap_config,
 	.ab_coeff = 153,
+	.keep_alive = true,
 };
 
 static struct qcom_icc_node * const sdm660_cnoc_nodes[] = {
@@ -1597,6 +1599,7 @@ static const struct qcom_icc_desc sdm660_cnoc = {
 	.num_nodes = ARRAY_SIZE(sdm660_cnoc_nodes),
 	.bus_clk_desc = &bus_2_clk,
 	.regmap_cfg = &sdm660_cnoc_regmap_config,
+	.keep_alive = true,
 };
 
 static struct qcom_icc_node * const sdm660_gnoc_nodes[] = {
@@ -1662,6 +1665,7 @@ static const struct qcom_icc_desc sdm660_mnoc = {
 	.num_intf_clocks = ARRAY_SIZE(mm_intf_clocks),
 	.regmap_cfg = &sdm660_mnoc_regmap_config,
 	.ab_coeff = 153,
+	.keep_alive = true,
 };
 
 static struct qcom_icc_node * const sdm660_snoc_nodes[] = {
@@ -1698,6 +1702,7 @@ static const struct qcom_icc_desc sdm660_snoc = {
 	.num_nodes = ARRAY_SIZE(sdm660_snoc_nodes),
 	.bus_clk_desc = &bus_1_clk,
 	.regmap_cfg = &sdm660_snoc_regmap_config,
+	.keep_alive = true,
 };
 
 static const struct of_device_id sdm660_noc_of_match[] = {
@@ -1717,6 +1722,7 @@ static struct platform_driver sdm660_noc_driver = {
 	.driver = {
 		.name = "qnoc-sdm660",
 		.of_match_table = sdm660_noc_of_match,
+		.sync_state = icc_sync_state,
 	},
 };
 module_platform_driver(sdm660_noc_driver);

---
base-commit: aac26bee2287c88af5be5a5ff96d783b19a28790
change-id: 20261009-sdm660-icc-sync-state-0698d9521f4c

Best regards,
--  
Fabricio Akio <fabricioakio@gmail.com>

