From: Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>
Date: Thu, 06 Aug 2026 20:21:36 +0530
Subject: [PATCH v5 1/2] dt-bindings: clock: qcom: Add LPASS VA CSR
 HeartBeat pulse clock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260806-master-20260805-sync-v5-1-0ff42e9b6431@oss.qualcomm.com>
References: <20260806-master-20260805-sync-v5-0-0ff42e9b6431@oss.qualcomm.com>
In-Reply-To: <20260806-master-20260805-sync-v5-0-0ff42e9b6431@oss.qualcomm.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Srinivas Kandagatla <srinivas.kandagatla@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 prasad.kumpatla@oss.qualcomm.com, 
 Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786027907; l=2278;
 i=sarath.ganapathiraju@oss.qualcomm.com; s=default;
 h=from:subject:message-id; bh=qxVOLK3Yva6vAmZ6Xln4mzA/Miy1La7zeDTze4nIz90=;
 b=87HM7BtBsxxGw2O5gXizH1O4GgWMqqzSmrvoovkXlvDd5KvAQHQCY9+PNew5ooQAXBH4DvikZ
 dGQsisWptNVATfEoynSAlarQnXWnfUGvDYKn0FNWKQ3cXJ9Zmo4I3WZ
X-Developer-Key: i=sarath.ganapathiraju@oss.qualcomm.com; a=ed25519;
 pk=4p2FWGXM+F2sir13Lu5stw5aKX5trUymK/ttESvgxQg=
X-Endpoint-Received: by B4 Relay for sarath.ganapathiraju@oss.qualcomm.com/default with auth_id=870
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a binding for the Qualcomm LPASS VA CSR rate generator node that
exposes the lpass_heartbeat_pulse clock on hawi.

The HeartBeat Pulse (also known as RateGen Pulse) synchronizes the
start of the DMAs and Codec Interfaces for the audio usecase and can
serve as a periodic wakeup source for the DSP.

Signed-off-by: Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>
Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
---
 .../bindings/clock/qcom,hawi-lpass-va-csr.yaml     | 51 ++++++++++++++++++++++
 1 file changed, 51 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/qcom,hawi-lpass-va-csr.yaml b/Documentation/devicetree/bindings/clock/qcom,hawi-lpass-va-csr.yaml
new file mode 100644
index 000000000000..9935173d8bee
--- /dev/null
+++ b/Documentation/devicetree/bindings/clock/qcom,hawi-lpass-va-csr.yaml
@@ -0,0 +1,51 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/clock/qcom,hawi-lpass-va-csr.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Qualcomm LPASS VA CSR heartbeat pulse clock provider
+
+maintainers:
+  - Srinivas Kandagatla <srinivas.kandagatla@oss.qualcomm.com>
+  - Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>
+
+description:
+  The LPASS (Low Power Audio Subsystem) VA CSR block contains a rate
+  generator that produces a periodic HeartBeat Pulse, also known as
+  the RateGen Pulse. This pulse synchronizes the start of DMAs and
+  Codec Interfaces for audio usecases and can serve as a periodic
+  wakeup source for the DSP.
+
+properties:
+  compatible:
+    enum:
+      - qcom,hawi-lpass-va-csr
+
+  reg:
+    maxItems: 1
+    description: Address and size of the rate generator registers within
+      the VA CSR block.
+
+  "#clock-cells":
+    const: 0
+
+required:
+  - compatible
+  - reg
+  - "#clock-cells"
+
+additionalProperties: false
+
+examples:
+  - |
+    soc {
+      #address-cells = <2>;
+      #size-cells = <2>;
+
+      clock-controller@7eed000 {
+        compatible = "qcom,hawi-lpass-va-csr";
+        reg = <0x0 0x07eed000 0x0 0x14>;
+        #clock-cells = <0>;
+      };
+    };

-- 
2.34.1

