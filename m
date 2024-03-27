From: Keguang Zhang <keguang.zhang@gmail.com>
Subject: [PATCH v6 0/3] Add support for Loongson-1 NAND
Date: Wed, 27 Mar 2024 18:43:58 +0800
Message-Id: <20240327-loongson1-nand-v6-0-7f9311cef020@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAG74A2YC/zWNyw7CIBBFf6WZtUN4VLCu/A/jgpSBElswoMbY9
 N9FEzc3OYt7zgqVSqQKx26FQs9YY04N9K6DcbIpEEbXGCSXPVdC45xzCjUngckmh8NBSeOMIe4
 1tNOtkI+vn/B8aexLXvA+FbJ/jeD7trKXQjEzcIMCrxQercXe3+IpLDbObMwLbNsHP9fsmqAAA
 AA=
To: Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>, 
 Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-mtd@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-mips@vger.kernel.org, devicetree@vger.kernel.org, 
 Keguang Zhang <keguang.zhang@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711536289; l=2068;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=5LDshXlu0PfiuyoM4qYt8E3ozT2zpeM2FAiCZBLBCNs=;
 b=3RTvOkvFiswtfYQcWbIvcSER2itdIL0AeQVtEs/e5MrHwNDzLk5E+H6/2S30psHNXdtb6+jed
 pv25qL0eBUqAmGtwVhy5+Sj4Dx+dqMpuibTVWD+W7vTe++nIoskh5DK
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the driver and dt-binding document for Loongson-1 NAND.
And modify nand_read_subpage() to allow subpage read by a single operation.

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
Keguang Zhang (3):
      dt-bindings: mtd: Add Loongson-1 NAND Controller
      mtd: rawnand: Enable monolithic read when reading subpages
      mtd: rawnand: Add Loongson-1 NAND Controller driver

 .../devicetree/bindings/mtd/loongson,ls1x-nfc.yaml |  66 ++
 drivers/mtd/nand/raw/Kconfig                       |   7 +
 drivers/mtd/nand/raw/Makefile                      |   1 +
 drivers/mtd/nand/raw/loongson1_nand.c              | 748 +++++++++++++++++++++
 drivers/mtd/nand/raw/nand_base.c                   |   5 +-
 include/linux/mtd/rawnand.h                        |   5 +
 6 files changed, 830 insertions(+), 2 deletions(-)
---
base-commit: 084c8e315db34b59d38d06e684b1a0dd07d30287
change-id: 20240316-loongson1-nand-98327d77e0f6

Best regards,
-- 
Keguang Zhang <keguang.zhang@gmail.com>

