From: Roland Dreier <rolanddreier@rivian.com>
Date: Tue, 06 Oct 2026 01:03:08 +0000
Subject: [PATCH 2/3] dmaengine: dw-axi-dmac: Report failed transfers in the
 descriptor result
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261006-dw-axi-fixes-v1-2-3b319e456d93@rivian.com>
References: <20261006-dw-axi-fixes-v1-0-3b319e456d93@rivian.com>
In-Reply-To: <20261006-dw-axi-fixes-v1-0-3b319e456d93@rivian.com>
To: Eugeniy Paltsev <Eugeniy.Paltsev@synopsys.com>, 
 Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>
Cc: dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Roland Dreier <rolanddreier@rivian.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791248589; l=1473;
 i=rolanddreier@rivian.com; s=20260814; h=from:subject:message-id;
 bh=dCofrQtsaToPcFMjK0WnPAuxqv/qWfmPzjG50ShhZtI=;
 b=bCwpgzy1rDeh+fkdCSIIb7DcxVLVKzfDguqxa7hSOrgx7ewVdEpXLrZzhCEjE+mpoKlP6zvtc
 9HHMxJAAt8zDHFlbLeWw5gn3FnxiNmryth7V2WCJVqPGVz7skvlXiaA
X-Developer-Key: i=rolanddreier@rivian.com; a=ed25519;
 pk=C7SBXsDIlarq7BpINqyDL67XV/AGNqNt09NCCpFcExk=
X-Endpoint-Received: by B4 Relay for rolanddreier@rivian.com/20260814 with auth_id=952
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

axi_chan_handle_err() completes a failed descriptor without updating
vd->tx_result. So clients using tx_result always get DMA_TRANS_NOERROR,
even for incomplete / failed transfers (bus error or other reason).

Set the result so a client can detect failures:
 - DMA_TRANS_READ_FAILED for source decode or slave errors
 - DMA_TRANS_WRITE_FAILED for destination decode or slave errors
 - DMA_TRANS_ABORTED for everything else

Assisted-by: LLM
Signed-off-by: Roland Dreier <rolanddreier@rivian.com>
---
 drivers/dma/dw-axi-dmac/dw-axi-dmac-platform.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/dma/dw-axi-dmac/dw-axi-dmac-platform.c b/drivers/dma/dw-axi-dmac/dw-axi-dmac-platform.c
index 813d17a278e7..88362f181207 100644
--- a/drivers/dma/dw-axi-dmac/dw-axi-dmac-platform.c
+++ b/drivers/dma/dw-axi-dmac/dw-axi-dmac-platform.c
@@ -1084,6 +1084,13 @@ static noinline void axi_chan_handle_err(struct axi_dma_chan *chan, u32 status)
 		axi_chan_name(chan), vd->tx.cookie, status);
 	axi_chan_list_dump_lli(chan, vd_to_axi_desc(vd));
 
+	if (status & (DWAXIDMAC_IRQ_SRC_DEC_ERR | DWAXIDMAC_IRQ_SRC_SLV_ERR))
+		vd->tx_result.result = DMA_TRANS_READ_FAILED;
+	else if (status & (DWAXIDMAC_IRQ_DST_DEC_ERR | DWAXIDMAC_IRQ_DST_SLV_ERR))
+		vd->tx_result.result = DMA_TRANS_WRITE_FAILED;
+	else
+		vd->tx_result.result = DMA_TRANS_ABORTED;
+
 	vchan_cookie_complete(vd);
 
 	/* Try to restart the controller */

-- 
2.54.0

