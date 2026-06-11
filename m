From: Roman Vivchar <rva333@protonmail.com>
Date: Thu, 11 Jun 2026 13:20:29 +0300
Subject: [PATCH 1/4] dt-bindings: mfd: mediatek: mt6397: add mt6323 PMIC
 EFUSE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260611-mt6323-nvmem-v1-1-b5e1b9ce51f2@protonmail.com>
References: <20260611-mt6323-nvmem-v1-0-b5e1b9ce51f2@protonmail.com>
In-Reply-To: <20260611-mt6323-nvmem-v1-0-b5e1b9ce51f2@protonmail.com>
To: Sen Chu <sen.chu@mediatek.com>, Sean Wang <sean.wang@mediatek.com>, 
 Macpaul Lin <macpaul.lin@mediatek.com>, Lee Jones <lee@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Srinivas Kandagatla <srini@kernel.org>, 
 Roman Vivchar <rva333@protonmail.com>
Cc: Andy Shevchenko <andy@kernel.org>, Jonathan Cameron <jic23@kernel.org>, 
 linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, Ben Grisdale <bengris32@protonmail.ch>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781173294; l=1528;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=Z+i5otfJXHcGSb/Mu1sxOt8XM4P2sXW7ssJy3Op5BOA=;
 b=gUhy/aA0enpF2VeL1vmKbLN5+5aZ3zuP73dUD/a/f91mu7DM4Fs8e/LpcnGOhwagXVx2aRZeA
 X9iv0Tj0NXFDRNngXQNm+ceQPH+VLbmGEVsPQGhjKDgkUYrURfsAO4K
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MediaTek mt6323 PMIC includes an EFUSE used for storing calibration
data.

Add the devicetree binding documentation for the MediaTek mt6323 EFUSE.

Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 .../devicetree/bindings/mfd/mediatek,mt6397.yaml    | 21 +++++++++++++++++++++
 1 file changed, 21 insertions(+)

diff --git a/Documentation/devicetree/bindings/mfd/mediatek,mt6397.yaml b/Documentation/devicetree/bindings/mfd/mediatek,mt6397.yaml
index 05c121b0cb3d..beaa67bf0df2 100644
--- a/Documentation/devicetree/bindings/mfd/mediatek,mt6397.yaml
+++ b/Documentation/devicetree/bindings/mfd/mediatek,mt6397.yaml
@@ -145,6 +145,23 @@ properties:
     required:
       - compatible
 
+  efuse:
+    type: object
+    unevaluatedProperties: false
+    description:
+      The efuse is responsible for storing calibration data, such as thermal
+      sensor calibration.
+
+    properties:
+      compatible:
+        const: mediatek,mt6323-efuse
+
+      nvmem-layout:
+        $ref: /schemas/nvmem/layouts/nvmem-layout.yaml#
+
+    required:
+      - compatible
+
   leds:
     type: object
     additionalProperties: false
@@ -243,6 +260,10 @@ examples:
         interrupt-controller;
         #interrupt-cells = <2>;
 
+        efuse {
+          compatible = "mediatek,mt6323-efuse";
+        };
+
         leds {
             compatible = "mediatek,mt6323-led";
             #address-cells = <1>;

-- 
2.54.0

