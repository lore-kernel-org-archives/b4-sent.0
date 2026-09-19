From: Nicolo Giuliani <nicolo.giuliani6@studio.unibo.it>
Subject: [PATCH 0/3] arm64: dts: marvell: Add Sophos XGS 107w NPU
Date: Sat, 19 Sep 2026 21:44:16 +0200
Message-Id: <20260919-send-dt-v1-0-365615a74ef3@studio.unibo.it>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABDmrmoC/yXMyw5AMBCF4VeRWWtSjbi9ili0ZjAWJR1EIt5ds
 fyS/5wLhAKTQJNcEOhg4cVHZGkC/WT9SIoxGow2ha6zWgl5VLipwjnUlc1LjQZivQYa+Pye2u6
 37G6mfnvncN8Pa32lp2sAAAA=
X-Change-ID: 20260919-send-dt-6bbd08a470d2
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Lunn <andrew@lunn.ch>, 
 Gregory Clement <gregory.clement@bootlin.com>, 
 Sebastian Hesselbarth <sebastian.hesselbarth@gmail.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Nicolo Giuliani <nicolo.giuliani6@studio.unibo.it>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789847056; l=2324;
 i=nicolo.giuliani6@studio.unibo.it; s=20260919; h=from:subject:message-id;
 bh=jN/xuLLWQ0ENNdxly/LSIJeQTI5L1wucNlyu8/3PGvQ=;
 b=kF2s2/YeaYZ1CM7tARbZ5N2d9Es+LHHwr6izOEkX3j/au1XGeuQjHgcgk6MQ6+Kb4u7qZaqGy
 YhZM/MnpVpGBQ102hDH2Y0PuLwtiPWljNEVU5qXc9b5S4nvI+unVrLb
X-Developer-Key: i=nicolo.giuliani6@studio.unibo.it; a=ed25519;
 pk=D652ecdT01GkA1eoFWNFNX85xIg5ZnFwUWyjfestgQw=
X-Endpoint-Received: by B4 Relay for nicolo.giuliani6@studio.unibo.it/20260919 with auth_id=1040
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Sophos XGS 87/107 desktop firewalls pair an AMD x86 host with a
separate network processing unit (NPU): a Marvell Armada CN9130 SoC with
its own eMMC and SPI NOR flash. The NPU serves the eight RJ45 ports and
the SFP cage through a Marvell 88E6193X switch on its MDIO bus, which is
connected to the SoC by a 10GBASE-R link, and reaches the x86 host over
PCIe.

This series adds the Sophos vendor prefix, the compatible string of the
NPU board and a device tree that describes the NPU as a standalone system:
UART console, eMMC, SPI NOR flash, the PCA9555 GPIO expander of the port
LEDs, the SFP cage and the switch with its ports. The LEDs, the USB ports
and the PCIe link to the x86 host (the CN9130 acts as a PCIe endpoint
towards it, which needs endpoint support that is not part of this series)
are not described.

The reset line of the switch is not passed to the mv88e6xxx driver as
reset-gpios, because the 88E6193X needs about two seconds after a reset,
much longer than the driver waits. The boot loader resets it instead.
The details are in patch 3.

Tested on an XGS 107w with Linux 6.18: boot from eMMC, eMMC and SPI NOR
access, the mvpp2 link to the switch at 10 Gb/s, the 88E6193X probing with
its eight user ports, and 936 Mbit/s through a front port. The SFP cage
and the PCA9555 outputs are untested.

dt_binding_check passes for vendor-prefixes.yaml and armada-7k-8k.yaml,
and CHECK_DTBS=y on marvell/cn9130-sophos-xgs107w.dtb reports no warning
specific to this board.

Based on the mvebu/dt branch of the mvebu tree (008e9faade).

Signed-off-by: Nicolo Giuliani <nicolo.giuliani6@studio.unibo.it>
---
Nicolo Giuliani (3):
      dt-bindings: vendor-prefixes: Add Sophos
      dt-bindings: arm: marvell: Add Sophos XGS 107w NPU
      arm64: dts: marvell: Add Sophos XGS 107w NPU board

 .../bindings/arm/marvell/armada-7k-8k.yaml         |   9 +
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 arch/arm64/boot/dts/marvell/Makefile               |   1 +
 .../boot/dts/marvell/cn9130-sophos-xgs107w.dts     | 209 +++++++++++++++++++++
 4 files changed, 221 insertions(+)
---
base-commit: 008e9faadef8c0aaa9b8a3ff05a2126e3c5b08b7
change-id: 20260919-send-dt-6bbd08a470d2

Best regards,
--  
Nicolo Giuliani <nicolo.giuliani6@studio.unibo.it>

