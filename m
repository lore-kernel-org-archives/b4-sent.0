From: Takahiro Kuwano <Takahiro.Kuwano@infineon.com>
Date: Wed, 19 Nov 2025 14:13:06 +0900
Subject: [PATCH 07/11] mtd: spi-nor: Migrate stacked/parallel part to new
 modules
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251119-amd-cleanup-v1-7-c555bd85e6e4@infineon.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763529253; l=28510;
 i=Takahiro.Kuwano@infineon.com; s=20250227; h=from:subject:message-id;
 bh=TsaU3TfAumm8eO/Wnw73mzHwS5bx+yXwkT4gdbf3Rcw=;
 b=k1OPmFHdno7pQItd2SGHZfrHfsb9/EitBlvGr20gt5kyZC2bHiLsC8h5PK84DtEd9nRo4+E2P
 JzguwoQq5dJD6zgMymRoYuNdjelgxq0bWH1wma2ch9KjxLlUiJNi5W2
X-Developer-Key: i=Takahiro.Kuwano@infineon.com; a=ed25519;
 pk=aS8V9WLuMUkl0vmgD0xJU19ZajdJmuyFBnBfVj0dfDs=
X-Endpoint-Received: by B4 Relay for Takahiro.Kuwano@infineon.com/20250227 with auth_id=566
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add new modules named stacked.c and parallel.c. Those are compiled along
with spi-nor-core in case CONFIG_SPI_STACKED_PARALLEL is enabled.

Copy erase/program/read and write_bar functions from core to both
modules. Some helper functions inn core are exposed.

Introduce new fixup functions, spi_nor_stacked_post_init_fixups() and
spi_nor_parallel_post_init_fixups() in each module. Those implement
ofnode property check performed in spi_nor_init_params() in core, update
size parameters with replacing params->*, and assign erase/program/read
to mtd_info. The fixups will be called from core after spi_nor_init()
call.

In stacked mode, spi_nor_init() is called twice to init upper page.
spi_nor_stacked_post_init_fixups() performs the second call of
spi_nor_init().

In parallel mode, there are size updates in spi_nor_select_erase(),
spi_nor_set_4byte_opcodes(), and spi_nor_scan(). Those are not moved to
parallel module as size update can be consolidated into one place,
spi_nor_parallel_post_init_fixups(). Besides, write_bar call performed
in read_bar() is moved to fixup as read_bar() is called once before
spi_nor_init() and shouldn't be a problem if it is called after
spi_nor_init().

At this point, keep spi-nor-core as it is, reverting stacked/parallel
related changes will be done at once in another patch.

Signed-off-by: Takahiro Kuwano <Takahiro.Kuwano@infineon.com>
---
 drivers/mtd/spi/Makefile       |   4 +
 drivers/mtd/spi/parallel.c     | 470 +++++++++++++++++++++++++++++++++++++++++
 drivers/mtd/spi/sf_internal.h  |  15 ++
 drivers/mtd/spi/spi-nor-core.c |  22 +-
 drivers/mtd/spi/stacked.c      | 453 +++++++++++++++++++++++++++++++++++++++
 5 files changed, 953 insertions(+), 11 deletions(-)

diff --git a/drivers/mtd/spi/Makefile b/drivers/mtd/spi/Makefile
index 44e67cd913a..563f61bd1aa 100644
--- a/drivers/mtd/spi/Makefile
+++ b/drivers/mtd/spi/Makefile
@@ -17,6 +17,10 @@ else
 spi-nor-y += spi-nor-core.o
 endif
 
+ifneq (,$(findstring spi-nor-core, $(spi-nor-y)))
+spi-nor-$(CONFIG_SPI_STACKED_PARALLEL) += stacked.o parallel.o
+endif
+
 obj-$(CONFIG_SPI_FLASH) += spi-nor.o
 obj-$(CONFIG_SPI_FLASH_DATAFLASH) += sf_dataflash.o
 obj-$(CONFIG_$(PHASE_)SPI_FLASH_MTD) += sf_mtd.o
diff --git a/drivers/mtd/spi/parallel.c b/drivers/mtd/spi/parallel.c
new file mode 100644
index 00000000000..d884eaefcd0
--- /dev/null
+++ b/drivers/mtd/spi/parallel.c
@@ -0,0 +1,470 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * (C) Copyright 2025 Infineon Technologies
+ *
+ * SPI NOR driver for parallel-memories configuration.
+ */
+
+#include <dm/device_compat.h>
+#include <linux/err.h>
+#include <linux/math64.h>
+#include <linux/sizes.h>
+#include <linux/mtd/spi-nor.h>
+#include <spi.h>
+
+#include "sf_internal.h"
+
+#if CONFIG_IS_ENABLED(SPI_FLASH_BAR)
+static int write_bar(struct spi_nor *nor, u32 offset)
+{
+	u8 cmd, bank_sel, upage_curr;
+	int ret;
+	struct mtd_info *mtd = &nor->mtd;
+
+	/* Wait until previous write command is finished */
+	if (spi_nor_wait_till_ready(nor))
+		return 1;
+
+	if (nor->flags & (SNOR_F_HAS_PARALLEL | SNOR_F_HAS_STACKED) &&
+	    mtd->size <= SZ_32M)
+		return 0;
+
+	if (mtd->size <= SZ_16M)
+		return 0;
+
+	offset = offset % (u32)mtd->size;
+	bank_sel = offset >> 24;
+
+	upage_curr = nor->spi->flags & SPI_XFER_U_PAGE;
+
+	if (!(nor->flags & SNOR_F_HAS_STACKED) && bank_sel == nor->bank_curr)
+		return 0;
+	else if (upage_curr == nor->upage_prev && bank_sel == nor->bank_curr)
+		return 0;
+
+	nor->upage_prev = upage_curr;
+
+	cmd = nor->bank_write_cmd;
+	write_enable(nor);
+	ret = nor->write_reg(nor, cmd, &bank_sel, 1);
+	if (ret < 0) {
+		debug("SF: fail to write bank register\n");
+		return ret;
+	}
+
+	nor->bank_curr = bank_sel;
+
+	return write_disable(nor);
+}
+#endif
+
+static int spi_nor_erase(struct mtd_info *mtd, struct erase_info *instr)
+{
+	struct spi_nor *nor = mtd_to_spi_nor(mtd);
+	u32 addr, len, rem, offset, max_size;
+	bool addr_known = false;
+	int ret, err;
+
+	dev_dbg(nor->dev, "at 0x%llx, len %lld\n", (long long)instr->addr,
+		(long long)instr->len);
+
+	div_u64_rem(instr->len, mtd->erasesize, &rem);
+	if (rem) {
+		ret = -EINVAL;
+		goto err;
+	}
+
+	addr = instr->addr;
+	len = instr->len;
+	max_size = instr->len;
+
+	instr->state = MTD_ERASING;
+	addr_known = true;
+
+	while (len) {
+		schedule();
+		if (!IS_ENABLED(CONFIG_XPL_BUILD) && ctrlc()) {
+			addr_known = false;
+			ret = -EINTR;
+			goto erase_err;
+		}
+		offset = addr;
+		if (CONFIG_IS_ENABLED(SPI_STACKED_PARALLEL)) {
+			if (nor->flags & SNOR_F_HAS_PARALLEL)
+				offset /= 2;
+
+			if (nor->flags & SNOR_F_HAS_STACKED) {
+				if (offset >= (mtd->size / 2))
+					nor->spi->flags |= SPI_XFER_U_PAGE;
+				else
+					nor->spi->flags &= ~SPI_XFER_U_PAGE;
+			}
+		}
+#if CONFIG_IS_ENABLED(SPI_FLASH_BAR)
+		ret = write_bar(nor, offset);
+		if (ret < 0)
+			goto erase_err;
+#endif
+		ret = write_enable(nor);
+		if (ret < 0)
+			goto erase_err;
+
+		if (len == mtd->size &&
+		    !(nor->flags & SNOR_F_NO_OP_CHIP_ERASE)) {
+			ret = spi_nor_erase_chip(nor);
+		} else {
+			ret = spi_nor_erase_sector(nor, offset);
+		}
+		if (ret < 0)
+			goto erase_err;
+
+		addr += ret;
+		len -= ret;
+
+		if (max_size == mtd->size &&
+		    !(nor->flags & SNOR_F_NO_OP_CHIP_ERASE)) {
+			ret = spi_nor_erase_chip_wait_till_ready(nor, mtd->size);
+		} else {
+			ret = spi_nor_wait_till_ready(nor);
+		}
+
+		if (ret)
+			goto erase_err;
+	}
+
+	addr_known = false;
+erase_err:
+#if CONFIG_IS_ENABLED(SPI_FLASH_BAR)
+	err = clean_bar(nor);
+	if (!ret)
+		ret = err;
+#endif
+	err = write_disable(nor);
+	if (!ret)
+		ret = err;
+
+err:
+	if (ret) {
+		instr->fail_addr = addr_known ? addr : MTD_FAIL_ADDR_UNKNOWN;
+		instr->state = MTD_ERASE_FAILED;
+	} else {
+		instr->state = MTD_ERASE_DONE;
+	}
+
+	return ret;
+}
+
+static int spi_nor_read(struct mtd_info *mtd, loff_t from, size_t len,
+			size_t *retlen, u_char *buf)
+{
+	struct spi_nor *nor = mtd_to_spi_nor(mtd);
+	loff_t offset = from;
+	u32 rem_bank_len = 0;
+	u32 stack_shift = 0;
+	size_t read_len;
+	u8 bank;
+	int ret;
+	bool is_ofst_odd = false;
+
+	dev_dbg(nor->dev, "from 0x%08x, len %zd\n", (u32)from, len);
+
+	if ((nor->flags & SNOR_F_HAS_PARALLEL) && (offset & 1)) {
+		/* We can hit this case when we use file system like ubifs */
+		from--;
+		len++;
+		is_ofst_odd = true;
+	}
+
+	while (len) {
+		read_len = len;
+		offset = from;
+
+		if (CONFIG_IS_ENABLED(SPI_FLASH_BAR)) {
+			bank = (u32)from / SZ_16M;
+			if (CONFIG_IS_ENABLED(SPI_STACKED_PARALLEL)) {
+				if (nor->flags & SNOR_F_HAS_PARALLEL)
+					bank /= 2;
+			}
+			rem_bank_len = SZ_16M * (bank + 1);
+			if (CONFIG_IS_ENABLED(SPI_STACKED_PARALLEL)) {
+				if (nor->flags & SNOR_F_HAS_PARALLEL)
+					rem_bank_len *= 2;
+			}
+			rem_bank_len -= from;
+		}
+
+		if (CONFIG_IS_ENABLED(SPI_STACKED_PARALLEL)) {
+			if (nor->flags & SNOR_F_HAS_STACKED) {
+				stack_shift = 1;
+				if (offset >= (mtd->size / 2)) {
+					offset = offset - (mtd->size / 2);
+					nor->spi->flags |= SPI_XFER_U_PAGE;
+				} else {
+					nor->spi->flags &= ~SPI_XFER_U_PAGE;
+				}
+			}
+		}
+
+		if (CONFIG_IS_ENABLED(SPI_STACKED_PARALLEL)) {
+			if (nor->flags & SNOR_F_HAS_PARALLEL)
+				offset /= 2;
+		}
+
+#if CONFIG_IS_ENABLED(SPI_FLASH_BAR)
+		ret = write_bar(nor, offset);
+		if (ret < 0)
+			return log_ret(ret);
+		if (len < rem_bank_len)
+			read_len = len;
+		else
+			read_len = rem_bank_len;
+#endif
+
+		if (read_len == 0)
+			return -EIO;
+
+		ret = nor->read(nor, offset, read_len, buf);
+		if (ret == 0) {
+			/* We shouldn't see 0-length reads */
+			ret = -EIO;
+			goto read_err;
+		}
+		if (ret < 0)
+			goto read_err;
+
+		if (is_ofst_odd == true) {
+			memmove(buf, (buf + 1), (len - 1));
+			*retlen += (ret - 1);
+			buf += ret - 1;
+			is_ofst_odd = false;
+		} else {
+			*retlen += ret;
+			buf += ret;
+		}
+		from += ret;
+		len -= ret;
+	}
+	ret = 0;
+
+read_err:
+#if CONFIG_IS_ENABLED(SPI_FLASH_BAR)
+	ret = clean_bar(nor);
+#endif
+	return ret;
+}
+
+static int spi_nor_write(struct mtd_info *mtd, loff_t to, size_t len,
+	size_t *retlen, const u_char *buf)
+{
+	struct spi_nor *nor = mtd_to_spi_nor(mtd);
+	size_t page_offset, page_remain, i;
+	ssize_t ret;
+	u32 offset;
+
+#ifdef CONFIG_SPI_FLASH_SST
+	/* sst nor chips use AAI word program */
+	if (nor->info->flags & SST_WRITE)
+		return sst_write(mtd, to, len, retlen, buf);
+#endif
+
+	dev_dbg(nor->dev, "to 0x%08x, len %zd\n", (u32)to, len);
+
+	if (!len)
+		return 0;
+
+	/*
+	 * Cannot write to odd offset in parallel mode,
+	 * so write 2 bytes first
+	 */
+	if ((nor->flags & SNOR_F_HAS_PARALLEL) && (to & 1)) {
+		u8 two[2] = {0xff, buf[0]};
+		size_t local_retlen;
+
+		ret = spi_nor_write(mtd, to & ~1, 2, &local_retlen, two);
+		if (ret < 0)
+			return ret;
+
+		*retlen += 1; /* We've written only one actual byte */
+		buf++;
+		len--;
+		to++;
+	}
+
+	for (i = 0; i < len; ) {
+		ssize_t written;
+		loff_t addr = to + i;
+		schedule();
+
+		/*
+		 * If page_size is a power of two, the offset can be quickly
+		 * calculated with an AND operation. On the other cases we
+		 * need to do a modulus operation (more expensive).
+		 */
+		if (is_power_of_2(nor->page_size)) {
+			page_offset = addr & (nor->page_size - 1);
+		} else {
+			u64 aux = addr;
+
+			page_offset = do_div(aux, nor->page_size);
+		}
+		offset = to + i;
+		if (nor->flags & SNOR_F_HAS_PARALLEL)
+			offset /= 2;
+
+		if (nor->flags & SNOR_F_HAS_STACKED) {
+			if (offset >= (mtd->size / 2)) {
+				offset = offset - (mtd->size / 2);
+				nor->spi->flags |= SPI_XFER_U_PAGE;
+			} else {
+				nor->spi->flags &= ~SPI_XFER_U_PAGE;
+			}
+		}
+
+#if CONFIG_IS_ENABLED(SPI_FLASH_BAR)
+		ret = write_bar(nor, offset);
+		if (ret < 0)
+			return ret;
+#endif
+
+		/* the size of data remaining on the first page */
+		page_remain = min_t(size_t,
+				    nor->page_size - page_offset, len - i);
+
+		write_enable(nor);
+		/*
+		 * On DTR capable flashes like Micron Xcella the writes cannot
+		 * start or end at an odd address in DTR mode. So we need to
+		 * append or prepend extra 0xff bytes to make sure the start
+		 * address and end address are even.
+		 */
+		if (spi_nor_protocol_is_dtr(nor->write_proto) &&
+		    ((offset | page_remain) & 1)) {
+			u_char *tmp;
+			size_t extra_bytes = 0;
+
+			tmp = kmalloc(nor->page_size, 0);
+			if (!tmp) {
+				ret = -ENOMEM;
+				goto write_err;
+			}
+
+			/* Prepend a 0xff byte if the start address is odd. */
+			if (offset & 1) {
+				tmp[0] = 0xff;
+				memcpy(tmp + 1, buf + i, page_remain);
+				offset--;
+				page_remain++;
+				extra_bytes++;
+			} else {
+				memcpy(tmp, buf + i, page_remain);
+			}
+
+			/* Append a 0xff byte if the end address is odd. */
+			if ((offset + page_remain) & 1) {
+				tmp[page_remain + extra_bytes] = 0xff;
+				extra_bytes++;
+				page_remain++;
+			}
+
+			ret = nor->write(nor, offset, page_remain, tmp);
+
+			kfree(tmp);
+
+			if (ret < 0)
+				goto write_err;
+
+			/*
+			 * We write extra bytes but they are not part of the
+			 * original write.
+			 */
+			written = ret - extra_bytes;
+		} else {
+			ret = nor->write(nor, offset, page_remain, buf + i);
+			if (ret < 0)
+				goto write_err;
+			written = ret;
+		}
+
+		ret = spi_nor_wait_till_ready(nor);
+		if (ret)
+			goto write_err;
+
+		*retlen += written;
+		i += written;
+	}
+
+write_err:
+#if CONFIG_IS_ENABLED(SPI_FLASH_BAR)
+	ret = clean_bar(nor);
+#endif
+	return ret;
+}
+
+int spi_nor_parallel_post_init_fixups(struct spi_nor *nor)
+{
+	struct mtd_info *mtd = &nor->mtd;
+
+#if CONFIG_IS_ENABLED(DM_SPI)
+	u64 flash_size[SNOR_FLASH_CNT_MAX] = { 0 };
+	struct udevice *dev = nor->spi->dev;
+	u32 idx = 0, i = 0;
+	int rc;
+
+	while (i < SNOR_FLASH_CNT_MAX) {
+		rc = ofnode_read_u64_index(dev_ofnode(dev), "parallel-memories",
+					   idx, &flash_size[i]);
+		if (rc == -EINVAL) {
+			break;
+		} else if (rc == -EOVERFLOW) {
+			idx++;
+		} else {
+			idx++;
+			i++;
+			if (!(nor->flags & SNOR_F_HAS_PARALLEL))
+				nor->flags |= SNOR_F_HAS_PARALLEL;
+		}
+	}
+
+	if (nor->flags & (SNOR_F_HAS_STACKED | SNOR_F_HAS_PARALLEL)) {
+		mtd->size = 0;
+		for (idx = 0; idx < SNOR_FLASH_CNT_MAX; idx++)
+			mtd->size += flash_size[idx];
+	}
+
+	/*
+	 * In parallel-memories the erase operation is
+	 * performed on both the flashes simultaneously
+	 * so, double the erasesize.
+	 */
+	if (nor->flags & SNOR_F_HAS_PARALLEL) {
+		nor->mtd.erasesize <<= 1;
+		nor->page_size <<= 1;
+		nor->mtd.writebufsize <<= 1;
+	}
+#endif
+
+#if CONFIG_IS_ENABLED(SPI_FLASH_BAR)
+	/* Make sure both chips use the same BAR */
+	if (nor->flags & SNOR_F_HAS_PARALLEL) {
+		int ret;
+
+		write_enable(nor);
+		ret = nor->write_reg(nor, nor->bank_write_cmd, &nor->bank_curr,
+				     1);
+		if (ret)
+			return ret;
+
+		ret = write_disable(nor);
+		if (ret)
+			return ret;
+	}
+#endif
+
+	if (nor->flags & SNOR_F_HAS_PARALLEL) {
+		mtd->_erase = spi_nor_erase;
+		mtd->_read = spi_nor_read;
+		mtd->_write = spi_nor_write;
+	}
+
+	return 0;
+}
diff --git a/drivers/mtd/spi/sf_internal.h b/drivers/mtd/spi/sf_internal.h
index 8d2249ce354..8b1a48f045a 100644
--- a/drivers/mtd/spi/sf_internal.h
+++ b/drivers/mtd/spi/sf_internal.h
@@ -93,4 +93,19 @@ static inline void spi_flash_mtd_unregister(struct spi_flash *flash)
 }
 #endif
 
+#if !CONFIG_IS_ENABLED(SPI_FLASH_TINY)
+int spi_nor_init(struct spi_nor *nor);
+int write_enable(struct spi_nor *nor);
+int write_disable(struct spi_nor *nor);
+int spi_nor_wait_till_ready(struct spi_nor *nor);
+struct spi_nor *mtd_to_spi_nor(struct mtd_info *mtd);
+#endif
+
+int spi_nor_erase_chip_wait_till_ready(struct spi_nor *nor, unsigned long size);
+int spi_nor_erase_chip(struct spi_nor *nor);
+int spi_nor_erase_sector(struct spi_nor *nor, u32 addr);
+int clean_bar(struct spi_nor *nor);
+int sst_write(struct mtd_info *mtd, loff_t to, size_t len, size_t *retlen,
+	      const u_char *buf);
+
 #endif /* _SF_INTERNAL_H_ */
diff --git a/drivers/mtd/spi/spi-nor-core.c b/drivers/mtd/spi/spi-nor-core.c
index 76c33b24368..9695a706d0b 100644
--- a/drivers/mtd/spi/spi-nor-core.c
+++ b/drivers/mtd/spi/spi-nor-core.c
@@ -637,7 +637,7 @@ static int write_sr3(struct spi_nor *nor, u8 val)
  * Set write enable latch with Write Enable command.
  * Returns negative if error occurred.
  */
-static int write_enable(struct spi_nor *nor)
+int write_enable(struct spi_nor *nor)
 {
 	return nor->write_reg(nor, SPINOR_OP_WREN, NULL, 0);
 }
@@ -645,12 +645,12 @@ static int write_enable(struct spi_nor *nor)
 /*
  * Send write disable instruction to the chip.
  */
-static int write_disable(struct spi_nor *nor)
+int write_disable(struct spi_nor *nor)
 {
 	return nor->write_reg(nor, SPINOR_OP_WRDI, NULL, 0);
 }
 
-static struct spi_nor *mtd_to_spi_nor(struct mtd_info *mtd)
+struct spi_nor *mtd_to_spi_nor(struct mtd_info *mtd)
 {
 	return mtd->priv;
 }
@@ -910,13 +910,13 @@ static int spi_nor_wait_till_ready_with_timeout(struct spi_nor *nor,
 	return -ETIMEDOUT;
 }
 
-static int spi_nor_wait_till_ready(struct spi_nor *nor)
+int spi_nor_wait_till_ready(struct spi_nor *nor)
 {
 	return spi_nor_wait_till_ready_with_timeout(nor,
 						    DEFAULT_READY_WAIT_JIFFIES);
 }
 
-static int spi_nor_erase_chip_wait_till_ready(struct spi_nor *nor, unsigned long size)
+int spi_nor_erase_chip_wait_till_ready(struct spi_nor *nor, unsigned long size)
 {
 	/*
 	 * Scale the timeout linearly with the size of the flash, with
@@ -941,7 +941,7 @@ static int spi_nor_erase_chip_wait_till_ready(struct spi_nor *nor, unsigned long
  * Otherwise, the BA24 bit may be left set and then after reset, the
  * ROM would read/write/erase SPL from 16 MiB * bank_sel address.
  */
-static int clean_bar(struct spi_nor *nor)
+int clean_bar(struct spi_nor *nor)
 {
 	u8 cmd, bank_sel = 0;
 	int ret;
@@ -1053,7 +1053,7 @@ static int read_bar(struct spi_nor *nor, const struct flash_info *info)
  *
  * Return: 0 on success, -errno otherwise.
  */
-static int spi_nor_erase_chip(struct spi_nor *nor)
+int spi_nor_erase_chip(struct spi_nor *nor)
 {
 	struct spi_mem_op op =
 		SPI_MEM_OP(SPI_MEM_OP_CMD(SPINOR_OP_CHIP_ERASE, 0),
@@ -1075,7 +1075,7 @@ static int spi_nor_erase_chip(struct spi_nor *nor)
  * Initiate the erasure of a single sector. Returns the number of bytes erased
  * on success, a negative error code on error.
  */
-static int spi_nor_erase_sector(struct spi_nor *nor, u32 addr)
+int spi_nor_erase_sector(struct spi_nor *nor, u32 addr)
 {
 	struct spi_mem_op op =
 		SPI_MEM_OP(SPI_MEM_OP_CMD(nor->erase_opcode, 0),
@@ -1885,8 +1885,8 @@ sst_write_err:
 	return ret;
 }
 
-static int sst_write(struct mtd_info *mtd, loff_t to, size_t len,
-		     size_t *retlen, const u_char *buf)
+int sst_write(struct mtd_info *mtd, loff_t to, size_t len, size_t *retlen,
+	      const u_char *buf)
 {
 	struct spi_nor *nor = mtd_to_spi_nor(mtd);
 	struct spi_slave *spi = nor->spi;
@@ -4278,7 +4278,7 @@ static int spi_nor_octal_dtr_enable(struct spi_nor *nor)
 	return 0;
 }
 
-static int spi_nor_init(struct spi_nor *nor)
+int spi_nor_init(struct spi_nor *nor)
 {
 	int err;
 
diff --git a/drivers/mtd/spi/stacked.c b/drivers/mtd/spi/stacked.c
new file mode 100644
index 00000000000..e005aea1053
--- /dev/null
+++ b/drivers/mtd/spi/stacked.c
@@ -0,0 +1,453 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * (C) Copyright 2025 Infineon Technologies
+ *
+ * SPI NOR driver for stacked-memories configuration.
+ */
+
+#include <dm/device_compat.h>
+#include <linux/err.h>
+#include <linux/math64.h>
+#include <linux/sizes.h>
+#include <linux/mtd/spi-nor.h>
+#include <spi.h>
+
+#include "sf_internal.h"
+
+#if CONFIG_IS_ENABLED(SPI_FLASH_BAR)
+static int write_bar(struct spi_nor *nor, u32 offset)
+{
+	u8 cmd, bank_sel, upage_curr;
+	int ret;
+	struct mtd_info *mtd = &nor->mtd;
+
+	/* Wait until previous write command is finished */
+	if (spi_nor_wait_till_ready(nor))
+		return 1;
+
+	if (nor->flags & (SNOR_F_HAS_PARALLEL | SNOR_F_HAS_STACKED) &&
+	    mtd->size <= SZ_32M)
+		return 0;
+
+	if (mtd->size <= SZ_16M)
+		return 0;
+
+	offset = offset % (u32)mtd->size;
+	bank_sel = offset >> 24;
+
+	upage_curr = nor->spi->flags & SPI_XFER_U_PAGE;
+
+	if (!(nor->flags & SNOR_F_HAS_STACKED) && bank_sel == nor->bank_curr)
+		return 0;
+	else if (upage_curr == nor->upage_prev && bank_sel == nor->bank_curr)
+		return 0;
+
+	nor->upage_prev = upage_curr;
+
+	cmd = nor->bank_write_cmd;
+	write_enable(nor);
+	ret = nor->write_reg(nor, cmd, &bank_sel, 1);
+	if (ret < 0) {
+		debug("SF: fail to write bank register\n");
+		return ret;
+	}
+
+	nor->bank_curr = bank_sel;
+
+	return write_disable(nor);
+}
+#endif
+
+static int spi_nor_erase(struct mtd_info *mtd, struct erase_info *instr)
+{
+	struct spi_nor *nor = mtd_to_spi_nor(mtd);
+	u32 addr, len, rem, offset, max_size;
+	bool addr_known = false;
+	int ret, err;
+
+	dev_dbg(nor->dev, "at 0x%llx, len %lld\n", (long long)instr->addr,
+		(long long)instr->len);
+
+	div_u64_rem(instr->len, mtd->erasesize, &rem);
+	if (rem) {
+		ret = -EINVAL;
+		goto err;
+	}
+
+	addr = instr->addr;
+	len = instr->len;
+	max_size = instr->len;
+
+	instr->state = MTD_ERASING;
+	addr_known = true;
+
+	while (len) {
+		schedule();
+		if (!IS_ENABLED(CONFIG_XPL_BUILD) && ctrlc()) {
+			addr_known = false;
+			ret = -EINTR;
+			goto erase_err;
+		}
+		offset = addr;
+		if (CONFIG_IS_ENABLED(SPI_STACKED_PARALLEL)) {
+			if (nor->flags & SNOR_F_HAS_PARALLEL)
+				offset /= 2;
+
+			if (nor->flags & SNOR_F_HAS_STACKED) {
+				if (offset >= (mtd->size / 2))
+					nor->spi->flags |= SPI_XFER_U_PAGE;
+				else
+					nor->spi->flags &= ~SPI_XFER_U_PAGE;
+			}
+		}
+#if CONFIG_IS_ENABLED(SPI_FLASH_BAR)
+		ret = write_bar(nor, offset);
+		if (ret < 0)
+			goto erase_err;
+#endif
+		ret = write_enable(nor);
+		if (ret < 0)
+			goto erase_err;
+
+		if (len == mtd->size &&
+		    !(nor->flags & SNOR_F_NO_OP_CHIP_ERASE)) {
+			ret = spi_nor_erase_chip(nor);
+		} else {
+			ret = spi_nor_erase_sector(nor, offset);
+		}
+		if (ret < 0)
+			goto erase_err;
+
+		addr += ret;
+		len -= ret;
+
+		if (max_size == mtd->size &&
+		    !(nor->flags & SNOR_F_NO_OP_CHIP_ERASE)) {
+			ret = spi_nor_erase_chip_wait_till_ready(nor, mtd->size);
+		} else {
+			ret = spi_nor_wait_till_ready(nor);
+		}
+
+		if (ret)
+			goto erase_err;
+	}
+
+	addr_known = false;
+erase_err:
+#if CONFIG_IS_ENABLED(SPI_FLASH_BAR)
+	err = clean_bar(nor);
+	if (!ret)
+		ret = err;
+#endif
+	err = write_disable(nor);
+	if (!ret)
+		ret = err;
+
+err:
+	if (ret) {
+		instr->fail_addr = addr_known ? addr : MTD_FAIL_ADDR_UNKNOWN;
+		instr->state = MTD_ERASE_FAILED;
+	} else {
+		instr->state = MTD_ERASE_DONE;
+	}
+
+	return ret;
+}
+
+static int spi_nor_read(struct mtd_info *mtd, loff_t from, size_t len,
+			size_t *retlen, u_char *buf)
+{
+	struct spi_nor *nor = mtd_to_spi_nor(mtd);
+	loff_t offset = from;
+	u32 rem_bank_len = 0;
+	u32 stack_shift = 0;
+	size_t read_len;
+	u8 bank;
+	int ret;
+	bool is_ofst_odd = false;
+
+	dev_dbg(nor->dev, "from 0x%08x, len %zd\n", (u32)from, len);
+
+	if ((nor->flags & SNOR_F_HAS_PARALLEL) && (offset & 1)) {
+		/* We can hit this case when we use file system like ubifs */
+		from--;
+		len++;
+		is_ofst_odd = true;
+	}
+
+	while (len) {
+		read_len = len;
+		offset = from;
+
+		if (CONFIG_IS_ENABLED(SPI_FLASH_BAR)) {
+			bank = (u32)from / SZ_16M;
+			if (CONFIG_IS_ENABLED(SPI_STACKED_PARALLEL)) {
+				if (nor->flags & SNOR_F_HAS_PARALLEL)
+					bank /= 2;
+			}
+			rem_bank_len = SZ_16M * (bank + 1);
+			if (CONFIG_IS_ENABLED(SPI_STACKED_PARALLEL)) {
+				if (nor->flags & SNOR_F_HAS_PARALLEL)
+					rem_bank_len *= 2;
+			}
+			rem_bank_len -= from;
+		}
+
+		if (CONFIG_IS_ENABLED(SPI_STACKED_PARALLEL)) {
+			if (nor->flags & SNOR_F_HAS_STACKED) {
+				stack_shift = 1;
+				if (offset >= (mtd->size / 2)) {
+					offset = offset - (mtd->size / 2);
+					nor->spi->flags |= SPI_XFER_U_PAGE;
+				} else {
+					nor->spi->flags &= ~SPI_XFER_U_PAGE;
+				}
+			}
+		}
+
+		if (CONFIG_IS_ENABLED(SPI_STACKED_PARALLEL)) {
+			if (nor->flags & SNOR_F_HAS_PARALLEL)
+				offset /= 2;
+		}
+
+#if CONFIG_IS_ENABLED(SPI_FLASH_BAR)
+		ret = write_bar(nor, offset);
+		if (ret < 0)
+			return log_ret(ret);
+		if (len < rem_bank_len)
+			read_len = len;
+		else
+			read_len = rem_bank_len;
+#endif
+
+		if (read_len == 0)
+			return -EIO;
+
+		ret = nor->read(nor, offset, read_len, buf);
+		if (ret == 0) {
+			/* We shouldn't see 0-length reads */
+			ret = -EIO;
+			goto read_err;
+		}
+		if (ret < 0)
+			goto read_err;
+
+		if (is_ofst_odd == true) {
+			memmove(buf, (buf + 1), (len - 1));
+			*retlen += (ret - 1);
+			buf += ret - 1;
+			is_ofst_odd = false;
+		} else {
+			*retlen += ret;
+			buf += ret;
+		}
+		from += ret;
+		len -= ret;
+	}
+	ret = 0;
+
+read_err:
+#if CONFIG_IS_ENABLED(SPI_FLASH_BAR)
+	ret = clean_bar(nor);
+#endif
+	return ret;
+}
+
+static int spi_nor_write(struct mtd_info *mtd, loff_t to, size_t len,
+	size_t *retlen, const u_char *buf)
+{
+	struct spi_nor *nor = mtd_to_spi_nor(mtd);
+	size_t page_offset, page_remain, i;
+	ssize_t ret;
+	u32 offset;
+
+#ifdef CONFIG_SPI_FLASH_SST
+	/* sst nor chips use AAI word program */
+	if (nor->info->flags & SST_WRITE)
+		return sst_write(mtd, to, len, retlen, buf);
+#endif
+
+	dev_dbg(nor->dev, "to 0x%08x, len %zd\n", (u32)to, len);
+
+	if (!len)
+		return 0;
+
+	/*
+	 * Cannot write to odd offset in parallel mode,
+	 * so write 2 bytes first
+	 */
+	if ((nor->flags & SNOR_F_HAS_PARALLEL) && (to & 1)) {
+		u8 two[2] = {0xff, buf[0]};
+		size_t local_retlen;
+
+		ret = spi_nor_write(mtd, to & ~1, 2, &local_retlen, two);
+		if (ret < 0)
+			return ret;
+
+		*retlen += 1; /* We've written only one actual byte */
+		buf++;
+		len--;
+		to++;
+	}
+
+	for (i = 0; i < len; ) {
+		ssize_t written;
+		loff_t addr = to + i;
+		schedule();
+
+		/*
+		 * If page_size is a power of two, the offset can be quickly
+		 * calculated with an AND operation. On the other cases we
+		 * need to do a modulus operation (more expensive).
+		 */
+		if (is_power_of_2(nor->page_size)) {
+			page_offset = addr & (nor->page_size - 1);
+		} else {
+			u64 aux = addr;
+
+			page_offset = do_div(aux, nor->page_size);
+		}
+		offset = to + i;
+		if (nor->flags & SNOR_F_HAS_PARALLEL)
+			offset /= 2;
+
+		if (nor->flags & SNOR_F_HAS_STACKED) {
+			if (offset >= (mtd->size / 2)) {
+				offset = offset - (mtd->size / 2);
+				nor->spi->flags |= SPI_XFER_U_PAGE;
+			} else {
+				nor->spi->flags &= ~SPI_XFER_U_PAGE;
+			}
+		}
+
+#if CONFIG_IS_ENABLED(SPI_FLASH_BAR)
+		ret = write_bar(nor, offset);
+		if (ret < 0)
+			return ret;
+#endif
+
+		/* the size of data remaining on the first page */
+		page_remain = min_t(size_t,
+				    nor->page_size - page_offset, len - i);
+
+		write_enable(nor);
+		/*
+		 * On DTR capable flashes like Micron Xcella the writes cannot
+		 * start or end at an odd address in DTR mode. So we need to
+		 * append or prepend extra 0xff bytes to make sure the start
+		 * address and end address are even.
+		 */
+		if (spi_nor_protocol_is_dtr(nor->write_proto) &&
+		    ((offset | page_remain) & 1)) {
+			u_char *tmp;
+			size_t extra_bytes = 0;
+
+			tmp = kmalloc(nor->page_size, 0);
+			if (!tmp) {
+				ret = -ENOMEM;
+				goto write_err;
+			}
+
+			/* Prepend a 0xff byte if the start address is odd. */
+			if (offset & 1) {
+				tmp[0] = 0xff;
+				memcpy(tmp + 1, buf + i, page_remain);
+				offset--;
+				page_remain++;
+				extra_bytes++;
+			} else {
+				memcpy(tmp, buf + i, page_remain);
+			}
+
+			/* Append a 0xff byte if the end address is odd. */
+			if ((offset + page_remain) & 1) {
+				tmp[page_remain + extra_bytes] = 0xff;
+				extra_bytes++;
+				page_remain++;
+			}
+
+			ret = nor->write(nor, offset, page_remain, tmp);
+
+			kfree(tmp);
+
+			if (ret < 0)
+				goto write_err;
+
+			/*
+			 * We write extra bytes but they are not part of the
+			 * original write.
+			 */
+			written = ret - extra_bytes;
+		} else {
+			ret = nor->write(nor, offset, page_remain, buf + i);
+			if (ret < 0)
+				goto write_err;
+			written = ret;
+		}
+
+		ret = spi_nor_wait_till_ready(nor);
+		if (ret)
+			goto write_err;
+
+		*retlen += written;
+		i += written;
+	}
+
+write_err:
+#if CONFIG_IS_ENABLED(SPI_FLASH_BAR)
+	ret = clean_bar(nor);
+#endif
+	return ret;
+}
+
+int spi_nor_stacked_post_init_fixups(struct spi_nor *nor)
+{
+	struct mtd_info *mtd = &nor->mtd;
+	int ret;
+
+#if CONFIG_IS_ENABLED(DM_SPI)
+	u64 flash_size[SNOR_FLASH_CNT_MAX] = { 0 };
+	struct udevice *dev = nor->spi->dev;
+	u32 idx = 0, i = 0;
+	int rc;
+
+	while (i < SNOR_FLASH_CNT_MAX) {
+		rc = ofnode_read_u64_index(dev_ofnode(dev), "stacked-memories",
+					   idx, &flash_size[i]);
+		if (rc == -EINVAL) {
+			break;
+		} else if (rc == -EOVERFLOW) {
+			idx++;
+		} else {
+			idx++;
+			i++;
+			if (!(nor->flags & SNOR_F_HAS_STACKED))
+				nor->flags |= SNOR_F_HAS_STACKED;
+			if (!(nor->spi->flags & SPI_XFER_STACKED))
+				nor->spi->flags |= SPI_XFER_STACKED;
+		}
+	}
+
+	if (nor->flags & (SNOR_F_HAS_STACKED | SNOR_F_HAS_PARALLEL)) {
+		mtd->size = 0;
+		for (idx = 0; idx < SNOR_FLASH_CNT_MAX; idx++)
+			mtd->size += flash_size[idx];
+	}
+#endif
+
+	if (nor->flags & SNOR_F_HAS_STACKED) {
+		nor->spi->flags |= SPI_XFER_U_PAGE;
+		ret = spi_nor_init(nor);
+		if (ret)
+			return ret;
+		nor->spi->flags &= ~SPI_XFER_U_PAGE;
+	}
+
+	if (nor->flags & SNOR_F_HAS_STACKED) {
+		mtd->_erase = spi_nor_erase;
+		mtd->_read = spi_nor_read;
+		mtd->_write = spi_nor_write;
+	}
+
+	return 0;
+}

-- 
2.34.1

