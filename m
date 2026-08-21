From: Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>
Date: Fri, 21 Aug 2026 23:26:50 +0530
Subject: [PATCH v6 1/2] dt-bindings: clock: qcom: Add LPASS VA CSR
 HeartBeat pulse clock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260821-heartbeat-v6-next-20260821-send-v6-1-62c5df84ce21@oss.qualcomm.com>
References: <20260821-heartbeat-v6-next-20260821-send-v6-0-62c5df84ce21@oss.qualcomm.com>
In-Reply-To: <20260821-heartbeat-v6-next-20260821-send-v6-0-62c5df84ce21@oss.qualcomm.com>
To: Bjorn Andersson <andersson@kernel.org>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Srinivas Kandagatla <srinivas.kandagatla@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>, 
 prasad.kumpatla@oss.qualcomm.com, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787335010; l=2151;
 i=sarath.ganapathiraju@oss.qualcomm.com; s=default;
 h=from:subject:message-id; bh=5DgYRL2d+tr5ENMkYeTnCE9rjgsWEYIKZ5OrVRuZXu4=;
 b=XMI4xKIek6X/vgwiT8E4Txtfv/b4zkbfKgzdhumxDBM/eSf3xmWuBinst8r3qzcWZ5qXDC6iX
 AogwNsCTsU/A1o8lWUJZ+aNNYe5LEz1vp/5jifBg9itzMwHyp5/38kc
X-Developer-Key: i=sarath.ganapathiraju@oss.qualcomm.com; a=ed25519;
 pk=4p2FWGXM+F2sir13Lu5stw5aKX5trUymK/ttESvgxQg=
X-Endpoint-Received: by B4 Relay for sarath.ganapathiraju@oss.qualcomm.com/default with auth_id=870
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a binding for the Qualcomm LPASS VA CSR rate generator node that
exposes the lpass_heartbeat_pulse clock on Hawi.

The HeartBeat Pulse (also known as RateGen Pulse) synchronizes the
start of the DMAs and Codec Interfaces for the audio usecase and can
serve as a periodic wakeup source for the DSP.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>
---
 .../bindings/clock/qcom,hawi-lpass-va-csr.yaml     | 45 ++++++++++++++++++++++
 1 file changed, 45 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/qcom,hawi-lpass-va-csr.yaml b/Documentation/devicetree/bindings/clock/qcom,hawi-lpass-va-csr.yaml
new file mode 100644
index 000000000000..bd3554f5c99c
--- /dev/null
+++ b/Documentation/devicetree/bindings/clock/qcom,hawi-lpass-va-csr.yaml
@@ -0,0 +1,45 @@
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
+  The Hawi LPASS (Low Power Audio Subsystem) VA CSR block contains a
+  rate generator that produces a periodic HeartBeat Pulse, also known
+  as the RateGen Pulse. This pulse synchronizes the start of DMAs and
+  Codec Interfaces for audio usecases and can serve as a periodic wakeup
+  source for the DSP.
+
+properties:
+  compatible:
+    enum:
+      - qcom,hawi-lpass-va-csr
+
+  reg:
+    maxItems: 1
+    description: Address and size of the VA CSR register block.
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
+    clock-controller@7ee0000 {
+      compatible = "qcom,hawi-lpass-va-csr";
+      reg = <0x07ee0000 0xe000>;
+      #clock-cells = <0>;
+    };

-- 
2.34.1

