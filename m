From: David Heidelberg <david@ixit.cz>
Date: Fri, 25 Sep 2026 23:22:21 +0200
Subject: [PATCH v8 3/5] dt-bindings: input: touchscreen: st,stmfts:
 Introduce STM FTS5
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-stmfts5-v8-3-0fcf49e2c85f@ixit.cz>
References: <20260925-stmfts5-v8-0-0fcf49e2c85f@ixit.cz>
In-Reply-To: <20260925-stmfts5-v8-0-0fcf49e2c85f@ixit.cz>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Henrik Rydberg <rydberg@bitmath.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Petr Hodina <petr.hodina@protonmail.com>, linux-input@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzk@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2063; i=david@ixit.cz;
 h=from:subject:message-id; bh=vbynNCWfAo0HQ+BS1gbKGd/f9mQ/YKgvFg8G/NvxKsg=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqtuYM07qIN5wZpC1R+DMIeJx5PEEPnjxk5Rjy2
 wZCQqg459OJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCarbmDAAKCRBgAj/E00kg
 clNwD/9Lg7M9OCARmi4aw5U9dpXlYVqUYvudwR3TMnYeqDScSaOHLsGU+lwTYIWX6wH74/XBWKd
 FCknE6jXY/3B+FiZw6W+I37Jiodjcjur0NyfBXxsxonYFqIw+OLEvFQVlFbOrV87bVkSAL2rgk5
 47yu8PsjW1gEKEN2tD8TidDhaoR1yCyQDgzNuu9/lm+XcquvxZLVyCMpC6m9No0KmLyFt7bGVV0
 K9O15atUUdD/zS5SfgV/FjceTGs3tUl7lokiwmbMSWubQpiFfVd0Z+iIRpm1YNGS/UQv9IN6Cps
 ETw4xVODF5tAOFErJt2dxCId4lphugOnp2e9TJqabWjooxUC4MhP1UFSDBrIN73tpVCeG07/4eS
 9jqaqZrkjqiAJ3pnL+oPex4mjkok/jiKF8BBpKjuWqVx63fuXzMhozRIzaCn4CBB2kgk3BTyyFS
 0Q9uUxfmA+fu283l73DEUyycoJIY6rnpfab6ENUKcIMPvbvcXPFoySgzzoAjQwsEniaGSvIHDnz
 PJJejbnz4+4Vf57aV/cmCu93HbvGv9TAt0RXzNjq4cdyjGBkfxqIkYM9A3WT6vS2k7r7GZu061d
 On8XhHD8OCISpH8IkQDcd55CyR4SFbrasDUwTOddPXeNHBdGh6Ldlktl0D8X+V+gwsYa7Fi/bnL
 AKBl/iXIlCFpTeQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce more recent STM FTS5 touchscreen support.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../bindings/input/touchscreen/st,stmfts.yaml      | 22 ++++++++++++++++++----
 1 file changed, 18 insertions(+), 4 deletions(-)

diff --git a/Documentation/devicetree/bindings/input/touchscreen/st,stmfts.yaml b/Documentation/devicetree/bindings/input/touchscreen/st,stmfts.yaml
index 6eb1ad6582d82..3de4bc5cd3f78 100644
--- a/Documentation/devicetree/bindings/input/touchscreen/st,stmfts.yaml
+++ b/Documentation/devicetree/bindings/input/touchscreen/st,stmfts.yaml
@@ -9,22 +9,21 @@ title: ST-Microelectronics FingerTip touchscreen controller
 maintainers:
   - Krzysztof Kozlowski <krzk@kernel.org>
 
 description:
   The ST-Microelectronics FingerTip device provides a basic touchscreen
   functionality. Along with it the user can enable the touchkey which can work
   as a basic HOME and BACK key for phones.
 
-allOf:
-  - $ref: touchscreen.yaml#
-
 properties:
   compatible:
-    const: st,stmfts
+    enum:
+      - st,stmfts
+      - st,stmfts5
 
   reg:
     maxItems: 1
 
   avdd-supply:
     description: Analogic power supply
 
   interrupts:
@@ -35,27 +34,42 @@ properties:
 
   touch-key-connected:
     type: boolean
     description: The touchkey feature is connected
 
   vdd-supply:
     description: Power supply
 
+  mode-switch-gpios:
+    description: Optional switch between touchscreen SLPI and AP mode.
+    maxItems: 1
+
   reset-gpios:
     description: Reset GPIO (active-low)
     maxItems: 1
 
 required:
   - compatible
   - reg
   - avdd-supply
   - interrupts
   - vdd-supply
 
+allOf:
+  - $ref: touchscreen.yaml#
+  - if:
+      not:
+        properties:
+          compatible:
+            const: st,stmfts5
+    then:
+      properties:
+        mode-switch-gpios: false
+
 unevaluatedProperties: false
 
 examples:
   - |
     #include <dt-bindings/interrupt-controller/irq.h>
 
     i2c {
         #address-cells = <1>;

-- 
2.55.0

