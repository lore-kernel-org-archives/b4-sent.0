From: Nathan Lynch <nathan.lynch@amd.com>
Date: Fri, 10 Apr 2026 08:07:24 -0500
Subject: [PATCH 14/23] dmaengine: sdxi: Attach descriptor ring state to
 contexts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260410-sdxi-base-v1-14-1d184cb5c60a@amd.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775826467; l=2539;
 i=nathan.lynch@amd.com; s=20260410; h=from:subject:message-id;
 bh=osQr3BYuGP2fBkWl8ruQ505ci52JISit3XTQLri9FVw=;
 b=1EooEzzSz67Nn6PR20Q6rrCyRCAf3qi2P0cVNLda1cXwdfMEQU79c4wdjgA7Tz6eVMZAsqlR0
 4p8Xayjz17YBZrdP0wIg80eMQbmbgoBm+njik+C99Q3ypwk52Oq350F
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=PK4ozhq+/z9/2Jl5rgDmvHa9raVomv79qM8p1RAFpEw=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260410 with auth_id=728
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Attach an instance of struct sdxi_ring_state to each context upon
allocation. Each ring state has the same lifetime has its context and
is freed upon context release.

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/context.c | 13 +++++++++++++
 drivers/dma/sdxi/context.h |  2 ++
 2 files changed, 15 insertions(+)

diff --git a/drivers/dma/sdxi/context.c b/drivers/dma/sdxi/context.c
index 7cae140c0a20..792b5032203b 100644
--- a/drivers/dma/sdxi/context.c
+++ b/drivers/dma/sdxi/context.c
@@ -24,6 +24,7 @@
 
 #include "context.h"
 #include "hw.h"
+#include "ring.h"
 #include "sdxi.h"
 
 #define DEFAULT_DESC_RING_ENTRIES 1024
@@ -60,6 +61,7 @@ static void sdxi_free_cxt(struct sdxi_cxt *cxt)
 		dma_free_coherent(sdxi_to_dev(sdxi), sq->ring_size,
 				  sq->desc_ring, sq->ring_dma);
 	kfree(cxt->sq);
+	kfree(cxt->ring_state);
 	kfree(cxt);
 }
 
@@ -77,6 +79,10 @@ static struct sdxi_cxt *sdxi_alloc_cxt(struct sdxi_dev *sdxi)
 
 	cxt->sdxi = sdxi;
 
+	cxt->ring_state = kzalloc_obj(*cxt->ring_state, GFP_KERNEL);
+	if (!cxt->ring_state)
+		return NULL;
+
 	cxt->sq = kzalloc_obj(*cxt->sq, GFP_KERNEL);
 	if (!cxt->sq)
 		return NULL;
@@ -373,6 +379,8 @@ int sdxi_admin_cxt_init(struct sdxi_dev *sdxi)
 	sq->cxt_sts->state = FIELD_PREP(SDXI_CXT_STS_STATE, CXTV_RUN);
 	cxt->id = SDXI_ADMIN_CXT_ID;
 	cxt->db = sdxi->dbs + cxt->id * sdxi->db_stride;
+	sdxi_ring_state_init(cxt->ring_state, &sq->cxt_sts->read_index,
+			     sq->write_index, sq->ring_entries, sq->desc_ring);
 
 	err = sdxi_publish_cxt(cxt);
 	if (err)
@@ -389,10 +397,15 @@ int sdxi_admin_cxt_init(struct sdxi_dev *sdxi)
  */
 struct sdxi_cxt *sdxi_cxt_new(struct sdxi_dev *sdxi)
 {
+	struct sdxi_sq *sq;
+
 	struct sdxi_cxt *cxt __free(sdxi_cxt) = sdxi_alloc_cxt(sdxi);
 	if (!cxt)
 		return NULL;
 
+	sq = cxt->sq;
+	sdxi_ring_state_init(cxt->ring_state, &sq->cxt_sts->read_index,
+			     sq->write_index, sq->ring_entries, sq->desc_ring);
 	if (register_cxt(sdxi, cxt))
 		return NULL;
 
diff --git a/drivers/dma/sdxi/context.h b/drivers/dma/sdxi/context.h
index 5cd78e883c8d..9779b9aa4f86 100644
--- a/drivers/dma/sdxi/context.h
+++ b/drivers/dma/sdxi/context.h
@@ -54,6 +54,8 @@ struct sdxi_cxt {
 	dma_addr_t akey_table_dma;
 
 	struct sdxi_sq *sq;
+
+	struct sdxi_ring_state *ring_state;
 };
 
 int sdxi_admin_cxt_init(struct sdxi_dev *sdxi);

-- 
2.53.0

