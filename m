From: Takahiro Kuwano <takahiro.kuwano@infineon.com>
Subject: [PATCH v2 0/4] mtd: spi-nor: split SFDP, ID database, and fixups
Date: Thu, 24 Sep 2026 18:10:04 +0900
Message-Id: <20260924-split-sfdp-id-v2-0-aafc70e0b657@infineon.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOzotGoC/yXM0QpAQBCF4VfRXNsaG4pXkQu7OxiJbQcpeXeLy
 6/T+S8QCkwCdXJBoIOF1yVCpwnYsVsGUuyiQaMusdK5Ej/zpqR3Pi6qKNEaRJflWED8+EA9n1+
 vaX/Lbiay2xuB+34AMhgi3XEAAAA=
X-Change-ID: 20260924-split-sfdp-id-560cb00d1405
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, Vignesh R <vigneshr@ti.com>, 
 Michael Walle <mwalle@kernel.org>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, 
 Tudor Ambarus <tudor.ambarus@linaro.org>, 
 Pratyush Yadav <pratyush@kernel.org>, Marek Vasut <marex@nabladev.com>, 
 Tanmay Kathpalia <tanmay.kathpalia@altera.com>, 
 Raymond Mao <raymond.mao@riscstar.com>, Ssunk <ssunkkan@gmail.com>, 
 Flaviu Nistor <flaviu.nistor@gmail.com>, 
 Eugen Hristev <ehristev@kernel.org>, Jeffrey Yu <jeyu@issi.com>, 
 Takahiro Kuwano <takahiro.kuwano@infineon.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790241010; l=3508;
 i=takahiro.kuwano@infineon.com; s=20250227; h=from:subject:message-id;
 bh=CQ0CFZojaJUYmTjR6jeK96ke4oz9tmnbjsEjRrPew48=;
 b=TGWKfpFGbAC6WPIeue3zf/xor0kzp2Me+/+uPUlFBhanRq5C6dTgFp+5FawNj+DtP7Cza+8fg
 MK4j5C3ak+6Br9y4GooOEWU1D3Cm1BtrbwZIGTLXtNBLR4/4wUyvW6f
X-Developer-Key: i=takahiro.kuwano@infineon.com; a=ed25519;
 pk=aS8V9WLuMUkl0vmgD0xJU19ZajdJmuyFBnBfVj0dfDs=
X-Endpoint-Received: by B4 Relay for takahiro.kuwano@infineon.com/20250227 with auth_id=566
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The spi-nor-core.c contains optional logics like SFDP and manufcaturer
specific fixups. The spi-nor-ids.c has single large ID database. There
are many #ifdef directives in those files and that negatively affects
readability and maintainability.

This series, as the first step of cleanup, move SFDP logic, IDs, and
fixups to newly source files. Reworking, renaming, and reformating
existing code is not a scope of this series and further cleanup will be
taken place in follow-up patches.

Here is the code size impact when applying this series.
Measured by my AMD Zynq-7000 (ARM32) environment with SFDP and all
manufcaturers are enabled.

SPI-NOR:
            text    data     bss     dec     hex filename
BEFORE    731133   14696       0  745829   b6165 u-boot
AFTER     732301   14696       0  746997   b65f5 u-boot
DELTA      +1168       0       0

TINY:
            text    data     bss     dec     hex filename
BEFORE     80492    3744     248   84484   14a04 spl/u-boot-spl
AFTER      80748    3744     248   84740   14b04 spl/u-boot-spl
DELTA       +256

---
Changes in v2:
- Rebase on top of next
- Link to v1: https://lore.kernel.org/u-boot/20260612-split-id-table-into-vendor-files-v1-0-dfaaa82cc6f0@infineon.com/

To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>
Cc: Vignesh R <vigneshr@ti.com>
Cc: Michael Walle <mwalle@kernel.org>
Cc: Miquel Raynal <miquel.raynal@bootlin.com>
Cc: Tudor Ambarus <tudor.ambarus@linaro.org>
Cc: Pratyush Yadav <pratyush@kernel.org>
Cc: Marek Vasut <marex@nabladev.com>
Cc: Tanmay Kathpalia <tanmay.kathpalia@altera.com>
Cc: Raymond Mao <raymond.mao@riscstar.com>
Cc: Ssunk <ssunkkan@gmail.com>
Cc: Flaviu Nistor <flaviu.nistor@gmail.com>
Cc: Eugen Hristev <ehristev@kernel.org>
Cc: Jeffrey Yu <jeyu@issi.com>
Signed-off-by: Takahiro Kuwano <takahiro.kuwano@infineon.com>

---
Takahiro Kuwano (4):
      mtd: spi-nor: move SFDP logic out of the core
      mtd: spi-nor: import manufacturer driver concept from Linux
      mtd: spi-nor: move flash info entries to manufacturer drivers
      mtd: spi-nor: move fixups to manufacturer drivers

 drivers/mtd/spi/Makefile        |   18 +
 drivers/mtd/spi/atmel.c         |   28 +
 drivers/mtd/spi/dosilicon.c     |   25 +
 drivers/mtd/spi/eon.c           |   23 +
 drivers/mtd/spi/fujitsu.c       |   27 +
 drivers/mtd/spi/gigadevice.c    |  140 ++
 drivers/mtd/spi/issi.c          |   84 ++
 drivers/mtd/spi/macronix.c      |  154 +++
 drivers/mtd/spi/micron-st.c     |  169 +++
 drivers/mtd/spi/puya.c          |   56 +
 drivers/mtd/spi/sf_internal.h   |  135 +-
 drivers/mtd/spi/sfdp.c          |  720 ++++++++++
 drivers/mtd/spi/sfdp.h          |  152 +++
 drivers/mtd/spi/siliconkaiser.c |   18 +
 drivers/mtd/spi/spansion.c      |  700 ++++++++++
 drivers/mtd/spi/spi-nor-core.c  | 2751 +++++++--------------------------------
 drivers/mtd/spi/spi-nor-ids.c   |  752 +----------
 drivers/mtd/spi/spi-nor-tiny.c  |   11 +-
 drivers/mtd/spi/sst.c           |   34 +
 drivers/mtd/spi/winbond.c       |  250 ++++
 drivers/mtd/spi/xmc.c           |   27 +
 drivers/mtd/spi/xtx.c           |   54 +
 drivers/mtd/spi/zbit.c          |   19 +
 include/linux/mtd/spi-nor.h     |    2 +
 24 files changed, 3378 insertions(+), 2971 deletions(-)
---
base-commit: 6b78e91c4d4e9c47fe825bd2d31c0496d15f03d9
change-id: 20260924-split-sfdp-id-560cb00d1405

Best regards,
--  
Takahiro Kuwano <takahiro.kuwano@infineon.com>

