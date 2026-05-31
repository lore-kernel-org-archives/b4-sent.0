From: Yassine Oudjana <y.oudjana@protonmail.com>
Date: Sun, 31 May 2026 11:10:45 +0200
Subject: [PATCH v2 4/4] Input: mtk-pmic-keys - Add support for MT6328
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260531-mt6735-pwrap-mt6328-pmic-v2-4-dac37bf92894@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780218643; l=1904;
 i=y.oudjana@protonmail.com; s=20260531; h=from:subject:message-id;
 bh=CI2JtjrfQGfceMW9Mo7uuZDEncWSbsLSjy6NPimDCZ8=;
 b=YumAYlYpzOnp4NdRv+QSZzgC27vFRedblud7yqmZoD1WccQnx+bmUwOBZrHH5iqjvuYbuKUR/
 4msldZHl4rBCGFN1KEIleh8cgcC0AuzhnP4TgGssjazW09rDi/Yage7
X-Developer-Key: i=y.oudjana@protonmail.com; a=ed25519;
 pk=sr7uwnyVqGKAIhvwnIwormkDM3d2VNc3VOTEU1GmsEM=
X-Endpoint-Received: by B4 Relay for y.oudjana@protonmail.com/20260531 with auth_id=802
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a compatible string and related data for the PMIC keys on the
MT6328 PMIC.

Signed-off-by: Yassine Oudjana <y.oudjana@protonmail.com>
Acked-by: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Reviewed-by: AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
---
 drivers/input/keyboard/mtk-pmic-keys.c | 15 +++++++++++++++
 1 file changed, 15 insertions(+)

diff --git a/drivers/input/keyboard/mtk-pmic-keys.c b/drivers/input/keyboard/mtk-pmic-keys.c
index c78d9f6d97c4..6aaca67e7703 100644
--- a/drivers/input/keyboard/mtk-pmic-keys.c
+++ b/drivers/input/keyboard/mtk-pmic-keys.c
@@ -9,6 +9,7 @@
 #include <linux/interrupt.h>
 #include <linux/kernel.h>
 #include <linux/mfd/mt6323/registers.h>
+#include <linux/mfd/mt6328/registers.h>
 #include <linux/mfd/mt6331/registers.h>
 #include <linux/mfd/mt6357/registers.h>
 #include <linux/mfd/mt6358/registers.h>
@@ -80,6 +81,17 @@ static const struct mtk_pmic_regs mt6323_regs = {
 	.rst_lprst_mask = MTK_PMIC_RST_DU_MASK,
 };
 
+static const struct mtk_pmic_regs mt6328_regs = {
+	.keys_regs[MTK_PMIC_PWRKEY_INDEX] =
+		MTK_PMIC_KEYS_REGS(MT6328_TOPSTATUS,
+		0x2, MT6328_INT_MISC_CON, 0x4, MTK_PMIC_PWRKEY_RST),
+	.keys_regs[MTK_PMIC_HOMEKEY_INDEX] =
+		MTK_PMIC_KEYS_REGS(MT6328_TOPSTATUS,
+		0x4, MT6328_INT_MISC_CON, 0x2, MTK_PMIC_HOMEKEY_RST),
+	.pmic_rst_reg = MT6328_TOP_RST_MISC,
+	.rst_lprst_mask = MTK_PMIC_RST_DU_MASK,
+};
+
 static const struct mtk_pmic_regs mt6331_regs = {
 	.keys_regs[MTK_PMIC_PWRKEY_INDEX] =
 		MTK_PMIC_KEYS_REGS(MT6331_TOPSTATUS, 0x2,
@@ -304,6 +316,9 @@ static const struct of_device_id of_mtk_pmic_keys_match_tbl[] = {
 	}, {
 		.compatible = "mediatek,mt6323-keys",
 		.data = &mt6323_regs,
+	}, {
+		.compatible = "mediatek,mt6328-keys",
+		.data = &mt6328_regs,
 	}, {
 		.compatible = "mediatek,mt6331-keys",
 		.data = &mt6331_regs,

-- 
2.54.0

