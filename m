From: Colin Huang <u8813345@gmail.com>
Subject: [PATCH v7 00/11] ARM: dts: aspeed: anacapa: restructure devicetree
 for development-phase
Date: Tue, 01 Sep 2026 20:15:15 +0800
Message-Id: <20260901-anacapa-devlop-phase-devicetree-v7-0-0bd71d2e0105@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANPBlmoC/43RzW6DMAzA8Vepcl6mfBCH7LT3mHpwHadEagFBh
 VZVvPtCL0XsQI9/H3625IcYecg8iq/DQww85TF3bQn/cRDUYHtmmWNpYZQBVSkvsUXCHmXk6dL
 1sm9w5CUy8W1glpVWOtpktSElitIPnPLvc8PPsXSTx1s33J8LJ71M37cnLZUM/hTAgick+32+Y
 r58UncViz2ZtRf2PVM8qJM1NXgN7p9nXx4os+/Z4nkKllxMdQynrVe9vFq5fa8qnovgWXFCILf
 13MrTdt9zxSOvXJ3ARgK/9WDlmTfug+UfygU0aHwgXnvzPP8BlrlDol4CAAA=
X-Change-ID: 20260407-anacapa-devlop-phase-devicetree-4101d3f312c0
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>, 
 Ryan Chen <ryan_chen@aspeedtech.com>, 
 Billy Tsai <billy_tsai@aspeedtech.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 colin.huang2@amd.com, Colin Huang <u8813345@gmail.com>, 
 Carl Lee <carl.lee@amd.com>, Rex Fu <rex.fu.amd@gmail.com>, 
 Andy Chung <Andy.Chung@amd.com>, Peter Shen <peter.shen@amd.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788264930; l=4763;
 i=u8813345@gmail.com; s=20260202; h=from:subject:message-id;
 bh=ih7W+wXfiTJthvY1vQFGO1aRjeSHWvFND7AC85htw0A=;
 b=s06DfTGT9sXXP1OOnhTvtLZ4KhucHRzdn4dQbTAet9lwP0+PLSpge/6xQit7R/XJINXc9FhPf
 6LnI95yaarxCirh1xyv2My06xMunVm/zWxHM6quFXlou41hI/8dk2rA
X-Developer-Key: i=u8813345@gmail.com; a=ed25519;
 pk=Zlg0WqpCw4qbswOqamTBTXIchwR/3SnYZpy7rjaGMdQ=
X-Endpoint-Received: by B4 Relay for u8813345@gmail.com/20260202 with auth_id=761
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series refactors the Anacapa BMC devicetree layout to better support
development-phase hardware revisions (EVT1/EVT2/DVT) while keeping a platform
entrypoint.

Signed-off-by: Colin Huang <u8813345@gmail.com>
---
Changes in v7:
- Fix [Critical] Devicetree ABI breakage due to removal of generic compatible string
  keep to use compatible string "facebook,anacapa-bmc".
- Fix [Low] Redundant redefinition of inherited properties in the `evt2.dts` file.
- Fix [Low] Included devicetrees use `.dts` extension instead of `.dtsi`
  aspeed-bmc-facebook-anacapa-evt1.dts -> aspeed-bmc-facebook-anacapa-evt1.dtsi
  aspeed-bmc-facebook-anacapa-evt2.dts -> aspeed-bmc-facebook-anacapa-evt2.dtsi
  aspeed-bmc-facebook-anacapa-dvt.dts -> aspeed-bmc-facebook-anacapa-dvt.dtsi
- Link to v6: https://lore.kernel.org/r/20260825-anacapa-devlop-phase-devicetree-v6-0-9059a2a279ce@gmail.com

Changes in v6:
- Fold the following fixes into this series: 
   - Remove redundant vhub pinctrl-names
   - Use default SPI2 memory mapping
   - Fix dt-check-style strict violations
- Move p3v3_bmc_aux node from evt1.dts to evt2.dts for dt-check-style
- Fix the patch author information
- Link to v5: https://lore.kernel.org/r/20260813-anacapa-devlop-phase-devicetree-v5-0-c7058f63dc67@gmail.com

Changes in v5:
- Remove redundant vhub pinctrl-names
- Use default SPI2 memory mapping
- Fix dt-check-style strict violations
- Add Acked-by from Conor Dooley
- Sort compatible strings in alphabetical order
- More commit message for ARM: dts: aspeed: anacapa: Add EVT1 devicetree and point wrapper to it.
- Update commit message to describe both LPDB and RPDB GPIO expanders  
- Link to v4: https://lore.kernel.org/r/20260805-anacapa-devlop-phase-devicetree-v4-0-5d67e0efa6c5@gmail.com

Changes in v4:
- Capitalize the first word of the short description.
- Rework the Anacapa development-phase devicetree hierarchy.
- Ensure that anacapa-evt1 generates an identical devicetree to the existing aspeed-bmc-facebook-anacapa.dts.
- Add SPI flash VCC supply.
- Simplify leakage GPIO line names.
- Add LPDB fuse monitor GPIO expander.
- Link to v3: https://lore.kernel.org/r/20260602-anacapa-devlop-phase-devicetree-v3-0-7c93c5df8d9b@gmail.com

Changes in v3:
- Restructure the EVT2 devicetree to inherit from the EVT1 devicetree, making it incremental rather than standalone.
- Add the DVT devicetree, inheriting from the EVT2 devicetree.
- Enable MCTP and FRU support for the NIC.
- Align PDB fan GPIO numbering.
- Add an EEPROM device node for the NFC adaptor board.
- Add an additional EEPROM device node for the SCM.
- Add shunt resistor values for HSC monitors
- Link to v2: https://lore.kernel.org/r/20260409-anacapa-devlop-phase-devicetree-v2-0-68f328671653@gmail.com

Changes in v2:
- Fix dtbs_check fail.
  Validated by following command:
    make dt_binding_check DT_SCHEMA_FILES=arm/aspeed/aspeed.yaml
    make CHECK_DTBS=y DT_SCHEMA_FILES=arm/aspeed/aspeed.yaml aspeed/aspeed-bmc-facebook-anacapa.dtb
    make CHECK_DTBS=y DT_SCHEMA_FILES=arm/aspeed/aspeed.yaml aspeed/aspeed-bmc-facebook-anacapa-evt1.dtb
    make CHECK_DTBS=y DT_SCHEMA_FILES=arm/aspeed/aspeed.yaml aspeed/aspeed-bmc-facebook-anacapa-evt2.dtb
- Link to v1: https://lore.kernel.org/r/20260407-anacapa-devlop-phase-devicetree-v1-0-97b96367cac3@gmail.com

---
Andy Chung (1):
      ARM: dts: aspeed: anacapa: Enable MCTP and FRU for NIC

Carl Lee (1):
      ARM: dts: aspeed: anacapa: Add eeprom device node for NFC adaptor board

Colin Huang (4):
      ARM: dts: aspeed: anacapa: Add EVT1 devicetree and point wrapper to it
      ARM: dts: aspeed: anacapa: Add EVT2 devicetree inheriting EVT1
      ARM: dts: aspeed: anacapa: Add DVT devicetree inheriting EVT2
      ARM: dts: aspeed: anacapa: Add additional EEPROM node for SCM

Peter Shen (1):
      ARM: dts: aspeed: anacapa: evt2: Add shunt resistor values for HSC monitors

Rex Fu (4):
      ARM: dts: aspeed: anacapa: Align PDB fan GPIO numbering
      ARM: dts: aspeed: anacapa: Add LPDB fuse monitor GPIO expander
      ARM: dts: aspeed: anacapa: Simplify leakage GPIO line names
      ARM: dts: aspeed: anacapa: Add SPI flash VCC supply

 .../aspeed/aspeed-bmc-facebook-anacapa-dvt.dtsi    |  260 +++++
 .../aspeed/aspeed-bmc-facebook-anacapa-evt1.dtsi   | 1131 ++++++++++++++++++++
 .../aspeed/aspeed-bmc-facebook-anacapa-evt2.dtsi   |  408 +++++++
 .../dts/aspeed/aspeed-bmc-facebook-anacapa.dts     | 1078 +------------------
 4 files changed, 1800 insertions(+), 1077 deletions(-)
---
base-commit: cd7d1ef7d74ed5f5a1790a40389bc38382924556
change-id: 20260407-anacapa-devlop-phase-devicetree-4101d3f312c0

Best regards,
-- 
Colin Huang <u8813345@gmail.com>

