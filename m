From: George Moussalem <george.moussalem@outlook.com>
Subject: [PATCH v6 0/3] Add support for the IPQ5018 Internal GE PHY
Date: Mon, 30 Jun 2025 16:34:59 +0400
Message-Id: <20250630-ipq5018-ge-phy-v6-0-01be06378c15@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHOEYmgC/23QzU7DMAwH8FeZciYoduK03WnvgTjka2sELF07I
 qap705aDhSy49+Wf7J9Z1MYY5jYfndnY8hxiulcgn7aMdeb8ynw6EtmKJCEkoLH4UICWl46Q3/
 j3mpS5miUC56VoWEMx/i1gi+vJfdxuqbxtvoZluoPRUj/qQxccO+NbVtSAUke0uf1PaW3Z5c+2
 IJl3AJtBeAKCC11o1wDrgbkL6AFVoAsgEKQsjFCgsUaUFugqwBVAPDSAJb90D04gTYAVO/MtJx
 gTKc7Zb318BeY5/kbpdzPD7IBAAA=
X-Change-ID: 20250430-ipq5018-ge-phy-db654afa4ced
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751286906; l=4361;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=6rSwfj0OgqcpS0whNGrBhLm2Rs5oxE6X+ajo/xI0UWA=;
 b=Kvrm1AJSq5+XPEMqSTSBbz73Svierh5rH5IkmJtZWSQFxnpA9c5t37ljwFISOR59szpETEMy+
 9xJp5hJx82hAYhJ8VAVUvAFhRywRflhC6XAAhbjjz2fGsxgp57aQMnF
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The IPQ5018 SoC contains an internal Gigabit Ethernet PHY with its
output pins that provide an MDI interface to either an external switch
in a PHY to PHY link architecture or directly to an attached RJ45
connector.

The PHY supports 10BASE-T/100BASE-TX/1000BASE-T link modes in SGMII
interface mode, CDT, auto-negotiation and 802.3az EEE.

The LDO controller found in the IPQ5018 SoC needs to be enabled to drive
power to the CMN Ethernet Block (CMN BLK) which the GE PHY depends on.
The LDO must be enabled in TCSR by writing to a specific register.

In a phy to phy architecture, DAC values need to be set to accommodate
for the short cable length.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
Changes in v6:
- Rebased on top of linux-next which includes the bindings (patch 2 in
  v5) and driver (patch 3 in v5) picked up from and merged by net-next,
  no changes otherwise.
- Link to v5: https://lore.kernel.org/r/20250610-ipq5018-ge-phy-v5-0-daa9694bdbd1@outlook.com

Changes in v5:
- Removed unused macro definition (IPQ5018_TCSR_ETH_LDO_READY)
- Reverted sorting of header files for which a separate patch can be
  submitted
- Added a comment to explain why the FIFO buffer needs to be reset
- Do not initialize local variable as caught by Russell
- Updated macro definition names to more accurately describe the PHY
  registers and their functions
- Include SGMII as supported interface mode in driver commit message
- Changed error handling of acquirement of PHY reset to use IR_ERR
  instead of IS_ERR_OR_NULL
- Link to v4: https://lore.kernel.org/r/20250609-ipq5018-ge-phy-v4-0-1d3a125282c3@outlook.com

Changes in v4:
- Updated description of qcom,dac-preset-short-cable property in
  accordance with Andrew's recommendation to indicate that if the
  property is not set, no DAC values will be modified.
- Added newlines between properties
- Added PHY ID as compatible in DT bindings for conditional check to
  evaluate correctly. Did a 'git grep' on all other PHY IDs defined in
  the driver but none are explicitly referenced so I haven't added them
- Link to v3: https://lore.kernel.org/r/20250602-ipq5018-ge-phy-v3-0-421337a031b2@outlook.com

Changes in v3:
- Replace bitmask of GEPHY_MISC_ARES with GENMASK as suggested by Konrad
- Removed references to RX and TX clocks as the driver need not
  explicitly enable them. The GCC gatecontrols and routes the PHY's
  output clocks, registered in the DT as fixed clocks, back to the PHY.
  The bindings file has been updated accordingly.
- Removed acquisition and enablement of RX and TX clocks from the driver
- Link to v2: https://lore.kernel.org/r/20250528-ipq5018-ge-phy-v2-0-dd063674c71c@outlook.com

Changes in v2:
- Moved values for MDAC and EDAC into the driver and converted DT
  property qca,dac to a new boolean: qcom,dac-preset-short-cable as per
  discussion.
- Added compatible string along with a condition with a description of
  properties including clocks, resets, and qcom,dac-preset-short-cable
  in the bindings to address bindings issues reported by Rob and to
  bypass restrictions on nr of clocks and resets in ethernet-phy.yaml
- Added example to bindings file
- Renamed all instances of IPQ5018_PHY_MMD3* macros to IPQ5018_PHY_PCS*
- Removed qca,eth-ldo-ready property and moved the TCSR register to the
  mdio bus the phy is on as there's already support for setting this reg
  property in the mdio-ipq4019 driver as per commit:
  23a890d493e3ec1e957bc925fabb120962ae90a7
- Explicitly probe on PHY ID as otherwise the PHY wouldn't come up and
  initialize as found during further testing when the kernel is flashed
  to NAND
- Link to v1: https://lore.kernel.org/r/20250525-ipq5018-ge-phy-v1-0-ddab8854e253@outlook.com

---
George Moussalem (3):
      clk: qcom: gcc-ipq5018: fix GE PHY reset
      arm64: dts: qcom: ipq5018: Add MDIO buses
      arm64: dts: qcom: ipq5018: Add GE PHY to internal mdio bus

 arch/arm64/boot/dts/qcom/ipq5018.dtsi | 48 +++++++++++++++++++++++++++++++++--
 drivers/clk/qcom/gcc-ipq5018.c        |  2 +-
 2 files changed, 47 insertions(+), 3 deletions(-)
---
base-commit: bc4672f3c5df8a47a3e5b4c31dead2b01103e70f
change-id: 20250430-ipq5018-ge-phy-db654afa4ced

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

