From: Jiebing Chen <jiebing.chen@amlogic.com>
Date: Wed, 21 Oct 2026 15:08:28 +0800
Subject: [PATCH v7 1/5] dt-bindings: clock: meson: Add audio power domain
 for S4 soc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261021-audio_drvier-v7-1-2b9aeae9cb8a@amlogic.com>
References: <20261021-audio_drvier-v7-0-2b9aeae9cb8a@amlogic.com>
In-Reply-To: <20261021-audio_drvier-v7-0-2b9aeae9cb8a@amlogic.com>
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
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792566509; l=1643;
 i=jiebing.chen@amlogic.com; s=20250110; h=from:subject:message-id;
 bh=Rx5wFB2nCKDMgS2AxdE5dKUFuTGBEHrm0nwe1wxO0Fc=;
 b=eBhduL44M/Hu7Y49Qv9Ch18NOTLGupOewGkhCiJANoMMipUyXfSkugV1wPhCTVmX6IqGc6e1O
 aYHYA0HYRvqBCf8ZzedfhFWWrzfRiOhCLQP46zS7kH0jK0336EZK5PD
X-Developer-Key: i=jiebing.chen@amlogic.com; a=ed25519;
 pk=6rFvvF45A84pLNRy03hfUHeROxHCnZ+1KAGw/DoqKic=
X-Endpoint-Received: by B4 Relay for jiebing.chen@amlogic.com/20250110 with auth_id=316
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The audio power domain has been found on S4 device.
It must be enabled prior to audio operations.

Signed-off-by: Jiebing Chen <jiebing.chen@amlogic.com>
---
 .../bindings/clock/amlogic,axg-audio-clkc.yaml          | 17 ++++++++++++++++-
 1 file changed, 16 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/clock/amlogic,axg-audio-clkc.yaml b/Documentation/devicetree/bindings/clock/amlogic,axg-audio-clkc.yaml
index fd7982dd4cea..69f5fef5f14a 100644
--- a/Documentation/devicetree/bindings/clock/amlogic,axg-audio-clkc.yaml
+++ b/Documentation/devicetree/bindings/clock/amlogic,axg-audio-clkc.yaml
@@ -20,6 +20,7 @@ properties:
     enum:
       - amlogic,axg-audio-clkc
       - amlogic,g12a-audio-clkc
+      - amlogic,s4-audio-clkc
       - amlogic,sm1-audio-clkc
 
   '#clock-cells':
@@ -100,6 +101,8 @@ properties:
   resets:
     description: internal reset line
 
+  power-domains:
+    maxItems: 1
 required:
   - compatible
   - '#clock-cells'
@@ -115,6 +118,7 @@ allOf:
           contains:
             enum:
               - amlogic,g12a-audio-clkc
+              - amlogic,s4-audio-clkc
               - amlogic,sm1-audio-clkc
     then:
       required:
@@ -122,7 +126,18 @@ allOf:
     else:
       properties:
         '#reset-cells': false
-
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
 
 examples:

-- 
2.52.0

