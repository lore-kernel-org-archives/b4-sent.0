From: Cristian Cozzolino <cristian_ci@protonmail.com>
Subject: [PATCH 00/10] ARM: Add support for yarisxl mt6582 board
Date: Sat, 20 Sep 2025 20:23:25 +0200
Message-Id: <20250920-mt6582-v1-0-b887720f577d@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAB7xzmgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDSyMD3dwSM1MLI11LY2PLFPO05NQkYxMloOKCotS0zAqwQdGxtbUAIVX
 EO1gAAAA=
X-Change-ID: 20250920-mt6582-9339d7fceb34
To: Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Russell King <linux@armlinux.org.uk>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sean Wang <sean.wang@mediatek.com>
Cc: linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, 
 Cristian Cozzolino <cristian_ci@protonmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758392693; l=1921;
 i=cristian_ci@protonmail.com; s=20250620; h=from:subject:message-id;
 bh=u840vuSdNA238eaEpBUXCICkOP9msH1ZivtGlgxyhXY=;
 b=f4PxI5rxzmphfC3mJqHuJLLtu74mC8xdE0jGsQiiZDg3Bhahc+aOijqzXFUCItKAZYB1hMVMj
 lXU7DXzkgbVBmoqDQ6RZfAdU6e6CAmTqrrYb1ssoPVQofruMMy5o98c
X-Developer-Key: i=cristian_ci@protonmail.com; a=ed25519;
 pk=xH5IvIPUNHV1Q8R0/pq2CfuVFR/wTiAyuyi6IwedjZY=
X-Endpoint-Received: by B4 Relay for cristian_ci@protonmail.com/20250620 with auth_id=438
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for Alcatel Pop C7 (OT-7041D) smartphone
board, named yarisxl, based on MT6582 SoC. It also includes some
preliminary patches. More in detail:
- patches 1 and 2 add support for mt6582 to platform code 
  (verified by looking at generic mt6582 downstream source code)
- patches 3-6 do some maintenance work to mt6582.dtsi 
  (I was unsure if squashing timer node patches into one)
- patches 7 and 8 add devicetree and dt-bindings support for yarisxl

Signed-off-by: Cristian Cozzolino <cristian_ci@protonmail.com>
---
Cristian Cozzolino (10):
      ARM: mediatek: add board_dt_compat entry for the MT6582 SoC
      ARM: mediatek: add MT6582 smp bring up code
      ARM: dts: mediatek: mt6582: move MMIO devices under soc node
      ARM: dts: mediatek: mt6582: sort nodes and properties
      ARM: dts: mediatek: mt6582: remove compatible property from root node
      ARM: dts: mediatek: mt6582: add mt6582 compatible to timer
      ARM: dts: mediatek: mt6582: add clock-names property to uart nodes
      ARM: dts: mediatek: mt6582: add enable-method property to cpus
      dt-bindings: arm: mediatek: Add MT6582 yarisxl
      ARM: dts: mediatek: add basic support for Alcatel yarisxl board

 .../devicetree/bindings/arm/mediatek.yaml          |   1 +
 arch/arm/boot/dts/mediatek/Makefile                |   1 +
 .../boot/dts/mediatek/mt6582-alcatel-yarisxl.dts   |  61 +++++++++
 arch/arm/boot/dts/mediatek/mt6582.dtsi             | 142 +++++++++++----------
 arch/arm/mach-mediatek/Kconfig                     |   4 +
 arch/arm/mach-mediatek/mediatek.c                  |   1 +
 arch/arm/mach-mediatek/platsmp.c                   |   1 +
 7 files changed, 142 insertions(+), 69 deletions(-)
---
base-commit: 846bd2225ec3cfa8be046655e02b9457ed41973e
change-id: 20250920-mt6582-9339d7fceb34

Best regards,
-- 
Cristian Cozzolino <cristian_ci@protonmail.com>

