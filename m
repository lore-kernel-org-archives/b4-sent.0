From: =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
Subject: [PATCH v2 0/3] rockchip: rk3528: Add FriendlyElec NanoPi R28S
Date: Mon, 12 Oct 2026 21:22:15 +0800
Message-Id: <20261012-nanopi-r28s-v2-0-3d162759dd3d@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NQQ6CMBBFr0Jmbc10LAisvIdhgTDImNg2LRIN6
 d0F3Lp8yfvvLxA5CEeoswUCzxLF2RXokEE3tvbOSvqVgZAKjZqUba3zogKVUWHbd4h4GozJYV3
 4wIO899q1+XF83R7cTVtiM0aJkwuf/W7Wm/e/PGuFCg31BeXVuaTq4oObnD0+GZqU0hcTlUx1u
 AAAAA==
X-Change-ID: 20261012-nanopi-r28s-0adc0003f445
To: u-boot@lists.u-boot-project.org
Cc: Kever Yang <kever.yang@rock-chips.com>, 
 Quentin Schulz <u-boot@0leil.net>, Jonas Karlman <jonas@kwiboo.se>, 
 Simon Glass <sjg@chromium.org>, Tom Rini <trini@konsulko.com>, 
 =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3019;
 i=HystericalDragons@proton.me; h=from:subject:message-id;
 bh=em4uWzBG5IgjJJuIFVD99J/wvYwEZa2GWIcYh3xj+aY=;
 b=owGbwMvMwCUmepz3XUtTHjvjabUkhqwz9zm57+/Mv7+VY19AdNN+i80/5Vx7CxovvihrSO++f
 mD742+tHaUsDGJcDLJiiiyym6ojhVZFzyxikToOM4eVCWQIAxenAEyk/zPD/xzeh2bWC2+vWtTj
 VFnzyuVwSLz8Pu8M8zaj5Btv7Q2q7jIyrO8uDzrOEd12sMl4w94Js9JTJNr7VFpe7Apznua/4PJ
 ybgA=
X-Developer-Key: i=HystericalDragons@proton.me; a=openpgp;
 fpr=1DB27B5912AA5B9972041AC715C70DEE84826E07
X-Endpoint-Received: by B4 Relay for HystericalDragons@proton.me/default with auth_id=1004
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The FriendlyElec NanoPi R28S is a dual gigabit Ethernet router board
based on the Rockchip RK3528 SoC. It shares most of its design with the
NanoPi Zero2.

The Linux devicetree for the board has been applied to the Rockchip
tree for v7.4, together with a patch that splits the parts shared with
the NanoPi Zero2 into a common rk3528-nanopi.dtsi:

  fdb087806e80 ("arm64: dts: rockchip: Split out the common NanoPi RK3528 parts")
  c1e23f3425c4 ("arm64: dts: rockchip: Add devicetree for the FriendlyElec NanoPi R28S")

These are not yet available in devicetree-rebasing, so this series only
contains the U-Boot side for review for now. Patch 3 does not build
until the R28S devicetree is in dts/upstream. Once both commits are in
devicetree-rebasing, I will pick them into dts/upstream with
tools/update-subtree.sh and add them at the start of the next version.

Patch 1 moves the U-Boot specific parts of the NanoPi Zero2 into a
common rk3528-nanopi-u-boot.dtsi, following the split in Linux. The
NanoPi Zero2 u-boot.dtb is identical before and after this patch.

Patch 2 adds a NanoPi RK3528 board target that reads the HW_ID on
SARADC channel 2 to select the FDT in SPL and set fdtfile, in the same
way as the Radxa ROCK 2 board target, and moves the NanoPi Zero2 to it.

Patch 3 adds the NanoPi R28S to that board target, so that
nanopi-zero2-rk3528_defconfig supports both boards.

nanopi-zero2-rk3528 was build-tested with the devicetree files from
v7.4-armsoc/dts64 copied into dts/upstream; the resulting FIT contains
both the Zero2 and the R28S FDT.

---
Changes in v2:
- Add a common NanoPi RK3528 board target that selects the FDT using
  the HW_ID on SARADC channel 2, instead of adding a new defconfig for
  the R28S (Jonas)
- Add Jonas Karlman as reviewer for the R28S.
- Link to v1: https://patch.msgid.link/20261012-nanopi-r28s-v1-0-042d62597829@proton.me

---
安容 (3):
      rockchip: rk3528: Split out common NanoPi u-boot.dtsi
      board: rockchip: Add common NanoPi RK3528 board target
      board: rockchip: Add FriendlyElec NanoPi R28S

 arch/arm/dts/rk3528-nanopi-r28s-u-boot.dtsi      |  3 ++
 arch/arm/dts/rk3528-nanopi-u-boot.dtsi           | 16 +++++++
 arch/arm/dts/rk3528-nanopi-zero2-u-boot.dtsi     | 10 +---
 arch/arm/mach-rockchip/rk3528/Kconfig            |  7 +++
 arch/arm/mach-rockchip/rk3528/MAINTAINERS        |  6 ---
 board/friendlyelec/nanopi-rk3528/Kconfig         | 14 ++++++
 board/friendlyelec/nanopi-rk3528/MAINTAINERS     | 13 ++++++
 board/friendlyelec/nanopi-rk3528/Makefile        |  3 ++
 board/friendlyelec/nanopi-rk3528/nanopi-rk3528.c | 59 ++++++++++++++++++++++++
 configs/nanopi-zero2-rk3528_defconfig            |  3 ++
 doc/board/rockchip/rockchip.rst                  |  2 +-
 11 files changed, 120 insertions(+), 16 deletions(-)
---
base-commit: 5e3b01c8466dbe45cd6a06299f8f4c7e8c1c2363
change-id: 20261012-nanopi-r28s-0adc0003f445

Best regards,
--  
安容 <HystericalDragons@proton.me>

