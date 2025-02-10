From: Nathan Lynch <nathan.lynch@amd.com>
Date: Mon, 10 Feb 2025 17:29:11 -0600
Subject: [PATCH] dmaengine: Remove device_prep_dma_imm_data from struct
 dma_device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250210-dmaengine-drop-imm-data-v1-1-e017766da2fa@amd.com>
X-B4-Tracking: v=1; b=H4sIAMaLqmcC/x3MSwqEMBBF0a1IjbsgBsXPVqQHhXnRGiRKItIQ3
 HsHh2dwb6GMpMg0N4USbs16xIr209C6S9zA6qrJGtsb2xp2QRA3jWCXjpM1BHZyCftBRgzd5Fd
 4qvWZ4PX3npfv8/wBAttvX2kAAAA=
X-Change-ID: 20250210-dmaengine-drop-imm-data-f7a8e749fcef
To: Vinod Koul <vkoul@kernel.org>
Cc: dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nathan Lynch <nathan.lynch@amd.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739230184; l=1774;
 i=nathan.lynch@amd.com; s=20241010; h=from:subject:message-id;
 bh=sXjE4x9Dbe9KQkwP5XNR830aZAR+1CIxnoSjbiiaAbk=;
 b=XxCcMUYHxv5qITDImcQuJbWFVgkGchmfqg8g+UnTZ+n01bHul4r3+72ROxnXuy50Y+PFTsq2g
 xhgZBPLLoMLA2zs83eJsaGaNy9ssNCyPOEhUMpgnv7mRGiXHVP+zG/d
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=ZR637UTGg5YLDj56cxFeHdYoUjPMMFbcijfOkAmAnbc=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20241010 with auth_id=241
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The device_prep_dma_imm_data() method isn't implemented or invoked by
any code since commit 80ade22c06ca ("misc: mic: remove the MIC drivers").

Remove it, shrinking struct dma_device by a few bytes.

Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 include/linux/dmaengine.h | 4 ----
 1 file changed, 4 deletions(-)

diff --git a/include/linux/dmaengine.h b/include/linux/dmaengine.h
index a360e0330436470bfea17f8df567ff785e4293ea..bb146c5ac3e4ccd7bc0afbf3b28e5b3d659ad62f 100644
--- a/include/linux/dmaengine.h
+++ b/include/linux/dmaengine.h
@@ -839,7 +839,6 @@ struct dma_filter {
  *	The function takes a buffer of size buf_len. The callback function will
  *	be called after period_len bytes have been transferred.
  * @device_prep_interleaved_dma: Transfer expression in a generic way.
- * @device_prep_dma_imm_data: DMA's 8 byte immediate data to the dst address
  * @device_caps: May be used to override the generic DMA slave capabilities
  *	with per-channel specific ones
  * @device_config: Pushes a new configuration to a channel, return 0 or an error
@@ -942,9 +941,6 @@ struct dma_device {
 	struct dma_async_tx_descriptor *(*device_prep_interleaved_dma)(
 		struct dma_chan *chan, struct dma_interleaved_template *xt,
 		unsigned long flags);
-	struct dma_async_tx_descriptor *(*device_prep_dma_imm_data)(
-		struct dma_chan *chan, dma_addr_t dst, u64 data,
-		unsigned long flags);
 
 	void (*device_caps)(struct dma_chan *chan, struct dma_slave_caps *caps);
 	int (*device_config)(struct dma_chan *chan, struct dma_slave_config *config);

---
base-commit: 2c17e9ea0caa5555e31e154fa1b06260b816f5cc
change-id: 20250210-dmaengine-drop-imm-data-f7a8e749fcef

Best regards,
-- 
Nathan Lynch <nathan.lynch@amd.com>

