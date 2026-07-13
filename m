From: Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>
Date: Tue, 14 Jul 2026 01:35:32 +0530
Subject: [PATCH 1/2] ASoC: dt-bindings: qcom,lpass-va-csr: Add HeartBeat
 pulse clock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260714-master-v1-1-1ebe5993225e@oss.qualcomm.com>
References: <20260714-master-v1-0-1ebe5993225e@oss.qualcomm.com>
In-Reply-To: <20260714-master-v1-0-1ebe5993225e@oss.qualcomm.com>
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>
Cc: Srinivas Kandagatla <srinivas.kandagatla@oss.qualcomm.com>, 
 linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 prasad.kumpatla@oss.qualcomm.com, 
 Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783973132; l=3495;
 i=sarath.ganapathiraju@oss.qualcomm.com; s=default;
 h=from:subject:message-id; bh=RbD5mg4ILVqZOMn1H2IVY7wxyZAxnDGJwjZKThdsa64=;
 b=h3h+596bSMJnpGEJ84mEFcm+pQkY7CCeRfkm8dGQ24+MDwGMQ+Q1j/rhGLSiF1S6Ex07exWgr
 z3yrEBKvxqMASu4TBX0yutnTs3PWaOdG9ELJHnO5UzTRVgThETZXSpw
X-Developer-Key: i=sarath.ganapathiraju@oss.qualcomm.com; a=ed25519;
 pk=4p2FWGXM+F2sir13Lu5stw5aKX5trUymK/ttESvgxQg=
X-Endpoint-Received: by B4 Relay for sarath.ganapathiraju@oss.qualcomm.com/default with auth_id=870
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Qualcomm LPASS VA CSR rate generator node that exposes
the lpass_heartbeat_pulse clock on hawi. Also extend the
qcom,lpass-va-macro binding to add qcom,hawi-lpass-va-macro with
its four-clock constraint (mclk, macro, dcodec, heartbeatpulse).

The HeartBeat Pulse (also known as RateGen Pulse) synchronizes the
start of the DMAs and Codec Interfaces for the audio usecase
and can serve as a periodic wakeup source for the DSP.

Signed-off-by: Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>
---
 .../bindings/sound/qcom,lpass-va-csr.yaml          | 47 ++++++++++++++++++++++
 .../bindings/sound/qcom,lpass-va-macro.yaml        | 18 +++++++++
 2 files changed, 65 insertions(+)

diff --git a/Documentation/devicetree/bindings/sound/qcom,lpass-va-csr.yaml b/Documentation/devicetree/bindings/sound/qcom,lpass-va-csr.yaml
new file mode 100644
index 000000000..794da92ad
--- /dev/null
+++ b/Documentation/devicetree/bindings/sound/qcom,lpass-va-csr.yaml
@@ -0,0 +1,47 @@
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
+    va-csr@7ee0000 {
+      compatible = "qcom,hawi-lpass-va-csr";
+      reg = <0x0 0x07ee0000 0x0 0xe000>;
+      #clock-cells = <0>;
+    };
diff --git a/Documentation/devicetree/bindings/sound/qcom,lpass-va-macro.yaml b/Documentation/devicetree/bindings/sound/qcom,lpass-va-macro.yaml
index aea31fbda..ae4df8967 100644
--- a/Documentation/devicetree/bindings/sound/qcom,lpass-va-macro.yaml
+++ b/Documentation/devicetree/bindings/sound/qcom,lpass-va-macro.yaml
@@ -19,6 +19,7 @@ properties:
           - qcom,sm8450-lpass-va-macro
           - qcom,sm8550-lpass-va-macro
           - qcom,sc8280xp-lpass-va-macro
+          - qcom,hawi-lpass-va-macro
       - items:
           - enum:
               - qcom,eliza-lpass-va-macro
@@ -168,6 +169,23 @@ allOf:
             - const: macro
             - const: dcodec
 
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: qcom,hawi-lpass-va-macro
+    then:
+      properties:
+        clocks:
+          minItems: 4
+          maxItems: 4
+        clock-names:
+          items:
+            - const: mclk
+            - const: macro
+            - const: dcodec
+            - const: heartbeatpulse
+
 unevaluatedProperties: false
 
 examples:

-- 
2.34.1

