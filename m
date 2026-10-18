From: Michael Baikov <manpacket@gmail.com>
Date: Sun, 18 Oct 2026 17:05:21 -0400
Subject: [PATCH] net: sfc: run hardware-classified UDP packets through GRO
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261018-sfc-gro-udp-v1-1-f7bf378178f8@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDA0ML3eK0ZN30onzd0pQCXdMU41TLROMkoyRTEyWgjoKi1LTMCrBp0bG
 1tQDEDXIoXQAAAA==
X-Change-ID: 20261018-sfc-gro-udp-5d3e9a3b2b54
To: Edward Cree <ecree.xilinx@gmail.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-net-drivers@amd.com, 
 linux-kernel@vger.kernel.org, Michael Baikov <manpacket@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792357547; l=3180;
 i=manpacket@gmail.com; s=20261015; h=from:subject:message-id;
 bh=11Plzd20WV2rMhW48ZwHWAj7uVsIcTQcCnD1lCBN+V0=;
 b=vQK9gyW/8OBXXuInwJXO6/eTz4UZT9n3mAPDqmKxKOFpQK49au9DpXzOdjPandNb8BshMs19K
 PnK+A7fq/pVCyXyDQs0xnwqwQr54SeykZ/xUn4BDCsv/SUSdS7W2f/Q
X-Developer-Key: i=manpacket@gmail.com; a=ed25519;
 pk=OljyhmMnK5zdnRB5D/BzDCrh2eycv9FSkJB+r1/MtzM=
X-Endpoint-Received: by B4 Relay for manpacket@gmail.com/20261015 with auth_id=1197
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit partially undoes changes made by the commit e79255de8581
("sfc: Do not pass non-TCP packets into GRO code"). Those changes made
sense back then, but now GRO can help with more message types. Instead
of passing just TCP packets driver to GRO now also pass UDP packets.

Tested on SFC9250 with a UDP_GRO socket.

Signed-off-by: Michael Baikov <manpacket@gmail.com>
---
Problem I'm trying to solve: I'm dealing with high data rate, small
message size multicast UDP traffic - uniform size, addresses - a perfect
candidate for UDP Generic Receive Offload (GRO). Made a prototype - it
worked as expected on the desktop during development, but wasn't
producing any GRO coalesced messages on the server.

The server uses SFC9250 and turns out its driver only allows GRO for TCP
packets. Change was made back in 2013.

Expected user impact:

1. GRO will start working for UDP
2. It might add a slight overhead for UDP traffic for e10 drivers.
   (this bypass only exists for e10 drivers, for e100 (ef100_rx.c:140)
   packets are passed to GRO unconditionally
---
 drivers/net/ethernet/sfc/ef10.c       | 2 ++
 drivers/net/ethernet/sfc/net_driver.h | 1 +
 drivers/net/ethernet/sfc/rx.c         | 3 ++-
 3 files changed, 5 insertions(+), 1 deletion(-)

diff --git a/drivers/net/ethernet/sfc/ef10.c b/drivers/net/ethernet/sfc/ef10.c
index 73bc064929f6..ab0f5e8aae6e 100644
--- a/drivers/net/ethernet/sfc/ef10.c
+++ b/drivers/net/ethernet/sfc/ef10.c
@@ -2955,6 +2955,8 @@ static int efx_ef10_handle_rx_event(struct efx_channel *channel,
 
 	if (rx_l4_class == ESE_FZ_L4_CLASS_TCP)
 		flags |= EFX_RX_PKT_TCP;
+	else if (rx_l4_class == ESE_FZ_L4_CLASS_UDP)
+		flags |= EFX_RX_PKT_UDP;
 
 	channel->irq_mod_score += 2 * n_packets;
 
diff --git a/drivers/net/ethernet/sfc/net_driver.h b/drivers/net/ethernet/sfc/net_driver.h
index 71144bb4c6c8..57cb508d82fa 100644
--- a/drivers/net/ethernet/sfc/net_driver.h
+++ b/drivers/net/ethernet/sfc/net_driver.h
@@ -341,6 +341,7 @@ struct efx_rx_buffer {
 #define EFX_RX_BUF_LAST_IN_PAGE	0x0001
 #define EFX_RX_PKT_CSUMMED	0x0002
 #define EFX_RX_PKT_DISCARD	0x0004
+#define EFX_RX_PKT_UDP		0x0020
 #define EFX_RX_PKT_TCP		0x0040
 #define EFX_RX_PKT_PREFIX_LEN	0x0080	/* length is in prefix only */
 #define EFX_RX_PKT_CSUM_LEVEL	0x0200
diff --git a/drivers/net/ethernet/sfc/rx.c b/drivers/net/ethernet/sfc/rx.c
index ffca82207e47..929ecb539b64 100644
--- a/drivers/net/ethernet/sfc/rx.c
+++ b/drivers/net/ethernet/sfc/rx.c
@@ -401,7 +401,8 @@ void __efx_rx_packet(struct efx_channel *channel)
 	if (unlikely(!(efx->net_dev->features & NETIF_F_RXCSUM)))
 		rx_buf->flags &= ~EFX_RX_PKT_CSUMMED;
 
-	if ((rx_buf->flags & EFX_RX_PKT_TCP) && !channel->type->receive_skb)
+	if ((rx_buf->flags & (EFX_RX_PKT_TCP | EFX_RX_PKT_UDP)) &&
+	    !channel->type->receive_skb)
 		efx_rx_packet_gro(channel, rx_buf, channel->rx_pkt_n_frags, eh, 0);
 	else
 		efx_rx_deliver(channel, eh, rx_buf, channel->rx_pkt_n_frags);

---
base-commit: 98c2ad4f5d805dbc1ea436a334ee59311806a48c
change-id: 20261018-sfc-gro-udp-5d3e9a3b2b54

Best regards,
-- 
Michael Baikov <manpacket@gmail.com>

