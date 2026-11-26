From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: dmitry.torokhov@gmail.com
Cc: matthias.bgg@gmail.com, angelogioacchino.delregno@collabora.com, 
 linux-input@vger.kernel.org, linux-mediatek@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
Subject: [PATCH 1/2] Input: mtk-pmic-keys - fix MT6358 long-press reset
 bits
Date: Thu, 26 Nov 2026 00:07:07 +0000
Message-Id: <20261126000706.15649-2-iasnezhkov@gmail.com>
In-Reply-To: <20261126000706.15649-1-iasnezhkov@gmail.com>
References: <20261126000706.15649-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795651626; l=3562;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=8Ps8xDSOLQnt6t9Mmu3NbmTDcsWme4WN7eNETt0rZx4=;
 b=AJVBhriT9ut+JHiqczAXuXI9TjkJQ/GIfCqGAZjc8xS3cMU3/83FthCHrGxSlrCqz4NIHZPRF
 LLBUBAI4UcGBlH4n6LyaXsIaoKQH1NnGck6Z5spgzFC5EehMJRAfVWP
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mt6358_regs reuses the MT6397 layout of TOP_RST_MISC: BIT(6) for the
power key reset, BIT(5) for the home key reset and GENMASK(9, 8) for
the long-press time. MT6358 and MT6366, which uses the
"mediatek,mt6358-keys" compatible, lay this register out differently:

  bit 0      RG_WDTRSTB_EN    (PMIC watchdog reset enable)
  bit 1      RG_WDTRSTB_MODE
  bit 5      RG_WDTRSTB_DEB   (PMIC watchdog reset debounce)
  bit 8      home key takes part in the long-press reset
  bit 9      RG_PWRKEY_RST_EN
  bits 13:12 long-press reset time

The watchdog bits are set by the boot firmware in coreboot's
pmic_wdt_set() for MT6358 (mt8183) and MT6366 (mt8186). MediaTek's LK2
names bit 8 RG_PWRKEY_KEY_MODE and bit 9 RG_PWRKEY_RST_EN of
MT6358_TOP_RST_MISC, and MediaTek's downstream mtk-pmic-keys driver
uses reset shifts 9 (power), 8 (home) and 12 (two-bit time) for MT6358
and MT6366.

With the default mediatek,long-press-mode = <0> the probe clears
bits 9:8, 6 and 5. That clears the long-press reset enable as intended,
but only by accident, and also clears RG_WDTRSTB_DEB. With modes 1
and 2, power-off-time-sec is written into the reset enable and key
mode bits, while the enable bits land on bit 6 and on bit 5
(RG_WDTRSTB_DEB).

On an MT6366 board (an MT6789 phone) TOP_RST_MISC reads 0x0225 after
the boot firmware: bits 0 and 5 (watchdog reset enable and debounce)
and bit 9 (power key reset enable). Under the MT6397 layout this would
decode as a home key reset without a power key reset, which the driver
itself can never configure.

Use the MT6358 layout. Its values equal the MT6331 ones, but the
fields are defined separately for this PMIC family.

Found and drafted with an AI coding assistant while bringing up MT6789.

Fixes: 994673dc6657 ("Input: mtk-pmic-keys - add support for MT6358")
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---

Notes:
    Tested: TOP_RST_MISC read back on an MT6366 board (MT6789 phone) running
    MediaTek's downstream driver, which programs the MT6358 layout: 0x0225.
    The mainline driver with this change has not been run on hardware and
    was not compile-tested in this form; the change only swaps constants.

 drivers/input/keyboard/mtk-pmic-keys.c | 10 +++++++---
 1 file changed, 7 insertions(+), 3 deletions(-)

diff --git a/drivers/input/keyboard/mtk-pmic-keys.c b/drivers/input/keyboard/mtk-pmic-keys.c
index 6f14318..422a1f4 100644
--- a/drivers/input/keyboard/mtk-pmic-keys.c
+++ b/drivers/input/keyboard/mtk-pmic-keys.c
@@ -29,6 +29,10 @@
 #define MTK_PMIC_MT6331_PWRKEY_RST	BIT(9)
 #define MTK_PMIC_MT6331_HOMEKEY_RST	BIT(8)
 
+#define MTK_PMIC_MT6358_RST_DU_MASK	GENMASK(13, 12)
+#define MTK_PMIC_MT6358_PWRKEY_RST	BIT(9)
+#define MTK_PMIC_MT6358_HOMEKEY_RST	BIT(8)
+
 #define MTK_PMIC_PWRKEY_INDEX	0
 #define MTK_PMIC_HOMEKEY_INDEX	1
 #define MTK_PMIC_MAX_KEY_COUNT	2
@@ -110,13 +114,13 @@ static const struct mtk_pmic_regs mt6358_regs = {
 	.keys_regs[MTK_PMIC_PWRKEY_INDEX] =
 		MTK_PMIC_KEYS_REGS(MT6358_TOPSTATUS,
 				   0x2, MT6358_PSC_TOP_INT_CON0, 0x5,
-				   MTK_PMIC_PWRKEY_RST),
+				   MTK_PMIC_MT6358_PWRKEY_RST),
 	.keys_regs[MTK_PMIC_HOMEKEY_INDEX] =
 		MTK_PMIC_KEYS_REGS(MT6358_TOPSTATUS,
 				   0x8, MT6358_PSC_TOP_INT_CON0, 0xa,
-				   MTK_PMIC_HOMEKEY_RST),
+				   MTK_PMIC_MT6358_HOMEKEY_RST),
 	.pmic_rst_reg = MT6358_TOP_RST_MISC,
-	.rst_lprst_mask = MTK_PMIC_RST_DU_MASK,
+	.rst_lprst_mask = MTK_PMIC_MT6358_RST_DU_MASK,
 	.key_release_irq = true,
 };
 
-- 
2.54.0 (Apple Git-157)


