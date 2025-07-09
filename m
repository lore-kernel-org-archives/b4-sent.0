From: Keguang Zhang <keguang.zhang@gmail.com>
Subject: [PATCH v2 0/9] MIPS: loongson32: Convert all platform devices to
 DT
Date: Wed, 09 Jul 2025 19:05:51 +0800
Message-Id: <20250709-loongson1-arch-v2-0-bcff6e518c09@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAA9NbmgC/zWNSw7CIBQAr9K8tY8ApR9ceQ/jgtBXILZgQI2x6
 d1FE5ezmJkNCuVABY7NBpmeoYQUK8hDA9ab6AjDVBkklx1XQuGSUnQlRYEmW48dmdHSpKw2Gqp
 0yzSH1y94vlSec1rx7jOZf6blg9SiVa0Ymei1Uv2AAq/kHnXH3t/pya0mLMymFfb9A3byxBqjA
 AAA
To: Thomas Bogendoerfer <tsbogend@alpha.franken.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 Keguang Zhang <keguang.zhang@gmail.com>
Cc: linux-mips@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Philippe_Mathieu-Daud=C3=A9?= <philmd@linaro.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752059245; l=3440;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=9xgK+fBhA8h6jU2nAkgquJvvHtf3UTyu5jZV7nmkulY=;
 b=H+G1PpJx5Jx4sLoMA0qdN+92ka3q+Vr90XkUJakkUx8pUHiGmrDHCKGJh7ShbhBrmbFWrjXRi
 kfMkC6BMBMcCQx97SH4ple36WcC5lWv6ymHDOBlFDRjzU3bHkabn0bF
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Convert all platform devices to Device Tree.  
Remove all obsolete platform device code.  
Switch to the generic MIPS kernel.  
Update Kconfig and Makefile accordingly.  
Update and rename the defconfig.

Changes in v2:
- Document two new boards: loongson,ls1b-demo and loongson,cq-t300b.
- Submit complete DTS files for each board.
- Switch to the generic MIPS kernel.
- Consolidate Loongson1 defconfigs.
- Link to v1: https://lore.kernel.org/all/20230729134318.1694467-1-keguang.zhang@gmail.com/

---
Keguang Zhang (9):
      dt-bindings: mips: loongson: Add LS1B demo board
      dt-bindings: mips: loongson: Add CQ-T300B board
      MIPS: dts: loongson: Add LS1B-DEMO board
      MIPS: dts: loongson: Add LSGZ_1B_DEV board
      MIPS: dts: loongson: Add Smartloong-1C board
      MIPS: dts: loongson: Add CQ-T300B board
      MIPS: loongson32: Switch to generic kernel
      MIPS: Unify Loongson1 PRID_REV
      MIPS: configs: Consolidate Loongson1 defconfigs

 .../devicetree/bindings/mips/loongson/devices.yaml |   2 +
 MAINTAINERS                                        |   3 +-
 arch/mips/Kconfig                                  |  64 ++---
 arch/mips/boot/dts/Makefile                        |   1 +
 arch/mips/boot/dts/loongson/Makefile               |   9 +
 arch/mips/boot/dts/loongson/cq-t300b.dts           |  93 +++++++
 arch/mips/boot/dts/loongson/loongson1.dtsi         | 136 ++++++++++
 arch/mips/boot/dts/loongson/loongson1b.dtsi        | 198 ++++++++++++++
 arch/mips/boot/dts/loongson/loongson1c.dtsi        | 141 ++++++++++
 arch/mips/boot/dts/loongson/ls1b-demo.dts          | 108 ++++++++
 arch/mips/boot/dts/loongson/lsgz_1b_dev.dts        | 145 +++++++++++
 arch/mips/boot/dts/loongson/smartloong-1c.dts      |  93 +++++++
 .../{loongson1b_defconfig => loongson1_defconfig}  |  94 +++++--
 arch/mips/configs/loongson1c_defconfig             | 121 ---------
 arch/mips/include/asm/cpu-type.h                   |   3 +-
 arch/mips/include/asm/cpu.h                        |   3 +-
 arch/mips/include/asm/mach-loongson32/irq.h        | 107 --------
 arch/mips/include/asm/mach-loongson32/loongson1.h  |  50 ----
 arch/mips/include/asm/mach-loongson32/platform.h   |  23 --
 arch/mips/include/asm/mach-loongson32/regs-mux.h   | 124 ---------
 arch/mips/kernel/cpu-probe.c                       |   6 +-
 arch/mips/loongson32/Kconfig                       |  43 +---
 arch/mips/loongson32/Makefile                      |  17 --
 arch/mips/loongson32/Platform                      |   1 -
 arch/mips/loongson32/common/Makefile               |   6 -
 arch/mips/loongson32/common/irq.c                  | 191 --------------
 arch/mips/loongson32/common/platform.c             | 285 ---------------------
 arch/mips/loongson32/common/prom.c                 |  42 ---
 arch/mips/loongson32/common/setup.c                |  26 --
 arch/mips/loongson32/common/time.c                 |  23 --
 arch/mips/loongson32/ls1b/Makefile                 |   6 -
 arch/mips/loongson32/ls1b/board.c                  |  55 ----
 arch/mips/loongson32/ls1c/Makefile                 |   6 -
 arch/mips/loongson32/ls1c/board.c                  |  23 --
 34 files changed, 1049 insertions(+), 1199 deletions(-)
---
base-commit: b5a1f9870f9828bd6625d6c946c66be4983d56f6
change-id: 20250414-loongson1-arch-5ea8ced4c9a9

Best regards,
-- 
Keguang Zhang <keguang.zhang@gmail.com>

