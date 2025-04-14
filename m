From: Chuan Liu <chuan.liu@amlogic.com>
Date: Mon, 14 Apr 2025 18:12:29 +0800
Subject: [PATCH v2 2/7] dt-bindings: soc: amlogic: C3 supports clk-measure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250414-clk-measure-v2-2-65077690053a@amlogic.com>
References: <20250414-clk-measure-v2-0-65077690053a@amlogic.com>
In-Reply-To: <20250414-clk-measure-v2-0-65077690053a@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744625573; l=875;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=P5KRner9ELHl3o409yiGCGnkva5HFExJ3rMn3+oG1ko=;
 b=OBeqwNSfKlp1ikH78aflX1hMLwcMKPmgvjsG+/sH9hULhjziPbD6BrLZo0QJOtrtPHjP37N20
 1aTJ/JXfGobCpPe30pfYUiyMIXlkVgDOZFfw9ZKJEiaGMjYHVHX5Qd2
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

C3 adds support for clk-measure.

Acked-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 .../devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml    | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml b/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml
index 77c281153010..275afe7fe374 100644
--- a/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml
+++ b/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml
@@ -22,6 +22,7 @@ properties:
       - amlogic,meson-axg-clk-measure
       - amlogic,meson-g12a-clk-measure
       - amlogic,meson-sm1-clk-measure
+      - amlogic,c3-clk-measure
 
   reg:
     maxItems: 1

-- 
2.42.0

