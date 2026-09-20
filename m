From: Chuan Liu <chuan.liu@amlogic.com>
Date: Sun, 20 Sep 2026 18:25:03 +0800
Subject: [PATCH v2 01/12] dt-bindings: soc: amlogic: Reordering compatible
 of clk-measure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260920-more-socs-to-support-clk_measure-v2-1-224382a429e8@amlogic.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789899904; l=1310;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=E0ttr7BdgbtQoJSGx2q0pEoA5GFoRJFe8UYzVUUxKY4=;
 b=P2i287sc1mgc4lPTdd06RMlJr9FfbF4fhs8o4EjiAUr3kwToKdHP4NN3mEdjraRBDKiYqe92J
 zbwSMbpBTT5Cw/jjHXY3BIz5oWYurNquUHm/74pS7Jnuroe6pZD4KbZ
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sort the compatible properties defined by clk-measure in alphabetical
order.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 .../bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml     | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)

diff --git a/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml b/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml
index b1200e6940ac..ad37eca48103 100644
--- a/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml
+++ b/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml
@@ -16,15 +16,15 @@ maintainers:
 properties:
   compatible:
     enum:
-      - amlogic,meson-gx-clk-measure
-      - amlogic,meson8-clk-measure
-      - amlogic,meson8b-clk-measure
+      - amlogic,a1-clk-measure
+      - amlogic,c3-clk-measure
       - amlogic,meson-axg-clk-measure
       - amlogic,meson-g12a-clk-measure
+      - amlogic,meson-gx-clk-measure
       - amlogic,meson-sm1-clk-measure
-      - amlogic,c3-clk-measure
+      - amlogic,meson8-clk-measure
+      - amlogic,meson8b-clk-measure
       - amlogic,s4-clk-measure
-      - amlogic,a1-clk-measure
       - amlogic,t7-clk-measure
 
   reg:

-- 
2.42.0

