From: Rui Cao <i@udp0.com>
Subject: [PATCH v2 0/5] arm64: dts: mediatek: Add MT6833 and the Xiaomi
 Redmi Note 13 5G
Date: Tue, 17 Nov 2026 17:11:30 +0800
Message-Id: <20261117-mt6833-base-v2-0-058a0685c40c@udp0.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/22NyQ6CMBRFf4W8tTUdZFz5H4ZFh4fUBEra0mgI/
 27BrcuTnHvuBgG9xQBdsYHHZIN1cwZ+KUCPcn4isSYzcMorxmhNplg1QhAlA5JStvVNtiWTxkB
 eLB4H+z5rj/7HYVUv1PFIHMZoQ3T+c94ldnj/y4kRSpSRnNFGYDuI+2oWetVugn7f9y/pvGost
 wAAAA==
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
 phone-devel@vger.kernel.org, Roman Vivchar <rva333@protonmail.com>, 
 Rui Cao <i@udp0.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794906695; l=2718;
 i=i@udp0.com; s=20261107; h=from:subject:message-id;
 bh=p9Enb7h3tqAIEZP5EV7jwzS6FFKHn1F3hp4gOfUaNOE=;
 b=ZCG2NI3TkmszzT9x9HfEXZZVr5GvPIJPaaajISgwPtZYD3yCMGNkO6s5hVZrIaB+zCgu+/JGB
 HZf58BvKYzuAbWLz/2SN/XpiYskc7FXfGEsG5kOfmZe/P+0hVmGQadg
X-Developer-Key: i=i@udp0.com; a=ed25519;
 pk=XZJKcKgnUUjjyw8KuKy7u2QeIX0JLY/L1Fxzwwje41w=
X-Endpoint-Received: by B4 Relay for i@udp0.com/20261107 with auth_id=1443
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds basic support for MediaTek's MT6833 (Dimensity 700) and
for the Xiaomi Redmi Note 13 5G (gold), which is built on it: the eight
cores with their caches and PMUs, PSCI, the architected timer, the GIC,
the watchdog and the first UART, and on the phone the framebuffer its
bootloader leaves lit and a ramoops region.

With it the phone boots to an initramfs on the framebuffer console, with
all eight cores online, both PMUs registered and the watchdog running;
UART0, which has no connector on gold, passes an internal loopback test.
The pin, clock and power domain controllers, the PMIC wrapper, UFS and
USB are to follow in later series.

Stock LK cannot boot a mainline DT directly, as its DT overlay step
expects vendor nodes. As on other MediaTek phones, this DT relies on
the bootloader (tested with kaeru, an open-source LK payload) to fill
in /memory and copy the firmware carveouts into /reserved-memory from
the FDT prepared by LK.

The watchdog gets a compatible of its own in v2, which the driver
matches in patch 3; the watchdog node in patch 5 needs that patch to
probe.

Signed-off-by: Rui Cao <i@udp0.com>
---
Changes in v2:
- Make mediatek,mt6833-wdt a compatible of its own instead of falling
  back to mediatek,mt6589-wdt, whose TOPRGU resets MT6833 doesn't share,
  and match it in mtk_wdt.c without reset data (Roman)
- dts: leave the memory size to the bootloader, and keep only ramoops
  and the framebuffer in reserved-memory (Roman)
- Collect Roman's Reviewed-by and Krzysztof's Acked-by tags on the arm
  and serial bindings
- Drop Krzysztof's Acked-by from the watchdog binding, which changed
- Link to v1: https://patch.msgid.link/20261107-mt6833-base-v1-0-bda21083e9f3@udp0.com

---
Rui Cao (5):
      dt-bindings: arm: mediatek: Add MT6833 and the Xiaomi Redmi Note 13 5G
      dt-bindings: watchdog: mediatek,mtk-wdt: Add MT6833
      watchdog: mediatek: Add MT6833
      dt-bindings: serial: mediatek,uart: Add MT6833
      arm64: dts: mediatek: Add MT6833 and the Xiaomi Redmi Note 13 5G

 .../devicetree/bindings/arm/mediatek.yaml          |   4 +
 .../devicetree/bindings/serial/mediatek,uart.yaml  |   1 +
 .../bindings/watchdog/mediatek,mtk-wdt.yaml        |   1 +
 arch/arm64/boot/dts/mediatek/Makefile              |   1 +
 .../arm64/boot/dts/mediatek/mt6833-xiaomi-gold.dts |  57 ++++
 arch/arm64/boot/dts/mediatek/mt6833.dtsi           | 341 +++++++++++++++++++++
 drivers/watchdog/mtk_wdt.c                         |   1 +
 7 files changed, 406 insertions(+)
---
base-commit: d48723711bae9b8cdc56719c448ba42fef28cbee
change-id: 20261107-mt6833-base-5a974a951add

Best regards,
--  
Rui Cao <i@udp0.com>

