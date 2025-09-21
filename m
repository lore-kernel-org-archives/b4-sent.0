From: Max Shevchenko <wctrl@proton.me>
Subject: [PATCH 0/3] Rewrite MediaTek UART APDMA driver to support more
 than 33 bits
Date: Sun, 21 Sep 2025 14:03:39 +0300
Message-Id: <20250921-uart-apdma-v1-0-107543c7102c@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIvbz2gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDSyND3dLEohLdxIKU3ERdy8RUc7NUE6M0I0NjJaCGgqLUtMwKsGHRsbW
 1ABs0505cAAAA
X-Change-ID: 20250921-uart-apdma-9ae76e42f213
To: Sean Wang <sean.wang@mediatek.com>, Vinod Koul <vkoul@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Long Cheng <long.cheng@mediatek.com>
Cc: dmaengine@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Max Shevchenko <wctrl@proton.me>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758452646; l=1014;
 i=wctrl@proton.me; s=20250603; h=from:subject:message-id;
 bh=zfFGum9b0/BleKUZeCTKfLnLOBtKdYp2e9/Jc3IpdTQ=;
 b=Quibm1DVcGl0mSoso1wZuKD1LG4vQ1WaKLN47ZGF1Ghf4HYVz2LEe84dbtvy0i9yXo49BuSCK
 r48rMZ4pJgKAXvMo/b1LwQAGKfFUn70yV3rHmeoxZI6PX4WuBaNbKmU
X-Developer-Key: i=wctrl@proton.me; a=ed25519;
 pk=JXUx3mL/OrnRvbK57HXgugBjEBKq4QgDKJqp7BALm74=
X-Endpoint-Received: by B4 Relay for wctrl@proton.me/20250603 with auth_id=421
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series aims to support more than 33 bits for the MediaTek
APDMA driver, since newer SoCs like MT6795, MT6779 or MT6985 have higher
values for the DMA bitmask.

The reference SoCs for bitmask values were taken from the downstream
kernel (6.6) for the MT6991 SoC. 

Signed-off-by: Max Shevchenko <wctrl@proton.me>
---
Max Shevchenko (3):
      dt-bindings: dma: mediatek,uart-dma: drop mediatek,dma-33bits property
      dmaengine: mediatek: mtk-uart-apdma: support more than 33 bits for DMA bitmask
      arm64: dts: mediatek: mt6795: drop mediatek,dma-33bits property

 .../devicetree/bindings/dma/mediatek,uart-dma.yaml | 11 ++---
 arch/arm64/boot/dts/mediatek/mt6795.dtsi           |  4 +-
 drivers/dma/mediatek/mtk-uart-apdma.c              | 47 ++++++++++++++++------
 3 files changed, 39 insertions(+), 23 deletions(-)
---
base-commit: f83ec76bf285bea5727f478a68b894f5543ca76e
change-id: 20250921-uart-apdma-9ae76e42f213

Best regards,
-- 
Max Shevchenko <wctrl@proton.me>

