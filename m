From: Mateusz Litwin <mateusz.litwin@nokia.com>
Date: Mon, 20 Jul 2026 17:12:38 +0200
Subject: [PATCH RFC 1/3] mtd: spi-nor: allow multiple erase sizes on
 uniform flash
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260720-spi_nor_multisize_erase-v1-1-38d719bfe77b@nokia.com>
References: <20260720-spi_nor_multisize_erase-v1-0-38d719bfe77b@nokia.com>
In-Reply-To: <20260720-spi_nor_multisize_erase-v1-0-38d719bfe77b@nokia.com>
To: Pratyush Yadav <pratyush@kernel.org>, Michael Walle <mwalle@kernel.org>, 
 Takahiro Kuwano <takahiro.kuwano@infineon.com>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>
Cc: linux-mtd@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Mateusz Litwin <mateusz.litwin@nokia.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784560422; l=8038;
 i=mateusz.litwin@nokia.com; s=20251217; h=from:subject:message-id;
 bh=0dMbUh0MFcxU9fENYEnsMbteWVGEkbGRMmTcYB3mrzE=;
 b=AAeWi5EgBol80Toz675Takkpkffc16C3UKCYCaK8A8idh15AKWtYElqIFjc42LOvZ4Pp9GpN4
 +Jg4J3ohRhjAinzyDY42cTMsr+hqzsHIhxyeuvuxLu95IbcfALM7XXt
X-Developer-Key: i=mateusz.litwin@nokia.com; a=ed25519;
 pk=9NV76cwWrtwYUektOrK/ht9GTzmhtkqSvghr3Td4hM4=
X-Endpoint-Received: by B4 Relay for mateusz.litwin@nokia.com/20251217 with auth_id=579
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce MTD_SPI_NOR_MULTI_ERASE_SIZE, which allows an SPI NOR MTD device
to use multiple erase sizes on uniform flashes.  When enabled, the driver
keeps all supported erase types in the uniform region mask instead of
collapsing to a single size, and routes multi-size uniform erases through
spi_nor_erase_multi_sectors().

This is useful where write access is needed on a minor-aligned partition
(for example u-boot-env, RouterBoot soft_config, or a boot header
partition) while still benefiting from larger erase commands on bulk
regions, instead of forcing CONFIG_MTD_SPI_NOR_USE_4K_SECTORS for the
entire device.

Also convert all erase-type opcodes to their 4-byte-address variants on
uniform flashes, so multi-size erases work correctly on devices above
16 MiB.

When patch 2 is applied on top, the multi_sectors routing introduced here
is replaced by a dedicated spi_nor_erase_uniform() path.

Signed-off-by: Mateusz Litwin <mateusz.litwin@nokia.com>
---
 drivers/mtd/spi-nor/Kconfig | 25 +++++++++++++++++++
 drivers/mtd/spi-nor/core.c  | 60 ++++++++++++++++++++++++++++++++-------------
 2 files changed, 68 insertions(+), 17 deletions(-)

diff --git a/drivers/mtd/spi-nor/Kconfig b/drivers/mtd/spi-nor/Kconfig
index fd05a24d64a9..b2f97117a057 100644
--- a/drivers/mtd/spi-nor/Kconfig
+++ b/drivers/mtd/spi-nor/Kconfig
@@ -19,10 +19,35 @@ config MTD_SPI_NOR_USE_4K_SECTORS
 	  Changing a small part of the flash's contents is usually faster with
 	  small sectors. On the other hand erasing should be faster when using
 	  64 KiB block instead of 16 × 4 KiB sectors.
+	  If MTD_SPI_NOR_MULTI_ERASE_SIZE is also enabled, the flash erasesize
+	  is reported as 4096 B, but large erase requests may still use larger
+	  erase sizes internally to improve performance.
 
 	  Please note that some tools/drivers/filesystems may not work with
 	  4096 B erase size (e.g. UBIFS requires 15 KiB as a minimum).
 
+config MTD_SPI_NOR_MULTI_ERASE_SIZE
+	bool "Use multiple erase sizes on uniform flashes"
+	default n
+	help
+	  Uniform SPI NOR flashes (whose erase map spans the whole device) may
+	  still advertise several erase sizes, e.g. 4 KiB, 32 KiB and 64 KiB.
+	  By default the driver collapses such a flash to a single erase size
+	  and uses that one size for every erase request.
+
+	  Say Y here to let those flashes use multiple erase sizes for a single
+	  erase request, exactly like non-uniform flashes already do: larger
+	  blocks are used for the aligned bulk of the range, while smaller
+	  blocks are used for the unaligned head and tail. This improves erase
+	  performance when a smaller erasesize is exposed to userspace.
+
+	  This option interacts with MTD_SPI_NOR_USE_4K_SECTORS: when both are
+	  enabled, the 4096 B erase size is exposed through mtd->erasesize, but
+	  the driver still uses multiple erase sizes internally to improve
+	  performance.
+
+	  If unsure, say N.
+
 choice
 	prompt "Software write protection at boot"
 	default MTD_SPI_NOR_SWP_DISABLE_ON_VOLATILE
diff --git a/drivers/mtd/spi-nor/core.c b/drivers/mtd/spi-nor/core.c
index b25d1a870a22..80c5a7940fae 100644
--- a/drivers/mtd/spi-nor/core.c
+++ b/drivers/mtd/spi-nor/core.c
@@ -7,6 +7,7 @@
  * Copyright (C) 2014, Freescale Semiconductor, Inc.
  */
 
+#include <linux/bitops.h>
 #include <linux/cleanup.h>
 #include <linux/delay.h>
 #include <linux/device.h>
@@ -1225,22 +1226,34 @@ static bool spi_nor_has_uniform_erase(const struct spi_nor *nor)
 	return !!nor->params->erase_map.uniform_region.erase_mask;
 }
 
+static bool spi_nor_has_multiple_uniform_erase_sizes(const struct spi_nor *nor)
+{
+	return hweight8(nor->params->erase_map.uniform_region.erase_mask) > 1;
+}
+
 static void spi_nor_set_4byte_opcodes(struct spi_nor *nor)
 {
+	struct spi_nor_erase_map *map = &nor->params->erase_map;
+	struct spi_nor_erase_type *erase;
+	int i;
+
 	nor->read_opcode = spi_nor_convert_3to4_read(nor->read_opcode);
 	nor->program_opcode = spi_nor_convert_3to4_program(nor->program_opcode);
 	nor->erase_opcode = spi_nor_convert_3to4_erase(nor->erase_opcode);
 
-	if (!spi_nor_has_uniform_erase(nor)) {
-		struct spi_nor_erase_map *map = &nor->params->erase_map;
-		struct spi_nor_erase_type *erase;
-		int i;
-
-		for (i = 0; i < SNOR_ERASE_TYPE_MAX; i++) {
-			erase = &map->erase_type[i];
-			erase->opcode =
-				spi_nor_convert_3to4_erase(erase->opcode);
-		}
+	/*
+	 * Convert the opcode of every erase type, including for uniform
+	 * flashes. For a uniform flash driven with a single erase type
+	 * the converted erase_type opcode matches the nor->erase_opcode
+	 * converted just above (spi_nor_select_erase() copied it from the same
+	 * erase type), so >16 MiB uniform flashes keep erasing correctly.
+	 * The erase map is always initialized, so we can safely convert all
+	 * erase types, to keep the erase map in a consistent state to flash
+	 * mode.
+	 */
+	for (i = 0; i < SNOR_ERASE_TYPE_MAX; i++) {
+		erase = &map->erase_type[i];
+		erase->opcode = spi_nor_convert_3to4_erase(erase->opcode);
 	}
 }
 
@@ -1710,7 +1723,7 @@ static int spi_nor_init_erase_cmd_list(struct spi_nor *nor,
 }
 
 /**
- * spi_nor_erase_multi_sectors() - perform a non-uniform erase
+ * spi_nor_erase_multi_sectors() - perform a multi-size erase
  * @nor:	pointer to a 'struct spi_nor'
  * @addr:	offset in the serial flash memory
  * @len:	number of bytes to erase
@@ -1830,7 +1843,8 @@ static int spi_nor_erase(struct mtd_info *mtd, struct erase_info *instr)
 	dev_dbg(nor->dev, "at 0x%llx, len %lld\n", (long long)instr->addr,
 			(long long)instr->len);
 
-	if (spi_nor_has_uniform_erase(nor)) {
+	if (spi_nor_has_uniform_erase(nor) &&
+	    !spi_nor_has_multiple_uniform_erase_sizes(nor)) {
 		div_u64_rem(instr->len, mtd->erasesize, &rem);
 		if (rem)
 			return -EINVAL;
@@ -1864,7 +1878,8 @@ static int spi_nor_erase(struct mtd_info *mtd, struct erase_info *instr)
 	 */
 
 	/* "sector"-at-a-time erase */
-	} else if (spi_nor_has_uniform_erase(nor)) {
+	} else if (spi_nor_has_uniform_erase(nor) &&
+		   !spi_nor_has_multiple_uniform_erase_sizes(nor)) {
 		while (len) {
 			ret = spi_nor_lock_device(nor);
 			if (ret)
@@ -2652,8 +2667,9 @@ static int spi_nor_select_pp(struct spi_nor *nor,
  * spi_nor_select_uniform_erase() - select optimum uniform erase type
  * @map:		the erase map of the SPI NOR
  *
- * Once the optimum uniform sector erase command is found, disable all the
- * other.
+ * Select the optimum uniform sector erase type. When
+ * CONFIG_MTD_SPI_NOR_MULTI_ERASE_SIZE is disabled, disable all other erase
+ * types in the uniform region erase mask.
  *
  * Return: pointer to erase type on success, NULL otherwise.
  */
@@ -2700,8 +2716,12 @@ spi_nor_select_uniform_erase(struct spi_nor_erase_map *map)
 	if (!erase)
 		return NULL;
 
-	/* Disable all other Sector Erase commands. */
-	map->uniform_region.erase_mask = BIT(erase - map->erase_type);
+	/*
+	 * Disable all other Sector Erase commands only when
+	 * CONFIG_MTD_SPI_NOR_MULTI_ERASE_SIZE is disabled.
+	 */
+	if (!IS_ENABLED(CONFIG_MTD_SPI_NOR_MULTI_ERASE_SIZE))
+		map->uniform_region.erase_mask = BIT(erase - map->erase_type);
 	return erase;
 }
 
@@ -2719,6 +2739,12 @@ static int spi_nor_select_erase(struct spi_nor *nor)
 	 * So to be backward compatible, the new implementation also tries to
 	 * manage the SPI flash memory as uniform with a single erase sector
 	 * size, when possible.
+	 * Exception is when CONFIG_MTD_SPI_NOR_MULTI_ERASE_SIZE is enabled.
+	 * We use multiple erase sizes for the SPI flash memory, but we still
+	 * need to select one of the supported erase sizes to set
+	 * mtd->erasesize. The selected erase size will be exposed as the
+	 * uniform erase size but all other erase sizes are still available
+	 * for use.
 	 */
 	if (spi_nor_has_uniform_erase(nor)) {
 		erase = spi_nor_select_uniform_erase(map);

-- 
2.43.0

