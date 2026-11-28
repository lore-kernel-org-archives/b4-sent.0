From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: matthias.bgg@gmail.com, angelogioacchino.delregno@collabora.com, 
 robh@kernel.org, krzk+dt@kernel.org, conor+dt@kernel.org
Cc: rva333@protonmail.com, amergnat@baylibre.com, me@adomerle.pw, 
 devicetree@vger.kernel.org, linux-mediatek@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, phone-devel@vger.kernel.org, 
 linux-kernel@vger.kernel.org
Subject: [PATCH v5 3/3] soc: mediatek: mtk-pmic-pwrap: Add MT6789 support
Date: Sat, 28 Nov 2026 04:36:32 +0000
Message-Id: <20261128043629.67417-4-iasnezhkov@gmail.com>
In-Reply-To: <20261128043629.67417-1-iasnezhkov@gmail.com>
References: <20261128043629.67417-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795840589; l=3515;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=+pYLSMXwJ9NiQvGwwMRsrRZ23/yXroYxHZhGWwEq/04=;
 b=L0FHebRo+C8oWpE+WDfSYmZh0ikTiJjDWomJelSI/jNBRMdKsuJf28cARtdkOpMhy3ItV0aex
 C4Vrre4bCgxCXWwOjGzWrNUVlQF2+MAMUP0XlcJNRbkFpPZY8BWDCDg
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Arseniy Velikanov <me@adomerle.pw>

Add PMIC-Wrapper support for the MediaTek MT6789 (Helio G99/G99+/G100/
G200 and tablet/IoT variant MT8781) SoC.

MT6789 uses the PMIF-SPI arbiter interface with the same register layout
as MT8195/MT6833: bank 3 interrupt registers (INT_EN at 0x450, INT_FLG
at 0x458, INT_CLR at 0x45C, mask 0x180000, matching PMIF_IRQ_*_3 in
drivers/spmi/spmi-mtk-pmif.c) and WACS2 software interface at
0x880..0x8A8. Register offsets and wrapper parameters are verified on
live MT6789 hardware (iKKO MindOne, MT6366 PMIC).

Signed-off-by: Arseniy Velikanov <me@adomerle.pw>
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---
Changes since v4:
- Rebased onto linux-next (after mt6572 additions).
- Clarified PMIF bank 3 INT_FLG (0x458) / INT_CLR (0x45C) provenance
  and MT6789 SoC variants in the commit message.

Changes since v2:
- Added PWRAP_INT_FLG (0x458) and PWRAP_INT_CLR (0x45C) matching bank 3
  PWRAP_INT_EN (0x450).
- Depends on patch 2/3 so probing does not write wdt_src to offset 0x0.
- Updated with an AI coding assistant.

 drivers/soc/mediatek/mtk-pmic-wrap.c | 29 ++++++++++++++++++++++++++++
 1 file changed, 29 insertions(+)

diff --git a/drivers/soc/mediatek/mtk-pmic-wrap.c b/drivers/soc/mediatek/mtk-pmic-wrap.c
index bdc0f90..a395b96 100644
--- a/drivers/soc/mediatek/mtk-pmic-wrap.c
+++ b/drivers/soc/mediatek/mtk-pmic-wrap.c
@@ -640,6 +640,19 @@ static const int mt6779_regs[] = {
 	[PWRAP_WACS2_VLDCLR] =		0xC28,
 };
 
+static const int mt6789_regs[] = {
+	[PWRAP_INIT_DONE2] =		0x0,
+	[PWRAP_TIMER_EN] =		0x3E4,
+	[PWRAP_INT_EN] =		0x450,
+	[PWRAP_INT_FLG] =		0x458,
+	[PWRAP_INT_CLR] =		0x45C,
+	[PWRAP_WACS2_CMD] =		0x880,
+	[PWRAP_SWINF_2_WDATA_31_0] =	0x884,
+	[PWRAP_SWINF_2_RDATA_31_0] =	0x894,
+	[PWRAP_WACS2_VLDCLR] =		0x8A4,
+	[PWRAP_WACS2_RDATA] =		0x8A8,
+};
+
 static const int mt6795_regs[] = {
 	[PWRAP_MUX_SEL] =		0x0,
 	[PWRAP_WRAP_EN] =		0x4,
@@ -1317,6 +1330,7 @@ enum pwrap_type {
 	PWRAP_MT6572,
 	PWRAP_MT6765,
 	PWRAP_MT6779,
+	PWRAP_MT6789,
 	PWRAP_MT6795,
 	PWRAP_MT6797,
 	PWRAP_MT6873,
@@ -1859,6 +1873,7 @@ static int pwrap_init_cipher(struct pmic_wrapper *wrp)
 	case PWRAP_MT7622:
 		pwrap_writel(wrp, 0, PWRAP_CIPHER_EN);
 		break;
+	case PWRAP_MT6789:
 	case PWRAP_MT6873:
 	case PWRAP_MT8183:
 	case PWRAP_MT8195:
@@ -2327,6 +2342,19 @@ static const struct pmic_wrapper_type pwrap_mt6779 = {
 	.init_soc_specific = NULL,
 };
 
+static const struct pmic_wrapper_type pwrap_mt6789 = {
+	.regs = mt6789_regs,
+	.type = PWRAP_MT6789,
+	.arb_en_all = 0x777f,
+	.int_en_all = 0x180000,
+	.int1_en_all = 0,
+	.spi_w = PWRAP_MAN_CMD_SPI_WRITE,
+	.wdt_src = PWRAP_WDT_SRC_MASK_ALL,
+	.caps = PWRAP_CAP_ARB,
+	.init_reg_clock = pwrap_common_init_reg_clock,
+	.init_soc_specific = NULL,
+};
+
 static const struct pmic_wrapper_type pwrap_mt6795 = {
 	.regs = mt6795_regs,
 	.type = PWRAP_MT6795,
@@ -2474,6 +2502,7 @@ static const struct of_device_id of_pwrap_match_tbl[] = {
 	{ .compatible = "mediatek,mt6572-pwrap", .data = &pwrap_mt6572 },
 	{ .compatible = "mediatek,mt6765-pwrap", .data = &pwrap_mt6765 },
 	{ .compatible = "mediatek,mt6779-pwrap", .data = &pwrap_mt6779 },
+	{ .compatible = "mediatek,mt6789-pwrap", .data = &pwrap_mt6789 },
 	{ .compatible = "mediatek,mt6795-pwrap", .data = &pwrap_mt6795 },
 	{ .compatible = "mediatek,mt6797-pwrap", .data = &pwrap_mt6797 },
 	{ .compatible = "mediatek,mt6873-pwrap", .data = &pwrap_mt6873 },
-- 
2.54.0 (Apple Git-157)


