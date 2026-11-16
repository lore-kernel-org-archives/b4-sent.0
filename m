From: "Jeff C. Jensen" <kernel@nullptr.com>
Date: Sun, 15 Nov 2026 19:43:05 -0800
Subject: [PATCH v2 2/3] dmaengine: xilinx_dma: Fix cyclic period count
 truncation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-xilinx-dma-work-v2-2-681ed00c15a1@nullptr.com>
References: <20261115-xilinx-dma-work-v2-0-681ed00c15a1@nullptr.com>
In-Reply-To: <20261115-xilinx-dma-work-v2-0-681ed00c15a1@nullptr.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1861; i=kernel@nullptr.com;
 s=openpgp-2026; h=from:subject:message-id;
 bh=YUWNqOn/+Zb1scbFCp7ICqUXI0F0lLN8QDUGg53bhVo=;
 b=owGbwMvMwCV2439B4wpuQQ7G02pJDFm/qu+uvPpBVkHu+WbX4IaZqbyrbzYI/c0y3Wkv92Cax
 hudZR8+dpSyMIhxMciKKbIcPzZtZ76tf11R9f0qmDmsTCBDGLg4BWAirfcYGQ63mp6z7lC443r1
 fMTf+i/3Ko8cllddclx0bs9WnS9HDzAzMhxc+/ePzrqTOc7zKqs/9qtb1kSr6fZcfLG82Ec7av7
 sx0wA
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
Reviewed-by: Suraj Gupta <suraj.gupta2@amd.com>
Reviewed-by: Frank Li <Frank.Li@nxp.com>
Signed-off-by: Jeff C. Jensen <kernel@nullptr.com>
---
 drivers/dma/xilinx/xilinx_dma.c | 9 +++++----
 1 file changed, 5 insertions(+), 4 deletions(-)

diff --git a/drivers/dma/xilinx/xilinx_dma.c b/drivers/dma/xilinx/xilinx_dma.c
index 6f00ab41b143..ba4fa1aafc50 100644
--- a/drivers/dma/xilinx/xilinx_dma.c
+++ b/drivers/dma/xilinx/xilinx_dma.c
@@ -2511,7 +2511,7 @@ static struct dma_async_tx_descriptor *xilinx_dma_prep_dma_cyclic(
 	struct xilinx_dma_chan *chan = to_xilinx_chan(dchan);
 	struct xilinx_dma_tx_descriptor *desc;
 	struct xilinx_axidma_tx_segment *segment, *head_segment, *prev = NULL;
-	size_t copy, sg_used;
+	size_t copy, sg_used, periods;
 	unsigned int num_periods;
 	int i;
 	u32 reg;
@@ -2519,10 +2519,11 @@ static struct dma_async_tx_descriptor *xilinx_dma_prep_dma_cyclic(
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

