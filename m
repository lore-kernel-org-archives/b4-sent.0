From: George Moussalem <george.moussalem@outlook.com>
Subject: [PATCH v4 00/13] Enable USB3 for Qualcomm IPQ5018
Date: Tue, 08 Sep 2026 13:40:53 +0400
Message-Id: <20260908-ipq5018-usb3-v4-0-b789702f0695@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/12QQW7DIBBFr2KxLtHAgGuiqso9qqrC9tCgxCYBb
 LWKcvdip5WSLt/iP72ZC0sUPSW2rS4s0uyTD2MB9VSxbm/HT+K+L8wkyBoaQO5PZw2i4VNqkat
 WNqYV1IuaWJmcIjn/tere3gu7GAae95HsnwTBSAONkmA2CFgQueDnyXcf/nSYBht3C/ix23RhW
 Jx7n3KI32vhLBfzb4yQjzGz5MAbh1r3z84BuV2Y8jGEw2pacma8m0v9b45ljqYlMFrb2trH+fV
 2XqSSl3y+3cgGSsmuT9pWL6vXQL14uTvanGlc3De1QFIErkYh8V79uhzZ2kS8wODztkLZ1uSM1
 T1QZ5VypuuNcFo65axtjBNKW+ipRF1/AFW9R9zBAQAA
X-Change-ID: 20260803-ipq5018-usb3-4b289b1ed16e
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Praveenkumar I <praveenkumar.i@oss.qualcomm.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 Nitheesh Sekar <quic_nsekar@quicinc.com>, 
 Wesley Cheng <quic_wcheng@quicinc.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Varadarajan Narayanan <quic_varada@quicinc.com>
Cc: linux-arm-msm@vger.kernel.org, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, George Moussalem <george.moussalem@outlook.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Stanislaw Pal <kuncy7@gmail.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788860512; l=8761;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=EB2qd8pfb+DcY/U6DOuRtvaI2n8YHf4yODLZQZwWwps=;
 b=aSikrBmXz2cH6RTA64e63N0pd0YDL1PWFFrVWJ8gwe0eif172yOxxK74++OCDQI7QFTpEM1k+
 GGMfnecxjlwCXQQ/YV627yrNHz1od3+rFWS4NYFbOfp9+fbBoSUrRvm
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Patch series adds Qualcomm 22ull Super-Speed USB UNIPHY driver support
present in Qualcomm IPQ5018 and IPQ5332 SoC which is required to enable
USB3. This PHY is interfaced with SNPS DWC3 USB and SNPS DWC PCIe.
Either one of the interface can use it via the mux selection present in
the TCSR register. Current patch series adds the support for UNIPHY with
DWC3 USB.

The series is now split into 3 parts:
1. Flatten USB Controller Nodes on IPQ SoCs
   link: https://lore.kernel.org/r/20260906-ipq-flatten-usb-v3-0-13e4e0f63123@outlook.com
2. Enable USB3 for Qualcomm IPQ5018 (this patch series)
3. Enable USB3 for Qualcomm IPQ5332 (to be submitted)

---
Changes in v4:
- Reverted change to rename the binding file.
  The qcom,ipq5018-uniphy-usb3-phy compatible string is added there.
- Removed redundant #clock-cells and #phy-cells constraint
- Updated description of CONFIG symbol to reflect it is a combo
  PCIe/USB3 PHY.
- Added separate patch to remove unused of_device.h header file
- Added separate patch to drop unused phy_to_dw_phy() macro
- Left names of macro definitions unchanged.
  This can be revisited in a future patch submission if deemed necessary
- Inlined reset_control_bulk_assert instead of using a single-use goto
  as suggested by Konrad.
- Replaced regmap_set_bits with regmap_assign_bits and pass the enable
  argument directly to the function.
- It's worth noting that I left the logic to register 1 phy in this
  patch unchanged despite Konard's suggestion to register both
  (PCIe and USB3) to avoid changing the existing binding for the
  existing PCIe phy instances in ipq5018/ipq5332. Although the silicon
  is capable of supporting both PCIe and USB3, the instances in scope
  are wired for single mode only. The next patch set will register both
  PCIe and USB3 PHYs for the combo PHY instance in IPQ5332 and use
  #phy-cells to select the right PHY in the respective PCIe and USB3
  controller nodes.
- Updated clock order of the IPQ5018 USB3 PHY node to match the order in
  the binding file.
- Corrected commit title of last patch to enable the USB3 PHY on the
  IPQ5018 RDP432-C2 board.
- Link to v3: https://lore.kernel.org/r/20260825-ipq5018-usb3-v3-0-39be0955a6aa@outlook.com

Changes in v3:
- The biggest change of this revision is that it does not create a new
  driver but instead adjust the existing qcom-uniphy-pcie-28lp driver
  for which the binding is also updated. Both the binding and the driver
  have been renamed to reflect the updated scope for both PCIe and USB3.
- The description of the qcom,phy-usb-mux-sel property has been updated
  based on Krzysztof's feedback to clarify that PCIe is the default mode
  (with absence of the property) and that the property is only used to
  select USB3 mode.
- Updated the driver using multiple patches to:
  - Rename the driver (incl. symbol) and change scope from PCIe to PCIe
    and USB3 combo PHY, existing compatible strings remain unchanged.
  - Refactor and simplify the phy initialization register/value pairs
  - Use bulk reset_control API to allow for uniform way of acquiring and
    managing resets for both legacy (unnamed resources) and new (named
    resources) to maintain backward compatibility.
  - Add support for the USB3 PHY instance on IPQ5018 SoCs.
  - Add support for the combo PCIe/USB3 PHY instance on IPQ5332 SoCs.
- Updated the compatible string of the existing PCIe PHY (instance 0)
  node in the IPQ5332 SoC devicetree to reflect it is a combo PCIe/USB3
  PHY. In addition to the existing PCIe-specific resources, added the
  clock and resets required for USB3 support. The node is now used for
  both PCIe and USB3 PHYs, and the correct PHY instance is returned
  based on the phy-cells argument.
- Added a patch to enable building the driver as a module (which was
  missing for the original driver).
- Updated Praveen's email address to praveenkumar.i@oss.qualcomm.com
  including his SoB tags and retained his authorship of the original
  patches.
- Moved patches related to flattening the USB controllers nodes to a
  separate patch series:
  link: https://lore.kernel.org/r/20260825-ipq-flatten-usb-v1-0-5c1f3170bbe9@outlook.com
- Moved patches related to enabling USB3 for Qualcomm IPQ5332 to a
  separate patch series (to be submitted).
- Link to v2: https://lore.kernel.org/r/20260812-ipq5018-usb3-v2-0-8f355d7ff0ef@outlook.com

Changes in v2:
- Rebased on top of master tree
- Included support for IPQ5018
- Changed bindings filename to match compatible string
- Dropped items from compatible list in bindings file
- Added required block in bindings file
- Removed double space of reset property in example in bindings file
- Added branching logic based on compatible string to define the right
  clocks per SoC in bindings file
- Renamed phy driver to phy-qcom-uniphy-usb-ss-22ull.c
- Added missing error handling uniphy_usb_init in phy driver
- Changed to use devm_clk_hw_register_fixed_rate to register fixed rate
  pipe clock
- Changed to use devm_of_clk_add_hw_provider to register clock provider
- Release exclusive get of vdd and changed to devm_regulator_get as the
  regulator supply is also acquired by the m31 USB2 phy driver
- Inlined acquisition of clocks to phy probe function
- Use reverse xmas tree sorting of variables in phy driver probe
- Moved USB mux selection away from phy init to probe as it needs to be
  set before the controller is taken out of reset.
- Flattened the USB controller nodes in line with latest bindings and
  flattened driver approach for both SoCs.
- Set clock frequencies in IPQ5018 controller node to ensure they're
  parented correctly and override any freqs set by the bootloader.
- Removed patch to add usb phy node for IPQ5332 as the pcie0 phy shares
  the same MMIO as the usb3 phy. Hence, chose the approach to override
  the compatible string of said node and assign the right clocks, reset,
  and related properties upon enabling it as a USB3 phy instead of
  adding a new node with the same unit and reg address space.
- Link to v1: https://lore.kernel.org/r/20230929084209.3033093-1-quic_ipkumar@quicinc.com

---
George Moussalem (13):
      dt-bindings: phy: qcom,ipq5332-uniphy-pcie: Document the IPQ5018 USB3 PHY
      phy: qualcomm: qcom-uniphy-pcie-28lp: Convert to PCIe/USB3 combo PHY driver
      phy: qualcomm: qcom-uniphy-pcie-usb3-28lp: Remove unused of_device.h header file
      phy: qualcomm: qcom-uniphy-pcie-usb3-28lp: Drop unused phy_to_dw_phy macro
      phy: qualcomm: qcom-uniphy-pcie-usb3-28lp: Refactor init regs table definitions
      phy: qualcomm: qcom-uniphy-pcie-usb3-28lp: Use bulk reset_control API
      phy: qualcomm: qcom-uniphy-pcie-usb3-28lp: Assert reset on clock enable failure
      phy: qualcomm: qcom-uniphy-pcie-usb3-28lp: Add support for USB3 PHY on IPQ5018
      arm64: dts: qcom: ipq5018: Add USB Super-Speed PHY node
      dt-bindings: usb: qcom,snps-dwc3: Add clocks for USB3 on Qualcomm IPQ5018
      arm64: dts: qcom: ipq5018: Add clocks required for USB3 support
      arm64: dts: qcom: ipq5018: Add Super-Speed UNIPHY to USB node
      arm64: dts: qcom: ipq5018-rdp432-c2: Enable USB Super-Speed PHY

 .../bindings/phy/qcom,ipq5332-uniphy-pcie-phy.yaml |  44 +-
 .../devicetree/bindings/usb/qcom,snps-dwc3.yaml    |  21 +-
 arch/arm64/boot/dts/qcom/ipq5018-rdp432-c2.dts     |  14 +
 arch/arm64/boot/dts/qcom/ipq5018.dtsi              |  33 +-
 drivers/phy/qualcomm/Kconfig                       |  24 +-
 drivers/phy/qualcomm/Makefile                      |   2 +-
 drivers/phy/qualcomm/phy-qcom-uniphy-pcie-28lp.c   | 331 ---------------
 .../phy/qualcomm/phy-qcom-uniphy-pcie-usb3-28lp.c  | 461 +++++++++++++++++++++
 8 files changed, 574 insertions(+), 356 deletions(-)
---
base-commit: 32b6ef9a5d0eca44f9cd91f52f4faa89f145a0de
change-id: 20260803-ipq5018-usb3-4b289b1ed16e
prerequisite-message-id: <20260906-ipq-flatten-usb-v3-0-13e4e0f63123@outlook.com>
prerequisite-patch-id: dd37852a0fd8928e6dd6d66e62c06d7d8f5d38d0
prerequisite-patch-id: 60972378af51aa5a2797a0ff0e62214e7dd243fe
prerequisite-patch-id: 5b791e87c7884503287a8a536958d89eb1969f80
prerequisite-patch-id: 95483f0c1984a0c16902b52b7b26793c38f466fe
prerequisite-patch-id: 51b5158ae634dd1c0713d77b0bb9473b4c88985e
prerequisite-patch-id: 5bf2892e76e4c1d3fd4e93f093c8169e23e0908d
prerequisite-patch-id: bb7b127468635b641c24555cd2e81fa201087ecd
prerequisite-patch-id: 6668bf3110dc6f763084c0c5d65833a85301bf44
prerequisite-patch-id: b7ebb4aec1ea4e78b2d498018b1413aaa056555b
prerequisite-patch-id: eeb34fd04ec7c02da54b06f4730a9b2bb75a71e8

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

