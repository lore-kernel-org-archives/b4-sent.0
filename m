From: =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
Date: Fri, 27 Nov 2026 16:21:09 +0100
Subject: [PATCH 4/4] ARM: dts: broadcom: bcm2711: Add DMA to sdhost
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261127-bcm2835-spi-dma-v1-4-8b134991ba2e@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795792928; l=1245;
 i=cleverline1mc@gmail.com; s=20261121; h=from:subject:message-id;
 bh=/3A1iVIGEOw8HTcWNipf4TWXImmbOVBsqjUojsiUWt4=;
 b=VCfdHD94pBgq/9ZwoeVithEmUptRa44rd0G0LBgq5ZCYGee/qKBnsr7Q5Dnues8r6YQKBlxjj
 cXOmfx7dOBlDojaQA6Cz4l1rfPKOkeQM0VWyJuqBez2grlZjLIv0At8
X-Developer-Key: i=cleverline1mc@gmail.com; a=ed25519;
 pk=2UEUVmQyfsiFZkNS7dkgFg0rUmhbcMIytM6NYhxFt/Y=
X-Endpoint-Received: by B4 Relay for cleverline1mc@gmail.com/20261121 with auth_id=1594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On BCM2835/6/7, sdhost gets its DMA channel from bcm2835-common.dtsi.
Commit 7dbe8c62ceeb ("ARM: dts: Add minimal Raspberry Pi 4 support")
added the BCM2711 DMA controller but gave sdhost no channel, so a
BCM2711 board that enables sdhost runs it in PIO mode:

  sdhost-bcm2835 fe202000.mmc: unable to initialise DMA channel. Falling back to PIO

Add the same dmas as on BCM2835/6/7; the BCM2711 legacy DMA engine uses
the same DREQ number.

Tested on a Raspberry Pi 4 B: the driver gets its channel and reports
"DMA enabled". Nothing on that board is wired to the sdhost pins, so
transfers are untested.

Fixes: 7dbe8c62ceeb ("ARM: dts: Add minimal Raspberry Pi 4 support")
Signed-off-by: Kryštof Černý <cleverline1mc@gmail.com>
---
 arch/arm/boot/dts/broadcom/bcm2711.dtsi | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/arm/boot/dts/broadcom/bcm2711.dtsi b/arch/arm/boot/dts/broadcom/bcm2711.dtsi
index 0680a0b1ca67..e18f11fb7f00 100644
--- a/arch/arm/boot/dts/broadcom/bcm2711.dtsi
+++ b/arch/arm/boot/dts/broadcom/bcm2711.dtsi
@@ -1155,6 +1155,8 @@ &sdhci {
 
 &sdhost {
 	interrupts = <GIC_SPI 120 IRQ_TYPE_LEVEL_HIGH>;
+	dmas = <&dma 13>;
+	dma-names = "rx-tx";
 };
 
 &spi {

-- 
2.47.3

