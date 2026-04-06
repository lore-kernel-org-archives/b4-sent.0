From: George Moussalem <george.moussalem@outlook.com>
Date: Mon, 06 Apr 2026 22:24:38 +0200
Subject: [PATCH v21 1/6] dt-bindings: pwm: add IPQ6018 binding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260406-ipq-pwm-v21-1-6ed1e868e4c2@outlook.com>
References: <20260406-ipq-pwm-v21-0-6ed1e868e4c2@outlook.com>
In-Reply-To: <20260406-ipq-pwm-v21-0-6ed1e868e4c2@outlook.com>
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-pwm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>, 
 Devi Priya <quic_devipriy@quicinc.com>, 
 Baruch Siach <baruch.siach@siklu.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Krzysztof Kozlowski <krzk@kernel.org>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775507135; l=1986;
 i=george.moussalem@outlook.com; s=20260406; h=from:subject:message-id;
 bh=nDWws50WaNvgOfPtIO2WBqjwriMPqndXS0BxB4pO04E=;
 b=vWsu1ylE+520h9fCI92em01kv+7O5LlzpmfD0ib1MZKI3/mGs5vExbXkpgmE7SvoDhDVnj3Mm
 NIVcIxlzI8kAgmvzaf5m4HsYQrPj2ylqu4GrmhtQOrjKcpNfF6DwfWG
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=uqspem3ahtBvPEBuxVbyyXT/0Vp3JNb/mo1EPbmBzWg=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20260406 with auth_id=722
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Devi Priya <quic_devipriy@quicinc.com>

DT binding for the PWM block in Qualcomm IPQ6018 SoC.

Reviewed-by: Bjorn Andersson <bjorn.andersson@linaro.org>
Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Co-developed-by: Baruch Siach <baruch.siach@siklu.com>
Signed-off-by: Baruch Siach <baruch.siach@siklu.com>
Signed-off-by: Devi Priya <quic_devipriy@quicinc.com>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 .../devicetree/bindings/pwm/qcom,ipq6018-pwm.yaml  | 51 ++++++++++++++++++++++
 1 file changed, 51 insertions(+)

diff --git a/Documentation/devicetree/bindings/pwm/qcom,ipq6018-pwm.yaml b/Documentation/devicetree/bindings/pwm/qcom,ipq6018-pwm.yaml
new file mode 100644
index 000000000000..f9f1f652e752
--- /dev/null
+++ b/Documentation/devicetree/bindings/pwm/qcom,ipq6018-pwm.yaml
@@ -0,0 +1,51 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/pwm/qcom,ipq6018-pwm.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Qualcomm IPQ6018 PWM controller
+
+maintainers:
+  - George Moussalem <george.moussalem@outlook.com>
+
+properties:
+  compatible:
+    oneOf:
+      - items:
+          - enum:
+              - qcom,ipq5018-pwm
+              - qcom,ipq5332-pwm
+              - qcom,ipq9574-pwm
+          - const: qcom,ipq6018-pwm
+      - const: qcom,ipq6018-pwm
+
+  reg:
+    maxItems: 1
+
+  clocks:
+    maxItems: 1
+
+  "#pwm-cells":
+    const: 3
+
+required:
+  - compatible
+  - reg
+  - clocks
+  - "#pwm-cells"
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/clock/qcom,gcc-ipq6018.h>
+
+    pwm: pwm@1941010 {
+        compatible = "qcom,ipq6018-pwm";
+        reg = <0x01941010 0x20>;
+        clocks = <&gcc GCC_ADSS_PWM_CLK>;
+        assigned-clocks = <&gcc GCC_ADSS_PWM_CLK>;
+        assigned-clock-rates = <100000000>;
+        #pwm-cells = <3>;
+    };

-- 
2.39.5

