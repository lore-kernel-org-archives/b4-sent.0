From: Manuel Janocha <manuel.janocha@amperfied.com>
Date: Fri, 27 Nov 2026 11:17:43 +0000
Subject: [PATCH net] net: ethernet: ti: cpsw_ale: serialize ALE table
 accesses
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-cpsw-ale-lock-v1-1-a72772d9a5ae@amperfied.com>
X-B4-Tracking: v=1; b=H4sIANZmCWsC/yWMzQqDMBAGX0X23IUkoIKvUnqI69d2VaJk7Q+I7
 960Pc7AzE6GrDDqqp0ynmq6pAL+VJHcY7qBdShMwYXG+9CwrPbiOIPnRSYWcfVQ94htdFSaNeO
 q79/vTAkbXf7SHv0I2b4nOo4P+xfzpHYAAAA=
X-Change-ID: 20261126-cpsw-ale-lock-cc05d5bea7a0
To: Siddharth Vadapalli <s-vadapalli@ti.com>, 
 Roger Quadros <rogerq@kernel.org>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: linux-omap@vger.kernel.org, netdev@vger.kernel.org, 
 Kuniyuki Iwashima <kuniyu@google.com>, stable@vger.kernel.org, 
 Manuel Janocha <manuel.janocha@amperfied.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795778302; l=13871;
 i=manuel.janocha@amperfied.com; s=20261127; h=from:subject:message-id;
 bh=F/gBDDRHH022ptqUxUqYe92QVqSBo1huapUmHvbf6Ow=;
 b=jAif4U7n5mT3PmUzmxwIy+smyiQNPSCkEhvOuWM9FVB4rAF88o2l+JDv/9ZYDPKAH2UylxOWM
 iROq1LyBwUSC397bydinsaRqn2OBTXWQ3XedLHGqrLMHziwsw2EhT+8
X-Developer-Key: i=manuel.janocha@amperfied.com; a=ed25519;
 pk=DEqXiAa78UfHuuvMWJsylc0F41gl8N+i7WtqrDb4xCQ=
X-Endpoint-Received: by B4 Relay for manuel.janocha@amperfied.com/20261127 with auth_id=1666
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ALE table is accessed through a single index register
(ALE_TABLE_CONTROL) and three data registers (ALE_TABLE). Reading an
entry writes the index and then reads the data registers; writing an
entry fills the data registers and then writes the index with
ALE_TABLE_WRITE. Most operations (add/del ucast/mcast/vlan,
vlan_add_modify, flush_multicast, set_allmulti, set_unreg_mcast) are
read-modify-write sequences over several entries. The driver has no
lock around any of this.

This did not matter as long as the callers were serialized by someone
else. Both ports of a CPSW switch share one ALE, but the port VLAN
and address operations run under RTNL, while ndo_set_rx_mode() runs
under netif_addr_lock_bh() of one port only and never took RTNL. Since
IPV6_ADD_MEMBERSHIP and friends no longer hold RTNL, joining an IPv6
multicast group (igmp6_group_added() -> dev_mc_add() ->
ndo_set_rx_mode()) can run concurrently with a VLAN or address
operation on the other port, or on the same port.

For example, on two CPUs:

  CPU0 (eth0 rx_mode, flush)     CPU1 (eth1 add_vid)
  cpsw_ale_read(A):
    writel(A, TABLE_CONTROL)
                                 cpsw_ale_read(B):
                                   writel(B, TABLE_CONTROL)
    readl(ALE_TABLE + 0..2)
      -> returns entry B
  cpsw_ale_write(A):
    entry B is written to index A

Entry A is lost and entry B exists twice. Interleaved writes can
equally mix the data words of two entries in one table slot. The same
happens inside the multi-entry loops, so entries are written back with
foreign data or are dropped.

Observed on an AM625 board with two am65-cpsw-nuss ports in dual EMAC
mode and seven VLANs on the second port: after boot the port VLAN
entry (VID 0), the unicast entry of the first port and two VLAN
entries were gone, copies of the unicast and of the broadcast entry
showed up at two other indexes. The switch then dropped every frame
received on the first port (p0_ale_vid_ingress_drop kept rising) while
the port could still transmit, and the board was unreachable.

Add a spinlock to struct cpsw_ale and take it in all exported
functions that access the table. spin_lock_bh() is used because
ndo_set_rx_mode() runs with bottom halves disabled
(netif_addr_lock_bh()) and the dev_mc_add()/dev_uc_add() family is not
restricted to process context, while the other callers run in process
context (RTNL, workqueue, ethtool, system suspend). None of them runs
in hard interrupt context, and a sleeping lock cannot be used because
of the atomic callers. The register accesses under the lock are plain
readl()/writel(); the regmap of the ALE is only used for the version,
feature and policer fields and is not touched under the lock.

cpsw_ale_vlan_add_modify() calls cpsw_ale_add_vlan() with the lock
held, so the body of the latter moves into a static helper that does
not take the lock. The loops over all entries run with the lock held
for the number of table entries; that is the same amount of MMIO as
before, just not preemptible by the other port.

The lock covers the table (index and data registers) only. The
read-modify-write of the ALE control registers and the policer index
registers are separate and left alone.

Discovery: observed on a test system and reproduced on the same board.
The reproducer joins IPv6 multicast groups in parallel on eth0, eth1
and a VLAN interface of eth1 while adding and deleting a VLAN on eth1.
It needs no kernel modification and no error injection. Without this
change eth0 stops receiving after about 30 seconds.

Testing: hardware test on an AM625 board (two CPSW ports,
am65-cpsw-nuss) with net at v7.4-rc3 (ef3e21c61baa) plus an
out-of-tree board device tree, built with PROVE_LOCKING,
DEBUG_SPINLOCK and DEBUG_ATOMIC_SLEEP. Without this patch the
reproducer kills reception within 120 seconds
(p0_ale_vid_ingress_drop 0 -> 2366 and rising; link down/up
recovers). With this patch it ran for 120 and for 300 seconds
(about 23000 joins, 88 VLAN add/delete cycles of three VLANs): eth0
and the VLANs kept receiving and lockdep stayed silent. The same
result was seen earlier with a backport to the TI vendor kernel
6.18.59. The legacy cpsw, cpsw_new and netcp users of the ALE were
only compile-tested (arm64, W=1).

Tooling: the port to net, the locking analysis and this changelog were
prepared with an AI coding assistant (Claude).

Fixes: 1767bb2d47b7 ("ipv6: mcast: Don't hold RTNL for IPV6_ADD_MEMBERSHIP and MCAST_JOIN_GROUP.")
Cc: stable@vger.kernel.org
Signed-off-by: Manuel Janocha <manuel.janocha@amperfied.com>
---
 drivers/net/ethernet/ti/cpsw_ale.c | 70 ++++++++++++++++++++++++++++++++------
 drivers/net/ethernet/ti/cpsw_ale.h |  2 ++
 2 files changed, 62 insertions(+), 10 deletions(-)

diff --git a/drivers/net/ethernet/ti/cpsw_ale.c b/drivers/net/ethernet/ti/cpsw_ale.c
index 9304405c9581..dc550142ed82 100644
--- a/drivers/net/ethernet/ti/cpsw_ale.c
+++ b/drivers/net/ethernet/ti/cpsw_ale.c
@@ -464,6 +464,7 @@ int cpsw_ale_flush_multicast(struct cpsw_ale *ale, int port_mask, int vid)
 	u32 ale_entry[ALE_ENTRY_WORDS];
 	int ret, idx;
 
+	spin_lock_bh(&ale->lock);
 	for (idx = 0; idx < ale->params.ale_entries; idx++) {
 		cpsw_ale_read(ale, idx, ale_entry);
 		ret = cpsw_ale_get_entry_type(ale_entry);
@@ -491,6 +492,7 @@ int cpsw_ale_flush_multicast(struct cpsw_ale *ale, int port_mask, int vid)
 
 		cpsw_ale_write(ale, idx, ale_entry);
 	}
+	spin_unlock_bh(&ale->lock);
 	return 0;
 }
 EXPORT_SYMBOL_GPL(cpsw_ale_flush_multicast);
@@ -520,15 +522,19 @@ int cpsw_ale_add_ucast(struct cpsw_ale *ale, const u8 *addr, int port,
 	cpsw_ale_set_blocked(ale_entry, (flags & ALE_BLOCKED) ? 1 : 0);
 	cpsw_ale_set_port_num(ale_entry, port, ale->port_num_bits);
 
+	spin_lock_bh(&ale->lock);
 	idx = cpsw_ale_match_addr(ale, addr, (flags & ALE_VLAN) ? vid : 0);
 	if (idx < 0)
 		idx = cpsw_ale_match_free(ale);
 	if (idx < 0)
 		idx = cpsw_ale_find_ageable(ale);
-	if (idx < 0)
+	if (idx < 0) {
+		spin_unlock_bh(&ale->lock);
 		return -ENOMEM;
+	}
 
 	cpsw_ale_write(ale, idx, ale_entry);
+	spin_unlock_bh(&ale->lock);
 	return 0;
 }
 EXPORT_SYMBOL_GPL(cpsw_ale_add_ucast);
@@ -539,12 +545,16 @@ int cpsw_ale_del_ucast(struct cpsw_ale *ale, const u8 *addr, int port,
 	u32 ale_entry[ALE_ENTRY_WORDS] = {0, 0, 0};
 	int idx;
 
+	spin_lock_bh(&ale->lock);
 	idx = cpsw_ale_match_addr(ale, addr, (flags & ALE_VLAN) ? vid : 0);
-	if (idx < 0)
+	if (idx < 0) {
+		spin_unlock_bh(&ale->lock);
 		return -ENOENT;
+	}
 
 	cpsw_ale_set_entry_type(ale_entry, ALE_TYPE_FREE);
 	cpsw_ale_write(ale, idx, ale_entry);
+	spin_unlock_bh(&ale->lock);
 	return 0;
 }
 EXPORT_SYMBOL_GPL(cpsw_ale_del_ucast);
@@ -555,6 +565,7 @@ int cpsw_ale_add_mcast(struct cpsw_ale *ale, const u8 *addr, int port_mask,
 	u32 ale_entry[ALE_ENTRY_WORDS] = {0, 0, 0};
 	int idx, mask;
 
+	spin_lock_bh(&ale->lock);
 	idx = cpsw_ale_match_addr(ale, addr, (flags & ALE_VLAN) ? vid : 0);
 	if (idx >= 0)
 		cpsw_ale_read(ale, idx, ale_entry);
@@ -575,10 +586,13 @@ int cpsw_ale_add_mcast(struct cpsw_ale *ale, const u8 *addr, int port_mask,
 		idx = cpsw_ale_match_free(ale);
 	if (idx < 0)
 		idx = cpsw_ale_find_ageable(ale);
-	if (idx < 0)
+	if (idx < 0) {
+		spin_unlock_bh(&ale->lock);
 		return -ENOMEM;
+	}
 
 	cpsw_ale_write(ale, idx, ale_entry);
+	spin_unlock_bh(&ale->lock);
 	return 0;
 }
 EXPORT_SYMBOL_GPL(cpsw_ale_add_mcast);
@@ -590,9 +604,12 @@ int cpsw_ale_del_mcast(struct cpsw_ale *ale, const u8 *addr, int port_mask,
 	int mcast_members = 0;
 	int idx;
 
+	spin_lock_bh(&ale->lock);
 	idx = cpsw_ale_match_addr(ale, addr, (flags & ALE_VLAN) ? vid : 0);
-	if (idx < 0)
+	if (idx < 0) {
+		spin_unlock_bh(&ale->lock);
 		return -ENOENT;
+	}
 
 	cpsw_ale_read(ale, idx, ale_entry);
 
@@ -609,6 +626,7 @@ int cpsw_ale_del_mcast(struct cpsw_ale *ale, const u8 *addr, int port_mask,
 		cpsw_ale_set_entry_type(ale_entry, ALE_TYPE_FREE);
 
 	cpsw_ale_write(ale, idx, ale_entry);
+	spin_unlock_bh(&ale->lock);
 	return 0;
 }
 EXPORT_SYMBOL_GPL(cpsw_ale_del_mcast);
@@ -642,8 +660,8 @@ static void cpsw_ale_set_vlan_untag(struct cpsw_ale *ale, u32 *ale_entry,
 		bitmap_clear(ale->p0_untag_vid_mask, vid, 1);
 }
 
-int cpsw_ale_add_vlan(struct cpsw_ale *ale, u16 vid, int port_mask, int untag,
-		      int reg_mcast, int unreg_mcast)
+static int __cpsw_ale_add_vlan(struct cpsw_ale *ale, u16 vid, int port_mask,
+			       int untag, int reg_mcast, int unreg_mcast)
 {
 	u32 ale_entry[ALE_ENTRY_WORDS] = {0, 0, 0};
 	int idx;
@@ -681,6 +699,19 @@ int cpsw_ale_add_vlan(struct cpsw_ale *ale, u16 vid, int port_mask, int untag,
 	cpsw_ale_write(ale, idx, ale_entry);
 	return 0;
 }
+
+int cpsw_ale_add_vlan(struct cpsw_ale *ale, u16 vid, int port_mask, int untag,
+		      int reg_mcast, int unreg_mcast)
+{
+	int ret;
+
+	spin_lock_bh(&ale->lock);
+	ret = __cpsw_ale_add_vlan(ale, vid, port_mask, untag, reg_mcast,
+				  unreg_mcast);
+	spin_unlock_bh(&ale->lock);
+
+	return ret;
+}
 EXPORT_SYMBOL_GPL(cpsw_ale_add_vlan);
 
 static void cpsw_ale_vlan_del_modify_int(struct cpsw_ale *ale,  u32 *ale_entry,
@@ -728,14 +759,18 @@ int cpsw_ale_vlan_del_modify(struct cpsw_ale *ale, u16 vid, int port_mask)
 	u32 ale_entry[ALE_ENTRY_WORDS] = {0, 0, 0};
 	int idx;
 
+	spin_lock_bh(&ale->lock);
 	idx = cpsw_ale_match_vlan(ale, vid);
-	if (idx < 0)
+	if (idx < 0) {
+		spin_unlock_bh(&ale->lock);
 		return -ENOENT;
+	}
 
 	cpsw_ale_read(ale, idx, ale_entry);
 
 	cpsw_ale_vlan_del_modify_int(ale, ale_entry, vid, port_mask);
 	cpsw_ale_write(ale, idx, ale_entry);
+	spin_unlock_bh(&ale->lock);
 
 	return 0;
 }
@@ -746,9 +781,12 @@ int cpsw_ale_del_vlan(struct cpsw_ale *ale, u16 vid, int port_mask)
 	u32 ale_entry[ALE_ENTRY_WORDS] = {0, 0, 0};
 	int members, idx;
 
+	spin_lock_bh(&ale->lock);
 	idx = cpsw_ale_match_vlan(ale, vid);
-	if (idx < 0)
+	if (idx < 0) {
+		spin_unlock_bh(&ale->lock);
 		return -ENOENT;
+	}
 
 	cpsw_ale_read(ale, idx, ale_entry);
 
@@ -771,6 +809,7 @@ int cpsw_ale_del_vlan(struct cpsw_ale *ale, u16 vid, int port_mask)
 	}
 
 	cpsw_ale_write(ale, idx, ale_entry);
+	spin_unlock_bh(&ale->lock);
 
 	return 0;
 }
@@ -784,6 +823,7 @@ int cpsw_ale_vlan_add_modify(struct cpsw_ale *ale, u16 vid, int port_mask,
 	int vlan_members, untag_members;
 	int idx, ret = 0;
 
+	spin_lock_bh(&ale->lock);
 	idx = cpsw_ale_match_vlan(ale, vid);
 	if (idx >= 0)
 		cpsw_ale_read(ale, idx, ale_entry);
@@ -803,8 +843,9 @@ int cpsw_ale_vlan_add_modify(struct cpsw_ale *ale, u16 vid, int port_mask,
 	reg_mcast_members = (reg_mcast_members & ~port_mask) | reg_mask;
 	unreg_mcast_members = (unreg_mcast_members & ~port_mask) | unreg_mask;
 
-	ret = cpsw_ale_add_vlan(ale, vid, vlan_members, untag_members,
-				reg_mcast_members, unreg_mcast_members);
+	ret = __cpsw_ale_add_vlan(ale, vid, vlan_members, untag_members,
+				  reg_mcast_members, unreg_mcast_members);
+	spin_unlock_bh(&ale->lock);
 	if (ret) {
 		dev_err(ale->params.dev, "Unable to add vlan\n");
 		return ret;
@@ -823,6 +864,7 @@ void cpsw_ale_set_unreg_mcast(struct cpsw_ale *ale, int unreg_mcast_mask,
 	int unreg_members = 0;
 	int type, idx;
 
+	spin_lock_bh(&ale->lock);
 	for (idx = 0; idx < ale->params.ale_entries; idx++) {
 		cpsw_ale_read(ale, idx, ale_entry);
 		type = cpsw_ale_get_entry_type(ale_entry);
@@ -841,6 +883,7 @@ void cpsw_ale_set_unreg_mcast(struct cpsw_ale *ale, int unreg_mcast_mask,
 				      unreg_members);
 		cpsw_ale_write(ale, idx, ale_entry);
 	}
+	spin_unlock_bh(&ale->lock);
 }
 EXPORT_SYMBOL_GPL(cpsw_ale_set_unreg_mcast);
 
@@ -885,6 +928,7 @@ void cpsw_ale_set_allmulti(struct cpsw_ale *ale, int allmulti, int port)
 	u32 ale_entry[ALE_ENTRY_WORDS];
 	int type, idx;
 
+	spin_lock_bh(&ale->lock);
 	for (idx = 0; idx < ale->params.ale_entries; idx++) {
 		int vlan_members;
 
@@ -907,6 +951,7 @@ void cpsw_ale_set_allmulti(struct cpsw_ale *ale, int allmulti, int port)
 
 		cpsw_ale_write(ale, idx, ale_entry);
 	}
+	spin_unlock_bh(&ale->lock);
 }
 EXPORT_SYMBOL_GPL(cpsw_ale_set_allmulti);
 
@@ -1540,6 +1585,7 @@ struct cpsw_ale *cpsw_ale_create(struct cpsw_ale_params *params)
 	ale = devm_kzalloc_obj(params->dev, *ale);
 	if (!ale)
 		return ERR_PTR(-ENOMEM);
+	spin_lock_init(&ale->lock);
 	ale->regmap = devm_regmap_init_mmio(params->dev, params->ale_regs,
 					    &ale_regmap_cfg);
 	if (IS_ERR(ale->regmap)) {
@@ -1641,10 +1687,12 @@ void cpsw_ale_dump(struct cpsw_ale *ale, u32 *data)
 {
 	int i;
 
+	spin_lock_bh(&ale->lock);
 	for (i = 0; i < ale->params.ale_entries; i++) {
 		cpsw_ale_read(ale, i, data);
 		data += ALE_ENTRY_WORDS;
 	}
+	spin_unlock_bh(&ale->lock);
 }
 EXPORT_SYMBOL_GPL(cpsw_ale_dump);
 
@@ -1652,10 +1700,12 @@ void cpsw_ale_restore(struct cpsw_ale *ale, u32 *data)
 {
 	int i;
 
+	spin_lock_bh(&ale->lock);
 	for (i = 0; i < ale->params.ale_entries; i++) {
 		cpsw_ale_write(ale, i, data);
 		data += ALE_ENTRY_WORDS;
 	}
+	spin_unlock_bh(&ale->lock);
 }
 EXPORT_SYMBOL_GPL(cpsw_ale_restore);
 
diff --git a/drivers/net/ethernet/ti/cpsw_ale.h b/drivers/net/ethernet/ti/cpsw_ale.h
index 87b7d1b3a34a..8e47261161fe 100644
--- a/drivers/net/ethernet/ti/cpsw_ale.h
+++ b/drivers/net/ethernet/ti/cpsw_ale.h
@@ -96,6 +96,8 @@ struct cpsw_ale {
 	u32			vlan_field_bits;
 	unsigned long		*p0_untag_vid_mask;
 	const struct ale_entry_fld *vlan_entry_tbl;
+	/* serializes access to the ALE table registers */
+	spinlock_t		lock;
 };
 
 enum cpsw_ale_control {

---
base-commit: ef3e21c61baa74e39a49b75318bd4541562ec43f
change-id: 20261126-cpsw-ale-lock-cc05d5bea7a0

Best regards,
--  
Manuel Janocha <manuel.janocha@amperfied.com>

