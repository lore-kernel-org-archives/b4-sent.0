From: Takahiro Kuwano <takahiro.kuwano@infineon.com>
Date: Fri, 12 Jun 2026 14:40:51 +0900
Subject: [PATCH 3/4] mtd: spi-nor: move flash info entries to manufacturer
 drivers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260612-split-id-table-into-vendor-files-v1-3-dfaaa82cc6f0@infineon.com>
References: <20260612-split-id-table-into-vendor-files-v1-0-dfaaa82cc6f0@infineon.com>
In-Reply-To: <20260612-split-id-table-into-vendor-files-v1-0-dfaaa82cc6f0@infineon.com>
To: u-boot@lists.denx.de
Cc: Tom Rini <trini@konsulko.com>, Vignesh R <vigneshr@ti.com>, 
 Tudor Ambarus <tudor.ambarus@linaro.org>, Michael Walle <mwalle@kernel.org>, 
 Pratyush Yadav <pratyush@kernel.org>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, Marek Vasut <marex@nabladev.com>, 
 Weijie Gao <weijie.gao@mediatek.com>, 
 Takahiro Kuwano <takahiro.kuwano@infineon.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781242882; l=95749;
 i=takahiro.kuwano@infineon.com; s=20250227; h=from:subject:message-id;
 bh=jej1r50820e8nk5Bktwsqh+rGL0CODzPAaM9HRCnoUA=;
 b=gPhIzm8pqv0Y0HhSJWuTwWatjTH8CJrpWS5WcROHQfW6a0duzFgr86/CbspNyIG+oUGJBghue
 FoyyWq4FNelClmA/tJgkVvaxN4VFhgP4kNYIts/4DIkhOmeOaBEfJee
X-Developer-Key: i=takahiro.kuwano@infineon.com; a=ed25519;
 pk=aS8V9WLuMUkl0vmgD0xJU19ZajdJmuyFBnBfVj0dfDs=
X-Endpoint-Received: by B4 Relay for takahiro.kuwano@infineon.com/20250227 with auth_id=566
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Create manufacturer driver files and move flash info entries into them.

Signed-off-by: Takahiro Kuwano <takahiro.kuwano@infineon.com>
---
 drivers/mtd/spi/Makefile        |  17 +
 drivers/mtd/spi/atmel.c         |  28 ++
 drivers/mtd/spi/dosilicon.c     |  25 ++
 drivers/mtd/spi/eon.c           |  23 ++
 drivers/mtd/spi/fujitsu.c       |  27 ++
 drivers/mtd/spi/gigadevice.c    | 136 ++++++++
 drivers/mtd/spi/issi.c          |  84 +++++
 drivers/mtd/spi/macronix.c      |  65 ++++
 drivers/mtd/spi/micron-st.c     |  70 ++++
 drivers/mtd/spi/puya.c          |  56 +++
 drivers/mtd/spi/sf_internal.h   |  57 +++-
 drivers/mtd/spi/siliconkaiser.c |  18 +
 drivers/mtd/spi/spansion.c      |  73 ++++
 drivers/mtd/spi/spi-nor-core.c  |   8 -
 drivers/mtd/spi/spi-nor-ids.c   | 732 ++--------------------------------------
 drivers/mtd/spi/spi-nor-tiny.c  |   7 -
 drivers/mtd/spi/sst.c           |  34 ++
 drivers/mtd/spi/winbond.c       | 146 ++++++++
 drivers/mtd/spi/xmc.c           |  26 ++
 drivers/mtd/spi/xtx.c           |  54 +++
 drivers/mtd/spi/zbit.c          |  19 ++
 21 files changed, 991 insertions(+), 714 deletions(-)

diff --git a/drivers/mtd/spi/Makefile b/drivers/mtd/spi/Makefile
index 69b598a9c38..a73b2c9cfbb 100644
--- a/drivers/mtd/spi/Makefile
+++ b/drivers/mtd/spi/Makefile
@@ -19,6 +19,23 @@ spi-nor-y += spi-nor-core.o
 spi-nor-$(CONFIG_SPI_FLASH_SFDP_SUPPORT) += sfdp.o
 endif
 
+spi-nor-$(CONFIG_SPI_FLASH_ATMEL) += atmel.o
+spi-nor-$(CONFIG_SPI_FLASH_DOSILICON) += dosilicon.o
+spi-nor-$(CONFIG_SPI_FLASH_EON) += eon.o
+spi-nor-$(CONFIG_SPI_FRAM_FUJITSU) += fujitsu.o
+spi-nor-$(CONFIG_SPI_FLASH_GIGADEVICE) += gigadevice.o
+spi-nor-$(CONFIG_SPI_FLASH_ISSI) += issi.o
+spi-nor-$(CONFIG_SPI_FLASH_MACRONIX) += macronix.o
+spi-nor-$(CONFIG_SPI_FLASH_PUYA) += puya.o
+spi-nor-$(CONFIG_SPI_FLASH_SILICONKAISER) += siliconkaiser.o
+spi-nor-$(CONFIG_SPI_FLASH_STMICRO) += micron-st.o
+spi-nor-$(CONFIG_SPI_FLASH_SPANSION) += spansion.o
+spi-nor-$(CONFIG_SPI_FLASH_SST) += sst.o
+spi-nor-$(CONFIG_SPI_FLASH_WINBOND) += winbond.o
+spi-nor-$(CONFIG_SPI_FLASH_XMC) += xmc.o
+spi-nor-$(CONFIG_SPI_FLASH_XTX) += xtx.o
+spi-nor-$(CONFIG_SPI_FLASH_ZBIT) += zbit.o
+
 obj-$(CONFIG_SPI_FLASH) += spi-nor.o
 obj-$(CONFIG_SPI_FLASH_DATAFLASH) += sf_dataflash.o
 obj-$(CONFIG_$(PHASE_)SPI_FLASH_MTD) += sf_mtd.o
diff --git a/drivers/mtd/spi/atmel.c b/drivers/mtd/spi/atmel.c
new file mode 100644
index 00000000000..53c7afff323
--- /dev/null
+++ b/drivers/mtd/spi/atmel.c
@@ -0,0 +1,28 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Copyright (C) 2013 Jagannadha Sutradharudu Teki, Xilinx Inc.
+ * Copyright (C) 2016 Jagan Teki <jagan@openedev.com>
+ * Copyright (C) 2018 Texas Instruments Incorporated - https://www.ti.com/
+ */
+
+#include <linux/mtd/spi-nor.h>
+#include "sf_internal.h"
+
+static const struct flash_info atmel_nor_parts[] = {
+	{ INFO("at26df321",	0x1f4700, 0, 64 * 1024, 64, SECT_4K) },
+	{ INFO("at25df321a",	0x1f4701, 0, 64 * 1024, 64, SECT_4K) },
+	{ INFO("at45db011d",	0x1f2200, 0, 64 * 1024,   4, SECT_4K) },
+	{ INFO("at45db021d",	0x1f2300, 0, 64 * 1024,   8, SECT_4K) },
+	{ INFO("at45db041d",	0x1f2400, 0, 64 * 1024,   8, SECT_4K) },
+	{ INFO("at45db081d",	0x1f2500, 0, 64 * 1024,  16, SECT_4K) },
+	{ INFO("at45db161d",	0x1f2600, 0, 64 * 1024,  32, SECT_4K) },
+	{ INFO("at45db321d",	0x1f2700, 0, 64 * 1024,  64, SECT_4K) },
+	{ INFO("at45db641d",	0x1f2800, 0, 64 * 1024, 128, SECT_4K) },
+	{ INFO("at25sl321",	0x1f4216, 0, 64 * 1024,  64, SECT_4K) },
+	{ INFO("at26df081a",	0x1f4501, 0, 64 * 1024,  16, SECT_4K) },
+};
+
+const struct spi_nor_manufacturer spi_nor_atmel = {
+	.parts = atmel_nor_parts,
+	.nparts = ARRAY_SIZE(atmel_nor_parts),
+};
diff --git a/drivers/mtd/spi/dosilicon.c b/drivers/mtd/spi/dosilicon.c
new file mode 100644
index 00000000000..1c889960656
--- /dev/null
+++ b/drivers/mtd/spi/dosilicon.c
@@ -0,0 +1,25 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Copyright (C) 2013 Jagannadha Sutradharudu Teki, Xilinx Inc.
+ * Copyright (C) 2016 Jagan Teki <jagan@openedev.com>
+ * Copyright (C) 2018 Texas Instruments Incorporated - https://www.ti.com/
+ */
+
+#include <linux/mtd/spi-nor.h>
+#include "sf_internal.h"
+
+static const struct flash_info dosilicon_nor_parts[] = {
+	{ INFO("ds25m4cb", 0xe5401a, 0, 64 * 1024, 1024,
+		    SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("ds25m4dn", 0xe5401b, 0, 64 * 1024, 2048,
+		    SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("ds25q4cb", 0xe5301a, 0, 64 * 1024, 1024,
+		    SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("ds25q4dn", 0xe5301b, 0, 64 * 1024, 2048,
+		    SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+};
+
+const struct spi_nor_manufacturer spi_nor_dosilicon = {
+	.parts = dosilicon_nor_parts,
+	.nparts = ARRAY_SIZE(dosilicon_nor_parts),
+};
diff --git a/drivers/mtd/spi/eon.c b/drivers/mtd/spi/eon.c
new file mode 100644
index 00000000000..6690ba2a1da
--- /dev/null
+++ b/drivers/mtd/spi/eon.c
@@ -0,0 +1,23 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Copyright (C) 2013 Jagannadha Sutradharudu Teki, Xilinx Inc.
+ * Copyright (C) 2016 Jagan Teki <jagan@openedev.com>
+ * Copyright (C) 2018 Texas Instruments Incorporated - https://www.ti.com/
+ */
+
+#include <linux/mtd/spi-nor.h>
+#include "sf_internal.h"
+
+static const struct flash_info eon_nor_parts[] = {
+	{ INFO("en25q80b",   0x1c3014, 0, 64 * 1024,   16, SECT_4K) },
+	{ INFO("en25q32b",   0x1c3016, 0, 64 * 1024,   64, 0) },
+	{ INFO("en25q64",    0x1c3017, 0, 64 * 1024,  128, SECT_4K) },
+	{ INFO("en25q128b",  0x1c3018, 0, 64 * 1024,  256, 0) },
+	{ INFO("en25qh128",  0x1c7018, 0, 64 * 1024,  256, 0) },
+	{ INFO("en25s64",    0x1c3817, 0, 64 * 1024,  128, SECT_4K) },
+};
+
+const struct spi_nor_manufacturer spi_nor_eon = {
+	.parts = eon_nor_parts,
+	.nparts = ARRAY_SIZE(eon_nor_parts),
+};
diff --git a/drivers/mtd/spi/fujitsu.c b/drivers/mtd/spi/fujitsu.c
new file mode 100644
index 00000000000..3d5328b1815
--- /dev/null
+++ b/drivers/mtd/spi/fujitsu.c
@@ -0,0 +1,27 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Copyright (C) 2013 Jagannadha Sutradharudu Teki, Xilinx Inc.
+ * Copyright (C) 2016 Jagan Teki <jagan@openedev.com>
+ * Copyright (C) 2018 Texas Instruments Incorporated - https://www.ti.com/
+ */
+
+#include <linux/mtd/spi-nor.h>
+#include "sf_internal.h"
+
+static const struct flash_info fujitsu_nor_parts[] = {
+	{
+		INFO_NAME("mb85rs256ty")
+		.id = {0x04, 0x7f, 0x25, 0x00, 0x00},
+		.id_len = 3,
+		.sector_size = 32 * 1024,
+		.n_sectors = 1,
+		.page_size = 32 * 1024, /* Whole chip can be written at once */
+		.flags = SPI_NOR_NO_ERASE,
+		.addr_width = 2,
+	},
+};
+
+const struct spi_nor_manufacturer spi_nor_fujitsu = {
+	.parts = fujitsu_nor_parts,
+	.nparts = ARRAY_SIZE(fujitsu_nor_parts),
+};
diff --git a/drivers/mtd/spi/gigadevice.c b/drivers/mtd/spi/gigadevice.c
new file mode 100644
index 00000000000..8cc12589db2
--- /dev/null
+++ b/drivers/mtd/spi/gigadevice.c
@@ -0,0 +1,136 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Copyright (C) 2013 Jagannadha Sutradharudu Teki, Xilinx Inc.
+ * Copyright (C) 2016 Jagan Teki <jagan@openedev.com>
+ * Copyright (C) 2018 Texas Instruments Incorporated - https://www.ti.com/
+ */
+
+#include <linux/mtd/spi-nor.h>
+#include "sf_internal.h"
+
+static const struct flash_info gigadevice_nor_parts[] = {
+	{
+		INFO("gd25q16", 0xc84015, 0, 64 * 1024,  32,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+	{
+		INFO("gd25q32", 0xc84016, 0, 64 * 1024,  64,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+	{
+		INFO("gd25lq32", 0xc86016, 0, 64 * 1024, 64,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+	{
+		INFO("gd25q64", 0xc84017, 0, 64 * 1024, 128,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+	{
+		INFO("gd25lq64c", 0xc86017, 0, 64 * 1024, 128,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+	{
+		INFO("gd25q128", 0xc84018, 0, 64 * 1024, 256,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+	/* adding these 3V QSPI flash parts */
+	{INFO("gd25b256", 0xc84019, 0, 64 * 1024, 512,	SECT_4K |
+	SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)	},
+	{INFO("gd25b512", 0xc8471A, 0, 64 * 1024, 1024,	SECT_4K |
+	SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
+	{INFO("gd55b01g", 0xc8471B, 0, 64 * 1024, 2048,	SECT_4K |
+	SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
+	{INFO("gd55b02g", 0xc8471C, 0, 64 * 1024, 4096,	SECT_4K |
+	SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
+	{INFO("gd25f64", 0xc84317, 0, 64 * 1024, 128,	SECT_4K |
+	SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK)},
+	{INFO("gd25f128", 0xc84318, 0, 64 * 1024, 256,	SECT_4K	|
+	SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK)},
+	{INFO("gd25f256", 0xc84319, 0, 64 * 1024, 512,	SECT_4K |
+	SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
+	{INFO("gd55f512", 0xc8431A, 0, 64 * 1024, 1024,	SECT_4K |
+	SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
+	{INFO("gd25t512", 0xc8461A, 0, 64 * 1024, 1024,	SECT_4K |
+	SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
+	{INFO("gd55t01g", 0xc8461B, 0, 64 * 1024, 2048,	SECT_4K |
+	SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
+	{INFO("gd55t02g",	0xc8461C, 0, 64 * 1024, 4096,	SECT_4K |
+	SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
+	/* adding these 3V OSPI flash parts */
+	{INFO("gd25x512", 0xc8481A, 0, 64 * 1024, 1024,	SECT_4K |
+	SPI_NOR_OCTAL_READ | SPI_NOR_4B_OPCODES)},
+	{INFO("gd55x01g", 0xc8481B, 0, 64 * 1024, 2048,	SECT_4K |
+	SPI_NOR_OCTAL_READ | SPI_NOR_4B_OPCODES)},
+	{INFO("gd55x02g", 0xc8481C, 0, 64 * 1024, 4096,	SECT_4K |
+	SPI_NOR_OCTAL_READ | SPI_NOR_4B_OPCODES)},
+	{
+		INFO("gd25lq128", 0xc86018, 0, 64 * 1024, 256,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+	{
+		INFO("gd25lq256d", 0xc86019, 0, 64 * 1024, 512,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+	/* adding these 1.8V QSPI flash parts */
+	{INFO("gd25lb256", 0xc86719, 0, 64 * 1024, 512,	SECT_4K |
+	SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
+	{INFO("gd25lb512", 0xc8671A, 0, 64 * 1024, 1024,	SECT_4K |
+	SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
+	{INFO("gd55lb01g", 0xc8671B, 0, 64 * 1024, 2048,	SECT_4K |
+	SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
+	{INFO("gd55lb02g", 0xc8671C, 0, 64 * 1024, 4096,	SECT_4K |
+	SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
+	{INFO("gd25lf80", 0xc86314, 0, 64 * 1024, 16,	SECT_4K |
+	SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK)},
+	{INFO("gd25lf16", 0xc86315, 0, 64 * 1024, 32,	SECT_4K |
+	SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK)},
+	{INFO("gd25lf32", 0xc86316, 0, 64 * 1024, 64,	SECT_4K |
+	SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK)	},
+	{INFO("gd25lf64", 0xc86317, 0, 64 * 1024, 128,	SECT_4K |
+	SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK)	},
+	{INFO("gd25lf128", 0xc86318, 0, 64 * 1024, 256,	SECT_4K |
+	SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK)	},
+	{INFO("gd25lf255", 0xc86319, 0, 64 * 1024, 512,	SECT_4K |
+	SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
+	{INFO("gd25lf511", 0xc8631A, 0, 64 * 1024, 1024,	SECT_4K |
+	SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
+	{INFO("gd25lt256", 0xc86619, 0, 64 * 1024, 512,	SECT_4K |
+	SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
+	{INFO("gd25lt512", 0xc8661A, 0, 64 * 1024, 1024,	SECT_4K |
+	SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
+	{INFO("gd55lt01g", 0xc8661B, 0, 64 * 1024, 2048,	SECT_4K |
+	SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
+	{INFO("gd55lt02g", 0xc8661C, 0, 64 * 1024, 4096,	SECT_4K |
+	SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
+	{INFO("gd25lx128j", 0xc86818, 0, 64 * 1024, 256,	SECT_4K |
+	SPI_NOR_OCTAL_READ)},
+	{
+		INFO("gd25lx256e", 0xc86819, 0, 64 * 1024, 512,
+		     SECT_4K | SPI_NOR_OCTAL_READ | SPI_NOR_4B_OPCODES)
+	},
+	/* adding these 1.8V OSPI flash parts */
+	{INFO("gd25lx512", 0xc8681A, 0, 64 * 1024, 1024,	SECT_4K |
+	SPI_NOR_OCTAL_READ | SPI_NOR_4B_OPCODES)},
+	{INFO("gd55lx01g", 0xc8681B, 0, 64 * 1024, 2048,	SECT_4K |
+	SPI_NOR_OCTAL_READ | SPI_NOR_4B_OPCODES)},
+	{INFO("gd55lx02g", 0xc8681C, 0, 64 * 1024, 4096,	SECT_4K |
+	SPI_NOR_OCTAL_READ | SPI_NOR_4B_OPCODES)},
+	{
+		INFO("gd55lb02ge", 0xc8671c, 0, 64 * 1024, 4096,
+		     SECT_4K | SPI_NOR_QUAD_READ |
+		     SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+};
+
+const struct spi_nor_manufacturer spi_nor_gigadevice = {
+	.parts = gigadevice_nor_parts,
+	.nparts = ARRAY_SIZE(gigadevice_nor_parts),
+};
diff --git a/drivers/mtd/spi/issi.c b/drivers/mtd/spi/issi.c
new file mode 100644
index 00000000000..2537ca811f8
--- /dev/null
+++ b/drivers/mtd/spi/issi.c
@@ -0,0 +1,84 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Copyright (C) 2013 Jagannadha Sutradharudu Teki, Xilinx Inc.
+ * Copyright (C) 2016 Jagan Teki <jagan@openedev.com>
+ * Copyright (C) 2018 Texas Instruments Incorporated - https://www.ti.com/
+ */
+
+#include <linux/mtd/spi-nor.h>
+#include "sf_internal.h"
+
+static const struct flash_info issi_nor_parts[] = {
+	{ INFO("is25lq040b", 0x9d4013, 0, 64 * 1024,   8,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("is25lp008", 0x9d6014, 0, 64 * 1024,  16, SPI_NOR_QUAD_READ) },
+	{ INFO("is25lp016", 0x9d6015, 0, 64 * 1024,  32, SPI_NOR_QUAD_READ) },
+	{ INFO("is25lp032",	0x9d6016, 0, 64 * 1024,  64, 0) },
+	{ INFO("is25lp064",	0x9d6017, 0, 64 * 1024, 128, 0) },
+	{ INFO("is25lp128",  0x9d6018, 0, 64 * 1024, 256,
+			SECT_4K | SPI_NOR_DUAL_READ) },
+	{ INFO("is25lp256",  0x9d6019, 0, 64 * 1024, 512,
+			SECT_4K | SPI_NOR_DUAL_READ) },
+	{ INFO("is25lp512",  0x9d601a, 0, 64 * 1024, 1024,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("is25lp512mj", 0x9d6020, 0, 64 * 1024, 1024,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("is25lp01g",  0x9d601b, 0, 64 * 1024, 2048,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("is25wp008", 0x9d7014, 0, 64 * 1024,  16, SPI_NOR_QUAD_READ) },
+	{ INFO("is25wp016", 0x9d7015, 0, 64 * 1024,  32, SPI_NOR_QUAD_READ) },
+	{ INFO("is25wp032",  0x9d7016, 0, 64 * 1024,  64,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("is25wp064",  0x9d7017, 0, 64 * 1024, 128,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("is25wp128",  0x9d7018, 0, 64 * 1024, 256,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("is25wp256",  0x9d7019, 0, 64 * 1024, 512,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+			SPI_NOR_4B_OPCODES) },
+	{ INFO("is25wp512",  0x9d701a, 0, 64 * 1024, 1024,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("is25wp512mj", 0x9d7020, 0, 64 * 1024, 1024,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("is25wp01g",  0x9d701b, 0, 64 * 1024, 2048,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("is25wp01gg",  0x9d7021, 0, 64 * 1024, 2048,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("is25wx128",  0x9d5b18, 0, 64 * 1024, 256,
+			SECT_4K | USE_FSR | SPI_NOR_OCTAL_READ) },
+	{ INFO("is25wx256",  0x9d5b19, 0, 128 * 1024, 256,
+			SECT_4K | USE_FSR | SPI_NOR_OCTAL_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("is25lx128",  0x9d5a18, 0, 64 * 1024, 256,
+			SECT_4K | USE_FSR | SPI_NOR_OCTAL_READ) },
+	{ INFO("is25lx512",  0x9d5a1a, 0, 64 * 1024, 1024,
+			SECT_4K | USE_FSR | SPI_NOR_4B_OPCODES | SPI_NOR_HAS_TB) },
+	{ INFO("is25lp01gg",  0x9d6021, 0, 64 * 1024, 2048,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_TB) },
+	{ INFO("is25lp010e",  0x9d4011, 0, 64 * 1024, 2,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("is25lp020e",  0x9d4012, 0, 64 * 1024, 4,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("is25lp040e",  0x9d4013, 0, 64 * 1024, 8,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("is25lp01gj",  0x9d6021, 0, 64 * 1024, 2048,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_TB) },
+	{ INFO("is25lp02gg",  0x9d6022, 0, 64 * 1024, 4096,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_TB) },
+	{ INFO("is25lp02gj",  0x9d6022, 0, 64 * 1024, 4096,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_TB) },
+	{ INFO("is25wp01gg",  0x9d7021, 0, 64 * 1024, 2048,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_TB) },
+	{ INFO("is25wp01gj",  0x9d7021, 0, 64 * 1024, 2048,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_TB) },
+	{ INFO("is25wj128f",  0x9d7118, 0, 64 * 1024, 256,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_TB) },
+	{ INFO("is25wp02gg",  0x9d7022, 0, 64 * 1024, 4096,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_TB) },
+	{ INFO("is25wp02gj",  0x9d7022, 0, 64 * 1024, 4096,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_TB) },
+};
+
+const struct spi_nor_manufacturer spi_nor_issi = {
+	.parts = issi_nor_parts,
+	.nparts = ARRAY_SIZE(issi_nor_parts),
+};
diff --git a/drivers/mtd/spi/macronix.c b/drivers/mtd/spi/macronix.c
new file mode 100644
index 00000000000..87843978cad
--- /dev/null
+++ b/drivers/mtd/spi/macronix.c
@@ -0,0 +1,65 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Copyright (C) 2013 Jagannadha Sutradharudu Teki, Xilinx Inc.
+ * Copyright (C) 2016 Jagan Teki <jagan@openedev.com>
+ * Copyright (C) 2018 Texas Instruments Incorporated - https://www.ti.com/
+ */
+
+#include <linux/mtd/spi-nor.h>
+#include "sf_internal.h"
+
+static const struct flash_info macronix_nor_parts[] = {
+	{ INFO("mx25l2005a",  0xc22012, 0, 64 * 1024,   4, SECT_4K) },
+	{ INFO("mx25l4005a",  0xc22013, 0, 64 * 1024,   8, SECT_4K) },
+	{ INFO("mx25l8005",   0xc22014, 0, 64 * 1024,  16, 0) },
+	{ INFO("mx25l1606e",  0xc22015, 0, 64 * 1024,  32, SECT_4K) },
+	{ INFO("mx25l3205d",  0xc22016, 0, 64 * 1024,  64, SECT_4K) },
+	{ INFO("mx25l6405d",  0xc22017, 0, 64 * 1024, 128, SECT_4K) },
+	{ INFO("mx25u2033e",  0xc22532, 0, 64 * 1024,   4, SECT_4K) },
+	{ INFO("mx25u1635e",  0xc22535, 0, 64 * 1024,  32, SECT_4K) },
+	{ INFO("mx25u3235f",  0xc22536, 0, 4 * 1024,  1024, SECT_4K) },
+	{ INFO("mx25u6435f",  0xc22537, 0, 64 * 1024, 128, SECT_4K) },
+	{ INFO("mx25l12805d", 0xc22018, 0, 64 * 1024, 256, SECT_4K) },
+	{ INFO("mx25u12835f", 0xc22538, 0, 64 * 1024, 256, SECT_4K |
+	       SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("mx25u51245g", 0xc2253a, 0, 64 * 1024, 1024, SECT_4K |
+	       SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("mx25l12855e", 0xc22618, 0, 64 * 1024, 256, 0) },
+	{ INFO("mx25l25635e", 0xc22019, 0, 64 * 1024, 512, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("mx25u25635f", 0xc22539, 0, 64 * 1024, 512, SECT_4K | SPI_NOR_4B_OPCODES) },
+	{ INFO("mx25v8035f",  0xc22314, 0, 64 * 1024,  16, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("mx25r1635f",  0xc22815, 0, 64 * 1024,  32, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("mx25l25655e", 0xc22619, 0, 64 * 1024, 512, 0) },
+	{ INFO("mx66l51235l", 0xc2201a, 0, 64 * 1024, 1024, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("mx66u51235f", 0xc2253a, 0, 64 * 1024, 1024, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("mx25u51245f", 0xc2953a, 0, 64 * 1024, 1024, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("mx66u1g45g",  0xc2253b, 0, 64 * 1024, 2048, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("mx66u2g45g",  0xc2253c, 0, 64 * 1024, 4096, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("mx66l1g45g",  0xc2201b, 0, 64 * 1024, 2048, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("mx66l2g45g",  0xc2201c, 0, 64 * 1024, 4096, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("mx25l1633e", 0xc22415, 0, 64 * 1024,   32, SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES | SECT_4K) },
+	{ INFO("mx25r6435f", 0xc22817, 0, 64 * 1024,   128,  SECT_4K) },
+	{ INFO("mx66uw2g345gx0", 0xc2943c, 0, 64 * 1024, 4096, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES | SPI_NOR_OCTAL_READ) },
+	{ INFO("mx66lm1g45g",    0xc2853b, 0, 64 * 1024, 2048, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("mx25lm51245g",   0xc2853a, 0, 64 * 1024, 1024, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("mx25lw51245g",   0xc2863a, 0, 64 * 1024, 1024, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("mx25lm25645g",   0xc28539, 0, 64 * 1024, 512, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("mx66uw2g345g",   0xc2843c, 0, 64 * 1024, 4096, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("mx66um1g45g",    0xc2803b, 0, 64 * 1024, 2048, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("mx66uw1g45g",    0xc2813b, 0, 64 * 1024, 2048, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("mx25uw51245g",   0xc2813a, 0, 64 * 1024, 1024, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("mx25uw51345g",   0xc2843a, 0, 64 * 1024, 1024, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("mx25um25645g",   0xc28039, 0, 64 * 1024, 512, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("mx25uw25645g",   0xc28139, 0, 64 * 1024, 512, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("mx25um25345g",   0xc28339, 0, 64 * 1024, 512, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("mx25uw25345g",   0xc28439, 0, 64 * 1024, 512, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("mx25uw12845g",   0xc28138, 0, 64 * 1024, 256, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("mx25uw12345g",   0xc28438, 0, 64 * 1024, 256, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("mx25uw6445g",    0xc28137, 0, 64 * 1024, 128, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("mx25uw6345g",    0xc28437, 0, 64 * 1024, 128, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
+};
+
+const struct spi_nor_manufacturer spi_nor_macronix = {
+	.parts = macronix_nor_parts,
+	.nparts = ARRAY_SIZE(macronix_nor_parts),
+};
diff --git a/drivers/mtd/spi/micron-st.c b/drivers/mtd/spi/micron-st.c
new file mode 100644
index 00000000000..2d47f1c60c0
--- /dev/null
+++ b/drivers/mtd/spi/micron-st.c
@@ -0,0 +1,70 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Copyright (C) 2013 Jagannadha Sutradharudu Teki, Xilinx Inc.
+ * Copyright (C) 2016 Jagan Teki <jagan@openedev.com>
+ * Copyright (C) 2018 Texas Instruments Incorporated - https://www.ti.com/
+ */
+
+#include <linux/mtd/spi-nor.h>
+#include "sf_internal.h"
+
+static const struct flash_info micron_nor_parts[] = {
+	{ INFO("n25q016a",	 0x20bb15, 0, 64 * 1024,   32, SECT_4K | SPI_NOR_QUAD_READ) },
+	{ INFO("n25q032",	 0x20ba16, 0, 64 * 1024,   64, SPI_NOR_QUAD_READ) },
+	{ INFO("n25q032a",	0x20bb16, 0, 64 * 1024,   64, SPI_NOR_QUAD_READ) },
+	{ INFO("n25q064",     0x20ba17, 0, 64 * 1024,  128, SECT_4K | SPI_NOR_QUAD_READ) },
+	{ INFO("n25q064a",    0x20bb17, 0, 64 * 1024,  128, SECT_4K | SPI_NOR_QUAD_READ) },
+	{ INFO("n25q128a11",  0x20bb18, 0, 64 * 1024,  256, SECT_4K | SPI_NOR_QUAD_READ) },
+	{ INFO("n25q128a13",  0x20ba18, 0, 64 * 1024,  256, SECT_4K | SPI_NOR_QUAD_READ) },
+	{ INFO6("mt25ql256a",    0x20ba19, 0x104400, 64 * 1024,  512, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES | USE_FSR) },
+	{ INFO("n25q256a",    0x20ba19, 0, 64 * 1024,  512, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | USE_FSR) },
+	{ INFO6("mt25qu256a",  0x20bb19, 0x104400, 64 * 1024,  512, SECT_4K | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES | USE_FSR) },
+	{ INFO("n25q256ax1",  0x20bb19, 0, 64 * 1024,  512, SECT_4K | SPI_NOR_QUAD_READ | USE_FSR) },
+	{ INFO("mt25qu128ab", 0x20bb18, 0, 64 * 1024,  256, SECT_4K | USE_FSR | SPI_NOR_QUAD_READ) },
+	{ INFO6("mt25qu512a",  0x20bb20, 0x104400, 64 * 1024, 1024,
+		 SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES |
+		 USE_FSR) },
+	{ INFO("n25q512a",    0x20bb20, 0, 64 * 1024, 1024, SECT_4K | USE_FSR | SPI_NOR_QUAD_READ) },
+	{ INFO6("mt25ql512a",  0x20ba20, 0x104400, 64 * 1024, 1024, SECT_4K | USE_FSR | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("n25q512ax3",  0x20ba20, 0, 64 * 1024, 1024, SECT_4K | USE_FSR | SPI_NOR_QUAD_READ) },
+	{ INFO("n25q00",      0x20ba21, 0, 64 * 1024, 2048, SECT_4K | USE_FSR | SPI_NOR_QUAD_READ | NO_CHIP_ERASE) },
+	{ INFO("n25q00a",     0x20bb21, 0, 64 * 1024, 2048, SECT_4K | USE_FSR | SPI_NOR_QUAD_READ | NO_CHIP_ERASE) },
+	{ INFO("mt25ql01g",   0x21ba20, 0, 64 * 1024, 2048, SECT_4K | USE_FSR | SPI_NOR_QUAD_READ | NO_CHIP_ERASE) },
+	{ INFO6("mt25qu01g",  0x20bb21, 0x104400, 64 * 1024, 2048, SECT_4K | USE_FSR | SPI_NOR_QUAD_READ | NO_CHIP_ERASE | SPI_NOR_4B_OPCODES) },
+	{ INFO("mt25qu02g",   0x20bb22, 0, 64 * 1024, 4096, SECT_4K | USE_FSR | SPI_NOR_QUAD_READ | NO_CHIP_ERASE) },
+	{ INFO("mt25ql02g",   0x20ba22, 0, 64 * 1024, 4096, SECT_4K | USE_FSR | SPI_NOR_QUAD_READ | NO_CHIP_ERASE | SPI_NOR_4B_OPCODES) },
+#ifdef CONFIG_SPI_FLASH_MT35XU
+	{ INFO("mt35xl512aba", 0x2c5a1a, 0,  128 * 1024,  512, USE_FSR | SPI_NOR_OCTAL_READ | SPI_NOR_4B_OPCODES | SPI_NOR_OCTAL_DTR_READ) },
+	{ INFO("mt35xu512aba", 0x2c5b1a, 0,  128 * 1024,  512, USE_FSR | SPI_NOR_OCTAL_READ | SPI_NOR_4B_OPCODES | SPI_NOR_OCTAL_DTR_READ) },
+	{ INFO("mt35xu01gaba", 0x2c5b1b, 0,  128 * 1024,  1024,
+		USE_FSR | SPI_NOR_OCTAL_READ | SPI_NOR_4B_OPCODES | NO_CHIP_ERASE) },
+#endif /* CONFIG_SPI_FLASH_MT35XU */
+	{ INFO6("mt35xu01g",  0x2c5b1b, 0x104100, 128 * 1024,  1024,
+		USE_FSR | SPI_NOR_OCTAL_READ | SPI_NOR_4B_OPCODES | NO_CHIP_ERASE) },
+	{ INFO("mt35xu02g",  0x2c5b1c, 0, 128 * 1024,  2048,
+		USE_FSR | SPI_NOR_OCTAL_READ | SPI_NOR_4B_OPCODES | NO_CHIP_ERASE) },
+};
+
+static const struct flash_info st_nor_parts[] = {
+	{ INFO("m25p10",  0x202011,  0,  32 * 1024,   4, 0) },
+	{ INFO("m25p20",  0x202012,  0,  64 * 1024,   4, 0) },
+	{ INFO("m25p40",  0x202013,  0,  64 * 1024,   8, 0) },
+	{ INFO("m25p80",  0x202014,  0,  64 * 1024,  16, 0) },
+	{ INFO("m25p16",  0x202015,  0,  64 * 1024,  32, 0) },
+	{ INFO("m25p32",  0x202016,  0,  64 * 1024,  64, 0) },
+	{ INFO("m25p64",  0x202017,  0,  64 * 1024, 128, 0) },
+	{ INFO("m25p128", 0x202018,  0, 256 * 1024,  64, 0) },
+	{ INFO("m25pe16", 0x208015,  0, 64 * 1024, 32, SECT_4K) },
+	{ INFO("m25px16",    0x207115,  0, 64 * 1024, 32, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("m25px64",    0x207117,  0, 64 * 1024, 128, 0) },
+};
+
+const struct spi_nor_manufacturer spi_nor_micron = {
+	.parts = micron_nor_parts,
+	.nparts = ARRAY_SIZE(micron_nor_parts),
+};
+
+const struct spi_nor_manufacturer spi_nor_st = {
+	.parts = st_nor_parts,
+	.nparts = ARRAY_SIZE(st_nor_parts),
+};
diff --git a/drivers/mtd/spi/puya.c b/drivers/mtd/spi/puya.c
new file mode 100644
index 00000000000..37092945dfc
--- /dev/null
+++ b/drivers/mtd/spi/puya.c
@@ -0,0 +1,56 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Copyright (C) 2013 Jagannadha Sutradharudu Teki, Xilinx Inc.
+ * Copyright (C) 2016 Jagan Teki <jagan@openedev.com>
+ * Copyright (C) 2018 Texas Instruments Incorporated - https://www.ti.com/
+ */
+
+#include <linux/mtd/spi-nor.h>
+#include "sf_internal.h"
+
+static const struct flash_info puya_nor_parts[] = {
+	{ INFO
+	 ("p25q05h", 0x856010, 0, 64 * 1024, 1,
+	  SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO
+	 ("p25q10h", 0x856011, 0, 64 * 1024, 2,
+	  SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO
+	 ("p25q20h", 0x856012, 0, 64 * 1024, 4,
+	  SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO
+	 ("p25q40h", 0x856013, 0, 64 * 1024, 8,
+	  SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO
+	 ("p25q80h", 0x856014, 0, 64 * 1024, 16,
+	  SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO
+	 ("p25q16h", 0x856015, 0, 64 * 1024, 32,
+	  SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO
+	 ("p25q32h", 0x856016, 0, 64 * 1024, 64,
+	  SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO
+	 ("p25q64h", 0x856017, 0, 64 * 1024, 128,
+	  SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO
+	 ("p25q128h", 0x856018, 0, 64 * 1024, 256,
+	  SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO
+	 ("py25f512hb", 0x85231a, 0, 64 * 1024, 1024,
+	  SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO
+	 ("py25f01ghb", 0x85231b, 0, 64 * 1024, 2048,
+	  SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO
+	 ("py25f512lc", 0x85631a, 0, 64 * 1024, 1024,
+	  SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO
+	 ("py25f01glc", 0x85631b, 0, 64 * 1024, 2048,
+	  SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+};
+
+const struct spi_nor_manufacturer spi_nor_puya = {
+	.parts = puya_nor_parts,
+	.nparts = ARRAY_SIZE(puya_nor_parts),
+};
diff --git a/drivers/mtd/spi/sf_internal.h b/drivers/mtd/spi/sf_internal.h
index 3b6b51cb11c..941729f5707 100644
--- a/drivers/mtd/spi/sf_internal.h
+++ b/drivers/mtd/spi/sf_internal.h
@@ -97,6 +97,45 @@ struct flash_info {
 #define SPI_NOR_OCTAL_DTR_READ	BIT(17)	/* Flash supports Octal DTR Read */
 };
 
+/* Exclude chip names for SPL to save space */
+#if !CONFIG_IS_ENABLED(SPI_FLASH_TINY)
+#define INFO_NAME(_name) .name = _name,
+#else
+#define INFO_NAME(_name)
+#endif
+
+/* Used when the "_ext_id" is two bytes at most */
+#define INFO(_name, _jedec_id, _ext_id, _sector_size, _n_sectors, _flags)	\
+		INFO_NAME(_name)					\
+		.id = {							\
+			((_jedec_id) >> 16) & 0xff,			\
+			((_jedec_id) >> 8) & 0xff,			\
+			(_jedec_id) & 0xff,				\
+			((_ext_id) >> 8) & 0xff,			\
+			(_ext_id) & 0xff,				\
+			},						\
+		.id_len = (!(_jedec_id) ? 0 : (3 + ((_ext_id) ? 2 : 0))),	\
+		.sector_size = (_sector_size),				\
+		.n_sectors = (_n_sectors),				\
+		.page_size = 256,					\
+		.flags = (_flags),
+
+#define INFO6(_name, _jedec_id, _ext_id, _sector_size, _n_sectors, _flags)	\
+		INFO_NAME(_name)					\
+		.id = {							\
+			((_jedec_id) >> 16) & 0xff,			\
+			((_jedec_id) >> 8) & 0xff,			\
+			(_jedec_id) & 0xff,				\
+			((_ext_id) >> 16) & 0xff,			\
+			((_ext_id) >> 8) & 0xff,			\
+			(_ext_id) & 0xff,				\
+			},						\
+		.id_len = 6,						\
+		.sector_size = (_sector_size),				\
+		.n_sectors = (_n_sectors),				\
+		.page_size = 256,					\
+		.flags = (_flags),
+
 /**
  * struct spi_nor_manufacturer - SPI NOR manufacturer object
  * @parts: array of parts supported by this manufacturer
@@ -113,7 +152,23 @@ struct spi_nor_manufacturer {
 #endif
 };
 
-extern const struct flash_info spi_nor_ids[];
+extern const struct spi_nor_manufacturer spi_nor_atmel;
+extern const struct spi_nor_manufacturer spi_nor_dosilicon;
+extern const struct spi_nor_manufacturer spi_nor_eon;
+extern const struct spi_nor_manufacturer spi_nor_fujitsu;
+extern const struct spi_nor_manufacturer spi_nor_gigadevice;
+extern const struct spi_nor_manufacturer spi_nor_issi;
+extern const struct spi_nor_manufacturer spi_nor_macronix;
+extern const struct spi_nor_manufacturer spi_nor_puya;
+extern const struct spi_nor_manufacturer spi_nor_siliconkaiser;
+extern const struct spi_nor_manufacturer spi_nor_micron;
+extern const struct spi_nor_manufacturer spi_nor_st;
+extern const struct spi_nor_manufacturer spi_nor_spansion;
+extern const struct spi_nor_manufacturer spi_nor_sst;
+extern const struct spi_nor_manufacturer spi_nor_winbond;
+extern const struct spi_nor_manufacturer spi_nor_xmc;
+extern const struct spi_nor_manufacturer spi_nor_xtx;
+extern const struct spi_nor_manufacturer spi_nor_zbit;
 
 #define JEDEC_MFR(info)	((info)->id[0])
 #define JEDEC_ID(info)		(((info)->id[1]) << 8 | ((info)->id[2]))
diff --git a/drivers/mtd/spi/siliconkaiser.c b/drivers/mtd/spi/siliconkaiser.c
new file mode 100644
index 00000000000..23e03ff8088
--- /dev/null
+++ b/drivers/mtd/spi/siliconkaiser.c
@@ -0,0 +1,18 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Copyright (C) 2013 Jagannadha Sutradharudu Teki, Xilinx Inc.
+ * Copyright (C) 2016 Jagan Teki <jagan@openedev.com>
+ * Copyright (C) 2018 Texas Instruments Incorporated - https://www.ti.com/
+ */
+
+#include <linux/mtd/spi-nor.h>
+#include "sf_internal.h"
+
+static const struct flash_info siliconkaiser_nor_parts[] = {
+	{ INFO("sk25lp128", 0x257018, 0, 64 * 1024, 256, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+};
+
+const struct spi_nor_manufacturer spi_nor_siliconkaiser = {
+	.parts = siliconkaiser_nor_parts,
+	.nparts = ARRAY_SIZE(siliconkaiser_nor_parts),
+};
diff --git a/drivers/mtd/spi/spansion.c b/drivers/mtd/spi/spansion.c
new file mode 100644
index 00000000000..405f5bf5e79
--- /dev/null
+++ b/drivers/mtd/spi/spansion.c
@@ -0,0 +1,73 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Copyright (C) 2013 Jagannadha Sutradharudu Teki, Xilinx Inc.
+ * Copyright (C) 2016 Jagan Teki <jagan@openedev.com>
+ * Copyright (C) 2018 Texas Instruments Incorporated - https://www.ti.com/
+ */
+
+#include <linux/mtd/spi-nor.h>
+#include "sf_internal.h"
+
+static const struct flash_info spansion_nor_parts[] = {
+	{ INFO("s25sl032p",  0x010215, 0x4d00,  64 * 1024,  64, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("s25sl064p",  0x010216, 0x4d00,  64 * 1024, 128, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO6("s25fl256s0", 0x010219, 0x4d0080, 256 * 1024, 128, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | USE_CLSR) },
+	{ INFO6("s25fl256s1", 0x010219, 0x4d0180,  64 * 1024, 512, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | USE_CLSR) },
+	{ INFO6("s25fl512s",  0x010220, 0x4d0080, 256 * 1024, 256, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | USE_CLSR) },
+	{ INFO6("s25fs064s",  0x010217, 0x4d0181,  64 * 1024, 128, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | USE_CLSR) },
+	{ INFO6("s25fs128s",  0x012018, 0x4d0181,  64 * 1024, 256, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | USE_CLSR) },
+	{ INFO6("s25fs256s",  0x010219, 0x4d0181,  64 * 1024, 512, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | USE_CLSR) },
+	{ INFO6("s25fs512s",  0x010220, 0x4d0081, 256 * 1024, 256, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | USE_CLSR) },
+	{ INFO("s25fl512s_256k",  0x010220, 0x4d00, 256 * 1024, 256, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | USE_CLSR) },
+	{ INFO("s25fl512s_64k",  0x010220, 0x4d01, 64 * 1024, 1024, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | USE_CLSR) },
+	{ INFO("s25fl512s_512k", 0x010220, 0x4f00, 256 * 1024, 256, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | USE_CLSR) },
+	{ INFO("s70fs01gs_256k", 0x010221, 0x4d00, 256 * 1024, 512, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("s25sl12800", 0x012018, 0x0300, 256 * 1024,  64, 0) },
+	{ INFO("s25sl12801", 0x012018, 0x0301,  64 * 1024, 256, 0) },
+	{ INFO6("s25fl128s",  0x012018, 0x4d0180, 64 * 1024, 256, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | USE_CLSR) },
+	{ INFO("s25fl129p0", 0x012018, 0x4d00, 256 * 1024,  64, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | USE_CLSR) },
+	{ INFO("s25fl129p1", 0x012018, 0x4d01,  64 * 1024, 256, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | USE_CLSR) },
+	{ INFO("s25sl008a",  0x010213,      0,  64 * 1024,  16, 0) },
+	{ INFO("s25sl016a",  0x010214,      0,  64 * 1024,  32, 0) },
+	{ INFO("s25sl032a",  0x010215,      0,  64 * 1024,  64, 0) },
+	{ INFO("s25sl064a",  0x010216,      0,  64 * 1024, 128, 0) },
+	{ INFO("s25fl116k",  0x014015,      0,  64 * 1024,  32, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("s25fl164k",  0x014017,      0,  64 * 1024, 128, SECT_4K) },
+	{ INFO("s25fl208k",  0x014014,      0,  64 * 1024,  16, SECT_4K | SPI_NOR_DUAL_READ) },
+	{ INFO("s25fl064l",  0x016017,      0,  64 * 1024, 128, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("s25fl128l",  0x016018,      0,  64 * 1024, 256, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("s25fl256l",  0x016019,      0,  64 * 1024, 512, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO6("s25hl512t",  0x342a1a, 0x0f0390, 256 * 1024, 256,
+		SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES |
+		USE_CLSR) },
+	{ INFO6("s25hl01gt",  0x342a1b, 0x0f0390, 256 * 1024, 512,
+		SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES |
+		USE_CLSR) },
+	{ INFO6("s25hl02gt",  0x342a1c, 0x0f0090, 256 * 1024, 1024,
+		SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES | NO_CHIP_ERASE) },
+	{ INFO6("s25hs512t",  0x342b1a, 0x0f0390, 256 * 1024, 256,
+		SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES |
+		USE_CLSR) },
+	{ INFO6("s25hs01gt",  0x342b1b, 0x0f0390, 256 * 1024, 512,
+		SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES |
+		USE_CLSR) },
+	{ INFO6("s25hs02gt",  0x342b1c, 0x0f0090, 256 * 1024, 1024,
+		SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES | NO_CHIP_ERASE) },
+	{ INFO6("s25fs256t",  0x342b19, 0x0f0890, 128 * 1024, 256,
+		SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+#ifdef CONFIG_SPI_FLASH_S28HX_T
+	{ INFO("s28hl256t",  0x345a19,      0, 256 * 1024, 128, SPI_NOR_OCTAL_DTR_READ) },
+	{ INFO("s28hl512t",  0x345a1a,      0, 256 * 1024, 256, SPI_NOR_OCTAL_DTR_READ) },
+	{ INFO("s28hl01gt",  0x345a1b,      0, 256 * 1024, 512, SPI_NOR_OCTAL_DTR_READ) },
+	{ INFO("s28hl02gt",  0x345a1c,      0, 256 * 1024, 1024, SPI_NOR_OCTAL_DTR_READ | NO_CHIP_ERASE) },
+	{ INFO("s28hs256t",  0x345b19,      0, 256 * 1024, 128, SPI_NOR_OCTAL_DTR_READ) },
+	{ INFO("s28hs512t",  0x345b1a,      0, 256 * 1024, 256, SPI_NOR_OCTAL_DTR_READ) },
+	{ INFO("s28hs01gt",  0x345b1b,      0, 256 * 1024, 512, SPI_NOR_OCTAL_DTR_READ) },
+	{ INFO("s28hs02gt",  0x345b1c,      0, 256 * 1024, 1024, SPI_NOR_OCTAL_DTR_READ | NO_CHIP_ERASE) },
+#endif
+};
+
+const struct spi_nor_manufacturer spi_nor_spansion = {
+	.parts = spansion_nor_parts,
+	.nparts = ARRAY_SIZE(spansion_nor_parts),
+};
diff --git a/drivers/mtd/spi/spi-nor-core.c b/drivers/mtd/spi/spi-nor-core.c
index 697e443bf5a..d107828092c 100644
--- a/drivers/mtd/spi/spi-nor-core.c
+++ b/drivers/mtd/spi/spi-nor-core.c
@@ -1409,14 +1409,6 @@ static const struct flash_info *spi_nor_read_id(struct spi_nor *nor)
 	if (info)
 		return info;
 
-	info = spi_nor_ids;
-	for (; info->name; info++) {
-		if (info->id_len) {
-			if (!memcmp(info->id, id, info->id_len))
-				return info;
-		}
-	}
-
 	dev_err(nor->dev, "unrecognized JEDEC id bytes: %02x, %02x, %02x\n",
 		id[0], id[1], id[2]);
 	return ERR_PTR(-ENODEV);
diff --git a/drivers/mtd/spi/spi-nor-ids.c b/drivers/mtd/spi/spi-nor-ids.c
index 45e9b866795..ad3012d33d8 100644
--- a/drivers/mtd/spi/spi-nor-ids.c
+++ b/drivers/mtd/spi/spi-nor-ids.c
@@ -11,720 +11,56 @@
 
 #include "sf_internal.h"
 
-/* Exclude chip names for SPL to save space */
-#if !CONFIG_IS_ENABLED(SPI_FLASH_TINY)
-#define INFO_NAME(_name) .name = _name,
-#else
-#define INFO_NAME(_name)
-#endif
-
-/* Used when the "_ext_id" is two bytes at most */
-#define INFO(_name, _jedec_id, _ext_id, _sector_size, _n_sectors, _flags)	\
-		INFO_NAME(_name)					\
-		.id = {							\
-			((_jedec_id) >> 16) & 0xff,			\
-			((_jedec_id) >> 8) & 0xff,			\
-			(_jedec_id) & 0xff,				\
-			((_ext_id) >> 8) & 0xff,			\
-			(_ext_id) & 0xff,				\
-			},						\
-		.id_len = (!(_jedec_id) ? 0 : (3 + ((_ext_id) ? 2 : 0))),	\
-		.sector_size = (_sector_size),				\
-		.n_sectors = (_n_sectors),				\
-		.page_size = 256,					\
-		.flags = (_flags),
-
-#define INFO6(_name, _jedec_id, _ext_id, _sector_size, _n_sectors, _flags)	\
-		INFO_NAME(_name)					\
-		.id = {							\
-			((_jedec_id) >> 16) & 0xff,			\
-			((_jedec_id) >> 8) & 0xff,			\
-			(_jedec_id) & 0xff,				\
-			((_ext_id) >> 16) & 0xff,			\
-			((_ext_id) >> 8) & 0xff,			\
-			(_ext_id) & 0xff,				\
-			},						\
-		.id_len = 6,						\
-		.sector_size = (_sector_size),				\
-		.n_sectors = (_n_sectors),				\
-		.page_size = 256,					\
-		.flags = (_flags),
-
-/* NOTE: double check command sets and memory organization when you add
- * more nor chips.  This current list focusses on newer chips, which
- * have been converging on command sets which including JEDEC ID.
- *
- * All newly added entries should describe *hardware* and should use SECT_4K
- * (or SECT_4K_PMC) if hardware supports erasing 4 KiB sectors. For usage
- * scenarios excluding small sectors there is config option that can be
- * disabled: CONFIG_SPI_FLASH_USE_4K_SECTORS.
- * For historical (and compatibility) reasons (before we got above config) some
- * old entries may be missing 4K flag.
- */
-const struct flash_info spi_nor_ids[] = {
-#ifdef CONFIG_SPI_FLASH_ATMEL		/* ATMEL */
-	/* Atmel -- some are (confusingly) marketed as "DataFlash" */
-	{ INFO("at26df321",	0x1f4700, 0, 64 * 1024, 64, SECT_4K) },
-	{ INFO("at25df321a",	0x1f4701, 0, 64 * 1024, 64, SECT_4K) },
-
-	{ INFO("at45db011d",	0x1f2200, 0, 64 * 1024,   4, SECT_4K) },
-	{ INFO("at45db021d",	0x1f2300, 0, 64 * 1024,   8, SECT_4K) },
-	{ INFO("at45db041d",	0x1f2400, 0, 64 * 1024,   8, SECT_4K) },
-	{ INFO("at45db081d",	0x1f2500, 0, 64 * 1024,  16, SECT_4K) },
-	{ INFO("at45db161d",	0x1f2600, 0, 64 * 1024,  32, SECT_4K) },
-	{ INFO("at45db321d",	0x1f2700, 0, 64 * 1024,  64, SECT_4K) },
-	{ INFO("at45db641d",	0x1f2800, 0, 64 * 1024, 128, SECT_4K) },
-	{ INFO("at25sl321",	0x1f4216, 0, 64 * 1024,  64, SECT_4K) },
-	{ INFO("at26df081a",	0x1f4501, 0, 64 * 1024,  16, SECT_4K) },
-#endif
-#ifdef CONFIG_SPI_FLASH_DOSILICON
-	/* Dosilicon Co., Ltd */
-	{ INFO("ds25m4cb", 0xe5401a, 0, 64 * 1024, 1024,
-		    SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("ds25m4dn", 0xe5401b, 0, 64 * 1024, 2048,
-		    SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("ds25q4cb", 0xe5301a, 0, 64 * 1024, 1024,
-		    SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("ds25q4dn", 0xe5301b, 0, 64 * 1024, 2048,
-		    SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-#endif
-#ifdef CONFIG_SPI_FLASH_EON		/* EON */
-	/* EON -- en25xxx */
-	{ INFO("en25q80b",   0x1c3014, 0, 64 * 1024,   16, SECT_4K) },
-	{ INFO("en25q32b",   0x1c3016, 0, 64 * 1024,   64, 0) },
-	{ INFO("en25q64",    0x1c3017, 0, 64 * 1024,  128, SECT_4K) },
-	{ INFO("en25q128b",  0x1c3018, 0, 64 * 1024,  256, 0) },
-	{ INFO("en25qh128",  0x1c7018, 0, 64 * 1024,  256, 0) },
-	{ INFO("en25s64",    0x1c3817, 0, 64 * 1024,  128, SECT_4K) },
+static const struct spi_nor_manufacturer *manufacturers[] = {
+#if (IS_ENABLED(CONFIG_SPI_FLASH_ATMEL))
+	&spi_nor_atmel,
 #endif
-#ifdef CONFIG_SPI_FRAM_FUJITSU
-	/* Fujitsu MB85RS256TY */
-	{
-		INFO_NAME("mb85rs256ty")
-		.id = {0x04, 0x7f, 0x25, 0x00, 0x00},
-		.id_len = 3,
-		.sector_size = 32 * 1024,
-		.n_sectors = 1,
-		.page_size = 32 * 1024, /* Whole chip can be written at once */
-		.flags = SPI_NOR_NO_ERASE,
-		.addr_width = 2,
-	},
+#if (IS_ENABLED(CONFIG_SPI_FLASH_DOSILICON))
+	&spi_nor_dosilicon,
 #endif
-#ifdef CONFIG_SPI_FLASH_GIGADEVICE	/* GIGADEVICE */
-	/* GigaDevice */
-	{
-		INFO("gd25q16", 0xc84015, 0, 64 * 1024,  32,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
-	{
-		INFO("gd25q32", 0xc84016, 0, 64 * 1024,  64,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
-	{
-		INFO("gd25lq32", 0xc86016, 0, 64 * 1024, 64,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
-	{
-		INFO("gd25q64", 0xc84017, 0, 64 * 1024, 128,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
-	{
-		INFO("gd25lq64c", 0xc86017, 0, 64 * 1024, 128,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
-	{
-		INFO("gd25q128", 0xc84018, 0, 64 * 1024, 256,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
-	/* adding these 3V QSPI flash parts */
-	{INFO("gd25b256", 0xc84019, 0, 64 * 1024, 512,	SECT_4K |
-	SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)	},
-	{INFO("gd25b512", 0xc8471A, 0, 64 * 1024, 1024,	SECT_4K |
-	SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
-	{INFO("gd55b01g", 0xc8471B, 0, 64 * 1024, 2048,	SECT_4K |
-	SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
-	{INFO("gd55b02g", 0xc8471C, 0, 64 * 1024, 4096,	SECT_4K |
-	SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
-	{INFO("gd25f64", 0xc84317, 0, 64 * 1024, 128,	SECT_4K |
-	SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK)},
-	{INFO("gd25f128", 0xc84318, 0, 64 * 1024, 256,	SECT_4K	|
-	SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK)},
-	{INFO("gd25f256", 0xc84319, 0, 64 * 1024, 512,	SECT_4K |
-	SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
-	{INFO("gd55f512", 0xc8431A, 0, 64 * 1024, 1024,	SECT_4K |
-	SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
-	{INFO("gd25t512", 0xc8461A, 0, 64 * 1024, 1024,	SECT_4K |
-	SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
-	{INFO("gd55t01g", 0xc8461B, 0, 64 * 1024, 2048,	SECT_4K |
-	SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
-	{INFO("gd55t02g",	0xc8461C, 0, 64 * 1024, 4096,	SECT_4K |
-	SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
-	/* adding these 3V OSPI flash parts */
-	{INFO("gd25x512", 0xc8481A, 0, 64 * 1024, 1024,	SECT_4K |
-	SPI_NOR_OCTAL_READ | SPI_NOR_4B_OPCODES)},
-	{INFO("gd55x01g", 0xc8481B, 0, 64 * 1024, 2048,	SECT_4K |
-	SPI_NOR_OCTAL_READ | SPI_NOR_4B_OPCODES)},
-	{INFO("gd55x02g", 0xc8481C, 0, 64 * 1024, 4096,	SECT_4K |
-	SPI_NOR_OCTAL_READ | SPI_NOR_4B_OPCODES)},
-	{
-		INFO("gd25lq128", 0xc86018, 0, 64 * 1024, 256,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
-	{
-		INFO("gd25lq256d", 0xc86019, 0, 64 * 1024, 512,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
-	/* adding these 1.8V QSPI flash parts */
-	{INFO("gd25lb256", 0xc86719, 0, 64 * 1024, 512,	SECT_4K |
-	SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
-	{INFO("gd25lb512", 0xc8671A, 0, 64 * 1024, 1024,	SECT_4K |
-	SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
-	{INFO("gd55lb01g", 0xc8671B, 0, 64 * 1024, 2048,	SECT_4K |
-	SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
-	{INFO("gd55lb02g", 0xc8671C, 0, 64 * 1024, 4096,	SECT_4K |
-	SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
-	{INFO("gd25lf80", 0xc86314, 0, 64 * 1024, 16,	SECT_4K |
-	SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK)},
-	{INFO("gd25lf16", 0xc86315, 0, 64 * 1024, 32,	SECT_4K |
-	SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK)},
-	{INFO("gd25lf32", 0xc86316, 0, 64 * 1024, 64,	SECT_4K |
-	SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK)	},
-	{INFO("gd25lf64", 0xc86317, 0, 64 * 1024, 128,	SECT_4K |
-	SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK)	},
-	{INFO("gd25lf128", 0xc86318, 0, 64 * 1024, 256,	SECT_4K |
-	SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK)	},
-	{INFO("gd25lf255", 0xc86319, 0, 64 * 1024, 512,	SECT_4K |
-	SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
-	{INFO("gd25lf511", 0xc8631A, 0, 64 * 1024, 1024,	SECT_4K |
-	SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
-	{INFO("gd25lt256", 0xc86619, 0, 64 * 1024, 512,	SECT_4K |
-	SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
-	{INFO("gd25lt512", 0xc8661A, 0, 64 * 1024, 1024,	SECT_4K |
-	SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
-	{INFO("gd55lt01g", 0xc8661B, 0, 64 * 1024, 2048,	SECT_4K |
-	SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
-	{INFO("gd55lt02g", 0xc8661C, 0, 64 * 1024, 4096,	SECT_4K |
-	SPI_NOR_QUAD_READ | SPI_NOR_HAS_LOCK | SPI_NOR_4B_OPCODES)},
-	{INFO("gd25lx128j", 0xc86818, 0, 64 * 1024, 256,	SECT_4K |
-	SPI_NOR_OCTAL_READ)},
-	{
-		INFO("gd25lx256e", 0xc86819, 0, 64 * 1024, 512,
-		     SECT_4K | SPI_NOR_OCTAL_READ | SPI_NOR_4B_OPCODES)
-	},
-	/* adding these 1.8V OSPI flash parts */
-	{INFO("gd25lx512", 0xc8681A, 0, 64 * 1024, 1024,	SECT_4K |
-	SPI_NOR_OCTAL_READ | SPI_NOR_4B_OPCODES)},
-	{INFO("gd55lx01g", 0xc8681B, 0, 64 * 1024, 2048,	SECT_4K |
-	SPI_NOR_OCTAL_READ | SPI_NOR_4B_OPCODES)},
-	{INFO("gd55lx02g", 0xc8681C, 0, 64 * 1024, 4096,	SECT_4K |
-	SPI_NOR_OCTAL_READ | SPI_NOR_4B_OPCODES)},
-	{
-		INFO("gd55lb02ge", 0xc8671c, 0, 64 * 1024, 4096,
-		     SECT_4K | SPI_NOR_QUAD_READ |
-		     SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
+#if (IS_ENABLED(CONFIG_SPI_FLASH_EON))
+	&spi_nor_eon,
 #endif
-#ifdef CONFIG_SPI_FLASH_ISSI		/* ISSI */
-	/* ISSI */
-	{ INFO("is25lq040b", 0x9d4013, 0, 64 * 1024,   8,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("is25lp008", 0x9d6014, 0, 64 * 1024,  16, SPI_NOR_QUAD_READ) },
-	{ INFO("is25lp016", 0x9d6015, 0, 64 * 1024,  32, SPI_NOR_QUAD_READ) },
-	{ INFO("is25lp032",	0x9d6016, 0, 64 * 1024,  64, 0) },
-	{ INFO("is25lp064",	0x9d6017, 0, 64 * 1024, 128, 0) },
-	{ INFO("is25lp128",  0x9d6018, 0, 64 * 1024, 256,
-			SECT_4K | SPI_NOR_DUAL_READ) },
-	{ INFO("is25lp256",  0x9d6019, 0, 64 * 1024, 512,
-			SECT_4K | SPI_NOR_DUAL_READ) },
-	{ INFO("is25lp512",  0x9d601a, 0, 64 * 1024, 1024,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("is25lp512mj", 0x9d6020, 0, 64 * 1024, 1024,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("is25lp01g",  0x9d601b, 0, 64 * 1024, 2048,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("is25wp008", 0x9d7014, 0, 64 * 1024,  16, SPI_NOR_QUAD_READ) },
-	{ INFO("is25wp016", 0x9d7015, 0, 64 * 1024,  32, SPI_NOR_QUAD_READ) },
-	{ INFO("is25wp032",  0x9d7016, 0, 64 * 1024,  64,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("is25wp064",  0x9d7017, 0, 64 * 1024, 128,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("is25wp128",  0x9d7018, 0, 64 * 1024, 256,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("is25wp256",  0x9d7019, 0, 64 * 1024, 512,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-			SPI_NOR_4B_OPCODES) },
-	{ INFO("is25wp512",  0x9d701a, 0, 64 * 1024, 1024,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("is25wp512mj", 0x9d7020, 0, 64 * 1024, 1024,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("is25wp01g",  0x9d701b, 0, 64 * 1024, 2048,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("is25wp01gg",  0x9d7021, 0, 64 * 1024, 2048,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("is25wx128",  0x9d5b18, 0, 64 * 1024, 256,
-			SECT_4K | USE_FSR | SPI_NOR_OCTAL_READ) },
-	{ INFO("is25wx256",  0x9d5b19, 0, 128 * 1024, 256,
-			SECT_4K | USE_FSR | SPI_NOR_OCTAL_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("is25lx128",  0x9d5a18, 0, 64 * 1024, 256,
-			SECT_4K | USE_FSR | SPI_NOR_OCTAL_READ) },
-	{ INFO("is25lx512",  0x9d5a1a, 0, 64 * 1024, 1024,
-			SECT_4K | USE_FSR | SPI_NOR_4B_OPCODES | SPI_NOR_HAS_TB) },
-	{ INFO("is25lp01gg",  0x9d6021, 0, 64 * 1024, 2048,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_TB) },
-	{ INFO("is25lp010e",  0x9d4011, 0, 64 * 1024, 2,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("is25lp020e",  0x9d4012, 0, 64 * 1024, 4,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("is25lp040e",  0x9d4013, 0, 64 * 1024, 8,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("is25lp01gj",  0x9d6021, 0, 64 * 1024, 2048,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_TB) },
-	{ INFO("is25lp02gg",  0x9d6022, 0, 64 * 1024, 4096,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_TB) },
-	{ INFO("is25lp02gj",  0x9d6022, 0, 64 * 1024, 4096,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_TB) },
-	{ INFO("is25wp01gg",  0x9d7021, 0, 64 * 1024, 2048,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_TB) },
-	{ INFO("is25wp01gj",  0x9d7021, 0, 64 * 1024, 2048,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_TB) },
-	{ INFO("is25wj128f",  0x9d7118, 0, 64 * 1024, 256,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_TB) },
-	{ INFO("is25wp02gg",  0x9d7022, 0, 64 * 1024, 4096,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_TB) },
-	{ INFO("is25wp02gj",  0x9d7022, 0, 64 * 1024, 4096,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_HAS_TB) },
+#if (IS_ENABLED(CONFIG_SPI_FRAM_FUJITSU))
+	&spi_nor_fujitsu,
 #endif
-#ifdef CONFIG_SPI_FLASH_MACRONIX	/* MACRONIX */
-	/* Macronix */
-	{ INFO("mx25l2005a",  0xc22012, 0, 64 * 1024,   4, SECT_4K) },
-	{ INFO("mx25l4005a",  0xc22013, 0, 64 * 1024,   8, SECT_4K) },
-	{ INFO("mx25l8005",   0xc22014, 0, 64 * 1024,  16, 0) },
-	{ INFO("mx25l1606e",  0xc22015, 0, 64 * 1024,  32, SECT_4K) },
-	{ INFO("mx25l3205d",  0xc22016, 0, 64 * 1024,  64, SECT_4K) },
-	{ INFO("mx25l6405d",  0xc22017, 0, 64 * 1024, 128, SECT_4K) },
-	{ INFO("mx25u2033e",  0xc22532, 0, 64 * 1024,   4, SECT_4K) },
-	{ INFO("mx25u1635e",  0xc22535, 0, 64 * 1024,  32, SECT_4K) },
-	{ INFO("mx25u3235f",  0xc22536, 0, 4 * 1024,  1024, SECT_4K) },
-	{ INFO("mx25u6435f",  0xc22537, 0, 64 * 1024, 128, SECT_4K) },
-	{ INFO("mx25l12805d", 0xc22018, 0, 64 * 1024, 256, SECT_4K) },
-	{ INFO("mx25u12835f", 0xc22538, 0, 64 * 1024, 256, SECT_4K |
-	       SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("mx25u51245g", 0xc2253a, 0, 64 * 1024, 1024, SECT_4K |
-	       SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("mx25l12855e", 0xc22618, 0, 64 * 1024, 256, 0) },
-	{ INFO("mx25l25635e", 0xc22019, 0, 64 * 1024, 512, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("mx25u25635f", 0xc22539, 0, 64 * 1024, 512, SECT_4K | SPI_NOR_4B_OPCODES) },
-	{ INFO("mx25v8035f",  0xc22314, 0, 64 * 1024,  16, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("mx25r1635f",  0xc22815, 0, 64 * 1024,  32, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("mx25l25655e", 0xc22619, 0, 64 * 1024, 512, 0) },
-	{ INFO("mx66l51235l", 0xc2201a, 0, 64 * 1024, 1024, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("mx66u51235f", 0xc2253a, 0, 64 * 1024, 1024, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("mx25u51245f", 0xc2953a, 0, 64 * 1024, 1024, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("mx66u1g45g",  0xc2253b, 0, 64 * 1024, 2048, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("mx66u2g45g",  0xc2253c, 0, 64 * 1024, 4096, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("mx66l1g45g",  0xc2201b, 0, 64 * 1024, 2048, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("mx66l2g45g",  0xc2201c, 0, 64 * 1024, 4096, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("mx25l1633e", 0xc22415, 0, 64 * 1024,   32, SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES | SECT_4K) },
-	{ INFO("mx25r6435f", 0xc22817, 0, 64 * 1024,   128,  SECT_4K) },
-	{ INFO("mx66uw2g345gx0", 0xc2943c, 0, 64 * 1024, 4096, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES | SPI_NOR_OCTAL_READ) },
-	{ INFO("mx66lm1g45g",    0xc2853b, 0, 64 * 1024, 2048, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("mx25lm51245g",   0xc2853a, 0, 64 * 1024, 1024, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("mx25lw51245g",   0xc2863a, 0, 64 * 1024, 1024, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("mx25lm25645g",   0xc28539, 0, 64 * 1024, 512, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("mx66uw2g345g",   0xc2843c, 0, 64 * 1024, 4096, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("mx66um1g45g",    0xc2803b, 0, 64 * 1024, 2048, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("mx66uw1g45g",    0xc2813b, 0, 64 * 1024, 2048, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("mx25uw51245g",   0xc2813a, 0, 64 * 1024, 1024, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("mx25uw51345g",   0xc2843a, 0, 64 * 1024, 1024, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("mx25um25645g",   0xc28039, 0, 64 * 1024, 512, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("mx25uw25645g",   0xc28139, 0, 64 * 1024, 512, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("mx25um25345g",   0xc28339, 0, 64 * 1024, 512, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("mx25uw25345g",   0xc28439, 0, 64 * 1024, 512, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("mx25uw12845g",   0xc28138, 0, 64 * 1024, 256, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("mx25uw12345g",   0xc28438, 0, 64 * 1024, 256, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("mx25uw6445g",    0xc28137, 0, 64 * 1024, 128, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("mx25uw6345g",    0xc28437, 0, 64 * 1024, 128, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
+#if (IS_ENABLED(CONFIG_SPI_FLASH_GIGADEVICE))
+	&spi_nor_gigadevice,
 #endif
-#ifdef CONFIG_SPI_FLASH_PUYA
-	/* Puya Semiconductor (Shanghai) Co., Ltd */
-	{ INFO
-	 ("p25q05h", 0x856010, 0, 64 * 1024, 1,
-	  SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO
-	 ("p25q10h", 0x856011, 0, 64 * 1024, 2,
-	  SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO
-	 ("p25q20h", 0x856012, 0, 64 * 1024, 4,
-	  SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO
-	 ("p25q40h", 0x856013, 0, 64 * 1024, 8,
-	  SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO
-	 ("p25q80h", 0x856014, 0, 64 * 1024, 16,
-	  SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO
-	 ("p25q16h", 0x856015, 0, 64 * 1024, 32,
-	  SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO
-	 ("p25q32h", 0x856016, 0, 64 * 1024, 64,
-	  SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO
-	 ("p25q64h", 0x856017, 0, 64 * 1024, 128,
-	  SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO
-	 ("p25q128h", 0x856018, 0, 64 * 1024, 256,
-	  SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO
-	 ("py25f512hb", 0x85231a, 0, 64 * 1024, 1024,
-	  SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO
-	 ("py25f01ghb", 0x85231b, 0, 64 * 1024, 2048,
-	  SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO
-	 ("py25f512lc", 0x85631a, 0, 64 * 1024, 1024,
-	  SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO
-	 ("py25f01glc", 0x85631b, 0, 64 * 1024, 2048,
-	  SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+#if (IS_ENABLED(CONFIG_SPI_FLASH_ISSI))
+	&spi_nor_issi,
 #endif
-
-#ifdef CONFIG_SPI_FLASH_SILICONKAISER
-	{ INFO("sk25lp128", 0x257018, 0, 64 * 1024, 256, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+#if (IS_ENABLED(CONFIG_SPI_FLASH_MACRONIX))
+	&spi_nor_macronix,
 #endif
-
-#ifdef CONFIG_SPI_FLASH_STMICRO		/* STMICRO */
-	/* Micron */
-	{ INFO("n25q016a",	 0x20bb15, 0, 64 * 1024,   32, SECT_4K | SPI_NOR_QUAD_READ) },
-	{ INFO("n25q032",	 0x20ba16, 0, 64 * 1024,   64, SPI_NOR_QUAD_READ) },
-	{ INFO("n25q032a",	0x20bb16, 0, 64 * 1024,   64, SPI_NOR_QUAD_READ) },
-	{ INFO("n25q064",     0x20ba17, 0, 64 * 1024,  128, SECT_4K | SPI_NOR_QUAD_READ) },
-	{ INFO("n25q064a",    0x20bb17, 0, 64 * 1024,  128, SECT_4K | SPI_NOR_QUAD_READ) },
-	{ INFO("n25q128a11",  0x20bb18, 0, 64 * 1024,  256, SECT_4K | SPI_NOR_QUAD_READ) },
-	{ INFO("n25q128a13",  0x20ba18, 0, 64 * 1024,  256, SECT_4K | SPI_NOR_QUAD_READ) },
-	{ INFO6("mt25ql256a",    0x20ba19, 0x104400, 64 * 1024,  512, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES | USE_FSR) },
-	{ INFO("n25q256a",    0x20ba19, 0, 64 * 1024,  512, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | USE_FSR) },
-	{ INFO6("mt25qu256a",  0x20bb19, 0x104400, 64 * 1024,  512, SECT_4K | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES | USE_FSR) },
-	{ INFO("n25q256ax1",  0x20bb19, 0, 64 * 1024,  512, SECT_4K | SPI_NOR_QUAD_READ | USE_FSR) },
-	{ INFO("mt25qu128ab", 0x20bb18, 0, 64 * 1024,  256, SECT_4K | USE_FSR | SPI_NOR_QUAD_READ) },
-	{ INFO6("mt25qu512a",  0x20bb20, 0x104400, 64 * 1024, 1024,
-		 SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES |
-		 USE_FSR) },
-	{ INFO("n25q512a",    0x20bb20, 0, 64 * 1024, 1024, SECT_4K | USE_FSR | SPI_NOR_QUAD_READ) },
-	{ INFO6("mt25ql512a",  0x20ba20, 0x104400, 64 * 1024, 1024, SECT_4K | USE_FSR | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("n25q512ax3",  0x20ba20, 0, 64 * 1024, 1024, SECT_4K | USE_FSR | SPI_NOR_QUAD_READ) },
-	{ INFO("n25q00",      0x20ba21, 0, 64 * 1024, 2048, SECT_4K | USE_FSR | SPI_NOR_QUAD_READ | NO_CHIP_ERASE) },
-	{ INFO("n25q00a",     0x20bb21, 0, 64 * 1024, 2048, SECT_4K | USE_FSR | SPI_NOR_QUAD_READ | NO_CHIP_ERASE) },
-	{ INFO("mt25ql01g",   0x21ba20, 0, 64 * 1024, 2048, SECT_4K | USE_FSR | SPI_NOR_QUAD_READ | NO_CHIP_ERASE) },
-	{ INFO6("mt25qu01g",  0x20bb21, 0x104400, 64 * 1024, 2048, SECT_4K | USE_FSR | SPI_NOR_QUAD_READ | NO_CHIP_ERASE | SPI_NOR_4B_OPCODES) },
-	{ INFO("mt25qu02g",   0x20bb22, 0, 64 * 1024, 4096, SECT_4K | USE_FSR | SPI_NOR_QUAD_READ | NO_CHIP_ERASE) },
-	{ INFO("mt25ql02g",   0x20ba22, 0, 64 * 1024, 4096, SECT_4K | USE_FSR | SPI_NOR_QUAD_READ | NO_CHIP_ERASE | SPI_NOR_4B_OPCODES) },
-#ifdef CONFIG_SPI_FLASH_MT35XU
-	{ INFO("mt35xl512aba", 0x2c5a1a, 0,  128 * 1024,  512, USE_FSR | SPI_NOR_OCTAL_READ | SPI_NOR_4B_OPCODES | SPI_NOR_OCTAL_DTR_READ) },
-	{ INFO("mt35xu512aba", 0x2c5b1a, 0,  128 * 1024,  512, USE_FSR | SPI_NOR_OCTAL_READ | SPI_NOR_4B_OPCODES | SPI_NOR_OCTAL_DTR_READ) },
-	{ INFO("mt35xu01gaba", 0x2c5b1b, 0,  128 * 1024,  1024,
-		USE_FSR | SPI_NOR_OCTAL_READ | SPI_NOR_4B_OPCODES | NO_CHIP_ERASE) },
-#endif /* CONFIG_SPI_FLASH_MT35XU */
-	{ INFO6("mt35xu01g",  0x2c5b1b, 0x104100, 128 * 1024,  1024,
-		USE_FSR | SPI_NOR_OCTAL_READ | SPI_NOR_4B_OPCODES | NO_CHIP_ERASE) },
-	{ INFO("mt35xu02g",  0x2c5b1c, 0, 128 * 1024,  2048,
-		USE_FSR | SPI_NOR_OCTAL_READ | SPI_NOR_4B_OPCODES | NO_CHIP_ERASE) },
+#if (IS_ENABLED(CONFIG_SPI_FLASH_PUYA))
+	&spi_nor_puya,
 #endif
-#ifdef CONFIG_SPI_FLASH_SPANSION	/* SPANSION */
-	/* Spansion/Cypress -- single (large) sector size only, at least
-	 * for the chips listed here (without boot sectors).
-	 */
-	{ INFO("s25sl032p",  0x010215, 0x4d00,  64 * 1024,  64, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("s25sl064p",  0x010216, 0x4d00,  64 * 1024, 128, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO6("s25fl256s0", 0x010219, 0x4d0080, 256 * 1024, 128, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | USE_CLSR) },
-	{ INFO6("s25fl256s1", 0x010219, 0x4d0180,  64 * 1024, 512, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | USE_CLSR) },
-	{ INFO6("s25fl512s",  0x010220, 0x4d0080, 256 * 1024, 256, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | USE_CLSR) },
-	{ INFO6("s25fs064s",  0x010217, 0x4d0181,  64 * 1024, 128, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | USE_CLSR) },
-	{ INFO6("s25fs128s",  0x012018, 0x4d0181,  64 * 1024, 256, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | USE_CLSR) },
-	{ INFO6("s25fs256s",  0x010219, 0x4d0181,  64 * 1024, 512, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | USE_CLSR) },
-	{ INFO6("s25fs512s",  0x010220, 0x4d0081, 256 * 1024, 256, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | USE_CLSR) },
-	{ INFO("s25fl512s_256k",  0x010220, 0x4d00, 256 * 1024, 256, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | USE_CLSR) },
-	{ INFO("s25fl512s_64k",  0x010220, 0x4d01, 64 * 1024, 1024, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | USE_CLSR) },
-	{ INFO("s25fl512s_512k", 0x010220, 0x4f00, 256 * 1024, 256, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | USE_CLSR) },
-	{ INFO("s70fs01gs_256k", 0x010221, 0x4d00, 256 * 1024, 512, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("s25sl12800", 0x012018, 0x0300, 256 * 1024,  64, 0) },
-	{ INFO("s25sl12801", 0x012018, 0x0301,  64 * 1024, 256, 0) },
-	{ INFO6("s25fl128s",  0x012018, 0x4d0180, 64 * 1024, 256, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | USE_CLSR) },
-	{ INFO("s25fl129p0", 0x012018, 0x4d00, 256 * 1024,  64, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | USE_CLSR) },
-	{ INFO("s25fl129p1", 0x012018, 0x4d01,  64 * 1024, 256, SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | USE_CLSR) },
-	{ INFO("s25sl008a",  0x010213,      0,  64 * 1024,  16, 0) },
-	{ INFO("s25sl016a",  0x010214,      0,  64 * 1024,  32, 0) },
-	{ INFO("s25sl032a",  0x010215,      0,  64 * 1024,  64, 0) },
-	{ INFO("s25sl064a",  0x010216,      0,  64 * 1024, 128, 0) },
-	{ INFO("s25fl116k",  0x014015,      0,  64 * 1024,  32, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("s25fl164k",  0x014017,      0,  64 * 1024, 128, SECT_4K) },
-	{ INFO("s25fl208k",  0x014014,      0,  64 * 1024,  16, SECT_4K | SPI_NOR_DUAL_READ) },
-	{ INFO("s25fl064l",  0x016017,      0,  64 * 1024, 128, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("s25fl128l",  0x016018,      0,  64 * 1024, 256, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("s25fl256l",  0x016019,      0,  64 * 1024, 512, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO6("s25hl512t",  0x342a1a, 0x0f0390, 256 * 1024, 256,
-		SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES |
-		USE_CLSR) },
-	{ INFO6("s25hl01gt",  0x342a1b, 0x0f0390, 256 * 1024, 512,
-		SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES |
-		USE_CLSR) },
-	{ INFO6("s25hl02gt",  0x342a1c, 0x0f0090, 256 * 1024, 1024,
-		SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES | NO_CHIP_ERASE) },
-	{ INFO6("s25hs512t",  0x342b1a, 0x0f0390, 256 * 1024, 256,
-		SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES |
-		USE_CLSR) },
-	{ INFO6("s25hs01gt",  0x342b1b, 0x0f0390, 256 * 1024, 512,
-		SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES |
-		USE_CLSR) },
-	{ INFO6("s25hs02gt",  0x342b1c, 0x0f0090, 256 * 1024, 1024,
-		SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES | NO_CHIP_ERASE) },
-	{ INFO6("s25fs256t",  0x342b19, 0x0f0890, 128 * 1024, 256,
-		SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-#ifdef CONFIG_SPI_FLASH_S28HX_T
-	{ INFO("s28hl256t",  0x345a19,      0, 256 * 1024, 128, SPI_NOR_OCTAL_DTR_READ) },
-	{ INFO("s28hl512t",  0x345a1a,      0, 256 * 1024, 256, SPI_NOR_OCTAL_DTR_READ) },
-	{ INFO("s28hl01gt",  0x345a1b,      0, 256 * 1024, 512, SPI_NOR_OCTAL_DTR_READ) },
-	{ INFO("s28hl02gt",  0x345a1c,      0, 256 * 1024, 1024, SPI_NOR_OCTAL_DTR_READ | NO_CHIP_ERASE) },
-	{ INFO("s28hs256t",  0x345b19,      0, 256 * 1024, 128, SPI_NOR_OCTAL_DTR_READ) },
-	{ INFO("s28hs512t",  0x345b1a,      0, 256 * 1024, 256, SPI_NOR_OCTAL_DTR_READ) },
-	{ INFO("s28hs01gt",  0x345b1b,      0, 256 * 1024, 512, SPI_NOR_OCTAL_DTR_READ) },
-	{ INFO("s28hs02gt",  0x345b1c,      0, 256 * 1024, 1024, SPI_NOR_OCTAL_DTR_READ | NO_CHIP_ERASE) },
+#if (IS_ENABLED(CONFIG_SPI_FLASH_SILICONKAISER))
+	&spi_nor_siliconkaiser,
 #endif
+#if (IS_ENABLED(CONFIG_SPI_FLASH_STMICRO))
+	&spi_nor_micron,
+	&spi_nor_st,
 #endif
-#ifdef CONFIG_SPI_FLASH_SST		/* SST */
-	/* SST -- large erase sizes are "overlays", "sectors" are 4K */
-	{ INFO("sst25vf040b", 0xbf258d, 0, 64 * 1024,  8, SECT_4K | SST_WRITE) },
-	{ INFO("sst25vf080b", 0xbf258e, 0, 64 * 1024, 16, SECT_4K | SST_WRITE) },
-	{ INFO("sst25vf016b", 0xbf2541, 0, 64 * 1024, 32, SECT_4K | SST_WRITE) },
-	{ INFO("sst25vf032b", 0xbf254a, 0, 64 * 1024, 64, SECT_4K | SST_WRITE) },
-	{ INFO("sst25vf064c", 0xbf254b, 0, 64 * 1024, 128, SECT_4K) },
-	{ INFO("sst25wf512",  0xbf2501, 0, 64 * 1024,  1, SECT_4K | SST_WRITE) },
-	{ INFO("sst25wf010",  0xbf2502, 0, 64 * 1024,  2, SECT_4K | SST_WRITE) },
-	{ INFO("sst25wf020",  0xbf2503, 0, 64 * 1024,  4, SECT_4K | SST_WRITE) },
-	{ INFO("sst25wf020a", 0x621612, 0, 64 * 1024,  4, SECT_4K) },
-	{ INFO("sst25wf040b", 0x621613, 0, 64 * 1024,  8, SECT_4K) },
-	{ INFO("sst25wf040",  0xbf2504, 0, 64 * 1024,  8, SECT_4K | SST_WRITE) },
-	{ INFO("sst25wf080",  0xbf2505, 0, 64 * 1024, 16, SECT_4K | SST_WRITE) },
-	{ INFO("sst26vf064b", 0xbf2643, 0, 64 * 1024, 128, SECT_4K | SPI_NOR_HAS_SST26LOCK | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("sst26wf016b", 0xbf2641, 0, 64 * 1024,  32, SECT_4K) },
-	{ INFO("sst26wf016",  0xbf2651, 0, 64 * 1024,  32, SECT_4K | SPI_NOR_HAS_SST26LOCK) },
-	{ INFO("sst26wf032",  0xbf2622, 0, 64 * 1024,  64, SECT_4K | SPI_NOR_HAS_SST26LOCK) },
-	{ INFO("sst26wf064",  0xbf2643, 0, 64 * 1024, 128, SECT_4K | SPI_NOR_HAS_SST26LOCK) },
+#if (IS_ENABLED(CONFIG_SPI_FLASH_SPANSION))
+	&spi_nor_spansion,
 #endif
-#ifdef CONFIG_SPI_FLASH_STMICRO		/* STMICRO */
-	/* STMicroelectronics -- newer production may have feature updates */
-	{ INFO("m25p10",  0x202011,  0,  32 * 1024,   4, 0) },
-	{ INFO("m25p20",  0x202012,  0,  64 * 1024,   4, 0) },
-	{ INFO("m25p40",  0x202013,  0,  64 * 1024,   8, 0) },
-	{ INFO("m25p80",  0x202014,  0,  64 * 1024,  16, 0) },
-	{ INFO("m25p16",  0x202015,  0,  64 * 1024,  32, 0) },
-	{ INFO("m25p32",  0x202016,  0,  64 * 1024,  64, 0) },
-	{ INFO("m25p64",  0x202017,  0,  64 * 1024, 128, 0) },
-	{ INFO("m25p128", 0x202018,  0, 256 * 1024,  64, 0) },
-	{ INFO("m25pe16", 0x208015,  0, 64 * 1024, 32, SECT_4K) },
-	{ INFO("m25px16",    0x207115,  0, 64 * 1024, 32, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("m25px64",    0x207117,  0, 64 * 1024, 128, 0) },
+#if (IS_ENABLED(CONFIG_SPI_FLASH_SST))
+	&spi_nor_sst,
 #endif
-#ifdef CONFIG_SPI_FLASH_WINBOND		/* WINBOND */
-	/* Winbond -- w25x "blocks" are 64K, "sectors" are 4KiB */
-	{ INFO("w25p80", 0xef2014, 0x0,	64 * 1024,    16, 0) },
-	{ INFO("w25p16", 0xef2015, 0x0,	64 * 1024,    32, 0) },
-	{ INFO("w25p32", 0xef2016, 0x0,	64 * 1024,    64, 0) },
-	{ INFO("w25x05", 0xef3010, 0, 64 * 1024,  1,  SECT_4K) },
-	{ INFO("w25x40", 0xef3013, 0, 64 * 1024,  8,  SECT_4K) },
-	{ INFO("w25x16", 0xef3015, 0, 64 * 1024,  32, SECT_4K) },
-	{ INFO("w25x32", 0xef3016, 0, 64 * 1024,  64, SECT_4K) },
-	{ INFO("w25q20cl", 0xef4012, 0, 64 * 1024,  4, SECT_4K) },
-	{ INFO("w25q20bw", 0xef5012, 0, 64 * 1024,  4, SECT_4K) },
-	{ INFO("w25q20ew", 0xef6012, 0, 64 * 1024,  4, SECT_4K) },
-	{
-		INFO("w25q16dw", 0xef6015, 0, 64 * 1024,  32,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
-	{
-		INFO("w25q32dw", 0xef6016, 0, 64 * 1024,  64,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
-	{
-		INFO("w25q16jv", 0xef7015, 0, 64 * 1024,  32,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ)
-	},
-	{
-		INFO("w25q32jv", 0xef7016, 0, 64 * 1024,  64,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
-	{
-		INFO("w25q32jwm", 0xef8016, 0, 64 * 1024,  64,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
-	{
-		INFO("w25q256jwm", 0xef8019, 0, 64 * 1024, 512,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
-	{ INFO("w25x64", 0xef3017, 0, 64 * 1024, 128, SECT_4K) },
-	{
-		INFO("w25q64dw", 0xef6017, 0, 64 * 1024, 128,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
-	{
-		INFO("w25q64jv", 0xef7017, 0, 64 * 1024, 128,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
-	{
-		INFO("w25q128fw", 0xef6018, 0, 64 * 1024, 256,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
-	{
-		INFO("w25q128jv", 0xef7018, 0, 64 * 1024, 256,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
-	{
-		INFO("w25q128jw", 0xef8018, 0, 64 * 1024, 256,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
-	{
-		INFO("w25q256fw", 0xef6019, 0, 64 * 1024, 512,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
-	{
-		INFO("w25q256jw", 0xef7019, 0, 64 * 1024, 512,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
-	{
-		INFO("w25q512nwq", 0xef6020, 0, 64 * 1024, 1024,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
-	{
-		INFO("w25q512nwm", 0xef8020, 0, 64 * 1024, 1024,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
-	{
-		INFO("w25q512jvq", 0xef4020, 0, 64 * 1024, 1024,
-		     SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-		     SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
-	{
-		INFO("w25q01jv", 0xef4021, 0, 64 * 1024, 2048,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
-	{
-		INFO("w25q01jvfim", 0xef7021, 0, 64 * 1024, 2048,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
-	{
-		INFO("w25q02jv", 0xef7022, 0, 64 * 1024, 4096,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
-	{ INFO("w25q80", 0xef5014, 0, 64 * 1024,  16, SECT_4K) },
-	{ INFO("w25q80bl", 0xef4014, 0, 64 * 1024,  16, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{
-		INFO("w25q16cl", 0xef4015, 0, 64 * 1024,  32,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
-	{ INFO("w25q32", 0xef4016, 0, 64 * 1024,  64, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("w25q64cv", 0xef4017, 0, 64 * 1024,  128, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("w25q128", 0xef4018, 0, 64 * 1024, 256,
-			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
-			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
-	},
-	{ INFO("w25q256", 0xef4019, 0, 64 * 1024, 512, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("w25m512jw", 0xef6119, 0, 64 * 1024, 1024, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("w25m512jv", 0xef7119, 0, 64 * 1024, 1024, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("w25h02jv", 0xef9022, 0, 64 * 1024, 4096, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("w25h512nw-am", 0xefa020, 0, 64 * 1024, 1024, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("w25h01nw-am", 0xefa021, 0, 64 * 1024, 2048, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("w25h02nw-am", 0xefa022, 0, 64 * 1024, 4096, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("w25q01nw-iq", 0xef6021, 0, 64 * 1024, 2048, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("w25q01nw-im", 0xef8021, 0, 64 * 1024, 2048, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("w25q02nw-im", 0xef8022, 0, 64 * 1024, 4096, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("w77q51nw", 0xef8a1a, 0, 64 * 1024, 1024, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+#if (IS_ENABLED(CONFIG_SPI_FLASH_WINBOND))
+	&spi_nor_winbond,
 #endif
-#ifdef CONFIG_SPI_FLASH_XMC
-	/* XMC (Wuhan Xinxin Semiconductor Manufacturing Corp.) */
-	{ INFO("XM25QH64A", 0x207017, 0, 64 * 1024, 128, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("XM25QH64C", 0x204017, 0, 64 * 1024, 128, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("XM25QH128A", 0x207018, 0, 64 * 1024, 256, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("XM25QU128C", 0x204118, 0, 64 * 1024, 256, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("XM25QH256C", 0x204019, 0, 64 * 1024, 512, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("XM25QU256C", 0x204119, 0, 64 * 1024, 512, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("XM25QH512C", 0x204020, 0, 64 * 1024, 1024, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("XM25QU512C", 0x204120, 0, 64 * 1024, 1024, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("XM25QH01D", 0x204021, 0, 64 * 1024, 2048, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+#if (IS_ENABLED(CONFIG_SPI_FLASH_XMC))
+	&spi_nor_xmc,
 #endif
-#ifdef CONFIG_SPI_FLASH_XTX
-	/* XTX Technology Limited */
-	/* adding these 3V QSPI flash parts */
-	{ INFO("xt25f08", 0x0b4014, 0, 64 * 1024, 16,
-	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("xt25f16", 0x0b4015, 0, 64 * 1024, 32,
-	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("xt25f32", 0x0b4016, 0, 64 * 1024, 64,
-	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("xt25f64", 0x0b4017, 0, 64 * 1024, 128,
-	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("xt25f128", 0x0b4018, 0, 64 * 1024, 256,
-	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("xt25f256", 0x0b4019, 0, 64 * 1024, 512,
-	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-	/* adding these 1.8V QSPI flash parts */
-	{ INFO("xt25q08", 0x0b6014, 0, 64 * 1024, 16,
-	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("xt25q16", 0x0b6015, 0, 64 * 1024, 32,
-	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("xt25q32", 0x0b6016, 0, 64 * 1024, 64,
-	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("xt25q64", 0x0b6017, 0, 64 * 1024, 128,
-	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("xt25q128", 0x0b6018, 0, 64 * 1024, 256,
-	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
-	{ INFO("xt25q256", 0x0b6019, 0, 64 * 1024, 512,
-	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("xt25q512", 0x0b601A, 0, 64 * 1024, 1024,
-	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("xt25q01g", 0x0b601B, 0, 64 * 1024, 2048,
-	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("xt55q02g", 0x0b601C, 0, 64 * 1024, 4096,
-	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-	/* adding these wide voltage QSPI flash parts */
-	{ INFO("xt25w512", 0x0b651A, 0, 64 * 1024, 1024,
-	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
-	{ INFO("xt25w01g", 0x0b651B, 0, 64 * 1024, 2048,
-	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+#if (IS_ENABLED(CONFIG_SPI_FLASH_XTX))
+	&spi_nor_xtx,
 #endif
-#ifdef CONFIG_SPI_FLASH_ZBIT
-	/* Zbit Semiconductor Inc. */
-	{ INFO("zb25vq128", 0x5e4018, 0, 64 * 1024, 256,
-	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+#if (IS_ENABLED(CONFIG_SPI_FLASH_ZBIT))
+	&spi_nor_zbit,
 #endif
-	{ },
-};
-
-static const struct spi_nor_manufacturer *manufacturers[] = {
 };
 
 const struct flash_info *spi_nor_match_id(struct spi_nor *nor, const u8 *id)
diff --git a/drivers/mtd/spi/spi-nor-tiny.c b/drivers/mtd/spi/spi-nor-tiny.c
index c7824285191..0df78483ccb 100644
--- a/drivers/mtd/spi/spi-nor-tiny.c
+++ b/drivers/mtd/spi/spi-nor-tiny.c
@@ -387,13 +387,6 @@ static const struct flash_info *spi_nor_read_id(struct spi_nor *nor)
 	if (info)
 		return info;
 
-	info = spi_nor_ids;
-	for (; info->sector_size != 0; info++) {
-		if (info->id_len) {
-			if (!memcmp(info->id, id, info->id_len))
-				return info;
-		}
-	}
 	dev_dbg(nor->dev, "unrecognized JEDEC id bytes: %02x, %02x, %02x\n",
 		id[0], id[1], id[2]);
 	return ERR_PTR(-EMEDIUMTYPE);
diff --git a/drivers/mtd/spi/sst.c b/drivers/mtd/spi/sst.c
new file mode 100644
index 00000000000..e169dba663a
--- /dev/null
+++ b/drivers/mtd/spi/sst.c
@@ -0,0 +1,34 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Copyright (C) 2013 Jagannadha Sutradharudu Teki, Xilinx Inc.
+ * Copyright (C) 2016 Jagan Teki <jagan@openedev.com>
+ * Copyright (C) 2018 Texas Instruments Incorporated - https://www.ti.com/
+ */
+
+#include <linux/mtd/spi-nor.h>
+#include "sf_internal.h"
+
+static const struct flash_info sst_nor_parts[] = {
+	{ INFO("sst25vf040b", 0xbf258d, 0, 64 * 1024,  8, SECT_4K | SST_WRITE) },
+	{ INFO("sst25vf080b", 0xbf258e, 0, 64 * 1024, 16, SECT_4K | SST_WRITE) },
+	{ INFO("sst25vf016b", 0xbf2541, 0, 64 * 1024, 32, SECT_4K | SST_WRITE) },
+	{ INFO("sst25vf032b", 0xbf254a, 0, 64 * 1024, 64, SECT_4K | SST_WRITE) },
+	{ INFO("sst25vf064c", 0xbf254b, 0, 64 * 1024, 128, SECT_4K) },
+	{ INFO("sst25wf512",  0xbf2501, 0, 64 * 1024,  1, SECT_4K | SST_WRITE) },
+	{ INFO("sst25wf010",  0xbf2502, 0, 64 * 1024,  2, SECT_4K | SST_WRITE) },
+	{ INFO("sst25wf020",  0xbf2503, 0, 64 * 1024,  4, SECT_4K | SST_WRITE) },
+	{ INFO("sst25wf020a", 0x621612, 0, 64 * 1024,  4, SECT_4K) },
+	{ INFO("sst25wf040b", 0x621613, 0, 64 * 1024,  8, SECT_4K) },
+	{ INFO("sst25wf040",  0xbf2504, 0, 64 * 1024,  8, SECT_4K | SST_WRITE) },
+	{ INFO("sst25wf080",  0xbf2505, 0, 64 * 1024, 16, SECT_4K | SST_WRITE) },
+	{ INFO("sst26vf064b", 0xbf2643, 0, 64 * 1024, 128, SECT_4K | SPI_NOR_HAS_SST26LOCK | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("sst26wf016b", 0xbf2641, 0, 64 * 1024,  32, SECT_4K) },
+	{ INFO("sst26wf016",  0xbf2651, 0, 64 * 1024,  32, SECT_4K | SPI_NOR_HAS_SST26LOCK) },
+	{ INFO("sst26wf032",  0xbf2622, 0, 64 * 1024,  64, SECT_4K | SPI_NOR_HAS_SST26LOCK) },
+	{ INFO("sst26wf064",  0xbf2643, 0, 64 * 1024, 128, SECT_4K | SPI_NOR_HAS_SST26LOCK) },
+};
+
+const struct spi_nor_manufacturer spi_nor_sst = {
+	.parts = sst_nor_parts,
+	.nparts = ARRAY_SIZE(sst_nor_parts),
+};
diff --git a/drivers/mtd/spi/winbond.c b/drivers/mtd/spi/winbond.c
new file mode 100644
index 00000000000..02c29ccf78c
--- /dev/null
+++ b/drivers/mtd/spi/winbond.c
@@ -0,0 +1,146 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Copyright (C) 2013 Jagannadha Sutradharudu Teki, Xilinx Inc.
+ * Copyright (C) 2016 Jagan Teki <jagan@openedev.com>
+ * Copyright (C) 2018 Texas Instruments Incorporated - https://www.ti.com/
+ */
+
+#include <linux/mtd/spi-nor.h>
+#include "sf_internal.h"
+
+static const struct flash_info winbond_nor_parts[] = {
+	{ INFO("w25p80", 0xef2014, 0x0,	64 * 1024,    16, 0) },
+	{ INFO("w25p16", 0xef2015, 0x0,	64 * 1024,    32, 0) },
+	{ INFO("w25p32", 0xef2016, 0x0,	64 * 1024,    64, 0) },
+	{ INFO("w25x05", 0xef3010, 0, 64 * 1024,  1,  SECT_4K) },
+	{ INFO("w25x40", 0xef3013, 0, 64 * 1024,  8,  SECT_4K) },
+	{ INFO("w25x16", 0xef3015, 0, 64 * 1024,  32, SECT_4K) },
+	{ INFO("w25x32", 0xef3016, 0, 64 * 1024,  64, SECT_4K) },
+	{ INFO("w25q20cl", 0xef4012, 0, 64 * 1024,  4, SECT_4K) },
+	{ INFO("w25q20bw", 0xef5012, 0, 64 * 1024,  4, SECT_4K) },
+	{ INFO("w25q20ew", 0xef6012, 0, 64 * 1024,  4, SECT_4K) },
+	{
+		INFO("w25q16dw", 0xef6015, 0, 64 * 1024,  32,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+	{
+		INFO("w25q32dw", 0xef6016, 0, 64 * 1024,  64,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+	{
+		INFO("w25q16jv", 0xef7015, 0, 64 * 1024,  32,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ)
+	},
+	{
+		INFO("w25q32jv", 0xef7016, 0, 64 * 1024,  64,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+	{
+		INFO("w25q32jwm", 0xef8016, 0, 64 * 1024,  64,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+	{
+		INFO("w25q256jwm", 0xef8019, 0, 64 * 1024, 512,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+	{ INFO("w25x64", 0xef3017, 0, 64 * 1024, 128, SECT_4K) },
+	{
+		INFO("w25q64dw", 0xef6017, 0, 64 * 1024, 128,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+	{
+		INFO("w25q64jv", 0xef7017, 0, 64 * 1024, 128,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+	{
+		INFO("w25q128fw", 0xef6018, 0, 64 * 1024, 256,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+	{
+		INFO("w25q128jv", 0xef7018, 0, 64 * 1024, 256,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+	{
+		INFO("w25q128jw", 0xef8018, 0, 64 * 1024, 256,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+	{
+		INFO("w25q256fw", 0xef6019, 0, 64 * 1024, 512,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+	{
+		INFO("w25q256jw", 0xef7019, 0, 64 * 1024, 512,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+	{
+		INFO("w25q512nwq", 0xef6020, 0, 64 * 1024, 1024,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+	{
+		INFO("w25q512nwm", 0xef8020, 0, 64 * 1024, 1024,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+	{
+		INFO("w25q512jvq", 0xef4020, 0, 64 * 1024, 1024,
+		     SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+		     SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+	{
+		INFO("w25q01jv", 0xef4021, 0, 64 * 1024, 2048,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+	{
+		INFO("w25q01jvfim", 0xef7021, 0, 64 * 1024, 2048,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+	{
+		INFO("w25q02jv", 0xef7022, 0, 64 * 1024, 4096,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+	{ INFO("w25q80", 0xef5014, 0, 64 * 1024,  16, SECT_4K) },
+	{ INFO("w25q80bl", 0xef4014, 0, 64 * 1024,  16, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{
+		INFO("w25q16cl", 0xef4015, 0, 64 * 1024,  32,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+	{ INFO("w25q32", 0xef4016, 0, 64 * 1024,  64, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("w25q64cv", 0xef4017, 0, 64 * 1024,  128, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("w25q128", 0xef4018, 0, 64 * 1024, 256,
+			SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ |
+			SPI_NOR_HAS_LOCK | SPI_NOR_HAS_TB)
+	},
+	{ INFO("w25q256", 0xef4019, 0, 64 * 1024, 512, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("w25m512jw", 0xef6119, 0, 64 * 1024, 1024, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("w25m512jv", 0xef7119, 0, 64 * 1024, 1024, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("w25h02jv", 0xef9022, 0, 64 * 1024, 4096, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("w25h512nw-am", 0xefa020, 0, 64 * 1024, 1024, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("w25h01nw-am", 0xefa021, 0, 64 * 1024, 2048, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("w25h02nw-am", 0xefa022, 0, 64 * 1024, 4096, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("w25q01nw-iq", 0xef6021, 0, 64 * 1024, 2048, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("w25q01nw-im", 0xef8021, 0, 64 * 1024, 2048, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("w25q02nw-im", 0xef8022, 0, 64 * 1024, 4096, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("w77q51nw", 0xef8a1a, 0, 64 * 1024, 1024, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+};
+
+const struct spi_nor_manufacturer spi_nor_winbond = {
+	.parts = winbond_nor_parts,
+	.nparts = ARRAY_SIZE(winbond_nor_parts),
+};
diff --git a/drivers/mtd/spi/xmc.c b/drivers/mtd/spi/xmc.c
new file mode 100644
index 00000000000..927fc42a0f3
--- /dev/null
+++ b/drivers/mtd/spi/xmc.c
@@ -0,0 +1,26 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Copyright (C) 2013 Jagannadha Sutradharudu Teki, Xilinx Inc.
+ * Copyright (C) 2016 Jagan Teki <jagan@openedev.com>
+ * Copyright (C) 2018 Texas Instruments Incorporated - https://www.ti.com/
+ */
+
+#include <linux/mtd/spi-nor.h>
+#include "sf_internal.h"
+
+static const struct flash_info xmc_nor_parts[] = {
+	{ INFO("XM25QH64A", 0x207017, 0, 64 * 1024, 128, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("XM25QH64C", 0x204017, 0, 64 * 1024, 128, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("XM25QH128A", 0x207018, 0, 64 * 1024, 256, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("XM25QU128C", 0x204118, 0, 64 * 1024, 256, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("XM25QH256C", 0x204019, 0, 64 * 1024, 512, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("XM25QU256C", 0x204119, 0, 64 * 1024, 512, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("XM25QH512C", 0x204020, 0, 64 * 1024, 1024, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("XM25QU512C", 0x204120, 0, 64 * 1024, 1024, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("XM25QH01D", 0x204021, 0, 64 * 1024, 2048, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+};
+
+const struct spi_nor_manufacturer spi_nor_xmc = {
+	.parts = xmc_nor_parts,
+	.nparts = ARRAY_SIZE(xmc_nor_parts),
+};
diff --git a/drivers/mtd/spi/xtx.c b/drivers/mtd/spi/xtx.c
new file mode 100644
index 00000000000..e49b1ceb76d
--- /dev/null
+++ b/drivers/mtd/spi/xtx.c
@@ -0,0 +1,54 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Copyright (C) 2013 Jagannadha Sutradharudu Teki, Xilinx Inc.
+ * Copyright (C) 2016 Jagan Teki <jagan@openedev.com>
+ * Copyright (C) 2018 Texas Instruments Incorporated - https://www.ti.com/
+ */
+
+#include <linux/mtd/spi-nor.h>
+#include "sf_internal.h"
+
+static const struct flash_info xtx_nor_parts[] = {
+	/* adding these 3V QSPI flash parts */
+	{ INFO("xt25f08", 0x0b4014, 0, 64 * 1024, 16,
+	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("xt25f16", 0x0b4015, 0, 64 * 1024, 32,
+	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("xt25f32", 0x0b4016, 0, 64 * 1024, 64,
+	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("xt25f64", 0x0b4017, 0, 64 * 1024, 128,
+	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("xt25f128", 0x0b4018, 0, 64 * 1024, 256,
+	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("xt25f256", 0x0b4019, 0, 64 * 1024, 512,
+	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+	/* adding these 1.8V QSPI flash parts */
+	{ INFO("xt25q08", 0x0b6014, 0, 64 * 1024, 16,
+	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("xt25q16", 0x0b6015, 0, 64 * 1024, 32,
+	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("xt25q32", 0x0b6016, 0, 64 * 1024, 64,
+	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("xt25q64", 0x0b6017, 0, 64 * 1024, 128,
+	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("xt25q128", 0x0b6018, 0, 64 * 1024, 256,
+	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+	{ INFO("xt25q256", 0x0b6019, 0, 64 * 1024, 512,
+	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("xt25q512", 0x0b601A, 0, 64 * 1024, 1024,
+	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("xt25q01g", 0x0b601B, 0, 64 * 1024, 2048,
+	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("xt55q02g", 0x0b601C, 0, 64 * 1024, 4096,
+	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+	/* adding these wide voltage QSPI flash parts */
+	{ INFO("xt25w512", 0x0b651A, 0, 64 * 1024, 1024,
+	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+	{ INFO("xt25w01g", 0x0b651B, 0, 64 * 1024, 2048,
+	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
+};
+
+const struct spi_nor_manufacturer spi_nor_xtx = {
+	.parts = xtx_nor_parts,
+	.nparts = ARRAY_SIZE(xtx_nor_parts),
+};
diff --git a/drivers/mtd/spi/zbit.c b/drivers/mtd/spi/zbit.c
new file mode 100644
index 00000000000..ee709b2bef1
--- /dev/null
+++ b/drivers/mtd/spi/zbit.c
@@ -0,0 +1,19 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Copyright (C) 2013 Jagannadha Sutradharudu Teki, Xilinx Inc.
+ * Copyright (C) 2016 Jagan Teki <jagan@openedev.com>
+ * Copyright (C) 2018 Texas Instruments Incorporated - https://www.ti.com/
+ */
+
+#include <linux/mtd/spi-nor.h>
+#include "sf_internal.h"
+
+static const struct flash_info zbit_nor_parts[] = {
+	{ INFO("zb25vq128", 0x5e4018, 0, 64 * 1024, 256,
+	       SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ) },
+};
+
+const struct spi_nor_manufacturer spi_nor_zbit = {
+	.parts = zbit_nor_parts,
+	.nparts = ARRAY_SIZE(zbit_nor_parts),
+};

-- 
2.43.0

