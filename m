From: Max Shevchenko <wctrl@proton.me>
Date: Sun, 21 Sep 2025 14:03:40 +0300
Subject: [PATCH 1/3] dt-bindings: dma: mediatek,uart-dma: drop
 mediatek,dma-33bits property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250921-uart-apdma-v1-1-107543c7102c@proton.me>
References: <20250921-uart-apdma-v1-0-107543c7102c@proton.me>
In-Reply-To: <20250921-uart-apdma-v1-0-107543c7102c@proton.me>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758452646; l=1846;
 i=wctrl@proton.me; s=20250603; h=from:subject:message-id;
 bh=TB4BCx1QYYV4SmqIa8ENnGfC/AB4i29OQtOF7WQHovg=;
 b=I3qa4PxpaBPKoU6fi7fhLxPcD3csXcw7CPfWSXpq7UuMv9OoZ9NtUPgrB3r4Fe5nltPitCZXj
 UCi2HFiDvpIDS0qTK6ZmeNqloia69Lkev+R2nCbnT8xCU05mNgjYFlI
X-Developer-Key: i=wctrl@proton.me; a=ed25519;
 pk=JXUx3mL/OrnRvbK57HXgugBjEBKq4QgDKJqp7BALm74=
X-Endpoint-Received: by B4 Relay for wctrl@proton.me/20250603 with auth_id=421
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Many newer SoCs support more than 33 bits for DMA.
Drop the property in order to switch to the platform data.

The reference SoCs were taken from the downstream kernel (6.6) for
the MT6991 SoC.

Signed-off-by: Max Shevchenko <wctrl@proton.me>
---
 Documentation/devicetree/bindings/dma/mediatek,uart-dma.yaml | 11 ++++-------
 1 file changed, 4 insertions(+), 7 deletions(-)

diff --git a/Documentation/devicetree/bindings/dma/mediatek,uart-dma.yaml b/Documentation/devicetree/bindings/dma/mediatek,uart-dma.yaml
index dab468a88942d694525aa391f695c44d192f0c42..9dfdfe81af7edbe3540e4b757547a5d5e6ae810c 100644
--- a/Documentation/devicetree/bindings/dma/mediatek,uart-dma.yaml
+++ b/Documentation/devicetree/bindings/dma/mediatek,uart-dma.yaml
@@ -22,12 +22,14 @@ properties:
       - items:
           - enum:
               - mediatek,mt2712-uart-dma
-              - mediatek,mt6795-uart-dma
               - mediatek,mt8365-uart-dma
               - mediatek,mt8516-uart-dma
           - const: mediatek,mt6577-uart-dma
       - enum:
-          - mediatek,mt6577-uart-dma
+          - mediatek,mt6577-uart-dma  # 32 bits
+          - mediatek,mt6795-uart-dma  # 33 bits
+          - mediatek,mt6779-uart-dma  # 34 bits
+          - mediatek,mt6985-uart-dma  # 35 bits
 
   reg:
     minItems: 1
@@ -56,10 +58,6 @@ properties:
       Number of virtual channels of the UART APDMA controller
     maximum: 16
 
-  mediatek,dma-33bits:
-    type: boolean
-    description: Enable 33-bits UART APDMA support
-
 required:
   - compatible
   - reg
@@ -116,7 +114,6 @@ examples:
             dma-requests = <12>;
             clocks = <&pericfg CLK_PERI_AP_DMA>;
             clock-names = "apdma";
-            mediatek,dma-33bits;
             #dma-cells = <1>;
         };
     };

-- 
2.51.0

