From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Sat, 28 Feb 2026 07:56:14 +0000
Subject: [PATCH v2 1/3] dt-bindings: arm: amlogic: add A311Y3 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260228-a9-baisc-dts-v2-1-47489d5cc1a8@amlogic.com>
References: <20260228-a9-baisc-dts-v2-0-47489d5cc1a8@amlogic.com>
In-Reply-To: <20260228-a9-baisc-dts-v2-0-47489d5cc1a8@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-serial@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772265409; l=1053;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=SsR9Sz9BWoMX3UnJeit5aTZNxRC651zrkqb0PjHBQcE=;
 b=k08vJ2okoMYlC+VuCctfB+kZ0JSYV4iwtRbRQFEyaS95ke3jOVuYpXYOqEZqJATMHxtJFju5J
 q5h+x/uY+KEAZZZpsxZHV0ui25r6INX4CzHLy6OVrvyoov1fhexElTe
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bindings for the Amlogic BY401 board, using A311Y3 Soc from
Amlogic A9 family chip.

Reviewed-by: Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 Documentation/devicetree/bindings/arm/amlogic.yaml | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/amlogic.yaml b/Documentation/devicetree/bindings/arm/amlogic.yaml
index a885278bc4e2..9f73a0054fb2 100644
--- a/Documentation/devicetree/bindings/arm/amlogic.yaml
+++ b/Documentation/devicetree/bindings/arm/amlogic.yaml
@@ -234,6 +234,12 @@ properties:
               - amlogic,av400
           - const: amlogic,a5
 
+      - description: Boards with the Amlogic A9 A311Y3 SoC
+        items:
+          - enum:
+              - amlogic,by401
+          - const: amlogic,a9
+
       - description: Boards with the Amlogic C3 C302X/C308L SoC
         items:
           - enum:

-- 
2.52.0

