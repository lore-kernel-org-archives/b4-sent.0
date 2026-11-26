From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: matthias.bgg@gmail.com, angelogioacchino.delregno@collabora.com, 
 robh@kernel.org, krzk+dt@kernel.org, conor+dt@kernel.org, 
 broonie@kernel.org
Cc: flora.fu@mediatek.com, amergnat@baylibre.com, leilk.liu@mediatek.com, 
 me@adomerle.pw, devicetree@vger.kernel.org, linux-spi@vger.kernel.org, 
 linux-mediatek@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org
Subject: [PATCH v3 0/4] soc/spi: mediatek: Add MT6789 PMIC wrapper and SPI
 support
Date: Thu, 26 Nov 2026 03:10:01 +0000
Message-Id: <20261126031001.27288-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795662602; l=1679;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=SSX2MYOf3hgS1EqmIn9zqqUiKL7h1Rp1ieInLyB7OCU=;
 b=kZ4V4FHt5o6RJ84Bp3g3s0xjpvWPzQOsDjGML3O1B52VHOCFPMhhOum+G1PN6q3ETTWrCUKcU
 ZUq2vfVPek7BUFMMOgYFhTO4q6ONCAGHkmYUEs1mxts+L7MRvCsmp34
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series continues the stalled July 2025 MediaTek MT6789 (Helio G99)
initial bring-up patches originally posted by Arseniy Velikanov (on CC):
- pwrap v1: https://lore.kernel.org/linux-mediatek/20250715225746.1321-1-me@adomerle.pw/
- spi v1:   https://lore.kernel.org/linux-mediatek/20250715231921.4527-1-me@adomerle.pw/

Original authorship and Signed-off-by are preserved on patches 1, 3,
and 4.

Changes since v2:
- Patch 2 (new): guard PWRAP_WDT_SRC_EN, PWRAP_WDT_SRC_EN_1, and cold
  pwrap_init() with !HAS_CAP(wrp->master->caps, PWRAP_CAP_ARB) so
  arbiter SoCs (MT6873, MT8195, MT6789) do not write wdt_src to offset
  0x0 (PWRAP_INIT_DONE2) during probe.
- Patch 3 (was 2/3): add [PWRAP_INT_FLG] = 0x458 and
  [PWRAP_INT_CLR] = 0x45C to mt6789_regs[] matching PMIF-SPI bank 3
  (INT_EN at 0x450, int_en_all = 0x180000) so pwrap_interrupt() does
  not clobber offset 0x0 and leave a level-high IRQ asserted.
- Patch 4 (was 3/3): renumbered to 4/4, unchanged.

The v3 rebase and fixes were prepared with an AI coding assistant.

Base: torvalds/linux master 4dce97c6c265.

Arseniy Velikanov (3):
  dt-bindings: soc: mediatek: pwrap: Add compatible for MT6789
  soc: mediatek: mtk-pmic-pwrap: Add MT6789 support
  dt-bindings: spi: mediatek,spi-mt65xx: Add compatible for MT6789

Ilia Snezhkov (1):
  soc: mediatek: mtk-pmic-pwrap: Skip WDT source and init on arbiter SoCs

 .../bindings/soc/mediatek/mediatek,pwrap.yaml |  1 +
 .../bindings/spi/mediatek,spi-mt65xx.yaml     |  4 +++
 drivers/soc/mediatek/mtk-pmic-wrap.c          | 44 ++++++++++++++++---
 3 files changed, 43 insertions(+), 6 deletions(-)

-- 
2.54.0 (Apple Git-157)

