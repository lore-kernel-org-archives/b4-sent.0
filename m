From: Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>
Date: Thu, 17 Sep 2026 19:27:14 +0530
Subject: [PATCH v8 1/2] dt-bindings: clock: qcom: Add LPASS VA CSR
 HeartBeat pulse clock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260917-master-v8-1-823d2c5d090a@oss.qualcomm.com>
References: <20260917-master-v8-0-823d2c5d090a@oss.qualcomm.com>
In-Reply-To: <20260917-master-v8-0-823d2c5d090a@oss.qualcomm.com>
To: andersson@kernel.org, abelvesa@kernel.org, sboyd@kernel.org, 
 bmasney+clk@redhat.com, jbrunet+clk@baylibre.com, robh@kernel.org, 
 krzk+dt@kernel.org, conor+dt@kernel.org, 
 srinivas.kandagatla@oss.qualcomm.com, sarath.ganapathiraju@oss.qualcomm.com
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 prasad.kumpatla@oss.qualcomm.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789653433; l=2671;
 i=sarath.ganapathiraju@oss.qualcomm.com; s=default;
 h=from:subject:message-id; bh=EqcShn4lKqnUcEIX4DZ2sa+EOeN9w3AEP1mmSm22Vj0=;
 b=VKw2hZ78nx0j2JO6QW+kYYGhECDAl5STY63kC6Hw2t3N0TiujyUA5kClKMxPJX1TK5h+XN8PZ
 dUNtvbjIamhBVKEWQcImhCa6zTsv1Uw1e/J5s+ueDgA2oxlqq7DjNoU
X-Developer-Key: i=sarath.ganapathiraju@oss.qualcomm.com; a=ed25519;
 pk=4p2FWGXM+F2sir13Lu5stw5aKX5trUymK/ttESvgxQg=
X-Endpoint-Received: by B4 Relay for sarath.ganapathiraju@oss.qualcomm.com/default with auth_id=870
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a binding for the Qualcomm LPASS VA CSR rate generator node that
exposes the lpass_heartbeat_pulse clock on Hawi.

The HeartBeat Pulse, also known as RateGen Pulse, synchronizes the
start of DMAs and Codec Interfaces for the audio usecase and can serve
as a periodic wakeup source for the DSP.

Require the LPASS LPR and audio vote clocks to access VA CSR register
space safely.

Signed-off-by: Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>
---
 .../bindings/clock/qcom,hawi-lpass-va-csr.yaml     | 62 ++++++++++++++++++++++
 1 file changed, 62 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/qcom,hawi-lpass-va-csr.yaml b/Documentation/devicetree/bindings/clock/qcom,hawi-lpass-va-csr.yaml
new file mode 100644
index 000000000000..601da83add2b
--- /dev/null
+++ b/Documentation/devicetree/bindings/clock/qcom,hawi-lpass-va-csr.yaml
@@ -0,0 +1,62 @@
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
+  clocks:
+    items:
+      - description: LPASS LPR (Low Power Resource) voting clock
+      - description: LPASS Audio voting clock
+
+  clock-names:
+    items:
+      - const: lpr
+      - const: audio
+
+  "#clock-cells":
+    const: 0
+
+required:
+  - compatible
+  - reg
+  - clocks
+  - clock-names
+  - "#clock-cells"
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/sound/qcom,q6dsp-lpass-ports.h>
+
+    clock-controller@7ee0000 {
+      compatible = "qcom,hawi-lpass-va-csr";
+      reg = <0x07ee0000 0xe000>;
+      clocks = <&q6prmcc LPASS_HW_LPR_VOTE LPASS_CLK_ATTRIBUTE_COUPLE_NO>,
+               <&q6prmcc LPASS_HW_DCODEC_VOTE LPASS_CLK_ATTRIBUTE_COUPLE_NO>;
+      clock-names = "lpr", "audio";
+      #clock-cells = <0>;
+    };

-- 
2.34.1

