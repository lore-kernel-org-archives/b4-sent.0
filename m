From: Nathan Lynch <nathan.lynch@amd.com>
Date: Fri, 10 Apr 2026 08:07:20 -0500
Subject: [PATCH 10/23] dmaengine: sdxi: Complete administrative context
 jump start
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260410-sdxi-base-v1-10-1d184cb5c60a@amd.com>
References: <20260410-sdxi-base-v1-0-1d184cb5c60a@amd.com>
In-Reply-To: <20260410-sdxi-base-v1-0-1d184cb5c60a@amd.com>
To: Vinod Koul <vkoul@kernel.org>
Cc: Wei Huang <wei.huang2@amd.com>, 
 Mario Limonciello <mario.limonciello@amd.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Jonathan Cameron <jonathan.cameron@huawei.com>, 
 Stephen Bates <Stephen.Bates@amd.com>, PradeepVineshReddy.Kodamati@amd.com, 
 John.Kariuki@amd.com, linux-pci@vger.kernel.org, 
 linux-kernel@vger.kernel.org, dmaengine@vger.kernel.org, 
 Nathan Lynch <nathan.lynch@amd.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775826467; l=2661;
 i=nathan.lynch@amd.com; s=20260410; h=from:subject:message-id;
 bh=kubAcpoNvMH0mX/GJJdrwMYFQK1FnJy4kZUeWUFVoLw=;
 b=7pj9RgnhwKsDbTwFx6YSm1hoIlRSARyL8X3IESnCY+LyM8dxaxYEWK1wLINHf77w93JiWP2AD
 2nopQyUJRXTCKSmk2UdY9lvB6Jz4ldpN5EmC8pDiHFBqka38tBGG5B4
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=PK4ozhq+/z9/2Jl5rgDmvHa9raVomv79qM8p1RAFpEw=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260410 with auth_id=728
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Now that the SDXI function has been placed in active state, the admin
context can finally be started by writing its doorbell. Introduce
sdxi_cxt_push_doorbell() to pair the necessary barrier with the
doorbell update.

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/context.c |  8 ++++++++
 drivers/dma/sdxi/context.h |  2 ++
 drivers/dma/sdxi/device.c  | 15 ++++++++++++++-
 3 files changed, 24 insertions(+), 1 deletion(-)

diff --git a/drivers/dma/sdxi/context.c b/drivers/dma/sdxi/context.c
index 097d871e530f..934c487b4774 100644
--- a/drivers/dma/sdxi/context.c
+++ b/drivers/dma/sdxi/context.c
@@ -16,6 +16,7 @@
 #include <linux/dmapool.h>
 #include <linux/errno.h>
 #include <linux/iommu.h>
+#include <linux/io-64-nonatomic-lo-hi.h>
 #include <linux/slab.h>
 #include <linux/types.h>
 #include <asm/barrier.h>
@@ -258,6 +259,13 @@ static int sdxi_publish_cxt(const struct sdxi_cxt *cxt)
 	/* todo: need to send DSC_CXT_UPD to admin */
 }
 
+void sdxi_cxt_push_doorbell(struct sdxi_cxt *cxt, u64 index)
+{
+	/* Ensure preceding write index increment is visible. */
+	dma_wmb();
+	iowrite64(index, cxt->db);
+}
+
 static void free_admin_cxt(void *ptr)
 {
 	struct sdxi_dev *sdxi = ptr;
diff --git a/drivers/dma/sdxi/context.h b/drivers/dma/sdxi/context.h
index bbde1fd49af3..c34acd730acb 100644
--- a/drivers/dma/sdxi/context.h
+++ b/drivers/dma/sdxi/context.h
@@ -58,4 +58,6 @@ struct sdxi_cxt {
 
 int sdxi_admin_cxt_init(struct sdxi_dev *sdxi);
 
+void sdxi_cxt_push_doorbell(struct sdxi_cxt *cxt, u64 index);
+
 #endif /* DMA_SDXI_CONTEXT_H */
diff --git a/drivers/dma/sdxi/device.c b/drivers/dma/sdxi/device.c
index 145aa098c269..15f61d1ce490 100644
--- a/drivers/dma/sdxi/device.c
+++ b/drivers/dma/sdxi/device.c
@@ -244,7 +244,20 @@ static int sdxi_fn_activate(struct sdxi_dev *sdxi)
 	 * SDXI 1.0 4.1.8.9: Set MMIO_CTL0.fn_gsr to GSRV_ACTIVE and
 	 * wait for MMIO_STS0.fn_gsv to reach GSV_ACTIVE or GSV_ERROR.
 	 */
-	return sdxi_dev_start(sdxi);
+	err = sdxi_dev_start(sdxi);
+	if (err)
+		return err;
+
+	/*
+	 * SDXI 1.0 4.1.8.10.b: Start the admin context using method
+	 * #3 ("Jump Start 1") from 4.3.4 Starting A Context and
+	 * Context Signaling. We haven't queued any descriptors to the
+	 * admin context at this point, so the appropriate value for
+	 * the doorbell is 0.
+	 */
+	sdxi_cxt_push_doorbell(sdxi->admin_cxt, 0);
+
+	return 0;
 }
 
 static int sdxi_create_dma_pool(struct sdxi_dev *sdxi, struct dma_pool **pool,

-- 
2.53.0

