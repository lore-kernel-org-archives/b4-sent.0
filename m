From: Rajan Yadav <rajanyadav0307@gmail.com>
Date: Fri, 20 Nov 2026 01:22:14 -0600
Subject: [PATCH 2/4] dt-bindings: arm: sunxi: Add KickPi K5C
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-k5c-dt-v1-v1-2-d9681df67bc0@gmail.com>
References: <20261120-k5c-dt-v1-v1-0-d9681df67bc0@gmail.com>
In-Reply-To: <20261120-k5c-dt-v1-v1-0-d9681df67bc0@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Maxime Ripard <mripard@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 Andre Przywara <andre.przywara@arm.com>, 
 Paul Kocialkowski <paulk@sys-base.io>, 
 Rajan Yadav <rajanyadav0307@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795159332; l=1161;
 i=rajanyadav0307@gmail.com; s=20261103; h=from:subject:message-id;
 bh=I6vTUiLrsSlHBFAWdmnCYgV4zJVZLtmnTrmixiYpI3k=;
 b=ivPANXo15cQvw/pll2FSLMB+F0n4tBG0M/5PnBd34+VGKE4ZuaF0S5IqXfE3QqBq2Calcjhe5
 eZ93q4HzeKqAz9m66TJSwX3+ay9dM9EDtKE7xdq6G50kPZxVbAVnmQK
X-Developer-Key: i=rajanyadav0307@gmail.com; a=ed25519;
 pk=4ZPeiP5qrv2b44q/Obxi2koUS70Q6npbttJnpUoTlgg=
X-Endpoint-Received: by B4 Relay for rajanyadav0307@gmail.com/20261103 with auth_id=1391
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The KickPi K5C is a single board computer with an Allwinner A133 SoC,
2 GB of DDR3 DRAM, eMMC, an SD card slot, Gigabit Ethernet, a Wi-Fi/BT
module, USB host ports and a USB-C OTG port.

Add its compatible. Like the Teclast P80, it names the SoC as
allwinner,sun50i-a133.

Claude Code (Anthropic) drafted this change and its message; I
reviewed it and checked it with dt_binding_check.

Signed-off-by: Rajan Yadav <rajanyadav0307@gmail.com>
---
 Documentation/devicetree/bindings/arm/sunxi.yaml | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/sunxi.yaml b/Documentation/devicetree/bindings/arm/sunxi.yaml
index 7da84e2de74..b21205f327f 100644
--- a/Documentation/devicetree/bindings/arm/sunxi.yaml
+++ b/Documentation/devicetree/bindings/arm/sunxi.yaml
@@ -405,6 +405,11 @@ properties:
           - const: jesurun,q5
           - const: allwinner,sun4i-a10
 
+      - description: KickPi K5C
+        items:
+          - const: kickpi,k5c
+          - const: allwinner,sun50i-a133
+
       - description: Lamobo R1
         items:
           - const: lamobo,lamobo-r1

-- 
2.34.1

