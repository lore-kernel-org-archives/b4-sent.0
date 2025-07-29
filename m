From: Christoph Paasch <cpaasch@openai.com>
Date: Tue, 29 Jul 2025 11:34:00 -0700
Subject: [PATCH net] net/mlx5: Correctly set gso_segs when LRO is used
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250729-mlx5_gso_segs-v1-1-b48c480c1c12@openai.com>
X-B4-Tracking: v=1; b=H4sIABcUiWgC/x3MSQqAMBAF0atIrw3EYHC4iog4fGODRkmLCOLdD
 S7fouohQWAI1clDARcL7z4iSxMal947KJ6iyWhjdWEqta237ZzsncCJKmHRmykfqkFTbI6Ame/
 /15DHSe37fvYiHwdkAAAA
X-Change-ID: 20250729-mlx5_gso_segs-8e5ea2d4b9b0
To: Saeed Mahameed <saeedm@nvidia.com>, Tariq Toukan <tariqt@nvidia.com>, 
 Mark Bloch <mbloch@nvidia.com>, Leon Romanovsky <leon@kernel.org>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Amir Vadai <amirv@mellanox.com>
Cc: netdev@vger.kernel.org, linux-rdma@vger.kernel.org, 
 Gal Pressman <gal@nvidia.com>, Christoph Paasch <cpaasch@openai.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753814051; l=2293;
 i=cpaasch@openai.com; s=20250712; h=from:subject:message-id;
 bh=BEl29bER/lvNXl8OFGctWB+GNXoUpmP6lKzTKh8mgKg=;
 b=yG4Ad4zj5YUqZ8aVs2erdhWF4rIFYiTUjcQ5GjoBH6yq2o/jWDsZQQKaa5fOXpKT2toAU1YBc
 BIRIRVF3CTBAzabqecpVEuwaesH5SNP3pEififo1w7jqr08AnCvRt9H
X-Developer-Key: i=cpaasch@openai.com; a=ed25519;
 pk=1HRHZlVUZPziMZvsAQFvP7n5+uEosTDAjXmNXykdxdg=
X-Endpoint-Received: by B4 Relay for cpaasch@openai.com/20250712 with auth_id=459
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When gso_segs is left at 0, a number of assumptions will end up being
incorrect throughout the stack.

For example, in the GRO-path, we set NAPI_GRO_CB()->count to gso_segs.
So, if a non-LRO'ed packet followed by an LRO'ed packet is being
processed in GRO, the first one will have NAPI_GRO_CB()->count set to 1 and
the next one to 0 (in dev_gro_receive()).
Since commit 531d0d32de3e
("net/mlx5: Correctly set gso_size when LRO is used")
these packets will get merged (as their gso_size now matches).
So, we end up in gro_complete() with NAPI_GRO_CB()->count == 1 and thus
don't call inet_gro_complete(). Meaning, checksum-validation in
tcp_checksum_complete() will fail with a "hw csum failure".

Even before the above mentioned commit, incorrect gso_segs means that other
things like TCP's accounting of incoming packets (tp->segs_in,
data_segs_in, rcv_ooopack) will be incorrect. Which means that if one
does bytes_received/data_segs_in, the result will be bigger than the
MTU.

Fix this by initializing gso_segs correctly when LRO is used.

Fixes: e586b3b0baee ("net/mlx5: Ethernet Datapath files")
Reported-by: Gal Pressman <gal@nvidia.com>
Closes: https://lore.kernel.org/netdev/6583783f-f0fb-4fb1-a415-feec8155bc69@nvidia.com/
Signed-off-by: Christoph Paasch <cpaasch@openai.com>
---
 drivers/net/ethernet/mellanox/mlx5/core/en_rx.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/net/ethernet/mellanox/mlx5/core/en_rx.c b/drivers/net/ethernet/mellanox/mlx5/core/en_rx.c
index 7462514c7f3d1606339ede13a6207c1629ab65a3..da3e340c99b72ce27861cccaa5bd722c1b446a55 100644
--- a/drivers/net/ethernet/mellanox/mlx5/core/en_rx.c
+++ b/drivers/net/ethernet/mellanox/mlx5/core/en_rx.c
@@ -1567,6 +1567,7 @@ static inline void mlx5e_build_rx_skb(struct mlx5_cqe64 *cqe,
 		unsigned int hdrlen = mlx5e_lro_update_hdr(skb, cqe, cqe_bcnt);
 
 		skb_shinfo(skb)->gso_size = DIV_ROUND_UP(cqe_bcnt - hdrlen, lro_num_seg);
+		skb_shinfo(skb)->gso_segs = lro_num_seg;
 		/* Subtract one since we already counted this as one
 		 * "regular" packet in mlx5e_complete_rx_cqe()
 		 */

---
base-commit: afd8c2c9e2e29c6c7705635bea2960593976dacc
change-id: 20250729-mlx5_gso_segs-8e5ea2d4b9b0

Best regards,
-- 
Christoph Paasch <cpaasch@openai.com>

