From: Tjerk Kusters <tkusters@aweta.nl>
Date: Mon, 02 Nov 2026 10:58:13 +0100
Subject: [PATCH net v4 1/2] igb: do not let XDP frames span more than one
 Rx buffer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261102-igb-rx-ts-fix-v4-1-8785124c5d23@aweta.nl>
References: <20261102-igb-rx-ts-fix-v4-0-8785124c5d23@aweta.nl>
In-Reply-To: <20261102-igb-rx-ts-fix-v4-0-8785124c5d23@aweta.nl>
To: Tony Nguyen <anthony.l.nguyen@intel.com>, 
 Przemek Kitszel <przemyslaw.kitszel@intel.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Alexei Starovoitov <ast@kernel.org>, Daniel Borkmann <daniel@iogearbox.net>, 
 Jesper Dangaard Brouer <hawk@kernel.org>, 
 John Fastabend <john.fastabend@gmail.com>, 
 Stanislav Fomichev <sdf@fomichev.me>, 
 Sven Auhagen <sven.auhagen@voleatech.de>, 
 Richard Cochran <richardcochran@gmail.com>, 
 Kurt Kanzenbach <kurt@linutronix.de>
Cc: intel-wired-lan@lists.osuosl.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, bpf@vger.kernel.org, 
 Maciej Fijalkowski <maciej.fijalkowski@intel.com>, Paul Moses <p@1g4.org>, 
 stable@vger.kernel.org, Tjerk Kusters <tkusters@aweta.nl>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793616473; l=5817;
 i=tkusters@aweta.nl; s=20260619; h=from:subject:message-id;
 bh=oeKPSFBLrPdgnpDjeb+PUB1eK71EhR4L/FqRyXpHCrM=;
 b=lNhogHtFrSl1tX+7vv+jRZAbbu0JyuYTp3P27fnxY514h5UT6bBIxPcHrMz2EZ/oHYct7OIZZ
 MosTg0j0OnnC45q9wWDlCDpB8I48toks5VIpFW2v1NMBanHsZX8qGHH
X-Developer-Key: i=tkusters@aweta.nl; a=ed25519;
 pk=JYRpYQ3+LrphEabgnxcbiOUpwvNP8WDDMcLzz+cwKsk=
X-Endpoint-Received: by B4 Relay for tkusters@aweta.nl/20260619 with auth_id=831
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

igb does not support XDP multi-buffer: igb_xdp_setup() only accepts an
MTU whose frame fits in one Rx buffer, and the XDP program only sees
the first buffer of a frame. The maximum receive length is not limited
accordingly, though. RLPML is only lowered when the frame fits a build_skb
buffer on systems with PAGE_SIZE < 8192 and no VFs, and the PF pool limit
in VMOLR is set the same way. Otherwise the MAC still accepts frames of
up to MAX_JUMBO_FRAME_SIZE while XDP is attached, for example at MTU
3000, at any MTU when PAGE_SIZE >= 8192, or when VFs are allocated.

Such frames span several descriptors. When the program does not return
XDP_PASS for the first buffer, no skb is built, and igb_clean_rx_irq()
handles the next buffer of the same frame as the start of a new frame:
it runs the program on it and may pass it to the stack as a bogus frame
made from the middle of the original payload.

Limit the receive length to the configured maximum frame size while XDP
is attached: in RLPML when no VFs are allocated, and in the PF pool's
VMOLR otherwise, as RLPML then has to stay large for the VFs. Larger
frames are dropped by the MAC. Also leave room for the inline Rx
timestamp header when checking that the frame fits in one Rx buffer, on
XDP setup and on MTU change; this lowers the largest MTU accepted with
XDP on 3 KiB buffers by 16 bytes.

Both registers are programmed from igb_set_rx_mode(), which
igb_configure() calls, and attaching or removing an XDP program on a
running interface goes through igb_close() and igb_open(), as does an
MTU change.

This follows the same approach as the igc fix that limits RLPML while
XDP is attached.

Tested on an I350 at MTU 3000 with Rx timestamping on and xdp-filter
dropping all IPv4 from the peer: 8242-byte frames are now dropped by the
MAC (rx_long_length_errors), instead of their last two buffers being
delivered as a separate frame. XDP attach at MTU 3030 still works, at
MTU 3046 it is refused, as is an MTU change from 3030 to 3046 with XDP
attached.

With two VFs allocated, the same frames are counted by the MAC but
dropped by the PF pool limit in VMOLR before they reach the Rx queue;
without this patch their last two buffers are again delivered as a
separate frame.

Link: https://lore.kernel.org/all/20261028083344.3047350-3-p@1g4.org/
Fixes: 9cbc948b5a20 ("igb: add XDP support")
Cc: stable@vger.kernel.org
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Tjerk Kusters <tkusters@aweta.nl>
---
 drivers/net/ethernet/intel/igb/igb_main.c | 30 +++++++++++++++++++++---------
 1 file changed, 21 insertions(+), 9 deletions(-)

diff --git a/drivers/net/ethernet/intel/igb/igb_main.c b/drivers/net/ethernet/intel/igb/igb_main.c
index ce91dda00ec0..5bf489cd7b06 100644
--- a/drivers/net/ethernet/intel/igb/igb_main.c
+++ b/drivers/net/ethernet/intel/igb/igb_main.c
@@ -2894,11 +2894,13 @@ static int igb_xdp_setup(struct net_device *dev, struct netdev_bpf *bpf)
 	bool running = netif_running(dev);
 	bool need_reset;
 
-	/* verify igb ring attributes are sufficient for XDP */
+	/* verify igb ring attributes are sufficient for XDP, leaving room
+	 * for the inline Rx timestamp header
+	 */
 	for (i = 0; i < adapter->num_rx_queues; i++) {
 		struct igb_ring *ring = adapter->rx_ring[i];
 
-		if (frame_size > igb_rx_bufsz(ring)) {
+		if (frame_size + IGB_TS_HDR_LEN > igb_rx_bufsz(ring)) {
 			NL_SET_ERR_MSG_MOD(bpf->extack,
 					   "The RX buffer size is too small for the frame size");
 			netdev_warn(dev, "XDP RX buffer size %d is too small for the frame size %d\n",
@@ -5324,6 +5326,7 @@ static void igb_set_rx_mode(struct net_device *netdev)
 	struct e1000_hw *hw = &adapter->hw;
 	unsigned int vfn = adapter->vfs_allocated_count;
 	u32 rctl = 0, vmolr = 0, rlpml = MAX_JUMBO_FRAME_SIZE;
+	u32 pool_rlpml;
 	int count;
 
 	/* Check for Promiscuous and All Multicast modes */
@@ -5386,6 +5389,12 @@ static void igb_set_rx_mode(struct net_device *netdev)
 			rlpml = IGB_MAX_FRAME_BUILD_SKB;
 	}
 #endif
+	/* XDP does not support frames that span more than one Rx buffer.
+	 * With VFs the global limit stays large and the PF pool is limited
+	 * through VMOLR below.
+	 */
+	if (!adapter->vfs_allocated_count && igb_xdp_is_enabled(adapter))
+		rlpml = min_t(u32, rlpml, adapter->max_frame_size);
 	wr32(E1000_RLPML, rlpml);
 
 	/* In order to support SR-IOV and eventually VMDq it is necessary to set
@@ -5402,15 +5411,18 @@ static void igb_set_rx_mode(struct net_device *netdev)
 	vmolr |= rd32(E1000_VMOLR(vfn)) &
 		 ~(E1000_VMOLR_ROPE | E1000_VMOLR_MPME | E1000_VMOLR_ROMPE);
 
-	/* enable Rx jumbo frames, restrict as needed to support build_skb */
-	vmolr &= ~E1000_VMOLR_RLPML_MASK;
+	/* enable Rx jumbo frames, restrict as needed to support build_skb
+	 * and XDP
+	 */
+	pool_rlpml = MAX_JUMBO_FRAME_SIZE;
 #if (PAGE_SIZE < 8192)
 	if (adapter->max_frame_size <= IGB_MAX_FRAME_BUILD_SKB)
-		vmolr |= IGB_MAX_FRAME_BUILD_SKB;
-	else
+		pool_rlpml = IGB_MAX_FRAME_BUILD_SKB;
 #endif
-		vmolr |= MAX_JUMBO_FRAME_SIZE;
-	vmolr |= E1000_VMOLR_LPE;
+	if (igb_xdp_is_enabled(adapter))
+		pool_rlpml = min_t(u32, pool_rlpml, adapter->max_frame_size);
+	vmolr &= ~E1000_VMOLR_RLPML_MASK;
+	vmolr |= pool_rlpml | E1000_VMOLR_LPE;
 
 	wr32(E1000_VMOLR(vfn), vmolr);
 
@@ -6713,7 +6725,7 @@ static int igb_change_mtu(struct net_device *netdev, int new_mtu)
 		for (i = 0; i < adapter->num_rx_queues; i++) {
 			struct igb_ring *ring = adapter->rx_ring[i];
 
-			if (max_frame > igb_rx_bufsz(ring)) {
+			if (max_frame + IGB_TS_HDR_LEN > igb_rx_bufsz(ring)) {
 				netdev_warn(adapter->netdev,
 					    "Requested MTU size is not supported with XDP. Max frame size is %d\n",
 					    max_frame);

-- 
2.27.0

