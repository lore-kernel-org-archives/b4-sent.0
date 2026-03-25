From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Wed, 25 Mar 2026 11:12:02 +0000
Subject: [PATCH 1/2] dt-bindings: iio: amplifiers: ad8366: add adrf5702/3
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260325-adrf570x-iio-support-v1-1-9a2685eb2e55@analog.com>
References: <20260325-adrf570x-iio-support-v1-0-9a2685eb2e55@analog.com>
In-Reply-To: <20260325-adrf570x-iio-support-v1-0-9a2685eb2e55@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774437143; l=1134;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=yeOzs3WYQQtQrqWYQpKl8DQScANIz91jhYI5r9rZsLc=;
 b=A6KDXoVGnlGQLC6ZMFVDPsyPzUOrUgWkiFt6we4vL3Q9CI4frXqcEjluTP8LySqFCv85IBv8u
 oCJcBr4+BImB9lwkZ9TqabmMPp/v/SbZzJ5uomHpbT4BJelQKCyRbOe
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add compatible entries for ADRF5702 and ADRF5703 Digital Attenuators.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 Documentation/devicetree/bindings/iio/amplifiers/adi,ad8366.yaml | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/amplifiers/adi,ad8366.yaml b/Documentation/devicetree/bindings/iio/amplifiers/adi,ad8366.yaml
index 2719de1166a1..065637ce33a5 100644
--- a/Documentation/devicetree/bindings/iio/amplifiers/adi,ad8366.yaml
+++ b/Documentation/devicetree/bindings/iio/amplifiers/adi,ad8366.yaml
@@ -20,6 +20,8 @@ properties:
       - adi,ad8366
       - adi,ada4961
       - adi,adl5240
+      - adi,adrf5702
+      - adi,adrf5703
       - adi,adrf5720
       - adi,adrf5730
       - adi,adrf5731
@@ -66,6 +68,8 @@ allOf:
               anyOf:
                 - const: adi,ad8366
                 - const: adi,ada4961
+                - const: adi,adrf5702
+                - const: adi,adrf5703
                 - const: adi,adrf5720
                 - const: adi,adrf5730
                 - const: adi,adrf5731

-- 
2.43.0

