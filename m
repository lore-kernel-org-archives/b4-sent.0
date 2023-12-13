From: Nuno Sa <nuno.sa@analog.com>
Date: Wed, 13 Dec 2023 16:02:32 +0100
Subject: [PATCH v3 1/8] dt-bindings: adc: ad9467: add new io-backend
 property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231213-dev-iio-backend-v3-1-bb9f12a5c6dc@analog.com>
References: <20231213-dev-iio-backend-v3-0-bb9f12a5c6dc@analog.com>
In-Reply-To: <20231213-dev-iio-backend-v3-0-bb9f12a5c6dc@analog.com>
To: devicetree@vger.kernel.org, linux-iio@vger.kernel.org
Cc: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Frank Rowand <frowand.list@gmail.com>, Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1702479785; l=1274;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=VgLwQbZqXp2b3r8rCQLCxjYuGEkN0w8TgD+TUyg/P+U=;
 b=RNEWJwrW39KG1P87W8rnKQQ8e2Lkd8TlA03zxcoQ0QbLcm+dFsEp7QUSCjggP5dF6AKs6wru6
 7WfnleJV3PJD0xq5tzRac5ebkAlf7fXFTpZPm/33v/2vSbneQVITc2F
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ad9467 will make use of the new IIO backend framework which is a
provider - consumer interface where IIO backends provide services to
consumers. As such, and being this device a consumer,  add the new
generic io-backend property to the bindings.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 Documentation/devicetree/bindings/iio/adc/adi,ad9467.yaml | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/adc/adi,ad9467.yaml b/Documentation/devicetree/bindings/iio/adc/adi,ad9467.yaml
index 7aa748d6b7a0..74e6827cbd47 100644
--- a/Documentation/devicetree/bindings/iio/adc/adi,ad9467.yaml
+++ b/Documentation/devicetree/bindings/iio/adc/adi,ad9467.yaml
@@ -44,6 +44,9 @@ properties:
       Pin that controls the powerdown mode of the device.
     maxItems: 1
 
+  io-backends:
+    maxItems: 1
+
   reset-gpios:
     description:
       Reset pin for the device.
@@ -54,6 +57,7 @@ required:
   - reg
   - clocks
   - clock-names
+  - io-backends
 
 additionalProperties: false
 
@@ -68,6 +72,7 @@ examples:
             reg = <0>;
             clocks = <&adc_clk>;
             clock-names = "adc-clk";
+            io-backends = <&iio_backend>;
         };
     };
 ...

-- 
2.43.0

