From: =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
Subject: [PATCH 0/4] spi: dt-bindings: bcm2835-spi, ARM: dts: bcm2711: Add
 DMA to spi0, i2s and sdhost
Date: Fri, 27 Nov 2026 16:21:05 +0100
Message-Id: <20261127-bcm2835-spi-dma-v1-0-8b134991ba2e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAOGfCWsC/yXMywqDQAxA0V+RrBuYTOuD/kpxMY+oKWhlokUQ/
 91pXZ7FvTsoJ2GFZ7FD4q+ofKYMuhUQBjf1jBKzwRpbEVlCH0bb3EvUWTCODr03DcfKUP1wkKs
 5cSfb//hqL+vq3xyW3waO4wTZQaGdcwAAAA==
X-Change-ID: 20261121-bcm2835-spi-dma-bb08ed60174a
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795792928; l=2083;
 i=cleverline1mc@gmail.com; s=20261121; h=from:subject:message-id;
 bh=GPAK2NN455l9SD+f8GSczRZqWij+l+kvBXDhsd9fwxQ=;
 b=vvKn9I4Hb52gOfCftXc+IgXPHf5l8Ol8880tjxh574m4hCmWVSNxE/N128JXpFPkR51lsl46i
 Ed3jpXibhG9AvJZYKcBQiX0J5oo2iiWk6ToQs2s3uqTswf36tBR6bMm
X-Developer-Key: i=cleverline1mc@gmail.com; a=ed25519;
 pk=2UEUVmQyfsiFZkNS7dkgFg0rUmhbcMIytM6NYhxFt/Y=
X-Endpoint-Received: by B4 Relay for cleverline1mc@gmail.com/20261121 with auth_id=1594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

I'm moving Unipi devices from the Raspberry Pi downstream kernel
to the CIP kernel and plan to upstream the gaps I find along the way.
This is the first of them.

On BCM2711 (Raspberry Pi 4, CM4), spi0, i2s and sdhost have no DMA
channels in the device tree, although the same controllers get them on
BCM2835/6/7 from bcm2835-common.dtsi. spi0 then runs in PIO mode, and
i2s, which has no PIO fallback, doesn't work.

Patch 1 documents dmas and dma-names in the bcm2835-spi binding. The
driver already requests them and bcm2835-common.dtsi already sets them;
dtbs_check doesn't flag that only because no in-tree board enables
spi0. The i2s and sdhost bindings already describe their channels.

Patches 2-4 add the dmas to bcm2711.dtsi, one controller per patch, so
each can be applied or reverted on its own. spi0 and i2s were tested on
a Raspberry Pi 4 B; sdhost only for probe and DMA binding, because
nothing on that board is wired to its pins.

Patch 1 is for the SPI tree, patches 2-4 for the Broadcom SoC tree.
There is no build dependency: without patch 1, patch 2 only adds a
dtbs_check warning for boards that enable spi0.

Checked with dt_binding_check for brcm,bcm2835-spi.yaml and with
dtbs_check on arm and arm64 (bcm2711-rpi-4-b, bcm2711-rpi-400,
bcm2711-rpi-cm4-io, and on arm also bcm2837-rpi-3-b and bcm2835-rpi-b):
no warnings.

An AI assistant (Claude) helped write the commit messages and this
cover letter.

---
Kryštof Černý (4):
      spi: dt-bindings: brcm,bcm2835-spi: Add dmas and dma-names
      ARM: dts: broadcom: bcm2711: Add DMA to spi0
      ARM: dts: broadcom: bcm2711: Add DMA to i2s
      ARM: dts: broadcom: bcm2711: Add DMA to sdhost

 Documentation/devicetree/bindings/spi/brcm,bcm2835-spi.yaml | 12 ++++++++++++
 arch/arm/boot/dts/broadcom/bcm2711.dtsi                     |  9 +++++++++
 2 files changed, 21 insertions(+)
---
base-commit: 909ef7a9a30fa139e69e555e3606680f5cca7726
change-id: 20261121-bcm2835-spi-dma-bb08ed60174a

Best regards,
--  
Kryštof Černý <cleverline1mc@gmail.com>

