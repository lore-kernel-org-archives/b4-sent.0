From: Christoph Paasch <cpaasch@openai.com>
Date: Mon, 25 Aug 2025 20:47:12 -0700
Subject: [PATCH net-next v3 1/2] net/mlx5: Bring back get_cqe_l3_hdr_type
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250825-cpaasch-pf-927-netmlx5-avoid-copying-the-payload-to-the-malloced-area-v3-1-5527e9eb6efc@openai.com>
References: <20250825-cpaasch-pf-927-netmlx5-avoid-copying-the-payload-to-the-malloced-area-v3-0-5527e9eb6efc@openai.com>
In-Reply-To: <20250825-cpaasch-pf-927-netmlx5-avoid-copying-the-payload-to-the-malloced-area-v3-0-5527e9eb6efc@openai.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756180043; l=1431;
 i=cpaasch@openai.com; s=20250712; h=from:subject:message-id;
 bh=SPLeig1w80KP25Uafa7OhBKZ5EPa50evdyHn8YkXEeM=;
 b=HgvBG4kttZykTui4idPziE/vWifA/0oBdBKeBSMQwAc70alyUk7B3XVLk312v3Jsxh7dFPW0+
 PnjiDPUa7uqDW7OHmnQlh/facHwnG+fRaHrujKPIrAbwQ0LB5TNRwfD
X-Developer-Key: i=cpaasch@openai.com; a=ed25519;
 pk=1HRHZlVUZPziMZvsAQFvP7n5+uEosTDAjXmNXykdxdg=
X-Endpoint-Received: by B4 Relay for cpaasch@openai.com/20250712 with auth_id=459
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 66af4fe37119 ("net/mlx5: Remove unused functions") removed
get_cqe_l3_hdr_type. Let's bring it back.

Also, define CQE_L3_HDR_TYPE_* to identify IPv6 and IPv4 packets.

Signed-off-by: Christoph Paasch <cpaasch@openai.com>
---
 include/linux/mlx5/device.h | 12 +++++++++++-
 1 file changed, 11 insertions(+), 1 deletion(-)

diff --git a/include/linux/mlx5/device.h b/include/linux/mlx5/device.h
index 9d2467f982ad4697f0b36f6975b820c3a41fc78a..5e4a03cff0f1d9b11c5f562c23dbf85c3302f681 100644
--- a/include/linux/mlx5/device.h
+++ b/include/linux/mlx5/device.h
@@ -927,11 +927,16 @@ static inline u8 get_cqe_lro_tcppsh(struct mlx5_cqe64 *cqe)
 	return (cqe->lro.tcppsh_abort_dupack >> 6) & 1;
 }
 
-static inline u8 get_cqe_l4_hdr_type(struct mlx5_cqe64 *cqe)
+static inline u8 get_cqe_l4_hdr_type(const struct mlx5_cqe64 *cqe)
 {
 	return (cqe->l4_l3_hdr_type >> 4) & 0x7;
 }
 
+static inline u8 get_cqe_l3_hdr_type(const struct mlx5_cqe64 *cqe)
+{
+	return (cqe->l4_l3_hdr_type >> 2) & 0x3;
+}
+
 static inline bool cqe_is_tunneled(struct mlx5_cqe64 *cqe)
 {
 	return cqe->tls_outer_l3_tunneled & 0x1;
@@ -1012,6 +1017,11 @@ enum {
 	CQE_L4_HDR_TYPE_TCP_ACK_AND_DATA	= 0x4,
 };
 
+enum {
+	CQE_L3_HDR_TYPE_IPV6			= 0x1,
+	CQE_L3_HDR_TYPE_IPV4			= 0x2,
+};
+
 enum {
 	CQE_RSS_HTYPE_IP	= GENMASK(3, 2),
 	/* cqe->rss_hash_type[3:2] - IP destination selected for hash

-- 
2.50.1

