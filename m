From: Yang Xiwen <forbidden405@outlook.com>
Date: Tue, 20 Feb 2024 03:34:16 +0800
Subject: [PATCH v5 5/5] dt-bindings: mmc: hisilicon,hi3798cv200-dw-mshc:
 add Hi3798MV200 binding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240220-b4-mmc-hi3798mv200-v5-5-f506c55f8e43@outlook.com>
References: <20240220-b4-mmc-hi3798mv200-v5-0-f506c55f8e43@outlook.com>
In-Reply-To: <20240220-b4-mmc-hi3798mv200-v5-0-f506c55f8e43@outlook.com>
To: Ulf Hansson <ulf.hansson@linaro.org>, 
 Jaehoon Chung <jh80.chung@samsung.com>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Igor Opaniuk <igor.opaniuk@linaro.org>, 
 tianshuliang <tianshuliang@hisilicon.com>, David Yang <mmyangfl@gmail.com>, 
 linux-kernel@vger.kernel.org, linux-mmc@vger.kernel.org, 
 devicetree@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708371252; l=2176;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=81ECSc1YzJgi6TVlBpCQAnGtw6DZilzIAOBsgMBQcb8=;
 b=++/uUq9V+SUxuC4pFVSCQq7u5QQ8lqaMQLhj6KrnmbC5zg5Gq4/WCOeMsEnVVwzhCQhd7ACzU
 xDAtwZQT/DSC2DeFWIUgBQDnK1axjUOGbyidAcWbImgSQIFXcYBNw7A
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add binding and an extra property for Hi3798MV200 DWMMC specific extension.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 .../mmc/hisilicon,hi3798cv200-dw-mshc.yaml         | 24 +++++++++++++++++++++-
 1 file changed, 23 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/mmc/hisilicon,hi3798cv200-dw-mshc.yaml b/Documentation/devicetree/bindings/mmc/hisilicon,hi3798cv200-dw-mshc.yaml
index f3dc973cb490..41c9b22523e7 100644
--- a/Documentation/devicetree/bindings/mmc/hisilicon,hi3798cv200-dw-mshc.yaml
+++ b/Documentation/devicetree/bindings/mmc/hisilicon,hi3798cv200-dw-mshc.yaml
@@ -4,7 +4,7 @@
 $id: http://devicetree.org/schemas/mmc/hisilicon,hi3798cv200-dw-mshc.yaml#
 $schema: http://devicetree.org/meta-schemas/core.yaml#
 
-title: Hisilicon Hi3798CV200 SoC specific extensions to the Synopsys DWMMC controller
+title: Hisilicon HiSTB SoCs specific extensions to the Synopsys DWMMC controller
 
 maintainers:
   - Yang Xiwen <forbidden405@outlook.com>
@@ -13,6 +13,7 @@ properties:
   compatible:
     enum:
       - hisilicon,hi3798cv200-dw-mshc
+      - hisilicon,hi3798mv200-dw-mshc
 
   reg:
     maxItems: 1
@@ -34,6 +35,15 @@ properties:
       - const: ciu-sample
       - const: ciu-drive
 
+  hisilicon,sap-dll-reg:
+    $ref: /schemas/types.yaml#/definitions/phandle-array
+    description: |
+      DWMMC core on Hi3798MV2x SoCs has a delay-locked-loop(DLL) attached to card data input path.
+      It is integrated into CRG core on the SoC and has to be controlled during tuning.
+    items:
+      - description: A phandle pointed to the CRG syscon node
+      - description: Sample DLL register offset in CRG address space
+
 required:
   - compatible
   - reg
@@ -44,6 +54,18 @@ required:
 allOf:
   - $ref: synopsys-dw-mshc-common.yaml#
 
+  - if:
+      properties:
+        compatible:
+          contains:
+            const: hisilicon,hi3798mv200-dw-mshc
+    then:
+      required:
+        - hisilicon,sap-dll-reg
+    else:
+      properties:
+        hisilicon,sap-dll-reg: false
+
 unevaluatedProperties: false
 
 examples:

-- 
2.43.0

