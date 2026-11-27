From: Tjerk Kusters <tkusters@aweta.nl>
Date: Fri, 27 Nov 2026 09:43:59 +0100
Subject: [PATCH net] igb: leave room for the Rx timestamp header in 2 KiB
 build_skb buffers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-igb-skb-pad-v1-1-7e069eaf16d7@aweta.nl>
X-B4-Tracking: v=1; b=H4sIAM5CCWsC/yWMwQrCMBAFf6W8cxeSgFH7K+Ihada6FmLJVhFK/
 72xPc7AzALlIqzomgWFv6LyzhVs26B/hjwwSaoMZ5y31p1Jhkg6RppCoku6eg4meDYn1GIq/JD
 ffrsh84z7IfUTX9zP/w/WdQMLR1Z2dAAAAA==
X-Change-ID: 20261127-igb-skb-pad-8d96ea0a6e05
To: Tony Nguyen <anthony.l.nguyen@intel.com>, 
 Przemek Kitszel <przemyslaw.kitszel@intel.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Alexei Starovoitov <ast@kernel.org>, Daniel Borkmann <daniel@iogearbox.net>, 
 Jesper Dangaard Brouer <hawk@kernel.org>, 
 John Fastabend <john.fastabend@gmail.com>, 
 Stanislav Fomichev <sdf@fomichev.me>, 
 Sven Auhagen <sven.auhagen@voleatech.de>
Cc: intel-wired-lan@lists.osuosl.org, netdev@vger.kernel.org, 
 bpf@vger.kernel.org, stable@vger.kernel.org, 
 Tjerk Kusters <tkusters@aweta.nl>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795769042; l=7109;
 i=tkusters@aweta.nl; s=20260619; h=from:subject:message-id;
 bh=LHZjkEOidXK7kx+tT6vj/G3tkhiPxIUoim+0JCqFf24=;
 b=AEkgnroG0gFyvAxAf2gDtHDf0wW2hJiBZV8LFjagw2b1mNptyxATLN3Htuf4uOhCZNK1fOU1e
 ipDBqw2GDHqAhCAz9ML1zYapEPSHFJVzaKpQXXJQtNZE9v4CGCfgbmN
X-Developer-Key: i=tkusters@aweta.nl; a=ed25519;
 pk=JYRpYQ3+LrphEabgnxcbiOUpwvNP8WDDMcLzz+cwKsk=
X-Endpoint-Received: by B4 Relay for tkusters@aweta.nl/20260619 with auth_id=831
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On 2 KiB build_skb Rx rings (PAGE_SIZE < 8192, legacy-rx off),
igb_skb_pad() places the DMA start so that exactly
IGB_MAX_FRAME_BUILD_SKB bytes (1536 on x86_64) are left before
skb_shared_info, and RLPML, or the PF pool limit in VMOLR when VFs are
allocated, is set to the same value. With Rx timestamping on, 82580 and
later MACs write a 16-byte timestamp header in front of the frame, so a
frame of more than 1520 bytes (without FCS) runs into skb_shared_info.
napi_build_skb() then zeroes the start of skb_shared_info, which holds
the last bytes of the frame, and __skb_put() moves skb->tail past
skb->end.

The MAC has checked the TCP or UDP checksum before that, so the payload
is delivered with its last bytes zeroed and without an error. Any
sender on the link can trigger this with frames of 1525 to 1536 bytes on
the wire, for example double-tagged frames or a peer with a larger MTU.
Any Rx timestamp filter is enough, as these MACs then timestamp all
packets. With XDP_TX, or XDP_REDIRECT to a device or CPU map,
xdp_update_frame_from_buff() hits the "missing reserved tailroom" WARN
for each such frame and drops it.

Before commit 9cbc948b5a20 ("igb: add XDP support"),
IGB_MAX_FRAME_BUILD_SKB left room for the header. That commit fixed the
frame size at 1536 bytes and gave the rest of the 2 KiB buffer to the
headroom. Reserve the header again in igb_skb_pad(). IGB_SKB_PAD is the
same for all build_skb rings, so the headroom goes from 192 to 176 bytes
on x86_64 for 2 KiB and for 3 KiB rings, and XDP programs have 16 bytes
less for bpf_xdp_adjust_head() and metadata. It was already below
XDP_PACKET_HEADROOM. The frame limit, the buffer size selection and the
MTU range for XDP do not change. IGB_2K_TOO_SMALL_WITH_PADDING already
counts the header, so the headroom stays at least NET_SKB_PAD.

That commit also took the header out of igb_rx_bufsz(), which is the
length of the DMA sync when a buffer goes to the hardware. Add
igb_rx_dma_len() for the two syncs. igb_rx_bufsz() itself stays as it
is, because it is also the frame size limit for XDP.

Tested on an I350 with kernel 7.3.1 (igb in net is the same apart from
the treewide kmalloc_obj conversions) at MTU 1500, with the Rx timestamp
filter set to ALL. A peer sent UDP datagrams of 0xff bytes in frames of
1521 to 1532 bytes (without FCS). Before this patch they were delivered
with their last 1 to 12 bytes zeroed, starting 1520 bytes into the
frame, and pings with a 0xff pattern of those sizes failed. With this
patch all of them arrive intact, also with an XDP program attached.
Frames of 1533 bytes and more are dropped by the MAC, as before. With
the timestamp filter off, and at MTU 3000 (3 KiB rings), nothing
changes. Frames that a VF sends to the PF, of up to 1536 bytes, arrive
intact with and without this patch; the MAC does not put the header in
front of them.

This was found by the Sashiko AI review of another igb series.

Link: https://lore.kernel.org/all/179551973551.3135.7270095499525377709@kernel.org/
Fixes: 9cbc948b5a20 ("igb: add XDP support")
Cc: stable@vger.kernel.org
Signed-off-by: Tjerk Kusters <tkusters@aweta.nl>
---
The Sashiko AI review reported this on v4 to v7 of my igb Rx timestamp
series; it is older than that series. Most recently:
https://lore.kernel.org/all/179551973551.3135.7270095499525377709@kernel.org/

This patch is independent of that series and applies on its own.

At MTU 1500, iperf3 TCP and UDP from a peer run at line rate (938 and
950 Mbit/s) with and without this patch, with the Rx timestamp filter
off and on, and the receiver's CPU load does not change measurably
(6 runs of 10 s per case, the differences are within the spread).

The patch and its description were prepared with the help of an AI
coding assistant (Claude). I reviewed them and ran the tests described in
the commit message on my test bench.
---
 drivers/net/ethernet/intel/igb/igb.h      | 21 +++++++++++++++++----
 drivers/net/ethernet/intel/igb/igb_main.c |  4 ++--
 2 files changed, 19 insertions(+), 6 deletions(-)

diff --git a/drivers/net/ethernet/intel/igb/igb.h b/drivers/net/ethernet/intel/igb/igb.h
index 8c9b02058cec..74e441a140c1 100644
--- a/drivers/net/ethernet/intel/igb/igb.h
+++ b/drivers/net/ethernet/intel/igb/igb.h
@@ -153,9 +153,9 @@ struct vf_mac_filter {
 
 /* Attempt to maximize the headroom available for incoming frames.  We
  * use a 2K buffer for receives and need 1536/1534 to store the data for
- * the frame.  This leaves us with 512 bytes of room.  From that we need
- * to deduct the space needed for the shared info and the padding needed
- * to IP align the frame.
+ * the frame, plus IGB_TS_HDR_LEN for the timestamp the hardware can place
+ * in front of it.  From the rest we need to deduct the space needed for
+ * the shared info and the padding needed to IP align the frame.
  *
  * Note: For cache line sizes 256 or larger this value is going to end
  *	 up negative.  In these cases we should fall back to the 3K
@@ -190,7 +190,7 @@ static inline int igb_skb_pad(void)
 	if (IGB_2K_TOO_SMALL_WITH_PADDING)
 		rx_buf_len = IGB_RXBUFFER_3072 + SKB_DATA_ALIGN(NET_IP_ALIGN);
 	else
-		rx_buf_len = IGB_RXBUFFER_1536;
+		rx_buf_len = IGB_RXBUFFER_1536 + IGB_TS_HDR_LEN;
 
 	/* if needed make room for NET_IP_ALIGN */
 	rx_buf_len -= NET_IP_ALIGN;
@@ -421,6 +421,19 @@ static inline unsigned int igb_rx_bufsz(struct igb_ring *ring)
 	return IGB_RXBUFFER_2048;
 }
 
+/* Number of bytes the hardware can write to an Rx buffer. On 2K build_skb
+ * rings the frame is limited to IGB_MAX_FRAME_BUILD_SKB, and the timestamp
+ * header comes in front of it.
+ */
+static inline unsigned int igb_rx_dma_len(struct igb_ring *ring)
+{
+#if (PAGE_SIZE < 8192)
+	if (ring_uses_build_skb(ring) && !ring_uses_large_buffer(ring))
+		return IGB_MAX_FRAME_BUILD_SKB + IGB_TS_HDR_LEN;
+#endif
+	return igb_rx_bufsz(ring);
+}
+
 static inline unsigned int igb_rx_pg_order(struct igb_ring *ring)
 {
 #if (PAGE_SIZE < 8192)
diff --git a/drivers/net/ethernet/intel/igb/igb_main.c b/drivers/net/ethernet/intel/igb/igb_main.c
index 131df3e09ba1..67fd24d71746 100644
--- a/drivers/net/ethernet/intel/igb/igb_main.c
+++ b/drivers/net/ethernet/intel/igb/igb_main.c
@@ -5084,7 +5084,7 @@ void igb_clean_rx_ring(struct igb_ring *rx_ring)
 		dma_sync_single_range_for_cpu(rx_ring->dev,
 					      buffer_info->dma,
 					      buffer_info->page_offset,
-					      igb_rx_bufsz(rx_ring),
+					      igb_rx_dma_len(rx_ring),
 					      DMA_FROM_DEVICE);
 
 		/* free resources associated with mapping */
@@ -9225,7 +9225,7 @@ void igb_alloc_rx_buffers(struct igb_ring *rx_ring, u16 cleaned_count)
 	bi = &rx_ring->rx_buffer_info[i];
 	i -= rx_ring->count;
 
-	bufsz = igb_rx_bufsz(rx_ring);
+	bufsz = igb_rx_dma_len(rx_ring);
 
 	do {
 		if (!igb_alloc_mapped_page(rx_ring, bi))

---
base-commit: cc7fe6e741730fef549e484379281736d32746f0
change-id: 20261127-igb-skb-pad-8d96ea0a6e05

Best regards,
--  
Tjerk Kusters <tkusters@aweta.nl>

