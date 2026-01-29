From: Aaron Kling <webgeek1234@gmail.com>
Date: Thu, 29 Jan 2026 01:46:30 -0600
Subject: [PATCH 1/3] dt-bindings: firmware: Add tz-log doc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260129-sm8550-abl-dtbo-v1-1-abca3be14024@gmail.com>
References: <20260129-sm8550-abl-dtbo-v1-0-abca3be14024@gmail.com>
In-Reply-To: <20260129-sm8550-abl-dtbo-v1-0-abca3be14024@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Kumar Sharma <quic_vksharma@quicinc.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>, 
 Kuldeep Singh <quic_kuldsing@quicinc.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769672821; l=2641;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=j4W6msnkMxX28xtcW8HkyUTEMXxzbIT7opeITn1uMGk=;
 b=PqAGvkhD9Zzy8UBReqL1jxcUtMVxygIkCcOIBcWYPM/8WiAI96j0BGWS5mdfpeMU45B2F2Eg/
 xz69tSs1LzcAvPgEMAylvdeQlGqqQMYaz3AqDk1LMJUX0b/h7X/HzOB
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Kuldeep Singh <quic_kuldsing@quicinc.com>

Add device-tree bindings for qcom tz-log. Exposes a debug
interface for accessing and displaying diagnostic information
related to secure code(Trustzone/QSEE).

Signed-off-by: Kuldeep Singh <quic_kuldsing@quicinc.com>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 .../devicetree/bindings/firmware/qcom,tz-log.yaml  | 66 ++++++++++++++++++++++
 1 file changed, 66 insertions(+)

diff --git a/Documentation/devicetree/bindings/firmware/qcom,tz-log.yaml b/Documentation/devicetree/bindings/firmware/qcom,tz-log.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..e5c67ca1546c2d10f4c3b5979bf7b8a1a7dd2132
--- /dev/null
+++ b/Documentation/devicetree/bindings/firmware/qcom,tz-log.yaml
@@ -0,0 +1,66 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/firmware/qcom,tz-log.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: TZLOG (Trust Zone log)
+
+maintainers:
+  - Vikas Kumar Sharma <quic_vksharma@quicinc.com>
+
+description:
+  This exposes a debug interface for accessing and displaying diagnostic information
+  related to secure code (Trustzone/QSEE).
+
+properties:
+  compatible:
+    const: qcom,tz-log
+
+  reg:
+    maxItems: 1
+
+  qcom,hyplog-enabled:
+    type: boolean
+    description: Indicates(boolean) if driver supports HYP logger service.
+
+  hyplog-address-offset:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description: Register offset to get the HYP log base address.
+
+  hyplog-size-offset:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description: Register offset to get the HYP log size parameter.
+
+  rmlog-address:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description: Register offset to get resource manager log base address.
+
+  rmlog-size:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description: Register offset to get the resource manager log size parameter.
+
+  tmecrashdump-address-offset:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description: Define tme crashump DDR region starting offset.
+
+required:
+  - compatible
+  - reg
+
+additionalProperties: false
+
+examples:
+  - |
+    soc {
+        #address-cells = <2>;
+        #size-cells = <2>;
+
+        qcom_tzlog: tz-log@146bf720 {
+            compatible = "qcom,tz-log";
+            reg = <0x0 0x146bf720 0x0 0x3000>;
+            qcom,hyplog-enabled;
+            hyplog-address-offset = <0x410>;
+            hyplog-size-offset = <0x414>;
+        };
+    };

-- 
2.52.0

