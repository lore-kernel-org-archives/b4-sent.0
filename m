From: Roman Vivchar <rva333@protonmail.com>
Subject: [PATCH 0/8] arm64: mediatek: initial support for mt6768
Date: Thu, 26 Nov 2026 14:39:53 +0200
Message-Id: <20261126-6768-init-v1-0-abc364a2447e@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ5AMBBA0avIrDXRUSWuIhZag7EoaRGJuLti+
 ZKff0EgzxSgTi7wdHDgxUXINAE7dW4kwX00YIZaStRCl7oS7HgTqkCjeoN5meUQ+9XTwOf3atr
 fYTcz2e0dwH0/cHtiXm0AAAA=
X-Change-ID: 20261126-6768-init-452b4db23703
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Sean Wang <sean.wang@mediatek.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Thomas Gleixner <tglx@kernel.org>, Radu Rendec <radu@rendec.net>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-serial@vger.kernel.org, linux-watchdog@vger.kernel.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795696875; l=1911;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=OuksRoDHKFpT/R8LxjmQb4PYxWFGU2toCTWUqRQ83nI=;
 b=M8pLRwIso+8rS6ShJtdTTZ8LXr45utWV3TwSmwDKcanvlFd8lSNaDtyAwkSlI9x8SUU2U0dwx
 or4OP3XkIa0Ahz+lp+/izRarO7wnUi18pqJzDcMEGt5RNvk2QYQ1y0h
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds basic support for the MediaTek mt6768 SoC and Xiaomi
Redmi Note 9 smartphone (codenamed "merlin").

The mt6768 is a 64-bit SoC featuring six Cortex-A55 and two Cortex-A75
cores, typically paired with LPDDR4X memory and found in low to mid range
phones.

This series requires custom TF-A and U-Boot forks, because the device
shipped with broken PSCI implementation and bootloader that pollutes dtb.
TF-A: https://github.com/mt6768-mainline/arm-trusted-firmware
U-Boot: https://github.com/mt6768-mainline/u-boot

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
Roman Vivchar (8):
      dt-bindings: arm: mediatek: add mt6768
      dt-bindings: serial: mediatek,uart: add mt6768
      dt-bindings: watchdog: mediatek,mtk-wdt: add mt6768
      dt-bindings: timer: mediatek,timer: add mt6768
      dt-bindings: interrupt-controller: mediatek,mt6577-sysirq: add mt6768
      watchdog: mediatek: add mt6768
      arm64: dts: mediatek: add initial mt6768 support
      arm64: dts: mediatek: mt6768: add Xiaomi Redmi Note 9 support

 .../devicetree/bindings/arm/mediatek.yaml          |   4 +
 .../mediatek,mt6577-sysirq.yaml                    |   1 +
 .../devicetree/bindings/serial/mediatek,uart.yaml  |   1 +
 .../devicetree/bindings/timer/mediatek,timer.yaml  |   1 +
 .../bindings/watchdog/mediatek,mtk-wdt.yaml        |   1 +
 arch/arm64/boot/dts/mediatek/Makefile              |   1 +
 .../boot/dts/mediatek/mt6768-xiaomi-merlin.dts     |  42 +++
 arch/arm64/boot/dts/mediatek/mt6768.dtsi           | 418 +++++++++++++++++++++
 drivers/watchdog/mtk_wdt.c                         |  22 ++
 include/dt-bindings/reset/mediatek,mt6768-wdt.h    |  19 +
 10 files changed, 510 insertions(+)
---
base-commit: 9437046953b2fb3bf55b36582450ea0267df82a7
change-id: 20261126-6768-init-452b4db23703

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

