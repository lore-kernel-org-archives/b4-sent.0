From: Cedric Jehasse <cedric.jehasse@luminex.be>
Date: Tue, 11 Aug 2026 13:45:49 +0200
Subject: [PATCH net-next v8 3/3] net: dsa: mv88e6xxx: add support for
 credit based shaper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-net-next-mv88e6xxx-cbs-v8-3-10d0baab2905@luminex.be>
References: <20260811-net-next-mv88e6xxx-cbs-v8-0-10d0baab2905@luminex.be>
In-Reply-To: <20260811-net-next-mv88e6xxx-cbs-v8-0-10d0baab2905@luminex.be>
To: Andrew Lunn <andrew@lunn.ch>, Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Russell King <linux@armlinux.org.uk>, 
 Jamal Hadi Salim <jhs@mojatatu.com>, Jiri Pirko <jiri@resnulli.us>, 
 Vinicius Costa Gomes <vinicius.gomes@intel.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Luke Howard <lukeh@padl.com>, 
 =?utf-8?q?Marek_Beh=C3=BAn?= <kabel@kernel.org>, 
 Cedric Jehasse <cedric.jehasse@gmail.com>, 
 Cedric Jehasse <cedric.jehasse@luminex.be>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786448754; l=19943;
 i=cedric.jehasse@luminex.be; s=20260213; h=from:subject:message-id;
 bh=AB35rvz8+lJVUXeONVQZfpgrp+ITr3Hzw6NZUnOhRIo=;
 b=GEJuZ+FNxdTy/e6eY+PlIzVAVFdAq0Gti79UODoSPucuCbcOehFvpSfL1erNDzM+olkVoWAVN
 L0tv/fBr4KqB5DbN7eXUXErjfJ9zG+3njWRLE1yiWvUasJCKne2He+W
X-Developer-Key: i=cedric.jehasse@luminex.be; a=ed25519;
 pk=DL2RaHc2bc7tTDTMJdugm42BtJk4Ip+7V41Gkj+Avjk=
X-Endpoint-Received: by B4 Relay for cedric.jehasse@luminex.be/20260213 with auth_id=638
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some of the chips supported by this driver have credit based shaper
support. Support is added for the 6341, 6352, 6390 and 6393 families.
This is configured using the Qav registers in the AVB register block.
There are small differences in the Qav registers between the chip
families (eg. the unit used for the rate and number of bits in the
registers). mv88e6xxx_qav_info is introduced to configure this per chip.

Eg. setting up 20mbps credit based shaper on a 1GBit link:
tc qdisc add dev p8 parent root handle 100: mqprio \
                num_tc 8 \
                map 0 0 6 7 0 5 0 0 0 0 0 0 0 0 0 0 \
                queues 1@0 1@1 1@2 1@3 1@4 1@5 1@6 1@7 \
                hw 0

tc qdisc replace dev p8 parent 100:8 cbs locredit -1470 hicredit 30 \
    sendslope -980000 idleslope 20000 offload 1

Note: only idleslope and hicredit can be programmed in the switch
registers, other parameters won't affect settings.

Signed-off-by: Cedric Jehasse <cedric.jehasse@luminex.be>
---
 drivers/net/dsa/mv88e6xxx/chip.c        | 141 ++++++++++++++++++++++++++++++++
 drivers/net/dsa/mv88e6xxx/chip.h        |  20 +++++
 drivers/net/dsa/mv88e6xxx/global2.h     |   3 +
 drivers/net/dsa/mv88e6xxx/global2_avb.c |  21 +++++
 drivers/net/dsa/mv88e6xxx/port.c        |  63 ++++++++++++++
 drivers/net/dsa/mv88e6xxx/port.h        |  20 +++++
 6 files changed, 268 insertions(+)

diff --git a/drivers/net/dsa/mv88e6xxx/chip.c b/drivers/net/dsa/mv88e6xxx/chip.c
index 47e531f24e5f2..a567ee9b6ce0d 100644
--- a/drivers/net/dsa/mv88e6xxx/chip.c
+++ b/drivers/net/dsa/mv88e6xxx/chip.c
@@ -32,6 +32,7 @@
 #include <linux/gpio/consumer.h>
 #include <linux/phylink.h>
 #include <net/dsa.h>
+#include <net/pkt_sched.h>
 
 #include "chip.h"
 #include "devlink.h"
@@ -5024,6 +5025,7 @@ static const struct mv88e6xxx_ops mv88e6240_ops = {
 	.port_set_ether_type = mv88e6351_port_set_ether_type,
 	.port_set_jumbo_size = mv88e6165_port_set_jumbo_size,
 	.port_egress_rate_limiting = mv88e6097_port_egress_rate_limiting,
+	.port_set_scheduling_mode = mv88e6352_port_set_scheduling_mode,
 	.port_pause_limit = mv88e6097_port_pause_limit,
 	.port_disable_learn_limit = mv88e6xxx_port_disable_learn_limit,
 	.port_disable_pri_override = mv88e6xxx_port_disable_pri_override,
@@ -5307,6 +5309,7 @@ static const struct mv88e6xxx_ops mv88e6341_ops = {
 	.port_set_ether_type = mv88e6351_port_set_ether_type,
 	.port_set_jumbo_size = mv88e6165_port_set_jumbo_size,
 	.port_egress_rate_limiting = mv88e6097_port_egress_rate_limiting,
+	.port_set_scheduling_mode = mv88e6352_port_set_scheduling_mode,
 	.port_pause_limit = mv88e6097_port_pause_limit,
 	.port_disable_learn_limit = mv88e6xxx_port_disable_learn_limit,
 	.port_disable_pri_override = mv88e6xxx_port_disable_pri_override,
@@ -5465,6 +5468,7 @@ static const struct mv88e6xxx_ops mv88e6352_ops = {
 	.port_set_ether_type = mv88e6351_port_set_ether_type,
 	.port_set_jumbo_size = mv88e6165_port_set_jumbo_size,
 	.port_egress_rate_limiting = mv88e6097_port_egress_rate_limiting,
+	.port_set_scheduling_mode = mv88e6352_port_set_scheduling_mode,
 	.port_pause_limit = mv88e6097_port_pause_limit,
 	.port_disable_learn_limit = mv88e6xxx_port_disable_learn_limit,
 	.port_disable_pri_override = mv88e6xxx_port_disable_pri_override,
@@ -5534,6 +5538,7 @@ static const struct mv88e6xxx_ops mv88e6390_ops = {
 	.port_get_cmode = mv88e6352_port_get_cmode,
 	.port_set_cmode = mv88e6390_port_set_cmode,
 	.port_setup_message_port = mv88e6xxx_setup_message_port,
+	.port_set_scheduling_mode = mv88e6390_port_set_scheduling_mode,
 	.stats_snapshot = mv88e6390_g1_stats_snapshot,
 	.stats_set_histogram = mv88e6390_g1_stats_set_histogram,
 	.stats_get_sset_count = mv88e6320_stats_get_sset_count,
@@ -5598,6 +5603,7 @@ static const struct mv88e6xxx_ops mv88e6390x_ops = {
 	.port_get_cmode = mv88e6352_port_get_cmode,
 	.port_set_cmode = mv88e6390x_port_set_cmode,
 	.port_setup_message_port = mv88e6xxx_setup_message_port,
+	.port_set_scheduling_mode = mv88e6390_port_set_scheduling_mode,
 	.stats_snapshot = mv88e6390_g1_stats_snapshot,
 	.stats_set_histogram = mv88e6390_g1_stats_set_histogram,
 	.stats_get_sset_count = mv88e6320_stats_get_sset_count,
@@ -5654,6 +5660,7 @@ static const struct mv88e6xxx_ops mv88e6393x_ops = {
 	.port_set_ether_type = mv88e6393x_port_set_ether_type,
 	.port_set_jumbo_size = mv88e6165_port_set_jumbo_size,
 	.port_egress_rate_limiting = mv88e6097_port_egress_rate_limiting,
+	.port_set_scheduling_mode = mv88e6390_port_set_scheduling_mode,
 	.port_pause_limit = mv88e6390_port_pause_limit,
 	.port_disable_learn_limit = mv88e6xxx_port_disable_learn_limit,
 	.port_disable_pri_override = mv88e6xxx_port_disable_pri_override,
@@ -5696,6 +5703,27 @@ static const struct mv88e6xxx_ops mv88e6393x_ops = {
 	.tcam_ops = &mv88e6393_tcam_ops,
 };
 
+static const struct mv88e6xxx_qav_info mv88e6352_qav_info = {
+	.rate_unit = 32,
+	.rate_mask = GENMASK(14, 0),
+	.hilimit_mask = GENMASK(14, 0),
+	.queue_mask = GENMASK(3, 0),
+};
+
+static const struct mv88e6xxx_qav_info mv88e6341_qav_info = {
+	.rate_unit = 64,
+	.rate_mask = GENMASK(15, 0),
+	.hilimit_mask = GENMASK(13, 0),
+	.queue_mask = GENMASK(3, 0),
+};
+
+static const struct mv88e6xxx_qav_info mv88e6390_qav_info = {
+	.rate_unit = 64,
+	.rate_mask = GENMASK(15, 0),
+	.hilimit_mask = GENMASK(13, 0),
+	.queue_mask = GENMASK(7, 0),
+};
+
 static const struct mv88e6xxx_info mv88e6xxx_table[] = {
 	[MV88E6020] = {
 		.prod_num = MV88E6XXX_PORT_SWITCH_ID_PROD_6020,
@@ -6260,6 +6288,7 @@ static const struct mv88e6xxx_info mv88e6xxx_table[] = {
 		.multi_chip = true,
 		.edsa_support = MV88E6XXX_EDSA_SUPPORTED,
 		.ptp_support = true,
+		.qav = &mv88e6352_qav_info,
 		.ops = &mv88e6240_ops,
 	},
 
@@ -6397,6 +6426,7 @@ static const struct mv88e6xxx_info mv88e6xxx_table[] = {
 		.multi_chip = true,
 		.edsa_support = MV88E6XXX_EDSA_SUPPORTED,
 		.ptp_support = true,
+		.qav = &mv88e6341_qav_info,
 		.ops = &mv88e6341_ops,
 	},
 
@@ -6477,6 +6507,7 @@ static const struct mv88e6xxx_info mv88e6xxx_table[] = {
 		.multi_chip = true,
 		.edsa_support = MV88E6XXX_EDSA_SUPPORTED,
 		.ptp_support = true,
+		.qav = &mv88e6352_qav_info,
 		.ops = &mv88e6352_ops,
 	},
 	[MV88E6361] = {
@@ -6534,6 +6565,7 @@ static const struct mv88e6xxx_info mv88e6xxx_table[] = {
 		.multi_chip = true,
 		.edsa_support = MV88E6XXX_EDSA_UNDOCUMENTED,
 		.ptp_support = true,
+		.qav = &mv88e6390_qav_info,
 		.ops = &mv88e6390_ops,
 	},
 	[MV88E6390X] = {
@@ -6561,6 +6593,7 @@ static const struct mv88e6xxx_info mv88e6xxx_table[] = {
 		.multi_chip = true,
 		.edsa_support = MV88E6XXX_EDSA_UNDOCUMENTED,
 		.ptp_support = true,
+		.qav = &mv88e6390_qav_info,
 		.ops = &mv88e6390x_ops,
 	},
 
@@ -6589,6 +6622,7 @@ static const struct mv88e6xxx_info mv88e6xxx_table[] = {
 		.pvt = true,
 		.multi_chip = true,
 		.ptp_support = true,
+		.qav = &mv88e6390_qav_info,
 		.ops = &mv88e6393x_ops,
 	},
 };
@@ -7210,6 +7244,112 @@ static int mv88e6xxx_crosschip_lag_leave(struct dsa_switch *ds, int sw_index,
 	return err_sync ? : err_pvt;
 }
 
+static int mv88e6xxx_setup_tc_cbs(struct dsa_switch *ds, int port,
+				  struct tc_cbs_qopt_offload *cbs)
+{
+	const struct mv88e6xxx_avb_ops *avb_ops;
+	struct mv88e6xxx_chip *chip = ds->priv;
+	const struct mv88e6xxx_qav_info *qav;
+	const struct mv88e6xxx_ops *ops;
+	int hilimit_reg;
+	int rate_reg;
+	u8 queue_bit;
+	u32 rate = 0;
+	u16 hilimit;
+	int err;
+
+	ops = chip->info->ops;
+	avb_ops = ops->avb_ops;
+	qav = chip->info->qav;
+
+	if (!qav || !avb_ops || !avb_ops->port_qav_write ||
+	    !ops->port_set_scheduling_mode)
+		return -EOPNOTSUPP;
+
+	if (!dsa_is_user_port(ds, port))
+		return -EOPNOTSUPP;
+
+	if (!(qav->queue_mask & BIT(cbs->queue))) {
+		NL_SET_ERR_MSG_MOD(cbs->extack, "CBS not supported on queue");
+		return -EOPNOTSUPP;
+	}
+
+	queue_bit = BIT(cbs->queue);
+	rate_reg = MV88E6XXX_PORT_QAV_CFG_RATE(cbs->queue);
+	hilimit_reg = MV88E6XXX_PORT_QAV_CFG_HILIMIT(cbs->queue);
+
+	if (cbs->enable) {
+		if (cbs->hicredit <= 0 ||
+		    cbs->hicredit > qav->hilimit_mask) {
+			NL_SET_ERR_MSG_MOD(cbs->extack,
+					   "hicredit out of range");
+			return -ERANGE;
+		}
+
+		rate = DIV_ROUND_UP(cbs->idleslope, qav->rate_unit);
+		if (rate > qav->rate_mask) {
+			NL_SET_ERR_MSG_MOD(cbs->extack,
+					   "idleslope out of range");
+			return -ERANGE;
+		}
+		/* avoid using zero rate */
+		rate = max_t(u16, rate, 1);
+	}
+
+	mv88e6xxx_reg_lock(chip);
+
+	if (!cbs->enable) {
+		err = mv88e6xxx_port_qav_write(chip, port, rate_reg, 0);
+		if (err)
+			goto unlock;
+
+		if (!(chip->ports[port].cbs_active_queues & ~queue_bit)) {
+			err = mv88e6xxx_port_set_scheduling_mode(chip, port, 0);
+			if (err)
+				goto unlock;
+		}
+		chip->ports[port].cbs_active_queues &= ~queue_bit;
+		goto unlock;
+	}
+
+	hilimit = cbs->hicredit & qav->hilimit_mask;
+	err = mv88e6xxx_port_qav_write(chip, port, hilimit_reg, hilimit);
+	if (err)
+		goto unlock;
+
+	err = mv88e6xxx_port_qav_write(chip, port, rate_reg, rate);
+	if (err)
+		goto unlock;
+
+	if (!chip->ports[port].cbs_active_queues) {
+		u8 sched_mode = chip->info->num_tx_queues - 1;
+
+		err = mv88e6xxx_port_set_scheduling_mode(chip, port,
+							 sched_mode);
+		if (err) {
+			mv88e6xxx_port_qav_write(chip, port, rate_reg, 0);
+			goto unlock;
+		}
+	}
+	chip->ports[port].cbs_active_queues |= queue_bit;
+
+unlock:
+	mv88e6xxx_reg_unlock(chip);
+
+	return err;
+}
+
+static int mv88e6xxx_port_setup_tc(struct dsa_switch *ds, int port,
+				   enum tc_setup_type type, void *type_data)
+{
+	switch (type) {
+	case TC_SETUP_QDISC_CBS:
+		return mv88e6xxx_setup_tc_cbs(ds, port, type_data);
+	default:
+		return -EOPNOTSUPP;
+	}
+}
+
 static const struct phylink_mac_ops mv88e6xxx_phylink_mac_ops = {
 	.mac_select_pcs		= mv88e6xxx_mac_select_pcs,
 	.mac_prepare		= mv88e6xxx_mac_prepare,
@@ -7269,6 +7409,7 @@ static const struct dsa_switch_ops mv88e6xxx_switch_ops = {
 	.port_hwtstamp_get	= mv88e6xxx_port_hwtstamp_get,
 	.port_txtstamp		= mv88e6xxx_port_txtstamp,
 	.port_rxtstamp		= mv88e6xxx_port_rxtstamp,
+	.port_setup_tc		= mv88e6xxx_port_setup_tc,
 	.cls_flower_add		= mv88e6xxx_cls_flower_add,
 	.cls_flower_del         = mv88e6xxx_cls_flower_del,
 	.get_ts_info		= mv88e6xxx_get_ts_info,
diff --git a/drivers/net/dsa/mv88e6xxx/chip.h b/drivers/net/dsa/mv88e6xxx/chip.h
index 3a1d79a117dca..85f646efe75ee 100644
--- a/drivers/net/dsa/mv88e6xxx/chip.h
+++ b/drivers/net/dsa/mv88e6xxx/chip.h
@@ -125,6 +125,7 @@ enum mv88e6xxx_edsa_support {
 };
 
 struct mv88e6xxx_ops;
+struct mv88e6xxx_qav_info;
 
 struct mv88e6xxx_info {
 	enum mv88e6xxx_family family;
@@ -177,6 +178,9 @@ struct mv88e6xxx_info {
 	/* Supports PTP */
 	bool ptp_support;
 
+	/* 802.1Qav credit based shaping */
+	const struct mv88e6xxx_qav_info *qav;
+
 	/* Internal PHY start index. 0 means that internal PHYs range starts at
 	 * port 0, 1 means internal PHYs range starts at port 1, etc
 	 */
@@ -304,6 +308,9 @@ struct mv88e6xxx_port {
 
 	/* MacAuth Bypass control flag */
 	bool mab;
+
+	/* Queues with CBS currently enabled. */
+	u8 cbs_active_queues;
 };
 
 enum mv88e6xxx_region_id {
@@ -606,6 +613,8 @@ struct mv88e6xxx_ops {
 				   size_t size);
 
 	int (*port_egress_rate_limiting)(struct mv88e6xxx_chip *chip, int port);
+	int (*port_set_scheduling_mode)(struct mv88e6xxx_chip *chip, int port,
+					u8 mode);
 	int (*port_pause_limit)(struct mv88e6xxx_chip *chip, int port, u8 in,
 				u8 out);
 	int (*port_disable_learn_limit)(struct mv88e6xxx_chip *chip, int port);
@@ -763,6 +772,10 @@ struct mv88e6xxx_avb_ops {
 	int (*tai_read)(struct mv88e6xxx_chip *chip, int addr, u16 *data,
 			int len);
 	int (*tai_write)(struct mv88e6xxx_chip *chip, int addr, u16 data);
+
+	/* Access port-scoped 802.1Qav registers */
+	int (*port_qav_write)(struct mv88e6xxx_chip *chip, int port, int addr,
+			      u16 data);
 };
 
 struct mv88e6xxx_ptp_ops {
@@ -798,6 +811,13 @@ struct mv88e6xxx_tcam_ops {
 	int (*flush_tcam)(struct mv88e6xxx_chip *chip);
 };
 
+struct mv88e6xxx_qav_info {
+	u16 rate_unit; /* in kbps */
+	u16 rate_mask; /* QPri Rate valid bits mask */
+	u16 hilimit_mask; /* QPri HiLimit bits mask*/
+	u8 queue_mask; /* supported queues bitmask */
+};
+
 static inline bool mv88e6xxx_has_stu(struct mv88e6xxx_chip *chip)
 {
 	return chip->info->max_sid > 0 &&
diff --git a/drivers/net/dsa/mv88e6xxx/global2.h b/drivers/net/dsa/mv88e6xxx/global2.h
index ff5adf7c9bc3a..df52ff3adc88c 100644
--- a/drivers/net/dsa/mv88e6xxx/global2.h
+++ b/drivers/net/dsa/mv88e6xxx/global2.h
@@ -186,6 +186,9 @@
 #define MV88E6352_G2_AVB_CMD_BLOCK_MASK		0x00e0
 #define MV88E6352_G2_AVB_CMD_ADDR_MASK		0x001f
 
+#define MV88E6XXX_PORT_QAV_CFG_RATE(queue)	(((queue) & 0x7) << 1)
+#define MV88E6XXX_PORT_QAV_CFG_HILIMIT(queue)	((((queue) & 0x7) << 1) + 1)
+
 /* Offset 0x17: AVB Data Register */
 #define MV88E6352_G2_AVB_DATA		0x17
 
diff --git a/drivers/net/dsa/mv88e6xxx/global2_avb.c b/drivers/net/dsa/mv88e6xxx/global2_avb.c
index 657783e043ff1..6b54e275d21ab 100644
--- a/drivers/net/dsa/mv88e6xxx/global2_avb.c
+++ b/drivers/net/dsa/mv88e6xxx/global2_avb.c
@@ -110,6 +110,15 @@ static int mv88e6352_g2_avb_port_ptp_write(struct mv88e6xxx_chip *chip,
 	return mv88e6xxx_g2_avb_write(chip, writeop, data);
 }
 
+static int mv88e6352_g2_avb_port_qav_write(struct mv88e6xxx_chip *chip,
+					   int port, int addr, u16 data)
+{
+	u16 writeop = MV88E6352_G2_AVB_CMD_OP_WRITE | (port << 8) |
+		      (MV88E6352_G2_AVB_CMD_BLOCK_QAV << 5) | addr;
+
+	return mv88e6xxx_g2_avb_write(chip, writeop, data);
+}
+
 static int mv88e6352_g2_avb_ptp_read(struct mv88e6xxx_chip *chip, int addr,
 				     u16 *data, int len)
 {
@@ -149,6 +158,7 @@ const struct mv88e6xxx_avb_ops mv88e6352_avb_ops = {
 	.ptp_write		= mv88e6352_g2_avb_ptp_write,
 	.tai_read		= mv88e6352_g2_avb_tai_read,
 	.tai_write		= mv88e6352_g2_avb_tai_write,
+	.port_qav_write		= mv88e6352_g2_avb_port_qav_write,
 };
 
 static int mv88e6165_g2_avb_tai_read(struct mv88e6xxx_chip *chip, int addr,
@@ -174,6 +184,7 @@ const struct mv88e6xxx_avb_ops mv88e6165_avb_ops = {
 	.ptp_write		= mv88e6352_g2_avb_ptp_write,
 	.tai_read		= mv88e6165_g2_avb_tai_read,
 	.tai_write		= mv88e6165_g2_avb_tai_write,
+	.port_qav_write		= mv88e6352_g2_avb_port_qav_write,
 };
 
 static int mv88e6390_g2_avb_port_ptp_read(struct mv88e6xxx_chip *chip,
@@ -197,6 +208,15 @@ static int mv88e6390_g2_avb_port_ptp_write(struct mv88e6xxx_chip *chip,
 	return mv88e6xxx_g2_avb_write(chip, writeop, data);
 }
 
+static int mv88e6390_g2_avb_port_qav_write(struct mv88e6xxx_chip *chip,
+					   int port, int addr, u16 data)
+{
+	u16 writeop = MV88E6390_G2_AVB_CMD_OP_WRITE | (port << 8) |
+		      (MV88E6352_G2_AVB_CMD_BLOCK_QAV << 5) | addr;
+
+	return mv88e6xxx_g2_avb_write(chip, writeop, data);
+}
+
 static int mv88e6390_g2_avb_ptp_read(struct mv88e6xxx_chip *chip, int addr,
 				     u16 *data, int len)
 {
@@ -236,4 +256,5 @@ const struct mv88e6xxx_avb_ops mv88e6390_avb_ops = {
 	.ptp_write		= mv88e6390_g2_avb_ptp_write,
 	.tai_read		= mv88e6390_g2_avb_tai_read,
 	.tai_write		= mv88e6390_g2_avb_tai_write,
+	.port_qav_write		= mv88e6390_g2_avb_port_qav_write,
 };
diff --git a/drivers/net/dsa/mv88e6xxx/port.c b/drivers/net/dsa/mv88e6xxx/port.c
index 4f915fbee228c..541fee492f5ff 100644
--- a/drivers/net/dsa/mv88e6xxx/port.c
+++ b/drivers/net/dsa/mv88e6xxx/port.c
@@ -1323,6 +1323,51 @@ int mv88e6097_port_egress_rate_limiting(struct mv88e6xxx_chip *chip, int port)
 				    0x0001);
 }
 
+int mv88e6352_port_set_scheduling_mode(struct mv88e6xxx_chip *chip, int port,
+				       u8 mode)
+{
+	u16 reg;
+	int err;
+
+	if (mode > 3)
+		return -EINVAL;
+
+	err = mv88e6xxx_port_read(chip, port, MV88E6XXX_PORT_EGRESS_RATE_CTL2,
+				  &reg);
+	if (err)
+		return err;
+
+	reg &= ~MV88E6XXX_PORT_EGRESS_RATE_CTL2_SCHEDULE_MASK;
+	reg |= mode << MV88E6XXX_PORT_EGRESS_RATE_CTL2_SCHEDULE_SHIFT;
+
+	return mv88e6xxx_port_write(chip, port,
+				    MV88E6XXX_PORT_EGRESS_RATE_CTL2, reg);
+}
+
+int mv88e6390_port_set_scheduling_mode(struct mv88e6xxx_chip *chip, int port,
+				       u8 mode)
+{
+	u16 reg;
+	int err;
+
+	if (mode > MV88E6390_PORT_QUEUE_CTL_SCHEDULE_MASK)
+		return -EINVAL;
+
+	reg = MV88E6390_PORT_QUEUE_CTL_UPDATE |
+	      (MV88E6390_PORT_QUEUE_CTL_SCHEDULE <<
+	       MV88E6390_PORT_QUEUE_CTL_PTR_SHIFT) |
+	      (mode & MV88E6390_PORT_QUEUE_CTL_SCHEDULE_MASK);
+
+	err = mv88e6xxx_port_write(chip, port, MV88E6390_PORT_QUEUE_CTL,
+				   reg);
+	if (err)
+		return err;
+
+	return mv88e6xxx_port_wait_bit(chip, port, MV88E6390_PORT_QUEUE_CTL,
+				       __bf_shf(MV88E6390_PORT_QUEUE_CTL_UPDATE)
+				       , 0);
+}
+
 /* Offset 0x0B: Port Association Vector */
 
 int mv88e6xxx_port_set_assoc_vector(struct mv88e6xxx_chip *chip, int port,
@@ -1736,3 +1781,21 @@ int mv88e6393x_port_set_policy(struct mv88e6xxx_chip *chip, int port,
 
 	return mv88e6393x_port_policy_write(chip, port, ptr, reg);
 }
+
+int mv88e6xxx_port_qav_write(struct mv88e6xxx_chip *chip, int port, int addr,
+			     u16 data)
+{
+	if (!chip->info->ops->avb_ops->port_qav_write)
+		return -EOPNOTSUPP;
+
+	return chip->info->ops->avb_ops->port_qav_write(chip, port, addr, data);
+}
+
+int mv88e6xxx_port_set_scheduling_mode(struct mv88e6xxx_chip *chip, int port,
+				       u8 mode)
+{
+	if (!chip->info->ops->port_set_scheduling_mode)
+		return -EOPNOTSUPP;
+
+	return chip->info->ops->port_set_scheduling_mode(chip, port, mode);
+}
diff --git a/drivers/net/dsa/mv88e6xxx/port.h b/drivers/net/dsa/mv88e6xxx/port.h
index bd61ddf2b228a..010319cb8a25a 100644
--- a/drivers/net/dsa/mv88e6xxx/port.h
+++ b/drivers/net/dsa/mv88e6xxx/port.h
@@ -241,6 +241,18 @@
 
 /* Offset 0x0A: Egress Rate Control 2 */
 #define MV88E6XXX_PORT_EGRESS_RATE_CTL2		0x0a
+#define MV88E6XXX_PORT_EGRESS_RATE_CTL2_SCHEDULE_MASK	0x3000
+#define MV88E6XXX_PORT_EGRESS_RATE_CTL2_SCHEDULE_SHIFT	12
+
+/* Offset 0x1C: Port Queue Control */
+#define MV88E6390_PORT_QUEUE_CTL			0x1c
+#define MV88E6390_PORT_QUEUE_CTL_UPDATE			0x8000
+#define MV88E6390_PORT_QUEUE_CTL_PTR_MASK		0x7f00
+#define MV88E6390_PORT_QUEUE_CTL_PTR_SHIFT		8
+#define MV88E6390_PORT_QUEUE_CTL_DATA_MASK		0x00ff
+#define MV88E6390_PORT_QUEUE_CTL_SCHEDULE		0x00
+#define MV88E6390_PORT_QUEUE_CTL_SCHEDULE_MASK		0x07
+
 
 /* Offset 0x0B: Port Association Vector */
 #define MV88E6XXX_PORT_ASSOC_VECTOR			0x0b
@@ -562,6 +574,10 @@ int mv88e6165_port_set_jumbo_size(struct mv88e6xxx_chip *chip, int port,
 				  size_t size);
 int mv88e6095_port_egress_rate_limiting(struct mv88e6xxx_chip *chip, int port);
 int mv88e6097_port_egress_rate_limiting(struct mv88e6xxx_chip *chip, int port);
+int mv88e6352_port_set_scheduling_mode(struct mv88e6xxx_chip *chip, int port,
+				       u8 mode);
+int mv88e6390_port_set_scheduling_mode(struct mv88e6xxx_chip *chip, int port,
+				       u8 mode);
 int mv88e6xxx_port_set_assoc_vector(struct mv88e6xxx_chip *chip, int port,
 				    u16 pav);
 int mv88e6097_port_pause_limit(struct mv88e6xxx_chip *chip, int port, u8 in,
@@ -606,5 +622,9 @@ int mv88e6xxx_port_hidden_read(struct mv88e6xxx_chip *chip, int block, int port,
 			       int reg, u16 *val);
 
 int mv88e6xxx_port_enable_tcam(struct mv88e6xxx_chip *chip, int port);
+int mv88e6xxx_port_qav_write(struct mv88e6xxx_chip *chip, int port, int addr,
+			     u16 data);
+int mv88e6xxx_port_set_scheduling_mode(struct mv88e6xxx_chip *chip, int port,
+				       u8 mode);
 
 #endif /* _MV88E6XXX_PORT_H */

-- 
2.43.0

