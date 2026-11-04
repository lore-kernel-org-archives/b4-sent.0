From: Tjerk Kusters <tkusters@aweta.nl>
Date: Wed, 04 Nov 2026 07:40:05 +0100
Subject: [PATCH net v5 4/4] igb: drop AF_XDP zero-copy frames that span
 several Rx buffers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-igb-rx-ts-fix-v5-4-bf4b4367129a@aweta.nl>
References: <20261104-igb-rx-ts-fix-v5-0-bf4b4367129a@aweta.nl>
In-Reply-To: <20261104-igb-rx-ts-fix-v5-0-bf4b4367129a@aweta.nl>
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
 Kurt Kanzenbach <kurt@linutronix.de>, 
 Sriram Yagnaraman <sriram.yagnaraman@ericsson.com>
Cc: intel-wired-lan@lists.osuosl.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, bpf@vger.kernel.org, 
 Maciej Fijalkowski <maciej.fijalkowski@intel.com>, Paul Moses <p@1g4.org>, 
 stable@vger.kernel.org, Tjerk Kusters <tkusters@aweta.nl>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793774404; l=3174;
 i=tkusters@aweta.nl; s=20260619; h=from:subject:message-id;
 bh=MkRF1V1g+97bXmg40zLUInt45xqgM/uhRHUJw6aF5q4=;
 b=5tLdWEbOPlIseyGjFHZUz7pLUptV5ZFvFzMDviMEiMJn7X3oDd3o1LhwK8jL8bbyqnyzYkk/Z
 +2nppyaYkr/DjOJt/1/Vjo80CY3L4/Yrb5INyDj9uCuW0SVnCsbshDK
X-Developer-Key: i=tkusters@aweta.nl; a=ed25519;
 pk=JYRpYQ3+LrphEabgnxcbiOUpwvNP8WDDMcLzz+cwKsk=
X-Endpoint-Received: by B4 Relay for tkusters@aweta.nl/20260619 with auth_id=831
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

igb_clean_rx_irq_zc() handles every descriptor as a complete frame and
strips the inline Rx timestamp header from each of them. If a frame
spans several descriptors, the AF_XDP socket gets its later buffers as
separate packets without headers. If such a buffer is shorter than the
header, the size wraps and the XDP program sees data past data_end. On
XDP_PASS, igb_construct_skb_zc() then fails to allocate an skb, and the
queue can stall on that descriptor.

The previous patches make sure that frames fit in one buffer while XDP
is attached. As ixgbe does, also drop any frame that still spans several
descriptors instead of passing its buffers on: free the buffers without
EOP, and the EOP buffer that ends such a frame. The state is kept in a
ring flag, as a frame can be split over two NAPI polls.

This depends on the previous patch. Without it, every full-size frame
on 2 KiB chunks spans two buffers and would be dropped.

Not reproduced on hardware, as with the previous patches the I350 no
longer splits frames in zero-copy mode.

Fixes: 2c6196013f84 ("igb: Add AF_XDP zero-copy Rx support")
Cc: stable@vger.kernel.org
Signed-off-by: Tjerk Kusters <tkusters@aweta.nl>
---
 drivers/net/ethernet/intel/igb/igb.h     |  1 +
 drivers/net/ethernet/intel/igb/igb_xsk.c | 23 +++++++++++++++++++++++
 2 files changed, 24 insertions(+)

diff --git a/drivers/net/ethernet/intel/igb/igb.h b/drivers/net/ethernet/intel/igb/igb.h
index 0495c02544d6..6613ea0eedb8 100644
--- a/drivers/net/ethernet/intel/igb/igb.h
+++ b/drivers/net/ethernet/intel/igb/igb.h
@@ -393,6 +393,7 @@ enum e1000_ring_flags_t {
 	IGB_RING_FLAG_TX_DETECT_HANG,
 	IGB_RING_FLAG_TX_DISABLED,
 	IGB_RING_FLAG_RX_ALLOC_FAILED,
+	IGB_RING_FLAG_RX_XSK_DISCARD,
 };
 
 #define ring_uses_large_buffer(ring) \
diff --git a/drivers/net/ethernet/intel/igb/igb_xsk.c b/drivers/net/ethernet/intel/igb/igb_xsk.c
index fb04df82272a..7b098069fff2 100644
--- a/drivers/net/ethernet/intel/igb/igb_xsk.c
+++ b/drivers/net/ethernet/intel/igb/igb_xsk.c
@@ -269,6 +269,8 @@ void igb_clean_rx_ring_zc(struct igb_ring *rx_ring)
 	u16 ntc = rx_ring->next_to_clean;
 	u16 ntu = rx_ring->next_to_use;
 
+	clear_bit(IGB_RING_FLAG_RX_XSK_DISCARD, &rx_ring->flags);
+
 	while (ntc != ntu) {
 		struct xdp_buff *xdp = rx_ring->rx_buffer_info_zc[ntc];
 
@@ -390,6 +392,27 @@ int igb_clean_rx_irq_zc(struct igb_q_vector *q_vector,
 		dma_rmb();
 
 		xdp = rx_ring->rx_buffer_info_zc[ntc];
+
+		/* A frame should never span several buffers here, see
+		 * igb_xsk_frame_fits(). If one does, drop all its buffers.
+		 */
+		if (unlikely(!igb_test_staterr(rx_desc, E1000_RXD_STAT_EOP) ||
+			     test_bit(IGB_RING_FLAG_RX_XSK_DISCARD,
+				      &rx_ring->flags))) {
+			if (igb_test_staterr(rx_desc, E1000_RXD_STAT_EOP))
+				clear_bit(IGB_RING_FLAG_RX_XSK_DISCARD,
+					  &rx_ring->flags);
+			else
+				set_bit(IGB_RING_FLAG_RX_XSK_DISCARD,
+					&rx_ring->flags);
+
+			xsk_buff_free(xdp);
+			ntc++;
+			if (ntc == rx_ring->count)
+				ntc = 0;
+			continue;
+		}
+
 		xsk_buff_set_size(xdp, size);
 		xsk_buff_dma_sync_for_cpu(xdp);
 

-- 
2.27.0

