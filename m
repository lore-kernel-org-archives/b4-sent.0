From: Richard Leitner <richard.leitner@linux.dev>
Date: Thu, 15 Oct 2026 22:58:00 +0200
Subject: [PATCH] spi: imx: fix slab corruption from undersized DMA bounce
 buffers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261015-fix-spi-imx-dma-v1-1-e28259671392@linux.dev>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM3QpAQBCG4VvRHJuy/sKtyMEug1F+2kFbcu8Wh
 09933uBkGUSqIILLJ0svC4eKgygHfUyEHLnDXEU5ypSGfbsUDZGnh12s0ZltCkz0mmRJ+BfmyU
 /+Yp181sOM1G7vxm47wcaJxsXcwAAAA==
X-Change-ID: 20261015-fix-spi-imx-dma-1bab95ea4863
To: Mark Brown <broonie@kernel.org>, Frank Li <Frank.Li@nxp.com>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, Carlos Song <carlos.song@nxp.com>
Cc: linux-spi@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792097892; l=3405;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=faqGfWDw1le1ZOU408v3r7oVHq96hylhJ7Q53F2VifA=;
 b=NWW3P6cYmkePPMpWsRHkUTk0deQKAZHw/C7ZSe4zPOPl/GT8QhdCPeKwGIQVg4uSFnyxUsCmw
 15j25uuYY3ICHQ3aqc/WSXW+2Q+ftGF8NhRirhOYUu2ePFIEg9S9Vyc
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit faa8e404ad8e ("spi: imx: support dynamic burst length for
ECSPI DMA mode"), the driver allocates its private DMA TX/RX buffers
with kzalloc(dma_len), where dma_len is only rounded up to 4 bytes, but
maps, syncs and unmaps them with DMA_CACHE_ALIGNED_LEN(dma_len), i.e.
rounded up to the cache line size. As a result, the DMA API operates on
memory beyond the end of the allocation.

This was observed on a custom i.MX8MP platform with an mcp251xfd CAN
controller under heavy RPMSG load, as a series of refcount_t warnings
triggered from rpmsg_recv_done() in virtio_rpmsg_bus:

  refcount_t: addition on 0; use-after-free.
  refcount_t: underflow; use-after-free.
  refcount_t: saturated; leaking memory.

Leading finally to an "Unable to handle kernel paging request" oops.
Reproducing this problem took between 30 minutes and roughly 30 hours
under the same workload.

Hardware watchpoints on the refcount of a struct rpmsg_endpoint showed
it was overwritten from 2 to 1 by __pi_memcpy_generic() in the
irq/155-spi2.0 thread. Additionally it was found that a "normal"
rpmsg_recv_done() took 11µs +/-2µs from its kref_get to kref_put. In
the error case the same sequence took about 215µs +/-10µs. Based on
this, an LLM was used to identify the size mismatch fixed here.

Allocate the buffers with DMA_CACHE_ALIGNED_LEN(dma_len) so they cover
the full mapped length, and use the same length for
dma_sync_single_for_cpu() to stay consistent with map and unmap.

With this patch applied, the same workload ran for more than 200 hours
without the problem reproducing.

Assisted-by: LLM
Fixes: faa8e404ad8e ("spi: imx: support dynamic burst length for ECSPI DMA mode")
Cc: stable@vger.kernel.org
Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
 drivers/spi/spi-imx.c | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/drivers/spi/spi-imx.c b/drivers/spi/spi-imx.c
index 79a6c1a60b0a0..3851c50dbe314 100644
--- a/drivers/spi/spi-imx.c
+++ b/drivers/spi/spi-imx.c
@@ -1578,11 +1578,13 @@ static int spi_imx_dma_tx_data_handle(struct spi_imx_data *spi_imx,
 		dma_data->dma_len = ALIGN(dma_data->data_len, BYTES_PER_32BITS_WORD);
 	}
 
-	dma_data->dma_tx_buf = kzalloc(dma_data->dma_len, GFP_KERNEL);
+	dma_data->dma_tx_buf = kzalloc(DMA_CACHE_ALIGNED_LEN(dma_data->dma_len),
+				       GFP_KERNEL);
 	if (!dma_data->dma_tx_buf)
 		return -ENOMEM;
 
-	dma_data->dma_rx_buf = kzalloc(dma_data->dma_len, GFP_KERNEL);
+	dma_data->dma_rx_buf = kzalloc(DMA_CACHE_ALIGNED_LEN(dma_data->dma_len),
+				       GFP_KERNEL);
 	if (!dma_data->dma_rx_buf) {
 		kfree(dma_data->dma_tx_buf);
 		return -ENOMEM;
@@ -1920,7 +1922,8 @@ static int spi_imx_dma_package_transfer(struct spi_imx_data *spi_imx,
 
 	/* Trim the DMA RX buffer and copy the actual data to rx_buf */
 	dma_sync_single_for_cpu(controller->dma_rx->device->dev, dma_data->dma_rx_addr,
-				dma_data->dma_len, DMA_FROM_DEVICE);
+				DMA_CACHE_ALIGNED_LEN(dma_data->dma_len),
+				DMA_FROM_DEVICE);
 	spi_imx_dma_rx_data_handle(spi_imx, dma_data, transfer->rx_buf + spi_imx->rx_offset,
 				   word_delay);
 	spi_imx->rx_offset += dma_data->data_len;

---
base-commit: 62f482ff73bf3ae88b0c899115527752cf9cbf13
change-id: 20261015-fix-spi-imx-dma-1bab95ea4863

Best regards,
--  
Richard Leitner <richard.leitner@linux.dev>

