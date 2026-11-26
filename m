From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: dmitry.torokhov@gmail.com
Cc: matthias.bgg@gmail.com, angelogioacchino.delregno@collabora.com, 
 linux-input@vger.kernel.org, linux-mediatek@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
Subject: [PATCH 2/2] Input: mtk-pmic-keys - fix MT6357 long-press reset
 bits
Date: Thu, 26 Nov 2026 00:07:08 +0000
Message-Id: <20261126000706.15649-3-iasnezhkov@gmail.com>
In-Reply-To: <20261126000706.15649-1-iasnezhkov@gmail.com>
References: <20261126000706.15649-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795651626; l=2249;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=yS1/exCajzsB+ZjgzM6lYxa7Xj5JiEYFeRxg/8WGWXY=;
 b=diOxS1vAsQ/Ar98FTN3N06GgLgjkeb67CkWLvI1iKnQ9PpMbiXhpSkE2OW6CSiMILCaaZTS97
 ZIXdX5QiDtRAX9VjAbu7HnH15VzFlgcCZcw6/HVMN5w//Zp8zXfLNPa
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The home key entry of mt6357_regs passes MTK_PMIC_HOMEKEY_INDEX, the
array index 1, as its reset enable mask, so the driver writes BIT(0) of
TOP_RST_MISC for the home key. The other two bits come from the MT6397
layout: BIT(6) for the power key and GENMASK(9, 8) for the long-press
time.

MT6357 shares TOP_RST_MISC at 0x14c with MT6358, and MediaTek's
downstream mtk-pmic-keys driver programs it with the same layout as
MT6358: power key reset enable at bit 9, home key at bit 8 and a two-bit
long-press time at bits 13:12. On MT6358 and MT6366, bit 0 of this
register is RG_WDTRSTB_EN, the PMIC watchdog reset enable (coreboot
pmic_wdt_set()), so with the default mediatek,long-press-mode = <0>
the probe very likely disables the PMIC watchdog reset on MT6357 too.

Use the MT6358 layout for MT6357.

Found and drafted with an AI coding assistant while bringing up MT6789.

Fixes: 297770ec5c93 ("Input: mtk-pmic-keys: add MT6357 support")
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---

Notes:
    Not tested on MT6357 hardware: the layout comes from MediaTek's
    downstream driver and from the MT6358/MT6366 sources cited in 1/2.
    Not compile-tested in this form; the change only swaps constants.

 drivers/input/keyboard/mtk-pmic-keys.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/input/keyboard/mtk-pmic-keys.c b/drivers/input/keyboard/mtk-pmic-keys.c
index 422a1f4..39cdb50 100644
--- a/drivers/input/keyboard/mtk-pmic-keys.c
+++ b/drivers/input/keyboard/mtk-pmic-keys.c
@@ -101,13 +101,13 @@ static const struct mtk_pmic_regs mt6357_regs = {
 	.keys_regs[MTK_PMIC_PWRKEY_INDEX] =
 		MTK_PMIC_KEYS_REGS(MT6357_TOPSTATUS,
 				   0x2, MT6357_PSC_TOP_INT_CON0, 0x5,
-				   MTK_PMIC_PWRKEY_RST),
+				   MTK_PMIC_MT6358_PWRKEY_RST),
 	.keys_regs[MTK_PMIC_HOMEKEY_INDEX] =
 		MTK_PMIC_KEYS_REGS(MT6357_TOPSTATUS,
 				   0x8, MT6357_PSC_TOP_INT_CON0, 0xa,
-				   MTK_PMIC_HOMEKEY_INDEX),
+				   MTK_PMIC_MT6358_HOMEKEY_RST),
 	.pmic_rst_reg = MT6357_TOP_RST_MISC,
-	.rst_lprst_mask = MTK_PMIC_RST_DU_MASK,
+	.rst_lprst_mask = MTK_PMIC_MT6358_RST_DU_MASK,
 };
 
 static const struct mtk_pmic_regs mt6358_regs = {
-- 
2.54.0 (Apple Git-157)


