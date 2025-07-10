From: jiebing chen <jiebing.chen@amlogic.com>
Date: Thu, 10 Jul 2025 11:35:37 +0800
Subject: [PATCH v5 1/6] dt-bindings: clock: meson: Add audio power domain
 for s4 soc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250710-audio_drvier-v5-1-d4155f1e7464@amlogic.com>
References: <20250710-audio_drvier-v5-0-d4155f1e7464@amlogic.com>
In-Reply-To: <20250710-audio_drvier-v5-0-d4155f1e7464@amlogic.com>
To: Jerome Brunet <jbrunet@baylibre.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>, Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: linux-sound@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 jian.xu@amlogic.com, shuai.li@amlogic.com, zhe.wang@amlogic.com, 
 jiebing chen <jiebing.chen@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752118569; l=3341;
 i=jiebing.chen@amlogic.com; s=20250110; h=from:subject:message-id;
 bh=yhsDXY7MMuP9ySNiIHj39Bbbf6ifv82AD9aG95a7FPY=;
 b=HRzZrpgSyMnpl/g7RHqIYGPk+EWvIzv1UFfvZEX3wevTxrCDzEyWmeD2hjyeoTXBQkF3x/u9Z
 HDXGEqCWaujBJZeKMnPNwhyn0alcJBgFA9a3avMZjC+jNYSXuybdFDI
X-Developer-Key: i=jiebing.chen@amlogic.com; a=ed25519;
 pk=6rFvvF45A84pLNRy03hfUHeROxHCnZ+1KAGw/DoqKic=
X-Endpoint-Received: by B4 Relay for jiebing.chen@amlogic.com/20250110 with auth_id=316
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The audio power domain has been detected on S4 device.
It must be enabled prior to audio operations.

Signed-off-by: jiebing chen <jiebing.chen@amlogic.com>
---
 .../bindings/clock/amlogic,axg-audio-clkc.yaml     | 55 +++++++++++++++++++++-
 1 file changed, 54 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/clock/amlogic,axg-audio-clkc.yaml b/Documentation/devicetree/bindings/clock/amlogic,axg-audio-clkc.yaml
index fd7982dd4ceab82389167079c2258a9acff51a76..c3f0bb9b2ff050394828ba339a7be0c9c48e9a76 100644
--- a/Documentation/devicetree/bindings/clock/amlogic,axg-audio-clkc.yaml
+++ b/Documentation/devicetree/bindings/clock/amlogic,axg-audio-clkc.yaml
@@ -21,6 +21,8 @@ properties:
       - amlogic,axg-audio-clkc
       - amlogic,g12a-audio-clkc
       - amlogic,sm1-audio-clkc
+      - amlogic,s4-audio-clkc
+      - amlogic,clock-pads-clkc
 
   '#clock-cells':
     const: 1
@@ -100,13 +102,15 @@ properties:
   resets:
     description: internal reset line
 
+  power-domains:
+    maxItems: 1
+
 required:
   - compatible
   - '#clock-cells'
   - reg
   - clocks
   - clock-names
-  - resets
 
 allOf:
   - if:
@@ -116,12 +120,37 @@ allOf:
             enum:
               - amlogic,g12a-audio-clkc
               - amlogic,sm1-audio-clkc
+              - amlogic,s4-audio-clkc
     then:
       required:
         - '#reset-cells'
     else:
       properties:
         '#reset-cells': false
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - amlogic,s4-audio-clkc
+    then:
+      required:
+        - power-domains
+    else:
+      properties:
+        power-domains: false
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - amlogic,clock-pads-clkc
+    then:
+      properties:
+        resets: false
+    else:
+      required:
+        - resets
 
 additionalProperties: false
 
@@ -129,6 +158,7 @@ examples:
   - |
     #include <dt-bindings/clock/axg-clkc.h>
     #include <dt-bindings/reset/amlogic,meson-axg-reset.h>
+    #include <dt-bindings/power/meson-s4-power.h>
     apb {
         #address-cells = <2>;
         #size-cells = <2>;
@@ -198,4 +228,27 @@ examples:
                           "slv_lrclk9";
             resets = <&reset RESET_AUDIO>;
         };
+      clk_pad: clock-controller@330e80 {
+        compatible = "amlogic,clock-pads-clkc";
+        reg = <0x0 0x330e80 0x0 0x10>;
+        #clock-cells = <1>;
+        clocks = <&clkc_periphs CLKID_AUDIO>,
+                 <&clkc_pll CLKID_MPLL0>,
+                 <&clkc_pll CLKID_MPLL1>,
+                 <&clkc_pll CLKID_MPLL2>,
+                 <&clkc_pll CLKID_MPLL3>,
+                 <&clkc_pll CLKID_HIFI_PLL>,
+                 <&clkc_pll CLKID_FCLK_DIV3>,
+                 <&clkc_pll CLKID_FCLK_DIV4>,
+                 <&clkc_pll CLKID_FCLK_DIV5>;
+        clock-names = "pclk",
+                      "mst_in0",
+                      "mst_in1",
+                      "mst_in2",
+                      "mst_in3",
+                      "mst_in4",
+                      "mst_in5",
+                      "mst_in6",
+                      "mst_in7";
+      };
     };

-- 
2.43.0

