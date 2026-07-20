From: Mateusz Litwin <mateusz.litwin@nokia.com>
Date: Mon, 20 Jul 2026 17:12:39 +0200
Subject: [PATCH RFC 2/3] mtd: spi-nor: add dedicated multi-size uniform
 erase path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-spi_nor_multisize_erase-v1-2-38d719bfe77b@nokia.com>
References: <20260720-spi_nor_multisize_erase-v1-0-38d719bfe77b@nokia.com>
In-Reply-To: <20260720-spi_nor_multisize_erase-v1-0-38d719bfe77b@nokia.com>
To: Pratyush Yadav <pratyush@kernel.org>, Michael Walle <mwalle@kernel.org>, 
 Takahiro Kuwano <takahiro.kuwano@infineon.com>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>
Cc: linux-mtd@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Mateusz Litwin <mateusz.litwin@nokia.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784560422; l=10478;
 i=mateusz.litwin@nokia.com; s=20251217; h=from:subject:message-id;
 bh=3dVnZER5+S/Zzb3IHLlukQyLRWdKKcKIEqJEBQYJD5Y=;
 b=77IgsA9QMuajC3iBRPFvm+vxGOeGnjJCI7RzQ45v8l0ZJnZcBcLZzbzm55grYfQXK3Uyyh6gp
 zoi/a4EoTKcCBDwD/xHHXbpNICdSUQtwiQBaO+J+pvf9ow5CVbxfYpH
X-Developer-Key: i=mateusz.litwin@nokia.com; a=ed25519;
 pk=9NV76cwWrtwYUektOrK/ht9GTzmhtkqSvghr3Td4hM4=
X-Endpoint-Received: by B4 Relay for mateusz.litwin@nokia.com/20251217 with auth_id=579
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement a dedicated uniform erase path for flashes with multiple erase
sizes, instead of reusing the non-uniform erase path introduced in patch 1.

The non-uniform path allocates an erase command list and walks the region
tree on every request.  For uniform flashes that work is unnecessary.
The dedicated flow iterates the range directly and selects the erase type
per step, which lowers CPU and memory overhead.

Refactor the single-sector erase sequence into spi_nor_erase_one(),
shared with spi_nor_erase_multi_sectors().  Validate multi-size uniform
requests through spi_nor_is_uniform_erasable() before locking the device:
address and length must be aligned to the smallest supported uniform erase
size.  This allows erase requests smaller than mtd->erasesize (e.g. a
32 KiB boot header region) while still using larger erase commands for
aligned bulk portions.

When CONFIG_MTD_SPI_NOR_MULTI_ERASE_SIZE is disabled, the legacy
single-size uniform behavior is unchanged: only the length is checked
against mtd->erasesize and address alignment is not validated.

Signed-off-by: Mateusz Litwin <mateusz.litwin@nokia.com>
---
 drivers/mtd/spi-nor/core.c | 208 ++++++++++++++++++++++++++++++---------------
 1 file changed, 141 insertions(+), 67 deletions(-)

diff --git a/drivers/mtd/spi-nor/core.c b/drivers/mtd/spi-nor/core.c
index 80c5a7940fae..4e13919d238a 100644
--- a/drivers/mtd/spi-nor/core.c
+++ b/drivers/mtd/spi-nor/core.c
@@ -7,7 +7,6 @@
  * Copyright (C) 2014, Freescale Semiconductor, Inc.
  */
 
-#include <linux/bitops.h>
 #include <linux/cleanup.h>
 #include <linux/delay.h>
 #include <linux/device.h>
@@ -1226,11 +1225,6 @@ static bool spi_nor_has_uniform_erase(const struct spi_nor *nor)
 	return !!nor->params->erase_map.uniform_region.erase_mask;
 }
 
-static bool spi_nor_has_multiple_uniform_erase_sizes(const struct spi_nor *nor)
-{
-	return hweight8(nor->params->erase_map.uniform_region.erase_mask) > 1;
-}
-
 static void spi_nor_set_4byte_opcodes(struct spi_nor *nor)
 {
 	struct spi_nor_erase_map *map = &nor->params->erase_map;
@@ -1243,13 +1237,9 @@ static void spi_nor_set_4byte_opcodes(struct spi_nor *nor)
 
 	/*
 	 * Convert the opcode of every erase type, including for uniform
-	 * flashes. For a uniform flash driven with a single erase type
-	 * the converted erase_type opcode matches the nor->erase_opcode
-	 * converted just above (spi_nor_select_erase() copied it from the same
-	 * erase type), so >16 MiB uniform flashes keep erasing correctly.
-	 * The erase map is always initialized, so we can safely convert all
-	 * erase types, to keep the erase map in a consistent state to flash
-	 * mode.
+	 * flashes. The erase map is always initialized, so we can safely
+	 * convert all erase types, even if they are not used, to keep the
+	 * erase map in a consistent state with address mode.
 	 */
 	for (i = 0; i < SNOR_ERASE_TYPE_MAX; i++) {
 		erase = &map->erase_type[i];
@@ -1550,6 +1540,35 @@ int spi_nor_erase_sector(struct spi_nor *nor, u32 addr)
 						nor->bouncebuf, nor->addr_nbytes);
 }
 
+/**
+ * spi_nor_erase_one() - erase a single sector at the given address
+ * @nor:	pointer to a 'struct spi_nor'
+ * @addr:	offset in the serial flash memory
+ *
+ * Return: 0 on success, -errno otherwise.
+ */
+static int spi_nor_erase_one(struct spi_nor *nor, u32 addr)
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
@@ -1566,6 +1585,47 @@ static u64 spi_nor_div_by_erase_size(const struct spi_nor_erase_type *erase,
 	return dividend >> erase->size_shift;
 }
 
+/**
+ * spi_nor_is_uniform_erasable() - check if a uniform erase request is valid
+ * @nor:	pointer to a 'struct spi_nor'
+ * @instr:	pointer to 'struct erase_info'
+ *
+ * When multiple erase sizes are enabled on a uniform flash, verify that the
+ * requested address and length are aligned to the smallest supported erase
+ * size in the uniform region.
+ *
+ * Return: true if the range can be erased, false otherwise.
+ */
+static bool spi_nor_is_uniform_erasable(const struct spi_nor *nor,
+					struct erase_info *instr)
+{
+	const struct spi_nor_erase_map *map = &nor->params->erase_map;
+	u8 erase_mask = map->uniform_region.erase_mask;
+	const struct spi_nor_erase_type *erase = NULL;
+	int i;
+	u32 rem;
+
+	for (i = 0; i < SNOR_ERASE_TYPE_MAX; i++) {
+		if (erase_mask & BIT(i) && map->erase_type[i].size) {
+			erase = &map->erase_type[i];
+			break;
+		}
+	}
+
+	if (unlikely(!erase))
+		return false;
+
+	spi_nor_div_by_erase_size(erase, instr->addr, &rem);
+	if (rem)
+		return false;
+
+	div_u64_rem(instr->len, erase->size, &rem);
+	if (rem)
+		return false;
+
+	return true;
+}
+
 /**
  * spi_nor_find_best_erase_type() - find the best erase type for the given
  *				    offset in the serial flash memory and the
@@ -1617,6 +1677,49 @@ spi_nor_find_best_erase_type(const struct spi_nor_erase_map *map,
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
+	/*
+	 * When CONFIG_MTD_SPI_NOR_MULTI_ERASE_SIZE is disabled, erase_size is
+	 * mtd->erasesize and nor->erase_opcode was set once at init by
+	 * spi_nor_select_erase().
+	 */
+	u32 erase_size = nor->mtd.erasesize;
+
+	while (len) {
+		if (IS_ENABLED(CONFIG_MTD_SPI_NOR_MULTI_ERASE_SIZE)) {
+			erase = spi_nor_find_best_erase_type(map, region, addr,
+							     len);
+			if (unlikely(!erase))
+				return -EINVAL;
+
+			nor->erase_opcode = erase->opcode;
+			erase_size = erase->size;
+		}
+
+		ret = spi_nor_erase_one(nor, addr);
+		if (ret)
+			return ret;
+
+		addr += erase_size;
+		len -= erase_size;
+	}
+
+	return 0;
+}
+
 /**
  * spi_nor_init_erase_cmd() - initialize an erase command
  * @region:	pointer to a structure that describes a SPI NOR erase region
@@ -1749,22 +1852,7 @@ static int spi_nor_erase_multi_sectors(struct spi_nor *nor, u64 addr, u32 len)
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
 
@@ -1843,11 +1931,20 @@ static int spi_nor_erase(struct mtd_info *mtd, struct erase_info *instr)
 	dev_dbg(nor->dev, "at 0x%llx, len %lld\n", (long long)instr->addr,
 			(long long)instr->len);
 
-	if (spi_nor_has_uniform_erase(nor) &&
-	    !spi_nor_has_multiple_uniform_erase_sizes(nor)) {
-		div_u64_rem(instr->len, mtd->erasesize, &rem);
-		if (rem)
-			return -EINVAL;
+	if (spi_nor_has_uniform_erase(nor)) {
+		if (IS_ENABLED(CONFIG_MTD_SPI_NOR_MULTI_ERASE_SIZE)) {
+			if (!spi_nor_is_uniform_erasable(nor, instr))
+				return -EINVAL;
+		} else {
+			/*
+			 * Legacy uniform validation: only the length must be
+			 * a multiple of mtd->erasesize. Address alignment is
+			 * not checked here for backward compatibility.
+			 */
+			div_u64_rem(instr->len, mtd->erasesize, &rem);
+			if (rem)
+				return -EINVAL;
+		}
 	}
 
 	addr = instr->addr;
@@ -1877,34 +1974,12 @@ static int spi_nor_erase(struct mtd_info *mtd, struct erase_info *instr)
 	 * to use "small sector erase", but that's not always optimal.
 	 */
 
-	/* "sector"-at-a-time erase */
-	} else if (spi_nor_has_uniform_erase(nor) &&
-		   !spi_nor_has_multiple_uniform_erase_sizes(nor)) {
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
+	} else if (spi_nor_has_uniform_erase(nor)) {
+		ret = spi_nor_erase_uniform(nor, addr, len);
+		if (ret)
+			goto erase_err;
 
-	/* erase multiple sectors */
+	/* erase multiple sectors on non-uniform flashes */
 	} else {
 		ret = spi_nor_erase_multi_sectors(nor, addr, len);
 		if (ret)
@@ -2739,12 +2814,11 @@ static int spi_nor_select_erase(struct spi_nor *nor)
 	 * So to be backward compatible, the new implementation also tries to
 	 * manage the SPI flash memory as uniform with a single erase sector
 	 * size, when possible.
-	 * Exception is when CONFIG_MTD_SPI_NOR_MULTI_ERASE_SIZE is enabled.
-	 * We use multiple erase sizes for the SPI flash memory, but we still
-	 * need to select one of the supported erase sizes to set
-	 * mtd->erasesize. The selected erase size will be exposed as the
-	 * uniform erase size but all other erase sizes are still available
-	 * for use.
+	 *
+	 * When CONFIG_MTD_SPI_NOR_MULTI_ERASE_SIZE is enabled, multiple erase
+	 * sizes are used internally, but mtd->erasesize still reflects the
+	 * selected uniform erase size exposed to userspace. The other erase
+	 * sizes remain available in the uniform region erase mask.
 	 */
 	if (spi_nor_has_uniform_erase(nor)) {
 		erase = spi_nor_select_uniform_erase(map);

-- 
2.43.0

