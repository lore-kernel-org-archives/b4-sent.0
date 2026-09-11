From: Chuan Liu <chuan.liu@amlogic.com>
Date: Fri, 11 Sep 2026 16:28:28 +0800
Subject: [PATCH 01/10] dt-bindings: soc: amlogic: Add compatible to support
 more SoCs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260911-more-socs-to-support-clk_measure-v1-1-940e269aa52f@amlogic.com>
References: <20260911-more-socs-to-support-clk_measure-v1-0-940e269aa52f@amlogic.com>
In-Reply-To: <20260911-more-socs-to-support-clk_measure-v1-0-940e269aa52f@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789115329; l=1253;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=cohyDpjVw0jD9doFV5tm/XEidv0ja/sUaS7qt5A3x+8=;
 b=+zRqxruOYTQd2GWbHMyhce6LqqsCixdgV8s7tFf1e7uXuhtRdOC4Qbns3oWiIJK2gcihR6bq4
 IhjH2to1X/2CqUefRZCrhxwbaNuxHIzjijPh9TGjnL5GH1DbkKXt/oJ
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
index b1200e6940ac..125be01e3b2c 100644
--- a/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml
+++ b/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml
@@ -26,6 +26,12 @@ properties:
       - amlogic,s4-clk-measure
       - amlogic,a1-clk-measure
       - amlogic,t7-clk-measure
+      - amlogic,a5-clk-measure
+      - amlogic,a4-clk-measure
+      - amlogic,s7-clk-measure
+      - amlogic,s7d-clk-measure
+      - amlogic,s6-clk-measure
+      - amlogic,a9-clk-measure
 
   reg:
     maxItems: 1

-- 
2.42.0

