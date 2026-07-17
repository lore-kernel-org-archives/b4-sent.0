From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Fri, 17 Jul 2026 07:49:35 +0000
Subject: [PATCH 3/3] spi: amlogic: spisg: Add support for A9 controller
 features
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260717-a9-spisg-v1-3-2eeea77be19f@amlogic.com>
References: <20260717-a9-spisg-v1-0-2eeea77be19f@amlogic.com>
In-Reply-To: <20260717-a9-spisg-v1-0-2eeea77be19f@amlogic.com>
To: Sunny Luo <sunny.luo@amlogic.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-spi@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784274574; l=5993;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=hSBlHqyRKAFzXRe5Mipf9iWE55K2Qe+NrDF5i5K4r+4=;
 b=oJ1QsKwU7s3BAluM3mGKO9WRC4zRwLYDoY+4s6U5EPkqNgmGIe7vUcOeypBUE1oHw6hxR2dVa
 XfpSOOFoTCRA8vjc421OToQlLakawI22icz4mguovajuGe6u7QescAl
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Amlogic A9 SPISG controller extends the A4 controller with additional
configuration options, including:

- Extended CS setup timing
- Hardware-controlled CS hold timing
- MOSI idle output configuration
- Configurable word gap

Add SoC-specific capability data and configure these features when they
are supported by the underlying hardware while keeping compatibility with
existing A4 controllers.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 drivers/spi/spi-amlogic-spisg.c | 65 ++++++++++++++++++++++++++++++++++++++---
 1 file changed, 61 insertions(+), 4 deletions(-)

diff --git a/drivers/spi/spi-amlogic-spisg.c b/drivers/spi/spi-amlogic-spisg.c
index 0f026d3e43e0..845eb81d483a 100644
--- a/drivers/spi/spi-amlogic-spisg.c
+++ b/drivers/spi/spi-amlogic-spisg.c
@@ -37,6 +37,12 @@
 #define CFG_HW_POS			BIT(6)
 /* start on vsync falling */
 #define CFG_HW_NEG			BIT(7)
+#define CFG_WORD_GAP			GENMASK(9, 8)
+#define CFG_MO_IDLE_OUTPUT		GENMASK(11, 10)
+/* cs hold time in pclk */
+#define CFG_CS_HOLD			GENMASK(26, 12)
+/* high 4 bits of cs setup time in sclk */
+#define CFG_CS_SETUP_EXTEND		GENMASK(30, 27)
 
 #define SPISG_REG_CFG_START		0x08
 #define CFG_BLOCK_NUM			GENMASK(19, 0)
@@ -143,6 +149,13 @@ struct spisg_descriptor_extra {
 	int				rx_ccsg_len;
 };
 
+struct aml_spisg_data {
+	bool				mo_idle_output_ctrl;
+	bool				word_gap_ctrl;
+	bool				cs_hold_ctrl;
+	bool				cs_setup_extend_ctrl;
+};
+
 struct spisg_device {
 	struct spi_controller		*controller;
 	struct platform_device		*pdev;
@@ -152,6 +165,7 @@ struct spisg_device {
 	struct clk			*sclk;
 	struct clk_div_table		*tbl;
 	struct completion		completion;
+	const struct aml_spisg_data	*data;
 	u32				status;
 	u32				speed_hz;
 	u32				effective_speed_hz;
@@ -483,6 +497,7 @@ static int aml_spisg_transfer_one_message(struct spi_controller *ctlr,
 {
 	struct spisg_device *spisg = spi_controller_get_devdata(ctlr);
 	struct device *dev = &spisg->pdev->dev;
+	const struct aml_spisg_data *data = spisg->data;
 	unsigned long long ms = 0;
 	struct spi_transfer *xfer;
 	struct spisg_descriptor *descs, *desc;
@@ -491,6 +506,7 @@ static int aml_spisg_transfer_one_message(struct spi_controller *ctlr,
 	int desc_num = 1, descs_len;
 	bool last_xfer_keep_ss = false;
 	u32 cs_hold_in_sclk = 0;
+	u32 val;
 	int ret = -EIO;
 
 	if (!aml_spisg_sem_down_read(spisg)) {
@@ -525,9 +541,17 @@ static int aml_spisg_transfer_one_message(struct spi_controller *ctlr,
 		}
 
 		/* calculate cs-setup delay with the first xfer speed */
-		if (list_is_first(&xfer->transfer_list, &msg->transfers))
-			desc->cfg_bus |= FIELD_PREP(CFG_CS_SETUP,
-				spi_delay_to_sclk(xfer->effective_speed_hz, &msg->spi->cs_setup));
+		if (list_is_first(&xfer->transfer_list, &msg->transfers)) {
+			val = spi_delay_to_sclk(xfer->effective_speed_hz, &msg->spi->cs_setup);
+			if (data && data->cs_setup_extend_ctrl) {
+				val = min_t(u32, 0xFF, val);
+				desc->cfg_bus |= FIELD_PREP(CFG_CS_SETUP, val & 0xF);
+				FIELD_MODIFY(CFG_CS_SETUP_EXTEND, &spisg->cfg_spi, val >> 4);
+			} else {
+				val = min_t(u32, 0xF, val);
+				desc->cfg_bus |= FIELD_PREP(CFG_CS_SETUP, val);
+			}
+		}
 
 		/* calculate cs-hold delay with the last xfer speed */
 		if (list_is_last(&xfer->transfer_list, &msg->transfers)) {
@@ -542,7 +566,12 @@ static int aml_spisg_transfer_one_message(struct spi_controller *ctlr,
 				       xfer->effective_speed_hz);
 	}
 
-	if (cs_hold_in_sclk) {
+	if (data && data->cs_hold_ctrl) {
+		cs_hold_in_sclk = cs_hold_in_sclk ? : 1;
+		val = cs_hold_in_sclk * (FIELD_GET(CFG_CLK_DIV, spisg->cfg_bus) + 1);
+		FIELD_MODIFY(CFG_CS_HOLD, &spisg->cfg_spi, val);
+		desc--;
+	} else if (cs_hold_in_sclk) {
 		/* additional null-descriptor to achieve the cs-hold delay */
 		aml_spisg_setup_null_desc(spisg, desc, cs_hold_in_sclk);
 		desc--;
@@ -722,6 +751,7 @@ static int aml_spisg_probe(struct platform_device *pdev)
 	struct spisg_device *spisg;
 	struct device *dev = &pdev->dev;
 	void __iomem *base;
+	u32 val = 0;
 	int ret, irq;
 
 	const struct regmap_config aml_regmap_config = {
@@ -740,6 +770,7 @@ static int aml_spisg_probe(struct platform_device *pdev)
 
 	spisg = spi_controller_get_devdata(ctlr);
 	spisg->controller = ctlr;
+	spisg->data = (struct aml_spisg_data *)of_device_get_match_data(dev);
 
 	spisg->pdev = pdev;
 	platform_set_drvdata(pdev, spisg);
@@ -770,6 +801,21 @@ static int aml_spisg_probe(struct platform_device *pdev)
 
 	spisg->cfg_spi = FIELD_PREP(CFG_SFLASH_WP, 1) |
 			 FIELD_PREP(CFG_SFLASH_HD, 1);
+
+	if (spisg->data && spisg->data->mo_idle_output_ctrl) {
+		if (!of_property_read_u32(dev->of_node, "amlogic,mo-idle-output", &val))
+			spisg->cfg_spi |=  FIELD_PREP(CFG_MO_IDLE_OUTPUT, val);
+		else
+			spisg->cfg_spi |=  FIELD_PREP(CFG_MO_IDLE_OUTPUT, 0);
+	}
+
+	if (spisg->data && spisg->data->word_gap_ctrl) {
+		if (!of_property_read_u32(dev->of_node, "amlogic,word-gap", &val))
+			spisg->cfg_spi |=  FIELD_PREP(CFG_WORD_GAP, val);
+		else
+			spisg->cfg_spi |=  FIELD_PREP(CFG_WORD_GAP, 1);
+	}
+
 	if (spi_controller_is_target(ctlr)) {
 		spisg->cfg_spi |= FIELD_PREP(CFG_SLAVE_EN, 1);
 		spisg->cfg_bus = FIELD_PREP(CFG_TX_TUNING, 0xf);
@@ -856,6 +902,13 @@ static int spisg_resume_runtime(struct device *dev)
 	return 0;
 }
 
+static const struct aml_spisg_data a9_spisg_data = {
+	.mo_idle_output_ctrl = true,
+	.word_gap_ctrl = true,
+	.cs_hold_ctrl = true,
+	.cs_setup_extend_ctrl = true,
+};
+
 static const struct dev_pm_ops amlogic_spisg_pm_ops = {
 	.runtime_suspend	= spisg_suspend_runtime,
 	.runtime_resume		= spisg_resume_runtime,
@@ -865,6 +918,10 @@ static const struct of_device_id amlogic_spisg_of_match[] = {
 	{
 		.compatible = "amlogic,a4-spisg",
 	},
+	{
+		.compatible = "amlogic,a9-spisg",
+		.data = &a9_spisg_data,
+	},
 
 	{ /* sentinel */ }
 };

-- 
2.52.0

