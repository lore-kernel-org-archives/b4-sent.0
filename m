From: =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
Subject: [PATCH v3 0/6] rockchip: rk3528: Add FriendlyElec NanoPi R28S
Date: Tue, 03 Nov 2026 18:37:05 +0800
Message-Id: <20261103-nanopi-r28s-v3-0-ae8664fd168f@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32Nyw7CIBBFf6VhLWYY+nTlfxgXtVA7JgKBSjRN/
 12oGxfG5UnuOXdhQXvSgR2KhXkdKZA1CeSuYMPUm6vmpBIzBKwFCOSmN9YR99gGDr0aAECOZVm
 xZDivR3putdP5w+Fxuelhzom8mCjM1r+2uyjy7nc5Cg4cSlQ1Vl3TYnd03s7W7O+a5XLEPy4mV
 ypRY1N1Skn17a7r+gaei1qC9AAAAA==
X-Change-ID: 20261012-nanopi-r28s-0adc0003f445
To: u-boot@lists.u-boot-project.org
Cc: Kever Yang <kever.yang@rock-chips.com>, 
 Quentin Schulz <u-boot@0leil.net>, Jonas Karlman <jonas@kwiboo.se>, 
 Simon Glass <sjg@chromium.org>, Tom Rini <trini@konsulko.com>, 
 Conor Dooley <conor.dooley@microchip.com>, 
 =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>, 
 Heiko Stuebner <heiko@sntech.de>, Chukun Pan <amadeus@jmu.edu.cn>, 
 Quentin Schulz <quentin.schulz@cherry.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3888;
 i=HystericalDragons@proton.me; s=20261103; h=from:subject:message-id;
 bh=4liYhmnYLrrZwdDx6nHPrOMRX6nbxZznefQdnWGlbKc=;
 b=owGbwMvMwCU8Ldb53x4TtgLG02pJDFkvdwbrnjXeY/ropPmtNbf2HvdLThfvr3v62Gl/d8Cul
 OKvHg3/OrazMAhzMciKKbJ0Sn+e+OXxhelfb07KgpnDygQyhIGLUwAm8vkkE6v0iRPr/r9YtzL4
 h5TPn/an95hj7h2bY90XKq70NSaY3XCuXM08ndPOwrsmOufK6vrvDPY+q+I12z3/Q5DhCyEz6+C
 od0wcNzuvlZ/eMsPu+y5m6Qdq/d53492sN7OFR3z+qv19OW/h9+pQ+8Un93H1ZH7OupEh/VE9ON
 q+flnPlt3ic5o/R7wSEawDAA==
X-Developer-Key: i=HystericalDragons@proton.me; a=openpgp;
 fpr=5A3AC293DCEEAA41A8A3266A910205A0AEB09D84
X-Endpoint-Received: by B4 Relay for HystericalDragons@proton.me/20261103 with auth_id=1393
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The FriendlyElec NanoPi R28S is a dual gigabit Ethernet router board
based on the Rockchip RK3528 SoC. It shares most of its design with the
NanoPi Zero2.

The Linux devicetree and bindings for the board are now in mainline
Linux and devicetree-rebasing. Import the three relevant commits with
U-Boot's tools/update-subtree.sh pick dts command, retaining their
upstream commit references:

  e9eafc0ca521
  f7f1ea96945d
  d0f6e37c635b

Patches 1-3 import the bindings and devicetrees into dts/upstream.
Patch 4 moves the U-Boot specific parts of the NanoPi Zero2 into a
common rk3528-nanopi-u-boot.dtsi, following the split in Linux.

Notes that `Assisted-by: LLM` tag is not required anymore since Linux
7.4, so checkpatch reports error for these patches. I have no idea
about how to deal with it, so I keep them as is. If I did wrong,
please tell me what should I do instead.

Patch 5 adds a NanoPi RK3528 board target that reads the HW_ID on
SARADC channel 2 to select the FDT in SPL and set fdtfile, in the same
way as the Radxa ROCK 2 board target, and moves the NanoPi Zero2 to it.

Patch 6 adds the NanoPi R28S to that board target, so that
nanopi-zero2-rk3528_defconfig supports both boards.

Build-tested with aarch64-linux-gnu-gcc using
nanopi-zero2-rk3528_defconfig and BINMAN_ALLOW_MISSING=1. U-Boot and
SPL compile, and the FIT contains both Zero2 and R28S devicetrees.
BL31 and Rockchip TPL were not supplied, so the generated images are
not bootable. No new hardware testing was performed.

---
Changes in v3:
- Rebase onto U-Boot mainline ab4dc5aacf9
- Import the mainline bindings and devicetrees with update-subtree.sh
- Widen the HW_ID ADC ranges to the buckets used by the FriendlyElec
  vendor U-Boot (Quentin)
- Merge the R28S MAINTAINERS entry into the NanoPi RK3528 entry
  (Quentin)
- Collect Reviewed-by tags
- Link to v2: https://patch.msgid.link/20261012-nanopi-r28s-v2-0-3d162759dd3d@proton.me

Changes in v2:
- Add a common NanoPi RK3528 board target that selects the FDT using
  the HW_ID on SARADC channel 2, instead of adding a new defconfig for
  the R28S (Jonas)
- Add Jonas Karlman as reviewer for the R28S.
- Link to v1: https://patch.msgid.link/20261012-nanopi-r28s-v1-0-042d62597829@proton.me

---
安容 (6):
      dt-bindings: arm: rockchip: Add FriendlyElec NanoPi R28S
      arm64: dts: rockchip: Split out the common NanoPi RK3528 parts
      arm64: dts: rockchip: Add devicetree for the FriendlyElec NanoPi R28S
      rockchip: rk3528: Split out common NanoPi u-boot.dtsi
      board: rockchip: Add common NanoPi RK3528 board target
      board: rockchip: Add FriendlyElec NanoPi R28S

 arch/arm/dts/rk3528-nanopi-r28s-u-boot.dtsi        |   3 +
 arch/arm/dts/rk3528-nanopi-u-boot.dtsi             |  16 ++
 arch/arm/dts/rk3528-nanopi-zero2-u-boot.dtsi       |  10 +-
 arch/arm/mach-rockchip/rk3528/Kconfig              |   7 +
 arch/arm/mach-rockchip/rk3528/MAINTAINERS          |   6 -
 board/friendlyelec/nanopi-rk3528/Kconfig           |  14 +
 board/friendlyelec/nanopi-rk3528/MAINTAINERS       |   9 +
 board/friendlyelec/nanopi-rk3528/Makefile          |   3 +
 board/friendlyelec/nanopi-rk3528/nanopi-rk3528.c   |  60 +++++
 configs/nanopi-zero2-rk3528_defconfig              |   3 +
 doc/board/rockchip/rockchip.rst                    |   2 +-
 dts/upstream/Bindings/arm/rockchip.yaml            |  12 +-
 .../src/arm64/rockchip/rk3528-nanopi-r28s.dts      | 160 +++++++++++
 .../src/arm64/rockchip/rk3528-nanopi-zero2.dts     | 290 +-------------------
 dts/upstream/src/arm64/rockchip/rk3528-nanopi.dtsi | 291 +++++++++++++++++++++
 15 files changed, 580 insertions(+), 306 deletions(-)
---
base-commit: ab4dc5aacf957835c295b59ef2dd28281839cb20
change-id: 20261012-nanopi-r28s-0adc0003f445

Best regards,
--  
安容 <HystericalDragons@proton.me>

