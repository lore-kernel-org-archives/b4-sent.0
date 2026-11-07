From: Roman Vivchar <rva333@protonmail.com>
Date: Sun, 08 Nov 2026 00:15:04 +0200
Subject: [PATCH 2/4] dt-bindings: iio: light: stk33xx: add stk3337
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-6768-stk3337-v1-2-0340c99b0e33@protonmail.com>
References: <20261108-6768-stk3337-v1-0-0340c99b0e33@protonmail.com>
In-Reply-To: <20261108-6768-stk3337-v1-0-0340c99b0e33@protonmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794089703; l=1019;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=ulTXlsgUnqMlSx1fcDqcSjlgFN3edmGNunTnTFylHu4=;
 b=NHHDjJaw3clpHIxlMzAhLy8EGQDdoHFpb9U1I66vH75woPji8SlN/5LqVOOKKi04+Az2mIXLl
 3T0wJNLfypvADeSkuW6rIc+xYQpNRL4uvepcWksifqBkvSERI+F/95M
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add compatible string for the stk3337 ALSPS sensor. Its core registers
are backwards compatible with the stk3310, while also providing a clear
light channel like the stk36c61, so document it with sensortek,stk3310
as a fallback.

Datasheet: https://www.bestmodulescorp.com/en/amfile/file/download/file/1699/product/1048/
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
2.56.0

