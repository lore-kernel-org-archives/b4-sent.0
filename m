From: Xincheng Ji <jixincheng@ultrarisc.com>
Subject: [PATCH v4 0/7] riscv: Add device tree support for UltraRISC DP1000
Date: Mon, 19 Oct 2026 15:55:24 +0800
Message-Id: <20261019-ultrarisc-dts-v4-0-3979747cda2e@ultrarisc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOzM1WoC/22QzU7DMBCEX6XKGSN7/RdXCPEeiMOuvaZBpIU4D
 aCq707iokIrjqPd+UYzh6bw0HFp1qtDM/DUlW63nYW5WTVxg9tnFl2adQMSnLQAYv86Djh0JYo
 0FhESkkbQypFrZs/bwLn7rLzHp5Mue3rhOC6Qn4+B3/dz0Hh6a3ouBWvQenVXc4L0In30GP+kT
 SCkCKgD5TaRVvrhfLuNu/6+snGMm8rJFlzSjhUaTORswFZBTkYZmyICu0AqGKsvXT5ZViBba9y
 cgdoslCCNjw5IW59bb3JQvLgIC4s5uO/G2SiNNjKrmGSKnFsITA6yJdMiB4sQWXlKuVk22XRl3
 A1fdfJJ1Qlq6xbM1bqTmjs7heSRiQPby86VNsEvYdntirCsZplMDN54H/8l6DNBSaWvCXoh5Ky
 ZCDDIdE04Ho/f5ljb3kYCAAA=
X-Change-ID: 20260522-ultrarisc-dts-9dab3a2316b6
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Andrew Lunn <andrew@lunn.ch>, 
 Jia Wang <wangjia@ultrarisc.com>, Xincheng Ji <jixincheng@ultrarisc.com>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Thomas Gleixner <tglx@kernel.org>, 
 Samuel Holland <samuel.holland@sifive.com>, 
 Anup Patel <anup@brainfault.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@sifive.com>, Conor Dooley <conor@kernel.org>, 
 linux-riscv@lists.infradead.org, Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.17-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792396528; l=6883;
 i=jixincheng@ultrarisc.com; s=20260922; h=from:subject:message-id;
 bh=+nT7KOC1mA/+B52t8Q9NW+6NXgbrsKgj1sPJsTbwq9E=;
 b=6lX0A3fyChdO2fcbKPvOTpQAWP75GV+/Sm+4uMNIn2VFoKqCy1r6V1XBhy9V7GHJKx9ce3Z5v
 lRW2waUBOiYDVM3egyui5ngqcVNccz3eDBmaiAr/wLYXRljd8QAW3gQ
X-Developer-Key: i=jixincheng@ultrarisc.com; a=ed25519;
 pk=n848dcS5D6g0vLad/rjp4Gf/1eedTe1a3pYUrkt2260=
X-Endpoint-Received: by B4 Relay for jixincheng@ultrarisc.com/20260922 with auth_id=1046
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

The following prerequisites have been applied to their respective
subsystem trees but are not yet included in the base:

- net: stmmac: Add common internal RGMII delay handling and DP1000 support
  https://lore.kernel.org/netdev/20260907-dwmac-ultrarisc-v2-0-9a39bf8db313@ultrarisc.com/

- dt-bindings: i2c: dw: Add compatible for UltraRISC DP1000 SoC
  https://patch.msgid.link/20260907-ultrarisc-dts-v2-6-5eb4c97477c5@ultrarisc.com

- dt-bindings: dma: snps,dw-axi-dmac: Add UltraRISC DP1000 compatible
  https://patch.msgid.link/20260907-ultrarisc-dts-v2-7-5eb4c97477c5@ultrarisc.com

Testing:
- Built dp1000-shenrongda-m0.dtb and dp1000-milkv-titan.dtb with
  ARCH=riscv and W=1.
- Ran dt_binding_check for the modified and prerequisite bindings.
- Validated both DTBs against the relevant Devicetree schemas with
  CHECK_DTBS=y and all prerequisite changes applied.
- Boot-tested both DTBs on Shenzhen Rongda M0 and Milk-V Titan. Verified
  the CPU topology and CBO selftests, UART, SPI, I2C/RTC, system memory,
  and all three PCIe root complexes. The expected PCIe endpoints were
  enumerated on both boards.
- With the prerequisite GMAC series applied, ultrarisc-dwmac established
  1000 Mb/s full-duplex links with the YT8531S PHY on M0 and the RTL8211F
  PHY on Titan.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
Signed-off-by: Xincheng Ji <jixincheng@ultrarisc.com>
---
Changes in v4:
- Move L2 cache nodes out of the CPU nodes and reference them using
  next-level-cache, following the standard Devicetree cache topology.
- Link to v3: https://patch.msgid.link/20261013-ultrarisc-dts-v3-0-5ff3ebb2a90d@ultrarisc.com

Changes in v3:
- Drop the DP1000 SPI binding patch, which has been merged, and the I2C
  and DMA binding patches, which have been applied.
- Correct the reg property address ranges and sizes for DMA and I2C nodes in the DP1000 base device tree.
- Link to v2: https://patch.msgid.link/20260907-ultrarisc-dts-v2-0-5eb4c97477c5@ultrarisc.com

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
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: Paul Walmsley <paul.walmsley@sifive.com>
Cc: Palmer Dabbelt <palmer@sifive.com>
Cc: Conor Dooley <conor@kernel.org>
Cc: linux-riscv@lists.infradead.org

---
Jia Wang (7):
      dt-bindings: vendor-prefixes: Add shenrongda
      dt-bindings: riscv: cpus: Add UltraRISC CP100 compatible
      dt-bindings: riscv: Add UltraRISC DP1000 board compatibles
      dt-bindings: timer: Add UltraRISC DP1000 CLINT
      riscv: dts: ultrarisc: Add initial device tree for UltraRISC DP1000
      riscv: dts: ultrarisc: Add Shenzhen Rongda M0 board device tree
      riscv: dts: ultrarisc: Add Milk-V Titan board device tree

 Documentation/devicetree/bindings/riscv/cpus.yaml  |   1 +
 .../devicetree/bindings/riscv/ultrarisc.yaml       |  27 +
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
 arch/riscv/boot/dts/ultrarisc/dp1000.dtsi          | 865 +++++++++++++++++++++
 13 files changed, 1474 insertions(+)
---
base-commit: 704340f1cd0dcef829eb62f5b48ae95a2ce17bdf
change-id: 20260522-ultrarisc-dts-9dab3a2316b6
prerequisite-message-id: <20260907-dwmac-ultrarisc-v2-0-9a39bf8db313@ultrarisc.com>
prerequisite-patch-id: 92e6cf1352d54e283d7721dc1542b580b8a41be1
prerequisite-patch-id: 875c2058e9d8a983d785d7447374758f994dc847
prerequisite-patch-id: 060a9b129c32c623a52ab1ba66f7a357e54575ff
prerequisite-patch-id: 9aafbac6d2531a378b2057bf57787c814523f9d3
prerequisite-patch-id: d75120a112276bd966d37441bd4d631e1539d0e8
prerequisite-patch-id: f526d36e1a4adb659a812fd4145dca2e69b19453
prerequisite-patch-id: 7d5e12085468dba34526d9047c62b357f874f91e

Best regards,
--  
Xincheng Ji <jixincheng@ultrarisc.com>

