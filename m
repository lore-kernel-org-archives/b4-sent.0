From: "Jeff C. Jensen" <kernel@nullptr.com>
Date: Thu, 22 Oct 2026 15:11:31 -0700
Subject: [PATCH 2/5] dmaengine: xilinx_dma: Fix cyclic period count
 truncation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-xilinx-dma-work-v1-2-20faea2e7a80@nullptr.com>
References: <20261022-xilinx-dma-work-v1-0-20faea2e7a80@nullptr.com>
In-Reply-To: <20261022-xilinx-dma-work-v1-0-20faea2e7a80@nullptr.com>
To: Vinod Koul <vkoul@kernel.org>, dmaengine@vger.kernel.org
Cc: Frank Li <Frank.Li@kernel.org>, Michal Simek <michal.simek@amd.com>, 
 Suraj Gupta <suraj.gupta2@amd.com>, 
 Radhey Shyam Pandey <radhey.shyam.pandey@amd.com>, 
 Alex Bereza <alex@bereza.email>, 
 Folker Schwesinger <dev@folker-schwesinger.de>, 
 Tomi Valkeinen <tomi.valkeinen@ideasonboard.com>, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 "Jeff C. Jensen" <kernel@nullptr.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1808; i=kernel@nullptr.com;
 s=openpgp-2026; h=from:subject:message-id;
 bh=uxgMXIyep7CAr1NQDXQw04MaelMXvUlXqqiFb7DgwaU=;
 b=owGbwMvMwCV2439B4wpuQQ7G02pJDFm3ugKKJba5Hm3erCNbdtFg4qLV6yddETf5tpDhkMKdq
 qiz1lWLO0pZGMS4GGTFFFmOH5u2M9/Wv66o+n4VzBxWJpAhDFycAjCRWUEM/1MeHOvqZrCZY/TV
 WKRuf3XJvjdpsetiws1OSr9Yu8fYt5+R4WX0p+Ucl1ov3Ty8O2BPy3mu+IKYuXZH8huiD97xzDo
 ZzgQA
X-Developer-Key: i=kernel@nullptr.com; a=openpgp;
 fpr=C7C696B96F3D4F7E727BDF7AD8FF7081A80B1108
X-Endpoint-Received: by B4 Relay for kernel@nullptr.com/openpgp-2026 with auth_id=1265
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

xilinx_dma_prep_dma_cyclic() stores buf_len / period_len, a size_t
quotient, in an unsigned int. On 64-bit builds the count can be
truncated: a buffer of 2^32 + 1 bytes split into 1-byte periods becomes
a single period, and the transfer covers one byte of the buffer the
client asked for.

Compute the quotient as a size_t and reject it if it exceeds
XILINX_DMA_NUM_DESCS before narrowing it. Each period needs at least one
hardware descriptor, so a larger count could never be prepared from the
pool anyway.

Fixes: 92d794dfb699 ("dmaengine: vdma: Add support for cyclic dma mode")
Assisted-by: Claude:claude-fable-5-1
Signed-off-by: Jeff C. Jensen <kernel@nullptr.com>
---
 drivers/dma/xilinx/xilinx_dma.c | 9 +++++----
 1 file changed, 5 insertions(+), 4 deletions(-)

diff --git a/drivers/dma/xilinx/xilinx_dma.c b/drivers/dma/xilinx/xilinx_dma.c
index 5ccc9f9d58a3..aa714effd10d 100644
--- a/drivers/dma/xilinx/xilinx_dma.c
+++ b/drivers/dma/xilinx/xilinx_dma.c
@@ -2454,7 +2454,7 @@ static struct dma_async_tx_descriptor *xilinx_dma_prep_dma_cyclic(
 	struct xilinx_dma_chan *chan = to_xilinx_chan(dchan);
 	struct xilinx_dma_tx_descriptor *desc;
 	struct xilinx_axidma_tx_segment *segment, *head_segment, *prev = NULL;
-	size_t copy, sg_used;
+	size_t copy, sg_used, periods;
 	unsigned int num_periods;
 	int i;
 	u32 reg;
@@ -2462,10 +2462,11 @@ static struct dma_async_tx_descriptor *xilinx_dma_prep_dma_cyclic(
 	if (!period_len)
 		return NULL;
 
-	num_periods = buf_len / period_len;
-
-	if (!num_periods)
+	/* a period takes at least one descriptor */
+	periods = buf_len / period_len;
+	if (!periods || periods > XILINX_DMA_NUM_DESCS)
 		return NULL;
+	num_periods = periods;
 
 	if (!is_slave_direction(direction))
 		return NULL;

-- 
2.43.0

