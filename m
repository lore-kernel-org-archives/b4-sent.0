From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Thu, 01 Oct 2026 18:55:34 +0200
Subject: [PATCH v4 1/3] dt-bindings: pwm: amlogic: Add bus clock for S4
 like
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261001-add-t7-sys-pwm-clk-v4-1-8ed2b1e0cdfe@aliel.fr>
References: <20261001-add-t7-sys-pwm-clk-v4-0-8ed2b1e0cdfe@aliel.fr>
In-Reply-To: <20261001-add-t7-sys-pwm-clk-v4-0-8ed2b1e0cdfe@aliel.fr>
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-pwm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, 
 Ronald Claveau <linux-kernel-dev@aliel.fr>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1948;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=DajmJPOZU5T3SXCz0k6CFapeDP4KwjcTSjnqHfrN4Go=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ9a+CRuS50VNubVQaV/S0nmPQ48emvfa5HK8UtD/tZknJ
 357vs8huKOUhUGMi0FWTJGlf67liXeXj575ukc9BWYOKxPIEAYuTgGYiDwfI8PCX4eY90VMeeA+
 +8DTCYv88v5FTmnY/uj3g6KZzwvDv7PpMTJc+7nr2vpanoZ0qcebeza1mPEkBMbZGEV+rt8rqP0
 +4QUzAA==
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The T7, A1, C3, and S4 PWM controllers have a bus system clock in
addition to the two input clocks of channels A and B.

The channel clocks are acquired by index in the pwm driver,
where the bus clock is fetched by name, with optional get
which is silent when not provided.

Require clock-names and minimum 3 items for S4, and devices
which fallback to S4, where the PWM devices do not work
without all 3 clocks.

Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
 Documentation/devicetree/bindings/pwm/pwm-amlogic.yaml | 13 ++++++++++---
 1 file changed, 10 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/pwm/pwm-amlogic.yaml b/Documentation/devicetree/bindings/pwm/pwm-amlogic.yaml
index c337d85da40f1..6d01adcfe897f 100644
--- a/Documentation/devicetree/bindings/pwm/pwm-amlogic.yaml
+++ b/Documentation/devicetree/bindings/pwm/pwm-amlogic.yaml
@@ -62,7 +62,7 @@ properties:
 
   clock-names:
     minItems: 1
-    maxItems: 2
+    maxItems: 3
 
   power-domains:
     maxItems: 1
@@ -143,9 +143,15 @@ allOf:
           items:
             - description: input clock of PWM channel A
             - description: input clock of PWM channel B
-        clock-names: false
+            - description: Bus clock, gates register access to the PWM controller
+        clock-names:
+          items:
+            - const: channel-a
+            - const: channel-b
+            - const: bus
       required:
         - clocks
+        - clock-names
 
   - if:
       properties:
@@ -179,6 +185,7 @@ examples:
     pwm@1000 {
       compatible = "amlogic,meson-s4-pwm";
       reg = <0x1000 0x10>;
-      clocks = <&pwm_src_a>, <&pwm_src_b>;
+      clocks = <&pwm_src_a>, <&pwm_src_b>, <&pwm_src_bus>;
+      clock-names = "channel-a", "channel-b", "bus";
       #pwm-cells = <3>;
     };

-- 
2.49.0

