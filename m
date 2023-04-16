From: Yang Xiwen <forbidden405@outlook.com>
Date: Sun, 16 Apr 2023 16:46:02 +0800
Subject: [PATCH RFC v3 4/4] dt-binding: mmc: histb-dw-mshc: Add Hi3798MV200
 compatible string
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230415-mmc-hi3798mv200-v3-4-00e2368c0709@outlook.com>
References: <20230415-mmc-hi3798mv200-v3-0-00e2368c0709@outlook.com>
In-Reply-To: <20230415-mmc-hi3798mv200-v3-0-00e2368c0709@outlook.com>
To: Ulf Hansson <ulf.hansson@linaro.org>, 
 Jaehoon Chung <jh80.chung@samsung.com>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Yang Xiwen <forbidden405@outlook.com>
Cc: tianshuliang <tianshuliang@hisilicon.com>, 
 Jiancheng Xue <xuejiancheng@hisilicon.com>, 
 Shawn Guo <shawn.guo@linaro.org>, David Yang <mmyangfl@gmail.com>, 
 linux-mmc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1681634825; l=1381;
 i=forbidden405@outlook.com; s=20230415; h=from:subject:message-id;
 bh=DChNXTsR5GdTAljXgm4pZiZ+L6iJZkFwTbHaR8G7CCs=;
 b=cuUE0RIRK/e2Gjbkq1dM5lB6Bv4YLFUYjY64ZF9NFtIvDFaT730d5GuJMXA8yTcQ51bpXfdCd
 wyE36bSoLPpA6Bxg9v/nKCcBd5zTMPr9TYZy8VXE3kA0GqY8zcwQv3k
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=hfdpPU3AXR+t7fdv58tXCD4UzRNq+fop2TMJezFlAhM=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230415 with auth_id=44
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Hi3798MV200 compatible string and an extra clock for it.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 Documentation/devicetree/bindings/mmc/histb-dw-mshc.yaml | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/Documentation/devicetree/bindings/mmc/histb-dw-mshc.yaml b/Documentation/devicetree/bindings/mmc/histb-dw-mshc.yaml
index 4711ad293b9e8..bcc8ea393981f 100644
--- a/Documentation/devicetree/bindings/mmc/histb-dw-mshc.yaml
+++ b/Documentation/devicetree/bindings/mmc/histb-dw-mshc.yaml
@@ -19,6 +19,7 @@ properties:
   compatible:
     enum:
       - hisilicon,hi3798cv200-dw-mshc
+      - hisilicon,hi3798mv200-dw-mshc
 
   reg:
     maxItems: 1
@@ -28,13 +29,16 @@ properties:
 
   clocks:
     minItems: 4
+    maxItems: 5
 
   clock-names:
+    minItems: 4
     items:
       - const: ciu
       - const: biu
       - const: ciu-sample
       - const: ciu-drive
+      - const: sap-dll-mode
 
 unevaluatedProperties: false
 
@@ -47,6 +51,18 @@ required:
 
 allOf:
   - $ref: synopsys-dw-mshc-common.yaml#
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: hisilicon,hi3798mv200-dw-mshc
+    then:
+      properties:
+        clocks:
+          minItems: 5
+
+        clock-names:
+          minItems: 5
 
 examples:
   - |

-- 
2.39.2

