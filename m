From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 08 Dec 2023 16:14:08 +0100
Subject: [PATCH v2 1/8] dt-bindings: adc: ad9467: document io-backend
 property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231208-dev-iio-backend-v2-1-5450951895e1@analog.com>
References: <20231208-dev-iio-backend-v2-0-5450951895e1@analog.com>
In-Reply-To: <20231208-dev-iio-backend-v2-0-5450951895e1@analog.com>
To: devicetree@vger.kernel.org, linux-iio@vger.kernel.org
Cc: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Frank Rowand <frowand.list@gmail.com>, Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1702048448; l=1040;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=D7q6W8VwWUTViQGqb/BMWILjEw70nj+zEHdZlbAYQfs=;
 b=LR+bQ8JVhYh8Nxd2JNwQ2wemBAt9u9NReHkrS52MLd7EI2VjnP6c7itJrlDnznmlpoXKAxwPM
 0RX0rSDKb6aBVntib++GIu8TwpMnqrN1RdQFd9gpdAjpMo76F6lHeeD
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a new property to reference IIO backend devices.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 Documentation/devicetree/bindings/iio/adc/adi,ad9467.yaml | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/adc/adi,ad9467.yaml b/Documentation/devicetree/bindings/iio/adc/adi,ad9467.yaml
index 7aa748d6b7a0..ae74249b4726 100644
--- a/Documentation/devicetree/bindings/iio/adc/adi,ad9467.yaml
+++ b/Documentation/devicetree/bindings/iio/adc/adi,ad9467.yaml
@@ -44,6 +44,10 @@ properties:
       Pin that controls the powerdown mode of the device.
     maxItems: 1
 
+  io-backends:
+    description: Phandle to the IIO backend device.
+    $ref: /schemas/types.yaml#/definitions/phandle
+
   reset-gpios:
     description:
       Reset pin for the device.
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

