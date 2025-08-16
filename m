From: Christoph Paasch <cpaasch@openai.com>
Subject: [PATCH net-next v2 0/2] net/mlx5: Avoid payload in skb's linear
 part for better GRO-processing
Date: Sat, 16 Aug 2025 08:39:02 -0700
Message-Id: <20250816-cpaasch-pf-927-netmlx5-avoid-copying-the-payload-to-the-malloced-area-v2-0-b11b30bc2d10@openai.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABamoGgC/62OQYrDMAxFr1K0rkrixk3b1dxj6ELYaiNILGObk
 BBy95owR5jl48H/b4PMSTjD87RB4lmyaKhgzidwA4UPo/jKYBpjm7416CJRdgPGNz5Mj4HLNC4
 WaVbx6DSuEj5YBsZI66jkseiBE42jOvZIiQlv1nSPtu+spRvUr5j4LcvR8Qt1s+4uBV7VDJKLp
 vUInNvD/7Vc/6llbrFBdsT+7sy96/hHIweSi9MJXvu+fwGiyscgJQEAAA==
X-Change-ID: 20250712-cpaasch-pf-927-netmlx5-avoid-copying-the-payload-to-the-malloced-area-6524917455a6
To: Saeed Mahameed <saeedm@nvidia.com>, Leon Romanovsky <leon@kernel.org>, 
 Tariq Toukan <tariqt@nvidia.com>, Mark Bloch <mbloch@nvidia.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Alexander Lobakin <aleksander.lobakin@intel.com>, 
 Gal Pressman <gal@nvidia.com>
Cc: linux-rdma@vger.kernel.org, netdev@vger.kernel.org, 
 Christoph Paasch <cpaasch@openai.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755358743; l=1531;
 i=cpaasch@openai.com; s=20250712; h=from:subject:message-id;
 bh=o+rHkyCjmB4hkyP7M3HLqZNJrf+AJVoFYhkrqijhjZg=;
 b=l+5SKjfiweJsliNW8BZ12uhSvZ3HCGFk0I44HeHLd7jk2KjiqBT2AVdISiC4cm3l8R0KQFZGD
 m8zotkOOwA+DIhQHVSicGgyv/ql/sM4st0Ck+gYjidoBBKPkOB+V3r2
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

 drivers/net/ethernet/mellanox/mlx5/core/en_rx.c | 37 ++++++++++++++++++++++++-
 include/linux/mlx5/device.h                     | 12 +++++++-
 2 files changed, 47 insertions(+), 2 deletions(-)
---
base-commit: bab3ce404553de56242d7b09ad7ea5b70441ea41
change-id: 20250712-cpaasch-pf-927-netmlx5-avoid-copying-the-payload-to-the-malloced-area-6524917455a6

Best regards,
-- 
Christoph Paasch <cpaasch@openai.com>

