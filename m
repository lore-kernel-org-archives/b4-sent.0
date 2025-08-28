From: Nickolay Goppen <setotau@yandex.ru>
Date: Thu, 28 Aug 2025 22:23:38 +0300
Subject: [PATCH v4 2/3] dt-bindings: pinctrl: qcom: Add SDM660 LPI pinctrl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250828-sdm660-lpass-lpi-v4-2-af4afdd52965@yandex.ru>
References: <20250828-sdm660-lpass-lpi-v4-0-af4afdd52965@yandex.ru>
In-Reply-To: <20250828-sdm660-lpass-lpi-v4-0-af4afdd52965@yandex.ru>
To: Bjorn Andersson <andersson@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-gpio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 ~postmarketos/upstreaming@lists.sr.ht, Nickolay Goppen <setotau@yandex.ru>, 
 Richard Acayan <mailingradian@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756409018; l=2869;
 i=setotau@yandex.ru; s=20250815; h=from:subject:message-id;
 bh=vFIjBIiT0xa6pAPf/4umxL0RLwDzLrxG2P7MmgFf9vQ=;
 b=pE6hgqz5HjgMc3QqoNAmcGwhLiDp7PQAoCD+EMIpH11DtRc5z/b6b6CLnxPqPH3YSkMLnWg1+
 270w+qjFHq+ATrxr7prPGPKk2+37Wx4VVFwv+ozNPndUqBMnux4/mhp
X-Developer-Key: i=setotau@yandex.ru; a=ed25519;
 pk=Og7YO6LfW+M2QfcJfjaUaXc8oOr5zoK8+4AtX5ICr4o=
X-Endpoint-Received: by B4 Relay for setotau@yandex.ru/20250815 with auth_id=492
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bindings for pin controller in SDM660 Low Power Audio SubSystem
LPASS).

Co-developed-by: Richard Acayan <mailingradian@gmail.com>
Signed-off-by: Richard Acayan <mailingradian@gmail.com>
Signed-off-by: Nickolay Goppen <setotau@yandex.ru>
---
 .../pinctrl/qcom,sdm660-lpass-lpi-pinctrl.yaml     | 74 ++++++++++++++++++++++
 1 file changed, 74 insertions(+)

diff --git a/Documentation/devicetree/bindings/pinctrl/qcom,sdm660-lpass-lpi-pinctrl.yaml b/Documentation/devicetree/bindings/pinctrl/qcom,sdm660-lpass-lpi-pinctrl.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..f71dbea9f75b398c9c5dd585635c469e1f426b6f
--- /dev/null
+++ b/Documentation/devicetree/bindings/pinctrl/qcom,sdm660-lpass-lpi-pinctrl.yaml
@@ -0,0 +1,74 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/pinctrl/qcom,sdm660-lpass-lpi-pinctrl.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Qualcomm SDM660 SoC LPASS LPI TLMM
+
+maintainers:
+  - Nickolay Goppen <setotau@yandex.ru>
+
+description:
+  Top Level Mode Multiplexer pin controller in the Low Power Audio SubSystem
+  (LPASS) Low Power Island (LPI) of Qualcomm SDM660 SoC.
+
+properties:
+  compatible:
+    const: qcom,sdm660-lpass-lpi-pinctrl
+
+  reg:
+    items:
+      - description: LPASS LPI TLMM Control and Status registers
+
+patternProperties:
+  "-state$":
+    oneOf:
+      - $ref: "#/$defs/qcom-sdm660-lpass-state"
+      - patternProperties:
+          "-pins$":
+            $ref: "#/$defs/qcom-sdm660-lpass-state"
+        additionalProperties: false
+
+$defs:
+  qcom-sdm660-lpass-state:
+    type: object
+    description:
+      Pinctrl node's client devices use subnodes for desired pin configuration.
+      Client device subnodes use below standard properties.
+    $ref: qcom,lpass-lpi-common.yaml#/$defs/qcom-tlmm-state
+    unevaluatedProperties: false
+
+    properties:
+      pins:
+        description:
+          List of gpio pins affected by the properties specified in this
+          subnode.
+        items:
+          pattern: "^gpio([0-9]|[1-2][0-9]|3[0-1])$"
+
+      function:
+        enum: [ gpio, comp_rx, dmic12, dmic34, mclk0, pdm_2_gpios,
+                pdm_clk, pdm_rx, pdm_sync ]
+        description:
+          Specify the alternative function to be configured for the specified
+          pins.
+
+allOf:
+  - $ref: qcom,lpass-lpi-common.yaml#
+
+required:
+  - compatible
+  - reg
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    lpi_tlmm: pinctrl@15070000 {
+        compatible = "qcom,sdm660-lpass-lpi-pinctrl";
+        reg = <0x15070000 0x20000>;
+        gpio-controller;
+        #gpio-cells = <2>;
+        gpio-ranges = <&lpi_tlmm 0 0 32>;
+    };

-- 
2.51.0

