From: Jia Wang <wangjia@ultrarisc.com>
Subject: [PATCH v2 00/10] riscv: Add device tree support for UltraRISC
 DP1000
Date: Mon, 07 Sep 2026 17:54:39 +0800
Message-Id: <20260907-ultrarisc-dts-v2-0-5eb4c97477c5@ultrarisc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOCJnmoC/12Q3U4DIRCFX2XDtRh+CiwbY3wP04sZmLUYt1Wgq
 6bpu0upMerlycx855w5sUI5UWHTcGKZ1lTSYd+EuhlY2MH+iXiKTTMllBVGKX58qRlyKoHHWri
 PgBqUlhYtazevmeb00XmP26suR3ymUC+Q741Mb8dmVK9rbKFSoBtNw1338cLx+L5A+OW2Ki64B
 +1xHiNqqR9+ZrfhsNx3NtSw6xwIXmtpJBrQIjrro9MWSVuHGxODjTI2EJrLFUIh3hBLqtMQZ+X
 F2BKECNqOKOQ8b7QTfjZy9EI4G4yVxrFLu10q9ZA/+/NW2cv0/KPa/PvTKlt6KwEdEJIn8zc92
 57P5y9vvEKZjAEAAA==
X-Change-ID: 20260522-ultrarisc-dts-9dab3a2316b6
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Jia Wang <wangjia@ultrarisc.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Thomas Gleixner <tglx@kernel.org>, 
 Samuel Holland <samuel.holland@sifive.com>, 
 Anup Patel <anup@brainfault.org>, Mark Brown <broonie@kernel.org>, 
 Andi Shyti <andi.shyti@kernel.org>, 
 Mika Westerberg <mika.westerberg@linux.intel.com>, 
 Eugeniy Paltsev <Eugeniy.Paltsev@synopsys.com>, 
 Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@sifive.com>, Conor Dooley <conor@kernel.org>, 
 linux-riscv@lists.infradead.org, linux-spi@vger.kernel.org, 
 linux-i2c@vger.kernel.org, dmaengine@vger.kernel.org, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788775103; l=6572;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=fs8d6nkh6D5RmIxH1uT+pAod8jqHIlEnS5dHbN7H6fI=;
 b=c33tukVmX93oP4g3h9Le0+lad+GXnTWwtk8+w9sK0qXF3luHh3Az/VxkVWq+KbB4u7uZTw2jd
 FkOBSxEHfmrA5jzgiXGtD20f7qmOJ/K/SCxhOLwIx2wptCxmA47T27T
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Devicetree support for the UltraRISC DP1000 RISC-V SoC and two
DP1000-based motherboards: Shenzhen Rongda M0 and Milk-V Titan.

DP1000 integrates eight UltraRISC CP100 CPU cores.  The SoC description
includes the CPU and cache topology, CLINT, PLIC, clock controller,
pinctrl, GPIO, four UARTs, two SPI controllers, four I2C controllers,
three PCIe root complexes, GMAC, and the DMA controller.

The Shenzhen Rongda M0 and Milk-V Titan device trees add their
board-specific pin multiplexing, RTC devices, and Ethernet PHY
configuration.  Both boards enable the three PCIe root complexes and
the GMAC described as disabled by default in the SoC DTS.  The Titan
description also provides its GPIO wakeup keys.

The binding patches add the vendor, CPU, board, and peripheral compatible
strings consumed by the new device trees.  The SPI, I2C, and AXI DMA nodes
use their respective generic DesignWare compatible strings as fallbacks.

An earlier version of the DP1000 SoC and board Devicetree support was
posted as part of a combined Devicetree and pinctrl series. The pinctrl
binding and driver were subsequently split out and merged separately.
This series carries the updated Devicetree portion.

Link: https://lore.kernel.org/all/20260515-ultrarisc-pinctrl-v1-0-bf559589ea8a@ultrarisc.com/

This series depends on the UltraRISC DP1000 GMAC support series:

net: stmmac: Add common RGMII delay handling and DP1000 support
https://lore.kernel.org/netdev/20260907-dwmac-ultrarisc-v2-0-9a39bf8db313@ultrarisc.com/

Testing:
- Built dp1000-shenrongda-m0.dtb and dp1000-milkv-titan.dtb with
  ARCH=riscv and W=1.
- Ran dt_binding_check for the modified bindings and the prerequisite
  DP1000 GMAC binding.
- Validated both DTBs against the relevant Devicetree schemas with
  CHECK_DTBS=y and the prerequisite GMAC series applied.
- Boot-tested both DTBs on Shenzhen Rongda M0 and Milk-V Titan. Verified
  the CPU topology and CBO selftests, UART, SPI, I2C/RTC, system memory,
  and all three PCIe root complexes. The expected PCIe endpoints were
  enumerated on both boards.
- With the prerequisite GMAC series applied, ultrarisc-dwmac established
  1000 Mb/s full-duplex links with the YT8531S PHY on M0 and the RTL8211F
  PHY on Titan.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
Changes in v2:
- Remove the dependency on the DP1000 clock series, which has since
  been merged.
- Drop the generic DWMAC compatible patch; DP1000 GMAC support is handled
  by a separate prerequisite series.
- Drop the RISC-V CPU binding yamllint fix, which has been applied.
- Add DP1000-specific resource constraints and hardware descriptions to
  the SPI, I2C and DMA bindings.
- Correct the native chip-select count of SPI1 from three to four.
- Describe all eight per-channel DMA interrupts.
- Update the DP1000 GMAC nodes for the separate GMAC support series:
  remove the generic DWMAC fallback, use "rgmii-id" for both boards, and
  clarify the fixed MAC-side RGMII delays.
- Link to v1: https://patch.msgid.link/20260824-ultrarisc-dts-v1-0-61ab7aebe9e5@ultrarisc.com

To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Paul Walmsley <pjw@kernel.org>
To: Palmer Dabbelt <palmer@dabbelt.com>
To: Albert Ou <aou@eecs.berkeley.edu>
To: Alexandre Ghiti <alex@ghiti.fr>
To: Jia Wang <wangjia@ultrarisc.com>
To: Daniel Lezcano <daniel.lezcano@kernel.org>
To: Thomas Gleixner <tglx@kernel.org>
To: Samuel Holland <samuel.holland@sifive.com>
To: Anup Patel <anup@brainfault.org>
To: Mark Brown <broonie@kernel.org>
To: Andi Shyti <andi.shyti@kernel.org>
To: Mika Westerberg <mika.westerberg@linux.intel.com>
To: Eugeniy Paltsev <Eugeniy.Paltsev@synopsys.com>
To: Vinod Koul <vkoul@kernel.org>
To: Frank Li <Frank.Li@kernel.org>
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: Paul Walmsley <paul.walmsley@sifive.com>
Cc: Palmer Dabbelt <palmer@sifive.com>
Cc: Conor Dooley <conor@kernel.org>
Cc: linux-riscv@lists.infradead.org
Cc: linux-spi@vger.kernel.org
Cc: linux-i2c@vger.kernel.org
Cc: dmaengine@vger.kernel.org

---
Jia Wang (10):
      dt-bindings: vendor-prefixes: Add shenrongda
      dt-bindings: riscv: cpus: Add UltraRISC CP100 compatible
      dt-bindings: riscv: Add UltraRISC DP1000 board compatibles
      dt-bindings: timer: Add UltraRISC DP1000 CLINT
      spi: dt-bindings: snps,dw-apb-ssi: Add compatible for UltraRISC DP1000 SoC
      dt-bindings: i2c: dw: Add compatible for UltraRISC DP1000 SoC
      dt-bindings: dma: snps,dw-axi-dmac: Add UltraRISC DP1000 compatible
      riscv: dts: ultrarisc: Add initial device tree for UltraRISC DP1000
      riscv: dts: ultrarisc: Add Shenzhen Rongda M0 board device tree
      riscv: dts: ultrarisc: Add Milk-V Titan board device tree

 .../devicetree/bindings/dma/snps,dw-axi-dmac.yaml  |  22 +
 .../bindings/i2c/snps,designware-i2c.yaml          |  15 +
 Documentation/devicetree/bindings/riscv/cpus.yaml  |   1 +
 .../devicetree/bindings/riscv/ultrarisc.yaml       |  27 +
 .../devicetree/bindings/spi/snps,dw-apb-ssi.yaml   |  16 +
 .../devicetree/bindings/timer/sifive,clint.yaml    |   1 +
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 MAINTAINERS                                        |   8 +
 arch/riscv/boot/dts/Makefile                       |   1 +
 arch/riscv/boot/dts/ultrarisc/Makefile             |   3 +
 .../dts/ultrarisc/dp1000-milkv-titan-pinctrl.dtsi  | 108 +++
 .../boot/dts/ultrarisc/dp1000-milkv-titan.dts      | 203 +++++
 arch/riscv/boot/dts/ultrarisc/dp1000-pinctrl.h     |  63 ++
 .../ultrarisc/dp1000-shenrongda-m0-pinctrl.dtsi    |  79 ++
 .../boot/dts/ultrarisc/dp1000-shenrongda-m0.dts    | 113 +++
 arch/riscv/boot/dts/ultrarisc/dp1000.dtsi          | 899 +++++++++++++++++++++
 16 files changed, 1561 insertions(+)
---
base-commit: df2908090cda368b01ff43709f51890076c56157
change-id: 20260522-ultrarisc-dts-9dab3a2316b6
prerequisite-message-id: <20260907-dwmac-ultrarisc-v2-0-9a39bf8db313@ultrarisc.com>
prerequisite-patch-id: 92e6cf1352d54e283d7721dc1542b580b8a41be1
prerequisite-patch-id: 875c2058e9d8a983d785d7447374758f994dc847
prerequisite-patch-id: 060a9b129c32c623a52ab1ba66f7a357e54575ff
prerequisite-patch-id: 9aafbac6d2531a378b2057bf57787c814523f9d3
prerequisite-patch-id: d75120a112276bd966d37441bd4d631e1539d0e8
prerequisite-patch-id: ac933151b5a30d769d736be367b45dc6d1d9bfb5

Best regards,
--  
Jia Wang <wangjia@ultrarisc.com>

