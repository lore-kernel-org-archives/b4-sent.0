From: =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
Subject: [PATCH 0/2] rockchip: rk3528: Add FriendlyElec NanoPi R28S
Date: Mon, 12 Oct 2026 14:55:41 +0800
Message-Id: <20261012-nanopi-r28s-v1-0-042d62597829@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ5AMBBA4avIrDWZ1k/EVcSiajAWJR1EIu6uW
 H6L9y4QCkwCdXJBoIOFFx+h0wTcZP1IivtoMGhKjdoob/2ysgqmEoW2d4iYDXleQCzWQAOf361
 pf8vezeS2dwH3/QDjXs9SbwAAAA==
X-Change-ID: 20261012-nanopi-r28s-0adc0003f445
To: u-boot@lists.u-boot-project.org
Cc: Kever Yang <kever.yang@rock-chips.com>, 
 Quentin Schulz <u-boot@0leil.net>, Jonas Karlman <jonas@kwiboo.se>, 
 Simon Glass <sjg@chromium.org>, Tom Rini <trini@konsulko.com>, 
 =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1946;
 i=HystericalDragons@proton.me; h=from:subject:message-id;
 bh=gzXn0YnkdiKTMTOZ+nkQExFtxEAE2L23nlurQLNfx0g=;
 b=owGbwMvMwCUmepz3XUtTHjvjabUkhqwzLfmH3aaXvj30+frjCt6LyzfacN3ap8XD2W3Omraji
 O/a5xt3O0pZGMS4GGTFFFlkN1VHCq2KnlnEInUcZg4rE8gQBi5OAZiITjQjw/p3/39Yfg5eZ/Rq
 Q+KFBwdUdrDkbRZ0Ctq7e1H95W/HV/oxMuxPnvVldcHV1Te11E6suVypenDRFOlbLIt+igb8OPp
 BspgfAA==
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
contains the U-Boot side for review for now. Patch 2 does not build
until the R28S devicetree is in dts/upstream. Once both commits are in
devicetree-rebasing, I will pick them into dts/upstream with
tools/update-subtree.sh and add them at the start of the next version.

Patch 1 moves the U-Boot specific parts of the NanoPi Zero2 into a
common rk3528-nanopi-u-boot.dtsi, following the split in Linux. The
NanoPi Zero2 u-boot.dtb is identical before and after this patch.

Both nanopi-r28s-rk3528 and nanopi-zero2-rk3528 were build-tested with
the devicetree files from v7.4-armsoc/dts64 copied into dts/upstream.

---
安容 (2):
      rockchip: rk3528: Split out common NanoPi u-boot.dtsi
      board: rockchip: Add FriendlyElec NanoPi R28S

 arch/arm/dts/rk3528-nanopi-r28s-u-boot.dtsi  |  3 ++
 arch/arm/dts/rk3528-nanopi-u-boot.dtsi       | 11 +++++
 arch/arm/dts/rk3528-nanopi-zero2-u-boot.dtsi | 10 +----
 arch/arm/mach-rockchip/rk3528/MAINTAINERS    |  7 +++
 configs/nanopi-r28s-rk3528_defconfig         | 65 ++++++++++++++++++++++++++++
 doc/board/rockchip/rockchip.rst              |  1 +
 6 files changed, 88 insertions(+), 9 deletions(-)
---
base-commit: 5e3b01c8466dbe45cd6a06299f8f4c7e8c1c2363
change-id: 20261012-nanopi-r28s-0adc0003f445

Best regards,
--  
安容 <HystericalDragons@proton.me>

