From: George Moussalem <george.moussalem@outlook.com>
Subject: [PATCH v3 00/12] Enable USB3 for Qualcomm IPQ5018
Date: Tue, 25 Aug 2026 16:37:17 +0400
Message-Id: <20260825-ipq5018-usb3-v3-0-39be0955a6aa@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/1XP0WrDIBTG8VcJXs9y1JhoKKPvMcqI8bhKm9iqC
 Rul7z6TbrBd/i/Oj+/cScLoMZGuupOIi08+TCXES0WGUz99IPW2NOHAG1AgqL/eJDBF52QErQ1
 X2jC0rEFSTq4Rnf/cuLdjaRfDSPMpYv+LCNBcg6o56J0AUVJQRm+zH9799TyPfTys4adhN4RxN
 U8+5RC/toULX+WfMYz/H7NwClQ5IaVtnQN0hzDnSwjnTTo+nvsiFj/5/BxJRkyp377sqv3T5XJ
 1qbv0OeO02nRhhZYDc4K1YAzqv/TrutL0CWmJ0eeuqg1TaI1V2IJrsVENWNmIEkzwula6seC0H
 MqoxzekDQodggEAAA==
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
 Manivannan Sadhasivam <mani@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, George Moussalem <george.moussalem@outlook.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787661450; l=7142;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=U4owbHtI3rszLAULeon1HWVvno+mZbXDsXARqkNQLT4=;
 b=q1P7Ien6S2ca3Bt6wVt6HjT4tDSGE2ikZPARJb4lGxtcO42KW9AiFF/CfD9pALS70t8erIIZ3
 pMn++8/u6LjB76G58zGtPOY1aEhqNC3xJl4GVDw2jpFYjfxzjUrKa7M
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
   link: https://lore.kernel.org/r/20260825-ipq-flatten-usb-v1-0-5c1f3170bbe9@outlook.com
2. Enable USB3 for Qualcomm IPQ5018 (this patch series)
3. Enable USB3 for Qualcomm IPQ5332 (to be submitted)

---
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
George Moussalem (12):
      dt-bindings: phy: qcom,ipq5332-uniphy-pcie: Change to PCIe/USB3 combo PHY
      dt-bindings: phy: qcom,ipq5332-uniphy-pcie-usb3: Document the IPQ5018 USB3 PHY
      phy: qualcomm: qcom-uniphy-pcie-28lp: Convert to PCIe/USB3 combo PHY driver
      phy: qualcomm: qcom-uniphy-pcie-usb3-28lp: Refactor init regs table definitions
      phy: qualcomm: qcom-uniphy-pcie-usb3-28lp: Use bulk reset_control API
      phy: qualcomm: qcom-uniphy-pcie-usb3-28lp: Improve error handling in power_on
      phy: qualcomm: qcom-uniphy-pcie-usb3-28lp: Add support for USB3 PHY on IPQ5018
      arm64: dts: qcom: ipq5018: Add USB Super-Speed PHY node
      dt-bindings: usb: qcom,snps-dwc3: Add clocks for USB3 on Qualcomm IPQ5018
      arm64: dts: qcom: ipq5018: Add clocks required for USB3 support
      arm64: dts: qcom: ipq5018: Add Super-Speed UNIPHY to USB node
      arm64: dts: qcom: ipq5018: Enable USB Super-Speed PHY

 .../bindings/phy/qcom,ipq5332-uniphy-pcie-phy.yaml | 109 ------
 .../phy/qcom,ipq5332-uniphy-pcie-usb3-phy.yaml     | 165 ++++++++
 .../devicetree/bindings/usb/qcom,snps-dwc3.yaml    |  21 +-
 arch/arm64/boot/dts/qcom/ipq5018-rdp432-c2.dts     |  14 +
 arch/arm64/boot/dts/qcom/ipq5018.dtsi              |  32 +-
 drivers/phy/qualcomm/Kconfig                       |  24 +-
 drivers/phy/qualcomm/Makefile                      |   2 +-
 drivers/phy/qualcomm/phy-qcom-uniphy-pcie-28lp.c   | 331 ----------------
 .../phy/qualcomm/phy-qcom-uniphy-pcie-usb3-28lp.c  | 422 +++++++++++++++++++++
 include/dt-bindings/phy/phy-qcom-qmp.h             |   4 +
 10 files changed, 663 insertions(+), 461 deletions(-)
---
base-commit: 4b18edbd8e70f7e6860d56370f13244896d0f95c
change-id: 20260803-ipq5018-usb3-4b289b1ed16e
prerequisite-message-id: <20260825-ipq-flatten-usb-v1-0-5c1f3170bbe9@outlook.com>
prerequisite-patch-id: d1ba4ccf4658d7373d60a1cf4b1057ca4ee9a1fa
prerequisite-patch-id: 2fc086a7ab95e5344fdd2d4d98840cff0548d127
prerequisite-patch-id: 2109e69ad19d1514823f5972462bda1300b6a6de
prerequisite-patch-id: 79132aa42b4bebcf6188ccb90c73b5b35ac73105
prerequisite-patch-id: 3f1e314656365cddccb4517e87c3b7c1737dc0a7
prerequisite-patch-id: 46ebb170aef0337dc431f573693a07f1ba91ee1f
prerequisite-patch-id: 684072c5491d2f3426741c1555034be79ced4ba0
prerequisite-patch-id: 114e9a12050675f96c6e59aee682a2ccbdef3a17
prerequisite-patch-id: b85b0caa80098c380e4448f8a3dfd9675a3938b0

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

