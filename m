From: Christoph Paasch <cpaasch@openai.com>
Date: Tue, 15 Jul 2025 13:20:53 -0700
Subject: [PATCH net v2] net/mlx5: Correctly set gso_size when LRO is used
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250715-cpaasch-pf-925-investigate-incorrect-gso_size-on-cx-7-nic-v2-1-e06c3475f3ac@openai.com>
X-B4-Tracking: v=1; b=H4sIACS4dmgC/x2N0QqDMAwAf0XyvIArFt1+ZQzpYqx5SUtTRCb++
 8oeD467E4yLsMGzO6HwLiZJG7hbB7QFjYyyNAbXO9+P9wEph2C0YV7x4TyK7mxVYqjNVEqlMFW
 MlmaTL2NSpANHVCGcvPsMvg/TEhZo/Vx4leP/foFyhfd1/QDj4EQQkAAAAA==
X-Change-ID: 20250714-cpaasch-pf-925-investigate-incorrect-gso_size-on-cx-7-nic-852b450a8dad
To: Saeed Mahameed <saeedm@nvidia.com>, Tariq Toukan <tariqt@nvidia.com>, 
 Mark Bloch <mbloch@nvidia.com>, Leon Romanovsky <leon@kernel.org>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Gal Pressman <gal@nvidia.com>
Cc: netdev@vger.kernel.org, linux-rdma@vger.kernel.org, 
 Christoph Paasch <cpaasch@openai.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752610867; l=3259;
 i=cpaasch@openai.com; s=20250712; h=from:subject:message-id;
 bh=+zux3SKfHs3vKZon0w9riKpNcRAgFX0sLiVki6c1lMw=;
 b=yhoowKJGwpVa5ITYjE0xwLhyxs8867DSSeKO3J423J8X0y7cPV8oOTJZ/r6H/GXg9HhtTT4eN
 ljKX+BSfcQgCu/OsWUgDx2za891lZgCPk5MF7coVRhZ6rMm+sHf0Wq0
X-Developer-Key: i=cpaasch@openai.com; a=ed25519;
 pk=1HRHZlVUZPziMZvsAQFvP7n5+uEosTDAjXmNXykdxdg=
X-Endpoint-Received: by B4 Relay for cpaasch@openai.com/20250712 with auth_id=459
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

gso_size is expected by the networking stack to be the size of the
payload (thus, not including ethernet/IP/TCP-headers). However, cqe_bcnt
is the full sized frame (including the headers). Dividing cqe_bcnt by
lro_num_seg will then give incorrect results.

For example, running a bpftrace higher up in the TCP-stack
(tcp_event_data_recv), we commonly have gso_size set to 1450 or 1451 even
though in reality the payload was only 1448 bytes.

This can have unintended consequences:
- In tcp_measure_rcv_mss() len will be for example 1450, but. rcv_mss
will be 1448 (because tp->advmss is 1448). Thus, we will always
recompute scaling_ratio each time an LRO-packet is received.
- In tcp_gro_receive(), it will interfere with the decision whether or
not to flush and thus potentially result in less gro'ed packets.

So, we need to discount the protocol headers from cqe_bcnt so we can
actually divide the payload by lro_num_seg to get the real gso_size.

v2:
 - Use "(unsigned char *)tcp + tcp->doff * 4 - skb->data)" to compute header-len
   (Tariq Toukan <tariqt@nvidia.com>)
 - Improve commit-message (Gal Pressman <gal@nvidia.com>)

Fixes: e586b3b0baee ("net/mlx5: Ethernet Datapath files")
Signed-off-by: Christoph Paasch <cpaasch@openai.com>
---
 drivers/net/ethernet/mellanox/mlx5/core/en_rx.c | 12 ++++++++----
 1 file changed, 8 insertions(+), 4 deletions(-)

diff --git a/drivers/net/ethernet/mellanox/mlx5/core/en_rx.c b/drivers/net/ethernet/mellanox/mlx5/core/en_rx.c
index 84b1ab8233b8107f0d954ea29c33601b279a2c27..7462514c7f3d1606339ede13a6207c1629ab65a3 100644
--- a/drivers/net/ethernet/mellanox/mlx5/core/en_rx.c
+++ b/drivers/net/ethernet/mellanox/mlx5/core/en_rx.c
@@ -1154,8 +1154,9 @@ static void mlx5e_lro_update_tcp_hdr(struct mlx5_cqe64 *cqe, struct tcphdr *tcp)
 	}
 }
 
-static void mlx5e_lro_update_hdr(struct sk_buff *skb, struct mlx5_cqe64 *cqe,
-				 u32 cqe_bcnt)
+static unsigned int mlx5e_lro_update_hdr(struct sk_buff *skb,
+					 struct mlx5_cqe64 *cqe,
+					 u32 cqe_bcnt)
 {
 	struct ethhdr	*eth = (struct ethhdr *)(skb->data);
 	struct tcphdr	*tcp;
@@ -1205,6 +1206,8 @@ static void mlx5e_lro_update_hdr(struct sk_buff *skb, struct mlx5_cqe64 *cqe,
 		tcp->check = tcp_v6_check(payload_len, &ipv6->saddr,
 					  &ipv6->daddr, check);
 	}
+
+	return (unsigned int)((unsigned char *)tcp + tcp->doff * 4 - skb->data);
 }
 
 static void *mlx5e_shampo_get_packet_hd(struct mlx5e_rq *rq, u16 header_index)
@@ -1561,8 +1564,9 @@ static inline void mlx5e_build_rx_skb(struct mlx5_cqe64 *cqe,
 		mlx5e_macsec_offload_handle_rx_skb(netdev, skb, cqe);
 
 	if (lro_num_seg > 1) {
-		mlx5e_lro_update_hdr(skb, cqe, cqe_bcnt);
-		skb_shinfo(skb)->gso_size = DIV_ROUND_UP(cqe_bcnt, lro_num_seg);
+		unsigned int hdrlen = mlx5e_lro_update_hdr(skb, cqe, cqe_bcnt);
+
+		skb_shinfo(skb)->gso_size = DIV_ROUND_UP(cqe_bcnt - hdrlen, lro_num_seg);
 		/* Subtract one since we already counted this as one
 		 * "regular" packet in mlx5e_complete_rx_cqe()
 		 */

---
base-commit: 0e9418961f897be59b1fab6e31ae1b09a0bae902
change-id: 20250714-cpaasch-pf-925-investigate-incorrect-gso_size-on-cx-7-nic-852b450a8dad

Best regards,
-- 
Christoph Paasch <cpaasch@openai.com>

