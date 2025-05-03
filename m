From: Sven Peter <sven@svenpeter.dev>
Date: Sat, 03 May 2025 10:06:48 +0000
Subject: [PATCH v4 1/9] dt-bindings: gpio: Add Apple Mac SMC GPIO block
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250503-smc-6-15-v4-1-500b9b6546fc@svenpeter.dev>
References: <20250503-smc-6-15-v4-0-500b9b6546fc@svenpeter.dev>
In-Reply-To: <20250503-smc-6-15-v4-0-500b9b6546fc@svenpeter.dev>
To: Sven Peter <sven@svenpeter.dev>, Janne Grunau <j@jannau.net>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Neal Gompa <neal@gompa.dev>, 
 Hector Martin <marcan@marcan.st>, Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sebastian Reichel <sre@kernel.org>, 
 Lee Jones <lee@kernel.org>, Marc Zyngier <maz@kernel.org>, 
 "Russell King (Oracle)" <rmk+kernel@armlinux.org.uk>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2207; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=7EVhNhPla32kZTqn+E4bqYHzUCjdjU3KtFUCmUQI7UM=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ4boqyPVVjZlh0udX7netF2fc79rZdm5M/5tNhc4u+ZmB
 zSZ78vsKGVhEONgkBVTZNm+3970ycM3gks3XXoPM4eVCWQIAxenAEzk5VSGX0xtEn/bj3YcOSdd
 s9NTLtet7q9g9Y6w19zSV3Mf27lcnMbIMKn+x0XnqqLANRdOsCY+FuZSFSqX/Hv7eueL7roP6pJ
 anAA=
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: "Russell King (Oracle)" <rmk+kernel@armlinux.org.uk>

Add the DT binding for the Apple Mac System Management Controller GPIOs.

Signed-off-by: Russell King (Oracle) <rmk+kernel@armlinux.org.uk>
Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
 .../devicetree/bindings/gpio/apple,smc-gpio.yaml   | 37 ++++++++++++++++++++++
 MAINTAINERS                                        |  1 +
 2 files changed, 38 insertions(+)

diff --git a/Documentation/devicetree/bindings/gpio/apple,smc-gpio.yaml b/Documentation/devicetree/bindings/gpio/apple,smc-gpio.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..07305eeb2595f59d5c28f6e507295b828dafd4a1
--- /dev/null
+++ b/Documentation/devicetree/bindings/gpio/apple,smc-gpio.yaml
@@ -0,0 +1,37 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/gpio/apple,smc-gpio.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Apple Mac System Management Controller GPIO
+
+maintainers:
+  - Sven Peter <sven@svenpeter.dev>
+
+description:
+  Apple Mac System Management Controller GPIO block.
+
+properties:
+  compatible:
+    const: apple,smc-gpio
+
+  gpio-controller: true
+
+  '#gpio-cells':
+    const: 2
+
+required:
+  - compatible
+  - gpio-controller
+  - '#gpio-cells'
+
+additionalProperties: false
+
+examples:
+  - |
+    gpio {
+        compatible = "apple,smc-gpio";
+        gpio-controller;
+        #gpio-cells = <2>;
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index a70d79a5f6ae98fc0055f1da20dbecc095ea5c65..7f91f0225133490607ba0d79ad4225892ef31a66 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2267,6 +2267,7 @@ F:	Documentation/devicetree/bindings/arm/apple/*
 F:	Documentation/devicetree/bindings/clock/apple,nco.yaml
 F:	Documentation/devicetree/bindings/cpufreq/apple,cluster-cpufreq.yaml
 F:	Documentation/devicetree/bindings/dma/apple,admac.yaml
+F:	Documentation/devicetree/bindings/gpio/apple,smc-gpio.yaml
 F:	Documentation/devicetree/bindings/i2c/apple,i2c.yaml
 F:	Documentation/devicetree/bindings/input/touchscreen/apple,z2-multitouch.yaml
 F:	Documentation/devicetree/bindings/interrupt-controller/apple,*

-- 
2.34.1

