From: Roman Vivchar <rva333@protonmail.com>
Date: Wed, 30 Sep 2026 13:14:27 +0300
Subject: [PATCH v5 1/4] dt-bindings: nvmem: mediatek: efuse: add mt6572
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-6572-nvmem-v5-1-384d2a3a1770@protonmail.com>
References: <20260930-6572-nvmem-v5-0-384d2a3a1770@protonmail.com>
In-Reply-To: <20260930-6572-nvmem-v5-0-384d2a3a1770@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790763284; l=1140;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=5K32Q1swD4S3cSggeXC/0toQquH0mxZvBxfpkIPi+IU=;
 b=M5/+WU7HpaDQSfcWxQZiRaA9XqEdJXJUf99cACRJWf9sFJsmkIkc1oQnfBjYsGTIQgqAQypN8
 aQWVac7lxewCQy2A12P9ZVN2Dij1muWKQwR7Zu0KCJX72yqllDEF1UO
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a compatible string for the mt6572 SoC efuse controller.

Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
Reviewed-by: AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 Documentation/devicetree/bindings/nvmem/mediatek,efuse.yaml | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/nvmem/mediatek,efuse.yaml b/Documentation/devicetree/bindings/nvmem/mediatek,efuse.yaml
index f9323b3ecfc8..e10947164941 100644
--- a/Documentation/devicetree/bindings/nvmem/mediatek,efuse.yaml
+++ b/Documentation/devicetree/bindings/nvmem/mediatek,efuse.yaml
@@ -24,13 +24,16 @@ properties:
 
   compatible:
     oneOf:
+      - enum:
+          - mediatek,mt6572-efuse
+          - mediatek,mt8186-efuse
+
       - items:
           - enum:
               - mediatek,mt8188-efuse
               - mediatek,mt8189-efuse
               - mediatek,mt8196-efuse
           - const: mediatek,mt8186-efuse
-      - const: mediatek,mt8186-efuse
 
       - items:
           - enum:

-- 
2.55.0

