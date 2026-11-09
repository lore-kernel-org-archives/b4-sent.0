From: Michael Baikov <manpacket@gmail.com>
Date: Mon, 09 Nov 2026 13:08:35 -0500
Subject: [PATCH] net: sfc: run all the packets through GRO
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-sfc-udp-gro2-v1-1-025d385f007f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqAIBBA0avIrBtQM6GuEi1CR5uNhVIE4t2Tl
 m/xf4VCmanAIipkerjwmTrUIMAde4qE7LtBS22VkjOW4PD2F8Z8ajST9cGNwRmroSdXpsDvv1u
 31j4fSpf2XgAAAA==
X-Change-ID: 20261109-sfc-udp-gro2-456dfc3fc462
To: Edward Cree <ecree.xilinx@gmail.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-net-drivers@amd.com, 
 linux-kernel@vger.kernel.org, Michael Baikov <manpacket@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794247715; l=2263;
 i=manpacket@gmail.com; s=20261015; h=from:subject:message-id;
 bh=0rd7K8H1ssa2d09oUpAQlHIjcPRA+ZoTgwxPqrVR7J0=;
 b=M6QcjD2zL+tYeQHO/aGWNAsCfzpoTvIoK02dBnEqGiVReRDgxClyyVRmtPynCI4SvPUlORNGL
 xJyVjCkKUOUDCNOkECX1efjh7M7nZqO3V2F7iD+murSrNAjxKQ1tNKJ
X-Developer-Key: i=manpacket@gmail.com; a=ed25519;
 pk=OljyhmMnK5zdnRB5D/BzDCrh2eycv9FSkJB+r1/MtzM=
X-Endpoint-Received: by B4 Relay for manpacket@gmail.com/20261015 with auth_id=1197
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit partially undoes changes made by the commit e79255de8581
("sfc: Do not pass non-TCP packets into GRO code"). Those changes made
sense back then, but now GRO can help with more message types. Now, when
GRO is enabled - pass all the messages though GRO subsystem.
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

First version of this patch tried to pass only UDP and TCP messages
though GRO, but since it's unlikely to have a high volume traffic that
is neither of those two - this version simply drops "is TCP?" check.

Link: https://lore.kernel.org/all/20261018-sfc-gro-udp-v1-1-f7bf378178f8@gmail.com/
---
 drivers/net/ethernet/sfc/rx.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/ethernet/sfc/rx.c b/drivers/net/ethernet/sfc/rx.c
index ffca82207e47..9874093944f8 100644
--- a/drivers/net/ethernet/sfc/rx.c
+++ b/drivers/net/ethernet/sfc/rx.c
@@ -401,7 +401,7 @@ void __efx_rx_packet(struct efx_channel *channel)
 	if (unlikely(!(efx->net_dev->features & NETIF_F_RXCSUM)))
 		rx_buf->flags &= ~EFX_RX_PKT_CSUMMED;
 
-	if ((rx_buf->flags & EFX_RX_PKT_TCP) && !channel->type->receive_skb)
+	if (!channel->type->receive_skb)
 		efx_rx_packet_gro(channel, rx_buf, channel->rx_pkt_n_frags, eh, 0);
 	else
 		efx_rx_deliver(channel, eh, rx_buf, channel->rx_pkt_n_frags);

---
base-commit: fa5196392691051963726787944db872420dfa75
change-id: 20261109-sfc-udp-gro2-456dfc3fc462

Best regards,
-- 
Michael Baikov <manpacket@gmail.com>

