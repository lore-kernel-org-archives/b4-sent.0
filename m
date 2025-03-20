From: Kelvin Zhang <kelvin.zhang@amlogic.com>
Date: Thu, 20 Mar 2025 17:42:08 +0800
Subject: [PATCH v5 1/3] dt-bindings: reset: Add compatible for Amlogic
 A4/A5 Reset Controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250320-a4-a5-reset-v5-1-296f83bf733d@amlogic.com>
References: <20250320-a4-a5-reset-v5-0-296f83bf733d@amlogic.com>
In-Reply-To: <20250320-a4-a5-reset-v5-0-296f83bf733d@amlogic.com>
To: Philipp Zabel <p.zabel@pengutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Zelong Dong <zelong.dong@amlogic.com>, 
 Conor Dooley <conor.dooley@microchip.com>, 
 Kelvin Zhang <kelvin.zhang@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742463756; l=2254;
 i=kelvin.zhang@amlogic.com; s=20240329; h=from:subject:message-id;
 bh=RBPG6lp45fxsEDVQ6Y1mIySEYTUUWfsM6OujOhVw3vA=;
 b=1iO6XQAAFeNeL4r0duOu23ksrBakwUJYF2Vj+z4zoFgsQqeIlbRVKMe2xVZqS+g5rZ/CT0RwJ
 0Xv7AQBqwweD0XX5PoEdJjlX9ggKLsGYWz7wIL7duhKXRJ8hXNgC1wO
X-Developer-Key: i=kelvin.zhang@amlogic.com; a=ed25519;
 pk=pgnle7HTNvnNTcOoGejvtTC7BJT30HUNXfMHRRXSylI=
X-Endpoint-Received: by B4 Relay for kelvin.zhang@amlogic.com/20240329 with auth_id=148
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Zelong Dong <zelong.dong@amlogic.com>

Add compatibles for Amlogic A4 and A5 reset controllers,
which fall back to 'amlogic,meson-s4-reset'.

Signed-off-by: Zelong Dong <zelong.dong@amlogic.com>
Acked-by: Conor Dooley <conor.dooley@microchip.com>
Acked-by: Philipp Zabel <p.zabel@pengutronix.de>
Link: https://lore.kernel.org/r/20240918074211.8067-2-zelong.dong@amlogic.com
Signed-off-by: Kelvin Zhang <kelvin.zhang@amlogic.com>
---
 .../bindings/reset/amlogic,meson-reset.yaml        | 22 ++++++++++++++--------
 1 file changed, 14 insertions(+), 8 deletions(-)

diff --git a/Documentation/devicetree/bindings/reset/amlogic,meson-reset.yaml b/Documentation/devicetree/bindings/reset/amlogic,meson-reset.yaml
index 695ef38a7bb346c92b4cf428e7615d45682c940a..150e95c0d9bed74c7045942610a311114a257889 100644
--- a/Documentation/devicetree/bindings/reset/amlogic,meson-reset.yaml
+++ b/Documentation/devicetree/bindings/reset/amlogic,meson-reset.yaml
@@ -12,14 +12,20 @@ maintainers:
 
 properties:
   compatible:
-    enum:
-      - amlogic,meson8b-reset # Reset Controller on Meson8b and compatible SoCs
-      - amlogic,meson-gxbb-reset # Reset Controller on GXBB and compatible SoCs
-      - amlogic,meson-axg-reset # Reset Controller on AXG and compatible SoCs
-      - amlogic,meson-a1-reset # Reset Controller on A1 and compatible SoCs
-      - amlogic,meson-s4-reset # Reset Controller on S4 and compatible SoCs
-      - amlogic,c3-reset # Reset Controller on C3 and compatible SoCs
-      - amlogic,t7-reset
+    oneOf:
+      - enum:
+          - amlogic,meson8b-reset # Reset Controller on Meson8b and compatible SoCs
+          - amlogic,meson-gxbb-reset # Reset Controller on GXBB and compatible SoCs
+          - amlogic,meson-axg-reset # Reset Controller on AXG and compatible SoCs
+          - amlogic,meson-a1-reset # Reset Controller on A1 and compatible SoCs
+          - amlogic,meson-s4-reset # Reset Controller on S4 and compatible SoCs
+          - amlogic,c3-reset # Reset Controller on C3 and compatible SoCs
+          - amlogic,t7-reset
+      - items:
+          - enum:
+              - amlogic,a4-reset
+              - amlogic,a5-reset
+          - const: amlogic,meson-s4-reset
 
   reg:
     maxItems: 1

-- 
2.37.1

