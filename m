From: ILYAS NHASSE <ilyas.nhasse@skf.com>
Date: Fri, 20 Nov 2026 12:26:47 +0100
Subject: [PATCH 1/2] dt-bindings: iio: adc: adi,ad7124: make interrupts
 optional
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-ad7124-no-irq-v1-1-7826c5c3fd25@skf.com>
References: <20261120-ad7124-no-irq-v1-0-7826c5c3fd25@skf.com>
In-Reply-To: <20261120-ad7124-no-irq-v1-0-7826c5c3fd25@skf.com>
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Marcelo Schmitt <marcelo.schmitt@analog.com>
Cc: linux@analog.com, linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, ILYAS NHASSE <ilyas.nhasse@skf.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795174009; l=1125;
 i=ilyas.nhasse@skf.com; s=20261120; h=from:subject:message-id;
 bh=OBY5HTgouzEhhyqdI03rWKM9m5ChuW0YKJiNCBaU4UY=;
 b=Q2kK1uSKSzFCdszJZr5rQwVp9XvjHFUET83hOJYqdsVcB9Mc6fe3K2mRWxtgmi66591Kz6kkN
 RJ0BarhykH3D72bN5LFAoUl+s/T01ZFYW/E9DIsr9Tpnhff5GJ9Hkm3
X-Developer-Key: i=ilyas.nhasse@skf.com; a=ed25519;
 pk=DeEyhWzUoP0HCAWFV/8oy5EFF+41tZxPpWZhfGyiMS4=
X-Endpoint-Received: by B4 Relay for ilyas.nhasse@skf.com/20261120 with auth_id=1581
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The AD7124 signals the end of a conversion on its DOUT/RDY pin, which is
also the SPI MISO line. Using it as an interrupt requires the board to
route that pin to an interrupt-capable input as well, which is not always
possible, e.g. when the ADC sits behind a digital isolator that only
carries the SPI signals.

The end of a conversion can also be read from the RDY bit of the status
register, so the interrupt is not needed to operate the device. Drop it
from the required properties.

Signed-off-by: ILYAS NHASSE <ilyas.nhasse@skf.com>
---
 Documentation/devicetree/bindings/iio/adc/adi,ad7124.yaml | 1 -
 1 file changed, 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/iio/adc/adi,ad7124.yaml b/Documentation/devicetree/bindings/iio/adc/adi,ad7124.yaml
index 2e3f84db6..875f46477 100644
--- a/Documentation/devicetree/bindings/iio/adc/adi,ad7124.yaml
+++ b/Documentation/devicetree/bindings/iio/adc/adi,ad7124.yaml
@@ -76,7 +76,6 @@ properties:
 required:
   - compatible
   - reg
-  - interrupts
 
 # Can't have both clock input and output at the same time.
 not:

-- 
2.43.0

