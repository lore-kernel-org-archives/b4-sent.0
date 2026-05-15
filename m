From: Jia Wang <wangjia@ultrarisc.com>
Subject: [PATCH 0/9] riscv: ultrarisc: add DP1000 SoC DT and pinctrl
 support
Date: Fri, 15 May 2026 09:17:56 +0800
Message-Id: <20260515-ultrarisc-pinctrl-v1-0-bf559589ea8a@ultrarisc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAER0BmoC/yXMQQqEMAxA0atI1hZqlSJzlcFFjVEj0pGkiiDe3
 c7M8i3+v0BJmBRexQVCByt/YkZVFoBziBMZHrLBWedtXXmzr0mCsKLZOGKS1dAYPLkGm9bWkLt
 NaOTz93x3f+veL4TpO4L7fgAwkAmRdQAAAA==
X-Change-ID: 20260316-ultrarisc-pinctrl-efa6e24c4803
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Samuel Holland <samuel.holland@sifive.com>
Cc: Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@sifive.com>, Conor Dooley <conor@kernel.org>, 
 devicetree@vger.kernel.org, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-gpio@vger.kernel.org, 
 Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778807890; l=3939;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=CIzqu3iSXQE7WxLBaG2FjLAc8gxifDDaK5d1TURsWzw=;
 b=Dc3d8WwB4MLDtzdPDDLY4xc9u1QECszdJWuus/oTWcJL6qCseT8wQhfxrgPWTLdMqoNvJ2MJ9
 GoaIZaZQjVpC7juOougB38kb6ZoCx5T2PubrnD9nuZnupQ/FfpHQfw3
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds initial Devicetree support for the UltraRISC DP1000 RISC-V
SoC and two DP1000-based boards (Milk-V Titan and Rongda M0).

The series introduces the required DT bindings, adds the DP1000 pinctrl
driver, and provides the initial SoC/board DTS files.

Notes:
  - Clocks are configured and enabled by firmware before Linux boots. Linux
    does not manage clock rates or gating at runtime on this platform.
    Therefore the initial DT only models the fixed clocks required by
    standard drivers, and no clock controller/driver is provided.
  - The DP1000 pinctrl binding supports two child node styles under the same
    controller compatible:
      * legacy DP1000-specific nodes using phandle-array properties
        "pinctrl-pins" and "pinconf-pins"
      * generic pinctrl nodes using "pins", "function" and generic pin
        configuration properties
    The legacy form is kept for compatibility with existing vendor DTs.
  - The bindings for "ultrarisc,dp1000-uart" and "ultrarisc,dp1000-pcie" are
    being reviewed in separate series, since the DP1000 SoC DTS introduced
    here uses those compatibles:
    * Link: https://lore.kernel.org/lkml/20260429-ultrarisc-serial-v7-3-e475cce9e274@ultrarisc.com/
    * Link: https://lore.kernel.org/lkml/20260427-ultrarisc-pcie-v4-2-98935f6cdfb5@ultrarisc.com/
  - ARCH_ULTRARISC support is being reviewed separately:
    * Link: https://lore.kernel.org/lkml/20260427-ultrarisc-pcie-v4-1-98935f6cdfb5@ultrarisc.com/

Testing:
  - dt_binding_check and yamllint (all new/modified binding YAMLs)
  - dtbs_check and dtbs (RISC-V, including dp1000-milkv-titan.dtb and
    dp1000-rongda-m0.dtb)
  - Kernel build for RISC-V and boot-tested on DP1000 (Milk-V Titan and
    Rongda M0)

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
Jia Wang (9):
      dt-bindings: vendor-prefixes: add Rongda
      dt-bindings: riscv: cpus: Add UltraRISC CP100 compatible
      dt-bindings: riscv: Add UltraRISC DP1000 bindings
      dt-bindings: pinctrl: Add UltraRISC DP1000 pinctrl bindings
      riscv: dts: ultrarisc: Add initial device tree for UltraRISC DP1000
      pinctrl: ultrarisc: Add UltraRISC DP1000 pinctrl driver
      riscv: dts: ultrarisc: add Rongda M0 board device tree
      riscv: dts: ultrarisc: add Milk-V Titan board device tree
      riscv: defconfig: enable ARCH_ULTRARISC

 .../bindings/pinctrl/ultrarisc,dp1000-pinctrl.yaml | 168 ++++
 Documentation/devicetree/bindings/riscv/cpus.yaml  |   1 +
 .../devicetree/bindings/riscv/ultrarisc.yaml       |  27 +
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 MAINTAINERS                                        |  15 +
 arch/riscv/boot/dts/Makefile                       |   1 +
 arch/riscv/boot/dts/ultrarisc/Makefile             |   3 +
 .../dts/ultrarisc/dp1000-milkv-titan-pinctrl.dtsi  | 107 +++
 .../boot/dts/ultrarisc/dp1000-milkv-titan.dts      | 182 +++++
 .../dts/ultrarisc/dp1000-rongda-m0-pinctrl.dtsi    |  85 ++
 arch/riscv/boot/dts/ultrarisc/dp1000-rongda-m0.dts | 111 +++
 arch/riscv/boot/dts/ultrarisc/dp1000.dtsi          | 851 +++++++++++++++++++++
 arch/riscv/configs/defconfig                       |   1 +
 drivers/pinctrl/Kconfig                            |   1 +
 drivers/pinctrl/Makefile                           |   1 +
 drivers/pinctrl/ultrarisc/Kconfig                  |  23 +
 drivers/pinctrl/ultrarisc/Makefile                 |   4 +
 drivers/pinctrl/ultrarisc/pinctrl-dp1000.c         | 112 +++
 drivers/pinctrl/ultrarisc/pinctrl-ultrarisc.c      | 746 ++++++++++++++++++
 drivers/pinctrl/ultrarisc/pinctrl-ultrarisc.h      |  71 ++
 .../dt-bindings/pinctrl/ultrarisc,dp1000-pinctrl.h |  65 ++
 21 files changed, 2577 insertions(+)
---
base-commit: 50897c955902c93ae71c38698abb910525ebdc89
change-id: 20260316-ultrarisc-pinctrl-efa6e24c4803

Best regards,
--  
Jia Wang <wangjia@ultrarisc.com>

