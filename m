From: David Heidelberg <david@ixit.cz>
Date: Mon, 24 Nov 2025 22:53:34 +0100
Subject: [PATCH RFC 1/8] dt-bindings: power: supply: Add schema for
 Qualcomm pmi8998 fuel gauge
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251124-pmi8998_fuel_gauge-v1-1-dd3791f61478@ixit.cz>
References: <20251124-pmi8998_fuel_gauge-v1-0-dd3791f61478@ixit.cz>
In-Reply-To: <20251124-pmi8998_fuel_gauge-v1-0-dd3791f61478@ixit.cz>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Casey Connolly <casey@connolly.tech>, Joel Selvaraj <foss@joelselvaraj.com>, 
 Yassine Oudjana <y.oudjana@protonmail.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Alexander Martinz <amartinz@shiftphones.com>, 
 =?utf-8?q?Barnab=C3=A1s_Cz=C3=A9m=C3=A1n?= <barnabas.czeman@mainlining.org>, 
 Richard Acayan <mailingradian@gmail.com>, 
 Alexey Minnekhanov <alexeymin@postmarketos.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2537; i=david@ixit.cz;
 h=from:subject:message-id; bh=8gDcJuVR00nr5ImU9LywPVZeG4RNmdnomhcdhAvXSQU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpJNPfKWxSxscYEJAYp0SZC4kEMTmRSgRMI64xj
 rQ01rKQLCGJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaSTT3wAKCRBgAj/E00kg
 cvywD/44kARU05lAFhs0AM2MeVjrNig/NHmW+MGYEYMB/NjjZhFdlAEW2mW3SDWCOVZsDI3D+GO
 vjP++xsbeZeNP71XrakQ2eVD1Qzzv4DQvbmIMAxUrutiJklsbsHss2jAJIAXFZ9mQ8BTXafGmQg
 5QHQ2IjNqg2FejoJfBEWUs0hs9+gYieJ9w15xoWpCG2WWa75wqRGfM5588iTYad1XgSRy/opK+9
 K6Hi5GAbCSNUR1QfAKTOeIty1pJYalKQ1AXHflttX2gghCqUHI533EC8LTC3D+TGzzQo2fB1h0B
 Ouz9Kwtp8FsrQCS3o9C2aPuKVBWkvxTr4yCL038A1IRWsgH6quQ7jGU0BU3Qgv8LuqdhTbdScb6
 4K6rYCnpgGiG5xGRJcMgYg8ZHdHURY+Z7I2MEbHeTq7n18KXos3oNf2DzVA+mRR2OP9ZQZWDqWC
 UyXIGTv4h4vA2TdD9cSB6WG3RYJqRf5IGCMIbk6ENdzDUuSzZmlgRKdi3nA1MFLQSAh3m3wqEtM
 4Qp/IQyP3ktpTg+EsrzHh+PY49I+eGXTWifdnXJAEZVgne2k44igHbNNEU7tKbmoQe1qRJSF4bT
 niN4FbblG68cu2nvm6tWzI2S28R5wT9HXcMRtyiBenjGRyMnVjuMfT7/pxQqU5tzHd/y3U8p1i6
 V8uLRsbV9ElYgvw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Yassine Oudjana <y.oudjana@protonmail.com>

Add a device-tree schema for Qualcomm PMIC 8998 fuel gauge.

Signed-off-by: Barnabás Czémán <barnabas.czeman@mainlining.org>
Signed-off-by: Yassine Oudjana <y.oudjana@protonmail.com>
---
 .../bindings/power/supply/qcom,pmi8998-fg.yaml     | 77 ++++++++++++++++++++++
 1 file changed, 77 insertions(+)

diff --git a/Documentation/devicetree/bindings/power/supply/qcom,pmi8998-fg.yaml b/Documentation/devicetree/bindings/power/supply/qcom,pmi8998-fg.yaml
new file mode 100644
index 0000000000000..9acc1a7f04cda
--- /dev/null
+++ b/Documentation/devicetree/bindings/power/supply/qcom,pmi8998-fg.yaml
@@ -0,0 +1,77 @@
+# SPDX-License-Identifier: (GPL-2.0-only or BSD-3-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/power/supply/qcom,pmi8998-fg.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Qualcomm PMI8998 PMIC Fuel Gauge
+
+maintainers:
+  - Casey Connolly <casey@connolly.tech>
+  - Joel Selvaraj <foss@joelselvaraj.com>
+  - Yassine Oudjana <y.oudjana@protonmail.com>
+
+allOf:
+  - $ref: /schemas/power/supply/power-supply.yaml#
+
+properties:
+  compatible:
+    const: qcom,pmi8998-fg
+
+  reg:
+    maxItems: 1
+
+  monitored-battery:
+    description: |
+       phandle of battery characteristics node.
+       The fuel gauge uses the following battery properties:
+       - charge-full-design-microamp-hours
+       - voltage-min-design-microvolt
+       - voltage-max-design-microvolt
+       See Documentation/devicetree/bindings/power/supply/battery.yaml
+
+  interrupts:
+    items:
+      - description: State of charge change interrupt
+
+  interrupt-names:
+    items:
+      - const: soc-delta
+
+  power-supplies: true
+
+required:
+  - compatible
+  - reg
+  - monitored-battery
+  - interrupts
+  - interrupt-names
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    battery: battery {
+      compatible = "simple-battery";
+
+      charge-full-design-microamp-hours = <4070000>;
+      voltage-min-design-microvolt = <3400000>;
+      voltage-max-design-microvolt = <4400000>;
+    };
+
+    pmic {
+      #address-cells = <1>;
+      #size-cells = <0>;
+
+      fuel-gauge@4000 {
+        compatible = "qcom,pmi8998-fg";
+        reg = <0x4000>;
+
+        interrupts = <0x2 0x40 0x4 IRQ_TYPE_EDGE_RISING>;
+        interrupt-names = "soc-delta";
+
+        monitored-battery = <&battery>;
+      };
+    };

-- 
2.51.0

