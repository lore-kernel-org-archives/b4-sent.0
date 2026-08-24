From: Jia Wang <wangjia@ultrarisc.com>
Subject: [PATCH 00/12] riscv: Add device tree support for UltraRISC DP1000
Date: Mon, 24 Aug 2026 13:54:13 +0800
Message-Id: <20260824-ultrarisc-dts-v1-0-61ab7aebe9e5@ultrarisc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIXci2oC/22Nyw6DIBQFf8WwLgmCgPorjYsLXFtaHy2gaWL89
 2pt0k2Xk5wzs5CIwWMkdbaQgLOPfhw2yE8ZsVcYLki925hwxhWTnNOpSwGCj5a6FGnlwAjgIld
 Gke3zCNj618d3bg6Ok7mhTbvkuwj4nLZQOma/Tp39qdhutHcKudEAsmoVM/Vc7CIDEakd+96nO
 iuE5KYExKpkTJZSACjRSu2U0JqX3GGuQYiWNOv6BtIRknj0AAAA
X-Change-ID: 20260522-ultrarisc-dts-9dab3a2316b6
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Thomas Gleixner <tglx@kernel.org>, 
 Samuel Holland <samuel.holland@sifive.com>, 
 Anup Patel <anup@brainfault.org>, Mark Brown <broonie@kernel.org>, 
 Andi Shyti <andi.shyti@kernel.org>, 
 Mika Westerberg <mika.westerberg@linux.intel.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Giuseppe Cavallaro <peppe.cavallaro@st.com>, 
 Jose Abreu <joabreu@synopsys.com>, 
 Eugeniy Paltsev <Eugeniy.Paltsev@synopsys.com>, 
 Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>
Cc: Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@sifive.com>, Conor Dooley <conor@kernel.org>, 
 devicetree@vger.kernel.org, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-spi@vger.kernel.org, 
 linux-i2c@vger.kernel.org, netdev@vger.kernel.org, 
 dmaengine@vger.kernel.org, Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787552108; l=4470;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=0/Xzhe2w9Sk25MhwhUaru7RZxcbtsKDtkT59/Di0x8U=;
 b=muAC+VMha9vnX4vL4gDakTbk8VFQlQQhKDwQGjzBj7GfU6pvTzZXdrQ5kUQKMiW2JcExPOqSO
 EhlHFWHWBomAbCbQ3MnlJ5UsptqgsPUWV8cJfCN49tMU0XuTPJCsT6R
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

The binding patches add the vendor, CPU, board, and peripheral
compatible strings consumed by the new device trees.  The SPI, I2C,
GMAC, and AXI DMA nodes use their respective generic DesignWare
compatible strings as fallbacks.

An earlier version of the DP1000 SoC and board Devicetree support was
posted as part of a combined Devicetree and pinctrl series. The pinctrl
binding and driver were subsequently split out and merged separately.
This series carries the updated Devicetree portion.

Link: https://lore.kernel.org/all/20260515-ultrarisc-pinctrl-v1-0-bf559589ea8a@ultrarisc.com/

This series depends on the UltraRISC DP1000 clock controller series:

clk: ultrarisc: add DP1000 clock support
https://patch.msgid.link/20260720-ultrarisc-clock-v4-0-fe639d63bbac@ultrarisc.com

Testing:
- Built dp1000-shenrongda-m0.dtb and dp1000-milkv-titan.dtb with
  ARCH=riscv and W=1.
- Ran dt_binding_check for the modified and prerequisite bindings.
- Validated both DTBs against the relevant Devicetree schemas with
  CHECK_DTBS=y.
- Boot-tested both DTBs on Shenzhen Rongda M0 and Milk-V Titan. Verified
  the CPU topology and CBO selftests, UART, SPI, I2C/RTC, Ethernet, system
  memory, and all three PCIe root complexes. The expected PCIe endpoints
  were enumerated on both boards.

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
Jia Wang (12):
      dt-bindings: riscv: cpus: Fix yamllint style issues
      dt-bindings: vendor-prefixes: Add shenrongda
      dt-bindings: riscv: cpus: Add UltraRISC CP100 compatible
      dt-bindings: riscv: Add UltraRISC DP1000 board compatibles
      dt-bindings: timer: Add UltraRISC DP1000 CLINT
      spi: dt-bindings: snps,dw-apb-ssi: Add compatible for UltraRISC DP1000 SoC
      dt-bindings: i2c: dw: Add compatible for UltraRISC DP1000 SoC
      dt-bindings: net: snps,dwmac: Add compatible for UltraRISC DP1000 SoC
      dt-bindings: dma: snps,dw-axi-dmac: Add UltraRISC DP1000 compatible
      riscv: dts: ultrarisc: Add initial device tree for UltraRISC DP1000
      riscv: dts: ultrarisc: Add Shenzhen Rongda M0 board device tree
      riscv: dts: ultrarisc: Add Milk-V Titan board device tree

 .../devicetree/bindings/dma/snps,dw-axi-dmac.yaml  |   1 +
 .../bindings/i2c/snps,designware-i2c.yaml          |   1 +
 .../devicetree/bindings/net/snps,dwmac.yaml        |   1 +
 Documentation/devicetree/bindings/riscv/cpus.yaml  |   9 +-
 .../devicetree/bindings/riscv/ultrarisc.yaml       |  27 +
 .../devicetree/bindings/spi/snps,dw-apb-ssi.yaml   |   1 +
 .../devicetree/bindings/timer/sifive,clint.yaml    |   1 +
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 MAINTAINERS                                        |   8 +
 arch/riscv/boot/dts/Makefile                       |   1 +
 arch/riscv/boot/dts/ultrarisc/Makefile             |   3 +
 .../dts/ultrarisc/dp1000-milkv-titan-pinctrl.dtsi  | 108 +++
 .../boot/dts/ultrarisc/dp1000-milkv-titan.dts      | 203 +++++
 arch/riscv/boot/dts/ultrarisc/dp1000-pinctrl.h     |  63 ++
 .../ultrarisc/dp1000-shenrongda-m0-pinctrl.dtsi    |  79 ++
 .../boot/dts/ultrarisc/dp1000-shenrongda-m0.dts    | 114 +++
 arch/riscv/boot/dts/ultrarisc/dp1000.dtsi          | 899 +++++++++++++++++++++
 17 files changed, 1517 insertions(+), 4 deletions(-)
---
base-commit: 4352b8aee98005853aa63f57d6377282de17a33f
change-id: 20260522-ultrarisc-dts-9dab3a2316b6
prerequisite-change-id: 20260522-ultrarisc-clock-a1b7aa59f60b:v4
prerequisite-patch-id: 9dc814b858bc1cf4736cc54bb85c26e9ca89eb59
prerequisite-patch-id: 4b2811f1845e86731e887f66fd31978b72885f37
prerequisite-patch-id: 37ec1006cbead8c4eef7e3c8f146fabab5875edf

Best regards,
--  
Jia Wang <wangjia@ultrarisc.com>

