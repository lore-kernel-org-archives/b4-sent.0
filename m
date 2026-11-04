From: Nathan Lynch <nathan.lynch@amd.com>
Date: Tue, 03 Nov 2026 20:50:01 -0600
Subject: [PATCH v4 20/25] dmaengine: sdxi: Add client context release with
 update and sync
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-sdxi-base-v4-20-3668ccc7aab8@amd.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793760600; l=6419;
 i=nathan.lynch@amd.com; s=20260722; h=from:subject:message-id;
 bh=DyUho94aHD/s6qLu87Q74yX1eWXQuWFBmFBUTNvyZ70=;
 b=c0EsCJ4zJpMETA4m5fpESHZKanIxfR6hDGYSHc4bC7hNSdo9Pg5okyTxVUXk1fsqZ3HzOeq9t
 +sBiss4oNUDB9jMLArRw2j30t61L+YAKvM2Z+4PjZcOIsu0SS5c1edn
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=pO5+BCw/TENGLvwX5NYZOZmZihcxjkxeFSMuk47erps=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260722 with auth_id=891
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Invalidate an unused, stopped client context and synchronize hardware
caches before freeing its resources. Add administrative update, reservation, and
completion-polling helpers.

Claim completion-status storage before making an irrevocable ring
reservation. Return the claim if reservation fails, and release it after
consuming a terminal result. A timeout leaves hardware ownership
unresolved, so retain that block in the administrative pool until context
teardown, even if the device writes its terminal signal later. Repeated
timeouts can exhaust the pool, causing further claims to time out rather
than reuse outstanding status blocks.

If update or synchronization fails, retain the context and its ID for
cleanup after function shutdown. Device-wide teardown frees clients after
the best-effort function stop/reset path without submitting additional
administrative operations.

Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/context.c | 128 +++++++++++++++++++++++++++++++++++++++++++++
 drivers/dma/sdxi/context.h |   6 +++
 2 files changed, 134 insertions(+)

diff --git a/drivers/dma/sdxi/context.c b/drivers/dma/sdxi/context.c
index 679c5cfab19d..5ca99ac8080c 100644
--- a/drivers/dma/sdxi/context.c
+++ b/drivers/dma/sdxi/context.c
@@ -106,6 +106,78 @@ static struct sdxi_cxt *sdxi_alloc_cxt(struct sdxi_dev *sdxi)
 	return_ptr(cxt);
 }
 
+/* Claim completion storage before making a ring reservation irrevocable. */
+static int sdxi_cxt_reserve(struct sdxi_cxt *cxt, size_t nr,
+			    struct sdxi_ring_resv *resv,
+			    struct sdxi_completion *comp)
+{
+	int err;
+
+	err = sdxi_cst_pool_get_wait(cxt->cst_pool, comp);
+	if (err)
+		return err;
+
+	err = sdxi_ring_reserve(cxt->ring_state, nr, resv);
+	if (err)
+		sdxi_cst_pool_put(cxt->cst_pool, comp->cst_blk);
+
+	return err;
+}
+
+static int sdxi_cxt_poll_completion(struct sdxi_cxt *cxt,
+				    const struct sdxi_completion *comp)
+{
+	int err = sdxi_cst_blk_poll(comp->cst_blk);
+
+	/*
+	 * A timeout does not end hardware ownership. Keep these administrative
+	 * blocks claimed until context teardown, even if they complete later.
+	 * Repeated timeouts can exhaust the pool; allocation then times out too.
+	 */
+	if (err != -ETIMEDOUT)
+		sdxi_cst_pool_put(cxt->cst_pool, comp->cst_blk);
+	sdxi_ring_wake_up(cxt->ring_state);
+
+	return err;
+}
+
+/*
+ * Signal the function that a client context's control structures have
+ * been modified so it discards any privately cached copies of them.
+ * DSC_SYNC.CXT is required before the operation can be considered
+ * complete.
+ */
+static int sdxi_cxt_update(const struct sdxi_cxt *cxt)
+{
+	struct sdxi_cxt *adm = to_admin_cxt(cxt);
+	struct sdxi_slot upd, sync;
+	struct sdxi_ring_resv resv;
+	struct sdxi_completion comp;
+	int err;
+
+	might_sleep();
+
+	err = sdxi_cxt_reserve(adm, 2, &resv, &comp);
+	if (err)
+		return err;
+
+	upd = sdxi_ring_resv_slot(&resv, 0);
+	sync = sdxi_ring_resv_slot(&resv, 1);
+
+	sdxi_encode_cxt_upd(sdxi_slot_desc(upd), &(const struct sdxi_cxt_upd) {
+			.level = SDXI_CXT_UPD_LVL_L1,
+			.range = sdxi_cxt_range_single(cxt->id),
+		});
+	sdxi_encode_sync(sdxi_slot_desc(sync), &(const struct sdxi_sync) {
+			.filter = SDXI_SYNC_FLT_CXT,
+			.range = sdxi_cxt_range_single(cxt->id),
+		});
+	sdxi_cxt_submit(adm, upd, NULL, 0);
+	sdxi_cxt_submit(adm, sync, &comp, SDXI_CXT_SUBMIT_KICK);
+
+	return sdxi_cxt_poll_completion(adm, &comp);
+}
+
 struct sdxi_cxt_ctl_cfg {
 	dma_addr_t ds_ring_ptr;
 	dma_addr_t cxt_sts_ptr;
@@ -144,6 +216,16 @@ static int configure_cxt_ctl(struct sdxi_cxt_ctl *ctl, const struct sdxi_cxt_ctl
 	return 0;
 }
 
+static void invalidate_cxt_ctl(struct sdxi_cxt_ctl *ctl)
+{
+	u64 ds_ring_ptr = le64_to_cpu(ctl->ds_ring_ptr);
+
+	FIELD_MODIFY(SDXI_CXT_CTL_VL, &ds_ring_ptr, 0);
+	WRITE_ONCE(ctl->ds_ring_ptr, cpu_to_le64(ds_ring_ptr));
+	dma_wmb();
+	*ctl = (typeof(*ctl)) { 0 };
+}
+
 /*
  * Logical representation of CXT_L1_ENT subfields.
  */
@@ -194,6 +276,17 @@ static int configure_L1_entry(struct sdxi_cxt_L1_ent *ent,
 	return 0;
 }
 
+static void invalidate_L1_entry(struct sdxi_cxt_L1_ent *ent)
+{
+	u64 cxt_ctl_ptr = le64_to_cpu(ent->cxt_ctl_ptr);
+
+	FIELD_MODIFY(SDXI_CXT_L1_ENT_VL, &cxt_ctl_ptr, 0);
+	WRITE_ONCE(ent->cxt_ctl_ptr, cpu_to_le64(cxt_ctl_ptr));
+	dma_wmb();
+	*ent = (typeof(*ent)) { 0 };
+}
+
+
 /* Publish the context control block and L1 entry to hardware. */
 static int sdxi_publish_cxt(const struct sdxi_cxt *cxt)
 {
@@ -398,3 +491,38 @@ void sdxi_cxt_submit(struct sdxi_cxt *cxt, struct sdxi_slot slot,
 	if (flags & SDXI_CXT_SUBMIT_KICK)
 		sdxi_cxt_kick(cxt);
 }
+
+/*
+ * Release an unused, stopped client context. On update/sync failure the
+ * context remains owned by the device and its resources are retained for
+ * cleanup after function shutdown; the caller must not reuse it.
+ */
+int sdxi_cxt_exit(struct sdxi_cxt *cxt)
+{
+	struct sdxi_dev *sdxi = cxt->sdxi;
+	struct sdxi_cxt_L1_ent *ent;
+	u8 state;
+	int err;
+
+	if (WARN_ON(sdxi_cxt_is_admin(cxt)))
+		return -EINVAL;
+
+	state = FIELD_GET(SDXI_CXT_STS_STATE, READ_ONCE(cxt->sq->cxt_sts.state));
+	if (state != CXTV_STOP_SW && state != CXTV_STOP_FN && state != CXTV_ERR_FN)
+		return -EBUSY;
+
+	ent = &sdxi->L1_table->entry[ID_TO_L1_INDEX(cxt->id)];
+	invalidate_L1_entry(ent);
+	invalidate_cxt_ctl(cxt->cxt_ctl);
+
+	err = sdxi_cxt_update(cxt);
+	if (err) {
+		dev_err(sdxi->dev,
+			"context %u release failed (%d), retaining resources until function shutdown\n",
+			cxt->id, err);
+		return err;
+	}
+
+	sdxi_free_cxt(cxt);
+	return 0;
+}
diff --git a/drivers/dma/sdxi/context.h b/drivers/dma/sdxi/context.h
index f048e298f6de..71eef2c6243b 100644
--- a/drivers/dma/sdxi/context.h
+++ b/drivers/dma/sdxi/context.h
@@ -52,6 +52,12 @@ struct sdxi_cxt {
 
 int sdxi_admin_cxt_init(struct sdxi_dev *sdxi);
 struct sdxi_cxt *sdxi_cxt_new(struct sdxi_dev *sdxi);
+/*
+ * Caller must exclude users and stop the client before release. An update or
+ * synchronization failure retains the invalidated context for device teardown;
+ * the caller must not reuse it.
+ */
+int sdxi_cxt_exit(struct sdxi_cxt *cxt);
 void sdxi_client_cxts_exit(struct sdxi_dev *sdxi);
 
 enum sdxi_submit_flags {

-- 
2.56.0

