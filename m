From: George Moussalem <george.moussalem@outlook.com>
Date: Wed, 12 Aug 2026 13:34:36 +0400
Subject: [PATCH v2 01/14] dt-bindings: phy: Document the Qualcomm IPQ5332
 UNIPHY USB Super-speed PHY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260812-ipq5018-usb3-v2-1-8f355d7ff0ef@outlook.com>
References: <20260812-ipq5018-usb3-v2-0-8f355d7ff0ef@outlook.com>
In-Reply-To: <20260812-ipq5018-usb3-v2-0-8f355d7ff0ef@outlook.com>
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Praveenkumar I <quic_ipkumar@quicinc.com>, 
 Varadarajan Narayanan <quic_varada@quicinc.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Wesley Cheng <quic_wcheng@quicinc.com>
Cc: linux-arm-msm@vger.kernel.org, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786527282; l=3396;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=x/XHiKaOymN+lw7axxWZFamZVeggR0D96mkqLpOTeXo=;
 b=QaT7K2ge1/yTg8FOi/whyzpy6jxBvE41hSl6F+6pqHKy/8vz7btgew/2phtKJFFdV+Fzttmge
 L7fDr4dsVtyBWD7XfDRcIHaqb1t+k74biRnYt9B2vq1K+WQCqKTzmfM
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Praveenkumar I <quic_ipkumar@quicinc.com>

Document the Qualcomm USB3 22ull UNIPHY present in the IPQ5018 and
IPQ5332 SoCs.

Signed-off-by: Praveenkumar I <quic_ipkumar@quicinc.com>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 .../phy/qcom,ipq5332-uniphy-usb-ss-phy.yaml        | 111 +++++++++++++++++++++
 1 file changed, 111 insertions(+)

diff --git a/Documentation/devicetree/bindings/phy/qcom,ipq5332-uniphy-usb-ss-phy.yaml b/Documentation/devicetree/bindings/phy/qcom,ipq5332-uniphy-usb-ss-phy.yaml
new file mode 100644
index 000000000000..cc9eccac51dd
--- /dev/null
+++ b/Documentation/devicetree/bindings/phy/qcom,ipq5332-uniphy-usb-ss-phy.yaml
@@ -0,0 +1,111 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/phy/qcom,ipq5332-uniphy-usb-ss-phy.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Qualcomm UNIPHY USB Super-Speed 22ull PHY
+
+maintainers:
+  - Praveenkumar I <quic_ipkumar@quicinc.com>
+  - Varadarajan Narayanan <quic_varada@quicinc.com>
+
+description:
+  USB Super-Speed UNIPHY found in Qualcomm IPQ5018 & IPQ5332 SoCs.
+
+properties:
+  compatible:
+    enum:
+      - qcom,ipq5018-uniphy-usb-ss-phy
+      - qcom,ipq5332-uniphy-usb-ss-phy
+
+  reg:
+    maxItems: 1
+
+  clocks:
+    minItems: 2
+    maxItems: 3
+
+  resets:
+    maxItems: 1
+
+  vdd-supply:
+    description:
+      Phandle to 5V regulator supply to PHY digital circuit.
+
+  qcom,phy-usb-mux-sel:
+    description: |
+      Mux selection for USB PHY. The USB3 and PCIe PHY pads are muxed and the
+      mux selection is done via a register in TCSR syscon.
+    $ref: /schemas/types.yaml#/definitions/phandle-array
+    items:
+      - items:
+          - description: phandle of TCSR syscon
+          - description: offset of PHY mux selection register
+
+  "#clock-cells":
+    const: 0
+
+  "#phy-cells":
+    const: 0
+
+required:
+  - compatible
+  - reg
+  - clocks
+  - resets
+  - vdd-supply
+  - qcom,phy-usb-mux-sel
+  - "#clock-cells"
+  - "#phy-cells"
+
+additionalProperties: false
+
+allOf:
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - qcom,ipq5018-uniphy-usb-ss-phy
+    then:
+      properties:
+        clocks:
+          items:
+            - description: USB3 PHY CFG AHB clock
+            - description: USB3 pipe clock
+
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - qcom,ipq5332-uniphy-usb-ss-phy
+    then:
+      properties:
+        clocks:
+          items:
+            - description: Shared PCIe/USB3 PHY AHB clock
+            - description: USB3 PHY CFG AHB clock
+            - description: USB3 pipe clock
+
+examples:
+  - |
+    #include <dt-bindings/clock/qcom,ipq5332-gcc.h>
+
+    phy@4b0000 {
+        compatible = "qcom,ipq5332-uniphy-usb-ss-phy";
+        reg = <0x4b0000 0x800>;
+
+        clocks = <&gcc GCC_PCIE3X1_PHY_AHB_CLK>,
+                 <&gcc GCC_USB0_PHY_CFG_AHB_CLK>,
+                 <&gcc GCC_USB0_PIPE_CLK>;
+        resets = <&gcc GCC_USB0_PHY_BCR>;
+
+        #clock-cells = <0>;
+        #phy-cells = <0>;
+
+        qcom,phy-usb-mux-sel = <&tcsr 0x10540>;
+
+        vdd-supply = <&regulator_fixed_5p0>;
+    };

-- 
2.53.0

