From: =?utf-8?q?Dominik_Dvo=C5=99=C3=A1k?= <Dominik.Dvorak@econ.muni.cz>
Date: Mon, 09 Nov 2026 09:24:10 +0100
Subject: [PATCH iwl-net v2] ice: fix Rx byte accounting for dropped XDP
 frames
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261109-ice-xdp-rx-bytes-v2-1-7d6035e687e2@econ.muni.cz>
X-B4-Tracking: v=1; b=H4sIACmD8WoC/3WNwQ6CMBBEf4Xs2SW0CCSe/A/DobSrbKItaWstE
 v7dhruHObxM5s0GgTxTgEu1gafEgZ0tIE8V6FnZByGbwiAb2QvRdMiaMJsFfcZpjRTwrLQqaUh
 qCWW2eLpzPpQ34M8TLUUYSzFziM6vx1USR/3fmgQK7Fujhqmj1gz9lbSz9ettudZfGPd9/wH60
 G/KvAAAAA==
X-Change-ID: 20261105-ice-xdp-rx-bytes-4aca4ac0e2c2
To: intel-wired-lan@lists.osuosl.org
Cc: netdev@vger.kernel.org, 
 Maciej Fijalkowski <maciej.fijalkowski@intel.com>, 
 Tony Nguyen <anthony.l.nguyen@intel.com>, 
 Przemek Kitszel <przemyslaw.kitszel@intel.com>, 
 Alexander Lobakin <aleksander.lobakin@intel.com>, 
 Michal Kubiak <michal.kubiak@intel.com>, stable@vger.kernel.org, 
 =?utf-8?q?Dominik_Dvo=C5=99=C3=A1k?= <Dominik.Dvorak@econ.muni.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794212658; l=4363;
 i=Dominik.Dvorak@econ.muni.cz; s=20261105; h=from:subject:message-id;
 bh=vmGpEja47/xI/Jmt7BtvYvGqCuVgtx1xmRCp+kyKWls=;
 b=IUXEjKuIWDxIAsEwrR8yZRdNiFvc5O1T2EZAU4prXwahNs++vMgJN659Lbp2URQ/UOT7PTy0n
 i9YXxyyo62UD2CK2c3U+UETs7d+DAs3B4L55DyES1l3lQ857mr7Gljt
X-Developer-Key: i=Dominik.Dvorak@econ.muni.cz; a=ed25519;
 pk=RTZ8nGbFvBgcLsYzcjFd1S3jciozWEBDwMVtwC7jkGI=
X-Endpoint-Received: by B4 Relay for Dominik.Dvorak@econ.muni.cz/20261105 with auth_id=1418
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since the Rx path was converted to page pool and libeth, ice_run_xdp()
returns the buffer itself via libeth_xdp_return_buff() on XDP_DROP,
XDP_ABORTED and on a failed XDP_TX or XDP_REDIRECT. That helper also
sets xdp->data to NULL. ice_clean_rx_irq() then calls xdp_get_buff_len()
on the same buffer to update the Rx byte counter, which evaluates
xdp->data_end - NULL and adds the low 32 bits of a kernel address to
the ring's byte counter for every such frame. For multi-buffer frames
it would also read skb_shared_info from a page that has already been
returned to the page pool.

On an E810 with an XDP blocklist attached to an 802.3ad bond, this shows
up as jumps of up to 4 GiB in the per-queue and netdev rx_bytes counters,
one per dropped packet, while the packet counters and the hardware byte
counter (rx_bytes.nic) stay correct. The bogus values are also exposed
to unprivileged users through the netdev statistics.

Count the frame length once, before running the XDP program, and use it
for the byte counter on every path; this also drops the duplicate
skb->len accounting that the XDP_PASS path did afterwards. The frame
length as received is counted, rather than the length after a possible
bpf_xdp_adjust_head()/bpf_xdp_adjust_tail().

The problem was tracked down and this fix written with the help of
Claude Opus 5.5 (Anthropic), working from netdev and ethtool counters
collected on the affected system and from the driver source.

Tested on an E810-XXV (7.0.14 kernel, same code as current master) with
an XDP blocklist attached to an 802.3ad bond: without the fix, each
dropped packet added about 2.5 GB to rx_queue_N_bytes; with the fix, 40
dropped packets produced no such jumps.

Fixes: 93f53db9f9dc ("ice: switch to Page Pool")
Cc: stable@vger.kernel.org # 6.18.x
Link: https://lore.kernel.org/netdev/DB7PR03MB460158B90A64D025962670E0D5772@DB7PR03MB4601.eurprd03.prod.outlook.com/
Signed-off-by: Dominik Dvořák <Dominik.Dvorak@econ.muni.cz>
---
Based on the stable v7.0.14 tree, which is what the affected box runs;
the changed code is identical in current master. Tested on that box
with the fixed module built against the 7.0.14-26-pve headers.
---
Changes in v2:
- Account for Rx bytes and packets once, before ice_run_xdp(), and drop
  the separate skb->len accounting on the XDP_PASS path (Olek).
- Add Cc: stable with the minimum affected version (Olek).
---
 drivers/net/ethernet/intel/ice/ice_txrx.c | 15 +++++++--------
 1 file changed, 7 insertions(+), 8 deletions(-)

diff --git a/drivers/net/ethernet/intel/ice/ice_txrx.c b/drivers/net/ethernet/intel/ice/ice_txrx.c
index 4ca1a0602307d076153f77671e8c9a6ff4f8dd28..8e4cda9a34b673a6c5a75e5aa7492c18bb0f3f19 100644
--- a/drivers/net/ethernet/intel/ice/ice_txrx.c
+++ b/drivers/net/ethernet/intel/ice/ice_txrx.c
@@ -1028,14 +1028,19 @@ static int ice_clean_rx_irq(struct ice_rx_ring *rx_ring, int budget)
 		if (ice_is_non_eop(rx_ring, rx_desc) || unlikely(!xdp->data))
 			continue;
 
+		/* Account for Rx bytes here, before ice_run_xdp() may free the
+		 * buffer and clear xdp->data; the XDP and skb paths share the
+		 * same length.
+		 */
+		total_rx_bytes += xdp_get_buff_len(&xdp->base);
+		total_rx_pkts++;
+
 		xdp_verdict = ice_run_xdp(rx_ring, xdp, xdp_prog, xdp_ring, rx_desc);
 		if (xdp_verdict == ICE_XDP_PASS)
 			goto construct_skb;
 
 		if (xdp_verdict & (ICE_XDP_TX | ICE_XDP_REDIR))
 			xdp_xmit |= xdp_verdict;
-		total_rx_bytes += xdp_get_buff_len(&xdp->base);
-		total_rx_pkts++;
 
 		xdp->data = NULL;
 		continue;
@@ -1053,18 +1058,12 @@ static int ice_clean_rx_irq(struct ice_rx_ring *rx_ring, int budget)
 
 		vlan_tci = ice_get_vlan_tci(rx_desc);
 
-		/* probably a little skewed due to removing CRC */
-		total_rx_bytes += skb->len;
-
 		/* populate checksum, VLAN, and protocol */
 		ice_process_skb_fields(rx_ring, rx_desc, skb);
 
 		ice_trace(clean_rx_irq_indicate, rx_ring, rx_desc, skb);
 		/* send completed skb up the stack */
 		ice_receive_skb(rx_ring, skb, vlan_tci);
-
-		/* update budget accounting */
-		total_rx_pkts++;
 	}
 
 	rx_ring->next_to_clean = ntc;

---
base-commit: 458c6079fc1d41d564c37679c8ace02cd83ee817
change-id: 20261105-ice-xdp-rx-bytes-4aca4ac0e2c2

Best regards,
-- 
Dominik Dvořák <Dominik.Dvorak@econ.muni.cz>

