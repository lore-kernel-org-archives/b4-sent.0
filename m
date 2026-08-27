From: Johnathan Browall <johnathan.browall@topgolf.com>
Date: Thu, 27 Aug 2026 09:11:25 +0200
Subject: [PATCH net] bnxt_en: avoid redundant RX mask updates in UC
 overflow state
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260827-bnxt-uc-overflow-v1-1-f20d48864fe9@topgolf.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMywrCMBBFf6XctQM1Yij+irhw4qSdUhJJ0geU/
 rtRl+deztmRJalk3JodSRbNGkOF86mBG56hF9JXZZjW2LYzljhshWZHcZHkp7iSv/C1q4+xzKj
 aO4nX7Ze8I0jB4z/mmUdx5RvDcXwAl7BU2HkAAAA=
X-Change-ID: 20260826-bnxt-uc-overflow-f3b5882626bb
To: Michael Chan <michael.chan@broadcom.com>, 
 Pavan Chebbi <pavan.chebbi@broadcom.com>, netdev@vger.kernel.org
Cc: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 =?utf-8?q?Pontus_H=C3=A5llstedt?= <pontus.hallstedt@topgolf.com>, 
 Johnathan Browall <johnathan.browall@topgolf.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787814691; l=5499;
 i=johnathan.browall@topgolf.com; s=20260826; h=from:subject:message-id;
 bh=4U2myiO1oDFh7prFk52MM8vNlU4NypZBLmBkndBL97o=;
 b=0KlDHFG7dkd488T0jnp+ZyUQ2EuxyAZh34SuX9VDDNs+oAZAjWPvl4WKWB7k5rD9mj0sbtNdp
 ahyVEujONtsBRlkZBP9x50fbZFmTQSSafnBfORH33KLacWMmLTM5tmZ
X-Developer-Key: i=johnathan.browall@topgolf.com; a=ed25519;
 pk=w6Hvfd81SFSs3dF3Kpe2Y17SpDtiKU3eXu0RdWOCnZk=
X-Endpoint-Received: by B4 Relay for johnathan.browall@topgolf.com/20260826 with auth_id=976
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

bnxt_cfg_rx_mode() stops programming individual L2 filters and turns
on the promiscuous bit in the VNIC rx mask when the interface has more
unicast addresses than the hardware has filter slots
(BNXT_MAX_UC_ADDRS).  The driver state never becomes consistent after
that: vnic->uc_filter_count stays at 1, so bnxt_uc_list_updated()
keeps reporting the UC list as changed on every rx-mode callback, and
bnxt_set_rx_mode() removes the promiscuous bit from the mask it
computes (it only re-adds it for IFF_PROMISC), so the mask comparison
also fails every time.

As a consequence, every rx-mode callback resends the same
HWRM_CFA_L2_SET_RX_MASK to the firmware, including for requests that
change nothing, such as setting a link flag to the value it already
has, or a macvlan going up or down.  That would only cost an
unnecessary firmware call if SET_RX_MASK processing did not affect
traffic, but on BCM57416 and BCM57504 (firmware 23.3 and 23.6) it
does: each invocation causes a short interval in which incoming
unicast traffic is dropped.  We observed this in production as
sequence gaps in GigE Vision camera streams on a PF carrying 19
secondary unicast addresses, with HWRM tracing showing a SET_RX_MASK
(and no filter alloc/free) for every repeated "ip link set ... arp on"
that changed nothing.

Fix it by recording the overflow state in a new vnic flag.  While the
flag is set, the UC list is only treated as updated once it has shrunk
enough to fit the available filters (the content of the list does not
matter while all unicast is accepted through promiscuous mode), and
bnxt_set_rx_mode() keeps the promiscuous bit in the mask, subject to
the same bnxt_promisc_ok() check that bnxt_cfg_rx_mode() applies.
bnxt_cfg_rx_mode() sets the flag when the list does not fit and clears
it, together with the promiscuous bit, when the list fits again.

An unchanged rx mode no longer causes any firmware call, and neither do
UC list changes that stay above the limit.  Crossing the limit and
real changes to the flags or the MC list are programmed as before.

Tested with the equivalent patch on 6.12.y on BCM57416: the repeated
SET_RX_MASK invocations no longer occur and the receive disruption is
no longer reproducible.

Fixes: c0c050c58d84 ("bnxt_en: New Broadcom ethernet driver.")
Cc: stable@vger.kernel.org
Co-developed-by: Pontus Hållstedt <pontus.hallstedt@topgolf.com>
Signed-off-by: Pontus Hållstedt <pontus.hallstedt@topgolf.com>
Signed-off-by: Johnathan Browall <johnathan.browall@topgolf.com>
---
 drivers/net/ethernet/broadcom/bnxt/bnxt.c | 21 +++++++++++++++++++++
 drivers/net/ethernet/broadcom/bnxt/bnxt.h |  1 +
 2 files changed, 22 insertions(+)

diff --git a/drivers/net/ethernet/broadcom/bnxt/bnxt.c b/drivers/net/ethernet/broadcom/bnxt/bnxt.c
index 9c2cc5027..4805ee63e 100644
--- a/drivers/net/ethernet/broadcom/bnxt/bnxt.c
+++ b/drivers/net/ethernet/broadcom/bnxt/bnxt.c
@@ -13791,6 +13791,16 @@ static bool bnxt_uc_list_updated(struct bnxt *bp,
 	struct netdev_hw_addr *ha;
 	int off = 0;
 
+	/* In the overflow state all unicast is accepted through the
+	 * promiscuous RX mask and no secondary L2 filters are in use,
+	 * so the list only needs reprogramming once it fits the
+	 * available filters again.  Reporting an update here would
+	 * resend an identical SET_RX_MASK on every callback, which
+	 * causes brief RX packet loss on some chips.
+	 */
+	if (vnic->flags & BNXT_VNIC_UC_PROMISC_FLAG)
+		return netdev_hw_addr_list_count(uc) <= (BNXT_MAX_UC_ADDRS - 1);
+
 	if (netdev_hw_addr_list_count(uc) != (vnic->uc_filter_count - 1))
 		return true;
 
@@ -13826,6 +13836,13 @@ static int bnxt_set_rx_mode(struct net_device *dev,
 	if (dev->flags & IFF_PROMISC)
 		mask |= CFA_L2_SET_RX_MASK_REQ_MASK_PROMISCUOUS;
 
+	/* Keep the promiscuous bit while the UC list is longer than the
+	 * available L2 filters, so that an unchanged rx mode is not
+	 * treated as a mask change.
+	 */
+	if ((vnic->flags & BNXT_VNIC_UC_PROMISC_FLAG) && bnxt_promisc_ok(bp))
+		mask |= CFA_L2_SET_RX_MASK_REQ_MASK_PROMISCUOUS;
+
 	uc_update = bnxt_uc_list_updated(bp, uc);
 
 	if (dev->flags & IFF_BROADCAST)
@@ -13869,7 +13886,11 @@ static int bnxt_cfg_rx_mode(struct bnxt *bp, struct netdev_hw_addr_list *uc,
 	netif_addr_lock_bh(dev);
 	if (netdev_hw_addr_list_count(uc) > (BNXT_MAX_UC_ADDRS - 1)) {
 		vnic->rx_mask |= CFA_L2_SET_RX_MASK_REQ_MASK_PROMISCUOUS;
+		vnic->flags |= BNXT_VNIC_UC_PROMISC_FLAG;
 	} else {
+		vnic->flags &= ~BNXT_VNIC_UC_PROMISC_FLAG;
+		if (!(dev->flags & IFF_PROMISC))
+			vnic->rx_mask &= ~CFA_L2_SET_RX_MASK_REQ_MASK_PROMISCUOUS;
 		netdev_hw_addr_list_for_each(ha, uc) {
 			memcpy(vnic->uc_list + off, ha->addr, ETH_ALEN);
 			off += ETH_ALEN;
diff --git a/drivers/net/ethernet/broadcom/bnxt/bnxt.h b/drivers/net/ethernet/broadcom/bnxt/bnxt.h
index ab894f8ad..53ad39f44 100644
--- a/drivers/net/ethernet/broadcom/bnxt/bnxt.h
+++ b/drivers/net/ethernet/broadcom/bnxt/bnxt.h
@@ -1332,6 +1332,7 @@ struct bnxt_vnic_info {
 #define BNXT_VNIC_RFS_NEW_RSS_FLAG	0x10
 #define BNXT_VNIC_NTUPLE_FLAG		0x20
 #define BNXT_VNIC_RSSCTX_FLAG		0x40
+#define BNXT_VNIC_UC_PROMISC_FLAG	0x80
 	struct ethtool_rxfh_context *rss_ctx;
 	u32		vnic_id;
 	u16		default_rx_ring;

---
base-commit: f967455fb2a5a2079b9eb5823e9ccf359174bf9f
change-id: 20260826-bnxt-uc-overflow-f3b5882626bb

Best regards,
--  
Johnathan Browall <johnathan.browall@topgolf.com>

