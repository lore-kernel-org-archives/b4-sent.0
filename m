From: Amit Sunil Dhamne <amitsd@google.com>
Date: Wed, 25 Mar 2026 22:22:23 +0000
Subject: [PATCH v9 2/6] dt-bindings: usb: maxim,max33359: Add supply
 property for vbus
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260325-max77759-charger-v9-2-4486dd297adc@google.com>
References: <20260325-max77759-charger-v9-0-4486dd297adc@google.com>
In-Reply-To: <20260325-max77759-charger-v9-0-4486dd297adc@google.com>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>, 
 Lee Jones <lee@kernel.org>, Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Tudor Ambarus <tudor.ambarus@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, Mark Brown <broonie@kernel.org>, 
 Matti Vaittinen <mazziesaccount@gmail.com>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-usb@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 RD Babiera <rdbabiera@google.com>, Kyle Tso <kyletso@google.com>, 
 Amit Sunil Dhamne <amitsd@google.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774477354; l=1273;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=xHGJ1Vk5ohekxV/HkgsFaQ5FhplVGnbXa8tx/HTuhSE=;
 b=CTTOsuHGqVUcu4uWfAFuYbSqHf/2gLAtRaF9QcKDjxZI511TxrXnXqTcN5uL2O40X58LVgvhg
 2xQrghgR95LAiEQ4UxBVsFYDj/kEO+8Q7PFMWxrkTvQlb05IeA8qpkG
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a regulator supply property for vbus. This notifies the regulator
provider to source vbus when Type-C operates in Source power mode,
while turn off sourcing vbus when operating in Sink mode or
disconnected.

Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
---
 Documentation/devicetree/bindings/usb/maxim,max33359.yaml | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/usb/maxim,max33359.yaml b/Documentation/devicetree/bindings/usb/maxim,max33359.yaml
index 3de4dc40b791..e652a24902ea 100644
--- a/Documentation/devicetree/bindings/usb/maxim,max33359.yaml
+++ b/Documentation/devicetree/bindings/usb/maxim,max33359.yaml
@@ -32,6 +32,9 @@ properties:
     description:
       Properties for usb c connector.
 
+  vbus-supply:
+    description: Regulator to control sourcing Vbus.
+
 required:
   - compatible
   - reg
@@ -53,6 +56,7 @@ examples:
             reg = <0x25>;
             interrupt-parent = <&gpa8>;
             interrupts = <2 IRQ_TYPE_LEVEL_LOW>;
+            vbus-supply = <&chgin_otg_reg>;
 
             connector {
                 compatible = "usb-c-connector";

-- 
2.53.0.1018.g2bb0e51243-goog

