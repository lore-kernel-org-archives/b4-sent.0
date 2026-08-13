From: Colin Huang <u8813345@gmail.com>
Subject: [PATCH v5 00/15] ARM: dts: aspeed: anacapa: restructure devicetree
 for development-phase
Date: Thu, 13 Aug 2026 19:59:30 +0800
Message-Id: <20260813-anacapa-devlop-phase-devicetree-v5-0-c7058f63dc67@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKKxfWoC/43NsW7DIBSF4VeJmEt1AQOmU98j6kAulxgpsS2IU
 KrI716cJVEyuON/hu/cWKGcqLCv3Y1lqqmkaWyhP3YMBz8eiafQmkmQBjqw3I8e/ex5oHqaZj4
 PvtAaCemSiXgnQAQVlZAIrClzppiu94f9T+shlcuUf++HVazr/+0qOHBnD84oY9Gj+j6efTp94
 nRmq13ls+e2Pdk800cle2OF0W+eengG5LanmmfRKdQh9sEdXr3u4fWgt72ueToYS0DRG9TP3rI
 sfyMIS5y+AQAA
X-Change-ID: 20260407-anacapa-devlop-phase-devicetree-4101d3f312c0
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 colin.huang2@amd.com, Colin Huang <u8813345@gmail.com>, 
 Conor Dooley <conor.dooley@microchip.com>, Carl Lee <carl.lee@amd.com>, 
 Rex Fu <rex.fu.amd@gmail.com>, Andy Chung <Andy.Chung@amd.com>, 
 Peter Shen <peter.shen@amd.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786622378; l=4004;
 i=u8813345@gmail.com; s=20260202; h=from:subject:message-id;
 bh=KspGXcyx0zJEN9WlK/sXLb3sPuYZz8T7kJQlmBlGklA=;
 b=zJW+wxbsgrn7odameHSrHPNFOoXZrsOk1aKRQSZdYLK+ZFFLrxpbYx13lcUvpxoLLTh86LQIc
 5DGIJRDwC4WBE5N5ifI7bcvBcxB1DCkUCHaZO1jhbzOGYMoU0i7Upcq
X-Developer-Key: i=u8813345@gmail.com; a=ed25519;
 pk=Zlg0WqpCw4qbswOqamTBTXIchwR/3SnYZpy7rjaGMdQ=
X-Endpoint-Received: by B4 Relay for u8813345@gmail.com/20260202 with auth_id=761
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series refactors the Anacapa BMC devicetree layout to better support
development-phase hardware revisions (EVT1/EVT2/DVT) while keeping a platform
entrypoint.

Signed-off-by: Colin Huang <u8813345@gmail.com>
---
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

Colin Huang (9):
      dt-bindings: arm: aspeed: Add Anacapa EVT1 EVT2 DVT board
      ARM: dts: aspeed: anacapa: Add EVT1 devicetree and point wrapper to it
      ARM: dts: aspeed: anacapa: Add EVT2 devicetree inheriting EVT1
      ARM: dts: aspeed: anacapa: Add DVT devicetree inheriting EVT2
      ARM: dts: aspeed: anacapa: Add additional EEPROM node for SCM
      ARM: dts: aspeed: anacapa: evt2: Add shunt resistor values for HSC monitors
      ARM: dts: aspeed: anacapa: fix dt-check-style strict violations
      ARM: dts: aspeed: anacapa: Use default SPI2 memory mapping
      ARM: dts: aspeed: anacapa: Remove redundant vhub pinctrl-names

Rex Fu (4):
      ARM: dts: aspeed: anacapa: Align PDB fan GPIO numbering
      ARM: dts: aspeed: anacapa: Add LPDB fuse monitor GPIO expander
      ARM: dts: aspeed: anacapa: Simplify leakage GPIO line names
      ARM: dts: aspeed: anacapa: Add SPI flash VCC supply

 .../devicetree/bindings/arm/aspeed/aspeed.yaml     |    3 +
 .../dts/aspeed/aspeed-bmc-facebook-anacapa-dvt.dts |  270 +++++
 .../aspeed/aspeed-bmc-facebook-anacapa-evt1.dts    | 1128 ++++++++++++++++++++
 .../aspeed/aspeed-bmc-facebook-anacapa-evt2.dts    |  435 ++++++++
 .../dts/aspeed/aspeed-bmc-facebook-anacapa.dts     | 1078 +------------------
 5 files changed, 1837 insertions(+), 1077 deletions(-)
---
base-commit: 112264fb0bd0a7982b13da18cd3e289e2ab76eed
change-id: 20260407-anacapa-devlop-phase-devicetree-4101d3f312c0

Best regards,
-- 
Colin Huang <u8813345@gmail.com>

