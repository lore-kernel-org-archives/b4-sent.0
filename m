From: Nathan Lynch <nathan.lynch@amd.com>
Date: Wed, 12 Mar 2025 10:32:50 -0500
Subject: [PATCH] dmaengine: Fix dma_async_tx_descriptor->tx_submit
 documentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250312-dma_async_tx_desc-tx_submit-doc-v1-1-16390060264c@amd.com>
X-B4-Tracking: v=1; b=H4sIACGp0WcC/x2NwQqDMBAFf0X23AVNK4i/UkqIm6fuwViytljEf
 2/wNMxl5iBDVhj11UEZXzVdU5HmVpHMIU1gjcXJ1a6t743juAQf7JfEb7uPMOFC+wyLbhxX4bY
 LDxkBh26gUnlnjLpfh+frPP84Wem8cQAAAA==
X-Change-ID: 20250312-dma_async_tx_desc-tx_submit-doc-58a4cfee2e8b
To: Vinod Koul <vkoul@kernel.org>, Randy Dunlap <rdunlap@infradead.org>
Cc: dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nathan Lynch <nathan.lynch@amd.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741793579; l=1583;
 i=nathan.lynch@amd.com; s=20241010; h=from:subject:message-id;
 bh=jp/DMy7JLfNicBeQPv3Ol20fnz7oTC0prR6cxoePnxE=;
 b=Mgbv/xwUHT1whJBL31TEUUUXdJfr2k6dY0JVcSLvH5yc3PnMmNCEzdW3p4i45rFohDbZJBN9w
 +xPAaXzrtP4Dd41ZF6C8Aw++raCCJPJa/3lwGJp9wqXu1XDLMq0HvCQ
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=ZR637UTGg5YLDj56cxFeHdYoUjPMMFbcijfOkAmAnbc=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20241010 with auth_id=241
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 790fb9956eea ("linux/dmaengine.h: fix a few kernel-doc
warnings") inserted new documentation for @desc_free in the middle of
@tx_submit's description.

Put @tx_submit's description back together, matching the indentation
style of the rest of the documentation for dma_async_tx_descriptor.

Fixes: 790fb9956eea ("linux/dmaengine.h: fix a few kernel-doc warnings")
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 include/linux/dmaengine.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/include/linux/dmaengine.h b/include/linux/dmaengine.h
index bb146c5ac3e4ccd7bc0afbf3b28e5b3d659ad62f..51e1e357892a0325646f82d580b199321d59ced4 100644
--- a/include/linux/dmaengine.h
+++ b/include/linux/dmaengine.h
@@ -594,9 +594,9 @@ struct dma_descriptor_metadata_ops {
  * @phys: physical address of the descriptor
  * @chan: target channel for this operation
  * @tx_submit: accept the descriptor, assign ordered cookie and mark the
+ *	descriptor pending. To be pushed on .issue_pending() call
  * @desc_free: driver's callback function to free a resusable descriptor
  *	after completion
- * descriptor pending. To be pushed on .issue_pending() call
  * @callback: routine to call after this operation is complete
  * @callback_result: error result from a DMA transaction
  * @callback_param: general parameter to pass to the callback routine

---
base-commit: 6565439894570a07b00dba0b739729fe6b56fba4
change-id: 20250312-dma_async_tx_desc-tx_submit-doc-58a4cfee2e8b

Best regards,
-- 
Nathan Lynch <nathan.lynch@amd.com>

