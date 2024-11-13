From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Wed, 13 Nov 2024 15:29:39 +0800
Subject: [PATCH v6 1/5] dt-bindings: pinctrl: move gpio-cells property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241113-a4_pinctrl-v6-1-35ba2401ee35@amlogic.com>
References: <20241113-a4_pinctrl-v6-0-35ba2401ee35@amlogic.com>
In-Reply-To: <20241113-a4_pinctrl-v6-0-35ba2401ee35@amlogic.com>
To: Linus Walleij <linus.walleij@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731482979; l=4180;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=qxv4emgVPROFoR8ScbTFnmLM8WUD+O9zBXHAgvRPWts=;
 b=95hEgHD2NGZC5TRpIpdAB5GLXogZK1SArEDVX3xOOhfXvQZ+cNZ1IdEhmVMaTg6NVSRGmO8Jm
 YjpMd9laA+BCcR3N+yBpSLxoX/hUTOD9CRhKxluoiNbUpiUDsh4EBDE
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move #gpio-cells property from common yaml file
to lower-level yaml files.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 .../devicetree/bindings/pinctrl/amlogic,meson-pinctrl-a1.yaml          | 3 +++
 .../devicetree/bindings/pinctrl/amlogic,meson-pinctrl-common.yaml      | 3 ---
 .../devicetree/bindings/pinctrl/amlogic,meson-pinctrl-g12a-aobus.yaml  | 3 +++
 .../bindings/pinctrl/amlogic,meson-pinctrl-g12a-periphs.yaml           | 3 +++
 .../devicetree/bindings/pinctrl/amlogic,meson8-pinctrl-aobus.yaml      | 3 +++
 .../devicetree/bindings/pinctrl/amlogic,meson8-pinctrl-cbus.yaml       | 3 +++
 6 files changed, 15 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/pinctrl/amlogic,meson-pinctrl-a1.yaml b/Documentation/devicetree/bindings/pinctrl/amlogic,meson-pinctrl-a1.yaml
index d9e0b2c48e84..a43d6d2a336d 100644
--- a/Documentation/devicetree/bindings/pinctrl/amlogic,meson-pinctrl-a1.yaml
+++ b/Documentation/devicetree/bindings/pinctrl/amlogic,meson-pinctrl-a1.yaml
@@ -38,6 +38,9 @@ patternProperties:
           - const: mux
           - const: gpio
 
+      "#gpio-cells":
+        const: 2
+
       gpio-line-names:
         minItems: 62 # A1
         maxItems: 82 # S4
diff --git a/Documentation/devicetree/bindings/pinctrl/amlogic,meson-pinctrl-common.yaml b/Documentation/devicetree/bindings/pinctrl/amlogic,meson-pinctrl-common.yaml
index e707c222a07f..7b2d129845f1 100644
--- a/Documentation/devicetree/bindings/pinctrl/amlogic,meson-pinctrl-common.yaml
+++ b/Documentation/devicetree/bindings/pinctrl/amlogic,meson-pinctrl-common.yaml
@@ -35,9 +35,6 @@ $defs:
     properties:
       gpio-controller: true
 
-      "#gpio-cells":
-        const: 2
-
       gpio-ranges:
         maxItems: 1
 
diff --git a/Documentation/devicetree/bindings/pinctrl/amlogic,meson-pinctrl-g12a-aobus.yaml b/Documentation/devicetree/bindings/pinctrl/amlogic,meson-pinctrl-g12a-aobus.yaml
index 108719bde0d0..9488bb7c8da3 100644
--- a/Documentation/devicetree/bindings/pinctrl/amlogic,meson-pinctrl-g12a-aobus.yaml
+++ b/Documentation/devicetree/bindings/pinctrl/amlogic,meson-pinctrl-g12a-aobus.yaml
@@ -36,6 +36,9 @@ patternProperties:
           - const: ds
           - const: gpio
 
+      "#gpio-cells":
+        const: 2
+
       gpio-line-names:
         maxItems: 15
 
diff --git a/Documentation/devicetree/bindings/pinctrl/amlogic,meson-pinctrl-g12a-periphs.yaml b/Documentation/devicetree/bindings/pinctrl/amlogic,meson-pinctrl-g12a-periphs.yaml
index dc277f2e2edf..b6f72b2c3d38 100644
--- a/Documentation/devicetree/bindings/pinctrl/amlogic,meson-pinctrl-g12a-periphs.yaml
+++ b/Documentation/devicetree/bindings/pinctrl/amlogic,meson-pinctrl-g12a-periphs.yaml
@@ -38,6 +38,9 @@ patternProperties:
           - const: mux
           - const: ds
 
+      "#gpio-cells":
+        const: 2
+
       gpio-line-names:
         maxItems: 85
 
diff --git a/Documentation/devicetree/bindings/pinctrl/amlogic,meson8-pinctrl-aobus.yaml b/Documentation/devicetree/bindings/pinctrl/amlogic,meson8-pinctrl-aobus.yaml
index add83c676327..1315e6203f44 100644
--- a/Documentation/devicetree/bindings/pinctrl/amlogic,meson8-pinctrl-aobus.yaml
+++ b/Documentation/devicetree/bindings/pinctrl/amlogic,meson8-pinctrl-aobus.yaml
@@ -44,6 +44,9 @@ patternProperties:
           - const: pull
           - const: gpio
 
+      "#gpio-cells":
+        const: 2
+
       gpio-line-names:
         minItems: 11 # GXL
         maxItems: 16 # Meson8
diff --git a/Documentation/devicetree/bindings/pinctrl/amlogic,meson8-pinctrl-cbus.yaml b/Documentation/devicetree/bindings/pinctrl/amlogic,meson8-pinctrl-cbus.yaml
index 412bbcc276f3..07fc77403c6f 100644
--- a/Documentation/devicetree/bindings/pinctrl/amlogic,meson8-pinctrl-cbus.yaml
+++ b/Documentation/devicetree/bindings/pinctrl/amlogic,meson8-pinctrl-cbus.yaml
@@ -45,6 +45,9 @@ patternProperties:
           - const: pull-enable
           - const: gpio
 
+      "#gpio-cells":
+        const: 2
+
       gpio-line-names:
         minItems: 86 # AXG
         maxItems: 120 # Meson8

-- 
2.37.1

