From: Yang Xiwen <forbidden405@outlook.com>
Date: Sat, 17 Feb 2024 05:02:32 +0800
Subject: [PATCH v3 4/4] dt-bindings: mmc: hisilicon,hi3798cv200-dw-mshc:
 rename to hisilicon,hi3798-dw-mshc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240217-b4-mmc-hi3798mv200-v3-4-f15464176947@outlook.com>
References: <20240217-b4-mmc-hi3798mv200-v3-0-f15464176947@outlook.com>
In-Reply-To: <20240217-b4-mmc-hi3798mv200-v3-0-f15464176947@outlook.com>
To: Ulf Hansson <ulf.hansson@linaro.org>, 
 Jaehoon Chung <jh80.chung@samsung.com>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Igor Opaniuk <igor.opaniuk@linaro.org>, 
 tianshuliang <tianshuliang@hisilicon.com>, David Yang <mmyangfl@gmail.com>, 
 linux-kernel@vger.kernel.org, linux-mmc@vger.kernel.org, 
 devicetree@vger.kernel.org, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708117349; l=2257;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=4kflwEv+WJmP2PPOQXUMuL9kHf3tVBCROKzZLHhxoCg=;
 b=De+GKfRljIWbAimat2RWpwDanhxiSTNmKJ/2FK/BfGDLvIyapvRs6Ka9et6HFD8QKfOqhoi1p
 YEL4HsJRGaJDvGo93lsCAaT86slCgcRumVlLqwlyYeFC/5ZuUgMpLKI
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add binding and an extra property for Hi3798MV200 DWMMC specific extension.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 ...-dw-mshc.yaml => hisilicon,hi3798-dw-mshc.yaml} | 23 ++++++++++++++++++++--
 1 file changed, 21 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/mmc/hisilicon,hi3798cv200-dw-mshc.yaml b/Documentation/devicetree/bindings/mmc/hisilicon,hi3798-dw-mshc.yaml
similarity index 73%
rename from Documentation/devicetree/bindings/mmc/hisilicon,hi3798cv200-dw-mshc.yaml
rename to Documentation/devicetree/bindings/mmc/hisilicon,hi3798-dw-mshc.yaml
index f3dc973cb490..26d7f4be965b 100644
--- a/Documentation/devicetree/bindings/mmc/hisilicon,hi3798cv200-dw-mshc.yaml
+++ b/Documentation/devicetree/bindings/mmc/hisilicon,hi3798-dw-mshc.yaml
@@ -1,10 +1,10 @@
 # SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
 %YAML 1.2
 ---
-$id: http://devicetree.org/schemas/mmc/hisilicon,hi3798cv200-dw-mshc.yaml#
+$id: http://devicetree.org/schemas/mmc/hisilicon,hi3798-dw-mshc.yaml#
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
@@ -34,6 +35,12 @@ properties:
       - const: ciu-sample
       - const: ciu-drive
 
+  hisilicon,sap-dll-reg:
+    $ref: /schemas/types.yaml#/definitions/phandle
+    description:
+      A phandle points to the sample delay-locked-loop(DLL)
+      syscon node, used for tuning.
+
 required:
   - compatible
   - reg
@@ -44,6 +51,18 @@ required:
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

