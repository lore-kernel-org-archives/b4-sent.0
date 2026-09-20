From: Chuan Liu <chuan.liu@amlogic.com>
Date: Sun, 20 Sep 2026 18:25:04 +0800
Subject: [PATCH v2 02/12] dt-bindings: soc: amlogic: Add clk-measure
 compatible to support more SoCs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260920-more-socs-to-support-clk_measure-v2-2-224382a429e8@amlogic.com>
References: <20260920-more-socs-to-support-clk_measure-v2-0-224382a429e8@amlogic.com>
In-Reply-To: <20260920-more-socs-to-support-clk_measure-v2-0-224382a429e8@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789899904; l=1482;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=iFtxCfNyNxPARsbwj859QUiks8NB1PYnjftvkWk6O4w=;
 b=n+6DE+7fBlM1JfnSWqS5Se1LkQPL36RhfgtOAcoBHnGLrTW7Iubv5I5sLFdtZKHw4/BYAuJkL
 h5L30EO/EkFDy2zhjuXgKE0FEd1sPAnCwt8S/HXIhNrILGG0/EPhoZC
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add clk-measure compatible for amlogic A5, A4, S7, S7D, S6 and A9 SoCs.

Although the clk-measure IP itself has little hardware difference across
SoCs, the clock inputs connected to the clk-measure block vary between
SoCs. Therefore, it is difficult to fall back to the configuration used
by previous SoCs.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 .../bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml          | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml b/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml
index ad37eca48103..16893f427532 100644
--- a/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml
+++ b/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml
@@ -17,6 +17,9 @@ properties:
   compatible:
     enum:
       - amlogic,a1-clk-measure
+      - amlogic,a4-clk-measure
+      - amlogic,a5-clk-measure
+      - amlogic,a9-clk-measure
       - amlogic,c3-clk-measure
       - amlogic,meson-axg-clk-measure
       - amlogic,meson-g12a-clk-measure
@@ -25,6 +28,9 @@ properties:
       - amlogic,meson8-clk-measure
       - amlogic,meson8b-clk-measure
       - amlogic,s4-clk-measure
+      - amlogic,s6-clk-measure
+      - amlogic,s7-clk-measure
+      - amlogic,s7d-clk-measure
       - amlogic,t7-clk-measure
 
   reg:

-- 
2.42.0

