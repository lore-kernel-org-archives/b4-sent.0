From: David Heidelberg <david@ixit.cz>
Date: Sun, 06 Sep 2026 02:41:12 +0200
Subject: [PATCH RFC 1/4] dt-bindings: soc: google: Add modemsmem
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-modemsmem-v1-1-a3634b553841@ixit.cz>
References: <20260906-modemsmem-v1-0-a3634b553841@ixit.cz>
In-Reply-To: <20260906-modemsmem-v1-0-a3634b553841@ixit.cz>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Richard Acayan <mailingradian@gmail.com>, Petr Vorel <petr.vorel@gmail.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1760; i=david@ixit.cz;
 h=from:subject:message-id; bh=vqaYf4qSxGlGwj04FourVUrqHojhUtgjS5zVQccHpxU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqnLavH8A1eT79EINjEArRKcRlMijgu1WDfsr/l
 PXO/RGsN6+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCapy2rwAKCRBgAj/E00kg
 cqEwEACaYUWLxuCN0WmfEkHeuzUtEYFxhSebcWiC3rAFJNtiTWEMJOpLJPvI2xSpMlWbaaVKQ/7
 4FBN4yDGqD9+zDP9zHQorsTu8V1IdIKthqOiRVFWnWLbiqwvDOsdr70QmaXcRxsNqOu5b89ZoDU
 2XarvvPy7itht6d1CyiRsMqCw36oNz6EhnoVUZMGqDrJjQC+m78k8/NfYSXo3feMKDetN9XBvp3
 tX5HGdaKQw869WQl9yMy/yB0FGJbTdDziArffSdKe+iImHEcQYilrk/IMYFNdIk7s735nrcHzFs
 KoUm0uHjcD32fIBcaucvw+rT6hcfS3qRRAo3ceDcfQ9ASGXOJBH19mj2Wmsc9pCFrVhOHDXeezT
 LeMPlYlLMnxmUHW0NyDzzsLWEIPhBB6NKUcrniRhG4U9aFbnJ3t+3TOSbkrWVQ/GpAz6oZmndnc
 y6tjkNS95T5ztKmtiElpD7hYI9hc4i2qaJ9fW0WPd1g4oabwFveYdYou3ViipzxObnsprMA8z9J
 4wdIY9yT8WqcJigRGPA4EL2Pk9TCVgIPs6WnOo8rwzwB10XGBUw7ClTPaXpPD/Aiuqbn+WFq/3a
 lHYXV1Y0yFFR5/wxI1stjh0AeVVcHNHYb8VHHAyrNcv4R+lSPNE2oVZxi66DdVmY5WyUgd9tK19
 BrBsfxiVhNgEQtQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The modem firmware on Google Pixel 3 - 5a devices expects the application
processor to publish SoC platform information in a vendor-defined SMEM
item before the modem boots.

Assisted-by: LLM
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../bindings/soc/google/google,modemsmem.yaml      | 39 ++++++++++++++++++++++
 1 file changed, 39 insertions(+)

diff --git a/Documentation/devicetree/bindings/soc/google/google,modemsmem.yaml b/Documentation/devicetree/bindings/soc/google/google,modemsmem.yaml
new file mode 100644
index 0000000000000..a5214a8093ba0
--- /dev/null
+++ b/Documentation/devicetree/bindings/soc/google/google,modemsmem.yaml
@@ -0,0 +1,39 @@
+# SPDX-License-Identifier: GPL-2.0-only
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/soc/google/google,modemsmem.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Google Modem Shared Memory
+
+maintainers:
+  - Richard Acayan <mailingradian@gmail.com>
+
+description:
+  The modem firmware on Google Pixel devices (Pixel 3 through Pixel 5a)
+  expects the application processor to publish SoC information (platform
+  type and revision) in a vendor-defined Qualcomm Shared Memory (SMEM)
+  item before the modem boots.
+
+properties:
+  compatible:
+    const: google,modemsmem
+
+  qcom,smem-id:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description:
+      Identifier of the SMEM item the SoC information is written to. Google
+      firmware uses the first vendor-reserved item.
+
+required:
+  - compatible
+  - qcom,smem-id
+
+additionalProperties: false
+
+examples:
+  - |
+    modemsmem {
+        compatible = "google,modemsmem";
+        qcom,smem-id = <134>;
+    };

-- 
2.55.0

