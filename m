From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: dmitry.torokhov@gmail.com
Cc: matthias.bgg@gmail.com, angelogioacchino.delregno@collabora.com, 
 linux-input@vger.kernel.org, linux-mediatek@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
Subject: [PATCH 0/2] Input: mtk-pmic-keys - fix TOP_RST_MISC layout on
 MT6357/MT6358
Date: Thu, 26 Nov 2026 00:07:06 +0000
Message-Id: <20261126000706.15649-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795651626; l=1940;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=k1ugJTSw2S1SmQnBcJkuN/0L5JelnI96Np8GylaWwEg=;
 b=7SVA7OjauVY4HUbsHh+BzYiDcDFH40ql4CQvLKg25dYuU3dLacPfs2TR2s3jU9z2rAT4wwHZ9
 wVpLJezUCU0BpDQF1BNYq+V5kZQ+YsrRA4l3ZUidEqFzxjhhqPkc7IJ
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The long-press reset setup of mtk-pmic-keys programs TOP_RST_MISC of
MT6357 and MT6358/MT6366 with the MT6397 bit layout. On these PMICs the
reset enable is bit 9, the home key mode bit 8 and the time bits 13:12,
while bits 0, 1 and 5 hold the PMIC watchdog reset setup done by the
boot firmware. MT6357 additionally passes the array index
MTK_PMIC_HOMEKEY_INDEX as its home key mask.

Patch 1 fixes MT6358 (also used by MT6366), with a register read from an
MT6366 board as evidence. Patch 2 fixes MT6357 from public sources only.

Sources (all public):
 - coreboot: src/soc/mediatek/mt8183/mt6358.c, src/soc/mediatek/mt8186/mt6366.c
   and src/soc/mediatek/common/mt6359p.c, pmic_wdt_set()
 - MediaTek LK2 as published by Gigaset (github.com/Gigaset-dev/lk2):
   platform/mediatek/common/pmic/mt6358/mt6358_psc.c
 - MediaTek's downstream drivers/input/keyboard/mtk-pmic-keys.c as
   published in vendor GPL releases (e.g. OnePlusOSS
   android_kernel_oneplus_mt6789, MotorolaMobilityLLC
   kernel-kernel_device_modules-6.6)

Not addressed here: MT6359. MediaTek's downstream driver uses the same
layout for it, but MediaTek's MT6359P header and coreboot place
TOP_RST_MISC at 0x14a with 0x14c being its _SET alias, while
include/linux/mfd/mt6359/registers.h has 0x14c. Someone with MT6359
hardware should check mt6359_regs separately.

Found and drafted with an AI coding assistant by comparing the driver
against the sources above. Not compile-tested in this form
(both patches only change constants); not run on MT6357 or MT6358
hardware with the mainline driver.

Ilia Snezhkov (2):
  Input: mtk-pmic-keys - fix MT6358 long-press reset bits
  Input: mtk-pmic-keys - fix MT6357 long-press reset bits

 drivers/input/keyboard/mtk-pmic-keys.c | 16 ++++++++++------
 1 file changed, 10 insertions(+), 6 deletions(-)

base-commit: 2800868f63227c8237d70c41e70d441c919620d6
-- 
2.54.0 (Apple Git-157)


