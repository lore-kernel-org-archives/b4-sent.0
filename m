From: Rui Cao <i@udp0.com>
Subject: [PATCH 0/4] arm64: dts: mediatek: Add MT6833 and the Xiaomi Redmi
 Note 13 5G
Date: Sat, 07 Nov 2026 20:21:57 +0800
Message-Id: <20261107-mt6833-base-v1-0-bda21083e9f3@udp0.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/yXMSQ5AQBBA0atIrXWizVxFLIoulMSQLkQi7q6xf
 Iv/LxCyTAKld4Glg4WX2UH7HrQDzj0pNs4QBmGqdZCpaUvzKFINCqkEiyzGItFoDLhitdTx+d2
 q+rfszUjt9i7gvh/fuVIJbwAAAA==
X-Change-ID: 20261107-mt6833-base-5a974a951add
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Sean Wang <sean.wang@mediatek.com>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-watchdog@vger.kernel.org, linux-serial@vger.kernel.org, 
 Rui Cao <i@udp0.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794054121; l=2117;
 i=i@udp0.com; s=20261107; h=from:subject:message-id;
 bh=aGS5pwVEaByvAXqt5RgayabtH/SOiH8kdtd7Klwjx3s=;
 b=1Ef+pPWL5tiXhC1xG3VTSFRe9IKi9UQRAXxxLvvz8FXj16P5KIn7VvQ1IzbZXh1U2N1dweMXI
 R6sOBKFv/MoAncwkaq7CB2MSNLwEMFZKAJCRoBeVYUeBvpKIBC37t/U
X-Developer-Key: i=i@udp0.com; a=ed25519;
 pk=XZJKcKgnUUjjyw8KuKy7u2QeIX0JLY/L1Fxzwwje41w=
X-Endpoint-Received: by B4 Relay for i@udp0.com/20261107 with auth_id=1443
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds basic support for MediaTek's MT6833 (Dimensity 700) and
for the Xiaomi Redmi Note 13 5G (gold), which is built on it: the eight
cores with their caches and PMUs, PSCI, the architected timer, the GIC,
the watchdog and the first UART, and on the phone its memory, the
regions its bootloader reserves for firmware and the framebuffer the
bootloader leaves lit.

With it the phone boots to an initramfs on the framebuffer console, with
all eight cores online, both PMUs registered and the watchdog running;
UART0, which has no connector on gold, passes an internal loopback test.
The pin, clock and power domain controllers, the PMIC wrapper, UFS and
USB are to follow in later series.

On booting: gold's bootloader (LK) only starts a kernel with the stock
device tree and the dtbo it overlays on it, so I boot mainline through a
small shim in the boot image. Like a bootloader, the shim takes the
memory node and the reserved regions from the tree LK passes, which
depend on the RAM variant, and enters the kernel with this device tree
updated with them. The values written out in the board's device tree are
the ones LK reports on a 6 GB unit, the one this was tested on.

Signed-off-by: Rui Cao <i@udp0.com>
---
Rui Cao (4):
      dt-bindings: arm: mediatek: Add MT6833 and the Xiaomi Redmi Note 13 5G
      dt-bindings: watchdog: mediatek,mtk-wdt: Add MT6833
      dt-bindings: serial: mediatek,uart: Add MT6833
      arm64: dts: mediatek: Add MT6833 and the Xiaomi Redmi Note 13 5G

 .../devicetree/bindings/arm/mediatek.yaml          |   4 +
 .../devicetree/bindings/serial/mediatek,uart.yaml  |   1 +
 .../bindings/watchdog/mediatek,mtk-wdt.yaml        |   1 +
 arch/arm64/boot/dts/mediatek/Makefile              |   1 +
 .../arm64/boot/dts/mediatek/mt6833-xiaomi-gold.dts | 205 +++++++++++++
 arch/arm64/boot/dts/mediatek/mt6833.dtsi           | 341 +++++++++++++++++++++
 6 files changed, 553 insertions(+)
---
base-commit: d48723711bae9b8cdc56719c448ba42fef28cbee
change-id: 20261107-mt6833-base-5a974a951add

Best regards,
--  
Rui Cao <i@udp0.com>

