From: =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
Date: Fri, 27 Nov 2026 16:21:08 +0100
Subject: [PATCH 3/4] ARM: dts: broadcom: bcm2711: Add DMA to i2s
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261127-bcm2835-spi-dma-v1-3-8b134991ba2e@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795792928; l=1355;
 i=cleverline1mc@gmail.com; s=20261121; h=from:subject:message-id;
 bh=btPPpOO7EzC2GTVg4V2ShCZQPnjgvV+OMkhhyyjh+9Q=;
 b=l8d0wjig/ng+d2XDHjj1iL8A1oUD0DKMCAGe8OdhNhok7gvQmwrUwtB2du+qBhGkuf7vjsZg9
 MbQ03pmSQI1C+pgbL+v7xuPWC7mXlP+0aONKA/hw0116AeiY5aq90HU
X-Developer-Key: i=cleverline1mc@gmail.com; a=ed25519;
 pk=2UEUVmQyfsiFZkNS7dkgFg0rUmhbcMIytM6NYhxFt/Y=
X-Endpoint-Received: by B4 Relay for cleverline1mc@gmail.com/20261121 with auth_id=1594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On BCM2835/6/7, i2s gets its DMA channels from bcm2835-common.dtsi.
Commit 7dbe8c62ceeb ("ARM: dts: Add minimal Raspberry Pi 4 support")
added the BCM2711 DMA controller but gave i2s no channels, although the
binding requires them. The driver has no PIO fallback, so on BCM2711
i2s fails to create its PCM and no sound card using it can register:

  bcm2835-i2s fe203000.i2s: Missing dma channel for stream: 0

Add the same dmas as on BCM2835/6/7; the BCM2711 legacy DMA engine uses
the same DREQ numbers.

Tested on a Raspberry Pi 4 B with simple-audio-card and a dummy S/PDIF
codec: 48 kHz/S16 and 192 kHz/S32 stereo play without xruns.

Fixes: 7dbe8c62ceeb ("ARM: dts: Add minimal Raspberry Pi 4 support")
Signed-off-by: Kryštof Černý <cleverline1mc@gmail.com>
---
 arch/arm/boot/dts/broadcom/bcm2711.dtsi | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/arch/arm/boot/dts/broadcom/bcm2711.dtsi b/arch/arm/boot/dts/broadcom/bcm2711.dtsi
index 8ebf52b20c66..0680a0b1ca67 100644
--- a/arch/arm/boot/dts/broadcom/bcm2711.dtsi
+++ b/arch/arm/boot/dts/broadcom/bcm2711.dtsi
@@ -1140,6 +1140,11 @@ &i2c1 {
 	interrupts = <GIC_SPI 117 IRQ_TYPE_LEVEL_HIGH>;
 };
 
+&i2s {
+	dmas = <&dma 2>, <&dma 3>;
+	dma-names = "tx", "rx";
+};
+
 &mailbox {
 	interrupts = <GIC_SPI 33 IRQ_TYPE_LEVEL_HIGH>;
 };

-- 
2.47.3

