From: =?utf-8?q?Dominik_Dvo=C5=99=C3=A1k?= <Dominik.Dvorak@econ.muni.cz>
Date: Thu, 05 Nov 2026 14:21:15 +0100
Subject: [PATCH iwl-net] ice: fix Rx byte accounting for dropped XDP frames
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261105-ice-xdp-rx-bytes-v1-1-63da7b5e3d76@econ.muni.cz>
X-B4-Tracking: v=1; b=H4sIAMqC7GoC/x2MQQ5AMBQFryJ/7Sdtg4WriEXVw0+kpBUq4u4ai
 1nMYuahiCCI1BYPBZwSZfNZdFmQW6yfwTJmJ6NMo7WqWRw4jTuHxMN9IHJlnc0oGGcoZ3vAJOl
 fdiTXyh4H9e/7AYxXQEFrAAAA
X-Change-ID: 20261105-ice-xdp-rx-bytes-4aca4ac0e2c2
To: intel-wired-lan@lists.osuosl.org
Cc: netdev@vger.kernel.org, 
 Maciej Fijalkowski <maciej.fijalkowski@intel.com>, 
 Tony Nguyen <anthony.l.nguyen@intel.com>, 
 Przemek Kitszel <przemyslaw.kitszel@intel.com>, 
 Alexander Lobakin <aleksander.lobakin@intel.com>, 
 Michal Kubiak <michal.kubiak@intel.com>, 
 =?utf-8?q?Dominik_Dvo=C5=99=C3=A1k?= <Dominik.Dvorak@econ.muni.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793884909; l=3624;
 i=Dominik.Dvorak@econ.muni.cz; s=20261105; h=from:subject:message-id;
 bh=jfrNnQ7InY4Nb94BiB/3wT4b52lrC1Z8QEHRLs4bn90=;
 b=6zN3cKhm2x0ywzitDLLbqyMLnFFkq/laCYFenPD5EbBny9wxp05fhN6XuGjklEkEP2T03OLO4
 1Bggsv2bG6XBqLSi8kQtuZJMGbmNlzKK/IFJaBdjD3UDUxpH6LEUu5L
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

Take the frame length before running the XDP program and use it for the
byte counter. For XDP_TX and XDP_REDIRECT this means the length of the
frame as received is counted, rather than the length after a possible
bpf_xdp_adjust_head()/bpf_xdp_adjust_tail().

The problem was tracked down and this fix written with the help of
Claude Opus 5.5 (Anthropic), working from netdev and ethtool counters
collected on the affected system and from the driver source.

Tested on an E810-XXV (7.0.14 kernel, same code as current master) with
an XDP blocklist attached to an 802.3ad bond: without the fix, each
dropped packet added about 2.5 GB to rx_queue_N_bytes; with the fix, 40
dropped packets produced no such jumps.

Fixes: 93f53db9f9dc ("ice: switch to Page Pool")
Link: https://lore.kernel.org/netdev/DB7PR03MB460158B90A64D025962670E0D5772@DB7PR03MB4601.eurprd03.prod.outlook.com/
Signed-off-by: Dominik Dvořák <Dominik.Dvorak@econ.muni.cz>
---
Based on the stable v7.0.14 tree, which is what the affected box runs;
the changed code is identical in current master. Tested on that box
with the fixed module built against the 7.0.14-26-pve headers.
---
 drivers/net/ethernet/intel/ice/ice_txrx.c | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/drivers/net/ethernet/intel/ice/ice_txrx.c b/drivers/net/ethernet/intel/ice/ice_txrx.c
index 4ca1a0602307d076153f77671e8c9a6ff4f8dd28..f62a1bb7bbca579b43fe2f4c8e1946e65b5cea63 100644
--- a/drivers/net/ethernet/intel/ice/ice_txrx.c
+++ b/drivers/net/ethernet/intel/ice/ice_txrx.c
@@ -968,7 +968,7 @@ static int ice_clean_rx_irq(struct ice_rx_ring *rx_ring, int budget)
 		union ice_32b_rx_flex_desc *rx_desc;
 		struct libeth_fqe *rx_buf;
 		struct sk_buff *skb;
-		unsigned int size;
+		unsigned int size, len;
 		u16 stat_err_bits;
 		u16 vlan_tci;
 		bool rxe;
@@ -1028,13 +1028,16 @@ static int ice_clean_rx_irq(struct ice_rx_ring *rx_ring, int budget)
 		if (ice_is_non_eop(rx_ring, rx_desc) || unlikely(!xdp->data))
 			continue;
 
+		/* ice_run_xdp() may free the buffer and clear xdp->data */
+		len = xdp_get_buff_len(&xdp->base);
+
 		xdp_verdict = ice_run_xdp(rx_ring, xdp, xdp_prog, xdp_ring, rx_desc);
 		if (xdp_verdict == ICE_XDP_PASS)
 			goto construct_skb;
 
 		if (xdp_verdict & (ICE_XDP_TX | ICE_XDP_REDIR))
 			xdp_xmit |= xdp_verdict;
-		total_rx_bytes += xdp_get_buff_len(&xdp->base);
+		total_rx_bytes += len;
 		total_rx_pkts++;
 
 		xdp->data = NULL;

---
base-commit: 458c6079fc1d41d564c37679c8ace02cd83ee817
change-id: 20261105-ice-xdp-rx-bytes-4aca4ac0e2c2

Best regards,
-- 
Dominik Dvořák <Dominik.Dvorak@econ.muni.cz>

