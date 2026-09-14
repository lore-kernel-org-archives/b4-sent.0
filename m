From: Roman Vivchar <rva333@protonmail.com>
Date: Mon, 14 Sep 2026 15:10:52 +0300
Subject: [PATCH] dt-bindings: dma: mediatek,uart-dma: add mt6572
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260914-6572-dt-uartdma-v1-1-b26b429ab68c@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQqDMBBA4avIrB1IQv2pVxEXcTLqFGoliUUQ7
 27U5bd4b4fAXjhAk+3g+S9BfnOCzjOgyc4jo7hkMMqUqtYvLIvKoIu4Wh/d16J5MzmtqposQao
 Wz4Ns97HtHoe1/zDFawPHcQI3ahAucwAAAA==
X-Change-ID: 20260814-6572-dt-uartdma-29ecd1078cac
To: Sean Wang <sean.wang@mediatek.com>, Vinod Koul <vkoul@kernel.org>, 
 Frank Li <Frank.Li@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Long Cheng <long.cheng@mediatek.com>
Cc: dmaengine@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789387877; l=1054;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=R/+/MvTbfqvkqZYPWb9QyO+k6HKf/kl6ZguY9m0N+VQ=;
 b=vHFQ8nf+Cscdtn5vC9FyI/0sorPVchBdXpOIQ+fzj8SGBcpe4ZMoTKRWZGvDpsjerB48ledz2
 KESJiMeDfqWDtBQYWIV6sKsJwpR3GB4+CKVowCWSei6VHMLmKXh0tdV
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a compatible string for the mt6572 APDMA, that is compatible with
mt6577 IP.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
Based on next-20260813 tag.
---
 Documentation/devicetree/bindings/dma/mediatek,uart-dma.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/dma/mediatek,uart-dma.yaml b/Documentation/devicetree/bindings/dma/mediatek,uart-dma.yaml
index bba20e88a6dc..bd5f5260613b 100644
--- a/Documentation/devicetree/bindings/dma/mediatek,uart-dma.yaml
+++ b/Documentation/devicetree/bindings/dma/mediatek,uart-dma.yaml
@@ -23,6 +23,7 @@ properties:
       - items:
           - enum:
               - mediatek,mt2712-uart-dma
+              - mediatek,mt6572-uart-dma
               - mediatek,mt6795-uart-dma
               - mediatek,mt8173-uart-dma
               - mediatek,mt8183-uart-dma

---
base-commit: 2697ef8943c9985c14708a6429e21812693857b2
change-id: 20260814-6572-dt-uartdma-29ecd1078cac

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

