From: Ben Grisdale <bengris32@protonmail.ch>
Subject: [PATCH 0/8] arm64: Initial support for MediaTek MT8163 SoC
Date: Mon, 19 Oct 2026 01:39:56 +0100
Message-Id: <20261019-arm64-initial-support-for-mediatek-mt8163-soc-v1-0-f2462b2d2437@protonmail.ch>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXNQQ7CIBBA0as0s3aSUislXsV0MYWpjkohQI1J0
 7uLunyb/zfInIQznJsNEr8kS1gq1KEBe6PlyiiuGrq206pVBil53aMsUoSemNcYQyo4h4SenVD
 hB/pilD5iDhaZTsb1g50GIqjNmHiW9+93Gf/O63RnW74T2PcPeljb5ZEAAAA=
X-Change-ID: 20261018-arm64-initial-support-for-mediatek-mt8163-soc-ea58d47cb7aa
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Sean Wang <sean.wang@mediatek.com>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-serial@vger.kernel.org, linux-watchdog@vger.kernel.org, 
 Ben Grisdale <bengris32@protonmail.ch>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792370441; l=2459;
 i=bengris32@protonmail.ch; s=20261018; h=from:subject:message-id;
 bh=thj8fkgUx0n2g+Qn+PTrOCu0LTjxGyRDrb52j8S8ekc=;
 b=i7OwJUkugOJE/D+2y+P+4fegBQ7NuLsKS335d+2Vi2ni8uBe4FdVhG0EnIbq72qaanzaK0SBo
 lNocYm3/9rMAQ7ClQ2xo2w5Yc2Rmgxz43NVeTj0SfrgeBg//XTWCMu1
X-Developer-Key: i=bengris32@protonmail.ch; a=ed25519;
 pk=4ewFRC2yNph/tXokHVzIDlgOA9Hxecf1AlBuD4eOnaU=
X-Endpoint-Received: by B4 Relay for bengris32@protonmail.ch/20261018 with auth_id=1233
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds basic support for the MediaTek MT8163 SoC.

The MT8163 is a 64-bit SoC featuring four ARM Cortex-A53 cores,
typically found in entry-level tablets and smart displays, such as
the Amazon Echo and Fire HD devices.

The bindings, SoC dtsi and watchdog support added here are enough to
boot the 2016 Amazon Echo Dot (biscuit) to a shell over UART0.

This series requires custom TF-A, U-Boot and OP-TEE ports for MT8163.
The stock vendor firmware does not provide a usable PSCI implementation
(the vendor kernel brings up secondary CPUs with a custom "mt-boot"
enable-method instead), and these ports also define the reserved memory
layout used by the board dts:
 - TF-A: https://github.com/iara-linux/arm-trusted-firmware
 - U-Boot: https://github.com/iara-linux/u-boot
 - OP-TEE: https://github.com/iara-linux/optee_os

This is the first of several series. Support for the remaining
peripherals will follow, starting with the clock controllers, pinctrl
and power domains.

Signed-off-by: Ben Grisdale <bengris32@protonmail.ch>
---
Ben Grisdale (8):
      dt-bindings: arm: mediatek: Add MT8163 Amazon Echo Dot (2016)
      dt-bindings: interrupt-controller: mediatek,mt6577-sysirq: Add MT8163
      dt-bindings: timer: mediatek,timer: Add MT8163
      dt-bindings: serial: mediatek,uart: Add MT8163
      dt-bindings: watchdog: mediatek,mtk-wdt: Add MT8163
      watchdog: mediatek: Add support for MT8163 TOPRGU/WDT
      arm64: dts: mediatek: Add basic support for MT8163 SoC
      arm64: dts: mediatek: Add Amazon Echo Dot (2016)

 .../devicetree/bindings/arm/mediatek.yaml          |   4 +
 .../mediatek,mt6577-sysirq.yaml                    |   1 +
 .../devicetree/bindings/serial/mediatek,uart.yaml  |   1 +
 .../devicetree/bindings/timer/mediatek,timer.yaml  |   1 +
 .../bindings/watchdog/mediatek,mtk-wdt.yaml        |   1 +
 arch/arm64/boot/dts/mediatek/Makefile              |   1 +
 .../boot/dts/mediatek/mt8163-amazon-biscuit.dts    |  68 ++++++
 arch/arm64/boot/dts/mediatek/mt8163.dtsi           | 243 +++++++++++++++++++++
 drivers/watchdog/mtk_wdt.c                         |   6 +
 include/dt-bindings/reset/mediatek,mt8163-wdt.h    |  23 ++
 10 files changed, 349 insertions(+)
---
base-commit: 2efb7a11f1aa4d2dc285fe2680cca22cb9f72f64
change-id: 20261018-arm64-initial-support-for-mediatek-mt8163-soc-ea58d47cb7aa

Best regards,
--  
Ben Grisdale <bengris32@protonmail.ch>

