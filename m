From: Roman Vivchar <rva333@protonmail.com>
Date: Wed, 15 Jul 2026 17:27:46 +0300
Subject: [PATCH 1/3] dt-bindings: nvmem: mediatek: efuse: add mt6572
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260715-6572-nvmem-v1-1-9c13be99d077@protonmail.com>
References: <20260715-6572-nvmem-v1-0-9c13be99d077@protonmail.com>
In-Reply-To: <20260715-6572-nvmem-v1-0-9c13be99d077@protonmail.com>
To: Srinivas Kandagatla <srini@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Andrew-CT Chen <andrew-ct.chen@mediatek.com>, 
 Lala Lin <lala.lin@mediatek.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784125843; l=783;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=6rsiJE+m+kSdFo7mQes/iDioeo1J+zD87d8WvcT3BfE=;
 b=hqCbIqp5vmmknQd+J44Xt579ZcLZFLWvnYZXMSPmyC/4j3yjrZvGG6bPQ4xyeCQvU1k6tu6QX
 GLTBeHaLUalDEXXbWJ2TrYgMGQQ/4Qua0vYtwJVDwZ/QMf350B3aj7Z
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a compatible string for the mt6572 SoC efuse controller.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 Documentation/devicetree/bindings/nvmem/mediatek,efuse.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/nvmem/mediatek,efuse.yaml b/Documentation/devicetree/bindings/nvmem/mediatek,efuse.yaml
index f9323b3ecfc8..269e2b09f5c8 100644
--- a/Documentation/devicetree/bindings/nvmem/mediatek,efuse.yaml
+++ b/Documentation/devicetree/bindings/nvmem/mediatek,efuse.yaml
@@ -44,6 +44,7 @@ properties:
 
       - items:
           - enum:
+              - mediatek,mt6572-efuse
               - mediatek,mt7622-efuse
               - mediatek,mt7623-efuse
               - mediatek,mt7981-efuse

-- 
2.54.0

