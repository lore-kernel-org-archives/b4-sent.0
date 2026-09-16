From: Roman Vivchar <rva333@protonmail.com>
Date: Wed, 16 Sep 2026 14:42:35 +0300
Subject: [PATCH] dt-bindings: iio: adc: mediatek,mt2701-auxadc: add mt6572
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260916-6572-dt-auxadc-v1-1-e8190d614c33@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMMQ6DMAxA0asgz1gKJk0RV0EMIXFadwCUAEJC3
 J1Axzf8f0DiKJygLQ6IvEmSacyoygLc144fRvHZQIqMaiqN5vUm9AvadbfeIRsfSNmhJt1Ajub
 IQfZn2PV/p3X4sVvuC5znBTiodohyAAAA
X-Change-ID: 20260814-6572-dt-auxadc-e6df20ab3248
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Zhiyong Tao <zhiyong.tao@mediatek.com>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789558977; l=1058;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=RZDlKUe7DkcNemzM8RoN8vGwJ99E8wZHTiCH/d1P1qc=;
 b=sAqCN+D1D/bp0wpWn6DIoDT5q9AaznJfEIUcDQ7I9fdG5FPPYC5pfDjIC9wSL6V3bOBTnmb/7
 hqK+o78k6yxDozFO2zoTZfpaH3rmXvvXlR9HVzsEf2JetXl9yHjHDHS
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a compatible string for the mt6572 AUXADC, that is compatible with
mt8173 IP.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 Documentation/devicetree/bindings/iio/adc/mediatek,mt2701-auxadc.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/iio/adc/mediatek,mt2701-auxadc.yaml b/Documentation/devicetree/bindings/iio/adc/mediatek,mt2701-auxadc.yaml
index d9e825e5054f..750e1e837fb8 100644
--- a/Documentation/devicetree/bindings/iio/adc/mediatek,mt2701-auxadc.yaml
+++ b/Documentation/devicetree/bindings/iio/adc/mediatek,mt2701-auxadc.yaml
@@ -38,6 +38,7 @@ properties:
           - const: mediatek,mt7986-auxadc
       - items:
           - enum:
+              - mediatek,mt6572-auxadc
               - mediatek,mt6893-auxadc
               - mediatek,mt8183-auxadc
               - mediatek,mt8186-auxadc

---
base-commit: 8cd9520d35a6c38db6567e97dd93b1f11f185dc6
change-id: 20260814-6572-dt-auxadc-e6df20ab3248

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

