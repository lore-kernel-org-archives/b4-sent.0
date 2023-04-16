From: Yang Xiwen <forbidden405@outlook.com>
Date: Sun, 16 Apr 2023 17:19:35 +0800
Subject: [PATCH RFC v4 4/4] dt-binding: mmc: histb-dw-mshc: Add Hi3798MV200
 compatible string
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230415-mmc-hi3798mv200-v4-4-44096e187f53@outlook.com>
References: <20230415-mmc-hi3798mv200-v4-0-44096e187f53@outlook.com>
In-Reply-To: <20230415-mmc-hi3798mv200-v4-0-44096e187f53@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1681636790; l=1593;
 i=forbidden405@outlook.com; s=20230415; h=from:subject:message-id;
 bh=q5GM8oNU5gnf/3ltWXbVzjwL+8fph3xf831mMOi9Dsk=;
 b=sASercxLEOoqglzvstfLuHzFGTm0s2nnT7EchZrLhr0uqiVFQtjGG7XcIeJv5rRi3L1U/BsYD
 tfTt3eSo7jVCeEF2xxPbI4r0dOamp2qh3J6pn8dSgtN7kgqRkkfOy0M
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=hfdpPU3AXR+t7fdv58tXCD4UzRNq+fop2TMJezFlAhM=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230415 with auth_id=44
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Hi3798MV200 compatible string and an extra clock for it.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 .../bindings/mmc/hisilicon,histb-dw-mshc.yaml      | 26 +++++++++++++++++++++-
 1 file changed, 25 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/mmc/hisilicon,histb-dw-mshc.yaml b/Documentation/devicetree/bindings/mmc/hisilicon,histb-dw-mshc.yaml
index 301b6ad39c5af..2f8335fd2c965 100644
--- a/Documentation/devicetree/bindings/mmc/hisilicon,histb-dw-mshc.yaml
+++ b/Documentation/devicetree/bindings/mmc/hisilicon,histb-dw-mshc.yaml
@@ -19,6 +19,7 @@ properties:
   compatible:
     enum:
       - hisilicon,hi3798cv200-dw-mshc
+      - hisilicon,hi3798mv200-dw-mshc
 
   reg:
     maxItems: 1
@@ -27,14 +28,16 @@ properties:
     maxItems: 1
 
   clocks:
-    maxItems: 4
+    maxItems: 5
 
   clock-names:
+    minItems: 4
     items:
       - const: ciu
       - const: biu
       - const: ciu-sample
       - const: ciu-drive
+      - const: sap-dll-mode
 
 required:
   - compatible
@@ -45,6 +48,27 @@ required:
 
 allOf:
   - $ref: synopsys-dw-mshc-common.yaml#
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: hisilicon,hi3798mv200-dw-mshc
+
+    then:
+      properties:
+        clocks:
+          minItems: 5
+
+        clock-names:
+          minItems: 5
+
+    else:
+      properties:
+        clocks:
+          maxItems: 4
+
+        clock-names:
+          maxItems: 4
 
 unevaluatedProperties: false
 

-- 
2.39.2

