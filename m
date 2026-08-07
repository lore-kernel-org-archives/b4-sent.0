From: Mateusz Litwin <mateusz.litwin@nokia.com>
Date: Fri, 07 Aug 2026 08:06:45 +0200
Subject: [PATCH v2] mtd: spi-nor: allow multiple erase sizes on uniform
 flash
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260807-spi_nor_multisize_erase-v2-1-5a0a61471d3b@nokia.com>
X-B4-Tracking: v=1; b=H4sIAPR1dWoC/4WNQQ6CMBREr0L+2ppSK1VW3sMQUtpf+VFa0iJRC
 Xe3cgGXbzLzZoGEkTBBXSwQcaZEwWcQuwJMr/0NGdnMILiouBKcpZFaH2I7PB9Tbn+wxagTMlt
 JaZyV+ug6yOsxoqPXZr42mXtKU4jv7Wguf+l/51wyzg4nq8pz51Cp7uLDnfTehAGadV2/SagJs
 74AAAA=
X-Change-ID: 20260720-spi_nor_multisize_erase-d644cfd4a5fb
To: Pratyush Yadav <pratyush@kernel.org>, Michael Walle <mwalle@kernel.org>, 
 Takahiro Kuwano <takahiro.kuwano@infineon.com>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>
Cc: linux-mtd@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Mateusz Litwin <mateusz.litwin@nokia.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786082872; l=16761;
 i=mateusz.litwin@nokia.com; s=20251217; h=from:subject:message-id;
 bh=dwB2QzbJ5PRzOohrMc4pgQM6/iEGEpvMBsQUHYX7TPI=;
 b=tRo7LF9+yc5I+WuqhvqtDC2/YF9kIVVBvn/e/aQmwffoWkSW80hA7+sObEHBkVX+1MOfcjib2
 Q9opO0Wis9DCG9pzuXIK/rR/Ki1SL4h47ulzf0L8NtaqbTjQE/lNDJl
X-Developer-Key: i=mateusz.litwin@nokia.com; a=ed25519;
 pk=9NV76cwWrtwYUektOrK/ht9GTzmhtkqSvghr3Td4hM4=
X-Endpoint-Received: by B4 Relay for mateusz.litwin@nokia.com/20251217 with auth_id=579
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allow an SPI NOR MTD device to use multiple erase sizes on uniform flashes.
The driver keeps all supported erase types in the uniform region mask
instead of collapsing to a single size.

When the largest erase size is exposed through mtd->erasesize, this
allows minor-aligned partitions (for example u-boot-env, RouterBoot
soft_config, or a boot header partition) while still exposing large
erase size to upper layers. Erase requests are validated against the
smallest supported uniform erase size, so callers may issue erases
smaller than mtd->erasesize.

When CONFIG_MTD_SPI_NOR_USE_4K_SECTORS is enabled, mtd->erasesize is
still reported as 4096 B to tools and upper layers, but bulk erase
requests now use larger erase commands internally instead of always
erasing 4 KiB sectors to improve bulk region erase performance.

Refactor the single-sector erase sequence into spi_nor_erase_one(),
shared with spi_nor_erase_multi_sectors().  Validate multi-size uniform
requests through spi_nor_is_uniform_erasable() before locking the device:
address and length must be aligned to the smallest supported uniform erase
size.  This allows erase requests smaller than mtd->erasesize (e.g. a
32 KiB boot header region) while still using larger erase commands for
aligned bulk portions.

Also convert all erase-type opcodes to their 4-byte-address variants on
uniform flashes, so multi-size erases work correctly on devices above
16 MiB.

Assisted-by: Cursor:Auto

Signed-off-by: Mateusz Litwin <mateusz.litwin@nokia.com>
---
Most SPI NOR flashes advertise several erase sizes (e.g. 4 KiB, 32 KiB and
64 KiB) even when the erase map is uniform across the whole device.  The
spi-nor driver currently collapses such flashes to a single erase size and
uses only that size for every erase request.

This is a problem on platforms that need a small erasesize for partition
alignment (for example u-boot-env, RouterBoot soft_config, or boot header
partitions) while still wanting fast bulk erases.  Today the usual
workaround is to enable MTD_SPI_NOR_USE_4K_SECTORS, which forces 4 KiB
erases for the entire device and hurts erase performance on large regions.

This patch allows an SPI NOR MTD device to use multiple erase sizes on
uniform flashes. The driver keeps the full erase map and picks the largest
suitable erase size for each step of an erase operation, similar to what
non-uniform flashes already do.  Userspace still sees a single
mtd->erasesize (4 KiB when MTD_SPI_NOR_USE_4K_SECTORS is enabled), but
large aligned portions of an erase request can use 32 KiB or 64 KiB erase
commands internally.

The patch also converts all erase-type opcodes to their 4-byte-address
variants on uniform flashes, so multi-size erases work correctly on devices
larger than 16 MiB.

The previous uniform erase path only required the length to be a multiple
of mtd->erasesize.  With this patch, spi_nor_is_uniform_erasable() instead
checks the address and length against the smallest supported uniform erase
size. Requests aligned to mtd->erasesize still pass (it is a multiple of
that size), while callers may now issue erases smaller than mtd->erasesize. 

This patch also rejects MEMERASE requests with misaligned addresses.
On uniform flashes, MEMERASE with a misaligned address but aligned length
previously returned success yet erased a different block (in W25Q128JV case
the controller implicitly aligned the address). Reject such requests with
-EINVAL instead of relying on that undefined behavior; please report any
regressions.

Tested: backported to a 6.6-based tree on Micron MT25QU02G with
MTD_SPI_NOR_USE_4K_SECTORS disabled (mtd->erasesize reports 64 KiB).
Test uses a lightly modified Remote System Update (RSU) stack for Agilex:
https://github.com/altera-fpga/intel-rsu. librsu erases the flash with
the MEMERASE ioctl on the MTD character device, issuing erase requests
smaller than mtd->erasesize (e.g. a 32 KiB boot header region).
Verified writes and erases on the 32 KiB region align with 64 KiB erase
size.

Tested also with latest kernel version 7.2 tree on Winbond W25Q128JV.
Erase of 0xfc0000 bytes with offset 0x0
Command: time sudo mtd_debug erase /dev/mtd0 0x0 0xfc0000

Without this patch:
MTD_SPI_NOR_USE_4K_SECTORS=n	|y
real    0m 59.640s		|3m 14.724s
user    0m 0.009s		|0m 0.005s
sys     0m 0.000s		|0m 0.004s
can write minor-aligned parts? N|Y

With this patch:
MTD_SPI_NOR_USE_4K_SECTORS=n	|y
real    0m 59.347s		|0m 59.621s
user    0m 0.004s		|0m 0.004s
sys     0m 0.008s		|0m 0.005s
can write minor-aligned parts? Y|Y

A few implementation details are worth discussing:

1. spansion_nor_late_init() overrides nor->erase_opcode (and mtd->erasesize)
   for flashes larger than 16 MiB.  With this patch,
   spi_nor_erase_uniform() sets nor->erase_opcode before each erase, so the
   late_init value is not used on the erase path.  If the SFDP table masks
   unsupported erase types in 4-byte-address mode, this is not an issue;
   otherwise late_init() or erase-type masking may need changes for
   Cypress/Spansion parts.

2. Some flashes do not support every erase type with 4-byte-address opcodes.
   Unsupported types are masked by clearing erase_type[].size, but the
   corresponding erase_mask bit is not cleared.  Erases work correctly, but
   debugfs can show a set bit in the sector-map erase mask for a type that is
   not listed under "erase commands".  Fixing that is probably best done in
   a separate patch.
---
Changes in v2:
- Drop MTD_SPI_NOR_MULTI_ERASE_SIZE kernel config adding.
- Drop skipping erase-type search in uniform bulk erase as it complicates
  the flow and gives little performance gain.
- Extract spi_nor_find_smallest_erase_type() helper for uniform erase
  validation.
- Clean up commit message and Kconfig help text.
- Added testing on the latest kernel. 
- Link to v1: https://lore.kernel.org/r/20260720-spi_nor_multisize_erase-v1-0-38d719bfe77b@nokia.com

To: Pratyush Yadav <pratyush@kernel.org>
To: Michael Walle <mwalle@kernel.org>
To: Takahiro Kuwano <takahiro.kuwano@infineon.com>
To: Miquel Raynal <miquel.raynal@bootlin.com>
To: Richard Weinberger <richard@nod.at>
To: Vignesh Raghavendra <vigneshr@ti.com>
Cc: linux-mtd@lists.infradead.org
Cc: linux-kernel@vger.kernel.org
---
 drivers/mtd/spi-nor/Kconfig |  13 ++-
 drivers/mtd/spi-nor/core.c  | 207 ++++++++++++++++++++++++++++----------------
 2 files changed, 144 insertions(+), 76 deletions(-)

diff --git a/drivers/mtd/spi-nor/Kconfig b/drivers/mtd/spi-nor/Kconfig
index fd05a24d64a9..4f83f9037d05 100644
--- a/drivers/mtd/spi-nor/Kconfig
+++ b/drivers/mtd/spi-nor/Kconfig
@@ -17,8 +17,17 @@ config MTD_SPI_NOR_USE_4K_SECTORS
 	  on the usage this feature may provide performance gain in comparison
 	  to erasing whole blocks (32/64 KiB).
 	  Changing a small part of the flash's contents is usually faster with
-	  small sectors. On the other hand erasing should be faster when using
-	  64 KiB block instead of 16 × 4 KiB sectors.
+	  small sectors.
+
+	  Say Y here to report 4096 B (if flash supports it) as mtd->erasesize
+	  to tools and upper layers.
+
+	  This is also useful when partition alignment or filesystem
+	  requirements call for a small erase size.
+
+	  Internally the driver still uses multiple erase sizes when performing
+	  erase operations, selecting the largest suitable size for each step
+	  to maintain erase performance on large regions.
 
 	  Please note that some tools/drivers/filesystems may not work with
 	  4096 B erase size (e.g. UBIFS requires 15 KiB as a minimum).
diff --git a/drivers/mtd/spi-nor/core.c b/drivers/mtd/spi-nor/core.c
index b25d1a870a22..ef88de0a5438 100644
--- a/drivers/mtd/spi-nor/core.c
+++ b/drivers/mtd/spi-nor/core.c
@@ -1227,20 +1227,17 @@ static bool spi_nor_has_uniform_erase(const struct spi_nor *nor)
 
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
+	for (i = 0; i < SNOR_ERASE_TYPE_MAX; i++) {
+		erase = &map->erase_type[i];
+		erase->opcode = spi_nor_convert_3to4_erase(erase->opcode);
 	}
 }
 
@@ -1537,6 +1534,35 @@ int spi_nor_erase_sector(struct spi_nor *nor, u32 addr)
 						nor->bouncebuf, nor->addr_nbytes);
 }
 
+/**
+ * spi_nor_erase_one() - erase a single sector at the given address
+ * @nor:	pointer to a 'struct spi_nor'
+ * @addr:	offset in the serial flash memory
+ *
+ * Return: 0 on success, -errno otherwise.
+ */
+static int spi_nor_erase_one(struct spi_nor *nor, u64 addr)
+{
+	int ret;
+
+	ret = spi_nor_lock_device(nor);
+	if (ret)
+		return ret;
+
+	ret = spi_nor_write_enable(nor);
+	if (ret) {
+		spi_nor_unlock_device(nor);
+		return ret;
+	}
+
+	ret = spi_nor_erase_sector(nor, addr);
+	spi_nor_unlock_device(nor);
+	if (ret)
+		return ret;
+
+	return spi_nor_wait_till_ready(nor);
+}
+
 /**
  * spi_nor_div_by_erase_size() - calculate remainder and update new dividend
  * @erase:	pointer to a structure that describes a SPI NOR erase type
@@ -1553,6 +1579,62 @@ static u64 spi_nor_div_by_erase_size(const struct spi_nor_erase_type *erase,
 	return dividend >> erase->size_shift;
 }
 
+/**
+ * spi_nor_find_smallest_erase_type() - find the smallest erase type in a mask
+ * @map:	the erase map of the SPI NOR
+ * @erase_mask:	bitmask of erase types to consider
+ *
+ * Erase types are ordered by size, with the smallest erase type at index 0.
+ *
+ * Return: pointer to the smallest active erase type, NULL otherwise.
+ */
+static const struct spi_nor_erase_type *
+spi_nor_find_smallest_erase_type(const struct spi_nor_erase_map *map,
+				 u8 erase_mask)
+{
+	int i;
+
+	for (i = 0; i < SNOR_ERASE_TYPE_MAX; i++) {
+		if (erase_mask & BIT(i) && map->erase_type[i].size)
+			return &map->erase_type[i];
+	}
+
+	return NULL;
+}
+
+/**
+ * spi_nor_is_uniform_erasable() - check if a uniform erase request is valid
+ * @nor:	pointer to a 'struct spi_nor'
+ * @instr:	pointer to 'struct erase_info'
+ *
+ * Verify that the requested address and length are aligned to the smallest
+ * supported erase size in the uniform region.
+ *
+ * Return: true if the range can be erased, false otherwise.
+ */
+static bool spi_nor_is_uniform_erasable(const struct spi_nor *nor,
+					struct erase_info *instr)
+{
+	const struct spi_nor_erase_map *map = &nor->params->erase_map;
+	const struct spi_nor_erase_type *erase;
+	u32 rem;
+
+	erase = spi_nor_find_smallest_erase_type(map,
+						 map->uniform_region.erase_mask);
+	if (unlikely(!erase))
+		return false;
+
+	spi_nor_div_by_erase_size(erase, instr->addr, &rem);
+	if (rem)
+		return false;
+
+	spi_nor_div_by_erase_size(erase, instr->len, &rem);
+	if (rem)
+		return false;
+
+	return true;
+}
+
 /**
  * spi_nor_find_best_erase_type() - find the best erase type for the given
  *				    offset in the serial flash memory and the
@@ -1604,6 +1686,39 @@ spi_nor_find_best_erase_type(const struct spi_nor_erase_map *map,
 	return NULL;
 }
 
+/**
+ * spi_nor_erase_uniform() - erase a range on a uniform flash
+ * @nor:	pointer to a 'struct spi_nor'
+ * @addr:	offset in the serial flash memory
+ * @len:	number of bytes to erase
+ *
+ * Return: 0 on success, -errno otherwise.
+ */
+static int spi_nor_erase_uniform(struct spi_nor *nor, u64 addr, u32 len)
+{
+	const struct spi_nor_erase_map *map = &nor->params->erase_map;
+	const struct spi_nor_erase_region *region = &map->uniform_region;
+	const struct spi_nor_erase_type *erase;
+	int ret;
+
+	while (len) {
+		erase = spi_nor_find_best_erase_type(map, region, addr, len);
+		if (unlikely(!erase))
+			return -EINVAL;
+
+		nor->erase_opcode = erase->opcode;
+
+		ret = spi_nor_erase_one(nor, addr);
+		if (ret)
+			return ret;
+
+		addr += erase->size;
+		len -= erase->size;
+	}
+
+	return 0;
+}
+
 /**
  * spi_nor_init_erase_cmd() - initialize an erase command
  * @region:	pointer to a structure that describes a SPI NOR erase region
@@ -1736,22 +1851,7 @@ static int spi_nor_erase_multi_sectors(struct spi_nor *nor, u64 addr, u32 len)
 			dev_vdbg(nor->dev, "erase_cmd->size = 0x%08x, erase_cmd->opcode = 0x%02x, erase_cmd->count = %u\n",
 				 cmd->size, cmd->opcode, cmd->count);
 
-			ret = spi_nor_lock_device(nor);
-			if (ret)
-				goto destroy_erase_cmd_list;
-
-			ret = spi_nor_write_enable(nor);
-			if (ret) {
-				spi_nor_unlock_device(nor);
-				goto destroy_erase_cmd_list;
-			}
-
-			ret = spi_nor_erase_sector(nor, addr);
-			spi_nor_unlock_device(nor);
-			if (ret)
-				goto destroy_erase_cmd_list;
-
-			ret = spi_nor_wait_till_ready(nor);
+			ret = spi_nor_erase_one(nor, addr);
 			if (ret)
 				goto destroy_erase_cmd_list;
 
@@ -1823,7 +1923,7 @@ static int spi_nor_erase(struct mtd_info *mtd, struct erase_info *instr)
 	struct spi_nor *nor = mtd_to_spi_nor(mtd);
 	u8 n_dice = nor->params->n_dice;
 	bool multi_die_erase = false;
-	u32 addr, len, rem;
+	u32 addr, len;
 	size_t die_size;
 	int ret;
 
@@ -1831,8 +1931,7 @@ static int spi_nor_erase(struct mtd_info *mtd, struct erase_info *instr)
 			(long long)instr->len);
 
 	if (spi_nor_has_uniform_erase(nor)) {
-		div_u64_rem(instr->len, mtd->erasesize, &rem);
-		if (rem)
+		if (!spi_nor_is_uniform_erasable(nor, instr))
 			return -EINVAL;
 	}
 
@@ -1858,38 +1957,12 @@ static int spi_nor_erase(struct mtd_info *mtd, struct erase_info *instr)
 		if (ret)
 			goto erase_err;
 
-	/* REVISIT in some cases we could speed up erasing large regions
-	 * by using SPINOR_OP_SE instead of SPINOR_OP_BE_4K.  We may have set up
-	 * to use "small sector erase", but that's not always optimal.
-	 */
-
-	/* "sector"-at-a-time erase */
 	} else if (spi_nor_has_uniform_erase(nor)) {
-		while (len) {
-			ret = spi_nor_lock_device(nor);
-			if (ret)
-				goto erase_err;
-
-			ret = spi_nor_write_enable(nor);
-			if (ret) {
-				spi_nor_unlock_device(nor);
-				goto erase_err;
-			}
-
-			ret = spi_nor_erase_sector(nor, addr);
-			spi_nor_unlock_device(nor);
-			if (ret)
-				goto erase_err;
-
-			ret = spi_nor_wait_till_ready(nor);
-			if (ret)
-				goto erase_err;
-
-			addr += mtd->erasesize;
-			len -= mtd->erasesize;
-		}
+		ret = spi_nor_erase_uniform(nor, addr, len);
+		if (ret)
+			goto erase_err;
 
-	/* erase multiple sectors */
+	/* erase multiple sectors on non-uniform flashes */
 	} else {
 		ret = spi_nor_erase_multi_sectors(nor, addr, len);
 		if (ret)
@@ -2652,8 +2725,7 @@ static int spi_nor_select_pp(struct spi_nor *nor,
  * spi_nor_select_uniform_erase() - select optimum uniform erase type
  * @map:		the erase map of the SPI NOR
  *
- * Once the optimum uniform sector erase command is found, disable all the
- * other.
+ * Select the optimum uniform sector erase type.
  *
  * Return: pointer to erase type on success, NULL otherwise.
  */
@@ -2697,11 +2769,6 @@ spi_nor_select_uniform_erase(struct spi_nor_erase_map *map)
 			/* keep iterating to find the wanted_size */
 	}
 
-	if (!erase)
-		return NULL;
-
-	/* Disable all other Sector Erase commands. */
-	map->uniform_region.erase_mask = BIT(erase - map->erase_type);
 	return erase;
 }
 
@@ -2712,14 +2779,6 @@ static int spi_nor_select_erase(struct spi_nor *nor)
 	struct mtd_info *mtd = &nor->mtd;
 	int i;
 
-	/*
-	 * The previous implementation handling Sector Erase commands assumed
-	 * that the SPI flash memory has an uniform layout then used only one
-	 * of the supported erase sizes for all Sector Erase commands.
-	 * So to be backward compatible, the new implementation also tries to
-	 * manage the SPI flash memory as uniform with a single erase sector
-	 * size, when possible.
-	 */
 	if (spi_nor_has_uniform_erase(nor)) {
 		erase = spi_nor_select_uniform_erase(map);
 		if (!erase)

---
base-commit: df415c5e1de0f1aeefacb4e6252ff98d38c04437
change-id: 20260720-spi_nor_multisize_erase-d644cfd4a5fb

Best regards,
--  
Mateusz Litwin <mateusz.litwin@nokia.com>

