From: Keguang Zhang <keguang.zhang@gmail.com>
Subject: [PATCH v13 0/2] Add support for Loongson-1 NAND
Date: Wed, 05 Mar 2025 19:05:03 +0800
Message-Id: <20250305-loongson1-nand-v13-0-a5bac21631cd@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAN8vyGcC/2XQwW7DIAyA4Vepch6VbQjgnfYe0w4JgRStDVPSR
 duqvvtItS5VuCCB9H+2uFSTH6OfqufdpRr9HKeYhnxB+bSr3KEZei9ilx8qAlIgUYtjSkM/pQH
 F0AydYCvJdMZ4CLrK0cfoQ/y6ia9v+R7GdBLnw+ibO4NQ55MUodwbBiNQvPv+M8/a/ywTX/pTE
 497l06Ld4jTOY3ftwVnvah/q5DZrjJrAcIElojOByB4kJZVZrPmSkKRm5xrMNY4iSo0apvbNbd
 gi9zm3LHufKPQtgq3Oa85Uzmdc87OmZalqhuQ2xzhv0cAKnqEDKBBTT4EC54KAFeAsPw9xAy0m
 snVlq1t2wKgO1BDFkqAMlDLGgwzd17yI3C9Xn8BqDKimm0CAAA=
To: Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-mtd@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-mips@vger.kernel.org, 
 Keguang Zhang <keguang.zhang@gmail.com>, 
 Krzysztof Kozlowski <krzk@kernel.org>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741172709; l=5250;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=A34voqNq/lx46quWlbjuRT9G0iCCqdX+8YpwipXpyE4=;
 b=F+f3SXX+hAXIGiykEwZ8MqwBG0UbvYTLiVhBW79MSDkpigv/E2rhuxU3QA1D5C/lNDLnhPAo6
 jV1QmYfrGtRDjgV5JgD3Clz+96CPyZQOWryXsA3aRyzmMU59I4+smX9
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the driver and dt-binding document for Loongson-1 NAND.

Changes in v13:
- Improve ls1x_nand_check_op() to cover all opcode checks and eliminate redundancy.
- Revert ls1x_nand_exec_op().
- Some minor adjustments.
- Link to v12: https://lore.kernel.org/r/20250121-loongson1-nand-v12-0-53507999de39@gmail.com

Changes in v12:
- Add MTD label in the example.
- Use MTD label for mtd->name instead of hardcoded assignment.                                                                                               
- Removed redundant fields addr1_reg and addr2_reg from struct ls1x_nand_op.
- Introduced .set_addr in struct ls1x_nand_host to replace the previous .parse_address,
  and improve its logic using regmap_update_bits() to avoid restoring the row address.
- Improve the logic of ls1x_nand_check_op() to eliminate repetitive checks.
- Add ECC engine type check in ls1x_nand_attach_chip().
- Some minor improvements.
- Link to v11: https://lore.kernel.org/r/20241217-loongson1-nand-v11-0-b692c58988bb@gmail.com

Changes in v11:
- Remove the requirement for 'nand-use-soft-ecc-engine' and 'nand-ecc-algo'.
- Add 'reg-names' to support DMA address.
- Move the DMA address to DT.
- Rename the source file to 'loongson1-nand-controller.c'.
- Improve the logic of ls1x_nand_op_cmd_mapping().
- Improve the logic of ls1x_nand_check_op() to exclude unsupported cases.
- Substitute 'host' for the improper term 'nfc'.
- Some minor fixes and adjustments.
- Link to v10: https://lore.kernel.org/r/20241002-loongson1-nand-v10-0-17162eff80e2@gmail.com

Changes in v10:                                                                                                                                              
- Fix the build error reported by kernel test robot.
  Link: https://lore.kernel.org/oe-kbuild-all/202409220010.vctkHddZ-lkp@intel.com
- Link to v9: https://lore.kernel.org/r/20240920-loongson1-nand-v9-0-9cc7b9345a03@gmail.com

Changes in v9:
- Change the compatible to 'loongson,ls1*-nand-controller'.
- Rename the dt-binding file to loongson,ls1b-nand-controller.yaml.
- Update MAINTAINERS file accordingly.
- Some minor adjustments.
- Rebasing due to recent upstream changes.
- Link to v8: https://lore.kernel.org/r/20240808-loongson1-nand-v8-0-c96dea418b41@gmail.com

Changes in v8:
- Add a description part.
- Adjust the compatible because the match data for ls1c-nfc differs from ls1b-nfc.
- Mark 'nand-use-soft-ecc-engine' and 'nand-ecc-algo' as mandatory.
- Delete the superfluous blank lines.
- Drop NAND_MONOLITHIC_READ and add support for real subpage read instead.
- Simplify the logic of ls1b_nand_parse_address() and ls1c_nand_parse_address().
- Split ls1x_nand_set_controller() into ls1x_nand_parse_instructions()
  and ls1x_nand_trigger_op().
- Implement ls1x_nand_op_cmd_mapping() to convert the opcodes instead of forcing them.
- Add ls1x_nand_check_op().
- Remove struct ls1x_nand after moving its members to struct ls1x_nfc.
- Add the prefix 'LS1X_' for all registers and their bits.
- Drop the macros: nand_readl() and nand_writel().
- Some minor fixes and improvements.
- Link to v7: https://lore.kernel.org/r/20240430-loongson1-nand-v7-0-60787c314fa4@gmail.com

Changes in v7:
- Rename the file to loongson,ls1b-nfc.yaml
- Rename the Kconfig dependency to LOONGSON1_APB_DMA
- Link to v6: https://lore.kernel.org/r/20240327-loongson1-nand-v6-0-7f9311cef020@gmail.com

Changes in v6:
- Amend Kconfig
- Add the dt-binding document
- Modify nand_read_subpage() to allow subpage read by a single operation
- Add DT support for driver
- Use DT data instead of platform data
- Remove MAX_ID_SIZE
- Remove case NAND_OP_CMD_INSTR in ls1x_nand_set_controller()
- Move ECC configuration to ls1x_nand_attach_chip()
- Rename variable "nand" to "ls1x"
- Rename variable "nc" to "nfc"
- Some minor fixes
- Link to v5: https://lore.kernel.org/all/20210520224213.7907-1-keguang.zhang@gmail.com

Changes in v5:
- Update the driver to fit the raw NAND framework.
- Implement exec_op() instead of legacy cmdfunc().
- Use dma_request_chan() instead of dma_request_channel().
- Some minor fixes and cleanups.

Changes in v4:
- Retrieve the controller from nand_hw_control.

Changes in v3:
- Replace __raw_readl/__raw_writel with readl/writel.
- Split ls1x_nand into two structures:
ls1x_nand_chip and ls1x_nand_controller.

Changes in v2:
- Modify the dependency in Kconfig due to the changes of DMA module.

Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
Keguang Zhang (2):
      dt-bindings: mtd: Add Loongson-1 NAND Controller
      mtd: rawnand: Add Loongson-1 NAND Controller Driver

 .../mtd/loongson,ls1b-nand-controller.yaml         |  72 ++
 MAINTAINERS                                        |   1 +
 drivers/mtd/nand/raw/Kconfig                       |   7 +
 drivers/mtd/nand/raw/Makefile                      |   1 +
 drivers/mtd/nand/raw/loongson1-nand-controller.c   | 853 +++++++++++++++++++++
 5 files changed, 934 insertions(+)
---
base-commit: 8936cec5cb6e27649b86fabf383d7ce4113bba49
change-id: 20240316-loongson1-nand-98327d77e0f6

Best regards,
-- 
Keguang Zhang <keguang.zhang@gmail.com>

