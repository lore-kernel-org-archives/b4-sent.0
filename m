From: Ricardo Rivera-Matos <rriveram@opensource.cirrus.com>
Date: Mon, 09 Nov 2026 11:57:03 -0600
Subject: [PATCH 1/4] ASoC: dt-bindings: cs35l45: Adds ABPE properties
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-cs35l45-bpe-v1-1-9d7bc95a90a4@opensource.cirrus.com>
References: <20261109-cs35l45-bpe-v1-0-9d7bc95a90a4@opensource.cirrus.com>
In-Reply-To: <20261109-cs35l45-bpe-v1-0-9d7bc95a90a4@opensource.cirrus.com>
To: David Rhodes <david.rhodes@cirrus.com>, 
 Richard Fitzgerald <rf@opensource.cirrus.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, patches@opensource.cirrus.com, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ricardo Rivera-Matos <rriveram@opensource.cirrus.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794247023; l=6837;
 i=rriveram@opensource.cirrus.com; s=20261106; h=from:subject:message-id;
 bh=Pd960E667LHVi6FmIxmZ758aNEZWIIdo2651OW+cP6w=;
 b=yPUJShhSoVV+eS8cd+cqXiQsZEpiAy3TJp75R0IhRUAB2RltEcbsPpXZnacBNZrKMcZGjMpo/
 SHc/G9mLOTpBvDff/83kxALj5kWxjS8n/SF9v8zUU3IWUjPgSPFe0ku
X-Developer-Key: i=rriveram@opensource.cirrus.com; a=ed25519;
 pk=k/iAEAtSPXvaWRDFupudzm6His7B7iJP1uiZ578a7Y8=
X-Endpoint-Received: by B4 Relay for rriveram@opensource.cirrus.com/20261106 with auth_id=1437
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds devicetree properties to configure the amplifier brownout
prevention engine (ABPE).

Signed-off-by: Ricardo Rivera-Matos <rriveram@opensource.cirrus.com>
---
 .../devicetree/bindings/sound/cirrus,cs35l45.yaml  | 161 +++++++++++++++++++++
 1 file changed, 161 insertions(+)

diff --git a/Documentation/devicetree/bindings/sound/cirrus,cs35l45.yaml b/Documentation/devicetree/bindings/sound/cirrus,cs35l45.yaml
index e674811b22b2..2c118fa57ad1 100644
--- a/Documentation/devicetree/bindings/sound/cirrus,cs35l45.yaml
+++ b/Documentation/devicetree/bindings/sound/cirrus,cs35l45.yaml
@@ -16,6 +16,62 @@ description: |
 
 allOf:
   - $ref: dai-common.yaml#
+  - if:
+      required:
+        - cirrus,amplifier-bpe-enable
+    then:
+      required:
+        - cirrus,amplifier-bpe-response-mode
+        - cirrus,amplifier-bpe-thresholds-microvolt
+        - cirrus,amplifier-bpe-attack-rates
+        - cirrus,amplifier-bpe-hold-times-us
+        - cirrus,amplifier-bpe-release-rates
+    else:
+      properties:
+        cirrus,amplifier-bpe-response-mode: false
+        cirrus,amplifier-bpe-thresholds-microvolt: false
+        cirrus,amplifier-bpe-attenuation-levels-db: false
+        cirrus,amplifier-bpe-attenuation-levels-microvolt: false
+        cirrus,amplifier-bpe-attenuation-levels-microwatt: false
+        cirrus,amplifier-bpe-attack-rates: false
+        cirrus,amplifier-bpe-hold-times-us: false
+        cirrus,amplifier-bpe-release-rates: false
+  - if:
+      properties:
+        cirrus,amplifier-bpe-response-mode:
+          const: 0
+      required:
+        - cirrus,amplifier-bpe-response-mode
+    then:
+      required:
+        - cirrus,amplifier-bpe-attenuation-levels-db
+      properties:
+        cirrus,amplifier-bpe-attenuation-levels-microvolt: false
+        cirrus,amplifier-bpe-attenuation-levels-microwatt: false
+  - if:
+      properties:
+        cirrus,amplifier-bpe-response-mode:
+          const: 1
+      required:
+        - cirrus,amplifier-bpe-response-mode
+    then:
+      required:
+        - cirrus,amplifier-bpe-attenuation-levels-microvolt
+      properties:
+        cirrus,amplifier-bpe-attenuation-levels-db: false
+        cirrus,amplifier-bpe-attenuation-levels-microwatt: false
+  - if:
+      properties:
+        cirrus,amplifier-bpe-response-mode:
+          const: 2
+      required:
+        - cirrus,amplifier-bpe-response-mode
+    then:
+      required:
+        - cirrus,amplifier-bpe-attenuation-levels-microwatt
+      properties:
+        cirrus,amplifier-bpe-attenuation-levels-db: false
+        cirrus,amplifier-bpe-attenuation-levels-microvolt: false
 
 properties:
   compatible:
@@ -123,6 +179,103 @@ properties:
       the current monitor (IMON) circuit is put into a low power operational
       state.
 
+  cirrus,amplifier-bpe-enable:
+    type: boolean
+    description: Enable the amplifier brownout prevention engine (BPE).
+
+  cirrus,amplifier-bpe-response-mode:
+    description:
+      Amplifier BPE attack and release response mode. This property
+      determines the ABPE attenuation natural units.
+      0 = logarithmic
+      1 = linear voltage
+      2 = linear power
+    $ref: /schemas/types.yaml#/definitions/uint32
+    enum: [0, 1, 2]
+
+  cirrus,amplifier-bpe-thresholds-microvolt:
+    description:
+      Amplifier BPE response battery voltage thresholds for levels L3, L2,
+      L1, L0, in that order. Each level can be set independently.
+    minItems: 4
+    maxItems: 4
+    items:
+      minimum: 2300000
+      maximum: 4500000
+      multipleOf: 10000
+
+  cirrus,amplifier-bpe-attenuation-levels-db:
+    description:
+      Amplifier BPE logarithmic audio output attenuation for levels L3, L2,
+      L1, L0, in whole dB steps. Half dB hardware settings are not
+      supported.
+    minItems: 4
+    maxItems: 4
+    items:
+      minimum: 0
+      maximum: 15
+
+  cirrus,amplifier-bpe-attenuation-levels-microvolt:
+    description: |
+      Amplifier BPE linear voltage audio output attenuation for levels L3,
+      L2, L1, L0.
+    minItems: 4
+    maxItems: 4
+    items:
+      minimum: 187500
+      maximum: 1000000
+      multipleOf: 31250
+
+  cirrus,amplifier-bpe-attenuation-levels-microwatt:
+    description: |
+      Amplifier BPE linear power audio output attenuation for levels L3,
+      L2, L1, L0.
+    $ref: /schemas/types.yaml#/definitions/uint32-array
+    minItems: 4
+    maxItems: 4
+    items:
+      minimum: 31250
+      maximum: 1000000
+      multipleOf: 31250
+
+  cirrus,amplifier-bpe-attack-rates:
+    description: |
+      Amplifier BPE attack rate register codes for levels L3, L2, L1, L0.
+      Code 0 is instantaneous; codes 1 through 8 select progressively
+      slower rates. The physical rate depends on the response mode.
+
+      See section 7.21.9 of the datasheet for a detailed description.
+    $ref: /schemas/types.yaml#/definitions/uint32-array
+    minItems: 4
+    maxItems: 4
+    items:
+      minimum: 0
+      maximum: 8
+
+  cirrus,amplifier-bpe-hold-times-us:
+    description: |
+      Amplifier BPE hold times for levels L3, L2, L1, L0. Infinite hold is
+      unsupported.
+    minItems: 4
+    maxItems: 4
+    items:
+      enum: [0, 250, 500, 1000, 5000, 10000, 25000, 50000,
+             100000, 250000, 500000, 1000000, 2500000, 5000000, 10000000]
+
+  cirrus,amplifier-bpe-release-rates:
+    description: |
+      Amplifier BPE release rate register codes for levels L3, L2, L1, L0.
+      Code 0 is instantaneous; codes 1 through 14 select progressively
+      slower rates. The physical rate depends on the response mode.
+
+      See section 7.21.11 of the datasheet for a detailed description.
+    $ref: /schemas/types.yaml#/definitions/uint32-array
+    minItems: 4
+    maxItems: 4
+    items:
+      minimum: 0
+      maximum: 14
+
 patternProperties:
   "^cirrus,gpio-ctrl[1-3]$":
     description:
@@ -251,6 +404,14 @@ examples:
             cirrus,ldpm-group2-delay-ms = <1000>;
             cirrus,ldpm-group2-vmon-select;
             cirrus,ldpm-group2-imon-select;
+            cirrus,amplifier-bpe-enable;
+            cirrus,amplifier-bpe-response-mode = <0>;
+            cirrus,amplifier-bpe-thresholds-microvolt =
+                <3200000 3000000 2800000 2600000>;
+            cirrus,amplifier-bpe-attenuation-levels-db = <3 6 9 12>;
+            cirrus,amplifier-bpe-attack-rates = <6 6 6 6>;
+            cirrus,amplifier-bpe-hold-times-us = <500 500 500 500>;
+            cirrus,amplifier-bpe-release-rates = <5 5 5 5>;
             cirrus,gpio-ctrl1 {
                 gpio-ctrl = <0x2>;
             };

-- 
2.43.0

