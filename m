From: Chuan Liu <chuan.liu@amlogic.com>
Date: Fri, 15 Aug 2025 16:37:27 +0800
Subject: [PATCH 01/13] dt-bindings: soc: amlogic: Add clk-measure related
 properties
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250815-add-more-socs-to-support-clk_measure-v1-1-59f04ba67457@amlogic.com>
References: <20250815-add-more-socs-to-support-clk_measure-v1-0-59f04ba67457@amlogic.com>
In-Reply-To: <20250815-add-more-socs-to-support-clk_measure-v1-0-59f04ba67457@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755247056; l=2924;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=WKCqPVvjKvBXZpMp6AHTLsZhyPJ7w7tYipQPXxNUfy8=;
 b=Q41qJt636clPDrUBiobgwPQhIgCCdN9zC7cR3+DvjHw/DkHPHACtzt579HcHsSbegx+EGYnso
 SAP1K0IrAffB30vT6+ZbJysS3mjFwAyqBwtGnT6NcX2J7u/OIiLPKsZ
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add three properties to clk-measure: 'clkmsr-indices', 'clkmsr-names',
and 'clkmsr-reg-v2' for describing measurable channels and register
offsets in DT.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 .../soc/amlogic/amlogic,meson-gx-clk-measure.yaml  | 54 +++++++++++++++++++++-
 1 file changed, 53 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml b/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml
index 39d4637c2d08..1c9d37eef5f0 100644
--- a/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml
+++ b/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml
@@ -6,7 +6,7 @@ $schema: http://devicetree.org/meta-schemas/core.yaml#
 
 title: Amlogic Internal Clock Measurer
 
-description:
+description: |
   The Amlogic SoCs contains an IP to measure the internal clocks.
   The precision is multiple of MHz, useful to debug the clock states.
 
@@ -28,15 +28,67 @@ properties:
   reg:
     maxItems: 1
 
+  clkmsr-indices:
+    $ref: /schemas/types.yaml#/definitions/uint32-array
+    description: |
+      Supported channel IDs for clk-measure.
+    minItems: 1
+    maxItems: 256
+
+  clkmsr-names:
+    $ref: /schemas/types.yaml#/definitions/string-array
+    description: |
+      The channel ID names supported by clk-measure correspond one-to-one with
+      the IDs specified in 'clkmsr-indices'.
+
+      Therefore, the defined 'clkmsr-indices' and 'clkmsr-names' must have
+      matching counts and maintain strict correspondence.
+    minItems: 1
+    maxItems: 256
+
+  clkmsr-reg-v2:
+    type: boolean
+    description: |
+      Specify whether the register address offset for clk-measure corresponds
+      to version V2.
+
 required:
   - compatible
   - reg
+  - clkmsr-indices
+  - clkmsr-names
 
 unevaluatedProperties: false
 
 examples:
   - |
+    /*
+     * Example 1: clk-measure uses the original version of register address
+     * offsets.
+     */
     clock-measure@8758 {
         compatible = "amlogic,meson-gx-clk-measure";
         reg = <0x8758 0x10>;
+        clkmsr-indices = <0>,
+                         <1>,
+                         <2>;
+        clkmsr-names = "ring_osc_out_ee0",
+                       "ring_osc_out_ee1",
+                       "ring_osc_out_ee2";
+    };
+
+  - |
+    /*
+     * Example 2: clk-measure uses V2 version register address offsets.
+     */
+    clock-measure@48000 {
+        compatible = "amlogic,c3-clk-measure";
+        reg = <0x48000 0x1c>;
+        clkmsr-reg-v2;
+        clkmsr-indices = <0>,
+                         <1>,
+                         <2>;
+        clkmsr-names = "sys_clk",
+                       "axi_clk",
+                       "rtc_clk";
     };

-- 
2.42.0

