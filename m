From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Mon, 23 Nov 2026 21:41:39 +0300
Subject: [PATCH 2/3] mtd: rawnand: Add Cortina CS7542 controller support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-b4-cs7542-nand-v1-2-7ce179c011e2@gmail.com>
References: <20261123-b4-cs7542-nand-v1-0-7ce179c011e2@gmail.com>
In-Reply-To: <20261123-b4-cs7542-nand-v1-0-7ce179c011e2@gmail.com>
To: Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-mtd@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795459297; l=27651;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=jw0gR4NdhyNSMRoUfHRyZvrfaOTU6c1rt2kchi8jIc0=;
 b=8dfoOqDXFXFgNjO7I50mSF1yjMJ1En5gX7rnY90mWcHD1GIBWefOmwuHz9gjorOKP6vr8NIG3
 NVItVqwuNbeCjzCD7GhpTgQrSvLg2Cl93gxntZ87RH9ULW6Rdn/V0Lv
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement exec_op using complete command/address/data transactions
supported by the controller sequencer. Cache ID, ONFI and page reads for
the split operations used by NAND core, and reject unsupported sequences
in check_only. Derive address cycles from the NAND geometry rather than
inferring them from chip capacity.

Use programmed I/O with the on-host Hamming engine, preserving the
256-byte steps and OOB layout required by existing Almond+ firmware.
Bound register waits, propagate failures without exposing partial cached
data, and validate ECC error locations before correcting bytes.

Keep DMA and unverified BCH modes out of this initial driver. Bus timing
is retained from firmware; no architecture-series dependency is needed.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 drivers/mtd/nand/raw/Kconfig       |  12 +
 drivers/mtd/nand/raw/Makefile      |   1 +
 drivers/mtd/nand/raw/cs752x_nand.c | 826 +++++++++++++++++++++++++++++++++++++
 3 files changed, 839 insertions(+)

diff --git a/drivers/mtd/nand/raw/Kconfig b/drivers/mtd/nand/raw/Kconfig
index 1f4053e53..3d2373503 100644
--- a/drivers/mtd/nand/raw/Kconfig
+++ b/drivers/mtd/nand/raw/Kconfig
@@ -12,6 +12,18 @@ if MTD_RAW_NAND
 
 comment "Raw/parallel NAND flash controllers"
 
+config MTD_NAND_CS752X
+	tristate "Cortina Systems CS7542 NAND controller"
+	depends on OF && HAS_IOMEM
+	help
+	  Support the CS7542 controller with programmed I/O and hardware
+	  Hamming ECC using the layout required by existing Almond+ firmware.
+	  The NAND bus timing is initialized by the platform firmware.
+	  Transfers use bounded polling and the native command sequencer.
+
+	  To compile this driver as a module, choose M here: the module
+	  will be called cs752x_nand.
+
 config MTD_NAND_DENALI
 	tristate
 
diff --git a/drivers/mtd/nand/raw/Makefile b/drivers/mtd/nand/raw/Makefile
index 619760138..3562f8940 100644
--- a/drivers/mtd/nand/raw/Makefile
+++ b/drivers/mtd/nand/raw/Makefile
@@ -71,3 +71,4 @@ nand-objs += nand_micron.o
 nand-objs += nand_sandisk.o
 nand-objs += nand_samsung.o
 nand-objs += nand_toshiba.o
+obj-$(CONFIG_MTD_NAND_CS752X) += cs752x_nand.o
diff --git a/drivers/mtd/nand/raw/cs752x_nand.c b/drivers/mtd/nand/raw/cs752x_nand.c
new file mode 100644
index 000000000..7c8f73e6f
--- /dev/null
+++ b/drivers/mtd/nand/raw/cs752x_nand.c
@@ -0,0 +1,826 @@
+// SPDX-License-Identifier: GPL-2.0
+#include <linux/kernel.h>
+#include <linux/slab.h>
+#include <linux/module.h>
+#include <linux/sched.h>
+#include <linux/platform_device.h>
+#include <linux/mtd/mtd.h>
+#include <linux/mtd/rawnand.h>
+#include <linux/mtd/partitions.h>
+#include <linux/bitops.h>
+#include <linux/err.h>
+#include <linux/unaligned.h>
+#include <linux/io.h>
+#include <linux/iopoll.h>
+#include <linux/delay.h>
+#include <linux/jiffies.h>
+#include <linux/of.h>
+
+#define CS75XX_OWN_BUF_SIZE	(SZ_4K + 512)
+
+#define FLASH_STATUS		0x08
+#define FLASH_TYPE		0x0c
+#define FLASH_NF_ACCESS		0x28
+#define FLASH_NF_COUNT		0x2c
+#define FLASH_NF_COMMAND	0x30
+#define FLASH_NF_ADDRESS_1	0x34
+#define FLASH_NF_ADDRESS_2	0x38
+#define FLASH_NF_DATA		0x3c
+#define FLASH_NF_ECC_STATUS	0x44
+#define FLASH_NF_ECC_CONTROL	0x48
+#define FLASH_NF_ECC_OOB	0x4c
+#define FLASH_NF_ECC_GEN0	0x50
+#define FLASH_FLASH_ACCESS_START 0xa4
+#define FLASH_NF_ECC_RESET	0xa8
+#define FLASH_FLASH_INTERRUPT	0xac
+#define FLASH_NF_BCH_CONTROL	0xd0
+
+#define NF_ACCESS_EXTADDR(x)	((x) & 0xff)
+#define NF_ACCESS_WIDTH8	(0x0 << 10)
+#define NF_ACCESS_WIDTH32	(0x2 << 10)
+
+#define NF_CNT_CMD(x)		((x) & 0x3)
+#define NF_CNT_ADDR(x)		(((x) & 0x7) << 4)
+#define NF_CNT_DATA(x)		(((x) & 0x3fff) << 8)
+#define NF_CNT_OOB(x)		(((x) & 0x3ffU) << 22)
+#define NCNT_EMPTY_OOB		0x3ff
+#define NCNT_EMPTY_DATA		0x3fff
+#define NCNT_EMPTY_ADDR		0x7
+#define NCNT_ADDR_4		0x3
+#define NCNT_ADDR_5		0x4
+#define NCNT_CMD_2		0x1
+
+#define FLASH_START_REGREQ	BIT(0)
+#define FLASH_START_CMD(x)	(((x) & 0x3) << 12)
+#define FLASH_RD		0x2
+#define FLASH_WT		0x3
+
+#define ECC_RESET_ECC_CLR	BIT(0)
+#define ECC_RESET_FIFO_CLR	BIT(1)
+#define ECC_RESET_NF_RESET	BIT(2)
+
+#define FLASH_INT_REGIRQ	BIT(0)
+
+#define ECC_CTL_CODESEL(x)	(((x) & 0xf) << 4)
+#define ECC_CTL_EN		BIT(8)
+
+#define ECC_STS_STATUS(v)	((v) & 0x3)
+#define ECC_STS_ERRBIT(v)	(((v) >> 3) & 0xf)
+#define ECC_STS_ERRBYTE(v)	(((v) >> 7) & 0x1ff)
+#define ECC_STS_DONE		BIT(31)
+#define ECC_NO_ERR		0x0
+#define ECC_1BIT_DATA_ERR	0x1
+#define ECC_1BIT_ECC_ERR	0x2
+#define ECC_UNCORRECTABLE	0x3
+
+#define FLASH_STATUS_NSTATE_MASK	(0x0f << 8)
+
+struct cs752x_nand_host {
+	struct nand_controller	controller;
+	struct nand_chip	chip;
+	struct device		*dev;
+
+	void __iomem		*iobase_fl;
+	u8			own_buf[CS75XX_OWN_BUF_SIZE];
+	unsigned int		buf_offs;
+	unsigned int		buf_data_len;
+	unsigned int		cache_column;
+	u8			read_mode;
+
+	u8			*ecc_calc;
+	u8			*ecc_code;
+};
+
+static inline struct cs752x_nand_host *to_host(struct nand_chip *chip)
+{
+	return container_of(chip, struct cs752x_nand_host, chip);
+}
+
+static inline u32 fl_readl(struct cs752x_nand_host *h, u32 reg)
+{
+	return readl(h->iobase_fl + reg);
+}
+
+static inline void fl_writel(struct cs752x_nand_host *h, u32 reg, u32 val)
+{
+	writel(val, h->iobase_fl + reg);
+}
+
+static int check_flash_ctrl_status(struct cs752x_nand_host *h)
+{
+	unsigned long timeo = jiffies + HZ;
+	u32 val;
+
+	do {
+		val = fl_readl(h, FLASH_STATUS) & FLASH_STATUS_NSTATE_MASK;
+		if (val == 0)
+			return 0;
+		cpu_relax();
+	} while (time_before(jiffies, timeo));
+
+	dev_err(h->dev, "FLASH_STATUS busy: 0x%x\n", val);
+	return -ETIMEDOUT;
+}
+
+static inline u32 mk_nf_command(u8 cmd0, u8 cmd1, u8 cmd2)
+{
+	return ((u32)cmd2 << 16) | ((u32)cmd1 << 8) | cmd0;
+}
+
+static u32 mk_nf_addr(struct nand_chip *chip, u32 page, u32 *addr1,
+		      u32 *addr2, u32 column)
+{
+	*addr1 = ((page & 0xffff) << 16) | column;
+	*addr2 = page >> 16;
+	return chip->options & NAND_ROW_ADDR_3 ? NCNT_ADDR_5 : NCNT_ADDR_4;
+}
+
+static int wait_reg(struct cs752x_nand_host *h, u32 reg, u32 bit, const char *what)
+{
+	unsigned long timeo = jiffies + 2 * HZ;
+
+	while (!(fl_readl(h, reg) & bit)) {
+		if (time_after(jiffies, timeo)) {
+			dev_err(h->dev, "%s timeout\n", what);
+			return -ETIMEDOUT;
+		}
+		udelay(1);
+		cond_resched();
+	}
+	return 0;
+}
+
+static void reset_ecc_bch_registers(struct cs752x_nand_host *h)
+{
+	fl_writel(h, FLASH_NF_ECC_RESET, ECC_RESET_ECC_CLR | ECC_RESET_FIFO_CLR);
+	fl_writel(h, FLASH_FLASH_INTERRUPT, FLASH_INT_REGIRQ);
+	fl_writel(h, FLASH_NF_ECC_RESET, ECC_RESET_ECC_CLR);
+	fl_writel(h, FLASH_NF_BCH_CONTROL, 0);
+	fl_writel(h, FLASH_NF_ECC_CONTROL, 0);
+}
+
+static void configure_hwecc_reg(struct cs752x_nand_host *h, bool is_write)
+{
+	fl_writel(h, FLASH_NF_ECC_CONTROL, ECC_CTL_EN);
+}
+
+static void cs752x_setup_page_regs(struct cs752x_nand_host *h, int page,
+				   bool write, bool oob_required)
+{
+	struct nand_chip *chip = &h->chip;
+	struct mtd_info *mtd = nand_to_mtd(chip);
+	u32 cmd, addr1, addr2, cnt;
+
+	cnt = NF_CNT_DATA(mtd->writesize - 1);
+	cnt |= NF_CNT_OOB(oob_required ? mtd->oobsize - 1 : NCNT_EMPTY_OOB);
+
+	cnt |= NF_CNT_CMD(NCNT_CMD_2);
+	cmd = write ? mk_nf_command(NAND_CMD_SEQIN, NAND_CMD_PAGEPROG, 0) :
+		      mk_nf_command(NAND_CMD_READ0, NAND_CMD_READSTART, 0);
+	cnt |= NF_CNT_ADDR(mk_nf_addr(chip, page, &addr1, &addr2, 0));
+
+	fl_writel(h, FLASH_NF_COUNT, cnt);
+	fl_writel(h, FLASH_NF_COMMAND, cmd);
+	fl_writel(h, FLASH_NF_ADDRESS_1, addr1);
+	fl_writel(h, FLASH_NF_ADDRESS_2, addr2);
+	fl_writel(h, FLASH_NF_ACCESS,
+		  NF_ACCESS_WIDTH32 |
+		  NF_ACCESS_EXTADDR(((u32)page << chip->page_shift) / SZ_128M));
+}
+
+static int cs752x_page_op_begin(struct cs752x_nand_host *h)
+{
+	int ret = check_flash_ctrl_status(h);
+
+	if (ret) {
+		fl_writel(h, FLASH_NF_ECC_RESET,
+			  ECC_RESET_ECC_CLR | ECC_RESET_FIFO_CLR | ECC_RESET_NF_RESET);
+		return ret;
+	}
+	reset_ecc_bch_registers(h);
+	return 0;
+}
+
+static int cs752x_nand_words(struct cs752x_nand_host *h, u8 *buf,
+			     unsigned int len, bool write)
+{
+	u32 value;
+	unsigned int i;
+	int ret;
+
+	if (len % sizeof(u32))
+		return -EINVAL;
+	for (i = 0; i < len; i += sizeof(u32)) {
+		if (write)
+			fl_writel(h, FLASH_NF_DATA, get_unaligned_le32(buf + i));
+		fl_writel(h, FLASH_FLASH_ACCESS_START,
+			  FLASH_START_REGREQ | FLASH_START_CMD(write ? FLASH_WT : FLASH_RD));
+		ret = readl_poll_timeout_atomic(h->iobase_fl + FLASH_FLASH_ACCESS_START,
+						value, !(value & FLASH_START_REGREQ), 1, 10000);
+		if (ret) {
+			fl_writel(h, FLASH_NF_ECC_RESET,
+				  ECC_RESET_ECC_CLR | ECC_RESET_FIFO_CLR | ECC_RESET_NF_RESET);
+			return ret;
+		}
+		if (!write)
+			put_unaligned_le32(fl_readl(h, FLASH_NF_DATA), buf + i);
+	}
+	return 0;
+}
+
+static int cs752x_nand_read_page_pio(struct cs752x_nand_host *h, u8 *buf,
+				     bool oob_required, int page)
+{
+	struct mtd_info *mtd = nand_to_mtd(&h->chip);
+	int ret;
+
+	cs752x_setup_page_regs(h, page, false, oob_required);
+	ret = cs752x_nand_words(h, buf, mtd->writesize, false);
+	if (ret || !oob_required)
+		return ret;
+	return cs752x_nand_words(h, h->chip.oob_poi, mtd->oobsize, false);
+}
+
+static int cs752x_nand_write_page_pio(struct cs752x_nand_host *h, const u8 *buf,
+				      bool oob_required, int page,
+				    int (*fill_oob)(struct cs752x_nand_host *))
+{
+	struct mtd_info *mtd = nand_to_mtd(&h->chip);
+	int ret;
+
+	cs752x_setup_page_regs(h, page, true, oob_required);
+	ret = cs752x_nand_words(h, (u8 *)buf, mtd->writesize, true);
+	if (ret || !oob_required)
+		return ret;
+	if (fill_oob) {
+		ret = fill_oob(h);
+		if (ret) {
+			fl_writel(h, FLASH_NF_ECC_RESET,
+				  ECC_RESET_ECC_CLR | ECC_RESET_FIFO_CLR | ECC_RESET_NF_RESET);
+			return ret;
+		}
+	}
+	return cs752x_nand_words(h, h->chip.oob_poi, mtd->oobsize, true);
+}
+
+static int fill_hamming_oob_data(struct cs752x_nand_host *h)
+{
+	struct nand_chip *chip = &h->chip;
+	struct mtd_info *mtd = nand_to_mtd(chip);
+	u8 *ecc_calc = h->ecc_calc;
+	int eccsteps = chip->ecc.steps, eccbytes = chip->ecc.bytes;
+	int i, j, ret;
+
+	ret = wait_reg(h, FLASH_NF_ECC_STATUS, ECC_STS_DONE, "ecc gen");
+	if (ret)
+		return ret;
+	fl_writel(h, FLASH_NF_ECC_CONTROL,
+		  fl_readl(h, FLASH_NF_ECC_CONTROL) & ~ECC_CTL_EN);
+
+	for (i = 0, j = 0; eccsteps; eccsteps--, i++, j += eccbytes) {
+		u32 v = fl_readl(h, FLASH_NF_ECC_GEN0 + 4 * i);
+
+		ecc_calc[j]     = v & 0xff;
+		ecc_calc[j + 1] = (v >> 8) & 0xff;
+		ecc_calc[j + 2] = (v >> 16) & 0xff;
+	}
+	return mtd_ooblayout_set_eccbytes(mtd, ecc_calc, chip->oob_poi, 0,
+					  chip->ecc.total);
+}
+
+static int hamming_correct(struct cs752x_nand_host *h, u8 *buf, int page)
+{
+	struct nand_chip *chip = &h->chip;
+	struct mtd_info *mtd = nand_to_mtd(chip);
+	u8 *ecc_code = h->ecc_code;
+	int eccsteps = chip->ecc.steps, eccbytes = chip->ecc.bytes;
+	int eccsize = chip->ecc.size;
+	int i, max_bitflips = 0, ret;
+	u8 *p = buf;
+
+	ret = wait_reg(h, FLASH_NF_ECC_STATUS, ECC_STS_DONE, "ecc gen");
+	if (ret)
+		return ret;
+	fl_writel(h, FLASH_NF_ECC_CONTROL,
+		  fl_readl(h, FLASH_NF_ECC_CONTROL) & ~ECC_CTL_EN);
+
+	ret = mtd_ooblayout_get_eccbytes(mtd, ecc_code, chip->oob_poi, 0, chip->ecc.total);
+	if (ret)
+		return ret;
+
+	for (i = 0; eccsteps; eccsteps--, i += eccbytes, p += eccsize) {
+		u32 sts, ctl;
+		int step = i / eccbytes;
+
+		fl_writel(h, FLASH_NF_ECC_OOB,
+			  ecc_code[i] | (ecc_code[i + 1] << 8) | (ecc_code[i + 2] << 16));
+		ctl = fl_readl(h, FLASH_NF_ECC_CONTROL) & ~ECC_CTL_CODESEL(0xf);
+		fl_writel(h, FLASH_NF_ECC_CONTROL, ctl | ECC_CTL_CODESEL(step));
+
+		sts = fl_readl(h, FLASH_NF_ECC_STATUS);
+		switch (ECC_STS_STATUS(sts)) {
+		case ECC_NO_ERR:
+			break;
+		case ECC_1BIT_DATA_ERR:
+			if (ECC_STS_ERRBYTE(sts) >= eccsize) {
+				mtd->ecc_stats.failed++;
+				break;
+			}
+			p[ECC_STS_ERRBYTE(sts)] ^= BIT(ECC_STS_ERRBIT(sts));
+			mtd->ecc_stats.corrected++;
+			max_bitflips = max(max_bitflips, 1);
+			dev_dbg(h->dev, "page %d step %d: 1-bit data error corrected\n",
+				page, step);
+			break;
+		case ECC_1BIT_ECC_ERR:
+			mtd->ecc_stats.corrected++;
+			max_bitflips = max(max_bitflips, 1);
+			dev_dbg(h->dev, "page %d step %d: 1-bit ecc error\n", page, step);
+			break;
+		case ECC_UNCORRECTABLE:
+			mtd->ecc_stats.failed++;
+			dev_dbg(h->dev, "page %d step %d: uncorrectable\n", page, step);
+			break;
+		}
+	}
+	return max_bitflips;
+}
+
+/* The controller sequences complete transactions; do not split CMD/ADDR. */
+struct cs752x_nand_op {
+	u32 command;
+	u64 address;
+	unsigned int ncmds;
+	unsigned int naddrs;
+	const struct nand_op_instr *data;
+	unsigned int timeout_ms;
+	unsigned int delay_ns;
+};
+
+static int cs752x_nand_decode(const struct nand_operation *op,
+			      struct cs752x_nand_op *p)
+{
+	unsigned int i, state = 0, nsig = 0, nwait = 0;
+	char sig[7] = {};
+
+	memset(p, 0, sizeof(*p));
+	p->timeout_ms = 100;
+	if (op->cs || !op->ninstrs || op->ninstrs > 6)
+		return -EOPNOTSUPP;
+	for (i = 0; i < op->ninstrs; i++) {
+		const struct nand_op_instr *in = &op->instrs[i];
+		unsigned int j;
+
+		p->delay_ns = max(p->delay_ns, in->delay_ns);
+		if (in->type != NAND_OP_WAITRDY_INSTR) {
+			if (in->type > NAND_OP_DATA_OUT_INSTR)
+				return -EOPNOTSUPP;
+			sig[nsig++] = "CAIO"[in->type];
+		} else if (++nwait > 1 || !i ||
+			   (op->instrs[i - 1].type != NAND_OP_CMD_INSTR &&
+			    op->instrs[i - 1].type != NAND_OP_ADDR_INSTR)) {
+			return -EOPNOTSUPP;
+		}
+		switch (in->type) {
+		case NAND_OP_CMD_INSTR:
+			if (p->ncmds == 2 || state == 4)
+				return -EOPNOTSUPP;
+			p->command |= (u32)in->ctx.cmd.opcode << (p->ncmds++ * 8);
+			state = 1;
+			break;
+		case NAND_OP_ADDR_INSTR:
+			if (state != 1 || p->naddrs || !in->ctx.addr.naddrs ||
+			    in->ctx.addr.naddrs > 5)
+				return -EOPNOTSUPP;
+			p->naddrs = in->ctx.addr.naddrs;
+			for (j = 0; j < p->naddrs; j++)
+				p->address |= (u64)in->ctx.addr.addrs[j] << (j * 8);
+			state = 2;
+			break;
+		case NAND_OP_DATA_IN_INSTR:
+		case NAND_OP_DATA_OUT_INSTR:
+			if (p->data || !in->ctx.data.len ||
+			    in->ctx.data.len > CS75XX_OWN_BUF_SIZE)
+				return -EOPNOTSUPP;
+			p->data = in;
+			state = in->type == NAND_OP_DATA_IN_INSTR ? 4 : 3;
+			break;
+		case NAND_OP_WAITRDY_INSTR:
+			if (!in->ctx.waitrdy.timeout_ms)
+				return -EOPNOTSUPP;
+			p->timeout_ms = in->ctx.waitrdy.timeout_ms;
+			break;
+		default:
+			return -EOPNOTSUPP;
+		}
+	}
+
+	if (!p->ncmds)
+		return p->data && p->data->type == NAND_OP_DATA_IN_INSTR &&
+		       op->ninstrs == 1 ? 0 : -EOPNOTSUPP;
+	/* Validate the whole sequence, not just the available register fields. */
+	if (p->command == NAND_CMD_RESET) {
+		if (strcmp(sig, "C"))
+			return -EOPNOTSUPP;
+	} else if (p->command == NAND_CMD_STATUS) {
+		if (strcmp(sig, "C") && strcmp(sig, "CI"))
+			return -EOPNOTSUPP;
+	} else if (p->command == NAND_CMD_READID || p->command == NAND_CMD_PARAM) {
+		if (strcmp(sig, "CA") && strcmp(sig, "CAI"))
+			return -EOPNOTSUPP;
+	} else if (p->command == (NAND_CMD_SEQIN | (NAND_CMD_PAGEPROG << 8))) {
+		if (strcmp(sig, "CAOC"))
+			return -EOPNOTSUPP;
+	} else if (strcmp(sig, "CAC") && strcmp(sig, "CACI")) {
+		return -EOPNOTSUPP;
+	}
+	switch (p->command) {
+	case NAND_CMD_RESET:
+		return !p->naddrs && !p->data ? 0 : -EOPNOTSUPP;
+	case NAND_CMD_STATUS:
+		return !p->naddrs && (!p->data ||
+		       (p->data->type == NAND_OP_DATA_IN_INSTR &&
+			p->data->ctx.data.len == 1)) ? 0 : -EOPNOTSUPP;
+	case NAND_CMD_READID:
+	case NAND_CMD_PARAM:
+		return p->naddrs == 1 && (!p->data ||
+		       p->data->type == NAND_OP_DATA_IN_INSTR) ? 0 : -EOPNOTSUPP;
+	case NAND_CMD_READ0 | (NAND_CMD_READSTART << 8):
+		return p->naddrs >= 4 && (!p->data ||
+		       p->data->type == NAND_OP_DATA_IN_INSTR) ? 0 : -EOPNOTSUPP;
+	case NAND_CMD_RNDOUT | (NAND_CMD_RNDOUTSTART << 8):
+		return p->naddrs == 2 && (!p->data ||
+		       p->data->type == NAND_OP_DATA_IN_INSTR) ? 0 : -EOPNOTSUPP;
+	case NAND_CMD_SEQIN | (NAND_CMD_PAGEPROG << 8):
+		return p->naddrs >= 4 && p->data &&
+		       p->data->type == NAND_OP_DATA_OUT_INSTR &&
+		       !(p->data->ctx.data.len % sizeof(u32)) &&
+		       !(p->address & 3) && state == 1 ? 0 : -EOPNOTSUPP;
+	case NAND_CMD_ERASE1 | (NAND_CMD_ERASE2 << 8):
+		return p->naddrs >= 2 && p->naddrs <= 3 && !p->data ? 0 : -EOPNOTSUPP;
+	default:
+		return -EOPNOTSUPP;
+	}
+}
+
+static int cs752x_nand_wait_ready(struct cs752x_nand_host *h,
+				  unsigned int timeout_ms)
+{
+	u32 value;
+
+	/* nflash_rbIn_d is the sampled NAND R/B input, not the FSM state. */
+	return readl_poll_timeout(h->iobase_fl + FLASH_STATUS, value,
+				 value & BIT(26), 1, (u64)timeout_ms * 1000);
+}
+
+static int cs752x_nand_pio(struct cs752x_nand_host *h,
+			   const struct cs752x_nand_op *p, u8 *buf,
+			  unsigned int len, bool write)
+{
+	u32 value;
+	unsigned int i, step = write && len ? sizeof(u32) : 1;
+	int ret;
+
+	ret = check_flash_ctrl_status(h);
+	if (ret)
+		return ret;
+	reset_ecc_bch_registers(h);
+	fl_writel(h, FLASH_NF_COUNT,
+		  NF_CNT_OOB(NCNT_EMPTY_OOB) |
+		  NF_CNT_DATA(len ? len - 1 : NCNT_EMPTY_DATA) |
+		  NF_CNT_ADDR(p->naddrs ? p->naddrs - 1 : NCNT_EMPTY_ADDR) |
+		  NF_CNT_CMD(p->ncmds - 1));
+	fl_writel(h, FLASH_NF_COMMAND, p->command);
+	fl_writel(h, FLASH_NF_ADDRESS_1, lower_32_bits(p->address));
+	fl_writel(h, FLASH_NF_ADDRESS_2, upper_32_bits(p->address));
+	fl_writel(h, FLASH_NF_ACCESS, write && len ? NF_ACCESS_WIDTH32 : NF_ACCESS_WIDTH8);
+
+	for (i = 0; i < max(len, 1U); i += step) {
+		if (write && len)
+			fl_writel(h, FLASH_NF_DATA, get_unaligned_le32(buf + i));
+		fl_writel(h, FLASH_FLASH_ACCESS_START,
+			  FLASH_START_REGREQ | FLASH_START_CMD(write ? FLASH_WT : FLASH_RD));
+		/* Byte PIO completes in microseconds, below scheduler granularity. */
+		ret = readl_poll_timeout_atomic(h->iobase_fl + FLASH_FLASH_ACCESS_START,
+						value, !(value & FLASH_START_REGREQ), 1,
+					(u64)p->timeout_ms * 1000);
+		if (ret)
+			goto out;
+		if (!write && len)
+			buf[i] = fl_readl(h, FLASH_NF_DATA) >> ((i % 4) * 8);
+	}
+	ret = p->command == NAND_CMD_STATUS ? 0 :
+	      cs752x_nand_wait_ready(h, p->timeout_ms);
+	if (p->delay_ns)
+		ndelay(p->delay_ns);
+out:
+	fl_writel(h, FLASH_NF_ECC_RESET,
+		  ECC_RESET_ECC_CLR | ECC_RESET_FIFO_CLR | ECC_RESET_NF_RESET);
+	return ret;
+}
+
+static int cs752x_nand_exec_op(struct nand_chip *chip,
+			       const struct nand_operation *op, bool check_only)
+{
+	struct cs752x_nand_host *h = to_host(chip);
+	struct mtd_info *mtd = nand_to_mtd(chip);
+	struct cs752x_nand_op p;
+	unsigned int len = 0, requested, col;
+	int ret;
+
+	ret = cs752x_nand_decode(op, &p);
+	if (ret || check_only)
+		return ret;
+	requested = p.data ? p.data->ctx.data.len : 0;
+	if (!p.ncmds) {
+		if (h->read_mode != NAND_CMD_STATUS)
+			goto cached;
+		if (requested != 1)
+			return -EOPNOTSUPP;
+		p.command = NAND_CMD_STATUS;
+		p.ncmds = 1;
+	}
+	if (p.command == (NAND_CMD_RNDOUT | (NAND_CMD_RNDOUTSTART << 8))) {
+		col = p.address;
+		if (h->read_mode != NAND_CMD_PARAM && h->read_mode != NAND_CMD_READ0)
+			return -EINVAL;
+		if (col < h->cache_column || col - h->cache_column > h->buf_data_len)
+			return -EINVAL;
+		h->buf_offs = col - h->cache_column;
+		goto cached;
+	}
+	h->buf_offs = 0;
+	h->buf_data_len = 0;
+	h->read_mode = p.command & 0xff;
+	h->cache_column = 0;
+	switch (p.command) {
+	case NAND_CMD_READID:
+		len = max(requested, 8U);
+		break;
+	case NAND_CMD_PARAM:
+		/* Keep all standard ONFI copies plus room for extended parameters. */
+		len = sizeof(h->own_buf);
+		break;
+	case NAND_CMD_STATUS:
+		len = 1;
+		break;
+	case NAND_CMD_READ0 | (NAND_CMD_READSTART << 8):
+		col = p.address & 0xffff;
+		if (col >= mtd->writesize + mtd->oobsize)
+			return -EINVAL;
+		h->cache_column = col;
+		len = mtd->writesize + mtd->oobsize - col;
+		break;
+	default:
+		break;
+	}
+	if (len > sizeof(h->own_buf) || (requested > len &&
+					 (!p.data || p.data->type == NAND_OP_DATA_IN_INSTR)))
+		return -EOPNOTSUPP;
+	if (p.data && p.data->type == NAND_OP_DATA_OUT_INSTR)
+		return cs752x_nand_pio(h, &p, (u8 *)p.data->ctx.data.buf.out,
+				      requested, true);
+
+	ret = cs752x_nand_pio(h, &p, h->own_buf, len,
+			      p.command == NAND_CMD_RESET);
+	if (ret)
+		return ret;
+	h->buf_data_len = len;
+cached:
+	if (!requested)
+		return 0;
+	if (h->buf_offs > h->buf_data_len ||
+	    requested > h->buf_data_len - h->buf_offs)
+		return -EOPNOTSUPP;
+	memcpy(p.data->ctx.data.buf.in, h->own_buf + h->buf_offs, requested);
+	h->buf_offs += requested;
+	return 0;
+}
+
+static int cs752x_nand_program_status(struct nand_chip *chip)
+{
+	u8 status;
+	int ret;
+
+	ret = cs752x_nand_wait_ready(to_host(chip), 1000);
+	if (ret)
+		return ret;
+	ret = nand_status_op(chip, &status);
+	if (ret)
+		return ret;
+	return status & NAND_STATUS_FAIL ? -EIO : 0;
+}
+
+static int cs752x_nand_write_oob_std(struct nand_chip *chip, int page)
+{
+	return nand_prog_page_op(chip, page, nand_to_mtd(chip)->writesize,
+				 chip->oob_poi, nand_to_mtd(chip)->oobsize);
+}
+
+static int cs752x_nand_read_page_raw(struct nand_chip *chip, u8 *buf,
+				     int oob_required, int page)
+{
+	struct cs752x_nand_host *h = to_host(chip);
+	int ret;
+
+	ret = cs752x_page_op_begin(h);
+	if (ret)
+		return ret;
+	return cs752x_nand_read_page_pio(h, buf, oob_required, page);
+}
+
+static int cs752x_nand_write_page_raw(struct nand_chip *chip, const u8 *buf,
+				      int oob_required, int page)
+{
+	struct cs752x_nand_host *h = to_host(chip);
+	int ret;
+
+	ret = cs752x_page_op_begin(h);
+	if (ret)
+		return ret;
+	ret = cs752x_nand_write_page_pio(h, buf, oob_required, page, NULL);
+	if (ret)
+		return ret;
+	return cs752x_nand_program_status(chip);
+}
+
+static int cs752x_nand_read_page_hwecc(struct nand_chip *chip, u8 *buf,
+				       int oob_required, int page)
+{
+	struct cs752x_nand_host *h = to_host(chip);
+	int ret;
+
+	ret = cs752x_page_op_begin(h);
+	if (ret)
+		return ret;
+	configure_hwecc_reg(h, false);
+
+	ret = cs752x_nand_read_page_pio(h, buf, true, page);
+	if (ret)
+		return ret;
+
+	ret = hamming_correct(h, buf, page);
+	return ret;
+}
+
+static int cs752x_nand_write_page_hwecc(struct nand_chip *chip, const u8 *buf,
+					int oob_required, int page)
+{
+	struct cs752x_nand_host *h = to_host(chip);
+	int ret;
+
+	ret = cs752x_page_op_begin(h);
+	if (ret)
+		return ret;
+	configure_hwecc_reg(h, true);
+
+	ret = cs752x_nand_write_page_pio(h, buf, true, page, fill_hamming_oob_data);
+	if (ret)
+		return ret;
+	return cs752x_nand_program_status(chip);
+}
+
+static int cs752x_nand_attach_chip(struct nand_chip *chip)
+{
+	struct mtd_info *mtd = nand_to_mtd(chip);
+	struct cs752x_nand_host *h = to_host(chip);
+	int ecc_total;
+
+	if (chip->options & NAND_BUSWIDTH_16 ||
+	    mtd->writesize <= 512 || mtd->oobsize % sizeof(u32) ||
+	    mtd->writesize + mtd->oobsize > sizeof(h->own_buf))
+		return -EOPNOTSUPP;
+	chip->ecc.engine_type = NAND_ECC_ENGINE_TYPE_ON_HOST;
+	chip->ecc.placement = NAND_ECC_PLACEMENT_OOB;
+
+	chip->ecc.algo = NAND_ECC_ALGO_HAMMING;
+	chip->ecc.size = 256;
+	chip->ecc.bytes = 3;
+	chip->ecc.strength = 1;
+
+	if (mtd->writesize < chip->ecc.size) {
+		dev_err(h->dev, "%d byte HW ECC not possible on %d byte page\n",
+			chip->ecc.size, mtd->writesize);
+		return -EINVAL;
+	}
+
+	ecc_total = mtd->writesize / chip->ecc.size * chip->ecc.bytes;
+	if (ecc_total > mtd->oobsize - 2) {
+		dev_err(h->dev, "%d ECC bytes do not fit in %d byte OOB\n",
+			ecc_total, mtd->oobsize);
+		return -EINVAL;
+	}
+
+	h->ecc_calc = devm_kzalloc(h->dev, mtd->oobsize, GFP_KERNEL);
+	h->ecc_code = devm_kzalloc(h->dev, mtd->oobsize, GFP_KERNEL);
+	if (!h->ecc_calc || !h->ecc_code)
+		return -ENOMEM;
+
+	if (mtd->oobsize == 8 || mtd->oobsize == 16)
+		mtd_set_ooblayout(mtd, nand_get_small_page_ooblayout());
+	else
+		mtd_set_ooblayout(mtd, nand_get_large_page_hamming_ooblayout());
+
+	chip->ecc.read_page	 = cs752x_nand_read_page_hwecc;
+	chip->ecc.write_page	 = cs752x_nand_write_page_hwecc;
+	chip->ecc.read_page_raw	 = cs752x_nand_read_page_raw;
+	chip->ecc.write_page_raw = cs752x_nand_write_page_raw;
+	chip->ecc.write_oob	 = cs752x_nand_write_oob_std;
+
+	dev_info(h->dev, "HW ECC %s, %d bytes per %d-byte step, page %u, oob %u\n",
+		 chip->ecc.algo == NAND_ECC_ALGO_BCH ? "BCH" : "Hamming",
+		 chip->ecc.bytes, chip->ecc.size, mtd->writesize, mtd->oobsize);
+	return 0;
+}
+
+static const struct nand_controller_ops cs752x_nand_controller_ops = {
+	.attach_chip = cs752x_nand_attach_chip,
+	.exec_op = cs752x_nand_exec_op,
+};
+
+static int cs752x_nand_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct cs752x_nand_host *h;
+	struct nand_chip *chip;
+	struct mtd_info *mtd;
+	struct device_node *flash;
+	u32 cs;
+	int err;
+
+	h = devm_kzalloc(dev, sizeof(*h), GFP_KERNEL);
+	if (!h)
+		return -ENOMEM;
+	h->dev = dev;
+
+	h->iobase_fl = devm_platform_ioremap_resource(pdev, 0);
+	if (IS_ERR(h->iobase_fl))
+		return PTR_ERR(h->iobase_fl);
+
+	nand_controller_init(&h->controller);
+	h->controller.ops = &cs752x_nand_controller_ops;
+
+	chip = &h->chip;
+	mtd = nand_to_mtd(chip);
+	chip->controller = &h->controller;
+	flash = of_get_available_child_by_name(dev->of_node, "nand");
+
+	if (!flash)
+		return dev_err_probe(dev, -ENODEV, "missing NAND chip node\n");
+	err = of_property_read_u32(flash, "reg", &cs);
+	if (err || cs) {
+		of_node_put(flash);
+		return dev_err_probe(dev, -EINVAL, "only chip select 0 is supported\n");
+	}
+	nand_set_flash_node(chip, flash);
+	of_node_put(flash);
+	nand_set_controller_data(chip, h);
+	mtd->dev.parent = dev;
+	mtd->name = "cs752x_nand_flash";
+
+	chip->options |= NAND_NO_SUBPAGE_WRITE;
+
+	dev_info(dev, "flash type 0x%08x\n", fl_readl(h, FLASH_TYPE));
+
+	err = nand_scan(chip, 1);
+	if (err)
+		return dev_err_probe(dev, err, "NAND scan failed\n");
+
+	err = mtd_device_register(mtd, NULL, 0);
+	if (err) {
+		nand_cleanup(chip);
+		return err;
+	}
+
+	platform_set_drvdata(pdev, h);
+	return 0;
+}
+
+static void cs752x_nand_remove(struct platform_device *pdev)
+{
+	struct cs752x_nand_host *h = platform_get_drvdata(pdev);
+	struct nand_chip *chip = &h->chip;
+
+	WARN_ON(mtd_device_unregister(nand_to_mtd(chip)));
+	nand_cleanup(chip);
+}
+
+static const struct of_device_id cs752x_nand_dt_ids[] = {
+	{ .compatible = "cortina,cs7542-nand" },
+	{}
+};
+MODULE_DEVICE_TABLE(of, cs752x_nand_dt_ids);
+
+static struct platform_driver cs752x_nand_driver = {
+	.driver = {
+		.name	= "cs752x_nand",
+		.of_match_table = cs752x_nand_dt_ids,
+	},
+	.probe		= cs752x_nand_probe,
+	.remove		= cs752x_nand_remove,
+};
+module_platform_driver(cs752x_nand_driver);
+
+MODULE_LICENSE("GPL");
+MODULE_DESCRIPTION("NAND flash driver for Cortina CS7542");
+MODULE_ALIAS("platform:cs752x_nand");

-- 
2.53.0

