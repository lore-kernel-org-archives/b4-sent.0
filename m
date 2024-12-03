From: Janne Grunau <j@jannau.net>
Subject: [PATCH v2 0/5] Add Apple SPI controller and spi-nor dt nodes
Date: Tue, 03 Dec 2024 08:57:56 +0100
Message-Id: <20241203-asahi-spi-dt-v2-0-cd68bfaf0c84@jannau.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAS6TmcC/1XMQQ6CMBCF4auQWTumrSWiK+5hWAxlkHFRSIuNh
 vTuVhIXLv+XvG+DyEE4wrXaIHCSKLMvYQ4VuIn8nVGG0mCUsVorjRRpEoyL4LBi3Rhb970e6MR
 QLkvgUV47d+tKTxLXObx3Penv+oPMP5Q0KjyTs9Ypaprx0j7Ie3oePa/Q5Zw/IzMp36kAAAA=
X-Change-ID: 20241101-asahi-spi-dt-58245bb1da3e
To: Hector Martin <marcan@marcan.st>, Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2988; i=j@jannau.net;
 s=yk2024; h=from:subject:message-id;
 bh=38p7GC9R1as6v+LwylJU+xoFYW0MlJUbCVhahYq60k0=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhnS/XVx8XB/sTvDsaRLr+iK/Suegj9iJztcWOsxvK+x27
 D86/8jtjlIWBjEuBlkxRZYk7ZcdDKtrFGNqH4TBzGFlAhnCwMUpABORX8bw30W1lDOg+3Gy3CPu
 vw/D46uTHhxYdPGBLXd2sVeXtcnBXQz/S+z2MiqWmTl371rHnNT+ikHccNOBi31u7JEtl77tWtT
 CBgA=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/yk2024 with auth_id=264
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds SPI controller and SPI NOR flash device nodes to the
man Apple silicon SoC dts files. Only the subset of used SPI controllers
is added. Five SPI controllers exists according to pmgr ADT data but the
commits only add controllers found in use on any of the devices. The
parameters for the missing nodes are guessable but there's no point in
adding them since no further M1 or M2 devices are expected.
Together with controller nodes the first SPI device is added. All Apple
silicon devices connect a SPI NOR flash to spi1. This holds Apple's 1st
stage bootloader, firmwares, platform and machine specific config data
and a writeable key-value store (nvram). Expose only the nvram as mtd
partition since it has use beyond exploring the content. Tools from
asahi-nvram [1] can modify the (default) boot configuration
(asahi-bless), read Bluetooth sync keys (asahi-btsync) and read and
write arbitrary keys (asahi-nvram).

Devicetree bindings are included in the driver series. Last version at
https://lore.kernel.org/linux-devicetree/20241101-asahi-spi-v3-0-3b411c5fb8e5@jannau.net/

This series passes `make CHECK_DTBS=1 dtbs` with the spi bindings except
for "local-mac-address" for the Bluetooth device (I need get back to
this).

[1] https://github.com/WhatAmISupposedToPutHere/asahi-nvram/

Signed-off-by: Janne Grunau <j@jannau.net>
---
Changes in v2:
- added spi0 pins from https://lore.kernel.org/asahi/969b7440-5173-4ecc-af31-c3cd1f3f5acf@marcan.st/
- rebased onto v6.13-rc1
- added Neal's Rb:
- Link to v1: https://lore.kernel.org/r/20241102-asahi-spi-dt-v1-0-7ac44c0a88f9@jannau.net
              https://lore.kernel.org/r/20241127-asahi-spi-dt-v1-0-907c9447f623@jannau.net

---
Hector Martin (1):
      arm64: dts: apple: t8103: Fix spi4 power domain sort order

Janne Grunau (4):
      arm64: dts: apple: t8103: Add spi controller nodes
      arm64: dts: apple: t8112: Add spi controller nodes
      arm64: dts: apple: t600x: Add spi controller nodes
      arm64: dts: apple: Add SPI NOR nvram partition to all devices

 arch/arm64/boot/dts/apple/spi1-nvram.dtsi      | 39 +++++++++++++
 arch/arm64/boot/dts/apple/t600x-common.dtsi    |  7 +++
 arch/arm64/boot/dts/apple/t600x-die0.dtsi      | 28 ++++++++++
 arch/arm64/boot/dts/apple/t600x-gpio-pins.dtsi | 14 +++++
 arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi |  2 +
 arch/arm64/boot/dts/apple/t600x-j375.dtsi      |  2 +
 arch/arm64/boot/dts/apple/t8103-jxxx.dtsi      |  2 +
 arch/arm64/boot/dts/apple/t8103-pmgr.dtsi      | 18 +++---
 arch/arm64/boot/dts/apple/t8103.dtsi           | 76 ++++++++++++++++++++++++++
 arch/arm64/boot/dts/apple/t8112-jxxx.dtsi      |  2 +
 arch/arm64/boot/dts/apple/t8112.dtsi           | 44 ++++++++++++++-
 11 files changed, 224 insertions(+), 10 deletions(-)
---
base-commit: 40384c840ea1944d7c5a392e8975ed088ecf0b37
change-id: 20241101-asahi-spi-dt-58245bb1da3e

Best regards,
-- 
Janne Grunau <j@jannau.net>

