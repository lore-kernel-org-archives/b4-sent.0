From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 28 Mar 2024 17:22:03 +0100
Subject: [PATCH v4 3/6] dt-bindings: iio: temperature: ltc2983: document
 power supply
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240328-ltc2983-misc-improv-v4-3-0cc428c07cd5@analog.com>
References: <20240328-ltc2983-misc-improv-v4-0-0cc428c07cd5@analog.com>
In-Reply-To: <20240328-ltc2983-misc-improv-v4-0-0cc428c07cd5@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org
Cc: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, 
 Jyoti Bhayana <jbhayana@google.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711642925; l=1227;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=rnQzwLPbXO4Riqnz6PXrWUTn4Pd8xKChQYwf/cGw4js=;
 b=43SYwE62YUShXFDg44JLjUmDEaIeL6O2K6S/Q9mqqHe32n1B6dDx12C1g4d5anxoCxxyZqYgI
 vyxOz4sd/clAkTmqZx8ubk8axhEJSB8CfB5Uk+gatvrKoYJCh7Sqp2k
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a property for the VDD power supply regulator.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 Documentation/devicetree/bindings/iio/temperature/adi,ltc2983.yaml | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/temperature/adi,ltc2983.yaml b/Documentation/devicetree/bindings/iio/temperature/adi,ltc2983.yaml
index dbb85135fd66..312febeeb3bb 100644
--- a/Documentation/devicetree/bindings/iio/temperature/adi,ltc2983.yaml
+++ b/Documentation/devicetree/bindings/iio/temperature/adi,ltc2983.yaml
@@ -57,6 +57,8 @@ properties:
   interrupts:
     maxItems: 1
 
+  vdd-supply: true
+
   adi,mux-delay-config-us:
     description: |
       Extra delay prior to each conversion, in addition to the internal 1ms
@@ -460,6 +462,7 @@ required:
   - compatible
   - reg
   - interrupts
+  - vdd-supply
 
 additionalProperties: false
 
@@ -489,6 +492,7 @@ examples:
             #address-cells = <1>;
             #size-cells = <0>;
 
+            vdd-supply = <&supply>;
             interrupts = <20 IRQ_TYPE_EDGE_RISING>;
             interrupt-parent = <&gpio>;
 

-- 
2.44.0

