From: Joachim Eastwood <joachim.eastwood@gmail.com>
Subject: [PATCH 0/3] arm64: dts: rockchip: Add NanoPi M6V2 board
Date: Sun, 01 Nov 2026 23:00:51 +0100
Message-Id: <20261101-nanopi-m6v2-v1-0-e401ea64b394@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ5AMBBA4as0s9akbaifq4gFNRiJVlpEIu6uW
 H6L9y4I6AkDVOwCjwcFcjZCJgzM1NoROfXRoITSUsiU29a6lfiiD8WN7kUuijKTmEMsVo8Dnd+
 tbn6HvZvRbO8C7vsB1h9Jc28AAAA=
X-Change-ID: 20261014-nanopi-m6v2-c6d0708951e7
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Shawn Lin <Shawn.lin@rock-chips.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Joachim Eastwood <joachim.eastwood@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793570476; l=1695;
 i=joachim.eastwood@gmail.com; s=20260701; h=from:subject:message-id;
 bh=pJ6sMrN48cPu0hMmZhmjBx3CU89+Wvf5/R4Y847eZW8=;
 b=H7wcfuRARX4ueHIDrdbfxZGohp3+1hq4nqIAMBVoJ+QHNY2o13nvPvJODZxVBH5BHCwKypWPo
 GG0j5nwo9BbDHtu/Zz/Ay4XFR0Qm3BY4j/gJV/wIW1hS2wC3KxVduv1
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
Patch 2 changes the Eth phy to a generic compatible in DT.
Patch 3 adds the NanoPi M6V2 device tree.

Patch 2 is tested on M6 which has a RTL8211F phy and MV2 with YT8531C.
Note that R6C and R6S also have RTL8211F phys so this test should
cover those as well.

Note that this patch set doesn't depend on the "NanoPi 6 series fixes
and improvements" patch set. The patch sets can be applied in any order
without any conflicts.

Link to schematic:
https://wiki.friendlyelec.com/wiki/images/b/b6/NanoPi_M6V2_2603_SCH.pdf

Based on v7.4-rc1.

Signed-off-by: Joachim Eastwood <joachim.eastwood@gmail.com>
---
Joachim Eastwood (3):
      dt-bindings: arm: rockchip: add FriendlyElec NanoPi M6V2
      arm64: dts: rockchip: rk3588s-nanopi: switch to generic eth phy compatible
      arm64: dts: rockchip: add support for NanoPi M6 board

 .../devicetree/bindings/arm/rockchip.yaml          |  1 +
 arch/arm64/boot/dts/rockchip/Makefile              |  1 +
 .../boot/dts/rockchip/rk3588s-nanopi-m6v2.dts      | 90 ++++++++++++++++++++++
 arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi   |  2 +-
 4 files changed, 93 insertions(+), 1 deletion(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261014-nanopi-m6v2-c6d0708951e7

Best regards,
--  
Joachim Eastwood <joachim.eastwood@gmail.com>

