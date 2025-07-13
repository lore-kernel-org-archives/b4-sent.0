From: Christoph Paasch <cpaasch@openai.com>
Subject: [PATCH net-next 0/2] net/mlx5: Avoid payload in skb's linear part
 for better GRO-processing
Date: Sun, 13 Jul 2025 16:33:05 -0700
Message-Id: <20250713-cpaasch-pf-927-netmlx5-avoid-copying-the-payload-to-the-malloced-area-v1-0-ecaed8c2844e@openai.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADFCdGgC/x3OQQqEMAyF4atI1hPQYhXnKsMsQhs1UNvSFlHEu
 1tcfpv/vQsyJ+EM3+aCxLtkCb6i+zRgVvILo9hqUK3S7dgpNJEomxXjjJMa0XPZ3KGR9iAWTYi
 n+AXLyhjpdIEslvByI+eCYYuUmHDQqp+6sdeaBqhbMfEsx/vjB7VZu0eB/30/m1TZQ6EAAAA=
X-Change-ID: 20250712-cpaasch-pf-927-netmlx5-avoid-copying-the-payload-to-the-malloced-area-6524917455a6
To: Saeed Mahameed <saeedm@nvidia.com>, Leon Romanovsky <leon@kernel.org>, 
 Tariq Toukan <tariqt@nvidia.com>, Mark Bloch <mbloch@nvidia.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: linux-rdma@vger.kernel.org, netdev@vger.kernel.org, 
 Christoph Paasch <cpaasch@openai.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752449639; l=1053;
 i=cpaasch@openai.com; s=20250712; h=from:subject:message-id;
 bh=lOoncje2oUnyFV/y0B2u8ZzppYxKn2zAB68qVvRIoRk=;
 b=ioSnehR5e7kuMAxE7uGeb0XuNvhZbFt+x+kCs6WgJ0hnHyokukeq66J0XA+CPcBqGtDJ9tYT3
 k5pJQM5vm0fAUzFjHKeHNyaJHwkiB3yLpaohwd75Qin5sDSaDHm6E4M
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
Christoph Paasch (2):
      net/mlx5: Bring back get_cqe_l3_hdr_type
      net/mlx5: Avoid copying payload to the skb's linear part

 drivers/net/ethernet/mellanox/mlx5/core/en_rx.c | 33 ++++++++++++++++++++++++-
 include/linux/mlx5/device.h                     | 12 ++++++++-
 2 files changed, 43 insertions(+), 2 deletions(-)
---
base-commit: a52f9f0d77f20efc285908a28b5697603b6597c7
change-id: 20250712-cpaasch-pf-927-netmlx5-avoid-copying-the-payload-to-the-malloced-area-6524917455a6

Best regards,
-- 
Christoph Paasch <cpaasch@openai.com>

