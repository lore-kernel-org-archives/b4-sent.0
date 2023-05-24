From: Caleb Connolly <caleb.connolly@linaro.org>
Date: Wed, 24 May 2023 01:34:17 +0100
Subject: [PATCH v8 1/2] dt-bindings: power: supply: qcom,pmi8998-charger:
 add bindings for smb2 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230524-pmi8998-charger-v8-1-b87ffcd9864d@linaro.org>
References: <20230524-pmi8998-charger-v8-0-b87ffcd9864d@linaro.org>
In-Reply-To: <20230524-pmi8998-charger-v8-0-b87ffcd9864d@linaro.org>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Caleb Connolly <caleb.connolly@linaro.org>, Andy Gross <agross@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, 
 Nathan Chancellor <nathan@kernel.org>, 
 Nick Desaulniers <ndesaulniers@google.com>, Tom Rix <trix@redhat.com>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.13-dev-1ec66
X-Developer-Signature: v=1; a=openpgp-sha256; l=2700;
 i=caleb.connolly@linaro.org; h=from:subject:message-id;
 bh=mAKhQB4vMKOTIi4ptw5/6sx61rxVOFQj12BF/0V6Wf4=;
 b=owEBbQKS/ZANAwAIAQWDMSsZX2S2AcsmYgBkbVuca91BFBxEWn37qyjvWZIrMB0BwpMgCgKCs
 cJ8M3sZRReJAjMEAAEIAB0WIQS2UaFGPGq+0GkMVc0FgzErGV9ktgUCZG1bnAAKCRAFgzErGV9k
 tmgbEACjPSDR8eI8EsY4Om5WGMdOAO/tbAfYF0j8s33wbRWawjdCBg3GQNdrk3wMLA0yRzWXfVp
 GI9whTjT9mdQD9vRSWdFjh1MYynIXKMSjDQpSadw28WGFu2yiHsmdHNo3KGoaWPicvS55Z1iKv7
 dKRkRMmkDPsqjCLaFfs2LT7rif3y0l1bY5vyNXZVBkZTYSuVcbJV557QZCHCMt8FntRv1h/ni7T
 kkR83slKYrmEPMdMxqjc2A7cx3WtNHLrSPaUxCATzMrZXnIN8JvsD1Q/VMEHhFquZb8y5FD+H4g
 a3KU6AHASEAtOlRKRIuHB47ydPMQRdF1N6r5rf1hWHoSUpb2Gjy37ur1xTcL2Ng7lzEIy6sMJV0
 3Ubxc04LH8h4BS2RHNuFzixylLqmi8QxBNplVA/MlW8ue103toTf6A+2KHxYSbQOjE/bwHXX4h5
 Y47CFZ0HpfXxmXA0a8srIENWgBWVcVjRKREeepxU1VW4WP101z+lJBO+C8D0vogEqvc1j5XmyLh
 lFlikCA0H4jzEoDPvZmIdD2mKNXpc8kRJYtMRTgj2PhlJQv8SVy4nww7IYzvh0CE1oC6x3lMvSy
 GXtLYN22rD3MlqP6aEYj61lNLvfKoRfRLHCgRb6OsMZQKokJ5D1/etPw56pYZDlZndHpOqX6Ueq
 Q0ywnBAAzqGrYMw==
X-Developer-Key: i=caleb.connolly@linaro.org; a=openpgp;
 fpr=83B24DA7FE145076BC38BB250CD904EB673A7C47
X-Endpoint-Received: by B4 Relay for caleb.connolly@linaro.org/default with auth_id=49
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add devicetree bindings for the Qualcomm PMI8998/PM660 SMB2 charger
driver.

Signed-off-by: Caleb Connolly <caleb.connolly@linaro.org>
Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
---
 .../power/supply/qcom,pmi8998-charger.yaml         | 82 ++++++++++++++++++++++
 1 file changed, 82 insertions(+)

diff --git a/Documentation/devicetree/bindings/power/supply/qcom,pmi8998-charger.yaml b/Documentation/devicetree/bindings/power/supply/qcom,pmi8998-charger.yaml
new file mode 100644
index 000000000000..277c47e048b6
--- /dev/null
+++ b/Documentation/devicetree/bindings/power/supply/qcom,pmi8998-charger.yaml
@@ -0,0 +1,82 @@
+# SPDX-License-Identifier: GPL-2.0 OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/power/supply/qcom,pmi8998-charger.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Qualcomm PMI8998/PM660 Switch-Mode Battery Charger "2"
+
+maintainers:
+  - Caleb Connolly <caleb.connolly@linaro.org>
+
+properties:
+  compatible:
+    enum:
+      - qcom,pmi8998-charger
+      - qcom,pm660-charger
+
+  reg:
+    maxItems: 1
+
+  interrupts:
+    maxItems: 4
+
+  interrupt-names:
+    items:
+      - const: usb-plugin
+      - const: bat-ov
+      - const: wdog-bark
+      - const: usbin-icl-change
+
+  io-channels:
+    items:
+      - description: USB in current in uA
+      - description: USB in voltage in uV
+
+  io-channel-names:
+    items:
+      - const: usbin_i
+      - const: usbin_v
+
+  monitored-battery:
+    description: phandle to the simple-battery node
+    $ref: /schemas/types.yaml#/definitions/phandle
+
+required:
+  - compatible
+  - reg
+  - interrupts
+  - interrupt-names
+  - io-channels
+  - io-channel-names
+  - monitored-battery
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+
+    pmic {
+      #address-cells = <1>;
+      #size-cells = <0>;
+      #interrupt-cells = <4>;
+
+      charger@1000 {
+        compatible = "qcom,pmi8998-charger";
+        reg = <0x1000>;
+
+        interrupts = <0x2 0x12 0x2 IRQ_TYPE_EDGE_BOTH>,
+                     <0x2 0x13 0x4 IRQ_TYPE_EDGE_BOTH>,
+                     <0x2 0x13 0x6 IRQ_TYPE_EDGE_RISING>,
+                     <0x2 0x16 0x1 IRQ_TYPE_EDGE_RISING>;
+        interrupt-names = "usb-plugin", "bat-ov", "wdog-bark", "usbin-icl-change";
+
+        io-channels = <&pmi8998_rradc 3>,
+                      <&pmi8998_rradc 4>;
+        io-channel-names = "usbin_i",
+                           "usbin_v";
+
+        monitored-battery = <&battery>;
+      };
+    };

-- 
2.40.1

