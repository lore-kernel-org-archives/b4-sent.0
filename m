From: Joachim Eastwood <joachim.eastwood@gmail.com>
Subject: [PATCH v2 0/3] arm64: dts: rockchip: Add NanoPi M6V2 board
Date: Wed, 04 Nov 2026 21:59:20 +0100
Message-Id: <20261104-nanopi-m6v2-v2-0-dfcd8714f48a@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/1XNQQ6CMBCF4auQWVvT1lrElfcwLEoZYYy0pMVGQ
 7i7BVYu/+TNNzNEDIQRrsUMARNF8i6HPBRge+M6ZNTmBsmlFlwo5ozzI7FBJ8msbnnJL9VZYAn
 5Ygz4oM+m3eu947t5op1WYl30FCcfvtu7JNbdLmf6T06CcYaKCzRaNadK3brB0Oto/QD1siw/T
 kmd6bgAAAA=
X-Change-ID: 20261014-nanopi-m6v2-c6d0708951e7
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Shawn Lin <Shawn.lin@rock-chips.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Joachim Eastwood <joachim.eastwood@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793825992; l=1813;
 i=joachim.eastwood@gmail.com; s=20260701; h=from:subject:message-id;
 bh=k2DHblhEFj5w7haYS80AKB4LL0FpR8EBvvhmiINNXjs=;
 b=2UAY/XFiEe8nlaDhGsA7ktyvq+cTBT3Xo9QsZVDr4r05QeI4+dS7zrCOBQDYBxliFsbd+Pc9A
 90J9Myq7AxhDM6NhG2QhPK7hoY+XwoGAe7KiXPrWJpnpmMAbFNzGDnf
X-Developer-Key: i=joachim.eastwood@gmail.com; a=ed25519;
 pk=ZN/8xWtdYaSd5oEfloYSZ1a+/ri0n0VZqjlEeHlbXFU=
X-Endpoint-Received: by B4 Relay for joachim.eastwood@gmail.com/20260701 with auth_id=846
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This short patch series add support for the NanoPi M6V2. The board is
very similar to the original M6 with only a few differences.

Differences:
* New audio CODEC (Everest ES8389)
* New Ethernet PHY (MotorComm YT8531C)
* 1 extra user button
* Misc connector changes on the board

Patch 1 documents the NanoPi M6V2 board compatibility string.
Patch 2 remove reference to the rtl8211f phy from common dtsi.
Patch 3 adds the NanoPi M6V2 device tree.

Link to schematic:
https://wiki.friendlyelec.com/wiki/images/b/b6/NanoPi_M6V2_2603_SCH.pdf

Based on linux-rockchip v7.5-armsoc/dts64 branch.

Signed-off-by: Joachim Eastwood <joachim.eastwood@gmail.com>
---
Changes in v2:
- Fix title of patch 3 - Sashiko
- Fix I2S clock copy-past mistake in patch 3 - Sashiko
- Dropped the generic phy compatibility since it won't work - Sashiko
- Add acked-by to patch 1 - Krzysztof
- Add new patch which remove reference to the rtl8211f phy
- Rebase on linux-rockchip v7.5-armsoc/dts64 branch
- Link to v1: https://patch.msgid.link/20261101-nanopi-m6v2-v1-0-e401ea64b394@gmail.com

---
Joachim Eastwood (3):
      dt-bindings: arm: rockchip: add FriendlyElec NanoPi M6V2
      arm64: dts: rockchip: rename rtl8211f node on rk3588s-nanopi
      arm64: dts: rockchip: add support for NanoPi M6V2 board

 .../devicetree/bindings/arm/rockchip.yaml          |  1 +
 arch/arm64/boot/dts/rockchip/Makefile              |  1 +
 .../boot/dts/rockchip/rk3588s-nanopi-m6v2.dts      | 94 ++++++++++++++++++++++
 arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi   | 12 +--
 4 files changed, 102 insertions(+), 6 deletions(-)
---
base-commit: 80e2828a00ba4f472289a699727abfd72a31de34
change-id: 20261014-nanopi-m6v2-c6d0708951e7

Best regards,
--  
Joachim Eastwood <joachim.eastwood@gmail.com>

