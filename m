From: Takahiro Kuwano <takahiro.kuwano@infineon.com>
Date: Fri, 12 Jun 2026 14:40:52 +0900
Subject: [PATCH 4/4] mtd: spi-nor: move fixups to manufacturer drivers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260612-split-id-table-into-vendor-files-v1-4-dfaaa82cc6f0@infineon.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781242882; l=61081;
 i=takahiro.kuwano@infineon.com; s=20250227; h=from:subject:message-id;
 bh=m9hERdxUE3ocFl1pZYoTnGoizQYGhmSCubz3DcxmDgA=;
 b=kksYXz7nUxSV/BjLFziPsJz801Ju8SsjQzQc6ZxrUVWVEd2mEsyvlbBKHwaVNG6hhJQwXtH8o
 hE27L8qmEXYB04+VVGYXGyYukjL0zQfOc4wfyAEJQjpW+ulgyKq8v9g
X-Developer-Key: i=takahiro.kuwano@infineon.com; a=ed25519;
 pk=aS8V9WLuMUkl0vmgD0xJU19ZajdJmuyFBnBfVj0dfDs=
X-Endpoint-Received: by B4 Relay for takahiro.kuwano@infineon.com/20250227 with auth_id=566
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move chip specific fixups from core to manufacturer drivers.
As manufacturer drivers are used in tiny as well, all fixups migrated
from core need to be excluded in CONFIG_SPI_FLASH_TINY.

Some helper functions used in fixups are exposed from core and some need
to be guarded by CONFIG_SPI_FLASH_TINY to avoid name conflict with local
functions in tiny.

Signed-off-by: Takahiro Kuwano <takahiro.kuwano@infineon.com>
---
 drivers/mtd/spi/macronix.c     |  89 ++++
 drivers/mtd/spi/micron-st.c    |  99 +++++
 drivers/mtd/spi/sf_internal.h  |  10 +
 drivers/mtd/spi/spansion.c     | 627 +++++++++++++++++++++++++++
 drivers/mtd/spi/spi-nor-core.c | 929 +----------------------------------------
 drivers/mtd/spi/winbond.c      | 104 +++++
 6 files changed, 938 insertions(+), 920 deletions(-)

diff --git a/drivers/mtd/spi/macronix.c b/drivers/mtd/spi/macronix.c
index 87843978cad..9ca55fc4f99 100644
--- a/drivers/mtd/spi/macronix.c
+++ b/drivers/mtd/spi/macronix.c
@@ -5,6 +5,7 @@
  * Copyright (C) 2018 Texas Instruments Incorporated - https://www.ti.com/
  */
 
+#include <dm/device_compat.h>
 #include <linux/mtd/spi-nor.h>
 #include "sf_internal.h"
 
@@ -59,7 +60,95 @@ static const struct flash_info macronix_nor_parts[] = {
 	{ INFO("mx25uw6345g",    0xc28437, 0, 64 * 1024, 128, SECT_4K | SPI_NOR_OCTAL_DTR_READ | SPI_NOR_4B_OPCODES) },
 };
 
+#if !CONFIG_IS_ENABLED(SPI_FLASH_TINY)
+/**
+ * spi_nor_macronix_octal_dtr_enable() - Enable octal DTR on Macronix flashes.
+ * @nor:	pointer to a 'struct spi_nor'
+ *
+ * Set Macronix max dummy cycles 20 to allow the flash to run at fastest frequency.
+ *
+ * Return: 0 on success, -errno otherwise.
+ */
+static int spi_nor_macronix_octal_dtr_enable(struct spi_nor *nor)
+{
+	struct spi_mem_op op;
+	int ret;
+	u8 buf;
+
+	ret = write_enable(nor);
+	if (ret)
+		return ret;
+
+	buf = SPINOR_REG_MXIC_DC_20;
+	op = (struct spi_mem_op)
+		SPI_MEM_OP(SPI_MEM_OP_CMD(SPINOR_OP_WR_CR2, 1),
+			   SPI_MEM_OP_ADDR(4, SPINOR_REG_MXIC_CR2_DC, 1),
+			   SPI_MEM_OP_NO_DUMMY,
+			   SPI_MEM_OP_DATA_OUT(1, &buf, 1));
+
+	ret = spi_mem_exec_op(nor->spi, &op);
+	if (ret)
+		return ret;
+
+	ret = spi_nor_wait_till_ready(nor);
+	if (ret)
+		return ret;
+
+	nor->read_dummy = MXIC_MAX_DC;
+	ret = write_enable(nor);
+	if (ret)
+		return ret;
+
+	buf = SPINOR_REG_MXIC_OPI_DTR_EN;
+	op = (struct spi_mem_op)
+		SPI_MEM_OP(SPI_MEM_OP_CMD(SPINOR_OP_WR_CR2, 1),
+			   SPI_MEM_OP_ADDR(4, SPINOR_REG_MXIC_CR2_MODE, 1),
+			   SPI_MEM_OP_NO_DUMMY,
+			   SPI_MEM_OP_DATA_OUT(1, &buf, 1));
+
+	ret = spi_mem_exec_op(nor->spi, &op);
+	if (ret) {
+		dev_err(nor->dev, "Failed to enable octal DTR mode\n");
+		return ret;
+	}
+	nor->reg_proto = SNOR_PROTO_8_8_8_DTR;
+
+	return 0;
+}
+
+static void macronix_octal_late_init(struct spi_nor *nor,
+				     struct spi_nor_flash_parameter *params)
+{
+	nor->octal_dtr_enable = spi_nor_macronix_octal_dtr_enable;
+}
+
+static void macronix_octal_post_sfdp_fixup(struct spi_nor *nor,
+					 struct spi_nor_flash_parameter *params)
+{
+	/*
+	 * Adding SNOR_HWCAPS_PP_8_8_8_DTR in hwcaps.mask when
+	 * SPI_NOR_OCTAL_DTR_READ flag exists.
+	 */
+	if (params->hwcaps.mask & SNOR_HWCAPS_READ_8_8_8_DTR)
+		params->hwcaps.mask |= SNOR_HWCAPS_PP_8_8_8_DTR;
+}
+
+static struct spi_nor_fixups macronix_octal_fixups = {
+	.post_sfdp = macronix_octal_post_sfdp_fixup,
+	.late_init = macronix_octal_late_init,
+};
+
+static void macronix_set_fixups(struct spi_nor *nor)
+{
+	if (nor->info->flags & SPI_NOR_OCTAL_DTR_READ)
+		nor->fixups = &macronix_octal_fixups;
+}
+#endif
+
 const struct spi_nor_manufacturer spi_nor_macronix = {
 	.parts = macronix_nor_parts,
 	.nparts = ARRAY_SIZE(macronix_nor_parts),
+#if !CONFIG_IS_ENABLED(SPI_FLASH_TINY)
+	.set_fixups = macronix_set_fixups,
+#endif
 };
diff --git a/drivers/mtd/spi/micron-st.c b/drivers/mtd/spi/micron-st.c
index 2d47f1c60c0..9982e9d660a 100644
--- a/drivers/mtd/spi/micron-st.c
+++ b/drivers/mtd/spi/micron-st.c
@@ -5,6 +5,7 @@
  * Copyright (C) 2018 Texas Instruments Incorporated - https://www.ti.com/
  */
 
+#include <dm/device_compat.h>
 #include <linux/mtd/spi-nor.h>
 #include "sf_internal.h"
 
@@ -59,9 +60,107 @@ static const struct flash_info st_nor_parts[] = {
 	{ INFO("m25px64",    0x207117,  0, 64 * 1024, 128, 0) },
 };
 
+#if !CONFIG_IS_ENABLED(SPI_FLASH_TINY) && CONFIG_IS_ENABLED(SPI_FLASH_MT35XU)
+static int spi_nor_micron_octal_dtr_enable(struct spi_nor *nor)
+{
+	struct spi_mem_op op;
+	u8 buf;
+	u8 addr_width = 3;
+	int ret;
+
+	/* Set dummy cycles for Fast Read to the default of 20. */
+	ret = write_enable(nor);
+	if (ret)
+		return ret;
+
+	buf = 20;
+	op = (struct spi_mem_op)
+		SPI_MEM_OP(SPI_MEM_OP_CMD(SPINOR_OP_MT_WR_ANY_REG, 1),
+			   SPI_MEM_OP_ADDR(addr_width, SPINOR_REG_MT_CFR1V, 1),
+			   SPI_MEM_OP_NO_DUMMY,
+			   SPI_MEM_OP_DATA_OUT(1, &buf, 1));
+	ret = spi_mem_exec_op(nor->spi, &op);
+	if (ret)
+		return ret;
+
+	ret = spi_nor_wait_till_ready(nor);
+	if (ret)
+		return ret;
+
+	nor->read_dummy = 20;
+
+	ret = write_enable(nor);
+	if (ret)
+		return ret;
+
+	buf = SPINOR_MT_OCT_DTR;
+	op = (struct spi_mem_op)
+		SPI_MEM_OP(SPI_MEM_OP_CMD(SPINOR_OP_MT_WR_ANY_REG, 1),
+			   SPI_MEM_OP_ADDR(addr_width, SPINOR_REG_MT_CFR0V, 1),
+			   SPI_MEM_OP_NO_DUMMY,
+			   SPI_MEM_OP_DATA_OUT(1, &buf, 1));
+	ret = spi_mem_exec_op(nor->spi, &op);
+	if (ret) {
+		dev_err(nor->dev, "Failed to enable octal DTR mode\n");
+		return ret;
+	}
+
+	return 0;
+}
+
+static void mt35xu512aba_late_init(struct spi_nor *nor,
+				   struct spi_nor_flash_parameter *params)
+{
+	nor->octal_dtr_enable = spi_nor_micron_octal_dtr_enable;
+}
+
+static void mt35xu512aba_post_sfdp_fixup(struct spi_nor *nor,
+					 struct spi_nor_flash_parameter *params)
+{
+	/* Set the Fast Read settings. */
+	params->hwcaps.mask |= SNOR_HWCAPS_READ_8_8_8_DTR;
+	spi_nor_set_read_settings(&params->reads[SNOR_CMD_READ_8_8_8_DTR],
+				  0, 20, SPINOR_OP_MT_DTR_RD,
+				  SNOR_PROTO_8_8_8_DTR);
+
+	params->hwcaps.mask |= SNOR_HWCAPS_PP_8_8_8_DTR;
+
+	nor->cmd_ext_type = SPI_NOR_EXT_REPEAT;
+	params->rdsr_dummy = 8;
+	params->rdsr_addr_nbytes = 0;
+
+	/*
+	 * SCCR Map 22nd DWORD does not indicate DTR Octal Mode Enable
+	 * for MT35XU512ABA but is actually supported by device.
+	 */
+	nor->flags |= SNOR_F_IO_MODE_EN_VOLATILE;
+
+	/*
+	 * The BFPT quad enable field is set to a reserved value so the quad
+	 * enable function is ignored by spi_nor_parse_bfpt(). Make sure we
+	 * disable it.
+	 */
+	params->quad_enable = NULL;
+}
+
+static struct spi_nor_fixups mt35xu512aba_fixups = {
+	.post_sfdp = mt35xu512aba_post_sfdp_fixup,
+	.late_init = mt35xu512aba_late_init,
+};
+
+static void micron_set_fixups(struct spi_nor *nor)
+{
+	if (!strcmp(nor->info->name, "mt35xu512aba"))
+		nor->fixups = &mt35xu512aba_fixups;
+}
+#endif
+
 const struct spi_nor_manufacturer spi_nor_micron = {
 	.parts = micron_nor_parts,
 	.nparts = ARRAY_SIZE(micron_nor_parts),
+#if !CONFIG_IS_ENABLED(SPI_FLASH_TINY) && CONFIG_IS_ENABLED(SPI_FLASH_MT35XU)
+	.set_fixups = micron_set_fixups,
+#endif
 };
 
 const struct spi_nor_manufacturer spi_nor_st = {
diff --git a/drivers/mtd/spi/sf_internal.h b/drivers/mtd/spi/sf_internal.h
index 941729f5707..0ea19913701 100644
--- a/drivers/mtd/spi/sf_internal.h
+++ b/drivers/mtd/spi/sf_internal.h
@@ -202,6 +202,12 @@ static inline int spi_nor_parse_sfdp(struct spi_nor *nor,
 #endif
 
 #if !CONFIG_IS_ENABLED(SPI_FLASH_TINY)
+int write_enable(struct spi_nor *nor);
+int set_4byte(struct spi_nor *nor, const struct flash_info *info, int enable);
+int spi_nor_sr_ready(struct spi_nor *nor);
+int spi_nor_wait_till_ready(struct spi_nor *nor);
+int spi_nor_read_write_reg(struct spi_nor *nor, struct spi_mem_op *op,
+			   void *buf);
 void spi_nor_set_read_settings(struct spi_nor_read_command *read,
 			       u8 num_mode_clocks,
 			       u8 num_wait_states,
@@ -211,6 +217,10 @@ int spansion_read_cr_quad_enable(struct spi_nor *nor);
 int macronix_quad_enable(struct spi_nor *nor);
 #endif
 
+void spi_nor_set_pp_settings(struct spi_nor_pp_command *pp, u8 opcode,
+			     enum spi_nor_protocol proto);
+int spi_nor_default_setup(struct spi_nor *nor, const struct flash_info *info,
+			  const struct spi_nor_flash_parameter *params);
 int spi_nor_hwcaps_read2cmd(u32 hwcaps);
 int spansion_no_read_cr_quad_enable(struct spi_nor *nor);
 
diff --git a/drivers/mtd/spi/spansion.c b/drivers/mtd/spi/spansion.c
index 405f5bf5e79..1dd38667062 100644
--- a/drivers/mtd/spi/spansion.c
+++ b/drivers/mtd/spi/spansion.c
@@ -5,6 +5,8 @@
  * Copyright (C) 2018 Texas Instruments Incorporated - https://www.ti.com/
  */
 
+#include <dm/device_compat.h>
+#include <linux/sizes.h>
 #include <linux/mtd/spi-nor.h>
 #include "sf_internal.h"
 
@@ -67,7 +69,632 @@ static const struct flash_info spansion_nor_parts[] = {
 #endif
 };
 
+#if !CONFIG_IS_ENABLED(SPI_FLASH_TINY)
+
+/* Use ID byte 4 to distinguish S25FS256T and S25Hx-T */
+#define S25FS256T_ID4	(0x08)
+
+/* Number of dummy cycle for Read Any Register (RDAR) op. */
+#define S25FS_S_RDAR_DUMMY	8
+
+static int spansion_read_any_reg(struct spi_nor *nor, u32 addr, u8 dummy,
+				 u8 *val)
+{
+	struct spi_mem_op op =
+		SPI_MEM_OP(SPI_MEM_OP_CMD(SPINOR_OP_RD_ANY_REG, 0),
+			   SPI_MEM_OP_ADDR(nor->addr_mode_nbytes, addr, 0),
+			   SPI_MEM_OP_DUMMY(dummy, 0),
+			   SPI_MEM_OP_DATA_IN(1, NULL, 0));
+	u8 buf[2];
+	int ret;
+
+	spi_nor_setup_op(nor, &op, nor->reg_proto);
+
+	/*
+	 * In Octal DTR mode, the number of address bytes is always 4 regardless
+	 * of addressing mode setting.
+	 */
+	if (nor->reg_proto == SNOR_PROTO_8_8_8_DTR)
+		op.addr.nbytes = 4;
+
+	/*
+	 * We don't want to read only one byte in DTR mode. So, read 2 and then
+	 * discard the second byte.
+	 */
+	if (spi_nor_protocol_is_dtr(nor->reg_proto))
+		op.data.nbytes = 2;
+
+	ret = spi_nor_read_write_reg(nor, &op, buf);
+	if (ret)
+		return ret;
+
+	*val = buf[0];
+
+	return 0;
+}
+
+static int spansion_write_any_reg(struct spi_nor *nor, u32 addr, u8 val)
+{
+	struct spi_mem_op op =
+		SPI_MEM_OP(SPI_MEM_OP_CMD(SPINOR_OP_WR_ANY_REG, 1),
+			   SPI_MEM_OP_ADDR(nor->addr_mode_nbytes, addr, 1),
+			   SPI_MEM_OP_NO_DUMMY,
+			   SPI_MEM_OP_DATA_OUT(1, NULL, 1));
+
+	return spi_nor_read_write_reg(nor, &op, &val);
+}
+
+/**
+ * spansion_quad_enable_volatile() - enable Quad I/O mode in volatile register.
+ * @nor:	pointer to a 'struct spi_nor'
+ * @addr_base:	base address of register (can be >0 in multi-die parts)
+ * @dummy:	number of dummy cycles for register read
+ *
+ * It is recommended to update volatile registers in the field application due
+ * to a risk of the non-volatile registers corruption by power interrupt. This
+ * function sets Quad Enable bit in CFR1 volatile.
+ *
+ * Return: 0 on success, -errno otherwise.
+ */
+static int spansion_quad_enable_volatile(struct spi_nor *nor, u32 addr_base,
+					 u8 dummy)
+{
+	u32 addr = addr_base + SPINOR_REG_CYPRESS_CFR1V;
+
+	u8 cr;
+	int ret;
+
+	/* Check current Quad Enable bit value. */
+	ret = spansion_read_any_reg(nor, addr, dummy, &cr);
+	if (ret < 0) {
+		dev_dbg(nor->dev,
+			"error while reading configuration register\n");
+		return -EINVAL;
+	}
+
+	if (cr & CR_QUAD_EN_SPAN)
+		return 0;
+
+	cr |= CR_QUAD_EN_SPAN;
+
+	write_enable(nor);
+
+	ret = spansion_write_any_reg(nor, addr, cr);
+
+	if (ret < 0) {
+		dev_dbg(nor->dev,
+			"error while writing configuration register\n");
+		return -EINVAL;
+	}
+
+	/* Read back and check it. */
+	ret = spansion_read_any_reg(nor, addr, dummy, &cr);
+	if (ret || !(cr & CR_QUAD_EN_SPAN)) {
+		dev_dbg(nor->dev, "Spansion Quad bit not set\n");
+		return -EINVAL;
+	}
+
+	return 0;
+}
+
+/*
+ * Read status register 1 by using Read Any Register command to support multi
+ * die package parts.
+ */
+static int spansion_sr_ready(struct spi_nor *nor, u32 addr_base, u8 dummy)
+{
+	u32 reg_addr = addr_base + SPINOR_REG_CYPRESS_STR1V;
+	u8 sr;
+	int ret;
+
+	ret = spansion_read_any_reg(nor, reg_addr, dummy, &sr);
+	if (ret < 0)
+		return ret;
+
+	if (sr & (SR_E_ERR | SR_P_ERR)) {
+		if (sr & SR_E_ERR)
+			dev_dbg(nor->dev, "Erase Error occurred\n");
+		else
+			dev_dbg(nor->dev, "Programming Error occurred\n");
+
+		nor->write_reg(nor, SPINOR_OP_CYPRESS_CLPEF, NULL, 0);
+		return -EIO;
+	}
+
+	return !(sr & SR_WIP);
+}
+
+/**
+ * spansion_erase_non_uniform() - erase non-uniform sectors for Spansion/Cypress
+ *                                chips
+ * @nor:	pointer to a 'struct spi_nor'
+ * @addr:	address of the sector to erase
+ * @opcode_4k:	opcode for 4K sector erase
+ * @ovlsz_top:	size of overlaid portion at the top address
+ * @ovlsz_btm:	size of overlaid portion at the bottom address
+ *
+ * Erase an address range on the nor chip that can contain 4KB sectors overlaid
+ * on top and/or bottom. The appropriate erase opcode and size are chosen by
+ * address to erase and size of overlaid portion.
+ *
+ * Return: number of bytes erased on success, -errno otherwise.
+ */
+static int spansion_erase_non_uniform(struct spi_nor *nor, u32 addr,
+				      u8 opcode_4k, u32 ovlsz_top,
+				      u32 ovlsz_btm)
+{
+	struct spi_mem_op op =
+		SPI_MEM_OP(SPI_MEM_OP_CMD(nor->erase_opcode, 0),
+			   SPI_MEM_OP_ADDR(nor->addr_width, addr, 0),
+			   SPI_MEM_OP_NO_DUMMY,
+			   SPI_MEM_OP_NO_DATA);
+	struct mtd_info *mtd = &nor->mtd;
+	u32 erasesize;
+	int ret;
+
+	/* 4KB sectors */
+	if (op.addr.val < ovlsz_btm ||
+	    op.addr.val >= mtd->size - ovlsz_top) {
+		op.cmd.opcode = opcode_4k;
+		erasesize = SZ_4K;
+
+	/* Non-overlaid portion in the normal sector at the bottom */
+	} else if (op.addr.val == ovlsz_btm) {
+		op.cmd.opcode = nor->erase_opcode;
+		erasesize = mtd->erasesize - ovlsz_btm;
+
+	/* Non-overlaid portion in the normal sector at the top */
+	} else if (op.addr.val == mtd->size - mtd->erasesize) {
+		op.cmd.opcode = nor->erase_opcode;
+		erasesize = mtd->erasesize - ovlsz_top;
+
+	/* Normal sectors */
+	} else {
+		op.cmd.opcode = nor->erase_opcode;
+		erasesize = mtd->erasesize;
+	}
+
+	spi_nor_setup_op(nor, &op, nor->write_proto);
+
+	ret = spi_mem_exec_op(nor->spi, &op);
+	if (ret)
+		return ret;
+
+	return erasesize;
+}
+
+static int s25fs_s_quad_enable(struct spi_nor *nor)
+{
+	return spansion_quad_enable_volatile(nor, 0, S25FS_S_RDAR_DUMMY);
+}
+
+static int s25fs_s_erase_non_uniform(struct spi_nor *nor, loff_t addr)
+{
+	u8 opcode = nor->addr_width == 4 ? SPINOR_OP_BE_4K_4B : SPINOR_OP_BE_4K;
+
+	/* Support 8 x 4KB sectors at bottom */
+	return spansion_erase_non_uniform(nor, addr, opcode, 0, SZ_32K);
+}
+
+static int s25fs_s_setup(struct spi_nor *nor, const struct flash_info *info,
+			 const struct spi_nor_flash_parameter *params)
+{
+	int ret;
+	u8 cfr3v;
+
+	/* Bank Address Register is not supported */
+	if (CONFIG_IS_ENABLED(SPI_FLASH_BAR))
+		return -EOPNOTSUPP;
+
+	/*
+	 * Read CR3V to check if uniform sector is selected. If not, assign an
+	 * erase hook that supports non-uniform erase.
+	 */
+	ret = spansion_read_any_reg(nor, SPINOR_REG_CYPRESS_CFR3V,
+				    S25FS_S_RDAR_DUMMY, &cfr3v);
+	if (ret)
+		return ret;
+	if (!(cfr3v & SPINOR_REG_CYPRESS_CFR3_UNISECT))
+		nor->erase = s25fs_s_erase_non_uniform;
+
+	return spi_nor_default_setup(nor, info, params);
+}
+
+static void s25fs_s_late_init(struct spi_nor *nor,
+			      struct spi_nor_flash_parameter *params)
+{
+	nor->setup = s25fs_s_setup;
+}
+
+static int s25fs_s_post_bfpt_fixup(struct spi_nor *nor,
+				   const struct sfdp_parameter_header *header,
+				   const struct sfdp_bfpt *bfpt,
+				   struct spi_nor_flash_parameter *params)
+{
+	/* The erase size is set to 4K from BFPT, but it's wrong. Fix it. */
+	nor->erase_opcode = SPINOR_OP_SE;
+	nor->mtd.erasesize = nor->info->sector_size;
+
+	/* The S25FS-S chip family reports 512-byte pages in BFPT but
+	 * in reality the write buffer still wraps at the safe default
+	 * of 256 bytes.  Overwrite the page size advertised by BFPT
+	 * to get the writes working.
+	 */
+	params->page_size = 256;
+
+	return 0;
+}
+
+static void s25fs_s_post_sfdp_fixup(struct spi_nor *nor,
+				    struct spi_nor_flash_parameter *params)
+{
+	/*
+	 * The S25FS064S(8MB) supports 1-1-2 and 1-1-4 commands, but params for
+	 * read ops in SFDP are wrong. The other density parts do not support
+	 * 1-1-2 and 1-1-4 commands.
+	 */
+	if (params->size == SZ_8M) {
+		spi_nor_set_read_settings(&params->reads[SNOR_CMD_READ_1_1_2],
+					  0, 8, SPINOR_OP_READ_1_1_2,
+					  SNOR_PROTO_1_1_2);
+		spi_nor_set_read_settings(&params->reads[SNOR_CMD_READ_1_1_4],
+					  0, 8, SPINOR_OP_READ_1_1_4,
+					  SNOR_PROTO_1_1_4);
+	} else {
+		params->hwcaps.mask &= ~SNOR_HWCAPS_READ_1_1_2;
+		params->hwcaps.mask &= ~SNOR_HWCAPS_READ_1_1_4;
+		params->hwcaps.mask &= ~SNOR_HWCAPS_PP_1_1_4;
+	}
+
+	/* Use volatile register to enable quad */
+	params->quad_enable = s25fs_s_quad_enable;
+}
+
+static struct spi_nor_fixups s25fs_s_fixups = {
+	.post_bfpt = s25fs_s_post_bfpt_fixup,
+	.post_sfdp = s25fs_s_post_sfdp_fixup,
+	.late_init = s25fs_s_late_init,
+};
+
+static int s25_s28_mdp_ready(struct spi_nor *nor)
+{
+	u32 addr;
+	int ret;
+
+	for (addr = 0; addr < nor->mtd.size; addr += SZ_128M) {
+		ret = spansion_sr_ready(nor, addr, nor->rdsr_dummy);
+		if (ret < 0)
+			return ret;
+		else if (ret == 0)
+			return 0;
+	}
+
+	return 1;
+}
+
+static int s25_quad_enable(struct spi_nor *nor)
+{
+	u32 addr;
+	int ret;
+
+	for (addr = 0; addr < nor->mtd.size; addr += SZ_128M) {
+		ret = spansion_quad_enable_volatile(nor, addr, 0);
+		if (ret)
+			return ret;
+	}
+
+	return 0;
+}
+
+static int s25_s28_erase_non_uniform(struct spi_nor *nor, loff_t addr)
+{
+	/* Support 32 x 4KB sectors at bottom */
+	return spansion_erase_non_uniform(nor, addr, SPINOR_OP_BE_4K_4B, 0,
+					  SZ_128K);
+}
+
+static int s25_s28_setup(struct spi_nor *nor, const struct flash_info *info,
+			 const struct spi_nor_flash_parameter *params)
+{
+	int ret;
+	u8 cr;
+
+#if CONFIG_IS_ENABLED(SPI_FLASH_BAR)
+	return -ENOTSUPP; /* Bank Address Register is not supported */
+#endif
+	/*
+	 * S25FS256T has multiple sector architecture options, with selection of
+	 * count and location of 128KB and 64KB sectors. This driver supports
+	 * uniform 128KB only due to complexity of non-uniform layout.
+	 */
+	if (nor->info->id[4] == S25FS256T_ID4) {
+		ret = spansion_read_any_reg(nor, SPINOR_REG_CYPRESS_ARCFN, 8,
+					    &cr);
+		if (ret)
+			return ret;
+
+		if (cr) /* Option 0 (ARCFN[7:0] == 0x00) is uniform */
+			return -EOPNOTSUPP;
+
+		return spi_nor_default_setup(nor, info, params);
+	}
+
+	/*
+	 * Read CFR3V to check if uniform sector is selected. If not, assign an
+	 * erase hook that supports non-uniform erase.
+	 */
+	ret = spansion_read_any_reg(nor, SPINOR_REG_CYPRESS_CFR3V, 0, &cr);
+	if (ret)
+		return ret;
+	if (!(cr & SPINOR_REG_CYPRESS_CFR3_UNISECT))
+		nor->erase = s25_s28_erase_non_uniform;
+
+	/*
+	 * For the multi-die package parts, the ready() hook is needed to check
+	 * all dies' status via read any register.
+	 */
+	if (nor->mtd.size > SZ_128M)
+		nor->ready = s25_s28_mdp_ready;
+
+	return spi_nor_default_setup(nor, info, params);
+}
+
+static void s25_late_init(struct spi_nor *nor,
+			  struct spi_nor_flash_parameter *params)
+{
+	nor->setup = s25_s28_setup;
+
+	/*
+	 * Programming is supported only in 16-byte ECC data unit granularity.
+	 * Byte-programming, bit-walking, or multiple program operations to the
+	 * same ECC data unit without an erase are not allowed.
+	 */
+	params->writesize = 16;
+}
+
+static int s25_s28_post_bfpt_fixup(struct spi_nor *nor,
+				   const struct sfdp_parameter_header *header,
+				   const struct sfdp_bfpt *bfpt,
+				   struct spi_nor_flash_parameter *params)
+{
+	int ret;
+	u32 addr;
+	u8 cfr3v;
+
+	/* erase size in case it is set to 4K from BFPT */
+	nor->erase_opcode = SPINOR_OP_SE_4B;
+	nor->mtd.erasesize = nor->info->sector_size;
+
+	/*
+	 * The default address mode in multi-die package parts (>1Gb) may be
+	 * 3- or 4-byte, depending on model number. BootROM code in some SoCs
+	 * use 3-byte mode for backward compatibility and should switch to
+	 * 4-byte mode after BootROM phase. Since registers in the 2nd die are
+	 * mapped within 32-bit address space, we need to make sure the flash is
+	 * in 4-byte address mode. The default address mode can be distinguished
+	 * by BFPT 16th DWORD. Power cycle exits 4-byte address mode if default
+	 * is 3-byte address mode.
+	 */
+	if (params->size > SZ_128M) {
+		if (bfpt->dwords[BFPT_DWORD(16)] & BFPT_DWORD16_EX4B_PWRCYC) {
+			ret = set_4byte(nor, nor->info, 1);
+			if (ret)
+				return ret;
+		}
+		nor->addr_mode_nbytes = 4;
+	}
+
+	/* The default address mode in S25FS256T is 4. */
+	if (nor->info->id[4] == S25FS256T_ID4)
+		nor->addr_mode_nbytes = 4;
+
+	/*
+	 * The page_size is set to 512B from BFPT, but it actually depends on
+	 * the configuration register. Look up the CFR3V and determine the
+	 * page_size. For multi-die package parts, use 512B only when the all
+	 * dies are configured to 512B buffer.
+	 */
+	for (addr = 0; addr < params->size; addr += SZ_128M) {
+		ret = spansion_read_any_reg(nor,
+					    addr + SPINOR_REG_CYPRESS_CFR3V, 0,
+					    &cfr3v);
+		if (ret)
+			return ret;
+
+		if (!(cfr3v & SPINOR_REG_CYPRESS_CFR3_PGSZ)) {
+			params->page_size = 256;
+			return 0;
+		}
+	}
+	params->page_size = 512;
+
+	return 0;
+}
+
+static void s25_post_sfdp_fixup(struct spi_nor *nor,
+				struct spi_nor_flash_parameter *params)
+{
+	if (nor->info->id[4] == S25FS256T_ID4) {
+		/* PP_1_1_4 is supported */
+		params->hwcaps.mask |= SNOR_HWCAPS_PP_1_1_4;
+	} else {
+		/* READ_FAST_4B (0Ch) requires mode cycles*/
+		params->reads[SNOR_CMD_READ_FAST].num_mode_clocks = 8;
+		/* PP_1_1_4 is not supported */
+		params->hwcaps.mask &= ~SNOR_HWCAPS_PP_1_1_4;
+		/* Use volatile register to enable quad */
+		params->quad_enable = s25_quad_enable;
+	}
+}
+
+static struct spi_nor_fixups s25_fixups = {
+	.post_bfpt = s25_s28_post_bfpt_fixup,
+	.post_sfdp = s25_post_sfdp_fixup,
+	.late_init = s25_late_init,
+};
+
+static int s25fl256l_setup(struct spi_nor *nor, const struct flash_info *info,
+			   const struct spi_nor_flash_parameter *params)
+{
+	return -ENOTSUPP; /* Bank Address Register is not supported */
+}
+
+static void s25fl256l_late_init(struct spi_nor *nor,
+				struct spi_nor_flash_parameter *params)
+{
+	nor->setup = s25fl256l_setup;
+}
+
+static struct spi_nor_fixups s25fl256l_fixups = {
+	.late_init = s25fl256l_late_init,
+};
+
+#ifdef CONFIG_SPI_FLASH_S28HX_T
+/**
+ * spi_nor_cypress_octal_dtr_enable() - Enable octal DTR on Cypress flashes.
+ * @nor:		pointer to a 'struct spi_nor'
+ *
+ * This also sets the memory access latency cycles to 24 to allow the flash to
+ * run at up to 200MHz.
+ *
+ * Return: 0 on success, -errno otherwise.
+ */
+static int spi_nor_cypress_octal_dtr_enable(struct spi_nor *nor)
+{
+	u32 addr;
+	u8 buf;
+	int ret;
+
+	ret = write_enable(nor);
+	if (ret)
+		return ret;
+
+	/* Use 24 dummy cycles for memory array reads. */
+	for (addr = 0; addr < nor->mtd.size; addr += SZ_128M) {
+		ret = spansion_read_any_reg(nor,
+					    addr + SPINOR_REG_CYPRESS_CFR2V, 0,
+					    &buf);
+		if (ret)
+			return ret;
+
+		buf &= ~SPINOR_REG_CYPRESS_CFR2_MEMLAT_MASK;
+		buf |= SPINOR_REG_CYPRESS_CFR2_MEMLAT_11_24;
+		ret = spansion_write_any_reg(nor,
+					     addr + SPINOR_REG_CYPRESS_CFR2V,
+					     buf);
+		if (ret) {
+			dev_warn(nor->dev, "failed to set default memory latency value: %d\n", ret);
+			return ret;
+		}
+	}
+	nor->read_dummy = 24;
+
+	ret = write_enable(nor);
+	if (ret)
+		return ret;
+
+	/* Set the octal and DTR enable bits. */
+	buf = SPINOR_REG_CYPRESS_CFR5_OCT_DTR_EN;
+	for (addr = 0; addr < nor->mtd.size; addr += SZ_128M) {
+		ret = spansion_write_any_reg(nor,
+					     addr + SPINOR_REG_CYPRESS_CFR5V,
+					     buf);
+		if (ret) {
+			dev_warn(nor->dev, "Failed to enable octal DTR mode\n");
+			return ret;
+		}
+	}
+
+	return 0;
+}
+
+static void s28hx_t_late_init(struct spi_nor *nor,
+			      struct spi_nor_flash_parameter *params)
+{
+	nor->octal_dtr_enable = spi_nor_cypress_octal_dtr_enable;
+	nor->setup = s25_s28_setup;
+
+	/*
+	 * Programming is supported only in 16-byte ECC data unit granularity.
+	 * Byte-programming, bit-walking, or multiple program operations to the
+	 * same ECC data unit without an erase are not allowed.
+	 */
+	params->writesize = 16;
+}
+
+static void s28hx_t_post_sfdp_fixup(struct spi_nor *nor,
+				    struct spi_nor_flash_parameter *params)
+{
+	/*
+	 * On older versions of the flash the xSPI Profile 1.0 table has the
+	 * 8D-8D-8D Fast Read opcode as 0x00. But it actually should be 0xEE.
+	 */
+	if (params->reads[SNOR_CMD_READ_8_8_8_DTR].opcode == 0)
+		params->reads[SNOR_CMD_READ_8_8_8_DTR].opcode =
+			SPINOR_OP_CYPRESS_RD_FAST;
+
+	params->hwcaps.mask |= SNOR_HWCAPS_PP_8_8_8_DTR;
+
+	/* This flash is also missing the 4-byte Page Program opcode bit. */
+	spi_nor_set_pp_settings(&params->page_programs[SNOR_CMD_PP],
+				SPINOR_OP_PP_4B, SNOR_PROTO_1_1_1);
+	/*
+	 * Since xSPI Page Program opcode is backward compatible with
+	 * Legacy SPI, use Legacy SPI opcode there as well.
+	 */
+	spi_nor_set_pp_settings(&params->page_programs[SNOR_CMD_PP_8_8_8_DTR],
+				SPINOR_OP_PP_4B, SNOR_PROTO_8_8_8_DTR);
+
+	/*
+	 * The xSPI Profile 1.0 table advertises the number of additional
+	 * address bytes needed for Read Status Register command as 0 but the
+	 * actual value for that is 4.
+	 */
+	params->rdsr_addr_nbytes = 4;
+}
+
+static struct spi_nor_fixups s28hx_t_fixups = {
+	.post_sfdp = s28hx_t_post_sfdp_fixup,
+	.post_bfpt = s25_s28_post_bfpt_fixup,
+	.late_init = s28hx_t_late_init,
+};
+#endif /* CONFIG_SPI_FLASH_S28HX_T */
+
+static void spansion_set_fixups(struct spi_nor *nor)
+{
+	if (JEDEC_MFR(nor->info) == SNOR_MFR_CYPRESS) {
+		switch (nor->info->id[1]) {
+		case 0x2a: /* S25HL (QSPI, 3.3V) */
+		case 0x2b: /* S25HS (QSPI, 1.8V) */
+			nor->fixups = &s25_fixups;
+			break;
+
+#ifdef CONFIG_SPI_FLASH_S28HX_T
+		case 0x5a: /* S28HL (Octal, 3.3V) */
+		case 0x5b: /* S28HS (Octal, 1.8V) */
+			nor->fixups = &s28hx_t_fixups;
+			break;
+#endif
+
+		default:
+			break;
+		}
+	}
+
+	if (CONFIG_IS_ENABLED(SPI_FLASH_BAR) &&
+	    !strcmp(nor->info->name, "s25fl256l"))
+		nor->fixups = &s25fl256l_fixups;
+
+	/* For FS-S (family ID = 0x81)  */
+	if (JEDEC_MFR(nor->info) == SNOR_MFR_SPANSION && nor->info->id[5] == 0x81)
+		nor->fixups = &s25fs_s_fixups;
+}
+#endif /* !CONFIG_IS_ENABLED(SPI_FLASH_TINY) */
+
 const struct spi_nor_manufacturer spi_nor_spansion = {
 	.parts = spansion_nor_parts,
 	.nparts = ARRAY_SIZE(spansion_nor_parts),
+#if !CONFIG_IS_ENABLED(SPI_FLASH_TINY)
+	.set_fixups = spansion_set_fixups,
+#endif
 };
diff --git a/drivers/mtd/spi/spi-nor-core.c b/drivers/mtd/spi/spi-nor-core.c
index d107828092c..6e61b5653bd 100644
--- a/drivers/mtd/spi/spi-nor-core.c
+++ b/drivers/mtd/spi/spi-nor-core.c
@@ -123,8 +123,8 @@ void spi_nor_setup_op(const struct spi_nor *nor,
 	}
 }
 
-static int spi_nor_read_write_reg(struct spi_nor *nor, struct spi_mem_op
-		*op, void *buf)
+int spi_nor_read_write_reg(struct spi_nor *nor, struct spi_mem_op *op,
+			   void *buf)
 {
 	if (op->data.dir == SPI_MEM_DATA_IN)
 		op->data.buf.in = buf;
@@ -165,55 +165,6 @@ static int spi_nor_write_reg(struct spi_nor *nor, u8 opcode, u8 *buf, int len)
 	return spi_nor_read_write_reg(nor, &op, buf);
 }
 
-#ifdef CONFIG_SPI_FLASH_SPANSION
-static int spansion_read_any_reg(struct spi_nor *nor, u32 addr, u8 dummy,
-				 u8 *val)
-{
-	struct spi_mem_op op =
-		SPI_MEM_OP(SPI_MEM_OP_CMD(SPINOR_OP_RD_ANY_REG, 0),
-			   SPI_MEM_OP_ADDR(nor->addr_mode_nbytes, addr, 0),
-			   SPI_MEM_OP_DUMMY(dummy, 0),
-			   SPI_MEM_OP_DATA_IN(1, NULL, 0));
-	u8 buf[2];
-	int ret;
-
-	spi_nor_setup_op(nor, &op, nor->reg_proto);
-
-	/*
-	 * In Octal DTR mode, the number of address bytes is always 4 regardless
-	 * of addressing mode setting.
-	 */
-	if (nor->reg_proto == SNOR_PROTO_8_8_8_DTR)
-		op.addr.nbytes = 4;
-
-	/*
-	 * We don't want to read only one byte in DTR mode. So, read 2 and then
-	 * discard the second byte.
-	 */
-	if (spi_nor_protocol_is_dtr(nor->reg_proto))
-		op.data.nbytes = 2;
-
-	ret = spi_nor_read_write_reg(nor, &op, buf);
-	if (ret)
-		return ret;
-
-	*val = buf[0];
-
-	return 0;
-}
-
-static int spansion_write_any_reg(struct spi_nor *nor, u32 addr, u8 val)
-{
-	struct spi_mem_op op =
-		SPI_MEM_OP(SPI_MEM_OP_CMD(SPINOR_OP_WR_ANY_REG, 1),
-			   SPI_MEM_OP_ADDR(nor->addr_mode_nbytes, addr, 1),
-			   SPI_MEM_OP_NO_DUMMY,
-			   SPI_MEM_OP_DATA_OUT(1, NULL, 1));
-
-	return spi_nor_read_write_reg(nor, &op, &val);
-}
-#endif
-
 static ssize_t spi_nor_read_data(struct spi_nor *nor, loff_t from, size_t len,
 				 u_char *buf)
 {
@@ -472,7 +423,7 @@ static int write_sr3(struct spi_nor *nor, u8 val)
  * Set write enable latch with Write Enable command.
  * Returns negative if error occurred.
  */
-static int write_enable(struct spi_nor *nor)
+int write_enable(struct spi_nor *nor)
 {
 	return nor->write_reg(nor, SPINOR_OP_WREN, NULL, 0);
 }
@@ -577,8 +528,7 @@ static void spi_nor_set_4byte_opcodes(struct spi_nor *nor,
 #endif /* !CONFIG_IS_ENABLED(SPI_FLASH_BAR) */
 
 /* Enable/disable 4-byte addressing mode. */
-static int set_4byte(struct spi_nor *nor, const struct flash_info *info,
-		     int enable)
+int set_4byte(struct spi_nor *nor, const struct flash_info *info, int enable)
 {
 	int status;
 	bool need_wren = false;
@@ -626,36 +576,7 @@ static int set_4byte(struct spi_nor *nor, const struct flash_info *info,
 	}
 }
 
-#ifdef CONFIG_SPI_FLASH_SPANSION
-/*
- * Read status register 1 by using Read Any Register command to support multi
- * die package parts.
- */
-static int spansion_sr_ready(struct spi_nor *nor, u32 addr_base, u8 dummy)
-{
-	u32 reg_addr = addr_base + SPINOR_REG_CYPRESS_STR1V;
-	u8 sr;
-	int ret;
-
-	ret = spansion_read_any_reg(nor, reg_addr, dummy, &sr);
-	if (ret < 0)
-		return ret;
-
-	if (sr & (SR_E_ERR | SR_P_ERR)) {
-		if (sr & SR_E_ERR)
-			dev_dbg(nor->dev, "Erase Error occurred\n");
-		else
-			dev_dbg(nor->dev, "Programming Error occurred\n");
-
-		nor->write_reg(nor, SPINOR_OP_CYPRESS_CLPEF, NULL, 0);
-		return -EIO;
-	}
-
-	return !(sr & SR_WIP);
-}
-#endif
-
-static int spi_nor_sr_ready(struct spi_nor *nor)
+int spi_nor_sr_ready(struct spi_nor *nor)
 {
 	int sr = read_sr(nor);
 
@@ -745,7 +666,7 @@ static int spi_nor_wait_till_ready_with_timeout(struct spi_nor *nor,
 	return -ETIMEDOUT;
 }
 
-static int spi_nor_wait_till_ready(struct spi_nor *nor)
+int spi_nor_wait_till_ready(struct spi_nor *nor)
 {
 	return spi_nor_wait_till_ready_with_timeout(nor,
 						    DEFAULT_READY_WAIT_JIFFIES);
@@ -1035,67 +956,6 @@ err:
 	return ret;
 }
 
-#ifdef CONFIG_SPI_FLASH_SPANSION
-/**
- * spansion_erase_non_uniform() - erase non-uniform sectors for Spansion/Cypress
- *                                chips
- * @nor:	pointer to a 'struct spi_nor'
- * @addr:	address of the sector to erase
- * @opcode_4k:	opcode for 4K sector erase
- * @ovlsz_top:	size of overlaid portion at the top address
- * @ovlsz_btm:	size of overlaid portion at the bottom address
- *
- * Erase an address range on the nor chip that can contain 4KB sectors overlaid
- * on top and/or bottom. The appropriate erase opcode and size are chosen by
- * address to erase and size of overlaid portion.
- *
- * Return: number of bytes erased on success, -errno otherwise.
- */
-static int spansion_erase_non_uniform(struct spi_nor *nor, u32 addr,
-				      u8 opcode_4k, u32 ovlsz_top,
-				      u32 ovlsz_btm)
-{
-	struct spi_mem_op op =
-		SPI_MEM_OP(SPI_MEM_OP_CMD(nor->erase_opcode, 0),
-			   SPI_MEM_OP_ADDR(nor->addr_width, addr, 0),
-			   SPI_MEM_OP_NO_DUMMY,
-			   SPI_MEM_OP_NO_DATA);
-	struct mtd_info *mtd = &nor->mtd;
-	u32 erasesize;
-	int ret;
-
-	/* 4KB sectors */
-	if (op.addr.val < ovlsz_btm ||
-	    op.addr.val >= mtd->size - ovlsz_top) {
-		op.cmd.opcode = opcode_4k;
-		erasesize = SZ_4K;
-
-	/* Non-overlaid portion in the normal sector at the bottom */
-	} else if (op.addr.val == ovlsz_btm) {
-		op.cmd.opcode = nor->erase_opcode;
-		erasesize = mtd->erasesize - ovlsz_btm;
-
-	/* Non-overlaid portion in the normal sector at the top */
-	} else if (op.addr.val == mtd->size - mtd->erasesize) {
-		op.cmd.opcode = nor->erase_opcode;
-		erasesize = mtd->erasesize - ovlsz_top;
-
-	/* Normal sectors */
-	} else {
-		op.cmd.opcode = nor->erase_opcode;
-		erasesize = mtd->erasesize;
-	}
-
-	spi_nor_setup_op(nor, &op, nor->write_proto);
-
-	ret = spi_mem_exec_op(nor->spi, &op);
-	if (ret)
-		return ret;
-
-	return erasesize;
-}
-#endif
-
 #if defined(CONFIG_SPI_FLASH_LOCK)
 #if defined(CONFIG_SPI_FLASH_STMICRO) || defined(CONFIG_SPI_FLASH_SST)
 /* Write status register and ensure bits in mask match written values */
@@ -1980,61 +1840,6 @@ int macronix_quad_enable(struct spi_nor *nor)
 }
 #endif
 
-#ifdef CONFIG_SPI_FLASH_SPANSION
-/**
- * spansion_quad_enable_volatile() - enable Quad I/O mode in volatile register.
- * @nor:	pointer to a 'struct spi_nor'
- * @addr_base:	base address of register (can be >0 in multi-die parts)
- * @dummy:	number of dummy cycles for register read
- *
- * It is recommended to update volatile registers in the field application due
- * to a risk of the non-volatile registers corruption by power interrupt. This
- * function sets Quad Enable bit in CFR1 volatile.
- *
- * Return: 0 on success, -errno otherwise.
- */
-static int spansion_quad_enable_volatile(struct spi_nor *nor, u32 addr_base,
-					 u8 dummy)
-{
-	u32 addr = addr_base + SPINOR_REG_CYPRESS_CFR1V;
-
-	u8 cr;
-	int ret;
-
-	/* Check current Quad Enable bit value. */
-	ret = spansion_read_any_reg(nor, addr, dummy, &cr);
-	if (ret < 0) {
-		dev_dbg(nor->dev,
-			"error while reading configuration register\n");
-		return -EINVAL;
-	}
-
-	if (cr & CR_QUAD_EN_SPAN)
-		return 0;
-
-	cr |= CR_QUAD_EN_SPAN;
-
-	write_enable(nor);
-
-	ret = spansion_write_any_reg(nor, addr, cr);
-
-	if (ret < 0) {
-		dev_dbg(nor->dev,
-			"error while writing configuration register\n");
-		return -EINVAL;
-	}
-
-	/* Read back and check it. */
-	ret = spansion_read_any_reg(nor, addr, dummy, &cr);
-	if (ret || !(cr & CR_QUAD_EN_SPAN)) {
-		dev_dbg(nor->dev, "Spansion Quad bit not set\n");
-		return -EINVAL;
-	}
-
-	return 0;
-}
-#endif
-
 #if defined(CONFIG_SPI_FLASH_SPANSION) || defined(CONFIG_SPI_FLASH_WINBOND)
 /*
  * Write status Register and configuration register with 2 bytes
@@ -2165,7 +1970,7 @@ spi_nor_set_read_settings(struct spi_nor_read_command *read,
 	read->proto = proto;
 }
 
-static void
+void
 spi_nor_set_pp_settings(struct spi_nor_pp_command *pp,
 			u8 opcode,
 			enum spi_nor_protocol proto)
@@ -2755,9 +2560,8 @@ static int spi_nor_select_erase(struct spi_nor *nor,
 	return 0;
 }
 
-static int spi_nor_default_setup(struct spi_nor *nor,
-				 const struct flash_info *info,
-				 const struct spi_nor_flash_parameter *params)
+int spi_nor_default_setup(struct spi_nor *nor, const struct flash_info *info,
+			  const struct spi_nor_flash_parameter *params)
 {
 	u32 shared_mask;
 	bool enable_quad_io;
@@ -2809,664 +2613,6 @@ static int spi_nor_setup(struct spi_nor *nor, const struct flash_info *info,
 	return nor->setup(nor, info, params);
 }
 
-#ifdef CONFIG_SPI_FLASH_SPANSION
-
-/* Use ID byte 4 to distinguish S25FS256T and S25Hx-T */
-#define S25FS256T_ID4	(0x08)
-
-/* Number of dummy cycle for Read Any Register (RDAR) op. */
-#define S25FS_S_RDAR_DUMMY	8
-
-static int s25fs_s_quad_enable(struct spi_nor *nor)
-{
-	return spansion_quad_enable_volatile(nor, 0, S25FS_S_RDAR_DUMMY);
-}
-
-static int s25fs_s_erase_non_uniform(struct spi_nor *nor, loff_t addr)
-{
-	u8 opcode = nor->addr_width == 4 ? SPINOR_OP_BE_4K_4B : SPINOR_OP_BE_4K;
-
-	/* Support 8 x 4KB sectors at bottom */
-	return spansion_erase_non_uniform(nor, addr, opcode, 0, SZ_32K);
-}
-
-static int s25fs_s_setup(struct spi_nor *nor, const struct flash_info *info,
-			 const struct spi_nor_flash_parameter *params)
-{
-	int ret;
-	u8 cfr3v;
-
-	/* Bank Address Register is not supported */
-	if (CONFIG_IS_ENABLED(SPI_FLASH_BAR))
-		return -EOPNOTSUPP;
-
-	/*
-	 * Read CR3V to check if uniform sector is selected. If not, assign an
-	 * erase hook that supports non-uniform erase.
-	 */
-	ret = spansion_read_any_reg(nor, SPINOR_REG_CYPRESS_CFR3V,
-				    S25FS_S_RDAR_DUMMY, &cfr3v);
-	if (ret)
-		return ret;
-	if (!(cfr3v & SPINOR_REG_CYPRESS_CFR3_UNISECT))
-		nor->erase = s25fs_s_erase_non_uniform;
-
-	return spi_nor_default_setup(nor, info, params);
-}
-
-static void s25fs_s_late_init(struct spi_nor *nor,
-			      struct spi_nor_flash_parameter *params)
-{
-	nor->setup = s25fs_s_setup;
-}
-
-static int s25fs_s_post_bfpt_fixup(struct spi_nor *nor,
-				   const struct sfdp_parameter_header *header,
-				   const struct sfdp_bfpt *bfpt,
-				   struct spi_nor_flash_parameter *params)
-{
-	/* The erase size is set to 4K from BFPT, but it's wrong. Fix it. */
-	nor->erase_opcode = SPINOR_OP_SE;
-	nor->mtd.erasesize = nor->info->sector_size;
-
-	/* The S25FS-S chip family reports 512-byte pages in BFPT but
-	 * in reality the write buffer still wraps at the safe default
-	 * of 256 bytes.  Overwrite the page size advertised by BFPT
-	 * to get the writes working.
-	 */
-	params->page_size = 256;
-
-	return 0;
-}
-
-static void s25fs_s_post_sfdp_fixup(struct spi_nor *nor,
-				    struct spi_nor_flash_parameter *params)
-{
-	/*
-	 * The S25FS064S(8MB) supports 1-1-2 and 1-1-4 commands, but params for
-	 * read ops in SFDP are wrong. The other density parts do not support
-	 * 1-1-2 and 1-1-4 commands.
-	 */
-	if (params->size == SZ_8M) {
-		spi_nor_set_read_settings(&params->reads[SNOR_CMD_READ_1_1_2],
-					  0, 8, SPINOR_OP_READ_1_1_2,
-					  SNOR_PROTO_1_1_2);
-		spi_nor_set_read_settings(&params->reads[SNOR_CMD_READ_1_1_4],
-					  0, 8, SPINOR_OP_READ_1_1_4,
-					  SNOR_PROTO_1_1_4);
-	} else {
-		params->hwcaps.mask &= ~SNOR_HWCAPS_READ_1_1_2;
-		params->hwcaps.mask &= ~SNOR_HWCAPS_READ_1_1_4;
-		params->hwcaps.mask &= ~SNOR_HWCAPS_PP_1_1_4;
-	}
-
-	/* Use volatile register to enable quad */
-	params->quad_enable = s25fs_s_quad_enable;
-}
-
-static struct spi_nor_fixups s25fs_s_fixups = {
-	.post_bfpt = s25fs_s_post_bfpt_fixup,
-	.post_sfdp = s25fs_s_post_sfdp_fixup,
-	.late_init = s25fs_s_late_init,
-};
-
-static int s25_s28_mdp_ready(struct spi_nor *nor)
-{
-	u32 addr;
-	int ret;
-
-	for (addr = 0; addr < nor->mtd.size; addr += SZ_128M) {
-		ret = spansion_sr_ready(nor, addr, nor->rdsr_dummy);
-		if (ret < 0)
-			return ret;
-		else if (ret == 0)
-			return 0;
-	}
-
-	return 1;
-}
-
-static int s25_quad_enable(struct spi_nor *nor)
-{
-	u32 addr;
-	int ret;
-
-	for (addr = 0; addr < nor->mtd.size; addr += SZ_128M) {
-		ret = spansion_quad_enable_volatile(nor, addr, 0);
-		if (ret)
-			return ret;
-	}
-
-	return 0;
-}
-
-static int s25_s28_erase_non_uniform(struct spi_nor *nor, loff_t addr)
-{
-	/* Support 32 x 4KB sectors at bottom */
-	return spansion_erase_non_uniform(nor, addr, SPINOR_OP_BE_4K_4B, 0,
-					  SZ_128K);
-}
-
-static int s25_s28_setup(struct spi_nor *nor, const struct flash_info *info,
-			 const struct spi_nor_flash_parameter *params)
-{
-	int ret;
-	u8 cr;
-
-#if CONFIG_IS_ENABLED(SPI_FLASH_BAR)
-	return -ENOTSUPP; /* Bank Address Register is not supported */
-#endif
-	/*
-	 * S25FS256T has multiple sector architecture options, with selection of
-	 * count and location of 128KB and 64KB sectors. This driver supports
-	 * uniform 128KB only due to complexity of non-uniform layout.
-	 */
-	if (nor->info->id[4] == S25FS256T_ID4) {
-		ret = spansion_read_any_reg(nor, SPINOR_REG_CYPRESS_ARCFN, 8,
-					    &cr);
-		if (ret)
-			return ret;
-
-		if (cr) /* Option 0 (ARCFN[7:0] == 0x00) is uniform */
-			return -EOPNOTSUPP;
-
-		return spi_nor_default_setup(nor, info, params);
-	}
-
-	/*
-	 * Read CFR3V to check if uniform sector is selected. If not, assign an
-	 * erase hook that supports non-uniform erase.
-	 */
-	ret = spansion_read_any_reg(nor, SPINOR_REG_CYPRESS_CFR3V, 0, &cr);
-	if (ret)
-		return ret;
-	if (!(cr & SPINOR_REG_CYPRESS_CFR3_UNISECT))
-		nor->erase = s25_s28_erase_non_uniform;
-
-	/*
-	 * For the multi-die package parts, the ready() hook is needed to check
-	 * all dies' status via read any register.
-	 */
-	if (nor->mtd.size > SZ_128M)
-		nor->ready = s25_s28_mdp_ready;
-
-	return spi_nor_default_setup(nor, info, params);
-}
-
-static void s25_late_init(struct spi_nor *nor,
-			  struct spi_nor_flash_parameter *params)
-{
-	nor->setup = s25_s28_setup;
-
-	/*
-	 * Programming is supported only in 16-byte ECC data unit granularity.
-	 * Byte-programming, bit-walking, or multiple program operations to the
-	 * same ECC data unit without an erase are not allowed.
-	 */
-	params->writesize = 16;
-}
-
-static int s25_s28_post_bfpt_fixup(struct spi_nor *nor,
-				   const struct sfdp_parameter_header *header,
-				   const struct sfdp_bfpt *bfpt,
-				   struct spi_nor_flash_parameter *params)
-{
-	int ret;
-	u32 addr;
-	u8 cfr3v;
-
-	/* erase size in case it is set to 4K from BFPT */
-	nor->erase_opcode = SPINOR_OP_SE_4B;
-	nor->mtd.erasesize = nor->info->sector_size;
-
-	/*
-	 * The default address mode in multi-die package parts (>1Gb) may be
-	 * 3- or 4-byte, depending on model number. BootROM code in some SoCs
-	 * use 3-byte mode for backward compatibility and should switch to
-	 * 4-byte mode after BootROM phase. Since registers in the 2nd die are
-	 * mapped within 32-bit address space, we need to make sure the flash is
-	 * in 4-byte address mode. The default address mode can be distinguished
-	 * by BFPT 16th DWORD. Power cycle exits 4-byte address mode if default
-	 * is 3-byte address mode.
-	 */
-	if (params->size > SZ_128M) {
-		if (bfpt->dwords[BFPT_DWORD(16)] & BFPT_DWORD16_EX4B_PWRCYC) {
-			ret = set_4byte(nor, nor->info, 1);
-			if (ret)
-				return ret;
-		}
-		nor->addr_mode_nbytes = 4;
-	}
-
-	/* The default address mode in S25FS256T is 4. */
-	if (nor->info->id[4] == S25FS256T_ID4)
-		nor->addr_mode_nbytes = 4;
-
-	/*
-	 * The page_size is set to 512B from BFPT, but it actually depends on
-	 * the configuration register. Look up the CFR3V and determine the
-	 * page_size. For multi-die package parts, use 512B only when the all
-	 * dies are configured to 512B buffer.
-	 */
-	for (addr = 0; addr < params->size; addr += SZ_128M) {
-		ret = spansion_read_any_reg(nor,
-					    addr + SPINOR_REG_CYPRESS_CFR3V, 0,
-					    &cfr3v);
-		if (ret)
-			return ret;
-
-		if (!(cfr3v & SPINOR_REG_CYPRESS_CFR3_PGSZ)) {
-			params->page_size = 256;
-			return 0;
-		}
-	}
-	params->page_size = 512;
-
-	return 0;
-}
-
-static void s25_post_sfdp_fixup(struct spi_nor *nor,
-				struct spi_nor_flash_parameter *params)
-{
-	if (nor->info->id[4] == S25FS256T_ID4) {
-		/* PP_1_1_4 is supported */
-		params->hwcaps.mask |= SNOR_HWCAPS_PP_1_1_4;
-	} else {
-		/* READ_FAST_4B (0Ch) requires mode cycles*/
-		params->reads[SNOR_CMD_READ_FAST].num_mode_clocks = 8;
-		/* PP_1_1_4 is not supported */
-		params->hwcaps.mask &= ~SNOR_HWCAPS_PP_1_1_4;
-		/* Use volatile register to enable quad */
-		params->quad_enable = s25_quad_enable;
-	}
-}
-
-static struct spi_nor_fixups s25_fixups = {
-	.post_bfpt = s25_s28_post_bfpt_fixup,
-	.post_sfdp = s25_post_sfdp_fixup,
-	.late_init = s25_late_init,
-};
-
-static int s25fl256l_setup(struct spi_nor *nor, const struct flash_info *info,
-			   const struct spi_nor_flash_parameter *params)
-{
-	return -ENOTSUPP; /* Bank Address Register is not supported */
-}
-
-static void s25fl256l_late_init(struct spi_nor *nor,
-				struct spi_nor_flash_parameter *params)
-{
-	nor->setup = s25fl256l_setup;
-}
-
-static struct spi_nor_fixups s25fl256l_fixups = {
-	.late_init = s25fl256l_late_init,
-};
-#endif
-
-#ifdef CONFIG_SPI_FLASH_S28HX_T
-/**
- * spi_nor_cypress_octal_dtr_enable() - Enable octal DTR on Cypress flashes.
- * @nor:		pointer to a 'struct spi_nor'
- *
- * This also sets the memory access latency cycles to 24 to allow the flash to
- * run at up to 200MHz.
- *
- * Return: 0 on success, -errno otherwise.
- */
-static int spi_nor_cypress_octal_dtr_enable(struct spi_nor *nor)
-{
-	u32 addr;
-	u8 buf;
-	int ret;
-
-	ret = write_enable(nor);
-	if (ret)
-		return ret;
-
-	/* Use 24 dummy cycles for memory array reads. */
-	for (addr = 0; addr < nor->mtd.size; addr += SZ_128M) {
-		ret = spansion_read_any_reg(nor,
-					    addr + SPINOR_REG_CYPRESS_CFR2V, 0,
-					    &buf);
-		if (ret)
-			return ret;
-
-		buf &= ~SPINOR_REG_CYPRESS_CFR2_MEMLAT_MASK;
-		buf |= SPINOR_REG_CYPRESS_CFR2_MEMLAT_11_24;
-		ret = spansion_write_any_reg(nor,
-					     addr + SPINOR_REG_CYPRESS_CFR2V,
-					     buf);
-		if (ret) {
-			dev_warn(nor->dev, "failed to set default memory latency value: %d\n", ret);
-			return ret;
-		}
-	}
-	nor->read_dummy = 24;
-
-	ret = write_enable(nor);
-	if (ret)
-		return ret;
-
-	/* Set the octal and DTR enable bits. */
-	buf = SPINOR_REG_CYPRESS_CFR5_OCT_DTR_EN;
-	for (addr = 0; addr < nor->mtd.size; addr += SZ_128M) {
-		ret = spansion_write_any_reg(nor,
-					     addr + SPINOR_REG_CYPRESS_CFR5V,
-					     buf);
-		if (ret) {
-			dev_warn(nor->dev, "Failed to enable octal DTR mode\n");
-			return ret;
-		}
-	}
-
-	return 0;
-}
-
-static void s28hx_t_late_init(struct spi_nor *nor,
-			      struct spi_nor_flash_parameter *params)
-{
-	nor->octal_dtr_enable = spi_nor_cypress_octal_dtr_enable;
-	nor->setup = s25_s28_setup;
-
-	/*
-	 * Programming is supported only in 16-byte ECC data unit granularity.
-	 * Byte-programming, bit-walking, or multiple program operations to the
-	 * same ECC data unit without an erase are not allowed.
-	 */
-	params->writesize = 16;
-}
-
-static void s28hx_t_post_sfdp_fixup(struct spi_nor *nor,
-				    struct spi_nor_flash_parameter *params)
-{
-	/*
-	 * On older versions of the flash the xSPI Profile 1.0 table has the
-	 * 8D-8D-8D Fast Read opcode as 0x00. But it actually should be 0xEE.
-	 */
-	if (params->reads[SNOR_CMD_READ_8_8_8_DTR].opcode == 0)
-		params->reads[SNOR_CMD_READ_8_8_8_DTR].opcode =
-			SPINOR_OP_CYPRESS_RD_FAST;
-
-	params->hwcaps.mask |= SNOR_HWCAPS_PP_8_8_8_DTR;
-
-	/* This flash is also missing the 4-byte Page Program opcode bit. */
-	spi_nor_set_pp_settings(&params->page_programs[SNOR_CMD_PP],
-				SPINOR_OP_PP_4B, SNOR_PROTO_1_1_1);
-	/*
-	 * Since xSPI Page Program opcode is backward compatible with
-	 * Legacy SPI, use Legacy SPI opcode there as well.
-	 */
-	spi_nor_set_pp_settings(&params->page_programs[SNOR_CMD_PP_8_8_8_DTR],
-				SPINOR_OP_PP_4B, SNOR_PROTO_8_8_8_DTR);
-
-	/*
-	 * The xSPI Profile 1.0 table advertises the number of additional
-	 * address bytes needed for Read Status Register command as 0 but the
-	 * actual value for that is 4.
-	 */
-	params->rdsr_addr_nbytes = 4;
-}
-
-static struct spi_nor_fixups s28hx_t_fixups = {
-	.post_sfdp = s28hx_t_post_sfdp_fixup,
-	.post_bfpt = s25_s28_post_bfpt_fixup,
-	.late_init = s28hx_t_late_init,
-};
-#endif /* CONFIG_SPI_FLASH_S28HX_T */
-
-#ifdef CONFIG_SPI_FLASH_MT35XU
-static int spi_nor_micron_octal_dtr_enable(struct spi_nor *nor)
-{
-	struct spi_mem_op op;
-	u8 buf;
-	u8 addr_width = 3;
-	int ret;
-
-	/* Set dummy cycles for Fast Read to the default of 20. */
-	ret = write_enable(nor);
-	if (ret)
-		return ret;
-
-	buf = 20;
-	op = (struct spi_mem_op)
-		SPI_MEM_OP(SPI_MEM_OP_CMD(SPINOR_OP_MT_WR_ANY_REG, 1),
-			   SPI_MEM_OP_ADDR(addr_width, SPINOR_REG_MT_CFR1V, 1),
-			   SPI_MEM_OP_NO_DUMMY,
-			   SPI_MEM_OP_DATA_OUT(1, &buf, 1));
-	ret = spi_mem_exec_op(nor->spi, &op);
-	if (ret)
-		return ret;
-
-	ret = spi_nor_wait_till_ready(nor);
-	if (ret)
-		return ret;
-
-	nor->read_dummy = 20;
-
-	ret = write_enable(nor);
-	if (ret)
-		return ret;
-
-	buf = SPINOR_MT_OCT_DTR;
-	op = (struct spi_mem_op)
-		SPI_MEM_OP(SPI_MEM_OP_CMD(SPINOR_OP_MT_WR_ANY_REG, 1),
-			   SPI_MEM_OP_ADDR(addr_width, SPINOR_REG_MT_CFR0V, 1),
-			   SPI_MEM_OP_NO_DUMMY,
-			   SPI_MEM_OP_DATA_OUT(1, &buf, 1));
-	ret = spi_mem_exec_op(nor->spi, &op);
-	if (ret) {
-		dev_err(nor->dev, "Failed to enable octal DTR mode\n");
-		return ret;
-	}
-
-	return 0;
-}
-
-static void mt35xu512aba_late_init(struct spi_nor *nor,
-				   struct spi_nor_flash_parameter *params)
-{
-	nor->octal_dtr_enable = spi_nor_micron_octal_dtr_enable;
-}
-
-static void mt35xu512aba_post_sfdp_fixup(struct spi_nor *nor,
-					 struct spi_nor_flash_parameter *params)
-{
-	/* Set the Fast Read settings. */
-	params->hwcaps.mask |= SNOR_HWCAPS_READ_8_8_8_DTR;
-	spi_nor_set_read_settings(&params->reads[SNOR_CMD_READ_8_8_8_DTR],
-				  0, 20, SPINOR_OP_MT_DTR_RD,
-				  SNOR_PROTO_8_8_8_DTR);
-
-	params->hwcaps.mask |= SNOR_HWCAPS_PP_8_8_8_DTR;
-
-	nor->cmd_ext_type = SPI_NOR_EXT_REPEAT;
-	params->rdsr_dummy = 8;
-	params->rdsr_addr_nbytes = 0;
-
-	/*
-	 * SCCR Map 22nd DWORD does not indicate DTR Octal Mode Enable
-	 * for MT35XU512ABA but is actually supported by device.
-	 */
-	nor->flags |= SNOR_F_IO_MODE_EN_VOLATILE;
-
-	/*
-	 * The BFPT quad enable field is set to a reserved value so the quad
-	 * enable function is ignored by spi_nor_parse_bfpt(). Make sure we
-	 * disable it.
-	 */
-	params->quad_enable = NULL;
-}
-
-static struct spi_nor_fixups mt35xu512aba_fixups = {
-	.post_sfdp = mt35xu512aba_post_sfdp_fixup,
-	.late_init = mt35xu512aba_late_init,
-};
-#endif /* CONFIG_SPI_FLASH_MT35XU */
-
-#if CONFIG_IS_ENABLED(SPI_FLASH_MACRONIX)
-/**
- * spi_nor_macronix_octal_dtr_enable() - Enable octal DTR on Macronix flashes.
- * @nor:	pointer to a 'struct spi_nor'
- *
- * Set Macronix max dummy cycles 20 to allow the flash to run at fastest frequency.
- *
- * Return: 0 on success, -errno otherwise.
- */
-static int spi_nor_macronix_octal_dtr_enable(struct spi_nor *nor)
-{
-	struct spi_mem_op op;
-	int ret;
-	u8 buf;
-
-	ret = write_enable(nor);
-	if (ret)
-		return ret;
-
-	buf = SPINOR_REG_MXIC_DC_20;
-	op = (struct spi_mem_op)
-		SPI_MEM_OP(SPI_MEM_OP_CMD(SPINOR_OP_WR_CR2, 1),
-			   SPI_MEM_OP_ADDR(4, SPINOR_REG_MXIC_CR2_DC, 1),
-			   SPI_MEM_OP_NO_DUMMY,
-			   SPI_MEM_OP_DATA_OUT(1, &buf, 1));
-
-	ret = spi_mem_exec_op(nor->spi, &op);
-	if (ret)
-		return ret;
-
-	ret = spi_nor_wait_till_ready(nor);
-	if (ret)
-		return ret;
-
-	nor->read_dummy = MXIC_MAX_DC;
-	ret = write_enable(nor);
-	if (ret)
-		return ret;
-
-	buf = SPINOR_REG_MXIC_OPI_DTR_EN;
-	op = (struct spi_mem_op)
-		SPI_MEM_OP(SPI_MEM_OP_CMD(SPINOR_OP_WR_CR2, 1),
-			   SPI_MEM_OP_ADDR(4, SPINOR_REG_MXIC_CR2_MODE, 1),
-			   SPI_MEM_OP_NO_DUMMY,
-			   SPI_MEM_OP_DATA_OUT(1, &buf, 1));
-
-	ret = spi_mem_exec_op(nor->spi, &op);
-	if (ret) {
-		dev_err(nor->dev, "Failed to enable octal DTR mode\n");
-		return ret;
-	}
-	nor->reg_proto = SNOR_PROTO_8_8_8_DTR;
-
-	return 0;
-}
-
-static void macronix_octal_late_init(struct spi_nor *nor,
-				     struct spi_nor_flash_parameter *params)
-{
-	nor->octal_dtr_enable = spi_nor_macronix_octal_dtr_enable;
-}
-
-static void macronix_octal_post_sfdp_fixup(struct spi_nor *nor,
-					 struct spi_nor_flash_parameter *params)
-{
-	/*
-	 * Adding SNOR_HWCAPS_PP_8_8_8_DTR in hwcaps.mask when
-	 * SPI_NOR_OCTAL_DTR_READ flag exists.
-	 */
-	if (params->hwcaps.mask & SNOR_HWCAPS_READ_8_8_8_DTR)
-		params->hwcaps.mask |= SNOR_HWCAPS_PP_8_8_8_DTR;
-}
-
-static struct spi_nor_fixups macronix_octal_fixups = {
-	.post_sfdp = macronix_octal_post_sfdp_fixup,
-	.late_init = macronix_octal_late_init,
-};
-#endif /* CONFIG_SPI_FLASH_MACRONIX */
-
-#if CONFIG_IS_ENABLED(SPI_FLASH_WINBOND)
-
-#define WINBOND_NOR_OP_SELDIE  0xc2    /* Select active die */
-
-struct winbond_nor_priv {
-	unsigned int n_dice;
-};
-
-/**
- * winbond_nor_select_die() - Set active die.
- * @nor:       pointer to 'struct spi_nor'.
- * @die:       die to set active.
- *
- * Certain Winbond chips feature more than a single die. This is mostly hidden
- * to the user, except that some chips may experience time deviation when
- * modifying the status bits between dies, which in some corner cases may
- * produce problematic races. Being able to explicitly select a die to check its
- * state in this case may be useful.
- *
- * Return: 0 on success, -errno otherwise.
- */
-static int winbond_nor_select_die(struct spi_nor *nor, u8 die)
-{
-	struct spi_mem_op op =
-		SPI_MEM_OP(SPI_MEM_OP_CMD(WINBOND_NOR_OP_SELDIE, 1),
-			   SPI_MEM_OP_NO_ADDR,
-			   SPI_MEM_OP_NO_DUMMY,
-			   SPI_MEM_OP_DATA_OUT(1, &die, 0));
-
-	int ret;
-
-	spi_nor_setup_op(nor, &op, SNOR_PROTO_1_1_1);
-	ret = spi_mem_exec_op(nor->spi, &op);
-	if (ret)
-		debug("Error %d selecting die %d\n", ret, die);
-
-	return ret;
-}
-
-static int winbond_nor_multi_die_ready(struct spi_nor *nor)
-{
-	struct winbond_nor_priv *winbond_priv = nor->priv;
-	unsigned int n_dice = winbond_priv ? winbond_priv->n_dice : 1;
-	int ret, i;
-
-	for (i = 0; i < n_dice; i++) {
-		ret = winbond_nor_select_die(nor, i);
-		if (ret)
-			return ret;
-
-		ret = spi_nor_sr_ready(nor);
-		if (ret <= 0)
-			return ret;
-	}
-
-	return 1;
-}
-
-static void winbond_nor_multi_die_post_sfdp_fixups(struct spi_nor *nor,
-						   struct spi_nor_flash_parameter *param)
-{
-	struct winbond_nor_priv *winbond_priv;
-
-	winbond_priv = kmalloc(sizeof(*winbond_priv), GFP_KERNEL);
-	if (!winbond_priv)
-		return;
-
-	winbond_priv->n_dice = param->size / SZ_64M;
-
-	/*
-	 * SFDP supports dice numbers, but this information is only available in
-	 * optional additional tables which are not provided by these chips.
-	 * Dice number has an impact though, because these devices need extra
-	 * care when reading the busy bit.
-	 */
-	nor->priv = winbond_priv;
-	nor->ready = winbond_nor_multi_die_ready;
-}
-
-static struct spi_nor_fixups winbond_nor_multi_die_fixups = {
-	.post_sfdp = winbond_nor_multi_die_post_sfdp_fixups,
-};
-#endif /* CONFIG_SPI_FLASH_WINBOND */
-
 /** spi_nor_octal_dtr_enable() - enable Octal DTR I/O if needed
  * @nor:                 pointer to a 'struct spi_nor'
  *
@@ -3644,63 +2790,6 @@ void spi_nor_set_fixups(struct spi_nor *nor)
 {
 	if (nor->manufacturer->set_fixups)
 		nor->manufacturer->set_fixups(nor);
-
-#ifdef CONFIG_SPI_FLASH_SPANSION
-	if (JEDEC_MFR(nor->info) == SNOR_MFR_CYPRESS) {
-		switch (nor->info->id[1]) {
-		case 0x2a: /* S25HL (QSPI, 3.3V) */
-		case 0x2b: /* S25HS (QSPI, 1.8V) */
-			nor->fixups = &s25_fixups;
-			break;
-
-#ifdef CONFIG_SPI_FLASH_S28HX_T
-		case 0x5a: /* S28HL (Octal, 3.3V) */
-		case 0x5b: /* S28HS (Octal, 1.8V) */
-			nor->fixups = &s28hx_t_fixups;
-			break;
-#endif
-
-		default:
-			break;
-		}
-	}
-
-	if (CONFIG_IS_ENABLED(SPI_FLASH_BAR) &&
-	    !strcmp(nor->info->name, "s25fl256l"))
-		nor->fixups = &s25fl256l_fixups;
-
-	/* For FS-S (family ID = 0x81)  */
-	if (JEDEC_MFR(nor->info) == SNOR_MFR_SPANSION && nor->info->id[5] == 0x81)
-		nor->fixups = &s25fs_s_fixups;
-#endif
-
-#ifdef CONFIG_SPI_FLASH_MT35XU
-	if (!strcmp(nor->info->name, "mt35xu512aba"))
-		nor->fixups = &mt35xu512aba_fixups;
-#endif
-
-#if CONFIG_IS_ENABLED(SPI_FLASH_MACRONIX)
-	if (JEDEC_MFR(nor->info) == SNOR_MFR_MACRONIX &&
-	    nor->info->flags & SPI_NOR_OCTAL_DTR_READ)
-		nor->fixups = &macronix_octal_fixups;
-#endif /* SPI_FLASH_MACRONIX */
-
-#if CONFIG_IS_ENABLED(SPI_FLASH_WINBOND)
-	if (JEDEC_MFR(nor->info) == SNOR_MFR_WINBOND) {
-		u8 multi_die_models[][2] = {
-			{ 0x40, 0x21 }, /* W25Q01JV */
-			{ 0x70, 0x22 }, /* W25Q02JV */
-		};
-		int i;
-
-		for (i = 0; i < sizeof(multi_die_models) / 2; i++) {
-			if (!memcmp(nor->info->id + 1, multi_die_models[i], 2)) {
-				nor->fixups = &winbond_nor_multi_die_fixups;
-				break;
-			}
-		}
-	}
-#endif /* SPI_FLASH_WINBOND */
 }
 
 int spi_nor_scan(struct spi_nor *nor)
diff --git a/drivers/mtd/spi/winbond.c b/drivers/mtd/spi/winbond.c
index 02c29ccf78c..d1030959b2c 100644
--- a/drivers/mtd/spi/winbond.c
+++ b/drivers/mtd/spi/winbond.c
@@ -5,6 +5,7 @@
  * Copyright (C) 2018 Texas Instruments Incorporated - https://www.ti.com/
  */
 
+#include <linux/sizes.h>
 #include <linux/mtd/spi-nor.h>
 #include "sf_internal.h"
 
@@ -140,7 +141,110 @@ static const struct flash_info winbond_nor_parts[] = {
 	{ INFO("w77q51nw", 0xef8a1a, 0, 64 * 1024, 1024, SECT_4K | SPI_NOR_DUAL_READ | SPI_NOR_QUAD_READ | SPI_NOR_4B_OPCODES) },
 };
 
+#if !CONFIG_IS_ENABLED(SPI_FLASH_TINY)
+
+#define WINBOND_NOR_OP_SELDIE  0xc2    /* Select active die */
+
+struct winbond_nor_priv {
+	unsigned int n_dice;
+};
+
+/**
+ * winbond_nor_select_die() - Set active die.
+ * @nor:       pointer to 'struct spi_nor'.
+ * @die:       die to set active.
+ *
+ * Certain Winbond chips feature more than a single die. This is mostly hidden
+ * to the user, except that some chips may experience time deviation when
+ * modifying the status bits between dies, which in some corner cases may
+ * produce problematic races. Being able to explicitly select a die to check its
+ * state in this case may be useful.
+ *
+ * Return: 0 on success, -errno otherwise.
+ */
+static int winbond_nor_select_die(struct spi_nor *nor, u8 die)
+{
+	struct spi_mem_op op =
+		SPI_MEM_OP(SPI_MEM_OP_CMD(WINBOND_NOR_OP_SELDIE, 1),
+			   SPI_MEM_OP_NO_ADDR,
+			   SPI_MEM_OP_NO_DUMMY,
+			   SPI_MEM_OP_DATA_OUT(1, &die, 0));
+
+	int ret;
+
+	spi_nor_setup_op(nor, &op, SNOR_PROTO_1_1_1);
+	ret = spi_mem_exec_op(nor->spi, &op);
+	if (ret)
+		debug("Error %d selecting die %d\n", ret, die);
+
+	return ret;
+}
+
+static int winbond_nor_multi_die_ready(struct spi_nor *nor)
+{
+	struct winbond_nor_priv *winbond_priv = nor->priv;
+	unsigned int n_dice = winbond_priv ? winbond_priv->n_dice : 1;
+	int ret, i;
+
+	for (i = 0; i < n_dice; i++) {
+		ret = winbond_nor_select_die(nor, i);
+		if (ret)
+			return ret;
+
+		ret = spi_nor_sr_ready(nor);
+		if (ret <= 0)
+			return ret;
+	}
+
+	return 1;
+}
+
+static void winbond_nor_multi_die_post_sfdp_fixups(struct spi_nor *nor,
+						   struct spi_nor_flash_parameter *param)
+{
+	struct winbond_nor_priv *winbond_priv;
+
+	winbond_priv = kmalloc(sizeof(*winbond_priv), GFP_KERNEL);
+	if (!winbond_priv)
+		return;
+
+	winbond_priv->n_dice = param->size / SZ_64M;
+
+	/*
+	 * SFDP supports dice numbers, but this information is only available in
+	 * optional additional tables which are not provided by these chips.
+	 * Dice number has an impact though, because these devices need extra
+	 * care when reading the busy bit.
+	 */
+	nor->priv = winbond_priv;
+	nor->ready = winbond_nor_multi_die_ready;
+}
+
+static struct spi_nor_fixups winbond_nor_multi_die_fixups = {
+	.post_sfdp = winbond_nor_multi_die_post_sfdp_fixups,
+};
+
+static void winbond_set_fixups(struct spi_nor *nor)
+{
+	u8 multi_die_models[][2] = {
+		{ 0x40, 0x21 }, /* W25Q01JV */
+		{ 0x70, 0x22 }, /* W25Q02JV */
+	};
+	int i;
+
+	for (i = 0; i < sizeof(multi_die_models) / 2; i++) {
+		if (!memcmp(nor->info->id + 1, multi_die_models[i], 2)) {
+			nor->fixups = &winbond_nor_multi_die_fixups;
+			break;
+		}
+	}
+}
+#endif /* !CONFIG_IS_ENABLED(SPI_FLASH_TINY) */
+
 const struct spi_nor_manufacturer spi_nor_winbond = {
 	.parts = winbond_nor_parts,
 	.nparts = ARRAY_SIZE(winbond_nor_parts),
+#if !CONFIG_IS_ENABLED(SPI_FLASH_TINY)
+	.set_fixups = winbond_set_fixups,
+#endif
 };

-- 
2.43.0

