From: Jian Hu <jian.hu@amlogic.com>
Date: Tue, 21 Apr 2026 16:17:41 +0800
Subject: [PATCH v3 1/4] dt-bindings: soc: amlogic: clk-measure: Add A1 and
 T7 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260421-clkmsr_a1_t7-v3-1-efc00b0f9e6b@amlogic.com>
References: <20260421-clkmsr_a1_t7-v3-0-efc00b0f9e6b@amlogic.com>
In-Reply-To: <20260421-clkmsr_a1_t7-v3-0-efc00b0f9e6b@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Jian Hu <jian.hu@amlogic.com>, Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776759517; l=925;
 i=jian.hu@amlogic.com; s=20260415; h=from:subject:message-id;
 bh=CgTT3MEiWBM2xyukC2as1xW5lCFjTJ74JkjsBhvGt3g=;
 b=feaATb50ETYIaEoFr1FWFcpa+a9f5SmprtuXNV8oZFl6Ut6k8o5at2vR/q0GwP7GGPOJcrzyD
 W5w//PdCZQYBdTUkMEGzPoBI2YD8xNshIcpKbmLmPlRbX7+2G+xWeH6
X-Developer-Key: i=jian.hu@amlogic.com; a=ed25519;
 pk=zHUE+rNtH9z+Sb8au1/elWknjFQmy5QDVkBoxleuOIA=
X-Endpoint-Received: by B4 Relay for jian.hu@amlogic.com/20260415 with auth_id=735
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the Amlogic A1 and T7 compatible for the clk-measurer IP.

Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Jian Hu <jian.hu@amlogic.com>
---
 .../devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml   | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml b/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml
index 39d4637c2d08..b1200e6940ac 100644
--- a/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml
+++ b/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml
@@ -24,6 +24,8 @@ properties:
       - amlogic,meson-sm1-clk-measure
       - amlogic,c3-clk-measure
       - amlogic,s4-clk-measure
+      - amlogic,a1-clk-measure
+      - amlogic,t7-clk-measure
 
   reg:
     maxItems: 1

-- 
2.47.1

