From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Sun, 19 Jul 2026 10:51:57 +0100
Subject: [PATCH 1/4] dt-bindings: iio: dac: ad5696: extend device support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260719-ad5686-extend-dev-support-v1-1-841ec75cf5d8@analog.com>
References: <20260719-ad5686-extend-dev-support-v1-0-841ec75cf5d8@analog.com>
In-Reply-To: <20260719-ad5686-extend-dev-support-v1-0-841ec75cf5d8@analog.com>
To: Michael Auchter <michael.auchter@ni.com>, linux@analog.com, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784454721; l=1452;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=C17Ef8/aBMvZgOB/6VhtM6LaRYek9umi2SylTJmyiAE=;
 b=IeZpLLd9yhIC5rXRxr+bxAsCcJ9DRMaOHgB/nXc40ICt4x1IrouFwCLw/HtbIeCeiFvUDQOGC
 fnMsusMb/EyCYqf8zcMRYyrUah2W4WUgg2eBygNGV1wTCe2OAUTbTWk
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Support for AD5316R, AD5673R, AD5675, AD5677R and AD5697R missing from the
device-tree bindings documentation. These devices have different bit
resolutions or different number of channels so no fallback compatibles
are used.

Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 Documentation/devicetree/bindings/iio/dac/adi,ad5696.yaml | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/dac/adi,ad5696.yaml b/Documentation/devicetree/bindings/iio/dac/adi,ad5696.yaml
index e10f8596f9d3..835fa21c474e 100644
--- a/Documentation/devicetree/bindings/iio/dac/adi,ad5696.yaml
+++ b/Documentation/devicetree/bindings/iio/dac/adi,ad5696.yaml
@@ -16,10 +16,14 @@ properties:
   compatible:
     enum:
       - adi,ad5311r
+      - adi,ad5316r
       - adi,ad5337r
       - adi,ad5338r
       - adi,ad5671r
+      - adi,ad5673r
+      - adi,ad5675
       - adi,ad5675r
+      - adi,ad5677r
       - adi,ad5691r
       - adi,ad5692r
       - adi,ad5693
@@ -29,6 +33,7 @@ properties:
       - adi,ad5695r
       - adi,ad5696
       - adi,ad5696r
+      - adi,ad5697r
 
   reg:
     maxItems: 1
@@ -84,6 +89,7 @@ allOf:
         compatible:
           contains:
             enum:
+              - adi,ad5675
               - adi,ad5693
               - adi,ad5694
               - adi,ad5696

-- 
2.43.0

