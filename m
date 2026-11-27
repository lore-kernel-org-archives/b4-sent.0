From: =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
Date: Fri, 27 Nov 2026 16:21:07 +0100
Subject: [PATCH 2/4] ARM: dts: broadcom: bcm2711: Add DMA to spi0
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261127-bcm2835-spi-dma-v1-2-8b134991ba2e@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795792928; l=1485;
 i=cleverline1mc@gmail.com; s=20261121; h=from:subject:message-id;
 bh=3LkYLqDSBIdIHjYVfPnYqCyqSH/Km4Qx6FOxvWDlO2M=;
 b=UMpTdwMyu7XiZ63swbQ4uW4crbOkMqjBmdrn03nR2H+a+YjGOGWQV5WYQFCY4RYCnaDTd3UMF
 Y3ZLYx9k/mRDyxHzsfm+Yvoavka08+8y3q1f7Lqgy7gpgNyLov3T+4W
X-Developer-Key: i=cleverline1mc@gmail.com; a=ed25519;
 pk=2UEUVmQyfsiFZkNS7dkgFg0rUmhbcMIytM6NYhxFt/Y=
X-Endpoint-Received: by B4 Relay for cleverline1mc@gmail.com/20261121 with auth_id=1594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On BCM2835/6/7, spi0 gets its DMA channels from bcm2835-common.dtsi,
where commit 3ce82be9ae3d ("ARM: dts: bcm283x: Move BCM2835/6/7 specific
to bcm2835-common.dtsi") moved them together with the DMA controller.
Commit 7dbe8c62ceeb ("ARM: dts: Add minimal Raspberry Pi 4 support")
then added the BCM2711 DMA controller without any of its users, so on
BCM2711 spi0 falls back to PIO and logs an error:

  spi-bcm2835 fe204000.spi: error -ENODEV: no tx-dma configuration found - not using dma mode

The BCM2711 has the same legacy DMA engine and DREQ numbers, and the
/soc dma-ranges already limit spi0 to the lower 1 GiB that the engine
can address. Add the same dmas as on BCM2835/6/7.

On a Raspberry Pi 4 B, 64 KiB transfers at 31.25 MHz go from 26.8 Mbit/s
with 11% of CPU0 left in PIO mode to 32.5 Mbit/s with CPU0 nearly idle.

Fixes: 7dbe8c62ceeb ("ARM: dts: Add minimal Raspberry Pi 4 support")
Signed-off-by: Kryštof Černý <cleverline1mc@gmail.com>
---
 arch/arm/boot/dts/broadcom/bcm2711.dtsi | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/arm/boot/dts/broadcom/bcm2711.dtsi b/arch/arm/boot/dts/broadcom/bcm2711.dtsi
index 5e3b4bb39396..8ebf52b20c66 100644
--- a/arch/arm/boot/dts/broadcom/bcm2711.dtsi
+++ b/arch/arm/boot/dts/broadcom/bcm2711.dtsi
@@ -1154,6 +1154,8 @@ &sdhost {
 
 &spi {
 	interrupts = <GIC_SPI 118 IRQ_TYPE_LEVEL_HIGH>;
+	dmas = <&dma 6>, <&dma 7>;
+	dma-names = "tx", "rx";
 };
 
 &spi1 {

-- 
2.47.3

