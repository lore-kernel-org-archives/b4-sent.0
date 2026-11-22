From: Roman Vivchar <rva333@protonmail.com>
Date: Sun, 22 Nov 2026 19:15:47 +0200
Subject: [PATCH v3 6/7] dt-bindings: iio: light: stk33xx: add stk3331
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-6768-stk3337-v3-6-b0d0a924e843@protonmail.com>
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
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795367795; l=928;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=FMWn6gsTNNWE09tFLvynX9SKYEXNZEcUpJAhLcr17Uo=;
 b=L0SRJNe1gG5tYGcqm/e7P0+nk5AeKlgbaBDTToAADrt5dGBPTUrL+SjzsRP5rN2shLSjj2xFl
 zjxVk3X4egtCr0K/hW372mpgAauuIsgLnusOG3kfgkGbzlvLOaZAqCP
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

STK3331 is a STK3337 variant with slightly bigger package. It has the
same Clear channel and register map. Add a compatible string for it.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 Documentation/devicetree/bindings/iio/light/stk33xx.yaml | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/light/stk33xx.yaml b/Documentation/devicetree/bindings/iio/light/stk33xx.yaml
index d5d7059fbc0f..2e91158921fe 100644
--- a/Documentation/devicetree/bindings/iio/light/stk33xx.yaml
+++ b/Documentation/devicetree/bindings/iio/light/stk33xx.yaml
@@ -29,6 +29,10 @@ properties:
               - sensortek,stk3337
               - sensortek,stk36c61
           - const: sensortek,stk3310
+      - items:
+          - const: sensortek,stk3331
+          - const: sensortek,stk3337
+          - const: sensortek,stk3310
 
   reg:
     maxItems: 1

-- 
2.56.1

