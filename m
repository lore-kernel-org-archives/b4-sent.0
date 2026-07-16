From: Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>
Date: Fri, 17 Jul 2026 01:21:15 +0530
Subject: [PATCH v2 1/3] ASoC: dt-bindings: qcom,lpass-va-csr: Add HeartBeat
 pulse clock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260717-master-v2-1-ae200627ad62@oss.qualcomm.com>
References: <20260717-master-v2-0-ae200627ad62@oss.qualcomm.com>
In-Reply-To: <20260717-master-v2-0-ae200627ad62@oss.qualcomm.com>
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>
Cc: Srinivas Kandagatla <srinivas.kandagatla@oss.qualcomm.com>, 
 linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 prasad.kumpatla@oss.qualcomm.com, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784231493; l=2245;
 i=sarath.ganapathiraju@oss.qualcomm.com; s=default;
 h=from:subject:message-id; bh=T7zITenaLQ9Lrl6goebTesyTMddGvt+a0ZHdbi6L3fU=;
 b=FV3jm2e+mCBnFDWB8NR67V8GBPxEM1HNiCySFYpUWUd90ENy/Gnt1/ZMbvoBjOrRLUZdkL8D1
 iJRUnE1h7O/BcQnGGNnuZyaL+eHRoADGR+o7TyqDiF/qRc5E0xBNc2F
X-Developer-Key: i=sarath.ganapathiraju@oss.qualcomm.com; a=ed25519;
 pk=4p2FWGXM+F2sir13Lu5stw5aKX5trUymK/ttESvgxQg=
X-Endpoint-Received: by B4 Relay for sarath.ganapathiraju@oss.qualcomm.com/default with auth_id=870
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Qualcomm LPASS VA CSR rate generator node that exposes
the lpass_heartbeat_pulse clock on hawi.

The HeartBeat Pulse (also known as RateGen Pulse) synchronizes the
start of the DMAs and Codec Interfaces for the audio usecase
and can serve as a periodic wakeup source for the DSP.

Signed-off-by: Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>
---
 .../bindings/sound/qcom,lpass-va-csr.yaml          | 52 ++++++++++++++++++++++
 1 file changed, 52 insertions(+)

diff --git a/Documentation/devicetree/bindings/sound/qcom,lpass-va-csr.yaml b/Documentation/devicetree/bindings/sound/qcom,lpass-va-csr.yaml
new file mode 100644
index 0000000000..131debb04f
--- /dev/null
+++ b/Documentation/devicetree/bindings/sound/qcom,lpass-va-csr.yaml
@@ -0,0 +1,52 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/sound/qcom,lpass-va-csr.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Qualcomm LPASS VA CSR heartbeat pulse clock provider
+
+maintainers:
+  - Srinivas Kandagatla <srinivas.kandagatla@oss.qualcomm.com>
+  - Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>
+
+description:
+  The LPASS VA CSR block contains the rate generator hardware which
+  produces the heartbeatpulse consumed by the Bolero codec macros
+  (rx, tx, wsa, va). It is modelled as a clock provider
+  so consumers can reference it by name in their clocks list.
+
+properties:
+  compatible:
+    enum:
+      - qcom,hawi-lpass-va-csr
+
+  reg:
+    maxItems: 1
+    description: Must cover the full VA CSR block (base 0x7EE0000, size 0xE000).
+
+  "#clock-cells":
+    const: 0
+    description:
+      Single clock output "lpass_heartbeat_pulse". Consumers reference
+      it by clock-name "heartbeatpulse" in their clocks list.
+
+required:
+  - compatible
+  - reg
+  - "#clock-cells"
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    soc {
+      #address-cells = <2>;
+      #size-cells = <2>;
+
+      va-csr@7ee0000 {
+        compatible = "qcom,hawi-lpass-va-csr";
+        reg = <0x0 0x07ee0000 0x0 0xe000>;
+        #clock-cells = <0>;
+      };
+    };

-- 
2.34.1

