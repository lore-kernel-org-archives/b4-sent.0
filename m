From: Christoph Paasch <cpaasch@openai.com>
Subject: [PATCH net-next v5 0/2] net/mlx5: Avoid payload in skb's linear
 part for better GRO-processing
Date: Thu, 04 Sep 2025 15:53:34 -0700
Message-Id: <20250904-cpaasch-pf-927-netmlx5-avoid-copying-the-payload-to-the-malloced-area-v5-0-ea492f7b11ac@openai.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAG4YumgC/63PTYqEMBAF4Ks0WU8N+TXaq7nH0IsyKduAmqAiS
 uPdOyMD00NvXT4e1PfqwSYaA03senmwkZYwhTjkYD4uzLU43AmCz5lJLg23QoJLiJNrITVQSQs
 DzX23GsAlBg8upi0Md5hbgoRbF9HDHI/YY9dFRx5wJITCSF0Jq43BgmUrjdSE9djxzfLNfHed2
 S03bZjmOG7HwEUc/e8WddKWRQAHcki+dLLUmr5iogHDp4v9MWGRf2wpirNYmdlaiFrx2kkv+Bu
 rXlhpzmJVZo2RliqqC2rcG6tf2fIsVv982zhvuFJo7X923/cnsTlOSIoCAAA=
X-Change-ID: 20250712-cpaasch-pf-927-netmlx5-avoid-copying-the-payload-to-the-malloced-area-6524917455a6
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757026645; l=2867;
 i=cpaasch@openai.com; s=20250712; h=from:subject:message-id;
 bh=Rbqz6hs0vXU3xPDk3Nmm32JXlYH8ZvvlopxpDT7dshQ=;
 b=rufRlFfQiR0sQ6+Xm/CZSr+zhJZeO7jWpfcGI549GFoslhla1aumNi5mkmgmu5MIfMSrP2GbC
 N9hUFFoNmkKAFv41Uk3sLK6xTTCrD66UR+E4LzCSL8QaZCq/fCFV5Td
X-Developer-Key: i=cpaasch@openai.com; a=ed25519;
 pk=1HRHZlVUZPziMZvsAQFvP7n5+uEosTDAjXmNXykdxdg=
X-Endpoint-Received: by B4 Relay for cpaasch@openai.com/20250712 with auth_id=459
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When LRO is enabled on the MLX, mlx5e_skb_from_cqe_mpwrq_nonlinear
copies parts of the payload to the linear part of the skb.

This triggers suboptimal processing in GRO, causing slow throughput,...

This patch series addresses this by using eth_get_headlen to compute the
size of the protocol headers and only copy those bits. This results in
a significant throughput improvement (detailled results in the specific
patch).

Signed-off-by: Christoph Paasch <cpaasch@openai.com>
---
Changes in v5:
- Fix patch #2 NULL-ptr deref when an xdp-prog is set. Instead of using
  skb->dev for eth_get_headlen, use rq->netdev. skb->dev will not be set
  in the xdp code-path. (Reported-by: Amery Hung <ameryhung@gmail.com>)
- Kept previous Reviewed-by as the change is minor.
- Link to v4: https://lore.kernel.org/r/20250828-cpaasch-pf-927-netmlx5-avoid-copying-the-payload-to-the-malloced-area-v4-0-bfcd5033a77c@openai.com

Changes in v4:
- Use eth_get_headlen() instead of building a dissector based on struct mlx5_cqe64.
  This mimics what other drivers,... are doing as well. (Eric Dumazet
  <edumazet@google.com>)
- Link to v3: https://lore.kernel.org/r/20250825-cpaasch-pf-927-netmlx5-avoid-copying-the-payload-to-the-malloced-area-v3-0-5527e9eb6efc@openai.com

Changes in v3:
- Avoid computing headlen when it is not absolutely necessary (e.g., xdp
  decides to "consume" the packet) (Dragos Tatulea <dtatulea@nvidia.com> & Jakub Kicinski <kuba@kernel.org>)
- Given the above change, consolidate the check for min3(...) in the new
  function to avoid code duplication.
- Make sure local variables are in reverse xmas-tree order.
- Refine comment about why the check for l4_type worsk as is.
- Link to v2: https://lore.kernel.org/r/20250816-cpaasch-pf-927-netmlx5-avoid-copying-the-payload-to-the-malloced-area-v2-0-b11b30bc2d10@openai.com

Changes in v2:
- Refine commit-message with more info and testing data
- Make mlx5e_cqe_get_min_hdr_len() return MLX5E_RX_MAX_HEAD when l3_type
  is neither IPv4 nor IPv6. Same for the l4_type. That way behavior is
  unchanged for other traffic types.
- Rename mlx5e_cqe_get_min_hdr_len to mlx5e_cqe_estimate_hdr_len
- Link to v1: https://lore.kernel.org/r/20250713-cpaasch-pf-927-netmlx5-avoid-copying-the-payload-to-the-malloced-area-v1-0-ecaed8c2844e@openai.com

---
Christoph Paasch (2):
      net/mlx5: DMA-sync earlier in mlx5e_skb_from_cqe_mpwrq_nonlinear
      net/mlx5: Avoid copying payload to the skb's linear part

 drivers/net/ethernet/mellanox/mlx5/core/en_rx.c | 24 +++++++++++++++++-------
 1 file changed, 17 insertions(+), 7 deletions(-)
---
base-commit: 5ef04a7b068cbb828eba226aacb42f880f7924d7
change-id: 20250712-cpaasch-pf-927-netmlx5-avoid-copying-the-payload-to-the-malloced-area-6524917455a6

Best regards,
-- 
Christoph Paasch <cpaasch@openai.com>

