From: Takahiro Kuwano <Takahiro.Kuwano@infineon.com>
Date: Wed, 19 Nov 2025 14:13:09 +0900
Subject: [PATCH 10/11] mtd: spi-nor: Revert stacked/parallel related
 commits
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251119-amd-cleanup-v1-10-c555bd85e6e4@infineon.com>
References: <20251119-amd-cleanup-v1-0-c555bd85e6e4@infineon.com>
In-Reply-To: <20251119-amd-cleanup-v1-0-c555bd85e6e4@infineon.com>
To: u-boot@lists.denx.de, Tudor Ambarus <tudor.ambarus@linaro.org>
Cc: Jagan Teki <jagan@amarulasolutions.com>, 
 Michal Simek <michal.simek@amd.com>, Tom Rini <trini@konsulko.com>, 
 Ibai Erkiaga <ibai.erkiaga-elorza@amd.com>, Vignesh R <vigneshr@ti.com>, 
 Prasad Kummari <prasad.kummari@amd.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Havish Mutya <havish.mutya@amd.com>, 
 Ashok Reddy Soma <ashok.reddy.soma@amd.com>, 
 Venkatesh Yadav Abbarapu <venkatesh.abbarapu@amd.com>, 
 Daassi Bacem <Bacem.Daassi@infineon.com>, 
 Shinsuke Okada <Shinsuke.Okada@infineon.com>, 
 Hiroyuki Saito <Hiroyuki.Saito2@infineon.com>, 
 Takahiro Kuwano <tkuw584924@gmail.com>, 
 Takahiro Kuwano <Takahiro.Kuwano@infineon.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763529253; l=21433;
 i=Takahiro.Kuwano@infineon.com; s=20250227; h=from:subject:message-id;
 bh=7naan25lk/VT7/hP97gZ+C7rlxarKCcRStWv83aua1c=;
 b=8GS+q6DC7o3usBpDYzDQEe9AFsa2MkNViYn60MTt8KjuRmFD6Kd4bS4oVoBAaZB5IeB39pzYU
 adKMg7or6+wDg9zEa1Ky2VbVs1lV5rl1cf6qX1jpNPrYM8jkbX6L4ML
X-Developer-Key: i=Takahiro.Kuwano@infineon.com; a=ed25519;
 pk=aS8V9WLuMUkl0vmgD0xJU19ZajdJmuyFBnBfVj0dfDs=
X-Endpoint-Received: by B4 Relay for Takahiro.Kuwano@infineon.com/20250227 with auth_id=566
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Revert the following commits to remove stacked/parallel mode support
from core. Exceptions are SPI_XFER_U_PAGE and nor->upage_prev that still
needed for stacked mode support.

f59cb6a6970 ("mtd: spi-nor: Remove recently added SST special case")
9bb02f7f453 ("mtd: spi-nor: Fix the spi_nor_read() when config SPI_STACKED_PARALLEL is enabled")
e61ea9f2e5d ("mtd: spi-nor: Guard SPI_STACKED_PARALLEL with DM_SPI check")
43423cdc5dc ("mtd: spi-nor: Always build SPI_STACKED_PARALLEL code")
003157bd1c2 ("mtd: spi-nor: Rewrite rem_bank_len calculation")
a21cfc4e7c5 ("mtd: spi-nor: Fix multiple coding style issues")
34cd4a72fb2 ("mtd: spi-nor: Remove recently added SST special case")
787692c8d75 ("mtd: spi-nor: Remove recently added write_disable() call")
8ef342f7cbb ("mtd: spi-nor: Remove recently added set_4byte() call")
b8807c8c406 ("mtd: spi-nor: Remove recently added spi_nor_wait_till_ready() call")
19e189b1de0 ("mtd: spi-nor: Remove recently added nor->addr_width == 3 test")
c480ec2c45b ("mtd: spi-nor: Add parallel and stacked memories support in read_bar and write_bar")
92e0ae42b47 ("mtd: spi-nor: Add parallel memories support for read_sr and read_fsr")
5d40b3d384d ("mtd: spi-nor: Add parallel and stacked memories support")

Signed-off-by: Takahiro Kuwano <Takahiro.Kuwano@infineon.com>
---
 drivers/mtd/spi/spi-nor-core.c | 392 ++++++-----------------------------------
 include/linux/mtd/spi-nor.h    |  10 --
 include/spi.h                  |   2 -
 3 files changed, 53 insertions(+), 351 deletions(-)

diff --git a/drivers/mtd/spi/spi-nor-core.c b/drivers/mtd/spi/spi-nor-core.c
index 9695a706d0b..acfbc0bb702 100644
--- a/drivers/mtd/spi/spi-nor-core.c
+++ b/drivers/mtd/spi/spi-nor-core.c
@@ -466,9 +466,8 @@ static ssize_t spi_nor_write_data(struct spi_nor *nor, loff_t to, size_t len,
 }
 
 /*
- * Return the status register value. If the chip is parallel, then the
- * read will be striped, so we should read 2 bytes to get the sr
- * register value from both of the parallel chips.
+ * Read the status register, returning its value in the location
+ * Return the status register value.
  * Returns negative if error occurred.
  */
 static int read_sr(struct spi_nor *nor)
@@ -500,29 +499,18 @@ static int read_sr(struct spi_nor *nor)
 	if (spi_nor_protocol_is_dtr(nor->reg_proto))
 		op.data.nbytes = 2;
 
-	if (nor->flags & SNOR_F_HAS_PARALLEL) {
-		op.data.nbytes = 2;
-		ret = spi_nor_read_write_reg(nor, &op, &val[0]);
-		if (ret < 0) {
-			pr_debug("error %d reading SR\n", (int)ret);
-			return ret;
-		}
-		val[0] |= val[1];
-	} else {
-		ret = spi_nor_read_write_reg(nor, &op, &val[0]);
-		if (ret < 0) {
-			pr_debug("error %d reading SR\n", (int)ret);
-			return ret;
-		}
+	ret = spi_nor_read_write_reg(nor, &op, val);
+	if (ret < 0) {
+		pr_debug("error %d reading SR\n", (int)ret);
+		return ret;
 	}
 
-	return val[0];
+	return *val;
 }
 
 /*
- * Return the flag status register value. If the chip is parallel, then
- * the read will be striped, so we should read 2 bytes to get the fsr
- * register value from both of the parallel chips.
+ * Read the flag status register, returning its value in the location
+ * Return the status register value.
  * Returns negative if error occurred.
  */
 static int read_fsr(struct spi_nor *nor)
@@ -554,23 +542,13 @@ static int read_fsr(struct spi_nor *nor)
 	if (spi_nor_protocol_is_dtr(nor->reg_proto))
 		op.data.nbytes = 2;
 
-	if (nor->flags & SNOR_F_HAS_PARALLEL) {
-		op.data.nbytes = 2;
-		ret = spi_nor_read_write_reg(nor, &op, &val[0]);
-		if (ret < 0) {
-			pr_debug("error %d reading SR\n", (int)ret);
-			return ret;
-		}
-		val[0] &= val[1];
-	} else {
-		ret = spi_nor_read_write_reg(nor, &op, &val[0]);
-		if (ret < 0) {
-			pr_debug("error %d reading FSR\n", ret);
-			return ret;
-		}
+	ret = spi_nor_read_write_reg(nor, &op, val);
+	if (ret < 0) {
+		pr_debug("error %d reading FSR\n", ret);
+		return ret;
 	}
 
-	return val[0];
+	return *val;
 }
 
 /*
@@ -718,17 +696,12 @@ static u8 spi_nor_convert_3to4_erase(u8 opcode)
 static void spi_nor_set_4byte_opcodes(struct spi_nor *nor,
 				      const struct flash_info *info)
 {
-	bool shift = 0;
-
-	if (nor->flags & SNOR_F_HAS_PARALLEL)
-		shift = 1;
-
 	/* Do some manufacturer fixups first */
 	switch (JEDEC_MFR(info)) {
 	case SNOR_MFR_SPANSION:
 		/* No small sector erase for 4-byte command set */
 		nor->erase_opcode = SPINOR_OP_SE;
-		nor->mtd.erasesize = info->sector_size << shift;
+		nor->mtd.erasesize = info->sector_size;
 		break;
 
 	default:
@@ -961,32 +934,12 @@ int clean_bar(struct spi_nor *nor)
 
 static int write_bar(struct spi_nor *nor, u32 offset)
 {
-	u8 cmd, bank_sel, upage_curr;
+	u8 cmd, bank_sel;
 	int ret;
-	struct mtd_info *mtd = &nor->mtd;
-
-	/* Wait until previous write command is finished */
-	if (spi_nor_wait_till_ready(nor))
-		return 1;
-
-	if (nor->flags & (SNOR_F_HAS_PARALLEL | SNOR_F_HAS_STACKED) &&
-	    mtd->size <= SZ_32M)
-		return 0;
 
-	if (mtd->size <= SZ_16M)
-		return 0;
-
-	offset = offset % (u32)mtd->size;
-	bank_sel = offset >> 24;
-
-	upage_curr = nor->spi->flags & SPI_XFER_U_PAGE;
-
-	if (!(nor->flags & SNOR_F_HAS_STACKED) && bank_sel == nor->bank_curr)
-		return 0;
-	else if (upage_curr == nor->upage_prev && bank_sel == nor->bank_curr)
-		return 0;
-
-	nor->upage_prev = upage_curr;
+	bank_sel = offset / SZ_16M;
+	if (bank_sel == nor->bank_curr)
+		goto bar_end;
 
 	cmd = nor->bank_write_cmd;
 	write_enable(nor);
@@ -996,19 +949,15 @@ static int write_bar(struct spi_nor *nor, u32 offset)
 		return ret;
 	}
 
+bar_end:
 	nor->bank_curr = bank_sel;
-
-	return write_disable(nor);
+	return nor->bank_curr;
 }
 
 static int read_bar(struct spi_nor *nor, const struct flash_info *info)
 {
 	u8 curr_bank = 0;
 	int ret;
-	struct mtd_info *mtd = &nor->mtd;
-
-	if (mtd->size <= SZ_16M)
-		return 0;
 
 	switch (JEDEC_MFR(info)) {
 	case SNOR_MFR_SPANSION:
@@ -1020,30 +969,15 @@ static int read_bar(struct spi_nor *nor, const struct flash_info *info)
 		nor->bank_write_cmd = SPINOR_OP_WREAR;
 	}
 
-	if (nor->flags & SNOR_F_HAS_PARALLEL)
-		nor->spi->flags |= SPI_XFER_LOWER;
-
 	ret = nor->read_reg(nor, nor->bank_read_cmd,
-			    &curr_bank, 1);
+				    &curr_bank, 1);
 	if (ret) {
 		debug("SF: fail to read bank addr register\n");
 		return ret;
 	}
 	nor->bank_curr = curr_bank;
 
-	// Make sure both chips use the same BAR
-	if (nor->flags & SNOR_F_HAS_PARALLEL) {
-		write_enable(nor);
-		ret = nor->write_reg(nor, nor->bank_write_cmd, &curr_bank, 1);
-		if (ret)
-			return ret;
-
-		ret = write_disable(nor);
-		if (ret)
-			return ret;
-	}
-
-	return ret;
+	return 0;
 }
 #endif
 
@@ -1107,8 +1041,8 @@ int spi_nor_erase_sector(struct spi_nor *nor, u32 addr)
 static int spi_nor_erase(struct mtd_info *mtd, struct erase_info *instr)
 {
 	struct spi_nor *nor = mtd_to_spi_nor(mtd);
-	u32 addr, len, rem, offset, max_size;
 	bool addr_known = false;
+	u32 addr, len, rem, max_size;
 	int ret, err;
 
 	dev_dbg(nor->dev, "at 0x%llx, len %lld\n", (long long)instr->addr,
@@ -1134,20 +1068,8 @@ static int spi_nor_erase(struct mtd_info *mtd, struct erase_info *instr)
 			ret = -EINTR;
 			goto erase_err;
 		}
-		offset = addr;
-		if (CONFIG_IS_ENABLED(SPI_STACKED_PARALLEL)) {
-			if (nor->flags & SNOR_F_HAS_PARALLEL)
-				offset /= 2;
-
-			if (nor->flags & SNOR_F_HAS_STACKED) {
-				if (offset >= (mtd->size / 2))
-					nor->spi->flags |= SPI_XFER_U_PAGE;
-				else
-					nor->spi->flags &= ~SPI_XFER_U_PAGE;
-			}
-		}
 #if CONFIG_IS_ENABLED(SPI_FLASH_BAR)
-		ret = write_bar(nor, offset);
+		ret = write_bar(nor, addr);
 		if (ret < 0)
 			goto erase_err;
 #endif
@@ -1159,7 +1081,7 @@ static int spi_nor_erase(struct mtd_info *mtd, struct erase_info *instr)
 		    !(nor->flags & SNOR_F_NO_OP_CHIP_ERASE)) {
 			ret = spi_nor_erase_chip(nor);
 		} else {
-			ret = spi_nor_erase_sector(nor, offset);
+			ret = spi_nor_erase_sector(nor, addr);
 		}
 		if (ret < 0)
 			goto erase_err;
@@ -1561,9 +1483,6 @@ static const struct flash_info *spi_nor_read_id(struct spi_nor *nor)
 	u8			id[SPI_NOR_MAX_ID_LEN];
 	const struct flash_info	*info;
 
-	if (nor->flags & SNOR_F_HAS_PARALLEL)
-		nor->spi->flags |= SPI_XFER_LOWER;
-
 	tmp = nor->read_reg(nor, SPINOR_OP_RDID, id, SPI_NOR_MAX_ID_LEN);
 	if (tmp < 0) {
 		dev_dbg(nor->dev, "error %d reading JEDEC ID\n", tmp);
@@ -1587,72 +1506,29 @@ static int spi_nor_read(struct mtd_info *mtd, loff_t from, size_t len,
 			size_t *retlen, u_char *buf)
 {
 	struct spi_nor *nor = mtd_to_spi_nor(mtd);
-	loff_t offset = from;
-	u32 rem_bank_len = 0;
-	u32 stack_shift = 0;
-	size_t read_len;
-	u8 bank;
 	int ret;
-	bool is_ofst_odd = false;
 
 	dev_dbg(nor->dev, "from 0x%08x, len %zd\n", (u32)from, len);
 
-	if ((nor->flags & SNOR_F_HAS_PARALLEL) && (offset & 1)) {
-		/* We can hit this case when we use file system like ubifs */
-		from--;
-		len++;
-		is_ofst_odd = true;
-	}
-
 	while (len) {
-		read_len = len;
-		offset = from;
-
-		if (CONFIG_IS_ENABLED(SPI_FLASH_BAR)) {
-			bank = (u32)from / SZ_16M;
-			if (CONFIG_IS_ENABLED(SPI_STACKED_PARALLEL)) {
-				if (nor->flags & SNOR_F_HAS_PARALLEL)
-					bank /= 2;
-			}
-			rem_bank_len = SZ_16M * (bank + 1);
-			if (CONFIG_IS_ENABLED(SPI_STACKED_PARALLEL)) {
-				if (nor->flags & SNOR_F_HAS_PARALLEL)
-					rem_bank_len *= 2;
-			}
-			rem_bank_len -= from;
-		}
-
-		if (CONFIG_IS_ENABLED(SPI_STACKED_PARALLEL)) {
-			if (nor->flags & SNOR_F_HAS_STACKED) {
-				stack_shift = 1;
-				if (offset >= (mtd->size / 2)) {
-					offset = offset - (mtd->size / 2);
-					nor->spi->flags |= SPI_XFER_U_PAGE;
-				} else {
-					nor->spi->flags &= ~SPI_XFER_U_PAGE;
-				}
-			}
-		}
-
-		if (CONFIG_IS_ENABLED(SPI_STACKED_PARALLEL)) {
-			if (nor->flags & SNOR_F_HAS_PARALLEL)
-				offset /= 2;
-		}
+		loff_t addr = from;
+		size_t read_len = len;
 
 #if CONFIG_IS_ENABLED(SPI_FLASH_BAR)
-		ret = write_bar(nor, offset);
+		u32 remain_len;
+
+		ret = write_bar(nor, addr);
 		if (ret < 0)
 			return log_ret(ret);
-		if (len < rem_bank_len)
+		remain_len = (SZ_16M * (nor->bank_curr + 1)) - addr;
+
+		if (len < remain_len)
 			read_len = len;
 		else
-			read_len = rem_bank_len;
+			read_len = remain_len;
 #endif
 
-		if (read_len == 0)
-			return -EIO;
-
-		ret = nor->read(nor, offset, read_len, buf);
+		ret = nor->read(nor, addr, read_len, buf);
 		if (ret == 0) {
 			/* We shouldn't see 0-length reads */
 			ret = -EIO;
@@ -1661,15 +1537,8 @@ static int spi_nor_read(struct mtd_info *mtd, loff_t from, size_t len,
 		if (ret < 0)
 			goto read_err;
 
-		if (is_ofst_odd == true) {
-			memmove(buf, (buf + 1), (len - 1));
-			*retlen += (ret - 1);
-			buf += ret - 1;
-			is_ofst_odd = false;
-		} else {
-			*retlen += ret;
-			buf += ret;
-		}
+		*retlen += ret;
+		buf += ret;
 		from += ret;
 		len -= ret;
 	}
@@ -1969,7 +1838,6 @@ static int spi_nor_write(struct mtd_info *mtd, loff_t to, size_t len,
 	struct spi_nor *nor = mtd_to_spi_nor(mtd);
 	size_t page_offset, page_remain, i;
 	ssize_t ret;
-	u32 offset;
 
 #ifdef CONFIG_SPI_FLASH_SST
 	/* sst nor chips use AAI word program */
@@ -1979,27 +1847,6 @@ static int spi_nor_write(struct mtd_info *mtd, loff_t to, size_t len,
 
 	dev_dbg(nor->dev, "to 0x%08x, len %zd\n", (u32)to, len);
 
-	if (!len)
-		return 0;
-
-	/*
-	 * Cannot write to odd offset in parallel mode,
-	 * so write 2 bytes first
-	 */
-	if ((nor->flags & SNOR_F_HAS_PARALLEL) && (to & 1)) {
-		u8 two[2] = {0xff, buf[0]};
-		size_t local_retlen;
-
-		ret = spi_nor_write(mtd, to & ~1, 2, &local_retlen, two);
-		if (ret < 0)
-			return ret;
-
-		*retlen += 1; /* We've written only one actual byte */
-		buf++;
-		len--;
-		to++;
-	}
-
 	for (i = 0; i < len; ) {
 		ssize_t written;
 		loff_t addr = to + i;
@@ -2017,30 +1864,18 @@ static int spi_nor_write(struct mtd_info *mtd, loff_t to, size_t len,
 
 			page_offset = do_div(aux, nor->page_size);
 		}
-		offset = to + i;
-		if (nor->flags & SNOR_F_HAS_PARALLEL)
-			offset /= 2;
-
-		if (nor->flags & SNOR_F_HAS_STACKED) {
-			if (offset >= (mtd->size / 2)) {
-				offset = offset - (mtd->size / 2);
-				nor->spi->flags |= SPI_XFER_U_PAGE;
-			} else {
-				nor->spi->flags &= ~SPI_XFER_U_PAGE;
-			}
-		}
+		/* the size of data remaining on the first page */
+		page_remain = min_t(size_t,
+				    nor->page_size - page_offset, len - i);
 
 #if CONFIG_IS_ENABLED(SPI_FLASH_BAR)
-		ret = write_bar(nor, offset);
+		ret = write_bar(nor, addr);
 		if (ret < 0)
 			return ret;
 #endif
 
-		/* the size of data remaining on the first page */
-		page_remain = min_t(size_t,
-				    nor->page_size - page_offset, len - i);
-
 		write_enable(nor);
+
 		/*
 		 * On DTR capable flashes like Micron Xcella the writes cannot
 		 * start or end at an odd address in DTR mode. So we need to
@@ -2048,7 +1883,7 @@ static int spi_nor_write(struct mtd_info *mtd, loff_t to, size_t len,
 		 * address and end address are even.
 		 */
 		if (spi_nor_protocol_is_dtr(nor->write_proto) &&
-		    ((offset | page_remain) & 1)) {
+		    ((addr | page_remain) & 1)) {
 			u_char *tmp;
 			size_t extra_bytes = 0;
 
@@ -2059,10 +1894,10 @@ static int spi_nor_write(struct mtd_info *mtd, loff_t to, size_t len,
 			}
 
 			/* Prepend a 0xff byte if the start address is odd. */
-			if (offset & 1) {
+			if (addr & 1) {
 				tmp[0] = 0xff;
 				memcpy(tmp + 1, buf + i, page_remain);
-				offset--;
+				addr--;
 				page_remain++;
 				extra_bytes++;
 			} else {
@@ -2070,13 +1905,13 @@ static int spi_nor_write(struct mtd_info *mtd, loff_t to, size_t len,
 			}
 
 			/* Append a 0xff byte if the end address is odd. */
-			if ((offset + page_remain) & 1) {
+			if ((addr + page_remain) & 1) {
 				tmp[page_remain + extra_bytes] = 0xff;
 				extra_bytes++;
 				page_remain++;
 			}
 
-			ret = nor->write(nor, offset, page_remain, tmp);
+			ret = nor->write(nor, addr, page_remain, tmp);
 
 			kfree(tmp);
 
@@ -2089,7 +1924,7 @@ static int spi_nor_write(struct mtd_info *mtd, loff_t to, size_t len,
 			 */
 			written = ret - extra_bytes;
 		} else {
-			ret = nor->write(nor, offset, page_remain, buf + i);
+			ret = nor->write(nor, addr, page_remain, buf + i);
 			if (ret < 0)
 				goto write_err;
 			written = ret;
@@ -2098,7 +1933,6 @@ static int spi_nor_write(struct mtd_info *mtd, loff_t to, size_t len,
 		ret = spi_nor_wait_till_ready(nor);
 		if (ret)
 			goto write_err;
-
 		*retlen += written;
 		i += written;
 	}
@@ -2376,10 +2210,6 @@ static int spi_nor_read_sfdp(struct spi_nor *nor, u32 addr,
 	nor->read_dummy = 8;
 
 	while (len) {
-		/* Both chips are identical, so should be the SFDP data */
-		if (nor->flags & SNOR_F_HAS_PARALLEL)
-			nor->spi->flags |= SPI_XFER_LOWER;
-
 		ret = nor->read(nor, addr, len, (u8 *)buf);
 		if (!ret || ret > len) {
 			ret = -EIO;
@@ -3193,70 +3023,6 @@ static int spi_nor_init_params(struct spi_nor *nor,
 		spi_nor_post_sfdp_fixups(nor, params);
 	}
 
-#if CONFIG_IS_ENABLED(DM_SPI)
-	if (CONFIG_IS_ENABLED(SPI_STACKED_PARALLEL)) {
-		u64 flash_size[SNOR_FLASH_CNT_MAX] = { 0 };
-		struct udevice *dev = nor->spi->dev;
-		u32 idx = 0, i = 0;
-		int rc;
-
-		/*
-		 * The flashes that are connected in stacked mode should be of same make.
-		 * Except the flash size all other properties are identical for all the
-		 * flashes connected in stacked mode.
-		 * The flashes that are connected in parallel mode should be identical.
-		 */
-		while (i < SNOR_FLASH_CNT_MAX) {
-			rc = ofnode_read_u64_index(dev_ofnode(dev), "stacked-memories",
-						   idx, &flash_size[i]);
-			if (rc == -EINVAL) {
-				break;
-			} else if (rc == -EOVERFLOW) {
-				idx++;
-			} else {
-				idx++;
-				i++;
-				if (!(nor->flags & SNOR_F_HAS_STACKED))
-					nor->flags |= SNOR_F_HAS_STACKED;
-				if (!(nor->spi->flags & SPI_XFER_STACKED))
-					nor->spi->flags |= SPI_XFER_STACKED;
-			}
-		}
-
-		i = 0;
-		idx = 0;
-		while (i < SNOR_FLASH_CNT_MAX) {
-			rc = ofnode_read_u64_index(dev_ofnode(dev), "parallel-memories",
-						   idx, &flash_size[i]);
-			if (rc == -EINVAL) {
-				break;
-			} else if (rc == -EOVERFLOW) {
-				idx++;
-			} else {
-				idx++;
-				i++;
-				if (!(nor->flags & SNOR_F_HAS_PARALLEL))
-					nor->flags |= SNOR_F_HAS_PARALLEL;
-			}
-		}
-
-		if (nor->flags & (SNOR_F_HAS_STACKED | SNOR_F_HAS_PARALLEL)) {
-			params->size = 0;
-			for (idx = 0; idx < SNOR_FLASH_CNT_MAX; idx++)
-				params->size += flash_size[idx];
-		}
-		/*
-		 * In parallel-memories the erase operation is
-		 * performed on both the flashes simultaneously
-		 * so, double the erasesize.
-		 */
-		if (nor->flags & SNOR_F_HAS_PARALLEL) {
-			nor->mtd.erasesize <<= 1;
-			params->page_size <<= 1;
-		}
-	}
-#endif
-
 	spi_nor_late_init_fixups(nor, params);
 
 	return 0;
@@ -3571,54 +3337,16 @@ static int spi_nor_select_erase(struct spi_nor *nor,
 	/* prefer "small sector" erase if possible */
 	if (info->flags & SECT_4K) {
 		nor->erase_opcode = SPINOR_OP_BE_4K;
-		/*
-		 * In parallel-memories the erase operation is
-		 * performed on both the flashes simultaneously
-		 * so, double the erasesize.
-		 */
-		if (nor->flags & SNOR_F_HAS_PARALLEL)
-			mtd->erasesize = 4096 * 2;
-		else
-			mtd->erasesize = 4096;
+		mtd->erasesize = 4096;
 	} else if (info->flags & SECT_4K_PMC) {
 		nor->erase_opcode = SPINOR_OP_BE_4K_PMC;
-		/*
-		 * In parallel-memories the erase operation is
-		 * performed on both the flashes simultaneously
-		 * so, double the erasesize.
-		 */
-		if (nor->flags & SNOR_F_HAS_PARALLEL)
-			mtd->erasesize = 4096 * 2;
-		else
-			mtd->erasesize = 4096;
+		mtd->erasesize = 4096;
 	} else
 #endif
 	{
 		nor->erase_opcode = SPINOR_OP_SE;
-		/*
-		 * In parallel-memories the erase operation is
-		 * performed on both the flashes simultaneously
-		 * so, double the erasesize.
-		 */
-		if (nor->flags & SNOR_F_HAS_PARALLEL)
-			mtd->erasesize = info->sector_size * 2;
-		else
-			mtd->erasesize = info->sector_size;
-	}
-
-	if ((JEDEC_MFR(info) == SNOR_MFR_SST) && info->flags & SECT_4K) {
-		nor->erase_opcode = SPINOR_OP_BE_4K;
-		/*
-		 * In parallel-memories the erase operation is
-		 * performed on both the flashes simultaneously
-		 * so, double the erasesize.
-		 */
-		if (nor->flags & SNOR_F_HAS_PARALLEL)
-			mtd->erasesize = 4096 * 2;
-		else
-			mtd->erasesize = 4096;
+		mtd->erasesize = info->sector_size;
 	}
-
 	return 0;
 }
 
@@ -4282,9 +4010,6 @@ int spi_nor_init(struct spi_nor *nor)
 {
 	int err;
 
-	if (nor->flags & SNOR_F_HAS_PARALLEL)
-		nor->spi->flags |= SPI_NOR_ENABLE_MULTI_CS;
-
 	err = spi_nor_octal_dtr_enable(nor);
 	if (err) {
 		dev_dbg(nor->dev, "Octal DTR mode not supported\n");
@@ -4474,7 +4199,6 @@ int spi_nor_scan(struct spi_nor *nor)
 	struct spi_slave *spi = nor->spi;
 	int ret;
 	int cfi_mtd_nb = 0;
-	bool shift = 0;
 
 #ifdef CONFIG_FLASH_CFI_MTD
 	cfi_mtd_nb = CFI_FLASH_BANKS;
@@ -4612,9 +4336,7 @@ int spi_nor_scan(struct spi_nor *nor)
 		nor->addr_width = 3;
 	}
 
-	if (nor->flags & (SNOR_F_HAS_PARALLEL | SNOR_F_HAS_STACKED))
-		shift = 1;
-	if (nor->addr_width == 3 && (mtd->size >> shift) > SZ_16M) {
+	if (nor->addr_width == 3 && mtd->size > SZ_16M) {
 #if !CONFIG_IS_ENABLED(SPI_FLASH_BAR)
 		/* enable 4-byte addressing if the device exceeds 16MiB */
 		nor->addr_width = 4;
@@ -4641,14 +4363,6 @@ int spi_nor_scan(struct spi_nor *nor)
 	if (ret)
 		return ret;
 
-	if (nor->flags & SNOR_F_HAS_STACKED) {
-		nor->spi->flags |= SPI_XFER_U_PAGE;
-		ret = spi_nor_init(nor);
-		if (ret)
-			return ret;
-		nor->spi->flags &= ~SPI_XFER_U_PAGE;
-	}
-
 	nor->rdsr_dummy = params.rdsr_dummy;
 	nor->rdsr_addr_nbytes = params.rdsr_addr_nbytes;
 	nor->name = info->name;
diff --git a/include/linux/mtd/spi-nor.h b/include/linux/mtd/spi-nor.h
index 4eef4ab0488..ebbf6a7a944 100644
--- a/include/linux/mtd/spi-nor.h
+++ b/include/linux/mtd/spi-nor.h
@@ -13,9 +13,6 @@
 #include <linux/mtd/mtd.h>
 #include <spi-mem.h>
 
-/* In parallel configuration enable multiple CS */
-#define SPI_NOR_ENABLE_MULTI_CS	(BIT(0) | BIT(1))
-
 /*
  * Manufacturer IDs
  *
@@ -308,13 +305,6 @@ enum spi_nor_option_flags {
 	SNOR_F_BROKEN_RESET	= BIT(6),
 	SNOR_F_SOFT_RESET	= BIT(7),
 	SNOR_F_IO_MODE_EN_VOLATILE = BIT(8),
-#if defined(CONFIG_SPI_STACKED_PARALLEL)
-	SNOR_F_HAS_STACKED	= BIT(9),
-	SNOR_F_HAS_PARALLEL	= BIT(10),
-#else
-	SNOR_F_HAS_STACKED	= 0,
-	SNOR_F_HAS_PARALLEL	= 0,
-#endif
 };
 
 struct spi_nor;
diff --git a/include/spi.h b/include/spi.h
index 2783200d663..473790135b9 100644
--- a/include/spi.h
+++ b/include/spi.h
@@ -164,8 +164,6 @@ struct spi_slave {
 #define SPI_XFER_END		BIT(1)	/* Deassert CS after transfer */
 #define SPI_XFER_ONCE		(SPI_XFER_BEGIN | SPI_XFER_END)
 #define SPI_XFER_U_PAGE		BIT(4)
-#define SPI_XFER_STACKED	BIT(5)
-#define SPI_XFER_LOWER		BIT(6)
 
 	/*
 	 * Flag indicating that the spi-controller has multi chip select

-- 
2.34.1

