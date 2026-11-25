From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Wed, 25 Nov 2026 13:36:32 +0300
Subject: [PATCH net-next v2 2/3] net: cortina: Add CS7542 CPU network
 datapath
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-b4-cs7542-ethernet-v2-2-d0ea3c6eb375@gmail.com>
References: <20261125-b4-cs7542-ethernet-v2-0-d0ea3c6eb375@gmail.com>
In-Reply-To: <20261125-b4-cs7542-ethernet-v2-0-d0ea3c6eb375@gmail.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Linus Walleij <linusw@kernel.org>
Cc: Philipp Zabel <p.zabel@pengutronix.de>, 
 Hans Ulli Kroll <ulli.kroll@googlemail.com>, 
 Russell King <linux@armlinux.org.uk>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795602990; l=100032;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=pZyWVLf3SEiEhyF1Bw/pXkDNzDQJVEpT6mBfGNSjZ7Q=;
 b=oDEyQCNR8HrlIiLXdxFyokR9NyJAGE6Xlr1fHf0BQOe8mVeTmQiJw38kvP7zrL5VY7Z0kzBJ8
 COETQs+4lqZAaDpM4jTj+/9KAChZsv7EZT1vjSQAitt37A3kGlIHj+Y
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the three-GMAC CS7542 CPU network datapath with phylink, per-port
NAPI RX and a shared coherent TX ring. Support scatter-gather TX and
multi-buffer RX while validating DMA addresses and ring ownership.
Use the normal NAPI weight and the supported external-DDR QM/TM setup.

Bound indirect initialization and require confirmed complete-domain
reset before freeing active DMA mappings. Pin mappings and context when
reset fails. Keep resource publication and shared-ring timer cancellation
under the TX lock so completions cannot wake a closing or failed port.
Use shared ndo_open cleanup labels and let the compiler inline MMIO
helpers when appropriate.

Acquire NI, FE, TM, SCH, QM, DMA and NI-XRAM controls exclusively from
the global provider. Assert and verify all seven without rolling back
protective assertions; preserve the first error and retain all active
DMA allocations on any failure. Deassert in reverse order. The shared
DMA control covers both LSO and SSP. Require the verified 64 MiB no-map
queue-manager reservation on the supported DDR layout.

Serialize read-modify-write accesses to NI registers shared by the MACs.
Abort initialization on the first scheduler command error before the
network engine can publish DMA buffers.

Resolve NVMEM MAC deferral before installing hardware cleanup, when no
reset or DMA state needs unwinding. Register the plain managed cleanup
action immediately before the first reset attempt, preserving protective
cleanup for that attempt and all later failures. Propagate a later
-EPROBE_DEFER instead of silently generating a random address.

Count RX fragments independently of whether the frame is deliverable.
Start with a masked NAPI poll to service previously queued RX descriptors.
Keep TX completion reaping available while closed ports still own queued
mappings; never release descriptors whose hardware ownership remains set.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 drivers/net/ethernet/cortina/Kconfig         |   14 +
 drivers/net/ethernet/cortina/Makefile        |    3 +
 drivers/net/ethernet/cortina/cs752x_fe.c     |  477 +++++++
 drivers/net/ethernet/cortina/cs752x_ne.c     | 1869 ++++++++++++++++++++++++++
 drivers/net/ethernet/cortina/cs752x_ne.h     |   13 +
 drivers/net/ethernet/cortina/cs752x_sch_tm.c |  687 ++++++++++
 6 files changed, 3063 insertions(+)

diff --git a/drivers/net/ethernet/cortina/Kconfig b/drivers/net/ethernet/cortina/Kconfig
index aaf9e294b..52c0683be 100644
--- a/drivers/net/ethernet/cortina/Kconfig
+++ b/drivers/net/ethernet/cortina/Kconfig
@@ -20,4 +20,18 @@ config GEMINI_ETHERNET
 	help
 	  This driver supports StorLink SL351x (Gemini) dual Gigabit Ethernet.
 
+config CS7542_ETHERNET
+	tristate "Cortina CS7542 network engine"
+	depends on OF && OF_RESERVED_MEM && HAS_IOMEM
+	select PHYLINK
+	select MFD_SYSCON
+	select RESET_CONTROLLER
+	help
+	  Support the CS7542 network engine GMACs with a CPU DMA datapath.
+	  A dedicated queue-manager DDR reservation and exclusive ownership
+	  of all seven NI, FE, TM, SCH, QM, DMA and NI-XRAM reset lines are
+	  required. The shared DMA line covers both LSO and SSP.
+	  To compile this driver as a module, choose M; the module is named
+	  cs7542-eth.
+
 endif # NET_VENDOR_CORTINA
diff --git a/drivers/net/ethernet/cortina/Makefile b/drivers/net/ethernet/cortina/Makefile
index 4e86d398a..e998ffcc8 100644
--- a/drivers/net/ethernet/cortina/Makefile
+++ b/drivers/net/ethernet/cortina/Makefile
@@ -2,3 +2,6 @@
 # Makefile for the Cortina Gemini network device drivers.
 
 obj-$(CONFIG_GEMINI_ETHERNET) += gemini.o
+
+obj-$(CONFIG_CS7542_ETHERNET) += cs7542-eth.o
+cs7542-eth-y := cs752x_ne.o cs752x_fe.o cs752x_sch_tm.o
diff --git a/drivers/net/ethernet/cortina/cs752x_fe.c b/drivers/net/ethernet/cortina/cs752x_fe.c
new file mode 100644
index 000000000..72f93ef49
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs752x_fe.c
@@ -0,0 +1,477 @@
+// SPDX-License-Identifier: GPL-2.0
+
+#include <linux/bitfield.h>
+#include <linux/bits.h>
+#include <linux/delay.h>
+#include <linux/device.h>
+#include <linux/io.h>
+#include <linux/iopoll.h>
+
+#include "cs752x_ne.h"
+
+#define FETOP_FE_AN_BNG_MAC_ACCESS		0x0004
+#define FETOP_FE_L4_PORT_RNGS_ACCESS		0x0010
+#define FETOP_FE_ETYPE_ACCESS			0x001c
+#define FETOP_FE_LLC_HDR_ACCESS			0x0024
+#define FETOP_FE_PRSR_CFG_0			0x003c
+#define FETOP_FE_STS_GLBL			0x0044
+#define FETOP_FE_LPB_ACCESS			0x004c
+#define FETOP_FE_CLASS_ACCESS			0x0054
+#define FETOP_FE_SDB_ACCESS			0x00a8
+#define FETOP_FE_VLN_ACCESS			0x00c8
+#define FETOP_FE_FWDRSLT_ACCESS			0x00d4
+#define FETOP_FE_QOSRSLT_ACCESS			0x00e8
+#define FETOP_FE_VOQPOL_ACCESS			0x00f4
+#define FETOP_FE_FVLAN_ACCESS			0x0100
+#define FETOP_FE_L3TBL_ACCESS			0x010c
+#define FETOP_FE_L2TBL_ACCESS			0x0124
+#define FETOP_FE_ACLRULE_ACCESS			0x0138
+#define FETOP_FE_ACLACTION_ACCESS		0x01ac
+#define FETOP_FE_PE_CONFIG_1			0x0224
+#define FETOP_FE_PE_VOQ_DRP_ACCESS		0x023c
+#define FETOP_FE_PKTLEN_RNGS_ACCESS		0x0288
+#define FETOP_HASH_STATUS			0x2000
+#define FETOP_HASH_INIT				0x2004
+#define FETOP_HASH_MASK_MEM_ACCESS		0x2068
+
+#define FE_TABLE_ACCESS_START			BIT(31)
+#define FE_TABLE_ACCESS_RBW_WRITE		BIT(30)
+
+#define FE_STS_GLBL_MEM_INIT_DONE		BIT(0)
+
+#define FE_HASH_STATUS_INIT_IN_PROGRESS		BIT(0)
+#define FE_HASH_STATUS_READY_FOR_INIT		BIT(1)
+#define FE_HASH_INIT_INIT			BIT(0)
+
+#define FE_PE_CONFIG_1_INS_CPUHDR_VOQ		GENMASK(7, 0)
+#define FE_PE_CONFIG_1_INS_CPUHDR_CRYPTO	BIT(8)
+#define FE_PE_CONFIG_1_INS_CPUHDR_ENCAP		BIT(9)
+#define FE_PE_CONFIG_1_PARSE_LIMIT		GENMASK(15, 11)
+
+#define FE_PE_CONFIG_1_ALL_CPU_PORTS		0xff
+#define FE_PE_CONFIG_1_PARSE_LIMIT_MIN_CYCLE	0x18
+
+#define FE_AN_BNG_MAC_ENTRY_MAX			15
+#define FE_L4_PORT_RNGS_MAX			32
+#define FE_ETH_CAM_ENTRY_MAX			63
+#define FE_LLC_ENTRY_MAX			3
+#define FE_LPB_ENTRY_MAX			8
+#define FE_CLASS_ENTRY_MAX			64
+#define FE_SDB_ENTRY_MAX			64
+#define FE_VLAN_ENTRY_MAX			4096
+#define FE_FWD_RESULT_ENTRY_MAX			8192
+#define FE_QOS_RESULT_ENTRY_MAX			128
+#define FE_VOQ_POL_ENTRY_MAX			512
+#define FE_FVLAN_ENTRY_MAX			512
+#define FE_L3_ADDR_ENTRY_MAX			1024
+#define FE_L2_ADDR_PAIR_ENTRY_MAX		512
+#define FE_ACL_ENTRY_MAX			128
+#define FE_PE_VOQ_DROP_ENTRY_MAX		32
+#define FE_HASH_MASK_ENTRY_MAX			64
+#define FE_PKTLEN_RANGE_ENTRY_MAX		4
+
+#define FE_TABLE_DATA_REGS_MAX			28
+
+#define FE_TABLE_ACCESS_TIMEOUT_US		10000
+#define FE_HASH_INIT_POLL_US			1000
+#define FE_HASH_INIT_TIMEOUT_US			1000000
+
+#define CS_GE_PORT_COUNT			3
+#define CS_CPU_PORT0_VOQ_BASE			48
+#define CS_CPU_PORT_VOQ_STRIDE			8
+
+#define CS_LPB_PVID_NONE			4095
+
+#define CS_CLASS_PORT_RULE_PRIORITY		50
+#define CS_CLASS_CATCHALL_RULE_PRIORITY		0
+#define CS_CLASS_CATCHALL_IDX			CS_GE_PORT_COUNT
+
+#define CS_FWD_ENTRY_FIRST_IDX			1
+
+struct fe_table {
+	const char *name;
+	u16 access;
+	u16 entries;
+	u8 addr_bits;
+	u8 nregs;
+};
+
+struct fe_field {
+	u8 reg;
+	u8 bit;
+	u8 width;
+};
+
+#define FE_TABLE(_name, _access, _entries, _addr_bits, _nregs)		\
+	{								\
+		.name = _name,						\
+		.access = _access,					\
+		.entries = _entries,					\
+		.addr_bits = _addr_bits,				\
+		.nregs = _nregs,					\
+	}
+
+#define FE_FIELD(_reg, _bit, _width)					\
+	(&(const struct fe_field){					\
+		.reg = _reg,						\
+		.bit = _bit,						\
+		.width = _width,					\
+	})
+
+static const struct fe_table fe_table_an_bng_mac =
+	FE_TABLE("AN_BNG_MAC", FETOP_FE_AN_BNG_MAC_ACCESS,
+		 FE_AN_BNG_MAC_ENTRY_MAX, 4, 2);
+static const struct fe_table fe_table_l4_port_rngs =
+	FE_TABLE("L4_PORT_RNGS", FETOP_FE_L4_PORT_RNGS_ACCESS,
+		 FE_L4_PORT_RNGS_MAX, 5, 2);
+static const struct fe_table fe_table_etype =
+	FE_TABLE("ETYPE", FETOP_FE_ETYPE_ACCESS, FE_ETH_CAM_ENTRY_MAX, 6, 1);
+static const struct fe_table fe_table_llc_hdr =
+	FE_TABLE("LLC_HDR", FETOP_FE_LLC_HDR_ACCESS, FE_LLC_ENTRY_MAX, 2, 1);
+static const struct fe_table fe_table_lpb =
+	FE_TABLE("LPB", FETOP_FE_LPB_ACCESS, FE_LPB_ENTRY_MAX, 3, 1);
+static const struct fe_table fe_table_class =
+	FE_TABLE("CLASS", FETOP_FE_CLASS_ACCESS, FE_CLASS_ENTRY_MAX, 6, 20);
+static const struct fe_table fe_table_sdb =
+	FE_TABLE("SDB", FETOP_FE_SDB_ACCESS, FE_SDB_ENTRY_MAX, 6, 7);
+static const struct fe_table fe_table_vln =
+	FE_TABLE("VLN", FETOP_FE_VLN_ACCESS, FE_VLAN_ENTRY_MAX, 12, 2);
+static const struct fe_table fe_table_fwdrslt =
+	FE_TABLE("FWDRSLT", FETOP_FE_FWDRSLT_ACCESS,
+		 FE_FWD_RESULT_ENTRY_MAX, 13, 4);
+static const struct fe_table fe_table_qosrslt =
+	FE_TABLE("QOSRSLT", FETOP_FE_QOSRSLT_ACCESS,
+		 FE_QOS_RESULT_ENTRY_MAX, 7, 2);
+static const struct fe_table fe_table_voqpol =
+	FE_TABLE("VOQPOL", FETOP_FE_VOQPOL_ACCESS, FE_VOQ_POL_ENTRY_MAX, 9, 2);
+static const struct fe_table fe_table_fvlan =
+	FE_TABLE("FVLAN", FETOP_FE_FVLAN_ACCESS, FE_FVLAN_ENTRY_MAX, 9, 2);
+static const struct fe_table fe_table_l3tbl =
+	FE_TABLE("L3TBL", FETOP_FE_L3TBL_ACCESS, FE_L3_ADDR_ENTRY_MAX, 10, 5);
+static const struct fe_table fe_table_l2tbl =
+	FE_TABLE("L2TBL", FETOP_FE_L2TBL_ACCESS,
+		 FE_L2_ADDR_PAIR_ENTRY_MAX, 9, 4);
+static const struct fe_table fe_table_aclrule =
+	FE_TABLE("ACLRULE", FETOP_FE_ACLRULE_ACCESS, FE_ACL_ENTRY_MAX, 7, 28);
+static const struct fe_table fe_table_aclaction =
+	FE_TABLE("ACLACTION", FETOP_FE_ACLACTION_ACCESS,
+		 FE_ACL_ENTRY_MAX, 7, 10);
+static const struct fe_table fe_table_pe_voq_drp =
+	FE_TABLE("PE_VOQ_DRP", FETOP_FE_PE_VOQ_DRP_ACCESS,
+		 FE_PE_VOQ_DROP_ENTRY_MAX, 5, 1);
+static const struct fe_table fe_table_hash_mask =
+	FE_TABLE("HASH_MASK", FETOP_HASH_MASK_MEM_ACCESS,
+		 FE_HASH_MASK_ENTRY_MAX, 6, 5);
+static const struct fe_table fe_table_pktlen_rngs =
+	FE_TABLE("PKTLEN_RNGS", FETOP_FE_PKTLEN_RNGS_ACCESS,
+		 FE_PKTLEN_RANGE_ENTRY_MAX, 2, 1);
+
+static const struct fe_table *const fe_flush_tables[] = {
+	&fe_table_an_bng_mac,
+	&fe_table_l4_port_rngs,
+	&fe_table_etype,
+	&fe_table_llc_hdr,
+	&fe_table_lpb,
+	&fe_table_class,
+	&fe_table_sdb,
+	&fe_table_vln,
+	&fe_table_fwdrslt,
+	&fe_table_qosrslt,
+	&fe_table_voqpol,
+	&fe_table_fvlan,
+	&fe_table_l3tbl,
+	&fe_table_l2tbl,
+	&fe_table_aclrule,
+	&fe_table_aclaction,
+	&fe_table_pe_voq_drp,
+	&fe_table_hash_mask,
+	&fe_table_pktlen_rngs,
+};
+
+#define FE_LPB_LSPID				FE_FIELD(0, 0, 4)
+#define FE_LPB_PVID				FE_FIELD(0, 4, 12)
+#define FE_LPB_MEM_PARITY			FE_FIELD(0, 24, 1)
+
+#define FE_CLASS_SVIDX				FE_FIELD(0, 0, 6)
+#define FE_CLASS_LSPID				FE_FIELD(0, 6, 4)
+#define FE_CLASS_LSPID_MASK			FE_FIELD(15, 1, 1)
+#define FE_CLASS_IP_DA_MASK			FE_FIELD(16, 12, 9)
+#define FE_CLASS_IP_SA_MASK			FE_FIELD(16, 21, 9)
+#define FE_CLASS_MCGID				FE_FIELD(18, 12, 9)
+#define FE_CLASS_MCGID_MASK			FE_FIELD(18, 21, 9)
+#define FE_CLASS_RSVD_621_606			FE_FIELD(18, 30, 16)
+#define FE_CLASS_RULE_PRI			FE_FIELD(19, 14, 6)
+#define FE_CLASS_ENTRY_VLD			FE_FIELD(19, 20, 1)
+#define FE_CLASS_MEM_PARITY			FE_FIELD(19, 21, 1)
+#define FE_CLASS_DATA19_RSRVD			FE_FIELD(19, 22, 10)
+
+#define FE_SDB_TTL_HOPLIMIT_ZERO_DISCARD_EN	FE_FIELD(4, 26, 1)
+#define FE_SDB_UU_FLOWIDX			FE_FIELD(5, 1, 13)
+#define FE_SDB_BC_FLOWIDX			FE_FIELD(5, 16, 13)
+#define FE_SDB_UM_FLOWIDX			FE_FIELD(5, 29, 13)
+#define FE_SDB_DROP				FE_FIELD(6, 11, 1)
+#define FE_SDB_ACL_DISABLE			FE_FIELD(6, 13, 1)
+#define FE_SDB_MEM_PARITY			FE_FIELD(6, 14, 1)
+
+#define FWD_VOQ_POLICY				FE_FIELD(0, 0, 1)
+#define FWD_POL_POLICY				FE_FIELD(0, 1, 2)
+#define FWD_VOQ_POL_TBL_IDX			FE_FIELD(0, 3, 9)
+#define FWD_DROP				FE_FIELD(3, 14, 1)
+#define FWD_MEM_PARITY				FE_FIELD(3, 17, 1)
+
+#define FWD_VOQPOL_VOQ_BASE			FE_FIELD(0, 0, 8)
+#define FWD_VOQPOL_COS_NOP			FE_FIELD(1, 7, 1)
+#define FWD_VOQPOL_MEM_PARITY			FE_FIELD(1, 8, 1)
+
+static void fe_set_field(u32 *data, const struct fe_field *f, u32 val)
+{
+	u64 mask = GENMASK_ULL(f->bit + f->width - 1, f->bit);
+	u64 v = ((u64)val << f->bit) & mask;
+
+	data[f->reg] &= ~lower_32_bits(mask);
+	data[f->reg] |= lower_32_bits(v);
+
+	if (upper_32_bits(mask)) {
+		data[f->reg + 1] &= ~upper_32_bits(mask);
+		data[f->reg + 1] |= upper_32_bits(v);
+	}
+}
+
+static int fe_table_write(struct device *dev, void __iomem *fe,
+			  const struct fe_table *t, unsigned int idx,
+			  const u32 *data)
+{
+	unsigned int i;
+	u32 val;
+	int ret;
+
+	for (i = 0; i < t->nregs; i++)
+		writel(data[i], fe + t->access + (t->nregs - i) * 4);
+
+	writel(FE_TABLE_ACCESS_START | FE_TABLE_ACCESS_RBW_WRITE |
+	       (idx & GENMASK(t->addr_bits - 1, 0)), fe + t->access);
+
+	ret = readl_poll_timeout(fe + t->access, val,
+				 !(val & FE_TABLE_ACCESS_START), 0,
+				 FE_TABLE_ACCESS_TIMEOUT_US);
+	if (ret)
+		dev_err(dev, "FE %s table entry %u write timeout\n",
+			t->name, idx);
+
+	return ret;
+}
+
+static int fe_table_flush(struct device *dev, void __iomem *fe,
+			  const struct fe_table *t)
+{
+	static const u32 zero[FE_TABLE_DATA_REGS_MAX];
+	unsigned int idx;
+	int ret;
+
+	for (idx = 0; idx < t->entries; idx++) {
+		ret = fe_table_write(dev, fe, t, idx, zero);
+		if (ret)
+			return ret;
+	}
+
+	dev_dbg(dev, "FE %s table flushed (%u entries)\n", t->name,
+		t->entries);
+
+	return 0;
+}
+
+static int fe_hash_init(struct device *dev, void __iomem *fe)
+{
+	u32 val;
+	int ret;
+
+	ret = readl_poll_timeout(fe + FETOP_HASH_STATUS, val,
+				 val & FE_HASH_STATUS_READY_FOR_INIT,
+				 FE_HASH_INIT_POLL_US, FE_HASH_INIT_TIMEOUT_US);
+	if (ret) {
+		dev_err(dev, "FE hash not ready for init: 0x%08x\n", val);
+		return ret;
+	}
+
+	writel(FE_HASH_INIT_INIT, fe + FETOP_HASH_INIT);
+
+	ret = read_poll_timeout(readl, val,
+				!(val & FE_HASH_STATUS_INIT_IN_PROGRESS),
+				FE_HASH_INIT_POLL_US, FE_HASH_INIT_TIMEOUT_US,
+				true, fe + FETOP_HASH_STATUS);
+	if (ret) {
+		dev_err(dev, "FE hash init timeout: 0x%08x\n", val);
+		return ret;
+	}
+
+	return 0;
+}
+
+static int fe_lpb_write(struct device *dev, void __iomem *fe,
+			unsigned int lspid)
+{
+	u32 data[1] = {};
+
+	fe_set_field(data, FE_LPB_LSPID, lspid);
+	fe_set_field(data, FE_LPB_PVID, CS_LPB_PVID_NONE);
+	fe_set_field(data, FE_LPB_MEM_PARITY, 0);
+
+	return fe_table_write(dev, fe, &fe_table_lpb, lspid, data);
+}
+
+static int fe_voqpol_write(struct device *dev, void __iomem *fe,
+			   unsigned int idx, unsigned int voq_base)
+{
+	u32 data[2] = {};
+
+	fe_set_field(data, FWD_VOQPOL_VOQ_BASE, voq_base);
+	fe_set_field(data, FWD_VOQPOL_COS_NOP, 0);
+	fe_set_field(data, FWD_VOQPOL_MEM_PARITY, 0);
+
+	return fe_table_write(dev, fe, &fe_table_voqpol, idx, data);
+}
+
+static int fe_fwdrslt_write(struct device *dev, void __iomem *fe,
+			    unsigned int idx, unsigned int voqpol_idx)
+{
+	u32 data[4] = {};
+
+	fe_set_field(data, FWD_VOQ_POLICY, 1);
+	fe_set_field(data, FWD_POL_POLICY, 0);
+	fe_set_field(data, FWD_VOQ_POL_TBL_IDX, voqpol_idx);
+	fe_set_field(data, FWD_DROP, 0);
+	fe_set_field(data, FWD_MEM_PARITY, 0);
+
+	return fe_table_write(dev, fe, &fe_table_fwdrslt, idx, data);
+}
+
+static int fe_sdb_write(struct device *dev, void __iomem *fe,
+			unsigned int idx, unsigned int fwdrslt_idx)
+{
+	u32 data[7] = {};
+
+	fe_set_field(data, FE_SDB_TTL_HOPLIMIT_ZERO_DISCARD_EN, 1);
+	fe_set_field(data, FE_SDB_UU_FLOWIDX, fwdrslt_idx);
+	fe_set_field(data, FE_SDB_BC_FLOWIDX, fwdrslt_idx);
+	fe_set_field(data, FE_SDB_UM_FLOWIDX, fwdrslt_idx);
+	fe_set_field(data, FE_SDB_DROP, 0);
+	fe_set_field(data, FE_SDB_ACL_DISABLE, 0);
+	fe_set_field(data, FE_SDB_MEM_PARITY, 0);
+
+	return fe_table_write(dev, fe, &fe_table_sdb, idx, data);
+}
+
+static int fe_class_write(struct device *dev, void __iomem *fe,
+			  unsigned int idx, unsigned int sdb_idx,
+			  unsigned int lspid, unsigned int lspid_mask,
+			  unsigned int rule_priority)
+{
+	u32 data[20];
+	unsigned int i;
+
+	for (i = 0; i < ARRAY_SIZE(data); i++)
+		data[i] = U32_MAX;
+
+	fe_set_field(data, FE_CLASS_SVIDX, sdb_idx);
+	fe_set_field(data, FE_CLASS_LSPID, lspid);
+	fe_set_field(data, FE_CLASS_LSPID_MASK, lspid_mask);
+	fe_set_field(data, FE_CLASS_IP_DA_MASK, 0);
+	fe_set_field(data, FE_CLASS_IP_SA_MASK, 0);
+	fe_set_field(data, FE_CLASS_MCGID, 0);
+	fe_set_field(data, FE_CLASS_MCGID_MASK, 0);
+	fe_set_field(data, FE_CLASS_RSVD_621_606, 0);
+	fe_set_field(data, FE_CLASS_RULE_PRI, rule_priority);
+	fe_set_field(data, FE_CLASS_ENTRY_VLD, 1);
+	fe_set_field(data, FE_CLASS_MEM_PARITY, 0);
+	fe_set_field(data, FE_CLASS_DATA19_RSRVD, 0);
+
+	return fe_table_write(dev, fe, &fe_table_class, idx, data);
+}
+
+static int fe_cpu_path_setup(struct device *dev, void __iomem *fe,
+			     unsigned int idx, unsigned int lspid,
+			     unsigned int lspid_mask, unsigned int voq_base,
+			     unsigned int rule_priority)
+{
+	unsigned int fwd_idx = CS_FWD_ENTRY_FIRST_IDX + idx;
+	int ret;
+
+	ret = fe_voqpol_write(dev, fe, fwd_idx, voq_base);
+	if (ret)
+		return ret;
+
+	ret = fe_fwdrslt_write(dev, fe, fwd_idx, fwd_idx);
+	if (ret)
+		return ret;
+
+	ret = fe_sdb_write(dev, fe, idx, fwd_idx);
+	if (ret)
+		return ret;
+
+	ret = fe_class_write(dev, fe, idx, idx, lspid, lspid_mask,
+			     rule_priority);
+	if (ret)
+		return ret;
+
+	dev_dbg(dev, "FE class %u: lspid %u mask %u -> sdb %u fwd %u voq %u\n",
+		idx, lspid, lspid_mask, idx, fwd_idx, voq_base);
+
+	return 0;
+}
+
+int cs752x_fe_init(struct device *dev, void __iomem *fe)
+{
+	unsigned int i;
+	u32 val;
+	int ret;
+
+	val = readl(fe + FETOP_FE_STS_GLBL);
+	if (!(val & FE_STS_GLBL_MEM_INIT_DONE))
+		dev_dbg(dev, "FE_STS_GLBL mem_init_done not set: 0x%08x\n",
+			val);
+
+	for (i = 0; i < ARRAY_SIZE(fe_flush_tables); i++) {
+		ret = fe_table_flush(dev, fe, fe_flush_tables[i]);
+		if (ret)
+			return ret;
+	}
+
+	ret = fe_hash_init(dev, fe);
+	if (ret)
+		return ret;
+
+	for (i = 0; i < FE_LPB_ENTRY_MAX; i++) {
+		ret = fe_lpb_write(dev, fe, i);
+		if (ret)
+			return ret;
+	}
+
+	for (i = 0; i < CS_GE_PORT_COUNT; i++) {
+		ret = fe_cpu_path_setup(dev, fe, i, i, 0,
+					CS_CPU_PORT0_VOQ_BASE +
+					i * CS_CPU_PORT_VOQ_STRIDE,
+					CS_CLASS_PORT_RULE_PRIORITY);
+		if (ret)
+			return ret;
+	}
+
+	ret = fe_cpu_path_setup(dev, fe, CS_CLASS_CATCHALL_IDX, 0, 1,
+				CS_CPU_PORT0_VOQ_BASE,
+				CS_CLASS_CATCHALL_RULE_PRIORITY);
+	if (ret)
+		return ret;
+
+	writel(FIELD_PREP(FE_PE_CONFIG_1_INS_CPUHDR_VOQ,
+			  FE_PE_CONFIG_1_ALL_CPU_PORTS) |
+	       FE_PE_CONFIG_1_INS_CPUHDR_CRYPTO |
+	       FE_PE_CONFIG_1_INS_CPUHDR_ENCAP |
+	       FIELD_PREP(FE_PE_CONFIG_1_PARSE_LIMIT,
+			  FE_PE_CONFIG_1_PARSE_LIMIT_MIN_CYCLE),
+	       fe + FETOP_FE_PE_CONFIG_1);
+
+	dev_dbg(dev, "FE_PE_CONFIG_1 0x%08x, FE_PRSR_CFG_0 0x%08x\n",
+		readl(fe + FETOP_FE_PE_CONFIG_1),
+		readl(fe + FETOP_FE_PRSR_CFG_0));
+
+	return 0;
+}
diff --git a/drivers/net/ethernet/cortina/cs752x_ne.c b/drivers/net/ethernet/cortina/cs752x_ne.c
new file mode 100644
index 000000000..081b42079
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs752x_ne.c
@@ -0,0 +1,1869 @@
+// SPDX-License-Identifier: GPL-2.0
+#include <linux/bitfield.h>
+#include <linux/bits.h>
+#include <linux/delay.h>
+#include <linux/dma-mapping.h>
+#include <linux/etherdevice.h>
+#include <linux/hrtimer.h>
+#include <linux/ethtool.h>
+#include <linux/interrupt.h>
+#include <linux/io.h>
+#include <linux/iopoll.h>
+#include <linux/module.h>
+#include <linux/mfd/syscon.h>
+#include <linux/regmap.h>
+#include <linux/reset.h>
+#include <linux/netdevice.h>
+#include <linux/of.h>
+#include <linux/of_net.h>
+#include <linux/of_reserved_mem.h>
+#include <linux/phylink.h>
+#include <linux/platform_device.h>
+#include <linux/skbuff.h>
+#include <linux/spinlock.h>
+#include <linux/rtnetlink.h>
+#include <linux/sizes.h>
+#include <linux/workqueue.h>
+#include <linux/xarray.h>
+
+#include "cs752x_ne.h"
+
+#define CS_NE_PORTS			3
+#define CS_NE_RX_INSTANCES		9
+#define CS_NE_TX_INSTANCES		2
+#define CS_NE_VOQS			112
+#define CS_NE_CPU_VOQ_BASE		48
+#define CS_NE_MAX_PKT_LEN		9022
+#define CS_NE_MIN_PKT_LEN		64
+#define CS_NE_MAX_CPU_BUFFERS		4096
+#define CS_NE_BUF_DATA_MAX		3584
+#define CS_NE_BUF_HDR_OFF		0x100
+#define CS_NE_TX_DESC_ORDER		10
+#define CS_NE_TX_DESC_NUM		BIT(CS_NE_TX_DESC_ORDER)
+#define CS_NE_TX_MIN_LEN		24
+#define CS_NE_TX_MAX_FRAGS		16
+#define CS_NE_TX_TIMER_US		200
+#define CS_NE_TX_STOP_TIMER_US		100000
+#define CS_NE_TX_REAP_THRESH		(CS_NE_TX_DESC_NUM / 4)
+#define CS_NE_ACCESS_TIMEOUT_US		10000
+#define CS_NE_RX_TAIL_SETTLE_US		16
+#define CS_NE_HDRA_CPU_PKT		0xc30001
+
+#define GLOBAL_NETWORK_ENGINE_INTENABLE_0	0x074
+#define GLOBAL_IO_DRIVE_STRENGTH		0x0b4
+#define   GMAC_DS_MASK				GENMASK(1, 0)
+
+#define NI_INTF_RST_CONFIG		0x000
+#define   NI_INTF_RST_GE_ALL		GENMASK(2, 0)
+#define NI_ETH_INT_CONFIG1		0x004
+#define   NI_INT_CFG_GE_MASK(p)		(GENMASK(2, 0) << ((p) * 8))
+#define   NI_INT_CFG_GE(p, v)		((v) << ((p) * 8))
+#define   NI_INT_CFG_RGMII_1000		2
+#define   NI_INT_CFG_RGMII_100		3
+#define   NI_PHY_MODE_GE(p)		BIT(4 + (p) * 8)
+#define   NI_RMII_CLKSRC_GE(p)		BIT(5 + (p) * 8)
+#define   NI_TX_USE_GEFIFO_GE(p)	BIT(6 + (p) * 8)
+#define   NI_INV_CLK_OUT_GE(p)		BIT(7 + (p) * 8)
+#define NI_ETH_INT_CONFIG2		0x008
+#define   NI_INT_CONFIG2_GE_MASK(p)	(0xff << ((p) * 8))
+#define   NI_TX_INTF_LP_TIME_GE(p)	BIT(5 + (p) * 8)
+#define NI_ETH_MGMT_PT_CONFIG		0x00c
+#define NI_ETH_MAC_CONFIG0(p)		(0x010 + (p) * 12)
+#define   NI_MAC_SPEED_10		BIT(0)
+#define   NI_MAC_HALF_DUPLEX		BIT(1)
+#define   NI_MAC_RX_EN			BIT(2)
+#define   NI_MAC_TX_EN			BIT(3)
+#define   NI_MAC_RX_FLOW_DISABLE	BIT(8)
+#define   NI_MAC_TX_FLOW_DISABLE	BIT(12)
+#define   NI_MAC_RX_RST			BIT(30)
+#define   NI_MAC_TX_RST			BIT(31)
+#define   NI_MAC_CONFIG0_INIT		0xc0100800
+#define NI_ETH_MAC_CONFIG2(p)		(0x018 + (p) * 12)
+#define NI_MAC_ADDR0			0x040
+#define NI_MAC_ADDR1			0x044
+#define NI_PKT_LEN_CONFIG		0x050
+#define   NI_MAX_PKT_SIZE		GENMASK(13, 0)
+#define   NI_MIN_PKT_SIZE		GENMASK(25, 16)
+#define NI_RX_CNTRL_CONFIG0(i)		(0x058 + (i) * 8)
+#define   NI_RUNT_DROP_DIS		BIT(6)
+#define NI_RX_CNTRL_CONFIG1(i)		(0x05c + (i) * 8)
+#define NI_RX_AGG_CONFIG		0x098
+#define   NI_RX_PORT_CAL_DIS		BIT(0)
+#define NI_RX_PORT_CAL_ACCESS		0x0ac
+#define NI_RX_PORT_CAL_DATA		0x0b0
+#define NI_SCH_BP_THLD_ETH		0x0c0
+#define   NI_SCH_BP_THLD_ETH_ASIC	0x082a00f8
+#define NI_MISC_CONFIG			0x0c8
+#define   NI_MC_ACCEPT_ALL		BIT(14)
+#define   NI_RXMIB_MODE			BIT(16)
+#define   NI_TXMIB_MODE			BIT(17)
+#define NI_TX_VOQ_LKUP_ACCESS		0x0cc
+#define NI_TX_VOQ_LKUP_DATA1		0x0d0
+#define NI_TX_VOQ_LKUP_DATA0		0x0d4
+#define   NI_TXEM_DISCRC		BIT(4)
+#define NI_CPUXRAM_ADRCFG_RX(i)		(0x1ac + (i) * 4)
+#define NI_CPUXRAM_ADRCFG_TX(i)		(0x1d0 + (i) * 4)
+#define NI_CPUXRAM_CFG			0x1d8
+#define   NI_CPUXRAM_PKT_DIS_MASK	GENMASK(10, 0)
+#define   NI_CPUXRAM_PTR_TOGGLE		GENMASK(9, 0)
+#define NI_CPUXRAM_SCH_BP_CFG(i)	(0x1e4 + (i) * 4)
+#define   NI_XRAM_SCH_RDY_MODE		BIT(15)
+#define   NI_XRAM_SCH_RDY_FREE_THLD	30
+#define NI_CPUXRAM_CPU_CFG_RX(i)	(0x204 + (i) * 24)
+#define NI_CPUXRAM_CPU_STA_RX(i)	(0x208 + (i) * 24)
+#define NI_CPUXRAM_INT_COLSC_CFG(i)	(0x20c + (i) * 24)
+#define   NI_INT_COLSC_DLY_TIME		GENMASK(19, 0)
+#define   NI_INT_COLSC_PKT		GENMASK(29, 20)
+#define   NI_INT_COLSC_FIRST_EN		BIT(30)
+#define   NI_INT_COLSC_EN		BIT(31)
+#define NI_CPUXRAM_RXPKT_INTERRUPT(i)	(0x3a0 + (i) * 8)
+#define NI_CPUXRAM_RXPKT_INTENABLE(i)	(0x3a4 + (i) * 8)
+#define   NI_XRAM_PTR_MASK		GENMASK(10, 0)
+
+#define NE_ACCESS			BIT(31)
+#define NE_ACCESS_WRITE			BIT(30)
+
+#define QM_CONFIG_0			0x000
+#define   QM_INIT			BIT(0)
+#define   QM_EGRESS_FC_INT_THRESHOLD	GENMASK(5, 4)
+#define   QM_MTU			GENMASK(15, 8)
+#define   QM_MAX_PKT_LEN		GENMASK(29, 16)
+#define   QM_CPU_FULL_ACCESS		BIT(31)
+#define QM_CONFIG_1			0x004
+#define   QM_MEM_CONFIG			GENMASK(1, 0)
+#define   QM_CPU_BANKS			GENMASK(6, 4)
+#define   QM_PAGING_SIZE		BIT(9)
+#define QM_STATUS_0			0x014
+#define   QM_INIT_DONE			BIT(0)
+#define QM_CPU_PATH_CONFIG_0		0x038
+#define   QM_CPU_BUFFERS		GENMASK(12, 0)
+#define   QM_MAX_CPU_PKT_LEN		GENMASK(29, 16)
+#define QM_CPU_PATH_CONFIG_1		0x03c
+#define   QM_LINUX_MODE			BIT(0)
+#define   QM_LINUX_2BYTE_ALIGN		BIT(2)
+#define QM_CPU_PATH_VOQ_MAP(i)		(0x040 + (i) * 4)
+#define QM_CPU_PATH_LINUX_SDRAM_ADDR(i)	(0x060 + (i) * 4)
+#define QM_CPU_PATH_STATUS_0		0x080
+#define   QM_SDRAM_ADDR_FIFO_WR_CNT	GENMASK(4, 0)
+#define QM_QUE_PROFILE_MEM_ACCESS	0x1c0
+#define QM_QUE_PROFILE_MEM_DATA		0x1c4
+#define   QM_PROFILE_PACKET_PORT	BIT(1)
+#define   QM_PROFILE_DS_SPEED		GENMASK(10, 2)
+#define   QM_PROFILE_PRIORITY		GENMASK(13, 11)
+#define QM_SPARE			0x1f8
+
+#define DMA_LSO_RXDMA_CONTROL		0x000
+#define DMA_LSO_TXDMA_CONTROL		0x004
+#define   DMA_ENABLE			BIT(0)
+#define   DMA_BURST_LEN			GENMASK(3, 2)
+#define DMA_LSO_TXQ_CONTROL(q)		(0x008 + (q) * 4)
+#define DMA_LSO_TXQ_BASE_DEPTH(q)	(0x0c8 + (q) * 4)
+#define DMA_LSO_TXQ_WPTR(q)		(0x0e8 + (q) * 8)
+#define DMA_LSO_TXQ_RPTR(q)		(0x0ec + (q) * 8)
+#define   DMA_PTR_MASK			GENMASK(12, 0)
+#define DMA_LSO_INTERRUPT_0		0x1d0
+#define DMA_LSO_INTENABLE_0		0x1d4
+#define DMA_LSO_TXQ_INTERRUPT(q)	(0x228 + (q) * 8)
+#define DMA_LSO_TXQ_INTENABLE(q)	(0x22c + (q) * 8)
+#define DMA_AXI_CONFIG			0x300
+#define   DMA_AXI_WRITE_ARB_CH0_2	GENMASK(15, 13)
+#define   DMA_AXI_READ_ARB_CH0_2	GENMASK(23, 21)
+#define   DMA_AXI_WRITE_OUTTRANS	GENMASK(25, 24)
+#define DMA_AXI_READ_DRR_0_3		0x30c
+#define DMA_AXI_READ_DRR_4_7		0x310
+#define DMA_AXI_WRITE_DRR_0_3		0x314
+#define DMA_AXI_WRITE_DRR_4_7		0x318
+#define DMA_AXI_READ_TIMEOUT		0x320
+#define DMA_AXI_WRITE_TIMEOUT		0x324
+
+#define FETOP_FE_PRSR_CFG_0		0x03c
+#define   FE_L4_CHKSUM_CHK_DISABLE	BIT(8)
+
+#define TX_DESC_OWN			BIT(31)
+#define TX_DESC_SOF			BIT(28)
+#define TX_DESC_EOF			BIT(27)
+#define TX_DESC_LEN			GENMASK(15, 0)
+#define TX_LSO_SEGMENT_EN		BIT(16)
+#define TX_LSO_IP_LENFIX_EN		BIT(22)
+#define TX_HDRA_DVOQ			GENMASK(10, 3)
+
+#define XR_NEXT_LINK			GENMASK(11, 0)
+#define XR_ERROR			BIT(29)
+#define XR_OWNERSHIP			BIT(31)
+#define HDRE_PKT_SIZE			GENMASK(13, 0)
+#define HDRE_CPU_HEADER_HI		BIT(4)
+#define XRAM_BUF_MASK			0xfffff000
+#define CS_NE_RX_DMA_SHIFT		12
+#define CS_NE_RX_BUF_SIZE		SZ_4K
+#define CS_NE_RX_MAX_BUFS		4
+
+static const u16 cs_ne_xram_rx_units[CS_NE_RX_INSTANCES] = {
+	525, 525, 525, 7, 7, 7, 91, 91, 56
+};
+
+static const u16 cs_ne_xram_tx_units[CS_NE_TX_INSTANCES] = { 214, 0 };
+static const u16 cs_ne_rx_pool_size[CS_NE_PORTS] = { 1024, 1024, 256 };
+
+struct cs_ne;
+
+enum cs_ne_rx_state {
+	CS_NE_RX_PENDING,
+	CS_NE_RX_HW,
+	CS_NE_RX_CPU,
+};
+
+struct cs_ne_rx_buf {
+	struct page *page;
+	void *cpu;
+	dma_addr_t dma;
+	struct list_head pending;
+	enum cs_ne_rx_state state;
+	u16 sync_off;
+	u16 sync_len;
+	u8 pool;
+};
+
+struct cs_ne_tx_buf {
+	struct sk_buff *skb;
+	dma_addr_t dma;
+	u16 len;
+	bool page;
+};
+
+struct cs_ne_txq {
+	u32 *desc;
+	dma_addr_t desc_dma;
+	struct cs_ne_tx_buf bufs[CS_NE_TX_DESC_NUM];
+	u16 head;
+	u16 tail;
+	/* Serializes shared TX ring ownership and all port queue state. */
+	spinlock_t lock;
+	struct hrtimer timer;
+	struct cs_ne *ne;
+	/* Shared admission gate: prevents new TX and queue wakeups while down. */
+	bool stopping;
+	/* Terminal cleanup, unlike last-port close, also stops completion polls. */
+	bool poll_stopping;
+	bool slow_poll;
+	bool fault;
+};
+
+struct cs_ne_port {
+	struct cs_ne *ne;
+	struct net_device *ndev;
+	struct device_node *np;
+	struct napi_struct napi;
+	struct phylink *phylink;
+	struct phylink_config phylink_config;
+	phy_interface_t interface;
+	int id;
+	int irq;
+	u32 rd;
+	/*
+	 * Published under txq.lock after IRQ/NAPI setup; gates shared wakeups.
+	 * netif_running() is already true while ndo_open() can still fail.
+	 */
+	bool opened;
+	bool registered;
+};
+
+#define CS_NE_NUM_RESETS 7
+static const char * const cs_ne_reset_names[CS_NE_NUM_RESETS] = {
+	"ni", "fe", "tm", "sch", "qm", "dma", "xram",
+};
+
+struct cs_ne {
+	struct device *dev;
+	/* Shared NI registers contain fields belonging to several MACs. */
+	spinlock_t ni_lock;
+	struct regmap *global;
+	struct reset_control_bulk_data resets[CS_NE_NUM_RESETS];
+	void __iomem *ni;
+	void __iomem *dma;
+	void __iomem *fe;
+	void __iomem *qm;
+	void __iomem *tm;
+	void __iomem *sch;
+	void __iomem *xram;
+	struct cs_ne_port *ports[CS_NE_PORTS];
+	struct cs_ne_txq txq;
+	/* RX mappings stay registered until hardware has been quiesced. */
+	struct xarray rx_buffers;
+	struct list_head rx_pending;
+	/* Serializes RX ownership, FIFO writes, retry and IRQ rearm/stop. */
+	spinlock_t rx_lock;
+	struct delayed_work rx_retry;
+	bool rx_stopping;
+	bool hw_active;
+	bool hw_accessible;
+	bool dma_quiesced;
+	bool dma_pinned;
+	bool hw_cleanup_done;
+};
+
+static u32 ni_rd(struct cs_ne *ne, u32 off)
+{
+	return readl(ne->ni + off);
+}
+
+static void ni_wr(struct cs_ne *ne, u32 off, u32 val)
+{
+	writel(val, ne->ni + off);
+}
+
+static void ni_rmw(struct cs_ne *ne, u32 off, u32 mask, u32 val)
+{
+	unsigned long flags;
+
+	spin_lock_irqsave(&ne->ni_lock, flags);
+	writel((readl(ne->ni + off) & ~mask) | (val & mask), ne->ni + off);
+	spin_unlock_irqrestore(&ne->ni_lock, flags);
+}
+
+static u32 qm_rd(struct cs_ne *ne, u32 off)
+{
+	return readl(ne->qm + off);
+}
+
+static void qm_wr(struct cs_ne *ne, u32 off, u32 val)
+{
+	writel(val, ne->qm + off);
+}
+
+static int cs_ne_wait_access(void __iomem *reg)
+{
+	u32 val;
+
+	return readl_poll_timeout_atomic(reg, val, !(val & NE_ACCESS), 1,
+					 CS_NE_ACCESS_TIMEOUT_US);
+}
+
+static int cs_ne_set_port_calendar(struct cs_ne *ne, u16 slot, u8 pspid)
+{
+	ni_wr(ne, NI_RX_PORT_CAL_DATA, pspid & 0x7);
+	ni_wr(ne, NI_RX_PORT_CAL_ACCESS,
+	      NE_ACCESS | NE_ACCESS_WRITE | (slot & 0x7f));
+	return cs_ne_wait_access(ne->ni + NI_RX_PORT_CAL_ACCESS);
+}
+
+static int cs_ne_set_voq_map(struct cs_ne *ne, u8 voq, u8 did)
+{
+	ni_wr(ne, NI_TX_VOQ_LKUP_DATA0, (did & 0xf) | NI_TXEM_DISCRC);
+	ni_wr(ne, NI_TX_VOQ_LKUP_DATA1, 0);
+	ni_wr(ne, NI_TX_VOQ_LKUP_ACCESS,
+	      NE_ACCESS | NE_ACCESS_WRITE | (voq & 0x7f));
+	return cs_ne_wait_access(ne->ni + NI_TX_VOQ_LKUP_ACCESS);
+}
+
+static int cs_ne_voq_map_init(struct cs_ne *ne)
+{
+	int voq, did, ret;
+
+	for (voq = 0; voq < CS_NE_VOQS; voq++) {
+		if (voq < 24)
+			did = voq / 8;
+		else if (voq < 32)
+			did = 4;
+		else if (voq < 40)
+			did = 5;
+		else if (voq < 48)
+			did = 6;
+		else
+			did = 8 + (voq - 48) / 8;
+		ret = cs_ne_set_voq_map(ne, voq, did);
+		if (ret)
+			return dev_err_probe(ne->dev, ret, "VOQ map %d timeout\n", voq);
+	}
+	return 0;
+}
+
+static int cs_ne_port_calendar_init(struct cs_ne *ne)
+{
+	int ret, i, j;
+
+	for (i = 0; i < 12; i++) {
+		for (j = 0; j < 8; j++) {
+			ret = cs_ne_set_port_calendar(ne, i * 8 + j, j);
+			if (ret)
+				return dev_err_probe(ne->dev, ret, "port calendar timeout\n");
+		}
+	}
+	for (i = 0; i < 12; i++) {
+		ret = cs_ne_set_port_calendar(ne, i * 8 + 2, 4);
+		if (ret)
+			return dev_err_probe(ne->dev, ret, "port calendar override timeout\n");
+	}
+	return 0;
+}
+
+static void cs_ne_xram_init(struct cs_ne *ne)
+{
+	u32 next = 0, val;
+	int i;
+
+	for (i = 0; i < CS_NE_RX_INSTANCES; i++)
+		ni_wr(ne, NI_CPUXRAM_ADRCFG_RX(i), 0);
+	for (i = 0; i < CS_NE_TX_INSTANCES; i++)
+		ni_wr(ne, NI_CPUXRAM_ADRCFG_TX(i), 0);
+
+	for (i = 0; i < CS_NE_RX_INSTANCES; i++) {
+		val = 0;
+		if (cs_ne_xram_rx_units[i]) {
+			val = next | ((next + cs_ne_xram_rx_units[i] - 1) << 16);
+			next += cs_ne_xram_rx_units[i];
+		}
+		ni_wr(ne, NI_CPUXRAM_ADRCFG_RX(i), val);
+	}
+	for (i = 0; i < CS_NE_TX_INSTANCES; i++) {
+		val = 0;
+		if (cs_ne_xram_tx_units[i]) {
+			val = next | ((next + cs_ne_xram_tx_units[i] - 1) << 16);
+			next += cs_ne_xram_tx_units[i];
+		}
+		ni_wr(ne, NI_CPUXRAM_ADRCFG_TX(i), val);
+	}
+
+	ni_rmw(ne, NI_CPUXRAM_CFG, NI_CPUXRAM_PKT_DIS_MASK, 0);
+	ni_rmw(ne, NI_CPUXRAM_CFG, NI_CPUXRAM_PTR_TOGGLE, NI_CPUXRAM_PTR_TOGGLE);
+	ni_rmw(ne, NI_CPUXRAM_CFG, NI_CPUXRAM_PTR_TOGGLE, 0);
+}
+
+static int cs_ne_check_reserved_memory(struct cs_ne *ne)
+{
+	struct device_node *np;
+	struct reserved_mem *rmem;
+	bool no_map;
+
+	np = of_parse_phandle(ne->dev->of_node, "memory-region", 0);
+	if (!np)
+		return dev_err_probe(ne->dev, -EINVAL, "QM reserved memory is required\n");
+	rmem = of_reserved_mem_lookup(np);
+	no_map = of_property_read_bool(np, "no-map");
+	of_node_put(np);
+	/* Only the 512 MiB DDR layout is currently verified on CS7542. */
+	if (!rmem || !no_map || rmem->base != 0x1c000000 || rmem->size != SZ_64M)
+		return dev_err_probe(ne->dev, -EINVAL, "unsupported QM DDR reservation\n");
+	return 0;
+}
+
+static int cs_ne_qm_init_cfg(struct cs_ne *ne)
+{
+	u32 val;
+
+	val = FIELD_PREP(QM_MAX_PKT_LEN, CS_NE_MAX_PKT_LEN) |
+	      FIELD_PREP(QM_MTU, (ETH_DATA_LEN + ETH_HLEN) & 0xff) |
+	      FIELD_PREP(QM_EGRESS_FC_INT_THRESHOLD, 1);
+	qm_wr(ne, QM_CONFIG_0, val);
+
+	val = qm_rd(ne, QM_CONFIG_1);
+	val &= ~(QM_MEM_CONFIG | QM_CPU_BANKS | QM_PAGING_SIZE);
+	val |= FIELD_PREP(QM_MEM_CONFIG, 2) |
+	       FIELD_PREP(QM_CPU_BANKS, 7) | QM_PAGING_SIZE;
+	qm_wr(ne, QM_CONFIG_1, val);
+	qm_wr(ne, QM_SPARE, 0);
+	return 0;
+}
+
+static void cs_ne_qm_cpu_path_init(struct cs_ne *ne)
+{
+	int i;
+
+	qm_wr(ne, QM_CPU_PATH_CONFIG_0,
+	      FIELD_PREP(QM_CPU_BUFFERS, CS_NE_MAX_CPU_BUFFERS) |
+	      FIELD_PREP(QM_MAX_CPU_PKT_LEN, CS_NE_MAX_PKT_LEN + 16));
+	qm_wr(ne, QM_CPU_PATH_CONFIG_1, QM_LINUX_MODE | QM_LINUX_2BYTE_ALIGN);
+	for (i = 0; i < 8; i++)
+		qm_wr(ne, QM_CPU_PATH_VOQ_MAP(i),
+		      i | (i << 3) | (i << 6) | (i << 9) | (i << 12) |
+		      (i << 15) | (i << 18) | (i << 21));
+}
+
+static int cs_ne_qm_set_profile(struct cs_ne *ne, int idx, u32 data)
+{
+	int ret;
+
+	qm_wr(ne, QM_CONFIG_0, qm_rd(ne, QM_CONFIG_0) | QM_CPU_FULL_ACCESS);
+	qm_wr(ne, QM_QUE_PROFILE_MEM_DATA, data);
+	qm_wr(ne, QM_QUE_PROFILE_MEM_ACCESS,
+	      NE_ACCESS | NE_ACCESS_WRITE | (idx & 0x7f));
+	ret = cs_ne_wait_access(ne->qm + QM_QUE_PROFILE_MEM_ACCESS);
+	qm_wr(ne, QM_CONFIG_0, qm_rd(ne, QM_CONFIG_0) & ~QM_CPU_FULL_ACCESS);
+	return ret;
+}
+
+static int cs_ne_qm_init(struct cs_ne *ne)
+{
+	u32 val, data;
+	int ret, i;
+
+	qm_wr(ne, QM_CONFIG_0, qm_rd(ne, QM_CONFIG_0) | QM_INIT);
+	ret = readl_poll_timeout(ne->qm + QM_STATUS_0, val, val & QM_INIT_DONE,
+				 10, 100000);
+	qm_wr(ne, QM_CONFIG_0, qm_rd(ne, QM_CONFIG_0) & ~QM_INIT);
+	if (ret) {
+		dev_err(ne->dev, "QM init timeout, status 0x%08x\n", val);
+		return ret;
+	}
+
+	for (i = 0; i < CS_NE_VOQS; i++) {
+		data = FIELD_PREP(QM_PROFILE_DS_SPEED, 500);
+		if (i < 24)
+			data |= QM_PROFILE_PACKET_PORT |
+				FIELD_PREP(QM_PROFILE_PRIORITY, 3);
+		else if (i < 40)
+			data |= FIELD_PREP(QM_PROFILE_PRIORITY, 1);
+		else if (i < 48)
+			data |= FIELD_PREP(QM_PROFILE_PRIORITY, 4);
+		ret = cs_ne_qm_set_profile(ne, i, data);
+		if (ret) {
+			dev_err(ne->dev, "QM profile %d timeout\n", i);
+			return ret;
+		}
+	}
+	return 0;
+}
+
+static int cs_ne_dma_init(struct cs_ne *ne)
+{
+	struct cs_ne_txq *txq = &ne->txq;
+	u32 val;
+
+	txq->desc = dma_alloc_coherent(ne->dev, CS_NE_TX_DESC_NUM * 32,
+				       &txq->desc_dma, GFP_KERNEL);
+	if (!txq->desc)
+		return -ENOMEM;
+	txq->ne = ne;
+	txq->stopping = true;
+	spin_lock_init(&txq->lock);
+
+	writel(FIELD_PREP(DMA_BURST_LEN, 3), ne->dma + DMA_LSO_RXDMA_CONTROL);
+	writel(FIELD_PREP(DMA_BURST_LEN, 3), ne->dma + DMA_LSO_TXDMA_CONTROL);
+	writel(0, ne->dma + DMA_LSO_TXQ_CONTROL(0));
+	writel((txq->desc_dma & ~0xf) | CS_NE_TX_DESC_ORDER,
+	       ne->dma + DMA_LSO_TXQ_BASE_DEPTH(0));
+	txq->head = readl(ne->dma + DMA_LSO_TXQ_RPTR(0)) & DMA_PTR_MASK &
+		    (CS_NE_TX_DESC_NUM - 1);
+	txq->tail = txq->head;
+	writel(txq->head, ne->dma + DMA_LSO_TXQ_WPTR(0));
+
+	writel(0xfffc0000, ne->dma + DMA_AXI_READ_TIMEOUT);
+	writel(0xfffc0000, ne->dma + DMA_AXI_WRITE_TIMEOUT);
+	val = readl(ne->dma + DMA_AXI_CONFIG);
+	val |= DMA_AXI_WRITE_ARB_CH0_2 | DMA_AXI_READ_ARB_CH0_2 |
+	       DMA_AXI_WRITE_OUTTRANS;
+	writel(val, ne->dma + DMA_AXI_CONFIG);
+	writel(0xffffffff, ne->dma + DMA_AXI_READ_DRR_0_3);
+	writel(0x0000ffff, ne->dma + DMA_AXI_READ_DRR_4_7);
+	writel(0xffffffff, ne->dma + DMA_AXI_WRITE_DRR_0_3);
+	writel(0x0000ffff, ne->dma + DMA_AXI_WRITE_DRR_4_7);
+	writel(0, ne->dma + DMA_LSO_INTENABLE_0);
+	writel(0, ne->dma + DMA_LSO_TXQ_INTENABLE(0));
+	return 0;
+}
+
+static int cs_ne_ni_init(struct cs_ne *ne)
+{
+	u32 val;
+	int ret, i;
+
+	val = ni_rd(ne, NI_INTF_RST_CONFIG);
+	ni_wr(ne, NI_INTF_RST_CONFIG, val | NI_INTF_RST_GE_ALL);
+	ni_wr(ne, NI_INTF_RST_CONFIG, val & ~NI_INTF_RST_GE_ALL);
+
+	ni_wr(ne, NI_SCH_BP_THLD_ETH, NI_SCH_BP_THLD_ETH_ASIC);
+	for (i = 0; i < CS_NE_PORTS; i++)
+		ni_wr(ne, NI_ETH_MAC_CONFIG0(i), NI_MAC_CONFIG0_INIT);
+
+	ret = regmap_update_bits(ne->global, GLOBAL_IO_DRIVE_STRENGTH,
+				 GMAC_DS_MASK, GMAC_DS_MASK);
+	if (ret)
+		return ret;
+	ret = regmap_write(ne->global, GLOBAL_NETWORK_ENGINE_INTENABLE_0, 0);
+	if (ret)
+		return ret;
+
+	ni_rmw(ne, NI_RX_AGG_CONFIG, NI_RX_PORT_CAL_DIS, 0);
+	ret = cs_ne_port_calendar_init(ne);
+	if (ret)
+		return ret;
+	ret = cs_ne_qm_init_cfg(ne);
+	if (ret)
+		return ret;
+	cs_ne_xram_init(ne);
+	cs_ne_qm_cpu_path_init(ne);
+
+	for (i = 0; i < 8; i++)
+		ni_wr(ne, NI_RX_CNTRL_CONFIG1(i), 0);
+	for (i = 3; i < 6; i++)
+		ni_rmw(ne, NI_RX_CNTRL_CONFIG0(i), NI_RUNT_DROP_DIS,
+		       NI_RUNT_DROP_DIS);
+	for (i = 0; i < 8; i++)
+		ni_wr(ne, NI_CPUXRAM_SCH_BP_CFG(i),
+		      NI_XRAM_SCH_RDY_MODE | NI_XRAM_SCH_RDY_FREE_THLD);
+
+	ni_rmw(ne, NI_PKT_LEN_CONFIG, NI_MAX_PKT_SIZE | NI_MIN_PKT_SIZE,
+	       FIELD_PREP(NI_MAX_PKT_SIZE, CS_NE_MAX_PKT_LEN) |
+	       FIELD_PREP(NI_MIN_PKT_SIZE, CS_NE_MIN_PKT_LEN));
+	ni_rmw(ne, NI_ETH_MGMT_PT_CONFIG, GENMASK(2, 0), 3);
+	ni_rmw(ne, NI_MISC_CONFIG,
+	       NI_RXMIB_MODE | NI_TXMIB_MODE | NI_MC_ACCEPT_ALL,
+	       NI_RXMIB_MODE | NI_TXMIB_MODE | NI_MC_ACCEPT_ALL);
+	ret = cs_ne_voq_map_init(ne);
+	if (ret)
+		return ret;
+
+	for (i = 0; i < CS_NE_PORTS; i++) {
+		ni_wr(ne, NI_CPUXRAM_INT_COLSC_CFG(i),
+		      NI_INT_COLSC_FIRST_EN | FIELD_PREP(NI_INT_COLSC_PKT, 4));
+		ni_wr(ne, NI_CPUXRAM_RXPKT_INTENABLE(i), 0);
+		ni_wr(ne, NI_CPUXRAM_RXPKT_INTERRUPT(i), 1);
+	}
+	return 0;
+}
+
+/* Called with rx_lock: all CPU free-list producers share one FIFO. */
+static bool cs_ne_qm_push_buffer(struct cs_ne *ne, struct cs_ne_rx_buf *buf)
+{
+	u32 value = qm_rd(ne, QM_CPU_PATH_STATUS_0);
+
+	/* Never write a full FIFO, or spin waiting for it with IRQs disabled. */
+	if (FIELD_GET(QM_SDRAM_ADDR_FIFO_WR_CNT, value) >= 28)
+		return false;
+	list_del_init(&buf->pending);
+	buf->state = CS_NE_RX_HW;
+	qm_wr(ne, QM_CPU_PATH_LINUX_SDRAM_ADDR(buf->pool), lower_32_bits(buf->dma));
+	return true;
+}
+
+static void cs_ne_rx_kick(struct cs_ne *ne)
+{
+	struct cs_ne_rx_buf *buf;
+	unsigned long flags;
+
+	spin_lock_irqsave(&ne->rx_lock, flags);
+	if (ne->rx_stopping)
+		goto unlock;
+	while (!list_empty(&ne->rx_pending)) {
+		buf = list_first_entry(&ne->rx_pending, struct cs_ne_rx_buf, pending);
+		if (!cs_ne_qm_push_buffer(ne, buf))
+			break;
+	}
+	/* Serialized with the stop flag so cancellation cannot miss a requeue. */
+	if (!list_empty(&ne->rx_pending))
+		mod_delayed_work(system_wq, &ne->rx_retry, msecs_to_jiffies(1));
+unlock:
+	spin_unlock_irqrestore(&ne->rx_lock, flags);
+}
+
+static void cs_ne_rx_retry(struct work_struct *work)
+{
+	struct cs_ne *ne = container_of(to_delayed_work(work), struct cs_ne, rx_retry);
+
+	cs_ne_rx_kick(ne);
+}
+
+static void cs_ne_rx_cancel_retry(void *data)
+{
+	struct cs_ne *ne = data;
+	unsigned long flags;
+
+	spin_lock_irqsave(&ne->rx_lock, flags);
+	ne->rx_stopping = true;
+	spin_unlock_irqrestore(&ne->rx_lock, flags);
+	cancel_delayed_work_sync(&ne->rx_retry);
+}
+
+/* Probe errors run before any RX address is published to hardware. */
+static void cs_ne_rx_cleanup(void *data)
+{
+	struct cs_ne *ne = data;
+	struct cs_ne_rx_buf *buf;
+	unsigned long index;
+
+	cs_ne_rx_cancel_retry(ne);
+	xa_for_each(&ne->rx_buffers, index, buf) {
+		/* A verified held reset revokes every hardware buffer reference. */
+		if (!ne->dma_quiesced && WARN_ON_ONCE(buf->state != CS_NE_RX_PENDING))
+			continue;
+		xa_erase(&ne->rx_buffers, index);
+		list_del_init(&buf->pending);
+		dma_unmap_page(ne->dev, buf->dma, CS_NE_RX_BUF_SIZE, DMA_FROM_DEVICE);
+		__free_page(buf->page);
+		kfree(buf);
+	}
+	if (xa_empty(&ne->rx_buffers))
+		xa_destroy(&ne->rx_buffers);
+}
+
+static int cs_ne_rx_refill(struct cs_ne_port *port, int count)
+{
+	struct cs_ne *ne = port->ne;
+	struct cs_ne_rx_buf *buf;
+	unsigned long flags;
+	int ret, i;
+
+	for (i = 0; i < count; i++) {
+		buf = kzalloc_obj(*buf);
+		if (!buf)
+			break;
+		buf->page = dev_alloc_page();
+		if (!buf->page)
+			goto free_buf;
+		buf->cpu = page_address(buf->page);
+		if (!buf->cpu)
+			goto free_page;
+		buf->dma = dma_map_page(ne->dev, buf->page, 0, CS_NE_RX_BUF_SIZE,
+					DMA_FROM_DEVICE);
+		if (dma_mapping_error(ne->dev, buf->dma))
+			goto free_page;
+		/* Hardware stores a 32-bit, 4 KiB aligned buffer address. */
+		if (upper_32_bits(buf->dma) || !IS_ALIGNED(buf->dma, CS_NE_RX_BUF_SIZE))
+			goto unmap;
+		buf->pool = port->id;
+		buf->state = CS_NE_RX_PENDING;
+		INIT_LIST_HEAD(&buf->pending);
+		ret = xa_insert(&ne->rx_buffers, buf->dma >> CS_NE_RX_DMA_SHIFT,
+				buf, GFP_KERNEL);
+		if (ret)
+			goto unmap;
+		spin_lock_irqsave(&ne->rx_lock, flags);
+		list_add_tail(&buf->pending, &ne->rx_pending);
+		spin_unlock_irqrestore(&ne->rx_lock, flags);
+		continue;
+unmap:
+		dma_unmap_page(ne->dev, buf->dma, CS_NE_RX_BUF_SIZE, DMA_FROM_DEVICE);
+free_page:
+		__free_page(buf->page);
+free_buf:
+		kfree(buf);
+		break;
+	}
+	cs_ne_rx_kick(ne);
+	return i;
+}
+
+/* Claim every buffer before copying or recycling any part of the packet. */
+static bool cs_ne_rx_claim(struct cs_ne *ne, const dma_addr_t *dma,
+			   struct cs_ne_rx_buf **bufs, unsigned int count)
+{
+	struct cs_ne_rx_buf *buf;
+	unsigned long flags;
+	unsigned int i;
+	bool valid = true;
+
+	if (!count || count > CS_NE_RX_MAX_BUFS)
+		return false;
+	spin_lock_irqsave(&ne->rx_lock, flags);
+	for (i = 0; i < count; i++) {
+		bufs[i] = NULL;
+		buf = xa_load(&ne->rx_buffers, dma[i] >> CS_NE_RX_DMA_SHIFT);
+		if (!buf || buf->dma != dma[i] || buf->state != CS_NE_RX_HW) {
+			valid = false;
+			continue;
+		}
+		buf->state = CS_NE_RX_CPU;
+		buf->sync_off = 0;
+		buf->sync_len = 0;
+		bufs[i] = buf;
+	}
+	spin_unlock_irqrestore(&ne->rx_lock, flags);
+	return valid;
+}
+
+static bool cs_ne_rx_range_valid(u32 off, u32 len)
+{
+	return off <= CS_NE_RX_BUF_SIZE && len <= CS_NE_RX_BUF_SIZE - off;
+}
+
+static void *cs_ne_rx_buf_cpu(struct cs_ne *ne, struct cs_ne_rx_buf *buf,
+			      u32 off, u32 len)
+{
+	u32 start, end;
+
+	if (!len || WARN_ON_ONCE(buf->state != CS_NE_RX_CPU ||
+				 !cs_ne_rx_range_valid(off, len)))
+		return NULL;
+	start = buf->sync_len ? min_t(u32, off, buf->sync_off) : off;
+	end = max_t(u32, off + len, buf->sync_off + buf->sync_len);
+	buf->sync_off = start;
+	buf->sync_len = end - start;
+	dma_sync_single_range_for_cpu(ne->dev, buf->dma, off, len, DMA_FROM_DEVICE);
+	return buf->cpu + off;
+}
+
+static void cs_ne_rx_recycle(struct cs_ne *ne, struct cs_ne_rx_buf *buf)
+{
+	unsigned long flags;
+
+	if (!buf)
+		return;
+	/* A claimed mapping cannot be handed to another CPU while it is copied. */
+	if (WARN_ON_ONCE(buf->state != CS_NE_RX_CPU))
+		return;
+	if (buf->sync_len)
+		dma_sync_single_range_for_device(ne->dev, buf->dma, buf->sync_off,
+						 buf->sync_len, DMA_FROM_DEVICE);
+	spin_lock_irqsave(&ne->rx_lock, flags);
+	buf->sync_len = 0;
+	buf->state = CS_NE_RX_PENDING;
+	list_add_tail(&buf->pending, &ne->rx_pending);
+	spin_unlock_irqrestore(&ne->rx_lock, flags);
+}
+
+static void cs_ne_tx_reap(struct cs_ne *ne);
+
+static int cs_ne_rx_poll(struct napi_struct *napi, int budget)
+{
+	struct cs_ne_port *port = container_of(napi, struct cs_ne_port, napi);
+	struct cs_ne *ne = port->ne;
+	struct net_device *ndev = port->ndev;
+	struct cs_ne_rx_buf *bufs[CS_NE_RX_MAX_BUFS];
+	dma_addr_t dma[CS_NE_RX_MAX_BUFS];
+	void __iomem *desc;
+	struct sk_buff *skb;
+	void *data;
+	u32 wr, rd, next, w1, hdre_hi, hdre_lo, pkt_size;
+	u32 off, total, seg, nbufs, remaining;
+	unsigned int i;
+	int done = 0;
+	bool valid;
+	unsigned long flags;
+
+	cs_ne_tx_reap(ne);
+	wr = ni_rd(ne, NI_CPUXRAM_CPU_STA_RX(port->id)) & NI_XRAM_PTR_MASK;
+	rd = port->rd;
+	while (rd != wr && done < budget) {
+		desc = ne->xram + rd * 8;
+		w1 = readl(desc + 4);
+		if (w1 & XR_OWNERSHIP) {
+			ndev->stats.rx_fifo_errors++;
+			break;
+		}
+		next = FIELD_GET(XR_NEXT_LINK, w1);
+		if (next == wr &&
+		    (ni_rd(ne, NI_CPUXRAM_CPU_STA_RX(port->id)) & NI_XRAM_PTR_MASK) == wr) {
+			/*
+			 * The next link reaches the unchanged hardware write pointer:
+			 * this is the current tail packet. Retain the vendor's 16us
+			 * DDR-arrival guard before reading its header and payload.
+			 * NAPI softirq context cannot use a sleeping delay here.
+			 */
+			udelay(CS_NE_RX_TAIL_SETTLE_US);
+		}
+		hdre_hi = readl(desc + 8);
+		hdre_lo = readl(desc + 12);
+		rd = next;
+		pkt_size = FIELD_GET(HDRE_PKT_SIZE, hdre_lo);
+		off = CS_NE_BUF_HDR_OFF + 8 + 16 + 2;
+		total = pkt_size > 20 ? pkt_size - 20 : 0;
+		valid = total >= ETH_HLEN && total <= CS_NE_MAX_PKT_LEN;
+		/* Drop policy must not hide trailing buffers in this descriptor. */
+		nbufs = 1;
+		if (total > CS_NE_BUF_DATA_MAX - (off & 0xff))
+			nbufs += DIV_ROUND_UP(total - (CS_NE_BUF_DATA_MAX - (off & 0xff)),
+					      CS_NE_BUF_DATA_MAX);
+		if (nbufs > CS_NE_RX_MAX_BUFS) {
+			valid = false;
+			nbufs = CS_NE_RX_MAX_BUFS;
+		}
+		for (i = 0; i < nbufs; i++)
+			dma[i] = readl(desc + 40 + i * 4) & XRAM_BUF_MASK;
+		valid = cs_ne_rx_claim(ne, dma, bufs, nbufs) && valid;
+		valid = valid && (hdre_hi & HDRE_CPU_HEADER_HI) && !(w1 & XR_ERROR);
+		if (!valid) {
+			ndev->stats.rx_errors++;
+			goto recycle;
+		}
+		skb = napi_alloc_skb(napi, total);
+		if (!skb) {
+			ndev->stats.rx_dropped++;
+			goto recycle;
+		}
+		remaining = total;
+		for (i = 0; i < nbufs; i++) {
+			seg = min_t(u32, remaining, CS_NE_BUF_DATA_MAX - (off & 0xff));
+			data = cs_ne_rx_buf_cpu(ne, bufs[i], off, seg);
+			if (!data)
+				break;
+			skb_put_data(skb, data, seg);
+			remaining -= seg;
+			off = CS_NE_BUF_HDR_OFF;
+		}
+		if (remaining) {
+			dev_kfree_skb(skb);
+			ndev->stats.rx_errors++;
+		} else {
+			ndev->stats.rx_packets++;
+			ndev->stats.rx_bytes += skb->len;
+			skb->protocol = eth_type_trans(skb, ndev);
+			napi_gro_receive(napi, skb);
+		}
+recycle:
+		for (i = 0; i < nbufs; i++)
+			cs_ne_rx_recycle(ne, bufs[i]);
+		done++;
+	}
+	cs_ne_rx_kick(ne);
+	ni_wr(ne, NI_CPUXRAM_CPU_CFG_RX(port->id), rd);
+	port->rd = rd;
+	if (done < budget && napi_complete_done(napi, done)) {
+		spin_lock_irqsave(&ne->rx_lock, flags);
+		if (READ_ONCE(port->opened) && !ne->rx_stopping)
+			ni_wr(ne, NI_CPUXRAM_RXPKT_INTENABLE(port->id), 1);
+		spin_unlock_irqrestore(&ne->rx_lock, flags);
+	}
+	return done;
+}
+
+static irqreturn_t cs_ne_rx_irq(int irq, void *data)
+{
+	struct cs_ne_port *port = data;
+	struct cs_ne *ne = port->ne;
+	u32 status;
+
+	status = ni_rd(ne, NI_CPUXRAM_RXPKT_INTERRUPT(port->id));
+	if (!status)
+		return IRQ_NONE;
+	ni_wr(ne, NI_CPUXRAM_RXPKT_INTENABLE(port->id), 0);
+	ni_wr(ne, NI_CPUXRAM_RXPKT_INTERRUPT(port->id), status);
+	napi_schedule(&port->napi);
+	return IRQ_HANDLED;
+}
+
+static void cs_ne_tx_stop_all(struct cs_ne *ne)
+{
+	int i;
+
+	for (i = 0; i < CS_NE_PORTS; i++)
+		if (ne->ports[i] && READ_ONCE(ne->ports[i]->opened))
+			netif_stop_queue(ne->ports[i]->ndev);
+}
+
+static void cs_ne_tx_complete(struct cs_ne *ne)
+{
+	struct cs_ne_txq *txq = &ne->txq;
+	struct cs_ne_tx_buf *buf;
+	u32 rptr;
+	int i;
+
+	if (txq->fault)
+		return;
+	rptr = readl(ne->dma + DMA_LSO_TXQ_RPTR(0)) & DMA_PTR_MASK;
+	/* Never consume unsubmitted descriptors or loop past the ring boundary. */
+	if (rptr >= CS_NE_TX_DESC_NUM ||
+	    ((rptr - txq->tail) & (CS_NE_TX_DESC_NUM - 1)) >
+	    ((txq->head - txq->tail) & (CS_NE_TX_DESC_NUM - 1))) {
+		txq->fault = true;
+		cs_ne_tx_stop_all(ne);
+		dev_err_ratelimited(ne->dev, "invalid TX completion pointer %#x\n", rptr);
+		return;
+	}
+	while (txq->tail != rptr) {
+		buf = &txq->bufs[txq->tail];
+		if (buf->len) {
+			if (buf->page)
+				dma_unmap_page(ne->dev, buf->dma, buf->len,
+					       DMA_TO_DEVICE);
+			else
+				dma_unmap_single(ne->dev, buf->dma, buf->len,
+						 DMA_TO_DEVICE);
+			buf->len = 0;
+		}
+		if (buf->skb) {
+			dev_consume_skb_any(buf->skb);
+			buf->skb = NULL;
+		}
+		txq->tail = (txq->tail + 1) & (CS_NE_TX_DESC_NUM - 1);
+	}
+	if (txq->stopping)
+		return;
+	if (((txq->tail - txq->head - 1) & (CS_NE_TX_DESC_NUM - 1)) <
+	    CS_NE_TX_MAX_FRAGS + 2)
+		return;
+	for (i = 0; i < CS_NE_PORTS; i++)
+		if (ne->ports[i] && READ_ONCE(ne->ports[i]->opened) &&
+		    netif_queue_stopped(ne->ports[i]->ndev))
+			netif_wake_queue(ne->ports[i]->ndev);
+}
+
+static u32 cs_ne_tx_free(const struct cs_ne_txq *txq)
+{
+	return (txq->tail - txq->head - 1) & (CS_NE_TX_DESC_NUM - 1);
+}
+
+/*
+ * There is no TX completion interrupt in use, so completed descriptors are
+ * reaped from the RX NAPI poll and from this timer. It has to be short:
+ * with HZ=100 a timer_list fires at most every 10 ms, and TCP small queues
+ * then limit a socket to what it can send per tick. Called with txq->lock.
+ */
+static void cs_ne_tx_arm_timer(struct cs_ne_txq *txq)
+{
+	if (!txq->poll_stopping && !txq->fault && txq->tail != txq->head &&
+	    (!hrtimer_is_queued(&txq->timer) || (!txq->stopping && txq->slow_poll))) {
+		/* No active socket needs fast completion while all ports are down.
+		 * Reopening shortens an already queued slow poll immediately.
+		 */
+		txq->slow_poll = txq->stopping;
+		hrtimer_start(&txq->timer,
+			      us_to_ktime(txq->slow_poll ? CS_NE_TX_STOP_TIMER_US :
+					  CS_NE_TX_TIMER_US), HRTIMER_MODE_REL_SOFT);
+	}
+}
+
+static enum hrtimer_restart cs_ne_tx_timer(struct hrtimer *t)
+{
+	struct cs_ne_txq *txq = container_of(t, struct cs_ne_txq, timer);
+
+	spin_lock(&txq->lock);
+	cs_ne_tx_complete(txq->ne);
+	cs_ne_tx_arm_timer(txq);
+	spin_unlock(&txq->lock);
+	return HRTIMER_NORESTART;
+}
+
+/* Set the stop flag under the same lock as every timer rearm. */
+static void cs_ne_tx_cancel_timer(void *data)
+{
+	struct cs_ne_txq *txq = data;
+
+	spin_lock_bh(&txq->lock);
+	txq->stopping = true;
+	txq->poll_stopping = true;
+	spin_unlock_bh(&txq->lock);
+	hrtimer_cancel(&txq->timer);
+}
+
+static void cs_ne_tx_reap(struct cs_ne *ne)
+{
+	struct cs_ne_txq *txq = &ne->txq;
+
+	if (READ_ONCE(txq->tail) == READ_ONCE(txq->head))
+		return;
+	spin_lock(&txq->lock);
+	cs_ne_tx_complete(ne);
+	spin_unlock(&txq->lock);
+}
+
+static void cs_ne_tx_desc(struct cs_ne_txq *txq, int port_id, dma_addr_t dma,
+			  u32 len, u32 total, bool sof, bool eof)
+{
+	u32 *desc = txq->desc + txq->head * 8;
+	u32 word0, word3;
+
+	word3 = TX_LSO_SEGMENT_EN | CS_NE_MAX_PKT_LEN;
+	if (eof && total < CS_NE_MIN_PKT_LEN)
+		word3 |= TX_LSO_IP_LENFIX_EN;
+	word0 = TX_DESC_OWN | FIELD_PREP(TX_DESC_LEN, len);
+	if (sof)
+		word0 |= TX_DESC_SOF;
+	if (eof)
+		word0 |= TX_DESC_EOF;
+
+	desc[1] = dma;
+	desc[2] = sof ? total << 16 : 0;
+	desc[3] = word3;
+	desc[4] = CS_NE_HDRA_CPU_PKT | FIELD_PREP(TX_HDRA_DVOQ, port_id * 8);
+	desc[5] = 0;
+	desc[6] = 0;
+	desc[7] = 0;
+	dma_wmb();
+	desc[0] = word0;
+}
+
+static netdev_tx_t cs_ne_xmit_sg(struct sk_buff *skb, struct net_device *ndev)
+{
+	struct cs_ne_port *port = netdev_priv(ndev);
+	struct cs_ne *ne = port->ne;
+	struct cs_ne_txq *txq = &ne->txq;
+	int nfrags = skb_shinfo(skb)->nr_frags;
+	u16 first = txq->head;
+	struct cs_ne_tx_buf *buf;
+	dma_addr_t dma;
+	u32 free, len;
+	int i;
+
+	free = (txq->tail - txq->head - 1) & (CS_NE_TX_DESC_NUM - 1);
+	if (free < nfrags + 2) {
+		cs_ne_tx_stop_all(ne);
+		return NETDEV_TX_BUSY;
+	}
+
+	for (i = 0; i <= nfrags; i++) {
+		const skb_frag_t *frag = i ? &skb_shinfo(skb)->frags[i - 1] : NULL;
+
+		buf = &txq->bufs[txq->head];
+		if (frag) {
+			len = skb_frag_size(frag);
+			dma = skb_frag_dma_map(ne->dev, frag, 0, len,
+					       DMA_TO_DEVICE);
+		} else {
+			len = skb_headlen(skb);
+			dma = dma_map_single(ne->dev, skb->data, len,
+					     DMA_TO_DEVICE);
+		}
+		if (dma_mapping_error(ne->dev, dma))
+			goto unmap;
+		buf->skb = NULL;
+		buf->dma = dma;
+		buf->len = len;
+		buf->page = !!frag;
+		cs_ne_tx_desc(txq, port->id, dma, len, skb->len, !frag,
+			      i == nfrags);
+		txq->head = (txq->head + 1) & (CS_NE_TX_DESC_NUM - 1);
+	}
+	buf->skb = skb;
+	dma_wmb();
+	writel(txq->head, ne->dma + DMA_LSO_TXQ_WPTR(0));
+
+	ndev->stats.tx_packets++;
+	ndev->stats.tx_bytes += skb->len;
+	free = (txq->tail - txq->head - 1) & (CS_NE_TX_DESC_NUM - 1);
+	if (free < CS_NE_TX_MAX_FRAGS + 2)
+		cs_ne_tx_stop_all(ne);
+	return NETDEV_TX_OK;
+
+unmap:
+	while (txq->head != first) {
+		txq->head = (txq->head - 1) & (CS_NE_TX_DESC_NUM - 1);
+		buf = &txq->bufs[txq->head];
+		txq->desc[txq->head * 8] = 0;
+		if (buf->page)
+			dma_unmap_page(ne->dev, buf->dma, buf->len,
+				       DMA_TO_DEVICE);
+		else
+			dma_unmap_single(ne->dev, buf->dma, buf->len,
+					 DMA_TO_DEVICE);
+		buf->len = 0;
+	}
+	dev_kfree_skb_any(skb);
+	ndev->stats.tx_dropped++;
+	return NETDEV_TX_OK;
+}
+
+static netdev_tx_t cs_ne_start_xmit(struct sk_buff *skb, struct net_device *ndev)
+{
+	struct cs_ne_port *port = netdev_priv(ndev);
+	struct cs_ne *ne = port->ne;
+	struct cs_ne_txq *txq = &ne->txq;
+	struct cs_ne_tx_buf *buf;
+	u32 *desc, word3, free;
+	dma_addr_t dma;
+	netdev_tx_t ret;
+	int len;
+
+	if (skb_is_nonlinear(skb) && !skb_has_frag_list(skb) &&
+	    skb_shinfo(skb)->nr_frags <= CS_NE_TX_MAX_FRAGS &&
+	    skb_headlen(skb) >= ETH_HLEN && skb->len >= CS_NE_TX_MIN_LEN) {
+		spin_lock(&txq->lock);
+		if (cs_ne_tx_free(txq) < CS_NE_TX_REAP_THRESH)
+			cs_ne_tx_complete(ne);
+		if (txq->stopping || txq->fault) {
+			spin_unlock(&txq->lock);
+			return NETDEV_TX_BUSY;
+		}
+		ret = cs_ne_xmit_sg(skb, ndev);
+		cs_ne_tx_arm_timer(txq);
+		spin_unlock(&txq->lock);
+		return ret;
+	}
+
+	if (skb_linearize(skb)) {
+		dev_kfree_skb_any(skb);
+		ndev->stats.tx_dropped++;
+		return NETDEV_TX_OK;
+	}
+	len = skb->len;
+	if (len < CS_NE_TX_MIN_LEN) {
+		if (skb_padto(skb, CS_NE_TX_MIN_LEN)) {
+			ndev->stats.tx_dropped++;
+			return NETDEV_TX_OK;
+		}
+		len = CS_NE_TX_MIN_LEN;
+	}
+
+	spin_lock(&txq->lock);
+	if (cs_ne_tx_free(txq) < CS_NE_TX_REAP_THRESH)
+		cs_ne_tx_complete(ne);
+	if (txq->stopping || txq->fault) {
+		spin_unlock(&txq->lock);
+		return NETDEV_TX_BUSY;
+	}
+	free = cs_ne_tx_free(txq);
+	if (free < 2) {
+		cs_ne_tx_stop_all(ne);
+		spin_unlock(&txq->lock);
+		return NETDEV_TX_BUSY;
+	}
+
+	dma = dma_map_single(ne->dev, skb->data, len, DMA_TO_DEVICE);
+	if (dma_mapping_error(ne->dev, dma)) {
+		spin_unlock(&txq->lock);
+		dev_kfree_skb_any(skb);
+		ndev->stats.tx_dropped++;
+		return NETDEV_TX_OK;
+	}
+
+	buf = &txq->bufs[txq->head];
+	buf->skb = skb;
+	buf->dma = dma;
+	buf->len = len;
+	buf->page = false;
+
+	word3 = TX_LSO_SEGMENT_EN | CS_NE_MAX_PKT_LEN;
+	if (len < CS_NE_MIN_PKT_LEN)
+		word3 |= TX_LSO_IP_LENFIX_EN;
+
+	desc = txq->desc + txq->head * 8;
+	desc[1] = dma;
+	desc[2] = len << 16;
+	desc[3] = word3;
+	desc[4] = CS_NE_HDRA_CPU_PKT | FIELD_PREP(TX_HDRA_DVOQ, port->id * 8);
+	desc[5] = 0;
+	desc[6] = 0;
+	desc[7] = 0;
+	dma_wmb();
+	desc[0] = TX_DESC_OWN | TX_DESC_SOF | TX_DESC_EOF |
+		  FIELD_PREP(TX_DESC_LEN, len);
+	dma_wmb();
+
+	txq->head = (txq->head + 1) & (CS_NE_TX_DESC_NUM - 1);
+	writel(txq->head, ne->dma + DMA_LSO_TXQ_WPTR(0));
+
+	ndev->stats.tx_packets++;
+	ndev->stats.tx_bytes += len;
+	free = (txq->tail - txq->head - 1) & (CS_NE_TX_DESC_NUM - 1);
+	if (free < CS_NE_TX_MAX_FRAGS + 2)
+		cs_ne_tx_stop_all(ne);
+	cs_ne_tx_arm_timer(txq);
+	spin_unlock(&txq->lock);
+	return NETDEV_TX_OK;
+}
+
+static void cs_ne_mac_enable(struct cs_ne_port *port, bool enable)
+{
+	u32 mask = NI_MAC_RX_RST | NI_MAC_TX_RST | NI_MAC_RX_EN | NI_MAC_TX_EN;
+
+	ni_rmw(port->ne, NI_ETH_MAC_CONFIG0(port->id), mask,
+	       enable ? (NI_MAC_RX_EN | NI_MAC_TX_EN) : 0);
+}
+
+static void cs_ne_port_hw_init(struct cs_ne_port *port)
+{
+	struct cs_ne *ne = port->ne;
+	int p = port->id;
+
+	ni_rmw(ne, NI_ETH_INT_CONFIG1,
+	       NI_INT_CFG_GE_MASK(p) | NI_PHY_MODE_GE(p) | NI_RMII_CLKSRC_GE(p) |
+	       NI_TX_USE_GEFIFO_GE(p) | NI_INV_CLK_OUT_GE(p),
+	       NI_INT_CFG_GE(p, NI_INT_CFG_RGMII_1000) | NI_TX_USE_GEFIFO_GE(p));
+	ni_rmw(ne, NI_ETH_INT_CONFIG2, NI_INT_CONFIG2_GE_MASK(p), 0);
+	ni_rmw(ne, NI_ETH_MAC_CONFIG0(p),
+	       NI_MAC_RX_FLOW_DISABLE | NI_MAC_TX_FLOW_DISABLE,
+	       NI_MAC_RX_FLOW_DISABLE | NI_MAC_TX_FLOW_DISABLE);
+}
+
+static void cs_ne_set_hw_addr(struct cs_ne_port *port)
+{
+	struct cs_ne *ne = port->ne;
+	const u8 *a = port->ndev->dev_addr;
+
+	ni_wr(ne, NI_MAC_ADDR0, a[0] | (a[1] << 8) | (a[2] << 16) | (a[3] << 24));
+	ni_rmw(ne, NI_MAC_ADDR1, 0xff, a[4]);
+	ni_rmw(ne, NI_ETH_MAC_CONFIG2(port->id), 0xff, a[5]);
+}
+
+static void cs_ne_mac_config(struct phylink_config *config, unsigned int mode,
+			     const struct phylink_link_state *state)
+{
+}
+
+static void cs_ne_mac_link_down(struct phylink_config *config,
+				unsigned int mode, phy_interface_t interface)
+{
+	struct cs_ne_port *port = container_of(config, struct cs_ne_port,
+					       phylink_config);
+
+	cs_ne_mac_enable(port, false);
+}
+
+static void cs_ne_mac_link_up(struct phylink_config *config,
+			      struct phy_device *phy, unsigned int mode,
+			      phy_interface_t interface, int speed, int duplex,
+			      bool tx_pause, bool rx_pause)
+{
+	struct cs_ne_port *port = container_of(config, struct cs_ne_port,
+					       phylink_config);
+	struct cs_ne *ne = port->ne;
+	int p = port->id;
+	u32 val = 0;
+
+	cs_ne_mac_enable(port, false);
+	if (speed == SPEED_10)
+		val |= NI_MAC_SPEED_10;
+	if (duplex != DUPLEX_FULL)
+		val |= NI_MAC_HALF_DUPLEX;
+	if (!rx_pause)
+		val |= NI_MAC_RX_FLOW_DISABLE;
+	if (!tx_pause)
+		val |= NI_MAC_TX_FLOW_DISABLE;
+	ni_rmw(ne, NI_ETH_MAC_CONFIG0(p),
+	       NI_MAC_SPEED_10 | NI_MAC_HALF_DUPLEX | NI_MAC_RX_FLOW_DISABLE |
+	       NI_MAC_TX_FLOW_DISABLE, val);
+	ni_rmw(ne, NI_ETH_INT_CONFIG1, NI_INT_CFG_GE_MASK(p),
+	       NI_INT_CFG_GE(p, speed == SPEED_1000 ? NI_INT_CFG_RGMII_1000 :
+			     NI_INT_CFG_RGMII_100));
+	ni_rmw(ne, NI_ETH_INT_CONFIG2, NI_INT_CONFIG2_GE_MASK(p),
+	       NI_TX_INTF_LP_TIME_GE(p));
+	cs_ne_mac_enable(port, true);
+}
+
+static const struct phylink_mac_ops cs_ne_phylink_ops = {
+	.mac_config = cs_ne_mac_config,
+	.mac_link_down = cs_ne_mac_link_down,
+	.mac_link_up = cs_ne_mac_link_up,
+};
+
+static int cs_ne_open(struct net_device *ndev)
+{
+	struct cs_ne_port *port = netdev_priv(ndev);
+	struct cs_ne *ne = port->ne;
+	unsigned long flags;
+	int ret;
+
+	/* RTNL also protects the final probe activation. */
+	if (ne->rx_stopping)
+		return -ENODEV;
+	if (READ_ONCE(ne->txq.fault))
+		return -EIO;
+
+	ret = phylink_of_phy_connect(port->phylink, port->np, 0);
+	if (ret) {
+		netdev_err(ndev, "phylink connect failed: %d\n", ret);
+		return ret;
+	}
+
+	port->rd = ni_rd(ne, NI_CPUXRAM_CPU_CFG_RX(port->id)) & NI_XRAM_PTR_MASK;
+	napi_enable(&port->napi);
+	ret = request_irq(port->irq, cs_ne_rx_irq, 0, ndev->name, port);
+	if (ret)
+		goto err_disable_napi;
+
+	spin_lock_bh(&ne->txq.lock);
+	if (ne->txq.fault) {
+		spin_unlock_bh(&ne->txq.lock);
+		ret = -EIO;
+		goto err_free_irq;
+	}
+	WRITE_ONCE(port->opened, true);
+	ne->txq.stopping = false;
+	cs_ne_tx_arm_timer(&ne->txq);
+	/* A concurrent TX fault must be able to stop this queue permanently. */
+	netif_start_queue(ndev);
+	spin_unlock_bh(&ne->txq.lock);
+	spin_lock_irqsave(&ne->rx_lock, flags);
+	ni_wr(ne, NI_CPUXRAM_RXPKT_INTERRUPT(port->id), 1);
+	ni_wr(ne, NI_CPUXRAM_RXPKT_INTENABLE(port->id), 0);
+	spin_unlock_irqrestore(&ne->rx_lock, flags);
+	/* A packet queued while down need not produce a new interrupt edge.
+	 * Poll once with interrupts masked; NAPI completion rearms them.
+	 */
+	napi_schedule(&port->napi);
+	phylink_start(port->phylink);
+	return 0;
+
+err_free_irq:
+	free_irq(port->irq, port);
+err_disable_napi:
+	napi_disable(&port->napi);
+	phylink_disconnect_phy(port->phylink);
+	return ret;
+}
+
+static int cs_ne_stop(struct net_device *ndev)
+{
+	struct cs_ne_port *port = netdev_priv(ndev);
+	struct cs_ne *ne = port->ne;
+	unsigned long flags;
+	bool last = true;
+	int i;
+
+	/* Serialize queue wakeups before waiting for ndo_start_xmit to finish. */
+	spin_lock_bh(&ne->txq.lock);
+	WRITE_ONCE(port->opened, false);
+	for (i = 0; i < CS_NE_PORTS; i++)
+		if (ne->ports[i] && READ_ONCE(ne->ports[i]->opened))
+			last = false;
+	if (last)
+		ne->txq.stopping = true;
+	spin_unlock_bh(&ne->txq.lock);
+	netif_tx_disable(ndev);
+	phylink_stop(port->phylink);
+	spin_lock_irqsave(&ne->rx_lock, flags);
+	ni_wr(ne, NI_CPUXRAM_RXPKT_INTENABLE(port->id), 0);
+	spin_unlock_irqrestore(&ne->rx_lock, flags);
+	free_irq(port->irq, port);
+	napi_disable(&port->napi);
+	phylink_disconnect_phy(port->phylink);
+	if (last) {
+		/* DMA may complete after NAPI is disabled. Reap only confirmed
+		 * completions and retain polling until the shared ring is empty.
+		 * Hardware-owned mappings remain live until completion or reset.
+		 */
+		spin_lock_bh(&ne->txq.lock);
+		cs_ne_tx_complete(ne);
+		cs_ne_tx_arm_timer(&ne->txq);
+		spin_unlock_bh(&ne->txq.lock);
+	}
+	return 0;
+}
+
+static int cs_ne_set_mac_address(struct net_device *ndev, void *addr)
+{
+	int ret;
+
+	ret = eth_mac_addr(ndev, addr);
+	if (ret)
+		return ret;
+	cs_ne_set_hw_addr(netdev_priv(ndev));
+	return 0;
+}
+
+static int cs_ne_eth_ioctl(struct net_device *ndev, struct ifreq *ifr, int cmd)
+{
+	struct cs_ne_port *port = netdev_priv(ndev);
+
+	return phylink_mii_ioctl(port->phylink, ifr, cmd);
+}
+
+static int cs_ne_get_link_ksettings(struct net_device *ndev,
+				    struct ethtool_link_ksettings *cmd)
+{
+	struct cs_ne_port *port = netdev_priv(ndev);
+
+	return phylink_ethtool_ksettings_get(port->phylink, cmd);
+}
+
+static int cs_ne_set_link_ksettings(struct net_device *ndev,
+				    const struct ethtool_link_ksettings *cmd)
+{
+	struct cs_ne_port *port = netdev_priv(ndev);
+
+	return phylink_ethtool_ksettings_set(port->phylink, cmd);
+}
+
+static const struct ethtool_ops cs_ne_ethtool_ops = {
+	.get_link = ethtool_op_get_link,
+	.get_link_ksettings = cs_ne_get_link_ksettings,
+	.set_link_ksettings = cs_ne_set_link_ksettings,
+};
+
+static const struct net_device_ops cs_ne_netdev_ops = {
+	.ndo_open = cs_ne_open,
+	.ndo_stop = cs_ne_stop,
+	.ndo_start_xmit = cs_ne_start_xmit,
+	.ndo_set_mac_address = cs_ne_set_mac_address,
+	.ndo_validate_addr = eth_validate_addr,
+	.ndo_eth_ioctl = cs_ne_eth_ioctl,
+};
+
+static void cs_ne_port_cleanup(void *data)
+{
+	struct cs_ne_port *port = data;
+
+	if (port->registered)
+		unregister_netdev(port->ndev);
+	phylink_destroy(port->phylink);
+	netif_napi_del(&port->napi);
+	/* The shared completion poll can outlive a closed port. */
+	spin_lock_bh(&port->ne->txq.lock);
+	port->ne->ports[port->id] = NULL;
+	spin_unlock_bh(&port->ne->txq.lock);
+}
+
+static int cs_ne_probe_port(struct cs_ne *ne, struct device_node *np)
+{
+	struct device *dev = ne->dev;
+	struct cs_ne_port *port;
+	struct net_device *ndev;
+	char irqname[8];
+	u32 id;
+	int ret;
+
+	ret = of_property_read_u32(np, "reg", &id);
+	if (ret || id >= CS_NE_PORTS || ne->ports[id]) {
+		dev_err(dev, "%pOF: bad port reg\n", np);
+		return -EINVAL;
+	}
+
+	ndev = devm_alloc_etherdev(dev, sizeof(*port));
+	if (!ndev)
+		return -ENOMEM;
+	SET_NETDEV_DEV(ndev, dev);
+	port = netdev_priv(ndev);
+	port->ne = ne;
+	port->ndev = ndev;
+	port->np = np;
+	port->id = id;
+
+	snprintf(irqname, sizeof(irqname), "eth%u", id);
+	port->irq = platform_get_irq_byname(to_platform_device(dev), irqname);
+	if (port->irq < 0)
+		return port->irq;
+
+	ret = of_get_phy_mode(np, &port->interface);
+	if (ret)
+		return ret;
+
+	ret = of_get_ethdev_address(np, ndev);
+	if (ret == -EPROBE_DEFER)
+		return ret;
+	if (ret)
+		eth_hw_addr_random(ndev);
+
+	ndev->dev.of_node = np;
+	ndev->netdev_ops = &cs_ne_netdev_ops;
+	ndev->ethtool_ops = &cs_ne_ethtool_ops;
+	ndev->hw_features = NETIF_F_SG;
+	ndev->features = NETIF_F_SG;
+	ndev->vlan_features = NETIF_F_SG;
+	ndev->min_mtu = ETH_MIN_MTU;
+	ndev->max_mtu = CS_NE_MAX_PKT_LEN - ETH_HLEN - ETH_FCS_LEN - 16;
+	netif_napi_add(ndev, &port->napi, cs_ne_rx_poll);
+
+	port->phylink_config.dev = &ndev->dev;
+	port->phylink_config.type = PHYLINK_NETDEV;
+	port->phylink_config.mac_capabilities = MAC_SYM_PAUSE | MAC_ASYM_PAUSE |
+		MAC_10 | MAC_100 | MAC_1000FD;
+	phy_interface_set_rgmii(port->phylink_config.supported_interfaces);
+	port->phylink = phylink_create(&port->phylink_config,
+				       of_fwnode_handle(np), port->interface,
+				       &cs_ne_phylink_ops);
+	if (IS_ERR(port->phylink)) {
+		ret = PTR_ERR(port->phylink);
+		netif_napi_del(&port->napi);
+		return ret;
+	}
+	ret = devm_add_action_or_reset(dev, cs_ne_port_cleanup, port);
+	if (ret)
+		return ret;
+
+	cs_ne_port_hw_init(port);
+	cs_ne_set_hw_addr(port);
+	spin_lock_bh(&ne->txq.lock);
+	ne->ports[id] = port;
+	spin_unlock_bh(&ne->txq.lock);
+
+	if (cs_ne_rx_refill(port, cs_ne_rx_pool_size[id]) != cs_ne_rx_pool_size[id])
+		return -ENOMEM;
+
+	return 0;
+}
+
+/*
+ * Try every protective assert and check every line, retaining the first error.
+ * Bulk assert must not be used here: its rollback deasserts earlier lines.
+ */
+static int cs_ne_assert_resets(struct cs_ne *ne)
+{
+	int first = 0, ret, i;
+
+	for (i = 0; i < CS_NE_NUM_RESETS; i++) {
+		ret = reset_control_assert(ne->resets[i].rstc);
+		if (ret && !first)
+			first = ret;
+	}
+	for (i = 0; i < CS_NE_NUM_RESETS; i++) {
+		ret = reset_control_status(ne->resets[i].rstc);
+		if (ret != 1 && !first)
+			first = ret < 0 ? ret : -EIO;
+	}
+	return first;
+}
+
+static int cs_ne_deassert_resets(struct cs_ne *ne)
+{
+	int ret, i;
+
+	/* Reverse the consumer's assert order, as the bulk API would. */
+	for (i = CS_NE_NUM_RESETS - 1; i >= 0; i--) {
+		ret = reset_control_deassert(ne->resets[i].rstc);
+		if (ret)
+			return ret;
+	}
+	for (i = 0; i < CS_NE_NUM_RESETS; i++) {
+		ret = reset_control_status(ne->resets[i].rstc);
+		if (ret)
+			return ret < 0 ? ret : -EIO;
+	}
+	return 0;
+}
+
+/* Last devres action: on a failed reset retain mappings and their device. */
+static void cs_ne_context_release(void *data)
+{
+	struct cs_ne *ne = data;
+
+	if (ne->dma_pinned) {
+		get_device(ne->dev);
+		dev_err(ne->dev, "DMA reset failed; allocations retained until reboot\n");
+		return;
+	}
+	kfree(ne);
+}
+
+/* All ports/IRQs/NAPI have been removed before this action runs. */
+static void cs_ne_hw_cleanup(void *data)
+{
+	struct cs_ne *ne = data;
+	struct cs_ne_txq *txq = &ne->txq;
+	struct cs_ne_tx_buf *buf;
+	int ret, i;
+
+	if (ne->hw_cleanup_done)
+		return;
+	ne->hw_cleanup_done = true;
+	cs_ne_rx_cancel_retry(ne);
+	cs_ne_tx_cancel_timer(txq);
+	if (ne->hw_accessible) {
+		ni_rmw(ne, NI_CPUXRAM_CFG, NI_CPUXRAM_PKT_DIS_MASK,
+		       NI_CPUXRAM_PKT_DIS_MASK);
+		writel(0, ne->dma + DMA_LSO_TXQ_CONTROL(0));
+		writel(0, ne->dma + DMA_LSO_TXDMA_CONTROL);
+		readl(ne->dma + DMA_LSO_TXDMA_CONTROL);
+	}
+
+	/* The entire owned NE + LSO/SSP domain stays reset through release. */
+	ret = cs_ne_assert_resets(ne);
+	if (ret && ne->hw_active) {
+		ne->dma_pinned = true;
+		return;
+	}
+	ne->dma_quiesced = !ret;
+	ne->hw_active = false;
+	cs_ne_rx_cleanup(ne);
+	for (i = 0; i < CS_NE_TX_DESC_NUM; i++) {
+		buf = &txq->bufs[i];
+		if (buf->len) {
+			if (buf->page)
+				dma_unmap_page(ne->dev, buf->dma, buf->len, DMA_TO_DEVICE);
+			else
+				dma_unmap_single(ne->dev, buf->dma, buf->len, DMA_TO_DEVICE);
+			buf->len = 0;
+		}
+		if (buf->skb) {
+			dev_kfree_skb_any(buf->skb);
+			buf->skb = NULL;
+		}
+	}
+	if (txq->desc) {
+		dma_free_coherent(ne->dev, CS_NE_TX_DESC_NUM * 32,
+				  txq->desc, txq->desc_dma);
+		txq->desc = NULL;
+	}
+}
+
+static void cs_ne_remove(struct platform_device *pdev)
+{
+	struct cs_ne *ne = platform_get_drvdata(pdev);
+	int i;
+
+	if (!ne || ne->hw_cleanup_done)
+		return;
+	for (i = 0; i < CS_NE_PORTS; i++)
+		if (ne->ports[i])
+			devm_release_action(ne->dev, cs_ne_port_cleanup, ne->ports[i]);
+	devm_release_action(ne->dev, cs_ne_hw_cleanup, ne);
+	platform_set_drvdata(pdev, NULL);
+}
+
+static void cs_ne_shutdown(struct platform_device *pdev)
+{
+	cs_ne_remove(pdev);
+}
+
+static void __iomem *cs_ne_iomap(struct platform_device *pdev, const char *name,
+				 size_t minimum_size)
+{
+	struct resource *res;
+
+	res = platform_get_resource_byname(pdev, IORESOURCE_MEM, name);
+	if (!res || resource_size(res) < minimum_size)
+		return ERR_PTR(-EINVAL);
+	return devm_ioremap_resource(&pdev->dev, res);
+}
+
+static int cs_ne_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct device_node *np;
+	struct cs_ne *ne;
+	int ret, i, nports = 0;
+
+	ne = kzalloc_obj(*ne);
+	if (!ne)
+		return -ENOMEM;
+	ne->dev = dev;
+	spin_lock_init(&ne->ni_lock);
+	ret = devm_add_action_or_reset(dev, cs_ne_context_release, ne);
+	if (ret)
+		return ret;
+	xa_init(&ne->rx_buffers);
+	INIT_LIST_HEAD(&ne->rx_pending);
+	spin_lock_init(&ne->rx_lock);
+	INIT_DELAYED_WORK(&ne->rx_retry, cs_ne_rx_retry);
+	/* Keep all allocated buffers CPU-owned until probe commits. */
+	ne->rx_stopping = true;
+	ne->txq.ne = ne;
+	ne->txq.stopping = true;
+	spin_lock_init(&ne->txq.lock);
+	hrtimer_setup(&ne->txq.timer, cs_ne_tx_timer, CLOCK_MONOTONIC,
+		      HRTIMER_MODE_REL_SOFT);
+	platform_set_drvdata(pdev, ne);
+
+	ne->global = syscon_regmap_lookup_by_phandle(dev->of_node, "cortina,global-syscon");
+	if (IS_ERR(ne->global))
+		return dev_err_probe(dev, PTR_ERR(ne->global), "global syscon\n");
+	ret = cs_ne_check_reserved_memory(ne);
+	if (ret)
+		return ret;
+	ne->ni = cs_ne_iomap(pdev, "ni", 0x500);
+	ne->dma = cs_ne_iomap(pdev, "dma", 0x800);
+	ne->fe = cs_ne_iomap(pdev, "fe", 0x4000);
+	ne->qm = cs_ne_iomap(pdev, "qm", 0x400);
+	ne->tm = cs_ne_iomap(pdev, "tm", 0x800);
+	ne->sch = cs_ne_iomap(pdev, "sch", 0x100);
+	ne->xram = cs_ne_iomap(pdev, "xram", 0x100000);
+	if (IS_ERR(ne->ni))
+		return dev_err_probe(dev, PTR_ERR(ne->ni), "NI resource\n");
+	if (IS_ERR(ne->dma))
+		return dev_err_probe(dev, PTR_ERR(ne->dma), "complete LSO/SSP DMA resource\n");
+	if (IS_ERR(ne->fe))
+		return dev_err_probe(dev, PTR_ERR(ne->fe), "FE resource\n");
+	if (IS_ERR(ne->qm))
+		return dev_err_probe(dev, PTR_ERR(ne->qm), "QM resource\n");
+	if (IS_ERR(ne->tm))
+		return dev_err_probe(dev, PTR_ERR(ne->tm), "TM resource\n");
+	if (IS_ERR(ne->sch))
+		return dev_err_probe(dev, PTR_ERR(ne->sch), "SCH resource\n");
+	if (IS_ERR(ne->xram))
+		return dev_err_probe(dev, PTR_ERR(ne->xram), "XRAM resource\n");
+
+	for (i = 0; i < CS_NE_NUM_RESETS; i++)
+		ne->resets[i].id = cs_ne_reset_names[i];
+	ret = devm_reset_control_bulk_get_exclusive(dev, CS_NE_NUM_RESETS, ne->resets);
+	if (ret)
+		return dev_err_probe(dev, ret, "exclusive engine resets\n");
+	ret = dma_set_mask_and_coherent(dev, DMA_BIT_MASK(32));
+	if (ret)
+		return ret;
+
+	for_each_available_child_of_node(dev->of_node, np) {
+		u8 addr[ETH_ALEN];
+
+		if (!of_node_name_eq(np, "ethernet-port"))
+			continue;
+		ret = of_get_mac_address(np, addr);
+		if (ret == -EPROBE_DEFER) {
+			of_node_put(np);
+			return ret;
+		}
+	}
+
+	/* No hardware state needs unwinding until the first reset attempt. */
+	ret = devm_add_action(dev, cs_ne_hw_cleanup, ne);
+	if (ret)
+		return ret;
+
+	ret = cs_ne_assert_resets(ne);
+	if (ret)
+		return dev_err_probe(dev, ret, "assert engine reset\n");
+	/* Reset pulse width, not an inferred DMA idle condition. */
+	usleep_range(100, 200);
+	ret = cs_ne_deassert_resets(ne);
+	if (ret)
+		return dev_err_probe(dev, ret, "release engine reset\n");
+	ne->hw_accessible = true;
+	ret = cs_ne_ni_init(ne);
+	if (ret)
+		return ret;
+	ret = cs_ne_dma_init(ne);
+	if (ret)
+		return ret;
+
+	ret = cs_ne_qm_init(ne);
+	if (ret)
+		return ret;
+	ret = cs752x_sch_init(dev, ne->sch);
+	if (ret)
+		return dev_err_probe(dev, ret, "SCH init failed\n");
+	ret = cs752x_tm_init(dev, ne->tm);
+	if (ret)
+		return dev_err_probe(dev, ret, "TM init failed\n");
+	ret = cs752x_fe_init(dev, ne->fe);
+	if (ret)
+		return dev_err_probe(dev, ret, "FE init failed\n");
+	writel(readl(ne->fe + FETOP_FE_PRSR_CFG_0) & ~FE_L4_CHKSUM_CHK_DISABLE,
+	       ne->fe + FETOP_FE_PRSR_CFG_0);
+
+	/* phylink_create() and destroy() may acquire RTNL themselves. */
+	for_each_available_child_of_node(dev->of_node, np) {
+		if (!of_node_name_eq(np, "ethernet-port"))
+			continue;
+		ret = cs_ne_probe_port(ne, np);
+		if (ret) {
+			dev_err(dev, "%pOF: probe failed: %d\n", np, ret);
+			of_node_put(np);
+			return ret;
+		}
+		nports++;
+	}
+	if (!nports)
+		return -ENODEV;
+
+	/* No netdev may open while the shared pools are only partly prepared. */
+	rtnl_lock();
+	for (i = 0; i < CS_NE_PORTS; i++) {
+		if (!ne->ports[i])
+			continue;
+		ret = register_netdevice(ne->ports[i]->ndev);
+		if (ret)
+			goto unlock;
+		ne->ports[i]->registered = true;
+	}
+
+	/* Cleanup must revoke hardware references before releasing any mappings. */
+	ne->hw_active = true;
+	/* There are no fallible probe operations after publishing DMA addresses. */
+	spin_lock_irq(&ne->rx_lock);
+	ne->rx_stopping = false;
+	spin_unlock_irq(&ne->rx_lock);
+	cs_ne_rx_kick(ne);
+	writel(DMA_ENABLE | FIELD_PREP(DMA_BURST_LEN, 3),
+	       ne->dma + DMA_LSO_TXDMA_CONTROL);
+	writel(1, ne->dma + DMA_LSO_TXQ_CONTROL(0));
+	ret = 0;
+unlock:
+	rtnl_unlock();
+	return ret;
+}
+
+static const struct of_device_id cs_ne_of_match[] = {
+	{ .compatible = "cortina,cs7542-ethernet" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, cs_ne_of_match);
+
+static struct platform_driver cs_ne_driver = {
+	.probe = cs_ne_probe,
+	.remove = cs_ne_remove,
+	.shutdown = cs_ne_shutdown,
+	.driver = {
+		.name = "cs7542-ethernet",
+		.of_match_table = cs_ne_of_match,
+	},
+};
+module_platform_driver(cs_ne_driver);
+
+MODULE_DESCRIPTION("Cortina CS7542 network engine driver");
+MODULE_LICENSE("GPL");
diff --git a/drivers/net/ethernet/cortina/cs752x_ne.h b/drivers/net/ethernet/cortina/cs752x_ne.h
new file mode 100644
index 000000000..1f7c08166
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs752x_ne.h
@@ -0,0 +1,13 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#ifndef __CS752X_NE_H__
+#define __CS752X_NE_H__
+
+#include <linux/types.h>
+
+struct device;
+
+int cs752x_fe_init(struct device *dev, void __iomem *fe);
+int cs752x_sch_init(struct device *dev, void __iomem *sch);
+int cs752x_tm_init(struct device *dev, void __iomem *tm);
+
+#endif
diff --git a/drivers/net/ethernet/cortina/cs752x_sch_tm.c b/drivers/net/ethernet/cortina/cs752x_sch_tm.c
new file mode 100644
index 000000000..da1563496
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs752x_sch_tm.c
@@ -0,0 +1,687 @@
+// SPDX-License-Identifier: GPL-2.0
+#include <linux/io.h>
+#include <linux/iopoll.h>
+#include <linux/device.h>
+#include <linux/delay.h>
+#include <linux/bitfield.h>
+#include <linux/bits.h>
+
+#include "cs752x_ne.h"
+
+#define SCH_CONTROL				0x000
+#define SCH_CONTROL_SOFT_RESET			BIT(0)
+
+#define SCH_STATUS				0x004
+#define SCH_STATUS_SCH_MEM_INIT_DONE		BIT(0)
+#define SCH_STATUS_CURRENT_SET_TDM_CONTROL	BIT(1)
+#define SCH_STATUS_CPU_CMD_STATUS		GENMASK(4, 2)
+
+#define SCH_SWITCH_TDM_CONTROL_SET		0x008
+#define SCH_SWITCH_TDM_CONTROL_SET_SWITCH	BIT(0)
+
+#define SCH_MAIN_TDM_CONTROL_SETA		0x00c
+#define SCH_MAIN_TDM_CONTROL_SETB		0x010
+#define SCH_MAIN_TDM_CONTROL_CALENDAR_RETURN	GENMASK(4, 0)
+
+#define SCH_MAIN_TDM_PORT_CALENDAR0_SETA	0x014
+#define SCH_MAIN_TDM_PORT_CALENDAR1_SETA	0x018
+#define SCH_MAIN_TDM_PORT_CALENDAR0_SETB	0x01c
+#define SCH_MAIN_TDM_PORT_CALENDAR1_SETB	0x020
+
+#define SCH_SHAPER_CONFIGURATION		0x024
+#define SCH_SHAPER_CONFIGURATION_CLOCKS_PER_ROUND_ST	GENMASK(9, 0)
+#define SCH_SHAPER_CONFIGURATION_GLOBAL_SCRUB_ENABLE	BIT(27)
+
+#define SCH_ATOMIC_COMMAND_CONTROL		0x028
+#define SCH_ATOMIC_COMMAND_CONTROL_START_WRITE	BIT(0)
+
+#define SCH_ATOMIC_COMMAND_DATA1		0x02c
+#define SCH_ATOMIC_COMMAND_DATA1_CPU_PORT	GENMASK(2, 0)
+#define SCH_ATOMIC_COMMAND_DATA1_PORT		GENMASK(3, 0)
+#define SCH_ATOMIC_COMMAND_DATA1_TMAX		GENMASK(21, 4)
+#define SCH_ATOMIC_COMMAND_DATA1_RPT		GENMASK(26, 22)
+
+#define SCH_ATOMIC_COMMAND_DATA0		0x030
+#define SCH_ATOMIC_COMMAND_DATA0_CMD		GENMASK(3, 0)
+#define SCH_ATOMIC_COMMAND_DATA0_MASK		BIT(4)
+#define SCH_ATOMIC_COMMAND_DATA0_VOQ		GENMASK(10, 4)
+#define SCH_ATOMIC_COMMAND_DATA0_SHAPER		GENMASK(11, 4)
+#define SCH_ATOMIC_COMMAND_DATA0_BURST		GENMASK(11, 4)
+#define SCH_ATOMIC_COMMAND_DATA0_QUANTA		GENMASK(29, 12)
+#define SCH_ATOMIC_COMMAND_DATA0_TSIZE		GENMASK(29, 12)
+
+#define SCH_INTERRUPT_0				0x034
+#define SCH_INTERRUPT_0_CPU_CMD_EXECUTED	BIT(0)
+
+#define SCH_DEBUG_CONTROL			0x084
+#define SCH_DEBUG_CONTROL_SWITCH_EXPR_MODE_LOWLVL	GENMASK(24, 20)
+
+#define SCH_CMD_VOQ_AS_DRR			1
+#define SCH_CMD_CHANGE_SHAPER_PARA		5
+#define SCH_CMD_SET_BURST_SIZE			7
+#define SCH_CMD_CHANGE_PORT_LEVEL_MASK		9
+
+#define SCH_ENABLE_PORT				0
+
+#define SCH_PORT_SCH_ID				0
+#define SCH_ROOT_SCH_ID				1
+#define SCH_CPU_SCH_ID				2
+
+#define SCH_MAX_ETH_PORT			5
+#define SCH_MAX_ROOT_PORT			1
+#define SCH_MAX_CPU_PORT			8
+#define SCH_MAX_PORT_QUEUE			8
+#define SCH_PORT_NO				(SCH_MAX_ETH_PORT + \
+						 SCH_MAX_ROOT_PORT + \
+						 SCH_MAX_CPU_PORT)
+#define SCH_VOQ_NO				(SCH_PORT_NO * \
+						 SCH_MAX_PORT_QUEUE)
+#define SCH_DRR_BASE_ID				SCH_VOQ_NO
+#define SCH_LT_BASE_ID				(SCH_VOQ_NO + SCH_PORT_NO)
+#define SCH_ST_BASE_ID				(SCH_LT_BASE_ID + SCH_PORT_NO)
+#define SCH_CPU_PORT0				(SCH_MAX_ETH_PORT + \
+						 SCH_MAX_ROOT_PORT)
+#define SCH_MAX_CALENDAR_LENGTH			32
+#define SCH_DEFAULT_QUANTA			9132
+#define SCH_CLOCKS_PER_ROUND_ST			0x100
+#define SCH_EXPR_MODE_LOWLVL			3
+
+#define SCH_CMD_TIMEOUT_US			10000
+#define SCH_INIT_TIMEOUT_US			10000
+#define SCH_RESET_DELAY_US			100
+
+#define TM_BM_CONFIG_0				0x000
+#define TM_BM_CONFIG_0_INIT			BIT(0)
+#define TM_BM_CONFIG_0_ENQUE_HDR_ADJUST		BIT(1)
+#define TM_BM_CONFIG_0_BM1_BYPASS_VOQ_PROCESS	BIT(4)
+#define TM_BM_CONFIG_0_BM1_BYPASS_DEST_PORT_PROCESS	BIT(5)
+#define TM_BM_CONFIG_0_BM1_BYPASS_CA_PROCESS	BIT(6)
+#define TM_BM_CONFIG_0_BM2_BYPASS_VOQ_PROCESS	BIT(8)
+#define TM_BM_CONFIG_0_BM2_BYPASS_DEST_PORT_PROCESS	BIT(9)
+#define TM_BM_CONFIG_0_BM2_BYPASS_CA_PROCESS	BIT(10)
+#define TM_BM_CONFIG_0_RECALCULATE_GLOBAL_BUFFERS_USED	BIT(29)
+#define TM_BM_CONFIG_0_DISABLE			BIT(30)
+#define TM_BM_CONFIG_0_CPU_FULL_ACCESS		BIT(31)
+
+#define TM_BM_STATUS_0				0x004
+#define TM_BM_STATUS_0_INIT_DONE		BIT(0)
+
+#define TM_BM_WRED_CONFIG_1			0x02c
+#define TM_BM_WRED_CONFIG_1_WRED_PROFILE_SELECT_MODE	GENMASK(15, 14)
+
+#define TM_BM_TRAFFIC_CONTROL_2			0x074
+#define TM_BM_TRAFFIC_CONTROL_2_WARNING_THRESHOLD_INT	GENMASK(11, 0)
+
+#define TM_BM_TRAFFIC_CONTROL_3			0x078
+#define TM_BM_TRAFFIC_CONTROL_3_LIVING_THRESHOLD_INT	GENMASK(11, 0)
+#define TM_BM_TRAFFIC_CONTROL_3_DYING_GASP_THRESHOLD_INT	GENMASK(27, 16)
+
+#define TM_BM_VOQ_MEM_ACCESS			0x080
+#define TM_BM_VOQ_MEM_ACCESS_ADDR		GENMASK(6, 0)
+
+#define TM_BM_VOQ_MEM_DATA			0x084
+#define TM_BM_VOQ_MEM_DATA_VOQ_PROFILE		GENMASK(4, 0)
+#define TM_BM_VOQ_MEM_DATA_WRED_PROFILE		GENMASK(9, 5)
+#define TM_BM_VOQ_MEM_DATA_DEST_PORT		GENMASK(12, 10)
+#define TM_BM_VOQ_MEM_DATA_VOQ_CNTR_ENABLE	BIT(13)
+#define TM_BM_VOQ_MEM_DATA_VOQ_CNTR		GENMASK(18, 14)
+#define TM_BM_VOQ_MEM_DATA_WRED_ENABLE		BIT(19)
+
+#define TM_BM_VOQ_PROFILE_MEM_ACCESS		0x0c0
+#define TM_BM_VOQ_PROFILE_MEM_ACCESS_ADDR	GENMASK(4, 0)
+
+#define TM_BM_VOQ_PROFILE_MEM_DATA1		0x0c4
+#define TM_BM_VOQ_PROFILE_MEM_DATA0		0x0c8
+#define TM_BM_VOQ_PROFILE_MEM_DATA0_VOQ_MIN_DEPTH	GENMASK(15, 0)
+#define TM_BM_VOQ_PROFILE_MEM_DATA0_VOQ_MAX_DEPTH	GENMASK(31, 16)
+
+#define TM_POL_CONFIG_0				0x100
+#define TM_POL_CONFIG_0_INIT			BIT(0)
+#define TM_POL_CONFIG_0_POL_COLOR_BLIND		BIT(4)
+#define TM_POL_CONFIG_0_POL_BYPASS_YELLOW	BIT(5)
+#define TM_POL_CONFIG_0_POL_BYPASS_RED		BIT(6)
+#define TM_POL_CONFIG_0_POL_DISABLE		BIT(30)
+#define TM_POL_CONFIG_0_CPU_FULL_ACCESS		BIT(31)
+
+#define TM_POL_CONFIG_SPID			0x104
+#define TM_POL_CONFIG_FLOW			0x108
+#define TM_POL_CONFIG_PKT_TYPE			0x10c
+#define TM_POL_CONFIG_CPU			0x110
+#define TM_POL_CONFIG_BYPASS_YELLOW		BIT(0)
+#define TM_POL_CONFIG_BYPASS_RED		BIT(1)
+#define TM_POL_CONFIG_DISABLE			BIT(2)
+#define TM_POL_CONFIG_COLOR_BLIND		BIT(3)
+#define TM_POL_CONFIG_BYPASS_YELLOW_DEFINE	BIT(4)
+#define TM_POL_CONFIG_UPDATE_MODE		BIT(5)
+#define TM_POL_CONFIG_NEST_LEVEL		GENMASK(7, 6)
+#define TM_POL_CONFIG_COMMIT_OVERRIDE_ENABLE	BIT(9)
+#define TM_POL_CONFIG_COMMON_MASK		(GENMASK(7, 0) | BIT(9))
+#define TM_POL_CONFIG_PKT_TYPE_LSPID0		GENMASK(19, 16)
+#define TM_POL_CONFIG_PKT_TYPE_LSPID1		GENMASK(23, 20)
+#define TM_POL_CONFIG_PKT_TYPE_LSPID2		GENMASK(27, 24)
+#define TM_POL_CONFIG_PKT_TYPE_LSPID3		GENMASK(31, 28)
+#define TM_POL_CONFIG_CPU_VOQ0			GENMASK(22, 16)
+#define TM_POL_CONFIG_CPU_VOQ1			GENMASK(30, 24)
+
+#define TM_POL_STATUS_0				0x124
+#define TM_POL_STATUS_0_INIT_DONE		BIT(0)
+
+#define TM_POL_FLOW_PROFILE_MEM_ACCESS		0x190
+#define TM_POL_FLOW_PROFILE_MEM_ACCESS_ADDR	GENMASK(6, 0)
+#define TM_POL_FLOW_PROFILE_MEM_DATA1		0x194
+#define TM_POL_FLOW_PROFILE_MEM_DATA0		0x198
+
+#define TM_PM_CONFIG_0				0x400
+#define TM_PM_CONFIG_0_INIT			BIT(0)
+#define TM_PM_CONFIG_0_AUTO_CLEAR_ON_READ_MODE	GENMASK(5, 4)
+#define TM_PM_CONFIG_0_DISABLE			BIT(30)
+
+#define TM_PM_STATUS_0				0x408
+#define TM_PM_STATUS_0_INIT_DONE		BIT(0)
+
+#define TM_MEM_ACCESS_RBW			BIT(30)
+#define TM_MEM_ACCESS_ACCESS			BIT(31)
+
+#define TM_BM_VOQ_NO				112
+#define TM_BM_CPU_VOQ_PROFILE_FIRST		48
+#define TM_BM_CPU_VOQ_PROFILE_END		72
+#define TM_BM_DEF_VOQ_MIN_DEPTH			48
+#define TM_BM_DEF_VOQ_MAX_DEPTH_EXT_BUFF	65530
+#define TM_BM_DEF_CPU_VOQ_MIN_DEPTH		128
+#define TM_BM_DEF_CPU_VOQ_MAX_DEPTH		32768
+#define TM_BM_DEF_DYING_GASP_INT		(6 * 24)
+#define TM_BM_DEF_LIVING_THSHLD_INT		(TM_BM_DEF_DYING_GASP_INT + \
+						 6 * 3)
+#define TM_BM_WRED_PROFILE_SELECT_DIRECT	2
+
+#define TM_POL_FLOW_POL_NO			128
+#define TM_POL_NEST_LEVEL_SPID			0
+#define TM_POL_NEST_LEVEL_FLOW			1
+#define TM_POL_NEST_LEVEL_PKT_TYPE		2
+
+#define TM_PM_READ_MODE_CLEAR_ALL		1
+
+#define TM_INIT_TIMEOUT_US			200000
+#define TM_ACCESS_TIMEOUT_US			1000
+
+struct cs752x_tm_mem_word {
+	u32 off;
+	u32 val;
+};
+
+static int cs752x_sch_cmd(struct device *dev, void __iomem *sch, u32 data0,
+			  u32 data1)
+{
+	u32 val;
+	int ret;
+
+	writel(data0, sch + SCH_ATOMIC_COMMAND_DATA0);
+	writel(data1, sch + SCH_ATOMIC_COMMAND_DATA1);
+	writel(SCH_ATOMIC_COMMAND_CONTROL_START_WRITE,
+	       sch + SCH_ATOMIC_COMMAND_CONTROL);
+
+	ret = readl_poll_timeout(sch + SCH_INTERRUPT_0, val,
+				 val & SCH_INTERRUPT_0_CPU_CMD_EXECUTED, 1,
+				 SCH_CMD_TIMEOUT_US);
+	if (ret) {
+		dev_err(dev, "sch command %#010x %#010x not executed\n",
+			data0, data1);
+		return ret;
+	}
+
+	writel(SCH_INTERRUPT_0_CPU_CMD_EXECUTED, sch + SCH_INTERRUPT_0);
+
+	val = FIELD_GET(SCH_STATUS_CPU_CMD_STATUS, readl(sch + SCH_STATUS));
+	if (val) {
+		dev_err(dev, "sch command %#010x %#010x failed, status %u\n",
+			data0, data1, val);
+		return -EIO;
+	}
+
+	return 0;
+}
+
+static int cs752x_sch_enable_port(struct device *dev, void __iomem *sch,
+				  unsigned int port)
+{
+	u32 data0, data1;
+
+	data0 = FIELD_PREP(SCH_ATOMIC_COMMAND_DATA0_CMD,
+			   SCH_CMD_CHANGE_PORT_LEVEL_MASK) |
+		FIELD_PREP(SCH_ATOMIC_COMMAND_DATA0_MASK, SCH_ENABLE_PORT);
+	data1 = FIELD_PREP(SCH_ATOMIC_COMMAND_DATA1_PORT, port);
+
+	return cs752x_sch_cmd(dev, sch, data0, data1);
+}
+
+static int cs752x_sch_set_port_burst(struct device *dev, void __iomem *sch,
+				     unsigned int port, unsigned int burst)
+{
+	u32 data0, data1;
+
+	data0 = FIELD_PREP(SCH_ATOMIC_COMMAND_DATA0_CMD,
+			   SCH_CMD_SET_BURST_SIZE) |
+		FIELD_PREP(SCH_ATOMIC_COMMAND_DATA0_BURST, burst);
+	data1 = FIELD_PREP(SCH_ATOMIC_COMMAND_DATA1_PORT, port);
+
+	return cs752x_sch_cmd(dev, sch, data0, data1);
+}
+
+static int cs752x_sch_bypass_shaper(struct device *dev, void __iomem *sch,
+				    unsigned int shaper, unsigned int cpu_port)
+{
+	u32 data0, data1;
+
+	data0 = FIELD_PREP(SCH_ATOMIC_COMMAND_DATA0_CMD,
+			   SCH_CMD_CHANGE_SHAPER_PARA) |
+		FIELD_PREP(SCH_ATOMIC_COMMAND_DATA0_SHAPER, shaper) |
+		FIELD_PREP(SCH_ATOMIC_COMMAND_DATA0_TSIZE, 0);
+	data1 = FIELD_PREP(SCH_ATOMIC_COMMAND_DATA1_CPU_PORT, cpu_port) |
+		FIELD_PREP(SCH_ATOMIC_COMMAND_DATA1_TMAX, 1) |
+		FIELD_PREP(SCH_ATOMIC_COMMAND_DATA1_RPT, 0);
+
+	return cs752x_sch_cmd(dev, sch, data0, data1);
+}
+
+static int cs752x_sch_enable_voq_drr(struct device *dev, void __iomem *sch,
+				     unsigned int voq, unsigned int quanta,
+				     unsigned int cpu_port)
+{
+	u32 data0, data1;
+
+	data0 = FIELD_PREP(SCH_ATOMIC_COMMAND_DATA0_CMD, SCH_CMD_VOQ_AS_DRR) |
+		FIELD_PREP(SCH_ATOMIC_COMMAND_DATA0_VOQ, voq) |
+		FIELD_PREP(SCH_ATOMIC_COMMAND_DATA0_QUANTA, quanta);
+	data1 = FIELD_PREP(SCH_ATOMIC_COMMAND_DATA1_CPU_PORT, cpu_port);
+
+	return cs752x_sch_cmd(dev, sch, data0, data1);
+}
+
+static int cs752x_sch_reset(struct device *dev, void __iomem *sch)
+{
+	u32 val;
+	int ret;
+
+	writel(SCH_CONTROL_SOFT_RESET, sch + SCH_CONTROL);
+	udelay(SCH_RESET_DELAY_US);
+	writel(0, sch + SCH_CONTROL);
+	udelay(SCH_RESET_DELAY_US);
+
+	ret = readl_poll_timeout(sch + SCH_STATUS, val,
+				 val & SCH_STATUS_SCH_MEM_INIT_DONE, 10,
+				 SCH_INIT_TIMEOUT_US);
+	if (ret)
+		dev_err(dev, "sch memory init failed, status %#010x\n", val);
+
+	return ret;
+}
+
+static void cs752x_sch_set_calendar(void __iomem *sch)
+{
+	static const u8 calendar[SCH_MAX_CALENDAR_LENGTH] = {
+		SCH_PORT_SCH_ID, SCH_PORT_SCH_ID, SCH_PORT_SCH_ID,
+		SCH_CPU_SCH_ID, SCH_CPU_SCH_ID,
+		SCH_PORT_SCH_ID, SCH_PORT_SCH_ID, SCH_PORT_SCH_ID,
+		SCH_CPU_SCH_ID, SCH_CPU_SCH_ID,
+		SCH_PORT_SCH_ID, SCH_PORT_SCH_ID, SCH_PORT_SCH_ID,
+		SCH_ROOT_SCH_ID,
+		SCH_PORT_SCH_ID, SCH_PORT_SCH_ID, SCH_PORT_SCH_ID,
+		SCH_CPU_SCH_ID, SCH_CPU_SCH_ID,
+		SCH_PORT_SCH_ID, SCH_PORT_SCH_ID, SCH_PORT_SCH_ID,
+		SCH_CPU_SCH_ID, SCH_CPU_SCH_ID,
+		SCH_PORT_SCH_ID, SCH_PORT_SCH_ID, SCH_PORT_SCH_ID,
+		SCH_ROOT_SCH_ID, SCH_ROOT_SCH_ID,
+		SCH_PORT_SCH_ID, SCH_PORT_SCH_ID, SCH_PORT_SCH_ID,
+	};
+	u32 cal0 = 0, cal1 = 0;
+	unsigned int i;
+
+	for (i = 0; i < SCH_MAX_CALENDAR_LENGTH / 2; i++)
+		cal0 |= (u32)(calendar[i] & 0x3) << (2 * i);
+	for (; i < SCH_MAX_CALENDAR_LENGTH; i++)
+		cal1 |= (u32)(calendar[i] & 0x3) <<
+			(2 * (i - SCH_MAX_CALENDAR_LENGTH / 2));
+
+	if (readl(sch + SCH_STATUS) & SCH_STATUS_CURRENT_SET_TDM_CONTROL) {
+		writel(cal0, sch + SCH_MAIN_TDM_PORT_CALENDAR0_SETA);
+		writel(cal1, sch + SCH_MAIN_TDM_PORT_CALENDAR1_SETA);
+		writel(FIELD_PREP(SCH_MAIN_TDM_CONTROL_CALENDAR_RETURN,
+				  SCH_MAX_CALENDAR_LENGTH - 1),
+		       sch + SCH_MAIN_TDM_CONTROL_SETA);
+	} else {
+		writel(cal0, sch + SCH_MAIN_TDM_PORT_CALENDAR0_SETB);
+		writel(cal1, sch + SCH_MAIN_TDM_PORT_CALENDAR1_SETB);
+		writel(FIELD_PREP(SCH_MAIN_TDM_CONTROL_CALENDAR_RETURN,
+				  SCH_MAX_CALENDAR_LENGTH - 1),
+		       sch + SCH_MAIN_TDM_CONTROL_SETB);
+	}
+
+	writel(SCH_SWITCH_TDM_CONTROL_SET_SWITCH,
+	       sch + SCH_SWITCH_TDM_CONTROL_SET);
+}
+
+int cs752x_sch_init(struct device *dev, void __iomem *sch)
+{
+	unsigned int port, q, cpu_port;
+	u32 val;
+	int ret;
+
+	ret = cs752x_sch_reset(dev, sch);
+	if (ret)
+		return ret;
+
+	cs752x_sch_set_calendar(sch);
+
+	for (port = 0; port < SCH_PORT_NO; port++) {
+		cpu_port = port >= SCH_CPU_PORT0 ? port - SCH_CPU_PORT0 : 0;
+
+		ret = cs752x_sch_enable_port(dev, sch, port);
+		if (ret)
+			return ret;
+		ret = cs752x_sch_set_port_burst(dev, sch, port, 0);
+		if (ret)
+			return ret;
+		ret = cs752x_sch_bypass_shaper(dev, sch, port + SCH_LT_BASE_ID, 0);
+		if (ret)
+			return ret;
+		ret = cs752x_sch_bypass_shaper(dev, sch, port + SCH_ST_BASE_ID, 0);
+		if (ret)
+			return ret;
+
+		for (q = 0; q < SCH_MAX_PORT_QUEUE; q++) {
+			ret = cs752x_sch_enable_voq_drr(dev, sch,
+							port * SCH_MAX_PORT_QUEUE + q,
+							SCH_DEFAULT_QUANTA, cpu_port);
+			if (ret)
+				return ret;
+			ret = cs752x_sch_bypass_shaper(dev, sch,
+						       port + SCH_DRR_BASE_ID,
+						       cpu_port);
+			if (ret)
+				return ret;
+		}
+	}
+
+	val = readl(sch + SCH_SHAPER_CONFIGURATION);
+	val &= ~SCH_SHAPER_CONFIGURATION_CLOCKS_PER_ROUND_ST;
+	val |= FIELD_PREP(SCH_SHAPER_CONFIGURATION_CLOCKS_PER_ROUND_ST,
+			  SCH_CLOCKS_PER_ROUND_ST);
+	val |= SCH_SHAPER_CONFIGURATION_GLOBAL_SCRUB_ENABLE;
+	writel(val, sch + SCH_SHAPER_CONFIGURATION);
+
+	val = readl(sch + SCH_DEBUG_CONTROL);
+	val &= ~SCH_DEBUG_CONTROL_SWITCH_EXPR_MODE_LOWLVL;
+	val |= FIELD_PREP(SCH_DEBUG_CONTROL_SWITCH_EXPR_MODE_LOWLVL,
+			  SCH_EXPR_MODE_LOWLVL);
+	writel(val, sch + SCH_DEBUG_CONTROL);
+
+	return 0;
+}
+
+static int cs752x_tm_wait_init_done(struct device *dev, void __iomem *tm,
+				    u32 status_off, u32 init_done,
+				    const char *name)
+{
+	u32 val;
+	int ret;
+
+	/* init_done is valid while INIT is asserted; clearing INIT clears it. */
+	ret = readl_poll_timeout(tm + status_off, val, val & init_done, 10,
+				 TM_INIT_TIMEOUT_US);
+	if (ret)
+		dev_err(dev, "tm %s init not done, status %#010x\n", name,
+			val);
+
+	return ret;
+}
+
+static int cs752x_tm_mem_write(struct device *dev, void __iomem *tm,
+			       u32 cfg_off, u32 cpu_full_access, u32 access_off,
+			       u32 addr, const struct cs752x_tm_mem_word *words,
+			       unsigned int nwords)
+{
+	unsigned int i;
+	u32 val;
+	int ret;
+
+	writel(readl(tm + cfg_off) | cpu_full_access, tm + cfg_off);
+
+	for (i = 0; i < nwords; i++)
+		writel(words[i].val, tm + words[i].off);
+
+	writel(TM_MEM_ACCESS_ACCESS | TM_MEM_ACCESS_RBW | addr,
+	       tm + access_off);
+	ret = readl_poll_timeout(tm + access_off, val,
+				 !(val & TM_MEM_ACCESS_ACCESS), 0,
+				 TM_ACCESS_TIMEOUT_US);
+
+	writel(readl(tm + cfg_off) & ~cpu_full_access, tm + cfg_off);
+
+	if (ret)
+		dev_err(dev, "tm memory write %#03x entry %#x timed out\n",
+			access_off, addr);
+
+	return ret;
+}
+
+static int cs752x_tm_bm_set_voq_profile(struct device *dev, void __iomem *tm,
+					unsigned int profile,
+					unsigned int min_depth,
+					unsigned int max_depth)
+{
+	struct cs752x_tm_mem_word words[2];
+
+	words[0].off = TM_BM_VOQ_PROFILE_MEM_DATA0;
+	words[0].val = FIELD_PREP(TM_BM_VOQ_PROFILE_MEM_DATA0_VOQ_MIN_DEPTH,
+				  min_depth) |
+		       FIELD_PREP(TM_BM_VOQ_PROFILE_MEM_DATA0_VOQ_MAX_DEPTH,
+				  max_depth);
+	words[1].off = TM_BM_VOQ_PROFILE_MEM_DATA1;
+	words[1].val = 0;
+
+	return cs752x_tm_mem_write(dev, tm, TM_BM_CONFIG_0,
+				   TM_BM_CONFIG_0_CPU_FULL_ACCESS,
+				   TM_BM_VOQ_PROFILE_MEM_ACCESS,
+				   FIELD_PREP(TM_BM_VOQ_PROFILE_MEM_ACCESS_ADDR,
+					      profile),
+				   words, 2);
+}
+
+static int cs752x_tm_bm_set_voq_mem(struct device *dev, void __iomem *tm,
+				    unsigned int voq)
+{
+	struct cs752x_tm_mem_word word;
+	unsigned int profile, wred_profile, dest_port;
+
+	profile = voq >= TM_BM_CPU_VOQ_PROFILE_FIRST &&
+		  voq < TM_BM_CPU_VOQ_PROFILE_END ? 1 : 0;
+	wred_profile = voq & 0x1f;
+	dest_port = (voq >> 3) & 0x7;
+
+	word.off = TM_BM_VOQ_MEM_DATA;
+	word.val = FIELD_PREP(TM_BM_VOQ_MEM_DATA_VOQ_PROFILE, profile) |
+		   FIELD_PREP(TM_BM_VOQ_MEM_DATA_WRED_PROFILE, wred_profile) |
+		   FIELD_PREP(TM_BM_VOQ_MEM_DATA_DEST_PORT, dest_port) |
+		   FIELD_PREP(TM_BM_VOQ_MEM_DATA_VOQ_CNTR_ENABLE, 0) |
+		   FIELD_PREP(TM_BM_VOQ_MEM_DATA_VOQ_CNTR, 0) |
+		   FIELD_PREP(TM_BM_VOQ_MEM_DATA_WRED_ENABLE, 0);
+
+	return cs752x_tm_mem_write(dev, tm, TM_BM_CONFIG_0,
+				   TM_BM_CONFIG_0_CPU_FULL_ACCESS,
+				   TM_BM_VOQ_MEM_ACCESS,
+				   FIELD_PREP(TM_BM_VOQ_MEM_ACCESS_ADDR, voq),
+				   &word, 1);
+}
+
+static int cs752x_tm_bm_init(struct device *dev, void __iomem *tm)
+{
+	unsigned int voq;
+	u32 val, cfg;
+	int ret;
+
+	val = readl(tm + TM_BM_WRED_CONFIG_1);
+	val &= ~TM_BM_WRED_CONFIG_1_WRED_PROFILE_SELECT_MODE;
+	val |= FIELD_PREP(TM_BM_WRED_CONFIG_1_WRED_PROFILE_SELECT_MODE,
+			  TM_BM_WRED_PROFILE_SELECT_DIRECT);
+	writel(val, tm + TM_BM_WRED_CONFIG_1);
+
+	cfg = readl(tm + TM_BM_CONFIG_0);
+	cfg &= ~(TM_BM_CONFIG_0_DISABLE |
+		 TM_BM_CONFIG_0_RECALCULATE_GLOBAL_BUFFERS_USED |
+		 TM_BM_CONFIG_0_BM2_BYPASS_CA_PROCESS |
+		 TM_BM_CONFIG_0_BM2_BYPASS_DEST_PORT_PROCESS |
+		 TM_BM_CONFIG_0_BM2_BYPASS_VOQ_PROCESS |
+		 TM_BM_CONFIG_0_BM1_BYPASS_CA_PROCESS |
+		 TM_BM_CONFIG_0_BM1_BYPASS_DEST_PORT_PROCESS |
+		 TM_BM_CONFIG_0_BM1_BYPASS_VOQ_PROCESS |
+		 TM_BM_CONFIG_0_ENQUE_HDR_ADJUST |
+		 TM_BM_CONFIG_0_INIT);
+
+	writel(cfg | TM_BM_CONFIG_0_BM1_BYPASS_CA_PROCESS |
+	       TM_BM_CONFIG_0_BM2_BYPASS_DEST_PORT_PROCESS |
+	       TM_BM_CONFIG_0_BM2_BYPASS_VOQ_PROCESS |
+	       TM_BM_CONFIG_0_INIT, tm + TM_BM_CONFIG_0);
+	ret = cs752x_tm_wait_init_done(dev, tm, TM_BM_STATUS_0,
+				       TM_BM_STATUS_0_INIT_DONE, "bm");
+	if (ret)
+		return ret;
+
+	writel(cfg, tm + TM_BM_CONFIG_0);
+
+	writel(FIELD_PREP(TM_BM_TRAFFIC_CONTROL_2_WARNING_THRESHOLD_INT, 0),
+	       tm + TM_BM_TRAFFIC_CONTROL_2);
+	writel(FIELD_PREP(TM_BM_TRAFFIC_CONTROL_3_LIVING_THRESHOLD_INT,
+			  TM_BM_DEF_LIVING_THSHLD_INT) |
+	       FIELD_PREP(TM_BM_TRAFFIC_CONTROL_3_DYING_GASP_THRESHOLD_INT,
+			  TM_BM_DEF_DYING_GASP_INT),
+	       tm + TM_BM_TRAFFIC_CONTROL_3);
+
+	ret = cs752x_tm_bm_set_voq_profile(dev, tm, 0, TM_BM_DEF_VOQ_MIN_DEPTH,
+					   TM_BM_DEF_VOQ_MAX_DEPTH_EXT_BUFF);
+	if (ret)
+		return ret;
+
+	ret = cs752x_tm_bm_set_voq_profile(dev, tm, 1,
+					   TM_BM_DEF_CPU_VOQ_MIN_DEPTH,
+					   TM_BM_DEF_CPU_VOQ_MAX_DEPTH);
+	if (ret)
+		return ret;
+
+	for (voq = 0; voq < TM_BM_VOQ_NO; voq++) {
+		ret = cs752x_tm_bm_set_voq_mem(dev, tm, voq);
+		if (ret)
+			return ret;
+	}
+
+	return 0;
+}
+
+static int cs752x_tm_pol_set_flow_policer_disabled(struct device *dev,
+						   void __iomem *tm,
+						   unsigned int id)
+{
+	struct cs752x_tm_mem_word words[2];
+
+	words[0].off = TM_POL_FLOW_PROFILE_MEM_DATA0;
+	words[0].val = 0;
+	words[1].off = TM_POL_FLOW_PROFILE_MEM_DATA1;
+	words[1].val = 0;
+
+	return cs752x_tm_mem_write(dev, tm, TM_POL_CONFIG_0,
+				   TM_POL_CONFIG_0_CPU_FULL_ACCESS,
+				   TM_POL_FLOW_PROFILE_MEM_ACCESS,
+				   FIELD_PREP(TM_POL_FLOW_PROFILE_MEM_ACCESS_ADDR,
+					      id),
+				   words, 2);
+}
+
+static int cs752x_tm_pol_init(struct device *dev, void __iomem *tm)
+{
+	unsigned int id;
+	u32 val, cfg;
+	int ret;
+
+	val = readl(tm + TM_POL_CONFIG_SPID);
+	val &= ~TM_POL_CONFIG_COMMON_MASK;
+	val |= FIELD_PREP(TM_POL_CONFIG_NEST_LEVEL, TM_POL_NEST_LEVEL_SPID);
+	writel(val, tm + TM_POL_CONFIG_SPID);
+
+	val = readl(tm + TM_POL_CONFIG_FLOW);
+	val &= ~TM_POL_CONFIG_COMMON_MASK;
+	val |= FIELD_PREP(TM_POL_CONFIG_NEST_LEVEL, TM_POL_NEST_LEVEL_FLOW);
+	writel(val, tm + TM_POL_CONFIG_FLOW);
+
+	val = readl(tm + TM_POL_CONFIG_CPU);
+	val &= ~(TM_POL_CONFIG_COMMON_MASK | TM_POL_CONFIG_CPU_VOQ0 |
+		 TM_POL_CONFIG_CPU_VOQ1);
+	val |= TM_POL_CONFIG_DISABLE;
+	writel(val, tm + TM_POL_CONFIG_CPU);
+
+	val = readl(tm + TM_POL_CONFIG_PKT_TYPE);
+	val &= ~(TM_POL_CONFIG_COMMON_MASK | TM_POL_CONFIG_PKT_TYPE_LSPID0 |
+		 TM_POL_CONFIG_PKT_TYPE_LSPID1 | TM_POL_CONFIG_PKT_TYPE_LSPID2 |
+		 TM_POL_CONFIG_PKT_TYPE_LSPID3);
+	val |= FIELD_PREP(TM_POL_CONFIG_NEST_LEVEL,
+			  TM_POL_NEST_LEVEL_PKT_TYPE) |
+	       FIELD_PREP(TM_POL_CONFIG_PKT_TYPE_LSPID0, 0) |
+	       FIELD_PREP(TM_POL_CONFIG_PKT_TYPE_LSPID1, 1) |
+	       FIELD_PREP(TM_POL_CONFIG_PKT_TYPE_LSPID2, 2) |
+	       FIELD_PREP(TM_POL_CONFIG_PKT_TYPE_LSPID3, 0);
+	writel(val, tm + TM_POL_CONFIG_PKT_TYPE);
+
+	cfg = readl(tm + TM_POL_CONFIG_0);
+	cfg &= ~(TM_POL_CONFIG_0_POL_DISABLE | TM_POL_CONFIG_0_POL_BYPASS_RED |
+		 TM_POL_CONFIG_0_POL_BYPASS_YELLOW |
+		 TM_POL_CONFIG_0_POL_COLOR_BLIND | TM_POL_CONFIG_0_INIT);
+
+	writel(cfg | TM_POL_CONFIG_0_INIT, tm + TM_POL_CONFIG_0);
+	ret = cs752x_tm_wait_init_done(dev, tm, TM_POL_STATUS_0,
+				       TM_POL_STATUS_0_INIT_DONE, "pol");
+	if (ret)
+		return ret;
+
+	writel(cfg, tm + TM_POL_CONFIG_0);
+
+	for (id = 0; id < TM_POL_FLOW_POL_NO; id++) {
+		ret = cs752x_tm_pol_set_flow_policer_disabled(dev, tm, id);
+		if (ret)
+			return ret;
+	}
+
+	return 0;
+}
+
+static int cs752x_tm_pm_init(struct device *dev, void __iomem *tm)
+{
+	u32 cfg;
+	int ret;
+
+	cfg = readl(tm + TM_PM_CONFIG_0);
+	cfg &= ~(TM_PM_CONFIG_0_DISABLE | TM_PM_CONFIG_0_AUTO_CLEAR_ON_READ_MODE |
+		 TM_PM_CONFIG_0_INIT);
+	cfg |= FIELD_PREP(TM_PM_CONFIG_0_AUTO_CLEAR_ON_READ_MODE,
+			  TM_PM_READ_MODE_CLEAR_ALL);
+
+	writel(cfg | TM_PM_CONFIG_0_INIT, tm + TM_PM_CONFIG_0);
+	ret = cs752x_tm_wait_init_done(dev, tm, TM_PM_STATUS_0,
+				       TM_PM_STATUS_0_INIT_DONE, "pm");
+	if (ret)
+		return ret;
+
+	writel(cfg, tm + TM_PM_CONFIG_0);
+
+	return 0;
+}
+
+int cs752x_tm_init(struct device *dev, void __iomem *tm)
+{
+	int ret;
+
+	ret = cs752x_tm_pol_init(dev, tm);
+	if (ret)
+		return ret;
+	ret = cs752x_tm_bm_init(dev, tm);
+	if (ret)
+		return ret;
+	return cs752x_tm_pm_init(dev, tm);
+}

-- 
2.53.0

