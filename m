From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 26 Apr 2024 17:42:12 +0200
Subject: [PATCH v2 3/7] dt-bindings: adc: axi-adc: add clocks property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240426-ad9467-new-features-v2-3-6361fc3ba1cc@analog.com>
References: <20240426-ad9467-new-features-v2-0-6361fc3ba1cc@analog.com>
In-Reply-To: <20240426-ad9467-new-features-v2-0-6361fc3ba1cc@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Jonathan Cameron <Jonathan.Cameron@huawei.com>, 
 Alexandru Ardelean <alexandru.ardelean@analog.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1714146147; l=1362;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=Kji5f67mZEzci00M6vCqK7nqcsD4CPN32lsTL2M54tY=;
 b=2PLktNW4hBVWhtlf7tXvDHJdFNDsnNv7SWATfWUTWw1p65eSQWZ3Ofj4EWJrA/MDiUSCeQvEh
 JHwKmwH/XC9DezBpZhQqTbVcd9PbIhzmNpLmhTmpfkTwPDIY/sp+QnH
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a required clock property as we can't access the device registers if
the AXI bus clock is not properly enabled.

Note this clock is a very fundamental one that is typically enabled
pretty early during boot. Independently of that, we should really rely on
it to be enabled.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Fixes: 96553a44e96d ("dt-bindings: iio: adc: add bindings doc for AXI ADC driver")
Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 Documentation/devicetree/bindings/iio/adc/adi,axi-adc.yaml | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/adc/adi,axi-adc.yaml b/Documentation/devicetree/bindings/iio/adc/adi,axi-adc.yaml
index 3d49d21ad33d..e1f450b80db2 100644
--- a/Documentation/devicetree/bindings/iio/adc/adi,axi-adc.yaml
+++ b/Documentation/devicetree/bindings/iio/adc/adi,axi-adc.yaml
@@ -28,6 +28,9 @@ properties:
   reg:
     maxItems: 1
 
+  clocks:
+    maxItems: 1
+
   dmas:
     maxItems: 1
 
@@ -48,6 +51,7 @@ required:
   - compatible
   - dmas
   - reg
+  - clocks
 
 additionalProperties: false
 
@@ -58,6 +62,7 @@ examples:
         reg = <0x44a00000 0x10000>;
         dmas = <&rx_dma 0>;
         dma-names = "rx";
+        clocks = <&axi_clk>;
         #io-backend-cells = <0>;
     };
 ...

-- 
2.44.0

