From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Wed, 22 Apr 2026 15:45:38 +0100
Subject: [PATCH 04/22] dt-bindings: iio: dac: ad5686: extend device support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260422-ad5313r-iio-support-v1-4-ed7dca001d1b@analog.com>
References: <20260422-ad5313r-iio-support-v1-0-ed7dca001d1b@analog.com>
In-Reply-To: <20260422-ad5313r-iio-support-v1-0-ed7dca001d1b@analog.com>
To: Jonathan Cameron <jic23@kernel.org>, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Michael Auchter <michael.auchter@ni.com>, linux-hardening@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776869181; l=1669;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=HqOQ9v1hLDh+jrtLmYJHNFXNPvRsvM+6yK2HXF19r28=;
 b=cHWHdVPDJIqbj+S6F/eVxycOYC4pyjly5Gl0bzbdm6grFkRPv+GWsRvR7XhXvPovUjPQJb425
 wZlCBBDGyifByfTkcEZSY/J6BLPzkhBCoxOYItNNwAj4iDYjErdaUJU
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add compatible entries for AD5313R, AD5317R, AD5674, AD5679, AD5687,
AD5687R, AD5689, AD5689R. These devices have unique combination of channel
count, bit resolution and supported command set, so that fallback
compatibles are not used. Also, a small copy-and-paste error is fixed to
the title field.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 Documentation/devicetree/bindings/iio/dac/adi,ad5686.yaml | 10 +++++++++-
 1 file changed, 9 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/iio/dac/adi,ad5686.yaml b/Documentation/devicetree/bindings/iio/dac/adi,ad5686.yaml
index 713f535bb33a..cb035741529f 100644
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

-- 
2.43.0

