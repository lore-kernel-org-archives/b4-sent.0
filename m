From: Yu-Che Hsieh <yc_hsieh@aspeedtech.com>
Date: Mon, 29 Jun 2026 14:49:00 +0800
Subject: [PATCH 3/4] dt-bindings: ipmi: Add optional LPC properties to
 ASPEED BT devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260629-aspeed-bt-bmc-multichannel-v1-3-fc23ee337f7a@aspeedtech.com>
References: <20260629-aspeed-bt-bmc-multichannel-v1-0-fc23ee337f7a@aspeedtech.com>
In-Reply-To: <20260629-aspeed-bt-bmc-multichannel-v1-0-fc23ee337f7a@aspeedtech.com>
To: Corey Minyard <corey@minyard.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>
Cc: openipmi-developer@lists.sourceforge.net, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, Yu-Che Hsieh <yc_hsieh@aspeedtech.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782715772; l=2189;
 i=yc_hsieh@aspeedtech.com; s=20260629; h=from:subject:message-id;
 bh=z+ycFWmOaDIg3MLyJDHKU8ALQWWy3TelygSh1S01hYI=;
 b=2Z9HfF4G2QEiNPdhd3fE4XoWv99voNdrQ8WCW9S6YS9YMCZkCHI4FWveW74mN6CgGvTdjwiDC
 DSvofFpp5H7Dr21dT5wgMlRNWm301BGtmyyzOF1GLUFzkHN5ot/asz7
X-Developer-Key: i=yc_hsieh@aspeedtech.com; a=ed25519;
 pk=kLxUeF7g6teciq79it9N3tYNgp3yCspZ+AHlYSnZ0gs=
X-Endpoint-Received: by B4 Relay for yc_hsieh@aspeedtech.com/20260629 with auth_id=844
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allocating IO and IRQ resources to LPC devices is in-theory an operation

for the host, however ASPEED systems describe these resources through

BMC-internal configuration, as already supported by the ASPEED KCS BMC

binding.

Add aspeed,lpc-io-reg and aspeed,lpc-interrupts to the ASPEED BT BMC

binding so firmware can describe the host LPC IO address and SerIRQ

configuration using the same properties as KCS devices.

Signed-off-by: Yu-Che Hsieh <yc_hsieh@aspeedtech.com>
---
 .../bindings/ipmi/aspeed,ast2400-ibt-bmc.yaml       | 21 +++++++++++++++++++++
 1 file changed, 21 insertions(+)

diff --git a/Documentation/devicetree/bindings/ipmi/aspeed,ast2400-ibt-bmc.yaml b/Documentation/devicetree/bindings/ipmi/aspeed,ast2400-ibt-bmc.yaml
index c4f7cdbbe16b..1803c6bbae93 100644
--- a/Documentation/devicetree/bindings/ipmi/aspeed,ast2400-ibt-bmc.yaml
+++ b/Documentation/devicetree/bindings/ipmi/aspeed,ast2400-ibt-bmc.yaml
@@ -25,6 +25,24 @@ properties:
   interrupts:
     maxItems: 1
 
+  aspeed,lpc-io-reg:
+    $ref: /schemas/types.yaml#/definitions/uint32-array
+    maxItems: 1
+    description: |
+      The host CPU LPC IO address for the BT device.
+
+  aspeed,lpc-interrupts:
+    $ref: /schemas/types.yaml#/definitions/uint32-array
+    minItems: 2
+    maxItems: 2
+    description: |
+      A 2-cell property expressing the LPC SerIRQ number and the interrupt
+      level/sense encoding (specified in the standard fashion).
+
+      Note that the generated interrupt is issued from the BMC to the host, and
+      thus the target interrupt controller is not captured by the BMC's
+      devicetree.
+
 required:
   - compatible
   - reg
@@ -35,10 +53,13 @@ additionalProperties: false
 examples:
   - |
     #include <dt-bindings/clock/aspeed-clock.h>
+    #include <dt-bindings/interrupt-controller/irq.h>
 
     bt@1e789140 {
         compatible = "aspeed,ast2400-ibt-bmc";
         reg = <0x1e789140 0x18>;
         interrupts = <8>;
         clocks = <&syscon ASPEED_CLK_GATE_LCLK>;
+        aspeed,lpc-io-reg = <0xe4>;
+        aspeed,lpc-interrupts = <10 IRQ_TYPE_LEVEL_LOW>;
     };

-- 
2.34.1

