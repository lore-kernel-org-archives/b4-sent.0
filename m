From: Cedric Jehasse <cedric.jehasse@luminex.be>
Date: Thu, 04 Jun 2026 10:30:15 +0200
Subject: [PATCH net-next 2/2] net: dsa: mv88e6xxx: add support for dcb pcp
 app
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260604-net-next-mv88e6xxx-pcp-prio-v1-2-f9d10fe6cdc8@luminex.be>
References: <20260604-net-next-mv88e6xxx-pcp-prio-v1-0-f9d10fe6cdc8@luminex.be>
In-Reply-To: <20260604-net-next-mv88e6xxx-pcp-prio-v1-0-f9d10fe6cdc8@luminex.be>
To: Andrew Lunn <andrew@lunn.ch>, Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Russell King <linux@armlinux.org.uk>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Luke Howard <lukeh@padl.com>, Cedric Jehasse <cedric.jehasse@gmail.com>, 
 Cedric Jehasse <cedric.jehasse@luminex.be>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780561819; l=23190;
 i=cedric.jehasse@luminex.be; s=20260213; h=from:subject:message-id;
 bh=vbq/xR+1aOCJGVhsg0S57sI1gN3M56tEOWeAmq/+PXE=;
 b=WEZ6Ra5o/OBIiNAFfp2GHUVRQ2Ep4OTq2KnvwVW39N5ssn/h+O//g1EnV9OM00OKX1bCLipX7
 sY66cle5IE2ABXkgt0iaN/iinD+qDPPIcrwLVv6uPJnbvTe8bg217WU
X-Developer-Key: i=cedric.jehasse@luminex.be; a=ed25519;
 pk=DL2RaHc2bc7tTDTMJdugm42BtJk4Ip+7V41Gkj+Avjk=
X-Endpoint-Received: by B4 Relay for cedric.jehasse@luminex.be/20260213 with auth_id=638
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement the DSA pcp_prio hooks to support the dcb pcp app.
In the Marvell switches this is done by configuring the IEEE PRI Mapping
table. There are different hardware implementations of this table
depending on the switch:
* a global table
* the 6390 has one table per port
* the 6393 has one table for DEI=0, and another table for DEI=1 per port

Example command:
dcb app replace dev p1 pcp-prio 7nd:3

Signed-off-by: Cedric Jehasse <cedric.jehasse@luminex.be>
---
 drivers/net/dsa/mv88e6xxx/Makefile |   1 +
 drivers/net/dsa/mv88e6xxx/chip.c   |  36 ++++++
 drivers/net/dsa/mv88e6xxx/chip.h   |  17 +++
 drivers/net/dsa/mv88e6xxx/dcb.c    | 229 +++++++++++++++++++++++++++++++++++++
 drivers/net/dsa/mv88e6xxx/dcb.h    |  21 ++++
 drivers/net/dsa/mv88e6xxx/port.c   |  28 ++++-
 drivers/net/dsa/mv88e6xxx/port.h   |   8 ++
 7 files changed, 338 insertions(+), 2 deletions(-)

diff --git a/drivers/net/dsa/mv88e6xxx/Makefile b/drivers/net/dsa/mv88e6xxx/Makefile
index b0b08c6f159c..6eb9be4d934a 100644
--- a/drivers/net/dsa/mv88e6xxx/Makefile
+++ b/drivers/net/dsa/mv88e6xxx/Makefile
@@ -1,6 +1,7 @@
 # SPDX-License-Identifier: GPL-2.0
 obj-$(CONFIG_NET_DSA_MV88E6XXX) += mv88e6xxx.o
 mv88e6xxx-objs := chip.o
+mv88e6xxx-objs += dcb.o
 mv88e6xxx-objs += devlink.o
 mv88e6xxx-objs += global1.o
 mv88e6xxx-objs += global1_atu.o
diff --git a/drivers/net/dsa/mv88e6xxx/chip.c b/drivers/net/dsa/mv88e6xxx/chip.c
index 5bbf5e69de9a..e12b84e42a93 100644
--- a/drivers/net/dsa/mv88e6xxx/chip.c
+++ b/drivers/net/dsa/mv88e6xxx/chip.c
@@ -35,6 +35,7 @@
 #include <net/pkt_sched.h>
 
 #include "chip.h"
+#include "dcb.h"
 #include "devlink.h"
 #include "global1.h"
 #include "global2.h"
@@ -4258,6 +4259,7 @@ static const struct mv88e6xxx_ops mv88e6085_ops = {
 	.stu_loadpurge = mv88e6352_g1_stu_loadpurge,
 	.phylink_get_caps = mv88e6185_phylink_get_caps,
 	.set_max_frame_size = mv88e6185_g1_set_max_frame_size,
+	.dcb_ops = &mv88e6352_dcb_ops,
 };
 
 static const struct mv88e6xxx_ops mv88e6095_ops = {
@@ -4290,6 +4292,7 @@ static const struct mv88e6xxx_ops mv88e6095_ops = {
 	.phylink_get_caps = mv88e6095_phylink_get_caps,
 	.pcs_ops = &mv88e6185_pcs_ops,
 	.set_max_frame_size = mv88e6185_g1_set_max_frame_size,
+	.dcb_ops = &mv88e6352_dcb_ops,
 };
 
 static const struct mv88e6xxx_ops mv88e6097_ops = {
@@ -4337,6 +4340,7 @@ static const struct mv88e6xxx_ops mv88e6097_ops = {
 	.stu_getnext = mv88e6352_g1_stu_getnext,
 	.stu_loadpurge = mv88e6352_g1_stu_loadpurge,
 	.set_max_frame_size = mv88e6185_g1_set_max_frame_size,
+	.dcb_ops = &mv88e6352_dcb_ops,
 };
 
 static const struct mv88e6xxx_ops mv88e6123_ops = {
@@ -4378,6 +4382,7 @@ static const struct mv88e6xxx_ops mv88e6123_ops = {
 	.stu_loadpurge = mv88e6352_g1_stu_loadpurge,
 	.phylink_get_caps = mv88e6185_phylink_get_caps,
 	.set_max_frame_size = mv88e6185_g1_set_max_frame_size,
+	.dcb_ops = &mv88e6352_dcb_ops,
 };
 
 static const struct mv88e6xxx_ops mv88e6131_ops = {
@@ -4418,6 +4423,7 @@ static const struct mv88e6xxx_ops mv88e6131_ops = {
 	.vtu_getnext = mv88e6185_g1_vtu_getnext,
 	.vtu_loadpurge = mv88e6185_g1_vtu_loadpurge,
 	.phylink_get_caps = mv88e6185_phylink_get_caps,
+	.dcb_ops = &mv88e6352_dcb_ops,
 };
 
 static const struct mv88e6xxx_ops mv88e6141_ops = {
@@ -4481,6 +4487,7 @@ static const struct mv88e6xxx_ops mv88e6141_ops = {
 	.serdes_get_regs = mv88e6390_serdes_get_regs,
 	.phylink_get_caps = mv88e6341_phylink_get_caps,
 	.pcs_ops = &mv88e6390_pcs_ops,
+	.dcb_ops = &mv88e6352_dcb_ops,
 };
 
 static const struct mv88e6xxx_ops mv88e6161_ops = {
@@ -4529,6 +4536,7 @@ static const struct mv88e6xxx_ops mv88e6161_ops = {
 	.ptp_ops = &mv88e6165_ptp_ops,
 	.phylink_get_caps = mv88e6185_phylink_get_caps,
 	.set_max_frame_size = mv88e6185_g1_set_max_frame_size,
+	.dcb_ops = &mv88e6352_dcb_ops,
 };
 
 static const struct mv88e6xxx_ops mv88e6165_ops = {
@@ -4566,6 +4574,7 @@ static const struct mv88e6xxx_ops mv88e6165_ops = {
 	.avb_ops = &mv88e6165_avb_ops,
 	.ptp_ops = &mv88e6165_ptp_ops,
 	.phylink_get_caps = mv88e6185_phylink_get_caps,
+	.dcb_ops = &mv88e6352_dcb_ops,
 };
 
 static const struct mv88e6xxx_ops mv88e6171_ops = {
@@ -4612,6 +4621,7 @@ static const struct mv88e6xxx_ops mv88e6171_ops = {
 	.stu_getnext = mv88e6352_g1_stu_getnext,
 	.stu_loadpurge = mv88e6352_g1_stu_loadpurge,
 	.phylink_get_caps = mv88e6351_phylink_get_caps,
+	.dcb_ops = &mv88e6352_dcb_ops,
 };
 
 static const struct mv88e6xxx_ops mv88e6172_ops = {
@@ -4669,6 +4679,7 @@ static const struct mv88e6xxx_ops mv88e6172_ops = {
 	.gpio_ops = &mv88e6352_gpio_ops,
 	.phylink_get_caps = mv88e6352_phylink_get_caps,
 	.pcs_ops = &mv88e6352_pcs_ops,
+	.dcb_ops = &mv88e6352_dcb_ops,
 };
 
 static const struct mv88e6xxx_ops mv88e6175_ops = {
@@ -4715,6 +4726,7 @@ static const struct mv88e6xxx_ops mv88e6175_ops = {
 	.stu_getnext = mv88e6352_g1_stu_getnext,
 	.stu_loadpurge = mv88e6352_g1_stu_loadpurge,
 	.phylink_get_caps = mv88e6351_phylink_get_caps,
+	.dcb_ops = &mv88e6352_dcb_ops,
 };
 
 static const struct mv88e6xxx_ops mv88e6176_ops = {
@@ -4773,6 +4785,7 @@ static const struct mv88e6xxx_ops mv88e6176_ops = {
 	.gpio_ops = &mv88e6352_gpio_ops,
 	.phylink_get_caps = mv88e6352_phylink_get_caps,
 	.pcs_ops = &mv88e6352_pcs_ops,
+	.dcb_ops = &mv88e6352_dcb_ops,
 };
 
 static const struct mv88e6xxx_ops mv88e6185_ops = {
@@ -4811,6 +4824,7 @@ static const struct mv88e6xxx_ops mv88e6185_ops = {
 	.phylink_get_caps = mv88e6185_phylink_get_caps,
 	.pcs_ops = &mv88e6185_pcs_ops,
 	.set_max_frame_size = mv88e6185_g1_set_max_frame_size,
+	.dcb_ops = &mv88e6352_dcb_ops,
 };
 
 static const struct mv88e6xxx_ops mv88e6190_ops = {
@@ -4830,6 +4844,7 @@ static const struct mv88e6xxx_ops mv88e6190_ops = {
 	.port_set_speed_duplex = mv88e6390_port_set_speed_duplex,
 	.port_max_speed_mode = mv88e6390_port_max_speed_mode,
 	.port_tag_remap = mv88e6390_port_tag_remap,
+	.dcb_ops = &mv88e6390_dcb_ops,
 	.port_set_policy = mv88e6352_port_set_policy,
 	.port_set_frame_mode = mv88e6351_port_set_frame_mode,
 	.port_set_ucast_flood = mv88e6352_port_set_ucast_flood,
@@ -4931,6 +4946,7 @@ static const struct mv88e6xxx_ops mv88e6190x_ops = {
 	.gpio_ops = &mv88e6352_gpio_ops,
 	.phylink_get_caps = mv88e6390x_phylink_get_caps,
 	.pcs_ops = &mv88e6390_pcs_ops,
+	.dcb_ops = &mv88e6390_dcb_ops,
 };
 
 static const struct mv88e6xxx_ops mv88e6191_ops = {
@@ -4990,6 +5006,7 @@ static const struct mv88e6xxx_ops mv88e6191_ops = {
 	.ptp_ops = &mv88e6352_ptp_ops,
 	.phylink_get_caps = mv88e6390_phylink_get_caps,
 	.pcs_ops = &mv88e6390_pcs_ops,
+	.dcb_ops = &mv88e6390_dcb_ops,
 };
 
 static const struct mv88e6xxx_ops mv88e6240_ops = {
@@ -5051,6 +5068,7 @@ static const struct mv88e6xxx_ops mv88e6240_ops = {
 	.ptp_ops = &mv88e6352_ptp_ops,
 	.phylink_get_caps = mv88e6352_phylink_get_caps,
 	.pcs_ops = &mv88e6352_pcs_ops,
+	.dcb_ops = &mv88e6352_dcb_ops,
 };
 
 static const struct mv88e6xxx_ops mv88e6250_ops = {
@@ -5096,6 +5114,7 @@ static const struct mv88e6xxx_ops mv88e6250_ops = {
 	.ptp_ops = &mv88e6352_ptp_ops,
 	.phylink_get_caps = mv88e6250_phylink_get_caps,
 	.set_max_frame_size = mv88e6185_g1_set_max_frame_size,
+	.dcb_ops = &mv88e6352_dcb_ops,
 };
 
 static const struct mv88e6xxx_ops mv88e6290_ops = {
@@ -5158,6 +5177,7 @@ static const struct mv88e6xxx_ops mv88e6290_ops = {
 	.phylink_get_caps = mv88e6390_phylink_get_caps,
 	.pcs_ops = &mv88e6390_pcs_ops,
 	.tcam_ops = &mv88e6390_tcam_ops,
+	.dcb_ops = &mv88e6390_dcb_ops,
 };
 
 static const struct mv88e6xxx_ops mv88e6320_ops = {
@@ -5211,6 +5231,7 @@ static const struct mv88e6xxx_ops mv88e6320_ops = {
 	.avb_ops = &mv88e6352_avb_ops,
 	.ptp_ops = &mv88e6352_ptp_ops,
 	.phylink_get_caps = mv88e632x_phylink_get_caps,
+	.dcb_ops = &mv88e6352_dcb_ops,
 };
 
 static const struct mv88e6xxx_ops mv88e6321_ops = {
@@ -5263,6 +5284,7 @@ static const struct mv88e6xxx_ops mv88e6321_ops = {
 	.avb_ops = &mv88e6352_avb_ops,
 	.ptp_ops = &mv88e6352_ptp_ops,
 	.phylink_get_caps = mv88e632x_phylink_get_caps,
+	.dcb_ops = &mv88e6352_dcb_ops,
 };
 
 static const struct mv88e6xxx_ops mv88e6341_ops = {
@@ -5329,6 +5351,7 @@ static const struct mv88e6xxx_ops mv88e6341_ops = {
 	.serdes_get_regs = mv88e6390_serdes_get_regs,
 	.phylink_get_caps = mv88e6341_phylink_get_caps,
 	.pcs_ops = &mv88e6390_pcs_ops,
+	.dcb_ops = &mv88e6352_dcb_ops,
 };
 
 static const struct mv88e6xxx_ops mv88e6350_ops = {
@@ -5375,6 +5398,7 @@ static const struct mv88e6xxx_ops mv88e6350_ops = {
 	.stu_getnext = mv88e6352_g1_stu_getnext,
 	.stu_loadpurge = mv88e6352_g1_stu_loadpurge,
 	.phylink_get_caps = mv88e6351_phylink_get_caps,
+	.dcb_ops = &mv88e6352_dcb_ops,
 };
 
 static const struct mv88e6xxx_ops mv88e6351_ops = {
@@ -5423,6 +5447,7 @@ static const struct mv88e6xxx_ops mv88e6351_ops = {
 	.avb_ops = &mv88e6352_avb_ops,
 	.ptp_ops = &mv88e6352_ptp_ops,
 	.phylink_get_caps = mv88e6351_phylink_get_caps,
+	.dcb_ops = &mv88e6352_dcb_ops,
 };
 
 static const struct mv88e6xxx_ops mv88e6352_ops = {
@@ -5487,6 +5512,7 @@ static const struct mv88e6xxx_ops mv88e6352_ops = {
 	.serdes_get_regs = mv88e6352_serdes_get_regs,
 	.phylink_get_caps = mv88e6352_phylink_get_caps,
 	.pcs_ops = &mv88e6352_pcs_ops,
+	.dcb_ops = &mv88e6352_dcb_ops,
 };
 
 static const struct mv88e6xxx_ops mv88e6390_ops = {
@@ -5553,6 +5579,7 @@ static const struct mv88e6xxx_ops mv88e6390_ops = {
 	.phylink_get_caps = mv88e6390_phylink_get_caps,
 	.pcs_ops = &mv88e6390_pcs_ops,
 	.tcam_ops = &mv88e6390_tcam_ops,
+	.dcb_ops = &mv88e6390_dcb_ops,
 };
 
 static const struct mv88e6xxx_ops mv88e6390x_ops = {
@@ -5618,6 +5645,7 @@ static const struct mv88e6xxx_ops mv88e6390x_ops = {
 	.ptp_ops = &mv88e6390_ptp_ops,
 	.phylink_get_caps = mv88e6390x_phylink_get_caps,
 	.pcs_ops = &mv88e6390_pcs_ops,
+	.dcb_ops = &mv88e6390_dcb_ops,
 };
 
 static const struct mv88e6xxx_ops mv88e6393x_ops = {
@@ -5684,6 +5712,7 @@ static const struct mv88e6xxx_ops mv88e6393x_ops = {
 	.phylink_get_caps = mv88e6393x_phylink_get_caps,
 	.pcs_ops = &mv88e6393x_pcs_ops,
 	.tcam_ops = &mv88e6393_tcam_ops,
+	.dcb_ops = &mv88e6393x_dcb_ops,
 };
 
 static const struct mv88e6xxx_qav_info mv88e6352_qav_info = {
@@ -7385,6 +7414,9 @@ static const struct dsa_switch_ops mv88e6xxx_switch_ops = {
 	.port_hwtstamp_get	= mv88e6xxx_port_hwtstamp_get,
 	.port_txtstamp		= mv88e6xxx_port_txtstamp,
 	.port_rxtstamp		= mv88e6xxx_port_rxtstamp,
+	.port_get_pcp_prio	= mv88e6xxx_port_get_pcp_prio,
+	.port_add_pcp_prio	= mv88e6xxx_port_add_pcp_prio,
+	.port_del_pcp_prio	= mv88e6xxx_port_del_pcp_prio,
 	.port_setup_tc		= mv88e6xxx_port_setup_tc,
 	.cls_flower_add		= mv88e6xxx_cls_flower_add,
 	.cls_flower_del         = mv88e6xxx_cls_flower_del,
@@ -7402,6 +7434,7 @@ static const struct dsa_switch_ops mv88e6xxx_switch_ops = {
 
 static int mv88e6xxx_register_switch(struct mv88e6xxx_chip *chip)
 {
+	const struct mv88e6xxx_dcb_ops *dcb_ops = chip->info->ops->dcb_ops;
 	struct device *dev = chip->dev;
 	struct dsa_switch *ds;
 
@@ -7418,6 +7451,9 @@ static int mv88e6xxx_register_switch(struct mv88e6xxx_chip *chip)
 	ds->ageing_time_min = chip->info->age_time_coeff;
 	ds->ageing_time_max = chip->info->age_time_coeff * U8_MAX;
 
+	ds->pcp_prio_mapping_is_global = dcb_ops &&
+					 dcb_ops->global_get_pcp_prio;
+
 	/* Some chips support up to 32, but that requires enabling the
 	 * 5-bit port mode, which we do not support. 640k^W16 ought to
 	 * be enough for anyone.
diff --git a/drivers/net/dsa/mv88e6xxx/chip.h b/drivers/net/dsa/mv88e6xxx/chip.h
index e563cfe8ab2a..1aa77b643924 100644
--- a/drivers/net/dsa/mv88e6xxx/chip.h
+++ b/drivers/net/dsa/mv88e6xxx/chip.h
@@ -211,6 +211,7 @@ struct mv88e6xxx_stu_entry {
 };
 
 struct mv88e6xxx_bus_ops;
+struct mv88e6xxx_dcb_ops;
 struct mv88e6xxx_irq_ops;
 struct mv88e6xxx_gpio_ops;
 struct mv88e6xxx_avb_ops;
@@ -728,6 +729,9 @@ struct mv88e6xxx_ops {
 
 	/* Ternary Content Addressable Memory operations */
 	const struct mv88e6xxx_tcam_ops *tcam_ops;
+
+	/* Data Center Bridging operations */
+	const struct mv88e6xxx_dcb_ops *dcb_ops;
 };
 
 struct mv88e6xxx_irq_ops {
@@ -779,6 +783,19 @@ struct mv88e6xxx_avb_ops {
 			      u16 data);
 };
 
+struct mv88e6xxx_dcb_ops {
+	/* Get/set the chip's global PCP to queue priority mapping */
+	int (*global_get_pcp_prio)(struct mv88e6xxx_chip *chip, u8 pcp);
+	int (*global_set_pcp_prio)(struct mv88e6xxx_chip *chip, u8 pcp,
+				   u8 prio);
+
+	/* Get/set a port's PCP to queue priority mapping */
+	int (*port_get_pcp_prio)(struct mv88e6xxx_chip *chip, int port,
+				 u8 pcp);
+	int (*port_set_pcp_prio)(struct mv88e6xxx_chip *chip, int port,
+				 u8 pcp, u8 prio);
+};
+
 struct mv88e6xxx_ptp_ops {
 	u64 (*clock_read)(struct cyclecounter *cc);
 	int (*ptp_enable)(struct ptp_clock_info *ptp,
diff --git a/drivers/net/dsa/mv88e6xxx/dcb.c b/drivers/net/dsa/mv88e6xxx/dcb.c
new file mode 100644
index 000000000000..0a3099cdf388
--- /dev/null
+++ b/drivers/net/dsa/mv88e6xxx/dcb.c
@@ -0,0 +1,229 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+// Copyright (c) 2026 Luminex Network Intelligence
+
+#include "chip.h"
+#include "dcb.h"
+#include "global1.h"
+#include "port.h"
+
+static int mv88e6352_get_pcp_prio(struct mv88e6xxx_chip *chip, u8 pcp)
+{
+	u16 val;
+	int err;
+
+	/* These devices have no mapping table for frames with DEI bit set */
+	if (pcp >= 8)
+		return -EOPNOTSUPP;
+
+	err = mv88e6xxx_g1_read(chip, MV88E6XXX_G1_IEEE_PRI, &val);
+	if (err)
+		return err;
+
+	return (val >> (pcp * 2)) & 3;
+}
+
+static int mv88e6352_set_pcp_prio(struct mv88e6xxx_chip *chip, u8 pcp, u8 prio)
+{
+	u16 val;
+	int err;
+
+	/* These devices have no mapping table for frames with DEI bit set */
+	if (pcp >= 8)
+		return -EOPNOTSUPP;
+
+	if (prio >= 4)
+		return -EINVAL;
+
+	err = mv88e6xxx_g1_read(chip, MV88E6XXX_G1_IEEE_PRI, &val);
+	if (err)
+		return err;
+
+	val &= ~(3 << (pcp * 2));
+	val |= prio << (pcp * 2);
+
+	return mv88e6xxx_g1_write(chip, MV88E6XXX_G1_IEEE_PRI, val);
+}
+
+static int mv88e639x_port_ieeepmt_pcp_entry(u8 pcp, bool has_dei,
+					    u16 *table, u8 *ptr)
+{
+	if (pcp >= 16)
+		return -EINVAL;
+
+	/* not all devices have a table for mapping with DEI bit set */
+	if (pcp >= 8 && !has_dei)
+		return -EOPNOTSUPP;
+
+	*table = pcp >= 8 ?
+		MV88E6393X_PORT_IEEE_PRIO_MAP_TABLE_INGRESS_PCP_DEI :
+		MV88E6390_PORT_IEEE_PRIO_MAP_TABLE_INGRESS_PCP;
+	*ptr = pcp & 7;
+
+	return 0;
+}
+
+static int mv88e639x_port_get_pcp_prio(struct mv88e6xxx_chip *chip, int port,
+				       u8 pcp, bool has_dei)
+{
+	u16 val, table;
+	u8 ptr;
+	int err;
+
+	err = mv88e639x_port_ieeepmt_pcp_entry(pcp, has_dei, &table, &ptr);
+	if (err)
+		return err;
+
+	err = mv88e6xxx_port_ieeepmt_read(chip, port, table, ptr, &val);
+	if (err)
+		return err;
+
+	if (val & MV88E6390_PORT_IEEE_PRIO_MAP_TABLE_QPRI_DIS)
+		return -EOPNOTSUPP;
+
+	return (val & MV88E6390_PORT_IEEE_PRIO_MAP_TABLE_QPRI_MASK)
+		>> MV88E6390_PORT_IEEE_PRIO_MAP_TABLE_QPRI_SHIFT;
+}
+
+static int mv88e639x_port_set_pcp_prio(struct mv88e6xxx_chip *chip, int port,
+				       u8 pcp, u8 prio, bool has_dei)
+{
+	u16 val, table;
+	u8 ptr;
+	int err;
+
+	if (prio >= 8)
+		return -EINVAL;
+
+	err = mv88e639x_port_ieeepmt_pcp_entry(pcp, has_dei, &table, &ptr);
+	if (err)
+		return err;
+
+	err = mv88e6xxx_port_ieeepmt_read(chip, port, table, ptr, &val);
+	if (err)
+		return err;
+
+	val &= ~MV88E6390_PORT_IEEE_PRIO_MAP_TABLE_QPRI_DIS;
+	val &= ~MV88E6390_PORT_IEEE_PRIO_MAP_TABLE_QPRI_MASK;
+	val |= (prio << MV88E6390_PORT_IEEE_PRIO_MAP_TABLE_QPRI_SHIFT) &
+		MV88E6390_PORT_IEEE_PRIO_MAP_TABLE_QPRI_MASK;
+
+	return mv88e6xxx_port_ieeepmt_write(chip, port, table, ptr, val);
+}
+
+static int mv88e6390_port_get_pcp_prio(struct mv88e6xxx_chip *chip, int port,
+				       u8 pcp)
+{
+	return mv88e639x_port_get_pcp_prio(chip, port, pcp, false);
+}
+
+static int mv88e6390_port_set_pcp_prio(struct mv88e6xxx_chip *chip, int port,
+				       u8 pcp, u8 prio)
+{
+	return mv88e639x_port_set_pcp_prio(chip, port, pcp, prio, false);
+}
+
+static int mv88e6393x_port_get_pcp_prio(struct mv88e6xxx_chip *chip, int port,
+					u8 pcp)
+{
+	return mv88e639x_port_get_pcp_prio(chip, port, pcp, true);
+}
+
+static int mv88e6393x_port_set_pcp_prio(struct mv88e6xxx_chip *chip, int port,
+					u8 pcp, u8 prio)
+{
+	return mv88e639x_port_set_pcp_prio(chip, port, pcp, prio, true);
+}
+
+const struct mv88e6xxx_dcb_ops mv88e6352_dcb_ops = {
+	.global_get_pcp_prio = mv88e6352_get_pcp_prio,
+	.global_set_pcp_prio = mv88e6352_set_pcp_prio,
+};
+
+const struct mv88e6xxx_dcb_ops mv88e6390_dcb_ops = {
+	.port_get_pcp_prio = mv88e6390_port_get_pcp_prio,
+	.port_set_pcp_prio = mv88e6390_port_set_pcp_prio,
+};
+
+const struct mv88e6xxx_dcb_ops mv88e6393x_dcb_ops = {
+	.port_get_pcp_prio = mv88e6393x_port_get_pcp_prio,
+	.port_set_pcp_prio = mv88e6393x_port_set_pcp_prio,
+};
+
+static int mv88e6xxx_dcb_get_pcp_prio(struct mv88e6xxx_chip *chip, int port,
+				      u8 pcp)
+{
+	const struct mv88e6xxx_dcb_ops *dcb_ops = chip->info->ops->dcb_ops;
+
+	if (!dcb_ops)
+		return -EOPNOTSUPP;
+
+	if (dcb_ops->port_get_pcp_prio)
+		return dcb_ops->port_get_pcp_prio(chip, port, pcp);
+
+	if (dcb_ops->global_get_pcp_prio)
+		return dcb_ops->global_get_pcp_prio(chip, pcp);
+
+	return -EOPNOTSUPP;
+}
+
+static int mv88e6xxx_dcb_set_pcp_prio(struct mv88e6xxx_chip *chip, int port,
+				      u8 pcp, u8 prio)
+{
+	const struct mv88e6xxx_dcb_ops *dcb_ops = chip->info->ops->dcb_ops;
+
+	if (!dcb_ops)
+		return -EOPNOTSUPP;
+
+	if (dcb_ops->port_set_pcp_prio)
+		return dcb_ops->port_set_pcp_prio(chip, port, pcp, prio);
+
+	if (dcb_ops->global_set_pcp_prio)
+		return dcb_ops->global_set_pcp_prio(chip, pcp, prio);
+
+	return -EOPNOTSUPP;
+}
+
+int mv88e6xxx_port_get_pcp_prio(struct dsa_switch *ds, int port, u8 pcp)
+{
+	struct mv88e6xxx_chip *chip = ds->priv;
+	int err;
+
+	mv88e6xxx_reg_lock(chip);
+	err = mv88e6xxx_dcb_get_pcp_prio(chip, port, pcp);
+	mv88e6xxx_reg_unlock(chip);
+
+	return err;
+}
+
+int mv88e6xxx_port_add_pcp_prio(struct dsa_switch *ds, int port, u8 pcp,
+				u8 prio)
+{
+	struct mv88e6xxx_chip *chip = ds->priv;
+	int err;
+
+	if (prio >= 8)
+		return -EINVAL;
+
+	mv88e6xxx_reg_lock(chip);
+	err = mv88e6xxx_dcb_set_pcp_prio(chip, port, pcp, prio);
+	mv88e6xxx_reg_unlock(chip);
+
+	return err;
+}
+
+int mv88e6xxx_port_del_pcp_prio(struct dsa_switch *ds, int port, u8 pcp,
+				u8 prio)
+{
+	struct mv88e6xxx_chip *chip = ds->priv;
+	int err = 0;
+
+	mv88e6xxx_reg_lock(chip);
+	if (mv88e6xxx_dcb_get_pcp_prio(chip, port, pcp) != prio)
+		goto unlock;
+
+	err = mv88e6xxx_dcb_set_pcp_prio(chip, port, pcp, 0);
+
+unlock:
+	mv88e6xxx_reg_unlock(chip);
+	return err;
+}
diff --git a/drivers/net/dsa/mv88e6xxx/dcb.h b/drivers/net/dsa/mv88e6xxx/dcb.h
new file mode 100644
index 000000000000..7a2124ec23ba
--- /dev/null
+++ b/drivers/net/dsa/mv88e6xxx/dcb.h
@@ -0,0 +1,21 @@
+/* SPDX-License-Identifier: GPL-2.0-or-later
+ *
+ * Marvell 88E6xxx Switch DCB support
+ */
+
+#ifndef _MV88E6XXX_DCB_H_
+#define _MV88E6XXX_DCB_H_
+
+#include "chip.h"
+
+extern const struct mv88e6xxx_dcb_ops mv88e6352_dcb_ops;
+extern const struct mv88e6xxx_dcb_ops mv88e6390_dcb_ops;
+extern const struct mv88e6xxx_dcb_ops mv88e6393x_dcb_ops;
+
+int mv88e6xxx_port_get_pcp_prio(struct dsa_switch *ds, int port, u8 pcp);
+int mv88e6xxx_port_add_pcp_prio(struct dsa_switch *ds, int port, u8 pcp,
+				u8 prio);
+int mv88e6xxx_port_del_pcp_prio(struct dsa_switch *ds, int port, u8 pcp,
+				u8 prio);
+
+#endif /* _MV88E6XXX_DCB_H_ */
diff --git a/drivers/net/dsa/mv88e6xxx/port.c b/drivers/net/dsa/mv88e6xxx/port.c
index 23d1435db0d8..a8e2f8910b0a 100644
--- a/drivers/net/dsa/mv88e6xxx/port.c
+++ b/drivers/net/dsa/mv88e6xxx/port.c
@@ -1641,8 +1641,8 @@ int mv88e6095_port_tag_remap(struct mv88e6xxx_chip *chip, int port)
 				    0x7654);
 }
 
-static int mv88e6xxx_port_ieeepmt_write(struct mv88e6xxx_chip *chip,
-					int port, u16 table, u8 ptr, u16 data)
+int mv88e6xxx_port_ieeepmt_write(struct mv88e6xxx_chip *chip,
+				 int port, u16 table, u8 ptr, u16 data)
 {
 	u16 reg;
 
@@ -1654,6 +1654,30 @@ static int mv88e6xxx_port_ieeepmt_write(struct mv88e6xxx_chip *chip,
 				    MV88E6390_PORT_IEEE_PRIO_MAP_TABLE, reg);
 }
 
+int mv88e6xxx_port_ieeepmt_read(struct mv88e6xxx_chip *chip, int port,
+				u16 table, u8 ptr, u16 *data)
+{
+	u16 reg;
+	int err;
+
+	reg = table |
+		(ptr << __bf_shf(MV88E6390_PORT_IEEE_PRIO_MAP_TABLE_PTR_MASK));
+
+	err = mv88e6xxx_port_write(chip, port,
+				   MV88E6390_PORT_IEEE_PRIO_MAP_TABLE, reg);
+	if (err)
+		return err;
+
+	err = mv88e6xxx_port_read(chip, port,
+				  MV88E6390_PORT_IEEE_PRIO_MAP_TABLE, &reg);
+	if (err)
+		return err;
+
+	*data = reg & MV88E6390_PORT_IEEE_PRIO_MAP_TABLE_DATA_MASK;
+
+	return 0;
+}
+
 int mv88e6390_port_tag_remap(struct mv88e6xxx_chip *chip, int port)
 {
 	int err, i;
diff --git a/drivers/net/dsa/mv88e6xxx/port.h b/drivers/net/dsa/mv88e6xxx/port.h
index cf8655a13729..8bf0f3cbc4f0 100644
--- a/drivers/net/dsa/mv88e6xxx/port.h
+++ b/drivers/net/dsa/mv88e6xxx/port.h
@@ -457,11 +457,15 @@
 #define MV88E6390_PORT_IEEE_PRIO_MAP_TABLE_EGRESS_GREEN_PCP	0x1000
 #define MV88E6390_PORT_IEEE_PRIO_MAP_TABLE_EGRESS_YELLOW_PCP	0x2000
 #define MV88E6390_PORT_IEEE_PRIO_MAP_TABLE_EGRESS_AVB_PCP	0x3000
+#define MV88E6393X_PORT_IEEE_PRIO_MAP_TABLE_INGRESS_PCP_DEI	0x4000
 #define MV88E6390_PORT_IEEE_PRIO_MAP_TABLE_EGRESS_GREEN_DSCP	0x5000
 #define MV88E6390_PORT_IEEE_PRIO_MAP_TABLE_EGRESS_YELLOW_DSCP	0x6000
 #define MV88E6390_PORT_IEEE_PRIO_MAP_TABLE_EGRESS_AVB_DSCP	0x7000
 #define MV88E6390_PORT_IEEE_PRIO_MAP_TABLE_PTR_MASK		0x0e00
 #define MV88E6390_PORT_IEEE_PRIO_MAP_TABLE_DATA_MASK		0x01ff
+#define MV88E6390_PORT_IEEE_PRIO_MAP_TABLE_QPRI_DIS		0x0080
+#define MV88E6390_PORT_IEEE_PRIO_MAP_TABLE_QPRI_MASK		0x0070
+#define MV88E6390_PORT_IEEE_PRIO_MAP_TABLE_QPRI_SHIFT		4
 
 /* Offset 0x18: Port IEEE Priority Remapping Registers (0-3) */
 #define MV88E6095_PORT_IEEE_PRIO_REMAP_0123	0x18
@@ -543,6 +547,10 @@ int mv88e6xxx_port_set_8021q_mode(struct mv88e6xxx_chip *chip, int port,
 				  u16 mode);
 int mv88e6095_port_tag_remap(struct mv88e6xxx_chip *chip, int port);
 int mv88e6390_port_tag_remap(struct mv88e6xxx_chip *chip, int port);
+int mv88e6xxx_port_ieeepmt_write(struct mv88e6xxx_chip *chip,
+				 int port, u16 table, u8 ptr, u16 data);
+int mv88e6xxx_port_ieeepmt_read(struct mv88e6xxx_chip *chip, int port,
+				u16 table, u8 ptr, u16 *data);
 int mv88e6xxx_port_set_egress_mode(struct mv88e6xxx_chip *chip, int port,
 				   enum mv88e6xxx_egress_mode mode);
 int mv88e6085_port_set_frame_mode(struct mv88e6xxx_chip *chip, int port,

-- 
2.43.0

