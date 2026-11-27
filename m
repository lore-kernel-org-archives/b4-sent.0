From: Jiebing Chen <jiebing.chen@amlogic.com>
Date: Fri, 27 Nov 2026 17:11:27 +0800
Subject: [PATCH 2/2] ASoC:dt-bindings:clock: Add audio power domain for S4
 soc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-clock_audio-v1-2-cf3ccf6b2bf0@amlogic.com>
References: <20261127-clock_audio-v1-0-cf3ccf6b2bf0@amlogic.com>
In-Reply-To: <20261127-clock_audio-v1-0-cf3ccf6b2bf0@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Jiebing Chen <jiebing.chen@amlogic.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795770705; l=1619;
 i=jiebing.chen@amlogic.com; s=20250110; h=from:subject:message-id;
 bh=8FHHLcJZtu8lo09r1PD8utgqmy2N7M4R5lGLzc1tkrA=;
 b=S5/ZguzthjI3gVUjCh7bFSWwXQpt4KWJI/JOEdlhWakZ84ChOO6sR/8sDkcQ47HcXY+LnDgd8
 EVXcg11kSBQDiP1TOsfR/KzzecBkhRsqAjyIHRKX6IB93LBOJjxr+mx
X-Developer-Key: i=jiebing.chen@amlogic.com; a=ed25519;
 pk=6rFvvF45A84pLNRy03hfUHeROxHCnZ+1KAGw/DoqKic=
X-Endpoint-Received: by B4 Relay for jiebing.chen@amlogic.com/20250110 with auth_id=316
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The audio power domain has been found on S4 device.
It must be enabled prior to audio operations.

Signed-off-by: Jiebing Chen <jiebing.chen@amlogic.com>
---
 .../bindings/clock/amlogic,axg-audio-clkc.yaml          | 17 +++++++++++++++++
 1 file changed, 17 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/amlogic,axg-audio-clkc.yaml b/Documentation/devicetree/bindings/clock/amlogic,axg-audio-clkc.yaml
index fd7982dd4cea..75ddaf8d8091 100644
--- a/Documentation/devicetree/bindings/clock/amlogic,axg-audio-clkc.yaml
+++ b/Documentation/devicetree/bindings/clock/amlogic,axg-audio-clkc.yaml
@@ -20,6 +20,7 @@ properties:
     enum:
       - amlogic,axg-audio-clkc
       - amlogic,g12a-audio-clkc
+      - amlogic,s4-audio-clkc
       - amlogic,sm1-audio-clkc
 
   '#clock-cells':
@@ -100,6 +101,9 @@ properties:
   resets:
     description: internal reset line
 
+  power-domains:
+    maxItems: 1
+
 required:
   - compatible
   - '#clock-cells'
@@ -115,6 +119,7 @@ allOf:
           contains:
             enum:
               - amlogic,g12a-audio-clkc
+              - amlogic,s4-audio-clkc
               - amlogic,sm1-audio-clkc
     then:
       required:
@@ -122,6 +127,18 @@ allOf:
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
 
 additionalProperties: false
 

-- 
2.52.0

