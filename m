From: Keguang Zhang <keguang.zhang@gmail.com>
Subject: [PATCH v3 0/9] MIPS: loongson32: Convert all platform devices to
 DT
Date: Wed, 16 Jul 2025 19:25:09 +0800
Message-Id: <20250716-loongson1-arch-v3-0-d160974d696b@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABWMd2gC/12Oyw6CMBQFf4V07SVtKY+68j8Mi1ou0AitaZGoh
 H+3YEyMy1mcObOQgN5gIMdkIR5nE4yzEbJDQnSvbIdgmsiEU55TwQQMztkuOMtAed1DjqrS2Ag
 tlSRxdPPYmscuPNeRW+9GmHqP6qvJaMkly0TGqpQVUoiiBAZX7O7xLn1tp6duVGZItRs3ZW/C5
 PxzT5z5Jv7UlFT+18wcKFx02xaYs0pT+WOq13V9A4gnywLvAAAA
To: Thomas Bogendoerfer <tsbogend@alpha.franken.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 Keguang Zhang <keguang.zhang@gmail.com>
Cc: linux-mips@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 =?utf-8?q?Philippe_Mathieu-Daud=C3=A9?= <philmd@linaro.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752665136; l=3912;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=p3BSUcDo5y0Wn2DQ5Qi8LbjrebDK6eyOiu8A1DTmYoo=;
 b=bGgm74usr1scB/TvEdJlAVUw5GvU3MMAKStrhD4cikw0SATfq+esZ2p2h3TpmtWONuK1J046W
 dlyTbPfCw26DLKh/qRfkJhAzEr7GQatC0WfSotQfyVCDDLmZAag6IL+
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Convert all platform devices to Device Tree.
Remove all obsolete platform device code.
Switch to the generic MIPS core.
Add built-in DTB support.
Update Kconfig and Makefile accordingly.
Update and rename the defconfig.

Changes in v3:
- Squash two previous changes that documented DT bindings for the
  LS1B-DEMO and CQ-T300B into a single patch.
- Separate the built-in DTB support into a single patch.
- Move the timer node under the APB bus.
- Remove redundant console bootargs since it is covered by stdout-path.
- Replace mtdparts bootargs with a "partitions" node.
- Link to v2: https://lore.kernel.org/r/20250709-loongson1-arch-v2-0-bcff6e518c09@gmail.com

Changes in v2:
- Document two new boards: loongson,ls1b-demo and loongson,cq-t300b.
- Submit complete DTS files for each board.
- Switch to the generic MIPS kernel.
- Consolidate Loongson1 defconfigs.
- Link to v1: https://lore.kernel.org/all/20230729134318.1694467-1-keguang.zhang@gmail.com/

---
Keguang Zhang (9):
      dt-bindings: mips: loongson: Add LS1B-DEMO and CQ-T300B
      MIPS: dts: loongson: Add LS1B-DEMO board
      MIPS: dts: loongson: Add LSGZ_1B_DEV board
      MIPS: dts: loongson: Add Smartloong-1C board
      MIPS: dts: loongson: Add CQ-T300B board
      MIPS: loongson: Add built-in DTB support
      MIPS: loongson32: Switch to generic core
      MIPS: Unify Loongson1 PRID_REV
      MIPS: configs: Consolidate Loongson1 defconfigs

 .../devicetree/bindings/mips/loongson/devices.yaml |   2 +
 MAINTAINERS                                        |   3 +-
 arch/mips/Kconfig                                  |  64 ++---
 arch/mips/boot/dts/Makefile                        |   1 +
 arch/mips/boot/dts/loongson/Makefile               |  10 +
 arch/mips/boot/dts/loongson/cq-t300b.dts           | 110 ++++++++
 arch/mips/boot/dts/loongson/loongson1.dtsi         | 136 ++++++++++
 arch/mips/boot/dts/loongson/loongson1b.dtsi        | 198 ++++++++++++++
 arch/mips/boot/dts/loongson/loongson1c.dtsi        | 141 ++++++++++
 arch/mips/boot/dts/loongson/ls1b-demo.dts          | 125 +++++++++
 arch/mips/boot/dts/loongson/lsgz_1b_dev.dts        | 162 ++++++++++++
 arch/mips/boot/dts/loongson/smartloong-1c.dts      | 110 ++++++++
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
 34 files changed, 1118 insertions(+), 1199 deletions(-)
---
base-commit: b5a1f9870f9828bd6625d6c946c66be4983d56f6
change-id: 20250414-loongson1-arch-5ea8ced4c9a9

Best regards,
-- 
Keguang Zhang <keguang.zhang@gmail.com>

