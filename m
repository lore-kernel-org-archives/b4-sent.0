From: =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
Date: Fri, 27 Nov 2026 16:21:06 +0100
Subject: [PATCH 1/4] spi: dt-bindings: brcm,bcm2835-spi: Add dmas and
 dma-names
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261127-bcm2835-spi-dma-v1-1-8b134991ba2e@gmail.com>
References: <20261127-bcm2835-spi-dma-v1-0-8b134991ba2e@gmail.com>
In-Reply-To: <20261127-bcm2835-spi-dma-v1-0-8b134991ba2e@gmail.com>
To: Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Florian Fainelli <florian.fainelli@broadcom.com>, 
 Broadcom internal kernel review list <bcm-kernel-feedback-list@broadcom.com>, 
 Ray Jui <ray.jui@broadcom.com>, Scott Branden <scott.branden@broadcom.com>, 
 Kanak Shilledar <kanakshilledar111@protonmail.com>, 
 Stefan Wahren <wahrenst@gmx.net>, Florian Fanelli <f.fainelli@gmail.com>, 
 Eric Anholt <eric@anholt.net>
Cc: Conor Dooley <conor.dooley@microchip.com>, linux-spi@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-rpi-kernel@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, Miroslav Ondra <ondra@faster.cz>, 
 =?utf-8?q?Matou=C5=A1_H=C3=BDbl?= <hyblmatous@gmail.com>, 
 =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795792928; l=1665;
 i=cleverline1mc@gmail.com; s=20261121; h=from:subject:message-id;
 bh=qVwzj9YtYL53uYDnPyCdzi1pxK78x9hB7h8+EBasjyc=;
 b=W5YThTyWtWNBznWDQ5RjgWHC76GiJzR/P/5D9VGh5DK5IchJJ57bcKp0bmIjCOj6VEYZ+0oVo
 hyr9v1AtyrsC9+0Ean6h/ASIx469R27KQ8kzrpg80JfyYatwJVM7W8e
X-Developer-Key: i=cleverline1mc@gmail.com; a=ed25519;
 pk=2UEUVmQyfsiFZkNS7dkgFg0rUmhbcMIytM6NYhxFt/Y=
X-Endpoint-Received: by B4 Relay for cleverline1mc@gmail.com/20261121 with auth_id=1594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver requests optional "tx" and "rx" DMA channels, and
bcm2835-common.dtsi has set them on the SPI node since commit
cbbe88333062 ("ARM: bcm283x: Enable DMA support for SPI controller"),
but the schema from the conversion to dtschema does not allow them.
dtbs_check is silent only because no in-tree board enables the node;
with spi0 enabled on a BCM2837 board it reports:

  spi@7e204000 (brcm,bcm2835-spi): Unevaluated properties are not allowed ('dma-names', 'dmas' were unexpected)

Document both properties.

Fixes: 85ce0dc28ffd ("spi: dt-bindings: brcm,bcm2835-spi: convert to dtschema")
Signed-off-by: Kryštof Černý <cleverline1mc@gmail.com>
---
 Documentation/devicetree/bindings/spi/brcm,bcm2835-spi.yaml | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/Documentation/devicetree/bindings/spi/brcm,bcm2835-spi.yaml b/Documentation/devicetree/bindings/spi/brcm,bcm2835-spi.yaml
index 94da68792194..8d2919ce6096 100644
--- a/Documentation/devicetree/bindings/spi/brcm,bcm2835-spi.yaml
+++ b/Documentation/devicetree/bindings/spi/brcm,bcm2835-spi.yaml
@@ -30,6 +30,16 @@ properties:
   clocks:
     maxItems: 1
 
+  dmas:
+    items:
+      - description: TX DMA channel
+      - description: RX DMA channel
+
+  dma-names:
+    items:
+      - const: tx
+      - const: rx
+
 required:
   - compatible
   - reg
@@ -45,6 +55,8 @@ examples:
         reg = <0x7e204000 0x1000>;
         interrupts = <2 22>;
         clocks = <&clk_spi>;
+        dmas = <&dma 6>, <&dma 7>;
+        dma-names = "tx", "rx";
         #address-cells = <1>;
         #size-cells = <0>;
     };

-- 
2.47.3

