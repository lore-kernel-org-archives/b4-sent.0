From: Johnathan Browall <johnathan.browall@topgolf.com>
Date: Tue, 01 Sep 2026 14:46:47 +0200
Subject: [PATCH net v3] bnxt_en: avoid redundant RX mask updates in UC
 overflow state
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260901-bnxt-uc-overflow-v3-1-2ea7c42c013c@topgolf.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NwRKCIBRFf8VhHQ2iEbXqP5oWAg+lMXEAycbx3
 1NqUVPL+96950zIgzPg0TGbkINovLHdEopNhmRTdTVgo5aMKKGMcMqw6MaAB4ltBKdbe8e6EDu
 +fCgTAi2z3oE2Y0KeUQcBXV5HP4gryLDC1lpjfLDukcQxT+W3Y//riDnOsaZElZyzUsPhFGxf2
 1Zvpb0lQaSfCP4HQVdEpZTMmSBQkW/EPM9PItzk/QwBAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788266822; l=8587;
 i=johnathan.browall@topgolf.com; s=20260826; h=from:subject:message-id;
 bh=JXa4L36f5k63XQR1//4sj+78c5sshjpWcD0nSiXaRxY=;
 b=ZnZZ6ZCn2hG6aXaTuLfzq91bzS+2Y7cuU5kZqp9rVJ5L+LY8/3xOKkaIdnsGPOl3I6u6OkrZ/
 OMq1xnC2t8hCw6+2ZfTpOesqJ0k749NSfCr+9/X4e8O646dMz7WnyaD
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

The flag is committed only after bnxt_hwrm_cfa_l2_set_rx_mask()
succeeds, so a failed attempt leaves the state marked as changed and
the next retry or rx-mode callback programs the mask again.  This
matches the behavior before this patch, where the never-converging
state retried until the firmware accepted the mask.  Committing the
flag before the send would let a single failure end the retry
sequence with the secondary filters already freed and the promiscuous
bit not installed.

An unchanged rx mode no longer causes any firmware call, and neither do
UC list changes that stay above the limit.  Crossing the limit and
real changes to the flags or the MC list are programmed as before.

Tested with the equivalent patch on 6.12.y on BCM57416: the repeated
SET_RX_MASK invocations no longer occur and the receive disruption is
no longer reproducible.

Fixes: c0c050c58d84 ("bnxt_en: New Broadcom ethernet driver.")
Cc: stable@vger.kernel.org # needs adjustment for <= 6.18
Co-developed-by: Pontus Hållstedt <pontus.hallstedt@topgolf.com>
Signed-off-by: Pontus Hållstedt <pontus.hallstedt@topgolf.com>
Signed-off-by: Johnathan Browall <johnathan.browall@topgolf.com>
---
The review also led us to two pre-existing defects in the same area,
independent of this patch. vnic->rx_mask is committed before the
firmware send, so any failed mask-only change retries without sending
anything, including at open time. And the IFF_PROMISC branch in
bnxt_set_rx_mode() lacks the bnxt_promisc_ok() gate that the skip_uc
strip applies, so an untrusted VF with IFF_PROMISC resends an
identical mask on every callback. We plan to send fixes for both
separately after this patch is applied.

Changes in v3:
- Commit the overflow flag only after HWRM_CFA_L2_SET_RX_MASK succeeds,
  so a failed send leaves the state marked as changed and the retry or
  any later rx-mode callback programs the mask again (Paolo Abeni's
  review). Without this, a single failure while entering overflow ended
  the retry sequence with the secondary filters freed and no
  promiscuous bit installed; a failure while leaving overflow silently
  left the port promiscuous.
- Reword the comment in bnxt_uc_list_updated(): on an untrusted VF the
  promiscuous bit is not usable, so the previous wording overstated the
  state (review finding on v1).
- Drop the Reviewed-by from v2 because of the code change.
- Link to v2: https://patch.msgid.link/20260828-bnxt-uc-overflow-v2-1-faddc16b0ea0@topgolf.com

Changes in v2:
- Wrap a line exceeding 80 columns (Pavan Chebbi)
- Collect Reviewed-by (Pavan Chebbi)
- Note on the stable Cc that trees <= 6.18 need an adjusted version.
- Link to v1: https://patch.msgid.link/20260827-bnxt-uc-overflow-v1-1-f20d48864fe9@topgolf.com
---
 drivers/net/ethernet/broadcom/bnxt/bnxt.c | 42 +++++++++++++++++++++++++++++--
 drivers/net/ethernet/broadcom/bnxt/bnxt.h |  1 +
 2 files changed, 41 insertions(+), 2 deletions(-)

diff --git a/drivers/net/ethernet/broadcom/bnxt/bnxt.c b/drivers/net/ethernet/broadcom/bnxt/bnxt.c
index 9c2cc5027..1e9e86934 100644
--- a/drivers/net/ethernet/broadcom/bnxt/bnxt.c
+++ b/drivers/net/ethernet/broadcom/bnxt/bnxt.c
@@ -13791,6 +13791,16 @@ static bool bnxt_uc_list_updated(struct bnxt *bp,
 	struct netdev_hw_addr *ha;
 	int off = 0;
 
+	/* In the overflow state no secondary L2 filters are programmed
+	 * and unicast RX relies on the promiscuous mask, so the list
+	 * only needs reprogramming once it fits the available filters
+	 * again.  Reporting an update here would resend an identical
+	 * SET_RX_MASK on every callback, which causes brief RX packet
+	 * loss on some chips.
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
@@ -13853,6 +13870,9 @@ static int bnxt_cfg_rx_mode(struct bnxt *bp, struct netdev_hw_addr_list *uc,
 	struct bnxt_vnic_info *vnic = &bp->vnic_info[BNXT_VNIC_DEFAULT];
 	struct netdev_hw_addr *ha;
 	int i, off = 0, rc;
+	bool uc_promisc;
+
+	uc_promisc = !!(vnic->flags & BNXT_VNIC_UC_PROMISC_FLAG);
 
 	if (!uc_update)
 		goto skip_uc;
@@ -13869,7 +13889,12 @@ static int bnxt_cfg_rx_mode(struct bnxt *bp, struct netdev_hw_addr_list *uc,
 	netif_addr_lock_bh(dev);
 	if (netdev_hw_addr_list_count(uc) > (BNXT_MAX_UC_ADDRS - 1)) {
 		vnic->rx_mask |= CFA_L2_SET_RX_MASK_REQ_MASK_PROMISCUOUS;
+		uc_promisc = true;
 	} else {
+		uc_promisc = false;
+		if (!(dev->flags & IFF_PROMISC))
+			vnic->rx_mask &=
+				~CFA_L2_SET_RX_MASK_REQ_MASK_PROMISCUOUS;
 		netdev_hw_addr_list_for_each(ha, uc) {
 			memcpy(vnic->uc_list + off, ha->addr, ETH_ALEN);
 			off += ETH_ALEN;
@@ -13907,11 +13932,24 @@ static int bnxt_cfg_rx_mode(struct bnxt *bp, struct netdev_hw_addr_list *uc,
 		vnic->mc_list_count = 0;
 		rc = bnxt_hwrm_cfa_l2_set_rx_mask(bp, 0);
 	}
-	if (rc)
+	if (rc) {
 		netdev_err(bp->dev, "HWRM cfa l2 rx mask failure rc: %d\n",
 			   rc);
+		return rc;
+	}
 
-	return rc;
+	/* Commit the overflow state only once the mask is installed, so
+	 * that a failed attempt keeps the state marked as changed and the
+	 * next retry or rx-mode callback programs the mask again.
+	 */
+	netif_addr_lock_bh(dev);
+	if (uc_promisc)
+		vnic->flags |= BNXT_VNIC_UC_PROMISC_FLAG;
+	else
+		vnic->flags &= ~BNXT_VNIC_UC_PROMISC_FLAG;
+	netif_addr_unlock_bh(dev);
+
+	return 0;
 }
 
 static bool bnxt_can_reserve_rings(struct bnxt *bp)
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

