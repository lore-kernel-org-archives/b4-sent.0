From: Christoph Paasch <cpaasch@openai.com>
Subject: [PATCH net-next v3 0/2] net/mlx5: Avoid payload in skb's linear
 part for better GRO-processing
Date: Mon, 25 Aug 2025 20:47:11 -0700
Message-Id: <20250825-cpaasch-pf-927-netmlx5-avoid-copying-the-payload-to-the-malloced-area-v3-0-5527e9eb6efc@openai.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAD8urWgC/62OwWrEIBRFf2Vw3VfUxCTTVf+jdPGibyZCoqIiC
 UP+fUQGSvezPFy45zxYomgpsa/Lg0UqNlnvKnQfF6YXdHcCayozyaXio5CgA2LSC4QbXOUIjvK
 27gqweGtA+3BYd4e8EAQ8Vo8Gsm+44bp6TQYwEsKgZH8VY68UDqy6QqSb3VvHD6uf9XfP7Lcui
 03Zx6MFFtH2V0v3ppYigANpJDNpOfU9fftADu2n9ltLKPJPO4nhXVpZtbMQc8dnLY3g/7TneT4
 BzeSZdpwBAAA=
X-Change-ID: 20250712-cpaasch-pf-927-netmlx5-avoid-copying-the-payload-to-the-malloced-area-6524917455a6
To: Saeed Mahameed <saeedm@nvidia.com>, Leon Romanovsky <leon@kernel.org>, 
 Tariq Toukan <tariqt@nvidia.com>, Mark Bloch <mbloch@nvidia.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Alexander Lobakin <aleksander.lobakin@intel.com>, 
 Gal Pressman <gal@nvidia.com>, Dragos Tatulea <dtatulea@nvidia.com>
Cc: linux-rdma@vger.kernel.org, netdev@vger.kernel.org, 
 Christoph Paasch <cpaasch@openai.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756180043; l=2117;
 i=cpaasch@openai.com; s=20250712; h=from:subject:message-id;
 bh=k+7yizfovCBjqyr67T5WBtYGeOcnZ1OX5JkfkELb1h0=;
 b=3tiuDdElYpLSKjZVLFiCbNxYu7fGhXcZA4R52YnDxXXGxuUlKQ02zoVrC+FytHQ2AnrgoCInP
 DAFDhiRlxSpA9PCELUXcKg2Dg1lX2SiDPNFbQ0sn46/xW3/joD8HVDn
X-Developer-Key: i=cpaasch@openai.com; a=ed25519;
 pk=1HRHZlVUZPziMZvsAQFvP7n5+uEosTDAjXmNXykdxdg=
X-Endpoint-Received: by B4 Relay for cpaasch@openai.com/20250712 with auth_id=459
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When LRO is enabled on the MLX, mlx5e_skb_from_cqe_mpwrq_nonlinear
copies parts of the payload to the linear part of the skb.

This triggers suboptimal processing in GRO, causing slow throughput,...

This patch series addresses this by copying a lower-bound estimate of
the protocol headers - trying to avoid the payload part. This results in
a significant throughput improvement (detailled results in the specific
patch).

Signed-off-by: Christoph Paasch <cpaasch@openai.com>
---
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
      net/mlx5: Bring back get_cqe_l3_hdr_type
      net/mlx5: Avoid copying payload to the skb's linear part

 drivers/net/ethernet/mellanox/mlx5/core/en_rx.c | 49 ++++++++++++++++++++++++-
 include/linux/mlx5/device.h                     | 12 +++++-
 2 files changed, 59 insertions(+), 2 deletions(-)
---
base-commit: 6e8e6baf16ce7d2310959ae81d0194a56874e0d2
change-id: 20250712-cpaasch-pf-927-netmlx5-avoid-copying-the-payload-to-the-malloced-area-6524917455a6

Best regards,
-- 
Christoph Paasch <cpaasch@openai.com>

