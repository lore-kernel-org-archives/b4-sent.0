From: Cedric Jehasse <cedric.jehasse@luminex.be>
Date: Fri, 13 Feb 2026 13:48:00 +0100
Subject: [PATCH net-next] net: dsa: mv88e6xxx: Add partial support for TCAM
 entries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260213-net-next-mv88e6xxx-tcam-v1-1-051e552e2afc@luminex.be>
X-B4-Tracking: v=1; b=H4sIAH8dj2kC/zWMuwqAMAwAf0UyG2grluKviIOPVDNYpS0SEP/dI
 jjccMPdDYkiU4KuuiHSxYmPUETXFczbGFZCXoqDUcYqoxsMlAuScb+cIysimOdxR2/bibRVyvk
 JSn1G8izfuYc/guF5XpmzpqpzAAAA
X-Change-ID: 20260213-net-next-mv88e6xxx-tcam-f65be16008fb
To: Andrew Lunn <andrew@lunn.ch>, Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 Cedric Jehasse <cedric.jehasse@luminex.be>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770986892; l=25312;
 i=cedric.jehasse@luminex.be; s=20260213; h=from:subject:message-id;
 bh=OB50XpWx29f5Qj3CscLPZoq2ZVU/+dX2uW/DcfjjbKw=;
 b=bb+eHop4IrkhTJuMgs9Vr5mx8GYv7pi48RvVBglMC/ZsC98wMe2b20Ol2ZOYJRaL63rOGuy/D
 4s4kVf4aJVBCjmSp1AT4QLYbT7aK2QyGehZRqaAPZ7EFiKEyw38WgbJ
X-Developer-Key: i=cedric.jehasse@luminex.be; a=ed25519;
 pk=DL2RaHc2bc7tTDTMJdugm42BtJk4Ip+7V41Gkj+Avjk=
X-Endpoint-Received: by B4 Relay for cedric.jehasse@luminex.be/20260213 with auth_id=638
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch adds partial Ternary Content Addressable Memory (TCAM) for
the mv88e6390 and mv88e6393 family of switches. TCAM entries allow the
switch to match the first 48 or 96 bytes of a frame and take actions on
matched frames.

This patch introduces a subset of the available TCAM functionality.
Matching on ip addresses/protocol and trapping to the cpu.

Eg. to trap traffic with destination ip 224.0.1.129 to the cpu:

tc qdisc add dev p1 clsact
tc filter add dev p1 ingress protocol ip flower skip_sw \
    dst_ip 224.0.1.129 action trap

Signed-off-by: Cedric Jehasse <cedric.jehasse@luminex.be>
---
 drivers/net/dsa/mv88e6xxx/Makefile   |   2 +
 drivers/net/dsa/mv88e6xxx/chip.c     |  30 ++++
 drivers/net/dsa/mv88e6xxx/chip.h     |  53 +++++++
 drivers/net/dsa/mv88e6xxx/port.c     |  23 ++-
 drivers/net/dsa/mv88e6xxx/port.h     |   7 +-
 drivers/net/dsa/mv88e6xxx/tcam.c     | 287 +++++++++++++++++++++++++++++++++++
 drivers/net/dsa/mv88e6xxx/tcam.h     |  37 +++++
 drivers/net/dsa/mv88e6xxx/tcflower.c | 138 +++++++++++++++++
 drivers/net/dsa/mv88e6xxx/tcflower.h |  13 ++
 9 files changed, 588 insertions(+), 2 deletions(-)

diff --git a/drivers/net/dsa/mv88e6xxx/Makefile b/drivers/net/dsa/mv88e6xxx/Makefile
index dd961081d631..b0b08c6f159c 100644
--- a/drivers/net/dsa/mv88e6xxx/Makefile
+++ b/drivers/net/dsa/mv88e6xxx/Makefile
@@ -21,6 +21,8 @@ mv88e6xxx-objs += serdes.o
 mv88e6xxx-objs += smi.o
 mv88e6xxx-objs += switchdev.o
 mv88e6xxx-objs += trace.o
+mv88e6xxx-objs += tcflower.o
+mv88e6xxx-objs += tcam.o
 
 # for tracing framework to find trace.h
 CFLAGS_trace.o := -I$(src)
diff --git a/drivers/net/dsa/mv88e6xxx/chip.c b/drivers/net/dsa/mv88e6xxx/chip.c
index 09002c853b78..baf67714229a 100644
--- a/drivers/net/dsa/mv88e6xxx/chip.c
+++ b/drivers/net/dsa/mv88e6xxx/chip.c
@@ -43,6 +43,8 @@
 #include "ptp.h"
 #include "serdes.h"
 #include "smi.h"
+#include "tcam.h"
+#include "tcflower.h"
 
 static void assert_reg_lock(struct mv88e6xxx_chip *chip)
 {
@@ -3560,6 +3562,11 @@ static int mv88e6xxx_setup_port(struct mv88e6xxx_chip *chip, int port)
 		if (err)
 			return err;
 	}
+	if (chip->info->ops->port_enable_tcam) {
+		err = chip->info->ops->port_enable_tcam(chip, port);
+		if (err)
+			return err;
+	}
 
 	if (chip->info->ops->port_tag_remap) {
 		err = chip->info->ops->port_tag_remap(chip, port);
@@ -3938,6 +3945,14 @@ static int mv88e6xxx_mdios_register(struct mv88e6xxx_chip *chip)
 	return 0;
 }
 
+static int mv88e6xxx_tcam_setup(struct mv88e6xxx_chip *chip)
+{
+	if (!mv88e6xxx_has_tcam(chip))
+		return 0;
+
+	return chip->info->ops->tcam_ops->flush_tcam(chip);
+}
+
 static void mv88e6xxx_teardown(struct dsa_switch *ds)
 {
 	struct mv88e6xxx_chip *chip = ds->priv;
@@ -4083,6 +4098,10 @@ static int mv88e6xxx_setup(struct dsa_switch *ds)
 	if (err)
 		goto unlock;
 
+	err = mv88e6xxx_tcam_setup(chip);
+	if (err)
+		goto unlock;
+
 unlock:
 	mv88e6xxx_reg_unlock(chip);
 
@@ -5134,6 +5153,7 @@ static const struct mv88e6xxx_ops mv88e6290_ops = {
 	.ptp_ops = &mv88e6390_ptp_ops,
 	.phylink_get_caps = mv88e6390_phylink_get_caps,
 	.pcs_ops = &mv88e6390_pcs_ops,
+	.tcam_ops = &mv88e6390_tcam_ops,
 };
 
 static const struct mv88e6xxx_ops mv88e6320_ops = {
@@ -5525,6 +5545,7 @@ static const struct mv88e6xxx_ops mv88e6390_ops = {
 	.serdes_get_regs = mv88e6390_serdes_get_regs,
 	.phylink_get_caps = mv88e6390_phylink_get_caps,
 	.pcs_ops = &mv88e6390_pcs_ops,
+	.tcam_ops = &mv88e6390_tcam_ops,
 };
 
 static const struct mv88e6xxx_ops mv88e6390x_ops = {
@@ -5621,6 +5642,7 @@ static const struct mv88e6xxx_ops mv88e6393x_ops = {
 	.port_set_cmode = mv88e6393x_port_set_cmode,
 	.port_setup_message_port = mv88e6xxx_setup_message_port,
 	.port_set_upstream_port = mv88e6393x_port_set_upstream_port,
+	.port_enable_tcam = mv88e6xxx_port_enable_tcam,
 	.stats_snapshot = mv88e6390_g1_stats_snapshot,
 	.stats_set_histogram = mv88e6390_g1_stats_set_histogram,
 	.stats_get_sset_count = mv88e6320_stats_get_sset_count,
@@ -5652,6 +5674,7 @@ static const struct mv88e6xxx_ops mv88e6393x_ops = {
 	.ptp_ops = &mv88e6352_ptp_ops,
 	.phylink_get_caps = mv88e6393x_phylink_get_caps,
 	.pcs_ops = &mv88e6393x_pcs_ops,
+	.tcam_ops = &mv88e6390_tcam_ops,
 };
 
 static const struct mv88e6xxx_info mv88e6xxx_table[] = {
@@ -6140,6 +6163,7 @@ static const struct mv88e6xxx_info mv88e6xxx_table[] = {
 		.pvt = true,
 		.multi_chip = true,
 		.ptp_support = true,
+		.tcam_support = true,
 		.ops = &mv88e6393x_ops,
 	},
 
@@ -6241,6 +6265,7 @@ static const struct mv88e6xxx_info mv88e6xxx_table[] = {
 		.pvt = true,
 		.multi_chip = true,
 		.ptp_support = true,
+		.tcam_support = true,
 		.ops = &mv88e6290_ops,
 	},
 
@@ -6454,6 +6479,7 @@ static const struct mv88e6xxx_info mv88e6xxx_table[] = {
 		.multi_chip = true,
 		.edsa_support = MV88E6XXX_EDSA_UNDOCUMENTED,
 		.ptp_support = true,
+		.tcam_support = true,
 		.ops = &mv88e6390_ops,
 	},
 	[MV88E6390X] = {
@@ -6505,6 +6531,7 @@ static const struct mv88e6xxx_info mv88e6xxx_table[] = {
 		.pvt = true,
 		.multi_chip = true,
 		.ptp_support = true,
+		.tcam_support = true,
 		.ops = &mv88e6393x_ops,
 	},
 };
@@ -6589,6 +6616,7 @@ static struct mv88e6xxx_chip *mv88e6xxx_alloc_chip(struct device *dev)
 	INIT_LIST_HEAD(&chip->mdios);
 	idr_init(&chip->policies);
 	INIT_LIST_HEAD(&chip->msts);
+	INIT_LIST_HEAD(&chip->tcam.entries);
 
 	return chip;
 }
@@ -7184,6 +7212,8 @@ static const struct dsa_switch_ops mv88e6xxx_switch_ops = {
 	.port_hwtstamp_get	= mv88e6xxx_port_hwtstamp_get,
 	.port_txtstamp		= mv88e6xxx_port_txtstamp,
 	.port_rxtstamp		= mv88e6xxx_port_rxtstamp,
+	.cls_flower_add		= mv88e6xxx_cls_flower_add,
+	.cls_flower_del         = mv88e6xxx_cls_flower_del,
 	.get_ts_info		= mv88e6xxx_get_ts_info,
 	.devlink_param_get	= mv88e6xxx_devlink_param_get,
 	.devlink_param_set	= mv88e6xxx_devlink_param_set,
diff --git a/drivers/net/dsa/mv88e6xxx/chip.h b/drivers/net/dsa/mv88e6xxx/chip.h
index e073446ee7d0..01148ebf6bb1 100644
--- a/drivers/net/dsa/mv88e6xxx/chip.h
+++ b/drivers/net/dsa/mv88e6xxx/chip.h
@@ -178,6 +178,9 @@ struct mv88e6xxx_info {
 	 * port 0, 1 means internal PHYs range starts at port 1, etc
 	 */
 	unsigned int internal_phys_offset;
+
+	/* Supports TCAM */
+	bool tcam_support;
 };
 
 struct mv88e6xxx_atu_entry {
@@ -210,6 +213,7 @@ struct mv88e6xxx_avb_ops;
 struct mv88e6xxx_ptp_ops;
 struct mv88e6xxx_pcs_ops;
 struct mv88e6xxx_cc_coeffs;
+struct mv88e6xxx_tcam_ops;
 
 struct mv88e6xxx_irq {
 	u16 masked;
@@ -339,6 +343,10 @@ struct mv88e6xxx_hw_stat {
 	int type;
 };
 
+struct mv88e6xxx_tcam {
+	struct list_head entries;
+};
+
 struct mv88e6xxx_chip {
 	const struct mv88e6xxx_info *info;
 
@@ -444,6 +452,35 @@ struct mv88e6xxx_chip {
 
 	/* FID map */
 	DECLARE_BITMAP(fid_bitmap, MV88E6XXX_N_FID);
+
+	/* TCAM entries */
+	struct mv88e6xxx_tcam tcam;
+};
+
+#define TCAM_MATCH_SIZE 96
+
+struct mv88e6xxx_tcam_key {
+	u16 spv;
+	u16 spv_mask;
+
+	u8 frame_data[TCAM_MATCH_SIZE];
+	u8 frame_mask[TCAM_MATCH_SIZE];
+};
+
+struct mv88e6xxx_tcam_action {
+	u8 dpv_mode;
+	u16 dpv;
+};
+
+struct mv88e6xxx_tcam_entry {
+	struct list_head list;
+	unsigned long cookie;
+	u32 prio;
+	u8 hw_idx;
+
+	struct mv88e6xxx_tcam_key key;
+	struct mv88e6xxx_tcam_action action;
+
 };
 
 struct mv88e6xxx_bus_ops {
@@ -678,6 +715,11 @@ struct mv88e6xxx_ops {
 
 	/* Max Frame Size */
 	int (*set_max_frame_size)(struct mv88e6xxx_chip *chip, int mtu);
+
+	int (*port_enable_tcam)(struct mv88e6xxx_chip *chip, int port);
+
+	/* Ternary Content Addressable Memory operations */
+	const struct mv88e6xxx_tcam_ops *tcam_ops;
 };
 
 struct mv88e6xxx_irq_ops {
@@ -752,6 +794,12 @@ struct mv88e6xxx_pcs_ops {
 
 };
 
+struct mv88e6xxx_tcam_ops {
+	int (*entry_add)(struct mv88e6xxx_chip *chip, struct mv88e6xxx_tcam_entry *entry, u8 idx);
+	int (*flush_tcam)(struct mv88e6xxx_chip *chip);
+	unsigned int dev_addr;
+};
+
 static inline bool mv88e6xxx_has_stu(struct mv88e6xxx_chip *chip)
 {
 	return chip->info->max_sid > 0 &&
@@ -769,6 +817,11 @@ static inline bool mv88e6xxx_has_lag(struct mv88e6xxx_chip *chip)
 	return !!chip->info->global2_addr;
 }
 
+static inline bool mv88e6xxx_has_tcam(struct mv88e6xxx_chip *chip)
+{
+	return chip->info->tcam_support;
+}
+
 static inline unsigned int mv88e6xxx_num_databases(struct mv88e6xxx_chip *chip)
 {
 	return chip->info->num_databases;
diff --git a/drivers/net/dsa/mv88e6xxx/port.c b/drivers/net/dsa/mv88e6xxx/port.c
index 66b1b7277281..e9d0289f91ad 100644
--- a/drivers/net/dsa/mv88e6xxx/port.c
+++ b/drivers/net/dsa/mv88e6xxx/port.c
@@ -1380,7 +1380,28 @@ int mv88e6xxx_port_disable_learn_limit(struct mv88e6xxx_chip *chip, int port)
 
 int mv88e6xxx_port_disable_pri_override(struct mv88e6xxx_chip *chip, int port)
 {
-	return mv88e6xxx_port_write(chip, port, MV88E6XXX_PORT_PRI_OVERRIDE, 0);
+	u16 reg;
+	int err;
+
+	err = mv88e6xxx_port_read(chip, port, MV88E6XXX_PORT_PRI_OVERRIDE, &reg);
+	if (err)
+		return err;
+
+	reg &= MV88E6XXX_PORT_PRI_OVERRIDE_TCAM_MODE_MASK;
+	return mv88e6xxx_port_write(chip, port, MV88E6XXX_PORT_PRI_OVERRIDE, reg);
+}
+
+int mv88e6xxx_port_enable_tcam(struct mv88e6xxx_chip *chip, int port)
+{
+	u16 reg;
+	int err;
+
+	err = mv88e6xxx_port_read(chip, port, MV88E6XXX_PORT_PRI_OVERRIDE, &reg);
+	if (err)
+		return err;
+
+	reg |= MV88E6XXX_PORT_PRI_OVERRIDE_TCAM_MODE_96_BYTE;
+	return mv88e6xxx_port_write(chip, port, MV88E6XXX_PORT_PRI_OVERRIDE, reg);
 }
 
 /* Offset 0x0E: Policy & MGMT Control Register for FAMILY 6191X 6193X 6393X */
diff --git a/drivers/net/dsa/mv88e6xxx/port.h b/drivers/net/dsa/mv88e6xxx/port.h
index c1d2f99efb1c..a2492cf4d920 100644
--- a/drivers/net/dsa/mv88e6xxx/port.h
+++ b/drivers/net/dsa/mv88e6xxx/port.h
@@ -254,7 +254,10 @@
 #define MV88E6XXX_PORT_ATU_CTL		0x0c
 
 /* Offset 0x0D: Priority Override Register */
-#define MV88E6XXX_PORT_PRI_OVERRIDE	0x0d
+#define MV88E6XXX_PORT_PRI_OVERRIDE			0x0d
+#define MV88E6XXX_PORT_PRI_OVERRIDE_TCAM_MODE_MASK	0x0003
+#define MV88E6XXX_PORT_PRI_OVERRIDE_TCAM_MODE_48_BYTE	0x0001
+#define MV88E6XXX_PORT_PRI_OVERRIDE_TCAM_MODE_96_BYTE	0x0002
 
 /* Offset 0x0E: Policy Control Register */
 #define MV88E6XXX_PORT_POLICY_CTL		0x0e
@@ -608,4 +611,6 @@ int mv88e6xxx_port_hidden_wait(struct mv88e6xxx_chip *chip);
 int mv88e6xxx_port_hidden_read(struct mv88e6xxx_chip *chip, int block, int port,
 			       int reg, u16 *val);
 
+int mv88e6xxx_port_enable_tcam(struct mv88e6xxx_chip *chip, int port);
+
 #endif /* _MV88E6XXX_PORT_H */
diff --git a/drivers/net/dsa/mv88e6xxx/tcam.c b/drivers/net/dsa/mv88e6xxx/tcam.c
new file mode 100644
index 000000000000..b02ae836348d
--- /dev/null
+++ b/drivers/net/dsa/mv88e6xxx/tcam.c
@@ -0,0 +1,287 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Marvell 88E6xxx Switch TCAM support
+ *
+ * Copyright (c) 2026 Luminex Network Intelligence
+ */
+
+#include "linux/list.h"
+
+#include "chip.h"
+#include "tcam.h"
+
+/* TCAM operatation register */
+#define MV88E6XXX_TCAM_OP		0x00
+#define MV88E6XXX_TCAM_OP_BUSY		0x8000
+#define MV88E6XXX_TCAM_OP_OP_MASK	0x7000
+#define MV88E6XXX_TCAM_OP_OP_FLUSH_ALL  0x1000
+#define MV88E6XXX_TCAM_OP_OP_FLUSH      0x2000
+#define MV88E6XXX_TCAM_OP_OP_LOAD       0x3000
+#define MV88E6XXX_TCAM_OP_OP_GET_NEXT   0x4000
+#define MV88E6XXX_TCAM_OP_OP_READ       0x5000
+
+/* TCAM keys register 1 */
+#define MV88E6XXX_KEYS1			0x02
+#define MV88E6XXX_KEYS1_FT_MASK		0xC000
+#define MV88E6XXX_KEYS1_SPV_MASK	0x0007
+
+/* TCAM keys register 1 */
+#define MV88E6XXX_KEYS2			0x03
+#define MV88E6XXX_KEYS2_SPV_MASK	0x00ff
+
+#define MV88E6XXX_ING_ACT3		0x04
+#define MV88E6XXX_ING_ACT3_SF		0x0800
+#define MV88E6XXX_ING_ACT3_DPV_MASK	0x07ff
+
+#define MV88E6XXX_ING_ACT5			0x06
+#define MV88E6XXX_ING_ACT5_DPV_MODE_MASK	0xc000
+
+static int mv88e6xxx_tcam_write(struct mv88e6xxx_chip *chip, int reg, u16 val)
+{
+	return mv88e6xxx_write(chip, chip->info->ops->tcam_ops->dev_addr, reg, val);
+}
+
+static int mv88e6xxx_tcam_wait(struct mv88e6xxx_chip *chip)
+{
+	int bit = __bf_shf(MV88E6XXX_TCAM_OP_BUSY);
+
+	return mv88e6xxx_wait_bit(chip, chip->info->ops->tcam_ops->dev_addr,
+				  MV88E6XXX_TCAM_OP, bit, 0);
+}
+
+static int mv88e6xxx_tcam_read_page(struct mv88e6xxx_chip *chip, u8 page, u8 entry)
+{
+	u16 val = MV88E6XXX_TCAM_OP_BUSY | MV88E6XXX_TCAM_OP_OP_READ | (page & 0x3) << 10 | entry;
+	int rc;
+
+	rc = mv88e6xxx_tcam_write(chip, MV88E6XXX_TCAM_OP, val);
+	if (rc)
+		return rc;
+
+	return mv88e6xxx_tcam_wait(chip);
+}
+
+static int mv88e6xxx_tcam_load_page(struct mv88e6xxx_chip *chip, u8 page, u8 entry)
+{
+	u16 val = MV88E6XXX_TCAM_OP_BUSY | MV88E6XXX_TCAM_OP_OP_LOAD | (page & 0x3) << 10 | entry;
+	int rc;
+
+	rc = mv88e6xxx_tcam_write(chip, MV88E6XXX_TCAM_OP, val);
+	if (rc)
+		return rc;
+
+	return mv88e6xxx_tcam_wait(chip);
+}
+
+static int mv88e6xxx_tcam_flush_entry(struct mv88e6xxx_chip *chip, u8 entry)
+{
+	u16 val = MV88E6XXX_TCAM_OP_BUSY | MV88E6XXX_TCAM_OP_OP_FLUSH | entry;
+	int rc;
+
+	rc = mv88e6xxx_tcam_write(chip, MV88E6XXX_TCAM_OP, val);
+	if (rc)
+		return rc;
+
+	return mv88e6xxx_tcam_wait(chip);
+}
+
+static int mv88e6xxx_tcam_flush_all(struct mv88e6xxx_chip *chip)
+{
+	u16 val = MV88E6XXX_TCAM_OP_BUSY | MV88E6XXX_TCAM_OP_OP_FLUSH_ALL;
+	int rc;
+
+	rc = mv88e6xxx_tcam_write(chip, MV88E6XXX_TCAM_OP, val);
+	if (rc)
+		return rc;
+
+	return mv88e6xxx_tcam_wait(chip);
+}
+
+struct mv88e6xxx_tcam_entry *mv88e6xxx_tcam_entry_find(struct mv88e6xxx_chip *chip,
+						       unsigned long cookie)
+{
+	struct mv88e6xxx_tcam_entry *entry;
+
+	list_for_each_entry(entry, &chip->tcam.entries, list)
+		if (entry->cookie == cookie)
+			return entry;
+
+	return NULL;
+}
+
+/* insert tcame ntry in ordered list and move existing entries if necessary */
+static int mv88e6xxx_tcam_insert_entry(struct mv88e6xxx_chip *chip,
+				       struct mv88e6xxx_tcam_entry *entry)
+{
+	struct mv88e6xxx_tcam_entry *elem;
+	struct list_head *hpos;
+	int rc;
+
+	list_for_each_prev(hpos, &chip->tcam.entries) {
+		elem = list_entry(hpos, struct mv88e6xxx_tcam_entry, list);
+		if (entry->prio >= elem->prio)
+			break;
+
+		u8 move_idx = elem->hw_idx + 1;
+
+		mv88e6xxx_reg_lock(chip);
+		rc = mv88e6xxx_tcam_flush_entry(chip, move_idx);
+		mv88e6xxx_reg_unlock(chip);
+		if (rc)
+			return rc;
+		mv88e6xxx_reg_lock(chip);
+		rc = chip->info->ops->tcam_ops->entry_add(chip, elem, move_idx);
+		mv88e6xxx_reg_unlock(chip);
+		if (rc)
+			return rc;
+
+		elem->hw_idx = move_idx;
+	}
+
+	if (list_is_head(hpos, &chip->tcam.entries)) {
+		entry->hw_idx = 0;
+	} else {
+		elem = list_entry(hpos, struct mv88e6xxx_tcam_entry, list);
+		entry->hw_idx = elem->hw_idx + 1;
+	}
+	list_add(&entry->list, hpos);
+	return 0;
+}
+
+int mv88e6xxx_tcam_entry_add(struct mv88e6xxx_chip *chip, struct mv88e6xxx_tcam_entry *entry)
+{
+	int rc;
+
+	rc = mv88e6xxx_tcam_insert_entry(chip, entry);
+	if (rc)
+		return rc;
+
+	mv88e6xxx_reg_lock(chip);
+	rc = mv88e6xxx_tcam_flush_entry(chip, entry->hw_idx);
+	mv88e6xxx_reg_unlock(chip);
+	if (rc)
+		goto unlink_out;
+	mv88e6xxx_reg_lock(chip);
+	rc = chip->info->ops->tcam_ops->entry_add(chip, entry, entry->hw_idx);
+	mv88e6xxx_reg_unlock(chip);
+	if (rc)
+		goto unlink_out;
+
+	return 0;
+
+unlink_out:
+	list_del(&entry->list);
+	return rc;
+}
+
+int mv88e6xxx_tcam_entry_del(struct mv88e6xxx_chip *chip, struct mv88e6xxx_tcam_entry *entry)
+{
+	struct mv88e6xxx_tcam_entry *elem = entry;
+	int rc;
+	u8 move_idx = entry->hw_idx;
+
+	mv88e6xxx_reg_lock(chip);
+	rc = mv88e6xxx_tcam_flush_entry(chip, entry->hw_idx);
+	mv88e6xxx_reg_unlock(chip);
+
+	/* move entries that come after the deleted entry forward */
+	list_for_each_entry_continue(elem, &chip->tcam.entries, list) {
+		u8 tmp_idx = elem->hw_idx;
+
+		mv88e6xxx_reg_lock(chip);
+		rc = chip->info->ops->tcam_ops->entry_add(chip, elem, move_idx);
+		mv88e6xxx_reg_unlock(chip);
+
+		elem->hw_idx =  move_idx;
+		move_idx = tmp_idx;
+
+		/* flush the last entry after moving entries */
+		if (list_is_last(&elem->list, &chip->tcam.entries)) {
+			mv88e6xxx_reg_lock(chip);
+			rc = mv88e6xxx_tcam_flush_entry(chip, tmp_idx);
+			mv88e6xxx_reg_unlock(chip);
+		}
+	}
+
+	list_del(&entry->list);
+	return rc;
+}
+
+static int mv88e6390_tcam_entry_add(struct mv88e6xxx_chip *chip,
+				    struct mv88e6xxx_tcam_entry *entry, u8 idx)
+{
+	int i;
+	int err = 0;
+
+	err = mv88e6xxx_tcam_read_page(chip, 2, idx);
+	if (err)
+		return err;
+	if (entry->action.dpv_mode != 0) {
+		u16 val = MV88E6XXX_ING_ACT3_SF | (entry->action.dpv & MV88E6XXX_ING_ACT3_DPV_MASK);
+
+		err = mv88e6xxx_tcam_write(chip, MV88E6XXX_ING_ACT3, val);
+		if (err)
+			return err;
+		val = entry->action.dpv_mode << 14;
+		err = mv88e6xxx_tcam_write(chip, MV88E6XXX_ING_ACT5, val);
+		if (err)
+			return err;
+	}
+	err = mv88e6xxx_tcam_load_page(chip, 2, idx);
+	if (err)
+		return err;
+
+	err = mv88e6xxx_tcam_read_page(chip, 1, idx);
+	if (err)
+		return err;
+
+	for (i = PAGE0_MATCH_SIZE; i < PAGE0_MATCH_SIZE + PAGE1_MATCH_SIZE; i++) {
+		if (entry->key.frame_mask[i]) {
+			u16 val = entry->key.frame_mask[i] << 8 | entry->key.frame_data[i];
+
+			err = mv88e6xxx_tcam_write(chip, i - PAGE0_MATCH_SIZE + 2, val);
+			if (err)
+				return err;
+		}
+	}
+	err = mv88e6xxx_tcam_load_page(chip, 1, idx);
+	if (err)
+		return err;
+
+	err = mv88e6xxx_tcam_read_page(chip, 0, idx);
+	if (err)
+		return err;
+	for (i = 0; i < PAGE0_MATCH_SIZE; i++) {
+		if (entry->key.frame_mask[i]) {
+			u16 val = entry->key.frame_mask[i] << 8 | entry->key.frame_data[i];
+
+			err = mv88e6xxx_tcam_write(chip, i + 6, val);
+			if (err)
+				return err;
+		}
+	}
+	u16 spv_mask = entry->key.spv_mask & mv88e6xxx_port_mask(chip);
+	u16 spv = entry->key.spv & mv88e6xxx_port_mask(chip);
+	// frame type mask bits must be set for a valid entry
+	err = mv88e6xxx_tcam_write(chip, MV88E6XXX_KEYS1,
+				   MV88E6XXX_KEYS1_FT_MASK | (spv_mask & 0x0700) | (spv >> 8));
+	if (err)
+		return err;
+
+	err = mv88e6xxx_tcam_write(chip, MV88E6XXX_KEYS2,
+				   (spv_mask << 8) | (spv & 0x00ff));
+	if (err)
+		return err;
+	err = mv88e6xxx_tcam_load_page(chip, 0, idx);
+	if (err)
+		return err;
+
+	entry->hw_idx = idx;
+	return 0;
+}
+
+const struct mv88e6xxx_tcam_ops mv88e6390_tcam_ops = {
+	.entry_add = mv88e6390_tcam_entry_add,
+	.flush_tcam = mv88e6xxx_tcam_flush_all,
+	.dev_addr = 0x1f,
+};
diff --git a/drivers/net/dsa/mv88e6xxx/tcam.h b/drivers/net/dsa/mv88e6xxx/tcam.h
new file mode 100644
index 000000000000..60ffb798e3af
--- /dev/null
+++ b/drivers/net/dsa/mv88e6xxx/tcam.h
@@ -0,0 +1,37 @@
+/* SPDX-License-Identifier: GPL-2.0-or-later */
+
+/*
+ * Copyright (c) 2026 Luminex Network Intelligence
+ */
+#ifndef _MV88E6XXX_TCAM_H_
+#define _MV88E6XXX_TCAM_H_
+
+#define PAGE0_MATCH_SIZE 22
+#define PAGE1_MATCH_SIZE 26
+
+#define DPV_MODE_NOP		0x0
+#define DPV_MODE_AND		0x1
+#define DPV_MODE_OR		0x2
+#define DPV_MODE_REPLACE	0x3
+
+int mv88e6xxx_tcam_entry_add(struct mv88e6xxx_chip *chip, struct mv88e6xxx_tcam_entry *entry);
+int mv88e6xxx_tcam_entry_del(struct mv88e6xxx_chip *chip, struct mv88e6xxx_tcam_entry *entry);
+struct mv88e6xxx_tcam_entry *mv88e6xxx_tcam_entry_find(struct mv88e6xxx_chip *chip,
+						       unsigned long cookie);
+#define mv88e6xxx_tcam_match_set(key, _offset, data, mask) \
+	do { \
+		typeof(_offset) (offset) = (_offset); \
+		BUILD_BUG_ON((offset) + sizeof((data)) > TCAM_MATCH_SIZE); \
+		__mv88e6xxx_tcam_match_set(key, offset, sizeof(data), \
+					   (u8 *)&(data), (u8 *)&(mask)); \
+	} while (0)
+
+static inline void __mv88e6xxx_tcam_match_set(struct mv88e6xxx_tcam_key *key, unsigned int offset,
+					      size_t size, u8 *data, u8 *mask)
+{
+	memcpy(&key->frame_data[offset], data, size);
+	memcpy(&key->frame_mask[offset], mask, size);
+}
+
+extern const struct mv88e6xxx_tcam_ops mv88e6390_tcam_ops;
+#endif
diff --git a/drivers/net/dsa/mv88e6xxx/tcflower.c b/drivers/net/dsa/mv88e6xxx/tcflower.c
new file mode 100644
index 000000000000..4e0cc65759ef
--- /dev/null
+++ b/drivers/net/dsa/mv88e6xxx/tcflower.c
@@ -0,0 +1,138 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Marvell 88E6xxx Switch flower support
+ *
+ * Copyright (c) 2026 Luminex Network Intelligence
+ */
+
+#include "chip.h"
+#include "tcflower.h"
+#include "tcam.h"
+
+static int mv88e6xx_flower_parse_key(struct mv88e6xxx_chip *chip,
+				     struct netlink_ext_ack *extack,
+				     struct flow_cls_offload *cls,
+				     struct mv88e6xxx_tcam_key *key)
+{
+	struct flow_rule *rule = flow_cls_offload_flow_rule(cls);
+	struct flow_dissector *dissector = rule->match.dissector;
+	u16 addr_type = 0;
+
+	if (dissector->used_keys &
+	    ~(BIT_ULL(FLOW_DISSECTOR_KEY_BASIC) |
+	      BIT_ULL(FLOW_DISSECTOR_KEY_CONTROL) |
+	      BIT_ULL(FLOW_DISSECTOR_KEY_IPV4_ADDRS) |
+	      BIT_ULL(FLOW_DISSECTOR_KEY_IPV6_ADDRS))) {
+		NL_SET_ERR_MSG_MOD(extack,
+				   "Unsupported keys used");
+		dev_warn(chip->dev, "used_keys: 0x%llx", dissector->used_keys);
+		return -EOPNOTSUPP;
+	}
+
+	if (flow_rule_match_key(rule, FLOW_DISSECTOR_KEY_CONTROL)) {
+		struct flow_match_control match;
+
+		flow_rule_match_control(rule, &match);
+		addr_type = match.key->addr_type;
+
+		if (flow_rule_has_control_flags(match.mask->flags,
+						cls->common.extack))
+			return -EOPNOTSUPP;
+	}
+	if (flow_rule_match_key(rule, FLOW_DISSECTOR_KEY_BASIC)) {
+		struct flow_match_basic match;
+
+		flow_rule_match_basic(rule, &match);
+		// ethertype
+		mv88e6xxx_tcam_match_set(key, 16, match.key->n_proto, match.mask->n_proto);
+		mv88e6xxx_tcam_match_set(key, 27, match.key->ip_proto, match.mask->ip_proto);
+	}
+
+	if (addr_type == FLOW_DISSECTOR_KEY_IPV4_ADDRS) {
+		struct flow_match_ipv4_addrs match;
+
+		flow_rule_match_ipv4_addrs(cls->rule, &match);
+		mv88e6xxx_tcam_match_set(key, 30, match.key->src, match.mask->src);
+		mv88e6xxx_tcam_match_set(key, 34, match.key->dst, match.mask->dst);
+	}
+
+	return 0;
+}
+
+int mv88e6xxx_cls_flower_add(struct dsa_switch *ds, int port,
+			     struct flow_cls_offload *cls, bool ingress)
+{
+	struct mv88e6xxx_chip *chip = ds->priv;
+	struct flow_rule *rule = flow_cls_offload_flow_rule(cls);
+	struct netlink_ext_ack *extack = cls->common.extack;
+	unsigned long cookie = cls->cookie;
+	const struct flow_action_entry *act;
+	struct mv88e6xxx_tcam_key key = { 0 };
+	struct mv88e6xxx_tcam_entry *entry;
+	int rc, i;
+
+	if (!mv88e6xxx_has_tcam(chip)) {
+		NL_SET_ERR_MSG_MOD(extack, "hardware offload not supported");
+		return -EOPNOTSUPP;
+	}
+
+	rc = mv88e6xx_flower_parse_key(chip, extack, cls, &key);
+	if (rc)
+		return rc;
+
+	entry = mv88e6xxx_tcam_entry_find(chip, cookie);
+	if (entry)
+		return -EEXIST;
+
+	entry = kzalloc(sizeof(*entry), GFP_KERNEL);
+	if (!entry)
+		return -ENOMEM;
+
+	entry->cookie = cookie;
+	entry->prio = cls->common.prio;
+	entry->key = key;
+
+	flow_action_for_each(i, act, &rule->action) {
+		switch (act->id) {
+		case FLOW_ACTION_TRAP: {
+			int cpu = dsa_upstream_port(ds, port);
+
+			entry->action.dpv_mode = DPV_MODE_REPLACE;
+			entry->action.dpv = BIT(cpu);
+			break;
+		}
+		default: {
+			NL_SET_ERR_MSG_MOD(extack, "action not supported");
+			rc = -EOPNOTSUPP;
+			goto err_free_entry;
+		}
+		}
+	}
+
+	entry->key.spv = BIT(port);
+	entry->key.spv_mask = mv88e6xxx_port_mask(chip);
+
+	rc = mv88e6xxx_tcam_entry_add(chip, entry);
+	if (rc)
+		goto err_free_entry;
+
+	return  0;
+
+err_free_entry:
+	kfree(entry);
+	return rc;
+}
+
+int mv88e6xxx_cls_flower_del(struct dsa_switch *ds, int port,
+			     struct flow_cls_offload *cls, bool ingress)
+{
+	struct mv88e6xxx_chip *chip = ds->priv;
+	struct mv88e6xxx_tcam_entry *entry = mv88e6xxx_tcam_entry_find(chip, cls->cookie);
+	int rc = 0;
+
+	if (entry) {
+		rc = mv88e6xxx_tcam_entry_del(chip, entry);
+		kfree(entry);
+	}
+	return  rc;
+}
diff --git a/drivers/net/dsa/mv88e6xxx/tcflower.h b/drivers/net/dsa/mv88e6xxx/tcflower.h
new file mode 100644
index 000000000000..96bb8da80bec
--- /dev/null
+++ b/drivers/net/dsa/mv88e6xxx/tcflower.h
@@ -0,0 +1,13 @@
+/* SPDX-License-Identifier: GPL-2.0-or-later */
+
+/*
+ * Copyright (c) 2026 Luminex Network Intelligence
+ */
+#ifndef _MV88E6XXX_TCFLOWER_H_
+#define _MV88E6XXX_TCFLOWER_H_
+
+int mv88e6xxx_cls_flower_add(struct dsa_switch *ds, int port,
+			     struct flow_cls_offload *cls, bool ingress);
+int mv88e6xxx_cls_flower_del(struct dsa_switch *ds, int port,
+			     struct flow_cls_offload *cls, bool ingress);
+#endif

---
base-commit: cd51b40495c09b92beea6893663b3d0ed7605e81
change-id: 20260213-net-next-mv88e6xxx-tcam-f65be16008fb

Best regards,
-- 
Cedric Jehasse <cedric.jehasse@luminex.be>

