From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 16 Jun 2026 16:40:53 +0100
Subject: [PATCH RFC 2/3] dmaengine: dma-axi-dmac: Switch to bitmap-based
 address width masks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260616-dmaengine-support-wider-dma-masks-v1-2-da23a8dcb756@analog.com>
References: <20260616-dmaengine-support-wider-dma-masks-v1-0-da23a8dcb756@analog.com>
In-Reply-To: <20260616-dmaengine-support-wider-dma-masks-v1-0-da23a8dcb756@analog.com>
To: dmaengine@vger.kernel.org, linux-iio@vger.kernel.org
Cc: Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781624455; l=1786;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=sU9DQsd6byszeh5ncz5ZqdeyVxN/jL4K0IVccBygpEg=;
 b=tjT7QgQ5D3btARwUqFiFGLvPT5JLa8ANAMSz53rWXUoroAu4yXPqJSmDVOTpx2RsSz3WSBuaT
 qfKt3V467FXB9RLgdEACH1DEnK1z+D1HplPt3ueSSVqKGtDtRNh5ZQV
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Advertise the source and destination bus widths through the new
dma_set_{src,dst}_addr_mask() helpers instead of open-coding the legacy
BIT() mask. This moves the driver onto the representation that can
express widths of 32 bytes and above and allows the legacy u32 field to
be removed once all users are converted.

While at it, give the channel width members their proper
enum dma_slave_buswidth type.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/dma/dma-axi-dmac.c | 12 ++++++++----
 1 file changed, 8 insertions(+), 4 deletions(-)

diff --git a/drivers/dma/dma-axi-dmac.c b/drivers/dma/dma-axi-dmac.c
index d47ff27e1408..19c258d511ca 100644
--- a/drivers/dma/dma-axi-dmac.c
+++ b/drivers/dma/dma-axi-dmac.c
@@ -152,8 +152,8 @@ struct axi_dmac_chan {
 	struct list_head active_descs;
 	enum dma_transfer_direction direction;
 
-	unsigned int src_width;
-	unsigned int dest_width;
+	enum dma_slave_buswidth src_width;
+	enum dma_slave_buswidth dest_width;
 	unsigned int src_type;
 	unsigned int dest_type;
 
@@ -1262,8 +1262,12 @@ static int axi_dmac_probe(struct platform_device *pdev)
 	dma_dev->device_terminate_all = axi_dmac_terminate_all;
 	dma_dev->device_synchronize = axi_dmac_synchronize;
 	dma_dev->dev = &pdev->dev;
-	dma_dev->src_addr_widths = BIT(dmac->chan.src_width);
-	dma_dev->dst_addr_widths = BIT(dmac->chan.dest_width);
+	ret = dma_set_src_addr_mask(dma_dev, &dmac->chan.src_width, 1);
+	if (ret)
+		return ret;
+	ret = dma_set_dst_addr_mask(dma_dev, &dmac->chan.dest_width, 1);
+	if (ret)
+		return ret;
 	dma_dev->directions = BIT(dmac->chan.direction);
 	dma_dev->residue_granularity = DMA_RESIDUE_GRANULARITY_DESCRIPTOR;
 	dma_dev->max_sg_burst = 31; /* 31 SGs maximum in one burst */

-- 
2.54.0

