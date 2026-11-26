From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: matthias.bgg@gmail.com, angelogioacchino.delregno@collabora.com, 
 robh@kernel.org, krzk+dt@kernel.org, conor+dt@kernel.org, 
 broonie@kernel.org
Cc: flora.fu@mediatek.com, amergnat@baylibre.com, leilk.liu@mediatek.com, 
 me@adomerle.pw, devicetree@vger.kernel.org, linux-spi@vger.kernel.org, 
 linux-mediatek@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org
Subject: [PATCH v2 0/3] soc/spi: mediatek: Add MT6789 PMIC wrapper and SPI
 support
Date: Thu, 26 Nov 2026 00:07:11 +0000
Message-Id: <20261126000711.16163-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795651631; l=1667;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=G9PMsIZX01zfzgZ0pzVqRvDuZFHrueTUpBX7CfgwtQg=;
 b=cHZ+Iqb33K1Qg1Hxu9iqpECjakPQEoxieY1fEJoT9k2aXuZWv5v1uPPcO3+bgX/MoBzx/Pa2g
 /fwDlcmBKP/BnFMcwnbLw+J90eqbJ7tzld9jYu/INVMLIfr1jNiw4o4
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series continues the stalled July 2025 MediaTek MT6789 (Helio G99)
initial bring-up patches originally posted by Arseniy Velikanov (on CC):
- pwrap v1: https://lore.kernel.org/linux-mediatek/20250715225746.1321-1-me@adomerle.pw/
- spi v1:   https://lore.kernel.org/linux-mediatek/20250715231921.4527-1-me@adomerle.pw/

Original authorship and Signed-off-by are preserved on all three patches.
If Arseniy prefers to continue maintaining this series directly, we are
happy to step aside or coordinate on the remaining MT6789 bring-up pieces
(clocks v3, pinctrl, LVTS thermal, scpsys, and DT).

Changes since v1:
- Patch 1 (pwrap binding): rebased onto v7.4-rc4; carried forward
  Acked-by: Rob Herring (Arm) <robh@kernel.org>.
- Patch 2 (mtk-pmic-wrap): rebased onto v7.4-rc4; marked mt6789_regs[]
  and pwrap_mt6789 const to match surrounding SoC tables; register table
  verified on live MT6789 hardware (iKKO MindOne, MT6366 PMIC).
- Patch 3 (spi-mt65xx binding): added mediatek,mt6893-spi fallback
  compatible as requested by Rob Herring in v1 review.

The v2 rebase and binding audit were prepared with an AI coding
assistant.

Base: torvalds/linux master 4dce97c6c265.

Arseniy Velikanov (3):
  dt-bindings: soc: mediatek: pwrap: Add compatible for MT6789
  soc: mediatek: mtk-pmic-pwrap: Add MT6789 support
  dt-bindings: spi: mediatek,spi-mt65xx: Add compatible for MT6789

 .../bindings/soc/mediatek/mediatek,pwrap.yaml |  1 +
 .../bindings/spi/mediatek,spi-mt65xx.yaml     |  4 +++
 drivers/soc/mediatek/mtk-pmic-wrap.c          | 27 +++++++++++++++++++
 3 files changed, 32 insertions(+)

-- 
2.54.0 (Apple Git-157)


