From: Nathan Lynch <nathan.lynch@amd.com>
Date: Tue, 26 Aug 2025 11:07:38 -0500
Subject: [PATCH RESEND] dmaengine: Fix dma_async_tx_descriptor->tx_submit
 documentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250826-dma_async_tx_desc-tx_submit-doc-fix-v1-1-18a4b51697db@amd.com>
X-B4-Tracking: v=1; b=H4sIAMnbrWgC/x2NMQvCMBBG/0q52YOaagnOdu2go0hIcle9oankq
 lRK/7vB6fHe8H0rKGdhhVO1QuaPqEypyH5XQXz69GAUKg6mNsfamhZp9M7rN0U3L45YIxbqO4w
 yI00RB1mwCZZsaIcDxQbK0itzyf+XG1y6a9ef4b5tP2/pqXF9AAAA
X-Change-ID: 20250826-dma_async_tx_desc-tx_submit-doc-fix-3b8d8b6f4dc3
To: Vinod Koul <vkoul@kernel.org>, Randy Dunlap <rdunlap@infradead.org>
Cc: dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dave Jiang <dave.jiang@intel.com>, Nathan Lynch <nathan.lynch@amd.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756224459; l=1773;
 i=nathan.lynch@amd.com; s=20241010; h=from:subject:message-id;
 bh=dIS6RoLkC1q3aI/0+NdaHu4Yd3RD9SjlUuZZHRlnaK8=;
 b=kKd1JVU0GPX4JoS9X5N5yAf9XN3rDuTtvp0R4k3NWvYCBveJlX5Eo2PK+jS4ERpVmfrXOSWjO
 uYYYnlNiM1EC9UGsIEYBOMW6hSpUb2zhB30IxZK8DxdL0pXMlol+IGy
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
Reviewed-by: Dave Jiang <dave.jiang@intel.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
Originally sent 12 Mar 2025:
https://lore.kernel.org/dmaengine/20250312-dma_async_tx_desc-tx_submit-doc-v1-1-16390060264c@amd.com/
---
 include/linux/dmaengine.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/include/linux/dmaengine.h b/include/linux/dmaengine.h
index 6de7c05d6bd8c99e176fe2fde0a9c3b55d40b37c..99efe2b9b4ea9844ca6161208362ef18ef111d96 100644
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
base-commit: 8f5ae30d69d7543eee0d70083daf4de8fe15d585
change-id: 20250826-dma_async_tx_desc-tx_submit-doc-fix-3b8d8b6f4dc3

Best regards,
-- 
Nathan Lynch <nathan.lynch@amd.com>

