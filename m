From: Ricardo Pardini <ricardo@pardini.net>
Subject: [PATCH v6 0/6] describe RTL8125 PCIe NICs on Rockchip boards
Date: Mon, 09 Nov 2026 13:32:15 +0100
Message-Id: <20261109-rk3588-dts-rtl-eth-describe-dt-alias-v6-0-91f1efefba0b@pardini.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAE+98WoC/43Oy07DMBAF0F+pvGaQ34+u+A/Ewo8JMVRpZZsIV
 OXfcYpQi8oiyzu6OnfOpGLJWMl+dyYF51zzcepBP+xIHP30ipBTz4RTrqniEsq7UNZCahVKOwC
 2ERLWWHLAfgR/yL5CZJiYNcFERUmnTgWH/HmZeX75yfUjvGFsq702xlzbsXxd/pjZ2vudVNsmZ
 wYMvB5i8koLH83TyZeUp/w4YSPr6MxvWbeR5UBBOkMpl5ZJMdyz4sp2eCMrOmu9tcoE4ZL/h5U
 3LDMbWdlZHpKwjvPEuLtn1ZV1jG5kVWcjCw7VwGhM+i+7LMs3qS59DkgCAAA=
X-Change-ID: 20260524-rk3588-dts-rtl-eth-describe-dt-alias-c1ed187b7c50
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Sebastian Reichel <sebastian.reichel@collabora.com>, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=5671; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=SE+ulRJfxixyEy/C7Yk/ixDXQAH0gsNdOqLkBsMFHLU=;
 b=owEBbQGS/pANAwAKATteP+Oex+3pAcsmYgBq8b1QkKbeReCVP3vLmzUDio/TNeYUoxxTEPpc9
 1svIbtRdOaJATMEAAEKAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCavG9UAAKCRA7Xj/jnsft
 6SVPB/4+GXlr+OKZbV8jwEKd11YzgQ8wTiVdVadBbGgtjCmXyMExxEeh1kTtiQYLwmrpJyPmRHw
 U9jcFB3lZlqEekR/DWIl5pAseFwJS8qgdaqWp95TzysxoTF8IzUzqunQm0MP49iPsZC4ieXDBDe
 WtTDaapgYmIOpR186lHOyNlnS/m4RfLvdMn59Dj+hj/rg1wZhi1iUxgkKDHUf0Wo0v+FM18+XT+
 DJDhSHrYNFEGKAw/XeYqG3hf92Z+uJu+MBxcxduQ7mgNcIsmhY6tu99TbRpqp+DBH9sdqbGiyvu
 nMKcKN4BhNevBzp/noteVQqysE20doL14NHIao7LisNgmo4a
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Several Rockchip rk35xx boards carry on-board Realtek RTL8125 2.5GbE
NICs whose PCI function nodes are not described in the DT. Describing
them allows for stable ethernetN aliases (matching the GMAC alias
convention on these boards) and lets U-Boot's fdt_fixup_ethernet()
inject mac-address properties from its ethaddr/ethNaddr env, so MACs
stay stable across boots and U-Boot and kernel MAC match.

The DT binding for the RTL8125 (patch 1/7 up to v5) is now sent
separately via net-next, carrying Rob's Reviewed-by [1]. There is no
direct dependency: "pci10ec,8125" is already covered by dtschema's
pci-device.yaml, so these DTs apply and validate without it; the
binding only adds validation of ethernet-controller properties on these
nodes.

On these boards the RTL8125s are not pre-programmed with a unique MAC
address, so without a DT node the kernel falls back to a random MAC on
each boot.

Tested on a NanoPC-T6: /sys/bus/pci/devices/0004:41:00.0/of_node ->
/sys/firmware/devicetree/base/pcie@fe190000/pcie@0,0/ethernet@0,0 and
u-boot correctly adds local-mac-address property there which is
correctly picked up kernel-side:

  => setenv eth1addr 8e:b4:90:66:66:66
  => boot
  ...
  # readlink -f /sys/bus/pci/devices/0004:41:00.0/of_node
  /sys/firmware/devicetree/base/pcie@fe190000/pcie@0,0/ethernet@0,0
  # xxd /sys/bus/pci/devices/0004:41:00.0/of_node/local-mac-address
  00000000: 8eb4 9066 6666                           ...fff
  # ip link show dev end1 | grep ether
       link/ether 8e:b4:90:66:66:66 brd ff:ff:ff:ff:ff:ff

[1] https://patch.msgid.link/20261109-dt-bindings-net-realtek-rtl8125-v1-1-cff4b8a8be66@pardini.net

Changes in v6:
- binding split out and sent separately via net-next (ref Heiko).
- rebased onto v7.4-rc1 (diff context changes only, eg. new NanoPC-T6
  pinctrl names).
- nanopc-t6: fix nomenclature according to schematics (ref Diederik).
- cm3588-nas, nanopi-r5s, nanopi-r6c, rock-5-itx: fix the root port
  bus-range to start at the secondary bus, as already done for the
  others in v4 (ref Sashiko).
- make commit messages and DT nodes consistent across boards (drop
  the inline comments; move the EEPROM/MAC rationale to the cover).
- cm3588: describe the RTL8125 in the SoM dtsi instead of the NAS
  carrier .dts, as it sits on the SoM.
- nanopi-r5s: note that mainline U-Boot only sets ethaddr/eth1addr
  (ref Diederik).
- Link to v5: https://patch.msgid.link/20260910-rk3588-dts-rtl-eth-describe-dt-alias-v5-0-c1b9e5f10cd6@pardini.net

Changes in v5:
- binding: reword commit message: pci10ec,8125 is already covered by
  dtschema pci-device.yaml; the binding is added only to validate the
  ethernet-controller properties on these nodes (local-mac-address,
  nvmem-cells, et al) (ref Krzysztof, Heiner).
- boards: add a few more Rockchip boards with RTL8125's.
- Link to v4: https://patch.msgid.link/20260617-rk3588-dts-rtl-eth-describe-dt-alias-v4-0-2bd38922d129@pardini.net

Changes in v4:
- binding: simplify the binding YAML ref Sashiko's and Krzysztof's
  reviews
- binding: describe only the RTL8125 + rename to match ref Heiner's
  review.
- dt: fix the bus-range according to Sashiko's review.
- Link to v3: https://patch.msgid.link/20260605-rk3588-dts-rtl-eth-describe-dt-alias-v3-0-8a8857b39daf@pardini.net

Changes in v3:
- new patch: add a DT binding for Realtek r8169 family PCIe Ethernet
  controllers, per Sebastian Reichel's review (the "pciVVVV,DDDD" OF
  spelling still needs a binding when used in a board DT).
- new patch for Rock5 series, and include a brief rationale in each.
- retitle the series, since it now covers a few boards and a binding
  rather than just DeviceTree changes for the NanoPC-T6.
- drop the v2 "rename vcc3v3_pcie2x1l0 regulator" patch from this
  series; it will be sent separately as it is not relevant to this.
- Link to v2: https://patch.msgid.link/20260529-rk3588-dts-rtl-eth-describe-dt-alias-v2-0-49700248143f@pardini.net

Changes in v2:
- fix: pcie2x1l0, not pcie2x1l1; indirectly caught by Sashiko's review [1]
- while-at-it: rename regulator vcc3v3_pcie2x1l0 to l1
- Link to v1: https://patch.msgid.link/20260525-rk3588-dts-rtl-eth-describe-dt-alias-v1-1-a6fcda563ac7@pardini.net

[1] https://sashiko.dev/#/patchset/20260525-rk3588-dts-rtl-eth-describe-dt-alias-v1-1-a6fcda563ac7%40pardini.net

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
Ricardo Pardini (6):
      arm64: dts: rockchip: describe PCIe RTL8125 Ethernet on NanoPC-T6
      arm64: dts: rockchip: describe PCIe RTL8125 Ethernet on ROCK 5 family
      arm64: dts: rockchip: describe PCIe RTL8125 Ethernet on CM3588
      arm64: dts: rockchip: describe PCIe RTL8125 Ethernet on NanoPi R5S
      arm64: dts: rockchip: describe PCIe RTL8125 Ethernet on NanoPi R6C
      arm64: dts: rockchip: describe PCIe RTL8125 Ethernet on ROCK 5 ITX

 arch/arm64/boot/dts/rockchip/rk3568-nanopi-r5s.dts | 30 ++++++++++++++++++++++
 .../dts/rockchip/rk3588-friendlyelec-cm3588.dtsi   | 15 +++++++++++
 arch/arm64/boot/dts/rockchip/rk3588-nanopc-t6.dtsi | 30 ++++++++++++++++++++++
 arch/arm64/boot/dts/rockchip/rk3588-rock-5-itx.dts | 30 ++++++++++++++++++++++
 .../boot/dts/rockchip/rk3588-rock-5b-5bp-5t.dtsi   | 15 +++++++++++
 arch/arm64/boot/dts/rockchip/rk3588-rock-5t.dts    | 18 +++++++++++++
 .../arm64/boot/dts/rockchip/rk3588s-nanopi-r6c.dts | 20 +++++++++++++++
 7 files changed, 158 insertions(+)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20260524-rk3588-dts-rtl-eth-describe-dt-alias-c1ed187b7c50

Best regards,
--  
Ricardo Pardini <ricardo@pardini.net>

