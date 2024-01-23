From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 23 Jan 2024 16:14:24 +0100
Subject: [PATCH v7 3/9] dt-bindings: adc: axi-adc: update bindings for
 backend framework
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240123-iio-backend-v7-3-1bff236b8693@analog.com>
References: <20240123-iio-backend-v7-0-1bff236b8693@analog.com>
In-Reply-To: <20240123-iio-backend-v7-0-1bff236b8693@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Frank Rowand <frowand.list@gmail.com>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, 
 Saravana Kannan <saravanak@google.com>, Rob Herring <robh@kernel.org>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706022871; l=1739;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=araWL3MBWOdTthhIEzT+iX7Wos0rotGDe8HqcId2NUg=;
 b=TmRlUPcTqQ7yHtySwvIe/LJr9awQYYA1hLmJI5TE2Cdr+Hc4pp0CFNntohcbbJTwccPqBDWco
 r4TyNeI/b2vBUooAibyeXNqJT4oGv7kZpoQdvGV7lIeecCV65PAib1U
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

'adi,adc-dev' is now deprecated and must not be used anymore. Hence,
also remove it from being required.

The reason why it's being deprecated is because the axi-adc CORE is now
an IIO service provider hardware (IIO backends) for consumers to make use
of. Before, the logic with 'adi,adc-dev' was the opposite (it was kind
of consumer referencing other nodes/devices) and that proved to be wrong
and to not scale.

Now, IIO consumers of this hardware are expected to reference it using the
io-backends property. Hence, the new '#io-backend-cells' is being added
so the device is easily identified as a provider.

Reviewed-by: Rob Herring <robh@kernel.org>
Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 Documentation/devicetree/bindings/iio/adc/adi,axi-adc.yaml | 8 +++++---
 1 file changed, 5 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/iio/adc/adi,axi-adc.yaml b/Documentation/devicetree/bindings/iio/adc/adi,axi-adc.yaml
index 9996dd93f84b..add10b22dcac 100644
--- a/Documentation/devicetree/bindings/iio/adc/adi,axi-adc.yaml
+++ b/Documentation/devicetree/bindings/iio/adc/adi,axi-adc.yaml
@@ -39,12 +39,15 @@ properties:
     $ref: /schemas/types.yaml#/definitions/phandle
     description:
       A reference to a the actual ADC to which this FPGA ADC interfaces to.
+    deprecated: true
+
+  '#io-backends-cells'
+    const: 0
 
 required:
   - compatible
   - dmas
   - reg
-  - adi,adc-dev
 
 additionalProperties: false
 
@@ -55,7 +58,6 @@ examples:
         reg = <0x44a00000 0x10000>;
         dmas = <&rx_dma 0>;
         dma-names = "rx";
-
-        adi,adc-dev = <&spi_adc>;
+        #io-backends-cells = <0>;
     };
 ...

-- 
2.43.0

