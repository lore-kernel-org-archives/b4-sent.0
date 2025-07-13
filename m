From: Christoph Paasch <cpaasch@openai.com>
Date: Sun, 13 Jul 2025 16:33:06 -0700
Subject: [PATCH net-next 1/2] net/mlx5: Bring back get_cqe_l3_hdr_type
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250713-cpaasch-pf-927-netmlx5-avoid-copying-the-payload-to-the-malloced-area-v1-1-ecaed8c2844e@openai.com>
References: <20250713-cpaasch-pf-927-netmlx5-avoid-copying-the-payload-to-the-malloced-area-v1-0-ecaed8c2844e@openai.com>
In-Reply-To: <20250713-cpaasch-pf-927-netmlx5-avoid-copying-the-payload-to-the-malloced-area-v1-0-ecaed8c2844e@openai.com>
To: Saeed Mahameed <saeedm@nvidia.com>, Leon Romanovsky <leon@kernel.org>, 
 Tariq Toukan <tariqt@nvidia.com>, Mark Bloch <mbloch@nvidia.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: linux-rdma@vger.kernel.org, netdev@vger.kernel.org, 
 Christoph Paasch <cpaasch@openai.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752449639; l=1431;
 i=cpaasch@openai.com; s=20250712; h=from:subject:message-id;
 bh=C/3QdRtBQlKCPf2WiTbNIp27bIs6JfitVu8RamyZd4M=;
 b=P+MRWHpJXo9YemPNR4iawvXjGeZy7ROhD5Jf2QK7J4zM1PXrwZGPRItguUzqQVaZKKHo0/Ygd
 4qJH9HTurmrAo6cpA0HtM1QBLzbYfBIsJfRZp74PJVzLhiyIODpzRxC
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
index 6822cfa5f4ad31ef6fb61be2dcfae3ac9a46d659..a0098df1b82bf746bf0132d547440b9dab22e57f 100644
--- a/include/linux/mlx5/device.h
+++ b/include/linux/mlx5/device.h
@@ -926,11 +926,16 @@ static inline u8 get_cqe_lro_tcppsh(struct mlx5_cqe64 *cqe)
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
@@ -1011,6 +1016,11 @@ enum {
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
2.49.0

