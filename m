From: Yassine Oudjana <y.oudjana@protonmail.com>
Date: Sun, 31 May 2026 11:10:43 +0200
Subject: [PATCH v2 2/4] soc: mediatek: pwrap: Add support for MT6735 and
 MT6328 SoC/PMIC pair
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260531-mt6735-pwrap-mt6328-pmic-v2-2-dac37bf92894@protonmail.com>
References: <20260531-mt6735-pwrap-mt6328-pmic-v2-0-dac37bf92894@protonmail.com>
In-Reply-To: <20260531-mt6735-pwrap-mt6328-pmic-v2-0-dac37bf92894@protonmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Flora Fu <flora.fu@mediatek.com>, Alexandre Mergnat <amergnat@baylibre.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: Yassine Oudjana <y.oudjana@protonmail.com>, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, linux-input@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780218643; l=9618;
 i=y.oudjana@protonmail.com; s=20260531; h=from:subject:message-id;
 bh=4sX0Mc13Y67E7+CkHSrLBQ5VssU6E+LoNwfXa6SDJOY=;
 b=uZ2KaiWCsnQzgGRnS2AGox7rSF2hzKvF5lZ6gXm5v3a+j29oP4H4cvHKueLEKep/3BZEMeV2J
 uV5eMgqx09iBo8Nf1Bz3VSAjqK5TqwzIf6vtFzDbWkYbavg8croRITD
X-Developer-Key: i=y.oudjana@protonmail.com; a=ed25519;
 pk=sr7uwnyVqGKAIhvwnIwormkDM3d2VNc3VOTEU1GmsEM=
X-Endpoint-Received: by B4 Relay for y.oudjana@protonmail.com/20260531 with auth_id=802
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add register definitions and configuration for the MT6735 SoC and the
MT6328 PMIC which are commonly paired and communicate through the PMIC
wrapper.

Note that the PMIC wrapper on MT6735M has a slightly different register
map and is therefore NOT compatible with MT6735.

Signed-off-by: Yassine Oudjana <y.oudjana@protonmail.com>
---
 drivers/soc/mediatek/mtk-pmic-wrap.c | 177 ++++++++++++++++++++++++++++++++++-
 1 file changed, 174 insertions(+), 3 deletions(-)

diff --git a/drivers/soc/mediatek/mtk-pmic-wrap.c b/drivers/soc/mediatek/mtk-pmic-wrap.c
index 0bcd85826375..0f14dca5609d 100644
--- a/drivers/soc/mediatek/mtk-pmic-wrap.c
+++ b/drivers/soc/mediatek/mtk-pmic-wrap.c
@@ -3,6 +3,7 @@
  * Copyright (c) 2014 MediaTek Inc.
  * Author: Flora Fu, MediaTek
  */
+
 #include <linux/clk.h>
 #include <linux/interrupt.h>
 #include <linux/io.h>
@@ -100,7 +101,7 @@ enum dew_regs {
 	PWRAP_DEW_CIPHER_MODE,
 	PWRAP_DEW_CIPHER_SWRST,
 
-	/* MT6323 only regs */
+	/* MT6323 and MT6328 only regs */
 	PWRAP_DEW_CIPHER_EN,
 	PWRAP_DEW_RDDMY_NO,
 
@@ -121,8 +122,10 @@ enum dew_regs {
 	PWRAP_RG_SPI_CON13,
 	PWRAP_SPISLV_KEY,
 
-	/* MT6359 only regs */
+	/* MT6359 and MT6328 only regs */
 	PWRAP_DEW_CRC_SWRST,
+
+	/* MT6359 only regs */
 	PWRAP_DEW_RG_EN_RECORD,
 	PWRAP_DEW_RECORD_CMD0,
 	PWRAP_DEW_RECORD_CMD1,
@@ -171,6 +174,23 @@ static const u32 mt6323_regs[] = {
 	[PWRAP_DEW_RDDMY_NO] =		0x01a4,
 };
 
+static const u32 mt6328_regs[] = {
+	[PWRAP_DEW_DIO_EN] =		0x02d4,
+	[PWRAP_DEW_READ_TEST] =		0x02d6,
+	[PWRAP_DEW_WRITE_TEST] =	0x02d8,
+	[PWRAP_DEW_CRC_SWRST] =		0x02da,
+	[PWRAP_DEW_CRC_EN] =		0x02dc,
+	[PWRAP_DEW_CRC_VAL] =		0x02de,
+	[PWRAP_DEW_MON_GRP_SEL] =	0x02e0,
+	[PWRAP_DEW_CIPHER_KEY_SEL] =	0x02e2,
+	[PWRAP_DEW_CIPHER_IV_SEL] =	0x02e4,
+	[PWRAP_DEW_CIPHER_EN] =		0x02e6,
+	[PWRAP_DEW_CIPHER_RDY] =	0x02e8,
+	[PWRAP_DEW_CIPHER_MODE] =	0x02ea,
+	[PWRAP_DEW_CIPHER_SWRST] =	0x02ec,
+	[PWRAP_DEW_RDDMY_NO] =		0x02ee,
+};
+
 static const u32 mt6331_regs[] = {
 	[PWRAP_DEW_DIO_EN] =		0x018c,
 	[PWRAP_DEW_READ_TEST] =		0x018e,
@@ -394,7 +414,7 @@ enum pwrap_regs {
 	PWRAP_ADC_RDATA_ADDR1,
 	PWRAP_ADC_RDATA_ADDR2,
 
-	/* MT7622 only regs */
+	/* MT7622 and MT6735 only regs */
 	PWRAP_STA,
 	PWRAP_CLR,
 	PWRAP_DVFS_ADR8,
@@ -417,6 +437,8 @@ enum pwrap_regs {
 	PWRAP_ADC_RDATA_ADDR,
 	PWRAP_GPS_STA,
 	PWRAP_SW_RST,
+
+	/* MT7622 only regs */
 	PWRAP_DVFS_STEP_CTRL0,
 	PWRAP_DVFS_STEP_CTRL1,
 	PWRAP_DVFS_STEP_CTRL2,
@@ -481,6 +503,13 @@ enum pwrap_regs {
 	/* MT8516 only regs */
 	PWRAP_OP_TYPE,
 	PWRAP_MSB_FIRST,
+
+	/* MT6735 only regs */
+	PWRAP_WACS3_EN,
+	PWRAP_INIT_DONE3,
+	PWRAP_WACS3_CMD,
+	PWRAP_WACS3_RDATA,
+	PWRAP_WACS3_VLDCLR,
 };
 
 static const int mt2701_regs[] = {
@@ -569,6 +598,119 @@ static const int mt2701_regs[] = {
 	[PWRAP_ADC_RDATA_ADDR2] =	0x154,
 };
 
+static const int mt6735_regs[] = {
+	[PWRAP_MUX_SEL] =			0x0,
+	[PWRAP_WRAP_EN] =			0x4,
+	[PWRAP_DIO_EN] =			0x8,
+	[PWRAP_SIDLY] =				0xc,
+	[PWRAP_RDDMY] =				0x10,
+	[PWRAP_SI_CK_CON] =			0x14,
+	[PWRAP_CSHEXT_WRITE] =			0x18,
+	[PWRAP_CSHEXT_READ] =			0x1c,
+	[PWRAP_CSLEXT_START] =			0x20,
+	[PWRAP_CSLEXT_END] =			0x24,
+	[PWRAP_STAUPD_PRD] =			0x28,
+	[PWRAP_STAUPD_GRPEN] =			0x2c,
+	[PWRAP_EINT_STA0_ADR] =			0x30,
+	[PWRAP_EINT_STA1_ADR] =			0x34,
+	[PWRAP_STA] =				0x38,
+	[PWRAP_CLR] =				0x3c,
+	[PWRAP_STAUPD_MAN_TRIG] =		0x40,
+	[PWRAP_STAUPD_STA] =			0x44,
+	[PWRAP_WRAP_STA] =			0x48,
+	[PWRAP_HARB_INIT] =			0x4c,
+	[PWRAP_HARB_HPRIO] =			0x50,
+	[PWRAP_HIPRIO_ARB_EN] =			0x54,
+	[PWRAP_HARB_STA0] =			0x58,
+	[PWRAP_HARB_STA1] =			0x5c,
+	[PWRAP_MAN_EN] =			0x60,
+	[PWRAP_MAN_CMD] =			0x64,
+	[PWRAP_MAN_RDATA] =			0x68,
+	[PWRAP_MAN_VLDCLR] =			0x6c,
+	[PWRAP_WACS0_EN] =			0x70,
+	[PWRAP_INIT_DONE0] =			0x74,
+	[PWRAP_WACS0_CMD] =			0x78,
+	[PWRAP_WACS0_RDATA] =			0x7c,
+	[PWRAP_WACS0_VLDCLR] =			0x80,
+	[PWRAP_WACS1_EN] =			0x84,
+	[PWRAP_INIT_DONE1] =			0x88,
+	[PWRAP_WACS1_CMD] =			0x8c,
+	[PWRAP_WACS1_RDATA] =			0x90,
+	[PWRAP_WACS1_VLDCLR] =			0x94,
+	[PWRAP_WACS2_EN] =			0x98,
+	[PWRAP_INIT_DONE2] =			0x9c,
+	[PWRAP_WACS2_CMD] =			0xa0,
+	[PWRAP_WACS2_RDATA] =			0xa4,
+	[PWRAP_WACS2_VLDCLR] =			0xa8,
+	[PWRAP_WACS3_EN] =			0xac,
+	[PWRAP_INIT_DONE3] =			0xb0,
+	[PWRAP_WACS3_CMD] =			0xb4,
+	[PWRAP_WACS3_RDATA] =			0xb8,
+	[PWRAP_WACS3_VLDCLR] =			0xbc,
+	[PWRAP_INT_EN] =			0xc0,
+	[PWRAP_INT_FLG_RAW] =			0xc4,
+	[PWRAP_INT_FLG] =			0xc8,
+	[PWRAP_INT_CLR] =			0xcc,
+	[PWRAP_SIG_ADR] =			0xd0,
+	[PWRAP_SIG_MODE] =			0xd4,
+	[PWRAP_SIG_VALUE] =			0xd8,
+	[PWRAP_SIG_ERRVAL] =			0xdc,
+	[PWRAP_CRC_EN] =			0xe0,
+	[PWRAP_TIMER_EN] =			0xe4,
+	[PWRAP_TIMER_STA] =			0xe8,
+	[PWRAP_WDT_UNIT] =			0xec,
+	[PWRAP_WDT_SRC_EN] =			0xf0,
+	[PWRAP_WDT_FLG] =			0xf4,
+	[PWRAP_DEBUG_INT_SEL] =			0xf8,
+	[PWRAP_DVFS_ADR0] =			0xfc,
+	[PWRAP_DVFS_WDATA0] =			0x100,
+	[PWRAP_DVFS_ADR1] =			0x104,
+	[PWRAP_DVFS_WDATA1] =			0x108,
+	[PWRAP_DVFS_ADR2] =			0x10c,
+	[PWRAP_DVFS_WDATA2] =			0x110,
+	[PWRAP_DVFS_ADR3] =			0x114,
+	[PWRAP_DVFS_WDATA3] =			0x118,
+	[PWRAP_DVFS_ADR4] =			0x11c,
+	[PWRAP_DVFS_WDATA4] =			0x120,
+	[PWRAP_DVFS_ADR5] =			0x124,
+	[PWRAP_DVFS_WDATA5] =			0x128,
+	[PWRAP_DVFS_ADR6] =			0x12c,
+	[PWRAP_DVFS_WDATA6] =			0x130,
+	[PWRAP_DVFS_ADR7] =			0x134,
+	[PWRAP_DVFS_WDATA7] =			0x138,
+	[PWRAP_DVFS_ADR8] =			0x13c,
+	[PWRAP_DVFS_WDATA8] =			0x140,
+	[PWRAP_DVFS_ADR9] =			0x144,
+	[PWRAP_DVFS_WDATA9] =			0x148,
+	[PWRAP_DVFS_ADR10] =			0x14c,
+	[PWRAP_DVFS_WDATA10] =			0x150,
+	[PWRAP_DVFS_ADR11] =			0x154,
+	[PWRAP_DVFS_WDATA11] =			0x158,
+	[PWRAP_DVFS_ADR12] =			0x15c,
+	[PWRAP_DVFS_WDATA12] =			0x160,
+	[PWRAP_DVFS_ADR13] =			0x164,
+	[PWRAP_DVFS_WDATA13] =			0x168,
+	[PWRAP_DVFS_ADR14] =			0x16c,
+	[PWRAP_DVFS_WDATA14] =			0x170,
+	[PWRAP_DVFS_ADR15] =			0x174,
+	[PWRAP_DVFS_WDATA15] =			0x178,
+	[PWRAP_SPMINF_STA] =			0x17c,
+	[PWRAP_CIPHER_KEY_SEL] =		0x180,
+	[PWRAP_CIPHER_IV_SEL] =			0x184,
+	[PWRAP_CIPHER_EN] =			0x188,
+	[PWRAP_CIPHER_RDY] =			0x18c,
+	[PWRAP_CIPHER_MODE] =			0x190,
+	[PWRAP_CIPHER_SWRST] =			0x194,
+	[PWRAP_DCM_EN] =			0x198,
+	[PWRAP_DCM_DBC_PRD] =			0x19c,
+	[PWRAP_EXT_CK] =			0x1a0,
+	[PWRAP_ADC_CMD_ADDR] =			0x1a4,
+	[PWRAP_PWRAP_ADC_CMD] =			0x1a8,
+	[PWRAP_ADC_RDATA_ADDR] =		0x1ac,
+	[PWRAP_GPS_STA] =			0x1b0,
+	[PWRAP_SW_RST] =			0x1b4,
+};
+
 static const int mt6765_regs[] = {
 	[PWRAP_MUX_SEL] =		0x0,
 	[PWRAP_WRAP_EN] =		0x4,
@@ -1302,6 +1444,7 @@ static const int mt8186_regs[] = {
 
 enum pmic_type {
 	PMIC_MT6323,
+	PMIC_MT6328,
 	PMIC_MT6331,
 	PMIC_MT6332,
 	PMIC_MT6351,
@@ -1314,6 +1457,7 @@ enum pmic_type {
 
 enum pwrap_type {
 	PWRAP_MT2701,
+	PWRAP_MT6735,
 	PWRAP_MT6765,
 	PWRAP_MT6779,
 	PWRAP_MT6795,
@@ -1733,6 +1877,10 @@ static void pwrap_init_chip_select_ext(struct pmic_wrapper *wrp, u8 hext_write,
 static int pwrap_common_init_reg_clock(struct pmic_wrapper *wrp)
 {
 	switch (wrp->master->type) {
+	case PWRAP_MT6735:
+		pwrap_write(wrp, wrp->slave->dew_regs[PWRAP_DEW_RDDMY_NO], 0x8);
+		pwrap_init_chip_select_ext(wrp, 0, 6, 0, 0);
+		break;
 	case PWRAP_MT6795:
 		if (wrp->slave->type == PMIC_MT6331) {
 			const u32 *dew_regs = wrp->slave->dew_regs;
@@ -1839,6 +1987,7 @@ static int pwrap_init_cipher(struct pmic_wrapper *wrp)
 		pwrap_writel(wrp, 1, PWRAP_CIPHER_START);
 		break;
 	case PWRAP_MT2701:
+	case PWRAP_MT6735:
 	case PWRAP_MT6765:
 	case PWRAP_MT6779:
 	case PWRAP_MT6795:
@@ -2194,6 +2343,14 @@ static const struct pwrap_slv_type pmic_mt6323 = {
 		PWRAP_SLV_CAP_SECURITY,
 };
 
+static const struct pwrap_slv_type pmic_mt6328 = {
+	.dew_regs = mt6328_regs,
+	.type = PMIC_MT6328,
+	.regops = &pwrap_regops16,
+	.caps = PWRAP_SLV_CAP_SPI | PWRAP_SLV_CAP_DUALIO |
+		PWRAP_SLV_CAP_SECURITY,
+};
+
 static const struct pwrap_slv_type pmic_mt6331 = {
 	.dew_regs = mt6331_regs,
 	.type = PMIC_MT6331,
@@ -2249,6 +2406,7 @@ static const struct pwrap_slv_type pmic_mt6397 = {
 
 static const struct of_device_id of_slave_match_tbl[] = {
 	{ .compatible = "mediatek,mt6323", .data = &pmic_mt6323 },
+	{ .compatible = "mediatek,mt6328", .data = &pmic_mt6328 },
 	{ .compatible = "mediatek,mt6331", .data = &pmic_mt6331 },
 	{ .compatible = "mediatek,mt6351", .data = &pmic_mt6351 },
 	{ .compatible = "mediatek,mt6357", .data = &pmic_mt6357 },
@@ -2277,6 +2435,18 @@ static const struct pmic_wrapper_type pwrap_mt2701 = {
 	.init_soc_specific = pwrap_mt2701_init_soc_specific,
 };
 
+static const struct pmic_wrapper_type pwrap_mt6735 = {
+	.regs = mt6735_regs,
+	.type = PWRAP_MT6735,
+	.arb_en_all = GENMASK(9, 0),
+	.int_en_all = GENMASK(31, 0),
+	.spi_w = PWRAP_MAN_CMD_SPI_WRITE,
+	.wdt_src = PWRAP_WDT_SRC_MASK_ALL,
+	.caps = PWRAP_CAP_RESET | PWRAP_CAP_DCM,
+	.init_reg_clock = pwrap_common_init_reg_clock,
+	.init_soc_specific = NULL,
+};
+
 static const struct pmic_wrapper_type pwrap_mt6765 = {
 	.regs = mt6765_regs,
 	.type = PWRAP_MT6765,
@@ -2446,6 +2616,7 @@ static const struct pmic_wrapper_type pwrap_mt8186 = {
 
 static const struct of_device_id of_pwrap_match_tbl[] = {
 	{ .compatible = "mediatek,mt2701-pwrap", .data = &pwrap_mt2701 },
+	{ .compatible = "mediatek,mt6735-pwrap", .data = &pwrap_mt6735 },
 	{ .compatible = "mediatek,mt6765-pwrap", .data = &pwrap_mt6765 },
 	{ .compatible = "mediatek,mt6779-pwrap", .data = &pwrap_mt6779 },
 	{ .compatible = "mediatek,mt6795-pwrap", .data = &pwrap_mt6795 },

-- 
2.54.0

