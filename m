From: Roman Vivchar <rva333@protonmail.com>
Date: Wed, 15 Jul 2026 15:26:40 +0300
Subject: [PATCH v2 3/3] soc: mediatek: pwrap: add mt6572 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260715-6572-pwrap-v2-3-bea1d801c81b@protonmail.com>
References: <20260715-6572-pwrap-v2-0-bea1d801c81b@protonmail.com>
In-Reply-To: <20260715-6572-pwrap-v2-0-bea1d801c81b@protonmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Flora Fu <flora.fu@mediatek.com>, Alexandre Mergnat <amergnat@baylibre.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784118429; l=3053;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=734OeVA8OVJF9zkD8y++4eBar+yDgtHe1s1/kC7/Zxk=;
 b=DHzyEVHfr1jchQ2eMIJvIUXEpktNqNFiQGh7LMUnb35+vD/3R+cuXsTBdugL4SGiL0gbHPFa2
 rM7wXhvcZ/VD/JGoEUvtlFqLb5G2V1rzlLb2Sj/aVOaQXvh2Tax15Yw
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add mt6572 registers and platform data for the pmic wrapper.

While vendor kernel source code suggests that mt6572 can be paired with
the mt6320 PMIC, no such devices have been found yet. Hence, registers
that not included in the mt2701 array are omitted.

The mt2701 SoC-specific initialization function is used because they
share the same GPS_INTF settings.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 drivers/soc/mediatek/mtk-pmic-wrap.c | 26 ++++++++++++++++++++++++++
 1 file changed, 26 insertions(+)

diff --git a/drivers/soc/mediatek/mtk-pmic-wrap.c b/drivers/soc/mediatek/mtk-pmic-wrap.c
index a4b10b0a97cb..3f05fc724e15 100644
--- a/drivers/soc/mediatek/mtk-pmic-wrap.c
+++ b/drivers/soc/mediatek/mtk-pmic-wrap.c
@@ -1314,6 +1314,7 @@ enum pmic_type {
 
 enum pwrap_type {
 	PWRAP_MT2701,
+	PWRAP_MT6572,
 	PWRAP_MT6765,
 	PWRAP_MT6779,
 	PWRAP_MT6795,
@@ -1733,6 +1734,11 @@ static void pwrap_init_chip_select_ext(struct pmic_wrapper *wrp, u8 hext_write,
 static int pwrap_common_init_reg_clock(struct pmic_wrapper *wrp)
 {
 	switch (wrp->master->type) {
+	case PWRAP_MT6572:
+		pwrap_writel(wrp, 0x8, PWRAP_RDDMY);
+		pwrap_write(wrp, wrp->slave->dew_regs[PWRAP_DEW_RDDMY_NO], 0x8);
+		pwrap_init_chip_select_ext(wrp, 5, 0, 0, 0);
+		break;
 	case PWRAP_MT6795:
 		if (wrp->slave->type == PMIC_MT6331) {
 			const u32 *dew_regs = wrp->slave->dew_regs;
@@ -1839,6 +1845,7 @@ static int pwrap_init_cipher(struct pmic_wrapper *wrp)
 		pwrap_writel(wrp, 1, PWRAP_CIPHER_START);
 		break;
 	case PWRAP_MT2701:
+	case PWRAP_MT6572:
 	case PWRAP_MT6765:
 	case PWRAP_MT6779:
 	case PWRAP_MT6795:
@@ -2277,6 +2284,24 @@ static const struct pmic_wrapper_type pwrap_mt2701 = {
 	.init_soc_specific = pwrap_mt2701_init_soc_specific,
 };
 
+/*
+ * MT6572 register map is a superset of the MT2701. It has additional registers
+ * OP_TYPE (0x10), MSB_FIRST (0x14), GPS_STA (0x40) and SW_RST (0x180),
+ * which were omitted because the driver doesn't use them.
+ */
+static const struct pmic_wrapper_type pwrap_mt6572 = {
+	.regs = mt2701_regs,
+	.type = PWRAP_MT6572,
+	.arb_en_all = 0x1ff,
+	.int_en_all = 0x7ffffffd,
+	.int1_en_all = 0,
+	.spi_w = PWRAP_MAN_CMD_SPI_WRITE,
+	.wdt_src = PWRAP_WDT_SRC_MASK_ALL,
+	.caps = PWRAP_CAP_RESET | PWRAP_CAP_DCM,
+	.init_reg_clock = pwrap_common_init_reg_clock,
+	.init_soc_specific = pwrap_mt2701_init_soc_specific,
+};
+
 static const struct pmic_wrapper_type pwrap_mt6765 = {
 	.regs = mt6765_regs,
 	.type = PWRAP_MT6765,
@@ -2446,6 +2471,7 @@ static const struct pmic_wrapper_type pwrap_mt8186 = {
 
 static const struct of_device_id of_pwrap_match_tbl[] = {
 	{ .compatible = "mediatek,mt2701-pwrap", .data = &pwrap_mt2701 },
+	{ .compatible = "mediatek,mt6572-pwrap", .data = &pwrap_mt6572 },
 	{ .compatible = "mediatek,mt6765-pwrap", .data = &pwrap_mt6765 },
 	{ .compatible = "mediatek,mt6779-pwrap", .data = &pwrap_mt6779 },
 	{ .compatible = "mediatek,mt6795-pwrap", .data = &pwrap_mt6795 },

-- 
2.54.0

