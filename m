From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 24 Jul 2026 13:03:14 +0100
Subject: [PATCH v2 4/6] dt-bindings: iio: dac: ad5696: extend device
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260724-ad5686-extend-dev-support-v2-4-cfc2b30ce988@analog.com>
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
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784894592; l=1287;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=63m1LwLWVeApaoTgcE/eNkXUbzs9WDM/QX6+A1pEnRM=;
 b=dMwYoTNaaVtwfZfGUbmtrZbjssG+7EMmIBgDhujc456oaGr7NZaVGCAXPaNqosSKndyFzqj8X
 jKNlXQ8bpPlBys41tTQzEwxzSgOVV9j6ECCYyYK66IU4unCpnipaqGP
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for AD5316R, AD5675 and AD5697R. These devices have different
bit resolutions or different number of channels so no fallback compatibles
are used.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 Documentation/devicetree/bindings/iio/dac/adi,ad5696.yaml | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/dac/adi,ad5696.yaml b/Documentation/devicetree/bindings/iio/dac/adi,ad5696.yaml
index 5a93edc976f0..835fa21c474e 100644
--- a/Documentation/devicetree/bindings/iio/dac/adi,ad5696.yaml
+++ b/Documentation/devicetree/bindings/iio/dac/adi,ad5696.yaml
@@ -16,10 +16,12 @@ properties:
   compatible:
     enum:
       - adi,ad5311r
+      - adi,ad5316r
       - adi,ad5337r
       - adi,ad5338r
       - adi,ad5671r
       - adi,ad5673r
+      - adi,ad5675
       - adi,ad5675r
       - adi,ad5677r
       - adi,ad5691r
@@ -31,6 +33,7 @@ properties:
       - adi,ad5695r
       - adi,ad5696
       - adi,ad5696r
+      - adi,ad5697r
 
   reg:
     maxItems: 1
@@ -86,6 +89,7 @@ allOf:
         compatible:
           contains:
             enum:
+              - adi,ad5675
               - adi,ad5693
               - adi,ad5694
               - adi,ad5696

-- 
2.43.0

