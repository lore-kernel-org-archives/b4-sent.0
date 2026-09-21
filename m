From: Nicolo Giuliani <nicolo.giuliani6@studio.unibo.it>
Date: Mon, 21 Sep 2026 05:56:29 +0200
Subject: [PATCH net v2] net: dsa: mv88e6xxx: 88E6191X and 88E6193X have no
 PTP
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-send-net-v2-1-031ad720f140@studio.unibo.it>
X-B4-Tracking: v=1; b=H4sIAOyqsGoC/2WNQQ6CMBBFr0JmbQktLYgr72FclDLKuGhJpxAN4
 e4WXLp8Py/vr8AYCRkuxQoRF2IKPoM6FeBG658oaMgMqlJN1clOMPpBeEyia601jamt02fI+hT
 xQe8jdYMswP038ty/0KU9smsjcQrxcxwu8pD/24sUUujaGNcq3RjEK6d5oFDOnvpQUo5v2/YFo
 RWcor0AAAA=
X-Change-ID: 20260919-send-net-97aa5653ac48
To: Andrew Lunn <andrew@lunn.ch>, Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Richard Cochran <richardcochran@gmail.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nicolo Giuliani <nicolo.giuliani6@studio.unibo.it>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789962988; l=6074;
 i=nicolo.giuliani6@studio.unibo.it; s=20260919; h=from:subject:message-id;
 bh=zvg227S60l2Y4KCjY2ZtncW2AyMuzOIIib4Gk2dmg1o=;
 b=267QZv6EzlKHut28OGs6bee7NNvCO2ylUTtereN1FBJtrz6WZ65ovebBlYIm1VmCLUGJx59CP
 7Gme7E5F2a0COndbzmMLnwQLUpWCEoK5kf7j5ZSR1ck9AsvzNiZKrLZ
X-Developer-Key: i=nicolo.giuliani6@studio.unibo.it; a=ed25519;
 pk=D652ecdT01GkA1eoFWNFNX85xIg5ZnFwUWyjfestgQw=
X-Endpoint-Received: by B4 Relay for nicolo.giuliani6@studio.unibo.it/20260919 with auth_id=1040
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The 88E6191X and 88E6193X are 6393 family devices that share
mv88e6393x_ops with the 88E6393X and are marked as ptp_support. Marvell's
UMSD driver describes both as parts without AVB (88E6193X: "BGA package -
No AVB, No Routing, No Cut-through"), and the register access confirms it
on an 88E6193X: the whole indirect AVB register space behind Global 2
registers 0x16 and 0x17 reads zero, for every port, block and address,
with the 6390 and with the 6352 command encoding. Writes to the TAI
registers, including the clock period register and the TAI global
configuration register, read back as zero.

Since commit 7e3c18097a70 ("net: dsa: mv88e6xxx: read cycle counter
period from hardware") the PTP setup reads the TAI clock period, so the
switch fails to probe:

mv88e6xxx ...: unexpected cycle counter period of 0 ps

Add mv88e6191x_ops, a copy of mv88e6393x_ops without avb_ops and ptp_ops,
use it for the 88E6191X and the 88E6193X and stop setting ptp_support for
them. The 88E6393X is unchanged.

Tested on an 88E6193X (Sophos XGS 107w): the switch probes and the ports
work. I do not have an 88E6191X, it is changed because UMSD describes it
the same way.

Fixes: de776d0d316f ("net: dsa: mv88e6xxx: add support for mv88e6393x family")
Suggested-by: Andrew Lunn <andrew@lunn.ch>
Assisted-by: LLM
Signed-off-by: Nicolo Giuliani <nicolo.giuliani6@studio.unibo.it>
---
Changes in v2:
- New patch instead of skipping PTP setup: the 88E6191X and 88E6193X have no AVB/PTP unit (per Andrew Lunn, from Marvell's UMSD; the AVB register space reads zero on an 88E6193X), so they get their own ops without avb_ops and ptp_ops and lose ptp_support
- Link to v1: https://patch.msgid.link/20260919-send-net-v1-1-4355c72465ee@studio.unibo.it
---
 drivers/net/dsa/mv88e6xxx/chip.c | 68 +++++++++++++++++++++++++++++++++++++---
 1 file changed, 64 insertions(+), 4 deletions(-)

diff --git a/drivers/net/dsa/mv88e6xxx/chip.c b/drivers/net/dsa/mv88e6xxx/chip.c
index 7f68a0c55..a4a8c7e11 100644
--- a/drivers/net/dsa/mv88e6xxx/chip.c
+++ b/drivers/net/dsa/mv88e6xxx/chip.c
@@ -5639,6 +5639,68 @@ static const struct mv88e6xxx_ops mv88e6390x_ops = {
 	.pcs_ops = &mv88e6390_pcs_ops,
 };
 
+static const struct mv88e6xxx_ops mv88e6191x_ops = {
+	/* MV88E6XXX_FAMILY_6393 without AVB and PTP: 6191X and 6193X */
+	.irl_init_all = mv88e6390_g2_irl_init_all,
+	.get_eeprom = mv88e6xxx_g2_get_eeprom8,
+	.set_eeprom = mv88e6xxx_g2_set_eeprom8,
+	.set_switch_mac = mv88e6xxx_g2_set_switch_mac,
+	.phy_read = mv88e6xxx_g2_smi_phy_read_c22,
+	.phy_write = mv88e6xxx_g2_smi_phy_write_c22,
+	.phy_read_c45 = mv88e6xxx_g2_smi_phy_read_c45,
+	.phy_write_c45 = mv88e6xxx_g2_smi_phy_write_c45,
+	.port_set_link = mv88e6xxx_port_set_link,
+	.port_sync_link = mv88e6xxx_port_sync_link,
+	.port_set_rgmii_delay = mv88e6390_port_set_rgmii_delay,
+	.port_set_speed_duplex = mv88e6393x_port_set_speed_duplex,
+	.port_tag_remap = mv88e6390_port_tag_remap,
+	.port_set_policy = mv88e6393x_port_set_policy,
+	.port_set_frame_mode = mv88e6351_port_set_frame_mode,
+	.port_set_ucast_flood = mv88e6352_port_set_ucast_flood,
+	.port_set_mcast_flood = mv88e6352_port_set_mcast_flood,
+	.port_set_ether_type = mv88e6393x_port_set_ether_type,
+	.port_set_jumbo_size = mv88e6165_port_set_jumbo_size,
+	.port_egress_rate_limiting = mv88e6097_port_egress_rate_limiting,
+	.port_pause_limit = mv88e6390_port_pause_limit,
+	.port_disable_learn_limit = mv88e6xxx_port_disable_learn_limit,
+	.port_disable_pri_override = mv88e6xxx_port_disable_pri_override,
+	.port_get_cmode = mv88e6352_port_get_cmode,
+	.port_set_cmode = mv88e6393x_port_set_cmode,
+	.port_setup_message_port = mv88e6xxx_setup_message_port,
+	.port_set_upstream_port = mv88e6393x_port_set_upstream_port,
+	.port_enable_tcam = mv88e6xxx_port_enable_tcam,
+	.stats_snapshot = mv88e6390_g1_stats_snapshot,
+	.stats_set_histogram = mv88e6390_g1_stats_set_histogram,
+	.stats_get_sset_count = mv88e6320_stats_get_sset_count,
+	.stats_get_strings = mv88e6320_stats_get_strings,
+	.stats_get_stat = mv88e6390_stats_get_stat,
+	/* .set_cpu_port is missing because this family does not support a global
+	 * CPU port, only per port CPU port which is set via
+	 * .port_set_upstream_port method.
+	 */
+	.set_egress_port = mv88e6393x_set_egress_port,
+	.watchdog_ops = &mv88e6393x_watchdog_ops,
+	.mgmt_rsvd2cpu = mv88e6393x_port_mgmt_rsvd2cpu,
+	.pot_clear = mv88e6xxx_g2_pot_clear,
+	.hardware_reset_pre = mv88e6xxx_g2_eeprom_wait,
+	.hardware_reset_post = mv88e6xxx_g2_eeprom_wait,
+	.reset = mv88e6352_g1_reset,
+	.rmu_disable = mv88e6390_g1_rmu_disable,
+	.atu_get_hash = mv88e6165_g1_atu_get_hash,
+	.atu_set_hash = mv88e6165_g1_atu_set_hash,
+	.vtu_getnext = mv88e6390_g1_vtu_getnext,
+	.vtu_loadpurge = mv88e6390_g1_vtu_loadpurge,
+	.stu_getnext = mv88e6390_g1_stu_getnext,
+	.stu_loadpurge = mv88e6390_g1_stu_loadpurge,
+	.serdes_get_lane = mv88e6393x_serdes_get_lane,
+	.serdes_irq_mapping = mv88e6390_serdes_irq_mapping,
+	/* TODO: serdes stats */
+	.gpio_ops = &mv88e6352_gpio_ops,
+	.phylink_get_caps = mv88e6393x_phylink_get_caps,
+	.pcs_ops = &mv88e6393x_pcs_ops,
+	.tcam_ops = &mv88e6393_tcam_ops,
+};
+
 static const struct mv88e6xxx_ops mv88e6393x_ops = {
 	/* MV88E6XXX_FAMILY_6393 */
 	.irl_init_all = mv88e6390_g2_irl_init_all,
@@ -6163,8 +6225,7 @@ static const struct mv88e6xxx_info mv88e6xxx_table[] = {
 		.atu_move_port_mask = 0x1f,
 		.pvt = true,
 		.multi_chip = true,
-		.ptp_support = true,
-		.ops = &mv88e6393x_ops,
+		.ops = &mv88e6191x_ops,
 	},
 
 	[MV88E6193X] = {
@@ -6190,8 +6251,7 @@ static const struct mv88e6xxx_info mv88e6xxx_table[] = {
 		.atu_move_port_mask = 0x1f,
 		.pvt = true,
 		.multi_chip = true,
-		.ptp_support = true,
-		.ops = &mv88e6393x_ops,
+		.ops = &mv88e6191x_ops,
 	},
 
 	[MV88E6220] = {

---
base-commit: 6c096bb08de97cdca051fecddad22cac6a1fd275
change-id: 20260919-send-net-97aa5653ac48

Best regards,
--  
Nicolo Giuliani <nicolo.giuliani6@studio.unibo.it>

