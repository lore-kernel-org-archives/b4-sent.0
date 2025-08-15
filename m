From: Chuan Liu <chuan.liu@amlogic.com>
Date: Fri, 15 Aug 2025 16:37:31 +0800
Subject: [PATCH 05/13] dt-bindings: soc: amlogic: Unify the compatible
 property for clk-measure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250815-add-more-socs-to-support-clk_measure-v1-5-59f04ba67457@amlogic.com>
References: <20250815-add-more-socs-to-support-clk_measure-v1-0-59f04ba67457@amlogic.com>
In-Reply-To: <20250815-add-more-socs-to-support-clk_measure-v1-0-59f04ba67457@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755247057; l=1771;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=WLsFB3kZYI5SRTtCiEJNIQMGbbEEbhu5OiVfqIrbRCU=;
 b=15BeFKwtMUW4Xf1NqNuNqnhEhMKHY/rAApALIEl3odOLL/43sqwREMcPMGqW3A7x/6AJvI4oR
 U3KLtA0rnWGCvCtUm3EXXlqWfXYYS9nC2B8xxigjirG1/dmavcx3I62
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The clk-measure IPs across Amlogic SoCs have minimal differences, so
they can be managed with a unified compatible property.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 .../bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml | 14 +++-----------
 1 file changed, 3 insertions(+), 11 deletions(-)

diff --git a/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml b/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml
index 1c9d37eef5f0..a7927acde2fe 100644
--- a/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml
+++ b/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml
@@ -15,15 +15,7 @@ maintainers:
 
 properties:
   compatible:
-    enum:
-      - amlogic,meson-gx-clk-measure
-      - amlogic,meson8-clk-measure
-      - amlogic,meson8b-clk-measure
-      - amlogic,meson-axg-clk-measure
-      - amlogic,meson-g12a-clk-measure
-      - amlogic,meson-sm1-clk-measure
-      - amlogic,c3-clk-measure
-      - amlogic,s4-clk-measure
+    const: amlogic,clk-measure
 
   reg:
     maxItems: 1
@@ -67,7 +59,7 @@ examples:
      * offsets.
      */
     clock-measure@8758 {
-        compatible = "amlogic,meson-gx-clk-measure";
+        compatible = "amlogic,clk-measure";
         reg = <0x8758 0x10>;
         clkmsr-indices = <0>,
                          <1>,
@@ -82,7 +74,7 @@ examples:
      * Example 2: clk-measure uses V2 version register address offsets.
      */
     clock-measure@48000 {
-        compatible = "amlogic,c3-clk-measure";
+        compatible = "amlogic,clk-measure";
         reg = <0x48000 0x1c>;
         clkmsr-reg-v2;
         clkmsr-indices = <0>,

-- 
2.42.0

