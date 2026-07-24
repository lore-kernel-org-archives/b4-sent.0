From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 24 Jul 2026 13:03:15 +0100
Subject: [PATCH v2 5/6] dt-bindings: iio: dac: ad5686: extend device
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260724-ad5686-extend-dev-support-v2-5-cfc2b30ce988@analog.com>
References: <20260724-ad5686-extend-dev-support-v2-0-cfc2b30ce988@analog.com>
In-Reply-To: <20260724-ad5686-extend-dev-support-v2-0-cfc2b30ce988@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784894592; l=2105;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=Ns24MscU2vZDNQferz6p0S9pqqd8IKrb5WBkwEhcXhc=;
 b=0uz5AU+C1uivsYzd4P0UnxNx2L8ua/yYz4ztwbhVNz9DcAraP03l0WP0pcXzNlZKiE2Og2R8Y
 GxIMxWR67BLDXLsGIyhQwnMp8Okwaa1z/AE0B0THASDP/GW1ZA3AwJs
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add compatible entries for AD5313R, AD5317R, AD5674, AD5679, AD5687,
AD5687R, AD5689, AD5689R. These devices have unique combination of channel
count, bit resolution and supported command set, so that fallback
compatibles are not used. Also, a small copy-and-paste error is fixed to
the title field.

Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 Documentation/devicetree/bindings/iio/dac/adi,ad5686.yaml | 14 +++++++++++++-
 1 file changed, 13 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/iio/dac/adi,ad5686.yaml b/Documentation/devicetree/bindings/iio/dac/adi,ad5686.yaml
index 02e8c78e36d3..d1bb09054440 100644
--- a/Documentation/devicetree/bindings/iio/dac/adi,ad5686.yaml
+++ b/Documentation/devicetree/bindings/iio/dac/adi,ad5686.yaml
@@ -4,7 +4,7 @@
 $id: http://devicetree.org/schemas/iio/dac/adi,ad5686.yaml#
 $schema: http://devicetree.org/meta-schemas/core.yaml#
 
-title: Analog Devices AD5360 and similar SPI DACs
+title: Analog Devices AD5686 and similar SPI DACs
 
 maintainers:
   - Michael Hennerich <michael.hennerich@analog.com>
@@ -14,10 +14,14 @@ properties:
   compatible:
     enum:
       - adi,ad5310r
+      - adi,ad5313r
+      - adi,ad5317r
       - adi,ad5672r
+      - adi,ad5674
       - adi,ad5674r
       - adi,ad5676
       - adi,ad5676r
+      - adi,ad5679
       - adi,ad5679r
       - adi,ad5681r
       - adi,ad5682r
@@ -28,6 +32,10 @@ properties:
       - adi,ad5685r
       - adi,ad5686
       - adi,ad5686r
+      - adi,ad5687
+      - adi,ad5687r
+      - adi,ad5689
+      - adi,ad5689r
 
   reg:
     maxItems: 1
@@ -84,10 +92,14 @@ allOf:
         compatible:
           contains:
             enum:
+              - adi,ad5674
               - adi,ad5676
+              - adi,ad5679
               - adi,ad5683
               - adi,ad5684
               - adi,ad5686
+              - adi,ad5687
+              - adi,ad5689
     then:
       required:
         - vref-supply

-- 
2.43.0

