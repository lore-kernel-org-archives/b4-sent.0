From: Roland Dreier <rolanddreier@rivian.com>
Date: Tue, 06 Oct 2026 01:03:09 +0000
Subject: [PATCH 3/3] dmaengine: dw-axi-dmac: Decode errors in the transfer
 failure log
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261006-dw-axi-fixes-v1-3-3b319e456d93@rivian.com>
References: <20261006-dw-axi-fixes-v1-0-3b319e456d93@rivian.com>
In-Reply-To: <20261006-dw-axi-fixes-v1-0-3b319e456d93@rivian.com>
To: Eugeniy Paltsev <Eugeniy.Paltsev@synopsys.com>, 
 Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>
Cc: dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Roland Dreier <rolanddreier@rivian.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791248589; l=3880;
 i=rolanddreier@rivian.com; s=20260814; h=from:subject:message-id;
 bh=MOZa5rNW7CgYaOelYWPIYZG2mHxV+5nlFLY6dOb9NYc=;
 b=M7Ecis/RGnR4bzxKYr0RGSjCEAB9EAm1JiqGlhCLCV66wQLNaTg8WCPbkihoowi5fwYCkW1zY
 eOSlNM6C+lVDXd/agpzjd8Ed+ZSfHPxKvHl9dX+wuTPAZzM9Xlnl15B
X-Developer-Key: i=rolanddreier@rivian.com; a=ed25519;
 pk=C7SBXsDIlarq7BpINqyDL67XV/AGNqNt09NCCpFcExk=
X-Endpoint-Received: by B4 Relay for rolanddreier@rivian.com/20260814 with auth_id=952
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

axi_chan_handle_err() reports every error with "Bad descriptor
submitted" and dumps the transfer's LLIs. Common errors are source and
destination decode or slave errors, from an undecoded address or a
target returning an error response. These errors do not necessarily
indicate a malformed descriptor, so the message is misleading. The
dump also has one line per LLI without any indication where the
transfer failed.

Report the first matching error name while retaining the raw interrupt
status so additional error bits remain visible. Include SAR, DAR and
LLP to provide hardware progress and linked-list context without
dumping every LLI. These registers are diagnostic snapshots, not
necessarily the exact addresses of the failing transactions.

Dump the LLIs only when a descriptor or programming error is present.
Leave the transfer result and recovery path unchanged.

Assisted-by: LLM
Signed-off-by: Roland Dreier <rolanddreier@rivian.com>
---
 drivers/dma/dw-axi-dmac/dw-axi-dmac-platform.c | 46 +++++++++++++++++++++++---
 1 file changed, 42 insertions(+), 4 deletions(-)

diff --git a/drivers/dma/dw-axi-dmac/dw-axi-dmac-platform.c b/drivers/dma/dw-axi-dmac/dw-axi-dmac-platform.c
index 88362f181207..e5a259e79a38 100644
--- a/drivers/dma/dw-axi-dmac/dw-axi-dmac-platform.c
+++ b/drivers/dma/dw-axi-dmac/dw-axi-dmac-platform.c
@@ -1059,6 +1059,36 @@ static void axi_chan_list_dump_lli(struct axi_dma_chan *chan,
 		axi_chan_dump_lli(chan, &desc_head->hw_desc[i]);
 }
 
+#define AXI_DMA_DATA_ERR	(DWAXIDMAC_IRQ_SRC_DEC_ERR | \
+			 DWAXIDMAC_IRQ_SRC_SLV_ERR | \
+			 DWAXIDMAC_IRQ_DST_DEC_ERR | \
+			 DWAXIDMAC_IRQ_DST_SLV_ERR)
+
+static const char *axi_chan_err_str(u32 status)
+{
+	if (status & DWAXIDMAC_IRQ_SRC_DEC_ERR)
+		return "source decode error";
+	if (status & DWAXIDMAC_IRQ_SRC_SLV_ERR)
+		return "source slave error";
+	if (status & DWAXIDMAC_IRQ_DST_DEC_ERR)
+		return "destination decode error";
+	if (status & DWAXIDMAC_IRQ_DST_SLV_ERR)
+		return "destination slave error";
+	if (status & DWAXIDMAC_IRQ_LLI_RD_DEC_ERR)
+		return "LLI read decode error";
+	if (status & DWAXIDMAC_IRQ_LLI_RD_SLV_ERR)
+		return "LLI read slave error";
+	if (status & DWAXIDMAC_IRQ_LLI_WR_DEC_ERR)
+		return "LLI write-back decode error";
+	if (status & DWAXIDMAC_IRQ_LLI_WR_SLV_ERR)
+		return "LLI write-back slave error";
+	if (status & DWAXIDMAC_IRQ_INVALID_ERR)
+		return "invalid LLI or shadow register";
+	if (status & DWAXIDMAC_IRQ_MULTIBLKTYPE_ERR)
+		return "invalid multi-block transfer type";
+	return "slave interface error";
+}
+
 static noinline void axi_chan_handle_err(struct axi_dma_chan *chan, u32 status)
 {
 	struct virt_dma_desc *vd;
@@ -1078,11 +1108,19 @@ static noinline void axi_chan_handle_err(struct axi_dma_chan *chan, u32 status)
 	/* Remove the completed descriptor from issued list */
 	list_del(&vd->node);
 
-	/* WARN about bad descriptor */
+	/*
+	 * SAR and DAR advance as each burst is issued, so with bursts still
+	 * outstanding they can be a little past the one that failed.
+	 */
 	dev_err(chan2dev(chan),
-		"Bad descriptor submitted for %s, cookie: %d, irq: 0x%08x\n",
-		axi_chan_name(chan), vd->tx.cookie, status);
-	axi_chan_list_dump_lli(chan, vd_to_axi_desc(vd));
+		"%s for %s, cookie: %d, irq: 0x%08x, SAR: 0x%llx DAR: 0x%llx LLP: 0x%llx\n",
+		axi_chan_err_str(status), axi_chan_name(chan), vd->tx.cookie,
+		status, lo_hi_readq(chan->chan_regs + CH_SAR),
+		lo_hi_readq(chan->chan_regs + CH_DAR),
+		lo_hi_readq(chan->chan_regs + CH_LLP));
+	/* Only dump LLIs on non-data errors */
+	if (status & (DWAXIDMAC_IRQ_ALL_ERR & ~AXI_DMA_DATA_ERR))
+		axi_chan_list_dump_lli(chan, vd_to_axi_desc(vd));
 
 	if (status & (DWAXIDMAC_IRQ_SRC_DEC_ERR | DWAXIDMAC_IRQ_SRC_SLV_ERR))
 		vd->tx_result.result = DMA_TRANS_READ_FAILED;

-- 
2.54.0

