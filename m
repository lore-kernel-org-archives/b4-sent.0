From: Nathan Lynch <nathan.lynch@amd.com>
Date: Fri, 05 Jun 2026 19:02:13 -0500
Subject: [PATCH v3 10/23] dmaengine: sdxi: Complete administrative context
 jump start
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260605-sdxi-base-v3-10-4d38ca2bdffe@amd.com>
References: <20260605-sdxi-base-v3-0-4d38ca2bdffe@amd.com>
In-Reply-To: <20260605-sdxi-base-v3-0-4d38ca2bdffe@amd.com>
To: Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>
Cc: Bjorn Helgaas <bhelgaas@google.com>, 
 David Rientjes <rientjes@google.com>, John.Kariuki@amd.com, 
 Jonathan Cameron <jic23@kernel.org>, Kinsey Ho <kinseyho@google.com>, 
 Mario Limonciello <mario.limonciello@amd.com>, 
 PradeepVineshReddy.Kodamati@amd.com, Shivank Garg <shivankg@amd.com>, 
 Stephen Bates <Stephen.Bates@amd.com>, Tycho Andersen <tycho@kernel.org>, 
 Wei Huang <wei.huang2@amd.com>, Wei Xu <weixugc@google.com>, 
 dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pci@vger.kernel.org, Nathan Lynch <nathan.lynch@amd.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780704140; l=2039;
 i=nathan.lynch@amd.com; s=20260410; h=from:subject:message-id;
 bh=Xz7O1bmLJ7W3hisyPklvsix3wrpdn8nowta4bg4ztKU=;
 b=bBfy3bckto5YkTDFV48vvpTAsuE3lLh6h4IVtlPaE2wYbyYBuxemg+UbGB3UxB2untV4Sgd1L
 fdFf5AdtBQ4DF7SVjqKz/EQTEII7Yo38JBMUDxDtd0235zYQVuVOQYb
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=PK4ozhq+/z9/2Jl5rgDmvHa9raVomv79qM8p1RAFpEw=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260410 with auth_id=728
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Now that the SDXI function has been placed in active state, the admin
context can finally be started by writing its doorbell. Introduce
a sdxi_cxt_push_doorbell() helper to simplify this for callers; it
will be used in all descriptor submission paths.

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/context.h |  6 ++++++
 drivers/dma/sdxi/device.c  | 15 ++++++++++++++-
 2 files changed, 20 insertions(+), 1 deletion(-)

diff --git a/drivers/dma/sdxi/context.h b/drivers/dma/sdxi/context.h
index 65b773446ba3..d89e026a7736 100644
--- a/drivers/dma/sdxi/context.h
+++ b/drivers/dma/sdxi/context.h
@@ -7,6 +7,7 @@
 #define DMA_SDXI_CONTEXT_H
 
 #include <linux/dma-mapping.h>
+#include <linux/io.h>
 #include <linux/types.h>
 
 #include "hw.h"
@@ -58,4 +59,9 @@ struct sdxi_cxt {
 
 int sdxi_admin_cxt_init(struct sdxi_dev *sdxi);
 
+static inline void sdxi_cxt_push_doorbell(struct sdxi_cxt *cxt, u64 index)
+{
+	writeq(index, cxt->db);
+}
+
 #endif /* DMA_SDXI_CONTEXT_H */
diff --git a/drivers/dma/sdxi/device.c b/drivers/dma/sdxi/device.c
index e8f087f758fd..b875d8cdb58a 100644
--- a/drivers/dma/sdxi/device.c
+++ b/drivers/dma/sdxi/device.c
@@ -269,7 +269,20 @@ static int sdxi_fn_activate(struct sdxi_dev *sdxi)
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
 
 static int sdxi_device_init(struct sdxi_dev *sdxi)

-- 
2.54.0

