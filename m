From: =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
Subject: [PATCH v6 0/3] arm64: dts: rockchip: Add FriendlyElec NanoPi R28S
Date: Mon, 14 Sep 2026 21:35:00 +0800
Message-Id: <20260914-r28s-upstream-v6-0-ea9edd75c126@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XOTW7DIBAF4KtErEMEw4+hq96jygLDuCFSbAscq
 1HkuxfSjYPU5ZPe92aeJGOKmMnH4UkSrjHHaSxBHw/EX9z4jTSGkgkw0MwyRROYTO9zXhK6G0X
 ggNAFzbUixcwJh/jz2vs6/+V876/olzpSG5eYlyk9XgdXXnv/ba+cMjpoE5QwFrR1n3Oalmk83
 ZDU7RX2ums1FA3c9apjg7fct1rstW21KBpRIHdCOqFEq+VOc95qWT/vtTdqANBBtlrttWy1Krq
 TzHppDZrw9vm2bb/ajblqtAEAAA==
X-Change-ID: 20260905-r28s-upstream-e212e27d6165
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chukun Pan <amadeus@jmu.edu.cn>, Jonas Karlman <jonas@kwiboo.se>, 
 jensen <jensenhuang@friendlyarm.com>, 
 Andrey Korshunov <razor1702@gmail.com>, 
 Diederik de Haas <diederik@cknow-tech.com>, 
 Conor Dooley <conor.dooley@microchip.com>, 
 =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=8046;
 i=HystericalDragons@proton.me; h=from:subject:message-id;
 bh=R3btyI4w5tF6ZHcJlaEq9PHDX+T4GAzDlq3NNhEgWtI=;
 b=owGbwMvMwCUmepz3XUtTHjvjabUkhqzlP3h+Wr+wc//S8+nFZT9BNY+CmmNCmzzz/HKDci03L
 3yuEr+to5SFQYyLQVZMkUV2U3Wk0KromUUsUsdh5rAygQxh4OIUgIkIrGH4K/JR9vQrzn18Vve/
 pthobXwalWA3XUdH4N7B76sfzK+J5GJkWLNe+FWG7/23Cv8VnaduNsh3rlBn5TosXW1U1bomZIs
 8JwA=
X-Developer-Key: i=HystericalDragons@proton.me; a=openpgp;
 fpr=1DB27B5912AA5B9972041AC715C70DEE84826E07
X-Endpoint-Received: by B4 Relay for HystericalDragons@proton.me/default with auth_id=1004
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The NanoPi R28S is a dual gigabit Ethernet router board based on the
Rockchip RK3528 SoC:

  https://wiki.friendlyelec.com/wiki/index.php/NanoPi_R28S

It is closely related to the already supported NanoPi Zero2, sharing
most of its power tree and peripheral routing. Patch 2 therefore moves
the common parts into rk3528-nanopi.dtsi, and patch 3 adds the board on
top of it. The split leaves the NanoPi Zero2 dtb unchanged; I verified
this by comparing the node and property sets of the dtb before and after
the split, which differ only in node order and phandle numbering.

The devicetree was derived from the vendor tree:

  https://github.com/friendlyarm/kernel-rockchip/commit/ee640c5344b13a0a317436e2357df01af8268ce7

but with many changes to make it suitable for mainline.

Tested on a metal-case unit without the optional onboard eMMC: boots
from microSD, both Ethernet ports link up at 1000 Mbps, the HYM8563 RTC
registers, and all three LEDs are functional. The USB Type-C connector
registers as a DWC3 UDC in peripheral mode; gadget enumeration against
a USB host was not completed, because that connector is also the 5V
input and a PC port cannot power the board.

The bootloader was U-Boot 2026.07 with a board specific R28S target,
which releases the RGMII PHY reset before Linux starts, so the reset
description in the PHY node is all the kernel needs.

Two things I did not do, because my hardware cannot verify them:

- The AICSemi AIC8800D80 WiFi chip on sdio0 has no upstream driver, so
  only the SDIO controller is described.
- The eMMC is described as HS200 rather than the vendor's HS400 with
  enhanced strobe, since the board at hand has an unpopulated eMMC
  footprint and the faster modes could not be verified.

---
Changes in v6:
- Dropped the coding style patch, and the blank line before "status" in
  the new devicetree along with it. Only 18 of the ~2900 "status"
  properties in arch/arm64/boot/dts/rockchip are preceded by a blank
  line, so the series now does what the rockchip devicetrees do (Jonas
  Karlman).
- Listed the NanoPi R28S and the NanoPi Zero2 in a single binding entry,
  since they share a devicetree. The entry only changed shape, so I kept
  Conor's Acked-by; please shout if that is not fine (Jonas Karlman).
- Kept all USB nodes in the board devicetrees instead of moving the OTG
  port into rk3528-nanopi.dtsi, since the NanoPi NEO3 Plus has USB 3.0
  and configures it differently (Jonas Karlman).
- Added the serial2 alias for the Bluetooth UART (Jonas Karlman).
- Named the user button pin configuration after its net in the
  schematic, GPIO4_B2_USR_BTN (Jonas Karlman).
- Described the SDIO slot more precisely: no-mmc, no-sd and the missing
  vmmc-supply. The module's VBAT comes from VCC_3V3 through a ferrite
  bead, VDDIO from VCC_1V8 (Jonas Karlman).
- Enabled DMA on uart2 with dma-names (Jonas Karlman).
- Kept dr_mode = "peripheral" and said why in a comment. The Type-C port
  is the 5V input: both CC pins have a 5.1k pull-down (R3811, R3812),
  USB20_OTG0_ID is not connected (R3922 is /NC) and VBUS only feeds
  VCC5V0_SYS through the input protection. So the port cannot present
  itself as a host or source VBUS, not even behind a powered hub.
- Did not add the WiFi and Bluetooth wake pin configurations. The pins
  are there, HOST_WAKE_WL and WL_WAKE_HOST on GPIO1_A6 and GPIO1_A7,
  HOST_WAKE_BT and BT_WAKE_HOST on GPIO1_B4 and GPIO1_B5, but the
  AIC8800D80 has no upstream driver, so there is no wifi@1 or bluetooth
  node to reference them from and the pin states would never be applied.
  They belong in the patch that adds those nodes (Jonas Karlman).
- Link to v5: https://patch.msgid.link/20260914-r28s-upstream-v5-0-7409c498e8dc@proton.me

Changes in v5:
- Dropped the pinctrl-0 before pinctrl-names reordering from the coding
  style patch and used the order the rest of the rockchip devicetrees
  use, pinctrl-names first, in the new devicetree as well. The strict
  mode of scripts/dtc/dt-check-style asks for the alphabetical order,
  but it does so for many other properties that no rockchip devicetree
  sorts that way either (Chukun Pan).
- Moved the SYS LED, which the NanoPi R28S shares with the NanoPi Zero2,
  and the led1 and led_sys pin configurations into rk3528-nanopi.dtsi.
  Both boards now only add their own LEDs to &leds (Chukun Pan).
- Renamed the NanoPi R28S LED nodes to led-1 and led-2, to use the
  led-[0-9] node naming (Chukun Pan).
- Changed the user button from KEY_RESTART to BTN_1. It is a general
  purpose button on this board, not a reset button (Chukun Pan).
- Link to v4: https://patch.msgid.link/20260911-r28s-upstream-v4-0-fb6c85f226d4@proton.me

Changes in v4:
- Dropped the patch that moved the NanoPi Zero2 RGMII PHY reset to the
  MDIO bus. GPIO4_C2 resets the PHY, not the bus, so describing it on
  &mdio1 is not a description of the hardware. It would also break
  Ethernet in U-Boot, which reads reset-gpios, reset-assert-us and
  reset-deassert-us from the PHY node and has no support for a bus
  level reset. The nanopi-zero2-rk3528 U-Boot target releases the PHY
  reset before Linux starts; the failure I reported was seen with the
  generic-rk3528 target, which carries no board devicetree. Pointed out
  by Chukun Pan, and by Jonas Karlman in the same discussion for the
  HINLINK H28K:
  https://lore.kernel.org/lkml/1e8da54f-ef87-4d31-9a0a-17c0ff66bee0@kwiboo.se/
  My own R28S has in fact been running a board specific U-Boot target
  all along, with the PHY node description this series now keeps, so
  the reset ordering problem I described does not arise there.
- Reworded the coding style patch to state the coding style violation
  itself as the reason, rather than the tool that found it (Diederik de
  Haas).
- Link to v3: https://patch.msgid.link/20260909-r28s-upstream-v3-0-ee3e1a34a353@proton.me

Changes in v3:
- New patch 1: describe the NanoPi Zero2 RGMII PHY reset on the MDIO
  bus rather than in the PHY node, so that it is applied before the PHY
  ID is read. A PHY held in reset by the bootloader was otherwise never
  probed, leaving the port dead. Reported by Andrey Korshunov, who
  proposed the deprecated snps,reset-gpio properties on the MAC; the
  bus level reset-gpios in mdio.yaml fixes the same ordering without a
  deprecated property.
- New patch 5: follow the DTS coding style in the three NanoPi RK3528
  devicetrees, as found by scripts/dtc/dt-check-style --mode=strict:
  pinctrl-0 before pinctrl-names, and a blank line before status.
  Suggested by Diederik de Haas.
- Picked up Conor Dooley's Acked-by on the binding.
- Link to v2: https://patch.msgid.link/20260907-r28s-upstream-v2-0-21ab570fc91c@proton.me

Changes in v2:
- Split the parts shared with the NanoPi Zero2 into a new
  rk3528-nanopi.dtsi (new patch 2). The NanoPi Zero2 dtb is unchanged.
- Name the pinctrl labels after the nets in the schematic: usr_btn,
  led1, led2, led_sys, pwr_wf and pcie_eth_perstb.
- Rename the button node to button-user and its label to "USER".
- Link to v1: https://patch.msgid.link/20260905-r28s-upstream-v1-0-f68d5389269a@proton.me

---
安容 (3):
      dt-bindings: arm: rockchip: Add FriendlyElec NanoPi R28S
      arm64: dts: rockchip: Split out the common NanoPi RK3528 parts
      arm64: dts: rockchip: Add devicetree for the FriendlyElec NanoPi R28S

 .../devicetree/bindings/arm/rockchip.yaml          |  12 +-
 arch/arm64/boot/dts/rockchip/Makefile              |   1 +
 .../arm64/boot/dts/rockchip/rk3528-nanopi-r28s.dts | 146 +++++++++++
 .../boot/dts/rockchip/rk3528-nanopi-zero2.dts      | 291 +--------------------
 arch/arm64/boot/dts/rockchip/rk3528-nanopi.dtsi    | 288 ++++++++++++++++++++
 5 files changed, 451 insertions(+), 287 deletions(-)
---
base-commit: 32e0f64640d558a0f5410ac5cdd8ebf371c5e6a6
change-id: 20260905-r28s-upstream-e212e27d6165

Best regards,
--  
安容 <HystericalDragons@proton.me>

