From: Nathan Lynch <nathan.lynch@amd.com>
Date: Tue, 03 Nov 2026 20:50:02 -0600
Subject: [PATCH v4 21/25] dmaengine: sdxi: Provide context start and stop
 APIs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-sdxi-base-v4-21-3668ccc7aab8@amd.com>
References: <20261103-sdxi-base-v4-0-3668ccc7aab8@amd.com>
In-Reply-To: <20261103-sdxi-base-v4-0-3668ccc7aab8@amd.com>
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
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793760600; l=3502;
 i=nathan.lynch@amd.com; s=20260722; h=from:subject:message-id;
 bh=WiX3Tqeldc4IPKX4oqsKJ8nPLPgMYEiqvrHy0gtdIWQ=;
 b=PtTdQnyKMzWBAsxUOJc7gmMZe9bigIh1gKSIz4okf4v0hkrfEmgTIgq13+mcmGN8GsUs3Qx+g
 vvn3qjSRNHyC6ovn7H2hIYLzlOZmmebOMeZoQJK9yxEYv00XSWhWWPM
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=pO5+BCw/TENGLvwX5NYZOZmZihcxjkxeFSMuk47erps=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260722 with auth_id=891
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement client context start and stop by submitting administrative
descriptors. Starting waits for the start descriptor to finish; stopping
submits stop followed by synchronization and waits for the latter.

Use the administrative reservation and polling helpers to claim status
blocks before reserving descriptors, release consumed results, and retain
timed-out blocks until context teardown. Expose these operations through
struct sdxi_cxt for clients such as the DMAengine provider.

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/context.c | 61 ++++++++++++++++++++++++++++++++++++++++++++++
 drivers/dma/sdxi/context.h |  3 +++
 2 files changed, 64 insertions(+)

diff --git a/drivers/dma/sdxi/context.c b/drivers/dma/sdxi/context.c
index 5ca99ac8080c..0979fa35346b 100644
--- a/drivers/dma/sdxi/context.c
+++ b/drivers/dma/sdxi/context.c
@@ -364,6 +364,67 @@ int sdxi_admin_cxt_init(struct sdxi_dev *sdxi)
 	return devm_add_action_or_reset(sdxi->dev, free_admin_cxt, sdxi);
 }
 
+int sdxi_start_cxt(struct sdxi_cxt *cxt)
+{
+	struct sdxi_cxt *adm = to_admin_cxt(cxt);
+	struct sdxi_ring_resv resv;
+	struct sdxi_completion comp;
+	struct sdxi_slot start;
+	int err;
+
+	might_sleep();
+
+	/* Administrative context activation is controlled by the function state. */
+	if (WARN_ON(adm == cxt))
+		return -EINVAL;
+
+	err = sdxi_cxt_reserve(adm, 1, &resv, &comp);
+	if (err)
+		return err;
+
+	start = sdxi_ring_resv_slot(&resv, 0);
+	sdxi_encode_cxt_start(sdxi_slot_desc(start), &(const struct sdxi_cxt_start) {
+			.range = sdxi_cxt_range_single(cxt->id),
+		});
+	sdxi_cxt_submit(adm, start, &comp, SDXI_CXT_SUBMIT_KICK);
+
+	return sdxi_cxt_poll_completion(adm, &comp);
+}
+
+void sdxi_stop_cxt(struct sdxi_cxt *cxt)
+{
+	struct sdxi_cxt *adm = to_admin_cxt(cxt);
+	struct sdxi_slot stop, sync;
+	struct sdxi_ring_resv resv;
+	struct sdxi_completion comp;
+	int err;
+
+	might_sleep();
+
+	/* Administrative context stopping is controlled by the function state. */
+	if (WARN_ON(adm == cxt))
+		return;
+
+	err = sdxi_cxt_reserve(adm, 2, &resv, &comp);
+	if (WARN_ON_ONCE(err))
+		return;
+
+	stop = sdxi_ring_resv_slot(&resv, 0);
+	sync = sdxi_ring_resv_slot(&resv, 1);
+
+	sdxi_encode_cxt_stop(sdxi_slot_desc(stop), &(const struct sdxi_cxt_stop) {
+			.range = sdxi_cxt_range_single(cxt->id),
+		});
+	sdxi_encode_sync(sdxi_slot_desc(sync), &(const struct sdxi_sync) {
+			.filter = SDXI_SYNC_FLT_STOP,
+			.range = sdxi_cxt_range_single(cxt->id),
+		});
+	sdxi_cxt_submit(adm, stop, NULL, 0);
+	sdxi_cxt_submit(adm, sync, &comp, SDXI_CXT_SUBMIT_KICK);
+
+	WARN_ON(sdxi_cxt_poll_completion(adm, &comp));
+}
+
 /*
  * Temporary owner for context id until it can be assigned to a
  * context object; enables scope-based cleanup.
diff --git a/drivers/dma/sdxi/context.h b/drivers/dma/sdxi/context.h
index 71eef2c6243b..acf41709c4de 100644
--- a/drivers/dma/sdxi/context.h
+++ b/drivers/dma/sdxi/context.h
@@ -60,6 +60,9 @@ struct sdxi_cxt *sdxi_cxt_new(struct sdxi_dev *sdxi);
 int sdxi_cxt_exit(struct sdxi_cxt *cxt);
 void sdxi_client_cxts_exit(struct sdxi_dev *sdxi);
 
+int sdxi_start_cxt(struct sdxi_cxt *cxt);
+void sdxi_stop_cxt(struct sdxi_cxt *cxt);
+
 enum sdxi_submit_flags {
 	SDXI_CXT_SUBMIT_KICK  = BIT(0),
 	SDXI_CXT_SUBMIT_FENCE = BIT(1),

-- 
2.56.0

