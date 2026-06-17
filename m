From: Roman Vivchar <rva333@protonmail.com>
Date: Wed, 17 Jun 2026 12:48:44 +0300
Subject: [PATCH v2 1/4] dt-bindings: mfd: mediatek: mt6397: add mt6323 PMIC
 EFUSE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260617-mt6323-nvmem-v2-1-4f30e36aa0f4@protonmail.com>
References: <20260617-mt6323-nvmem-v2-0-4f30e36aa0f4@protonmail.com>
In-Reply-To: <20260617-mt6323-nvmem-v2-0-4f30e36aa0f4@protonmail.com>
To: Sen Chu <sen.chu@mediatek.com>, Sean Wang <sean.wang@mediatek.com>, 
 Macpaul Lin <macpaul.lin@mediatek.com>, Lee Jones <lee@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Srinivas Kandagatla <srini@kernel.org>, 
 Roman Vivchar <rva333@protonmail.com>
Cc: Andy Shevchenko <andy@kernel.org>, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Ben Grisdale <bengris32@protonmail.ch>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781689724; l=1581;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=Y+qEH2u8RG69hEOj/2KlmQR+9sv6DjCcWKs/dnalb3U=;
 b=ovxSxVODW40H2iPH+WfzrBUbjzVxRv3qqbqJzqsMFcxS6Ib0+q1bJsCXPjI6nBJBU4GbThIso
 rJyeQWkbEY9Ag5DMC7jnoNC4q4V16jxMlTzQs0cGI2jO4Mt/u6lJG07
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MediaTek mt6323 PMIC includes an EFUSE used for storing calibration
data.

Add the devicetree binding documentation for the MediaTek mt6323 EFUSE.

Reviewed-by: Rob Herring (Arm) <robh@kernel.org>
Acked-by: Conor Dooley <conor.dooley@microchip.com>
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

