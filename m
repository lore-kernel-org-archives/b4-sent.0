From: Colin Huang <u8813345@gmail.com>
Subject: [PATCH v3 0/9] ARM: dts: aspeed: anacapa: restructure devicetree
 for development-phase
Date: Tue, 02 Jun 2026 21:24:55 +0800
Message-Id: <20260602-anacapa-devlop-phase-devicetree-v3-0-7c93c5df8d9b@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKfZHmoC/43NvQ6CMBSG4Vshna3pDxZw8j6Mw7Ec4CRIm5Y0G
 sK9W5h00vH9hudbWMRAGNm5WFjARJHclEMfCmYHmHrk1OZmSigjSlFxmMCCB95iGp3nfoCIW5D
 FOSDyUgrZ6k5LZQXLig/Y0XN/uN5yDxRnF177YZLb+r+dJBe8qe6N0aayYPWlfwCNR+sebLOT+
 vSa357Knqk7rWpTSXP68tZ1fQNF2GVHHgEAAA==
X-Change-ID: 20260407-anacapa-devlop-phase-devicetree-4101d3f312c0
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 colin.huang2@amd.com, Colin Huang <u8813345@gmail.com>, 
 Carl Lee <carl.lee@amd.com>, Rex Fu <rex.fu.amd@gmail.com>, 
 Andy Chung <Andy.Chung@amd.com>, Peter Shen <peter.shen@amd.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780406700; l=2654;
 i=u8813345@gmail.com; s=20260202; h=from:subject:message-id;
 bh=nFbJfV8A9rkTWO5rSUCpM/WiuDOGMVCW5hVMnvc7Ax0=;
 b=9OYO2EkCb3s9v4KIZOB5CzKtPjN2qZy5OYCUH6Fz2p5VAS0oEFBRGKho+OiFsoj5tC9LPmRC9
 uuXDJTnkyjbAPzvxpLix2GwjKXE5mxRmXb2d5+1JJbL30aFl/2s93uf
X-Developer-Key: i=u8813345@gmail.com; a=ed25519;
 pk=Zlg0WqpCw4qbswOqamTBTXIchwR/3SnYZpy7rjaGMdQ=
X-Endpoint-Received: by B4 Relay for u8813345@gmail.com/20260202 with auth_id=761
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series refactors the Anacapa BMC devicetree layout to better support
development-phase hardware revisions (EVT1/EVT2/DVT) while keeping a platform
entrypoint.

Signed-off-by: Colin Huang <u8813345@gmail.com>
---
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

Colin Huang (5):
      dt-bindings: arm: aspeed: add Anacapa EVT1 EVT2 DVT board
      ARM: dts: aspeed: anacapa: add EVT1 devicetree and point wrapper to it
      ARM: dts: aspeed: anacapa: add EVT2 devicetree inheriting EVT1
      ARM: dts: aspeed: anacapa: add DVT devicetree inheriting EVT2
      ARM: dts: aspeed: anacapa: add additional EEPROM node for SCM

Peter Shen (1):
      ARM: dts: aspeed: anacapa: evt2: add shunt resistor values for HSC monitors

Rex Fu (1):
      ARM: dts: aspeed: anacapa: Align PDB fan GPIO numbering

 .../devicetree/bindings/arm/aspeed/aspeed.yaml     |    3 +
 .../dts/aspeed/aspeed-bmc-facebook-anacapa-dvt.dts |  178 +++
 .../aspeed/aspeed-bmc-facebook-anacapa-evt1.dts    | 1179 ++++++++++++++++++++
 .../aspeed/aspeed-bmc-facebook-anacapa-evt2.dts    |  228 ++++
 .../dts/aspeed/aspeed-bmc-facebook-anacapa.dts     | 1077 +-----------------
 5 files changed, 1589 insertions(+), 1076 deletions(-)
---
base-commit: 7ca1caf017d34396397b19fb4de9ecef256f4acc
change-id: 20260407-anacapa-devlop-phase-devicetree-4101d3f312c0

Best regards,
-- 
Colin Huang <u8813345@gmail.com>

