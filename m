From: Christoph Paasch <cpaasch@openai.com>
Date: Thu, 04 Sep 2025 15:53:35 -0700
Subject: [PATCH net-next v5 1/2] net/mlx5: DMA-sync earlier in
 mlx5e_skb_from_cqe_mpwrq_nonlinear
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250904-cpaasch-pf-927-netmlx5-avoid-copying-the-payload-to-the-malloced-area-v5-1-ea492f7b11ac@openai.com>
References: <20250904-cpaasch-pf-927-netmlx5-avoid-copying-the-payload-to-the-malloced-area-v5-0-ea492f7b11ac@openai.com>
In-Reply-To: <20250904-cpaasch-pf-927-netmlx5-avoid-copying-the-payload-to-the-malloced-area-v5-0-ea492f7b11ac@openai.com>
To: Gal Pressman <gal@nvidia.com>, Dragos Tatulea <dtatulea@nvidia.com>, 
 Saeed Mahameed <saeedm@nvidia.com>, Tariq Toukan <tariqt@nvidia.com>, 
 Mark Bloch <mbloch@nvidia.com>, Leon Romanovsky <leon@kernel.org>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Alexei Starovoitov <ast@kernel.org>, Daniel Borkmann <daniel@iogearbox.net>, 
 Jesper Dangaard Brouer <hawk@kernel.org>, 
 John Fastabend <john.fastabend@gmail.com>, 
 Stanislav Fomichev <sdf@fomichev.me>, Amery Hung <ameryhung@gmail.com>
Cc: netdev@vger.kernel.org, linux-rdma@vger.kernel.org, bpf@vger.kernel.org, 
 Christoph Paasch <cpaasch@openai.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757026645; l=3190;
 i=cpaasch@openai.com; s=20250712; h=from:subject:message-id;
 bh=bwP/MTcnhWm0Jr7vtsKF6W2tCFcL1pVUhCGGU7dhD2w=;
 b=8Le5246O25dlFxrJBQIdJLpFAe6UXYR+piOCn7qifyIM55p3iKSKcWZa7ZjlMhnhfduNbtu+B
 NJgdvljZNbaCshXWa2Td0/aDDtdyI54TPhpbDCnDRVWzx6BG1Fcc4q2
X-Developer-Key: i=cpaasch@openai.com; a=ed25519;
 pk=1HRHZlVUZPziMZvsAQFvP7n5+uEosTDAjXmNXykdxdg=
X-Endpoint-Received: by B4 Relay for cpaasch@openai.com/20250712 with auth_id=459
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Doing the call to dma_sync_single_for_cpu() earlier will allow us to
adjust headlen based on the actual size of the protocol headers.

Doing this earlier means that we don't need to call
mlx5e_copy_skb_header() anymore and rather can call
skb_copy_to_linear_data() directly.

Reviewed-by: Eric Dumazet <edumazet@google.com>
Reviewed-by: Saeed Mahameed <saeedm@nvidia.com>
Signed-off-by: Christoph Paasch <cpaasch@openai.com>
---
 drivers/net/ethernet/mellanox/mlx5/core/en_rx.c | 19 ++++++++++++-------
 1 file changed, 12 insertions(+), 7 deletions(-)

diff --git a/drivers/net/ethernet/mellanox/mlx5/core/en_rx.c b/drivers/net/ethernet/mellanox/mlx5/core/en_rx.c
index b8c609d91d11bd315e8fb67f794a91bd37cd28c0..8bedbda522808cbabc8e62ae91a8c25d66725ebb 100644
--- a/drivers/net/ethernet/mellanox/mlx5/core/en_rx.c
+++ b/drivers/net/ethernet/mellanox/mlx5/core/en_rx.c
@@ -2005,17 +2005,19 @@ mlx5e_skb_from_cqe_mpwrq_nonlinear(struct mlx5e_rq *rq, struct mlx5e_mpw_info *w
 	struct skb_shared_info *sinfo;
 	unsigned int truesize = 0;
 	struct bpf_prog *prog;
+	void *va, *head_addr;
 	struct sk_buff *skb;
 	u32 linear_frame_sz;
 	u16 linear_data_len;
 	u16 linear_hr;
-	void *va;
 
 	prog = rcu_dereference(rq->xdp_prog);
 
+	head_addr = netmem_address(head_page->netmem) + head_offset;
+
 	if (prog) {
 		/* area for bpf_xdp_[store|load]_bytes */
-		net_prefetchw(netmem_address(frag_page->netmem) + frag_offset);
+		net_prefetchw(head_addr);
 		if (unlikely(mlx5e_page_alloc_fragmented(rq->page_pool,
 							 &wi->linear_page))) {
 			rq->stats->buff_alloc_err++;
@@ -2028,6 +2030,8 @@ mlx5e_skb_from_cqe_mpwrq_nonlinear(struct mlx5e_rq *rq, struct mlx5e_mpw_info *w
 		linear_data_len = 0;
 		linear_frame_sz = MLX5_SKB_FRAG_SZ(linear_hr + MLX5E_RX_MAX_HEAD);
 	} else {
+		dma_addr_t addr;
+
 		skb = napi_alloc_skb(rq->cq.napi,
 				     ALIGN(MLX5E_RX_MAX_HEAD, sizeof(long)));
 		if (unlikely(!skb)) {
@@ -2039,6 +2043,10 @@ mlx5e_skb_from_cqe_mpwrq_nonlinear(struct mlx5e_rq *rq, struct mlx5e_mpw_info *w
 		net_prefetchw(va); /* xdp_frame data area */
 		net_prefetchw(skb->data);
 
+		addr = page_pool_get_dma_addr_netmem(head_page->netmem);
+		dma_sync_single_for_cpu(rq->pdev, addr + head_offset, headlen,
+					rq->buff.map_dir);
+
 		frag_offset += headlen;
 		byte_cnt -= headlen;
 		linear_hr = skb_headroom(skb);
@@ -2117,8 +2125,6 @@ mlx5e_skb_from_cqe_mpwrq_nonlinear(struct mlx5e_rq *rq, struct mlx5e_mpw_info *w
 		}
 		__pskb_pull_tail(skb, headlen);
 	} else {
-		dma_addr_t addr;
-
 		if (xdp_buff_has_frags(&mxbuf->xdp)) {
 			struct mlx5e_frag_page *pagep;
 
@@ -2133,9 +2139,8 @@ mlx5e_skb_from_cqe_mpwrq_nonlinear(struct mlx5e_rq *rq, struct mlx5e_mpw_info *w
 			while (++pagep < frag_page);
 		}
 		/* copy header */
-		addr = page_pool_get_dma_addr_netmem(head_page->netmem);
-		mlx5e_copy_skb_header(rq, skb, head_page->netmem, addr,
-				      head_offset, head_offset, headlen);
+		skb_copy_to_linear_data(skb, head_addr, headlen);
+
 		/* skb linear part was allocated with headlen and aligned to long */
 		skb->tail += headlen;
 		skb->len  += headlen;

-- 
2.50.1

