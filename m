From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 01 Mar 2024 18:14:51 +0100
Subject: [PATCH v3 2/3] dt-bindings: iio: temperature: ltc2983: document
 power supply
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240301-ltc2983-misc-improv-v3-2-c09516ac0efc@analog.com>
References: <20240301-ltc2983-misc-improv-v3-0-c09516ac0efc@analog.com>
In-Reply-To: <20240301-ltc2983-misc-improv-v3-0-c09516ac0efc@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1709313291; l=1162;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=cQBR+Yq83wR9gQYjnaJnzjaD/C1UCI7IIsrATX4nTW8=;
 b=xGEJ10/wpnMNl/TXsFcMJ84nFiHRFXRPlzKnerymazyD+p0amBNLO1XJ3Syag/O/ZjZmoquGn
 +DxgDt9HiVzD8tTSNhX9OyfnScJkcQkf9Ulpy1hDJnv9QK5FbTJc/vP
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a property for the VDD power supply regulator.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 Documentation/devicetree/bindings/iio/temperature/adi,ltc2983.yaml | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/temperature/adi,ltc2983.yaml b/Documentation/devicetree/bindings/iio/temperature/adi,ltc2983.yaml
index dbb85135fd668..312febeeb3bba 100644
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
2.43.2

