From: Ben Grisdale <bengris32@protonmail.ch>
Date: Tue, 17 Nov 2026 13:28:09 +0000
Subject: [PATCH 2/2] soc: mediatek: pwrap: Add support for MT8163
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-mt8163-pwrap-support-v1-2-b00fa10035a5@protonmail.ch>
References: <20261117-mt8163-pwrap-support-v1-0-b00fa10035a5@protonmail.ch>
In-Reply-To: <20261117-mt8163-pwrap-support-v1-0-b00fa10035a5@protonmail.ch>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Flora Fu <flora.fu@mediatek.com>, Alexandre Mergnat <amergnat@baylibre.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Ben Grisdale <bengris32@protonmail.ch>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794922196; l=2470;
 i=bengris32@protonmail.ch; s=20261018; h=from:subject:message-id;
 bh=KQUjaX3+qHhIzKElI39Z3bS/gua1IXmfn76JotbTuig=;
 b=gm0V6u3IzWo4u7S4ZP1d/kO5qqkgUlZOnWou9QMh46QFPLBd6oF5sDCTHVSXZhgnmh4o73IfV
 qWpXBUHM1S4DsdpRnkJt5cMMprrUXigxd4o38mkZ4aD/cqxKqTXzmJu
X-Developer-Key: i=bengris32@protonmail.ch; a=ed25519;
 pk=4ewFRC2yNph/tXokHVzIDlgOA9Hxecf1AlBuD4eOnaU=
X-Endpoint-Received: by B4 Relay for bengris32@protonmail.ch/20261018 with auth_id=1233
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the PMIC wrapper on the MediaTek MT8163 SoC.

The register layout is identical to MT8516, so re-use its array.

Additionally, as all known MT8163 devices use the MT6323 PMIC,
re-use the reg clock init from MT2701.

Signed-off-by: Ben Grisdale <bengris32@protonmail.ch>
---
 drivers/soc/mediatek/mtk-pmic-wrap.c | 17 +++++++++++++++++
 1 file changed, 17 insertions(+)

diff --git a/drivers/soc/mediatek/mtk-pmic-wrap.c b/drivers/soc/mediatek/mtk-pmic-wrap.c
index 90677187c3b5..e4aa42614113 100644
--- a/drivers/soc/mediatek/mtk-pmic-wrap.c
+++ b/drivers/soc/mediatek/mtk-pmic-wrap.c
@@ -1321,6 +1321,7 @@ enum pwrap_type {
 	PWRAP_MT6873,
 	PWRAP_MT7622,
 	PWRAP_MT8135,
+	PWRAP_MT8163,
 	PWRAP_MT8173,
 	PWRAP_MT8183,
 	PWRAP_MT8186,
@@ -1843,6 +1844,7 @@ static int pwrap_init_cipher(struct pmic_wrapper *wrp)
 	case PWRAP_MT6779:
 	case PWRAP_MT6795:
 	case PWRAP_MT6797:
+	case PWRAP_MT8163:
 	case PWRAP_MT8173:
 	case PWRAP_MT8186:
 	case PWRAP_MT8365:
@@ -2063,6 +2065,8 @@ static int pwrap_init(struct pmic_wrapper *wrp)
 	switch (wrp->master->type) {
 	case PWRAP_MT6795:
 		fallthrough;
+	case PWRAP_MT8163:
+		fallthrough;
 	case PWRAP_MT8173:
 		/* Enable DCM */
 		pwrap_writel(wrp, 3, PWRAP_DCM_EN);
@@ -2367,6 +2371,18 @@ static const struct pmic_wrapper_type pwrap_mt8135 = {
 	.init_soc_specific = pwrap_mt8135_init_soc_specific,
 };
 
+static const struct pmic_wrapper_type pwrap_mt8163 = {
+	.regs = mt8516_regs,
+	.type = PWRAP_MT8163,
+	.arb_en_all = 0xff,
+	.int_en_all = ~(u32)(BIT(31) | BIT(2)),
+	.int1_en_all = 0,
+	.spi_w = PWRAP_MAN_CMD_SPI_WRITE,
+	.wdt_src = PWRAP_WDT_SRC_MASK_ALL,
+	.caps = PWRAP_CAP_RESET | PWRAP_CAP_DCM,
+	.init_reg_clock = pwrap_mt2701_init_reg_clock,
+};
+
 static const struct pmic_wrapper_type pwrap_mt8173 = {
 	.regs = mt8173_regs,
 	.type = PWRAP_MT8173,
@@ -2453,6 +2469,7 @@ static const struct of_device_id of_pwrap_match_tbl[] = {
 	{ .compatible = "mediatek,mt6873-pwrap", .data = &pwrap_mt6873 },
 	{ .compatible = "mediatek,mt7622-pwrap", .data = &pwrap_mt7622 },
 	{ .compatible = "mediatek,mt8135-pwrap", .data = &pwrap_mt8135 },
+	{ .compatible = "mediatek,mt8163-pwrap", .data = &pwrap_mt8163 },
 	{ .compatible = "mediatek,mt8173-pwrap", .data = &pwrap_mt8173 },
 	{ .compatible = "mediatek,mt8183-pwrap", .data = &pwrap_mt8183 },
 	{ .compatible = "mediatek,mt8186-pwrap", .data = &pwrap_mt8186 },

-- 
2.56.0

