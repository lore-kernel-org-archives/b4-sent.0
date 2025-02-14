From: jiebing chen <jiebing.chen@amlogic.com>
Date: Fri, 14 Feb 2025 10:13:40 +0800
Subject: [PATCH v2 1/5] dt-bindings: clock: axg-audio: Add mclk and sclk
 pad for s4
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250214-audio_drvier-v2-1-37881fa37c9e@amlogic.com>
References: <20250214-audio_drvier-v2-0-37881fa37c9e@amlogic.com>
In-Reply-To: <20250214-audio_drvier-v2-0-37881fa37c9e@amlogic.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739499221; l=2710;
 i=jiebing.chen@amlogic.com; s=20250110; h=from:subject:message-id;
 bh=TXC0nl0bF7ijEJ/f38+2QuSrF8LeB5NHcRgGAcnuK24=;
 b=hAMjhlWqZaRMxN531Yg+WGONAd/WY5kKkSD06NC7KGnMbzlciO0K80ublViD+xrTkfXqM8JwG
 p75Eq0MFLDoDJKe4Vm/Wx/FTn0L6cGgslDabJaKnkzKXY/41ZfN7WYd
X-Developer-Key: i=jiebing.chen@amlogic.com; a=ed25519;
 pk=6rFvvF45A84pLNRy03hfUHeROxHCnZ+1KAGw/DoqKic=
X-Endpoint-Received: by B4 Relay for jiebing.chen@amlogic.com/20250110 with auth_id=316
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

add the s4 audio power domain, add the mclk pad, sclk pad
and lrclk pad clock id for s4

Signed-off-by: jiebing chen <jiebing.chen@amlogic.com>
---
 .../bindings/clock/amlogic,axg-audio-clkc.yaml         | 18 ++++++++++++++++++
 include/dt-bindings/clock/axg-audio-clkc.h             | 11 +++++++++++
 2 files changed, 29 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/amlogic,axg-audio-clkc.yaml b/Documentation/devicetree/bindings/clock/amlogic,axg-audio-clkc.yaml
index fd7982dd4ceab82389167079c2258a9acff51a76..364783c6f7572b09d57de2b35d33adb7bcf7db18 100644
--- a/Documentation/devicetree/bindings/clock/amlogic,axg-audio-clkc.yaml
+++ b/Documentation/devicetree/bindings/clock/amlogic,axg-audio-clkc.yaml
@@ -21,6 +21,7 @@ properties:
       - amlogic,axg-audio-clkc
       - amlogic,g12a-audio-clkc
       - amlogic,sm1-audio-clkc
+      - amlogic,s4-audio-clkc
 
   '#clock-cells':
     const: 1
@@ -100,6 +101,9 @@ properties:
   resets:
     description: internal reset line
 
+  power-domains:
+    description: audio controller power
+
 required:
   - compatible
   - '#clock-cells'
@@ -116,12 +120,26 @@ allOf:
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
+
+    else:
+      properties:
+        power-domains: false
 
 additionalProperties: false
 
diff --git a/include/dt-bindings/clock/axg-audio-clkc.h b/include/dt-bindings/clock/axg-audio-clkc.h
index 607f23b83fa7287fe0403682ebf827e2df26a1ce..75dde05343d1fa74304ee21c9ec0541a8f51b15e 100644
--- a/include/dt-bindings/clock/axg-audio-clkc.h
+++ b/include/dt-bindings/clock/axg-audio-clkc.h
@@ -162,5 +162,16 @@
 #define AUD_CLKID_EARCRX_DMAC_SEL	182
 #define AUD_CLKID_EARCRX_DMAC_DIV	183
 #define AUD_CLKID_EARCRX_DMAC		184
+#define AUD_CLKID_TDM_MCLK_PAD0_SEL     185
+#define AUD_CLKID_TDM_MCLK_PAD1_SEL     186
+#define AUD_CLKID_TDM_MCLK_PAD0_DIV     187
+#define AUD_CLKID_TDM_MCLK_PAD1_DIV     188
+#define AUD_CLKID_TDM_MCLK_PAD2         189
+#define AUD_CLKID_TDM_MCLK_PAD2_SEL     190
+#define AUD_CLKID_TDM_MCLK_PAD2_DIV     191
+#define AUD_CLKID_TDM_SCLK_PAD3		192
+#define AUD_CLKID_TDM_SCLK_PAD4		193
+#define AUD_CLKID_TDM_LRCLK_PAD3	194
+#define AUD_CLKID_TDM_LRCLK_PAD4	195
 
 #endif /* __AXG_AUDIO_CLKC_BINDINGS_H */

-- 
2.43.0

