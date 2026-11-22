From: Roman Vivchar <rva333@protonmail.com>
Date: Sun, 22 Nov 2026 19:15:45 +0200
Subject: [PATCH v3 4/7] dt-bindings: iio: light: stk33xx: add stk3337
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-6768-stk3337-v3-4-b0d0a924e843@protonmail.com>
References: <20261122-6768-stk3337-v3-0-b0d0a924e843@protonmail.com>
In-Reply-To: <20261122-6768-stk3337-v3-0-b0d0a924e843@protonmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Joshua Crofts <crofts@kernel.org>, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Roman Vivchar <rva333@protonmail.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795367795; l=1072;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=bt5ETDB3Lc22WDD7vf0JJgbped6LOiPrRoW1lAcWv50=;
 b=0WDtuzNZjWnjKK6DmzeqhK+FQHmHKw7Ftlt2Asidw0bOy+XJkrNafQlijdy2dbL/hwMYymrTc
 6E/+MjRZuszArud71xFJGke3sYtzdGNlEXAYoQwQnbuSUUeT8ob8+hF
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add compatible string for the stk3337 ALSPS sensor. Its core registers
are backwards compatible with the stk3310, while also providing a clear
light channel like the stk36c61, so document it with sensortek,stk3310
as a fallback.

Datasheet: https://www.bestmodulescorp.com/en/amfile/file/download/file/1699/product/1048/
Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 Documentation/devicetree/bindings/iio/light/stk33xx.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/iio/light/stk33xx.yaml b/Documentation/devicetree/bindings/iio/light/stk33xx.yaml
index 114cf87eb54d..d5d7059fbc0f 100644
--- a/Documentation/devicetree/bindings/iio/light/stk33xx.yaml
+++ b/Documentation/devicetree/bindings/iio/light/stk33xx.yaml
@@ -26,6 +26,7 @@ properties:
       - items:
           - enum:
               - sensortek,stk3013
+              - sensortek,stk3337
               - sensortek,stk36c61
           - const: sensortek,stk3310
 

-- 
2.56.1

