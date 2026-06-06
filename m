From: Nathan Lynch <nathan.lynch@amd.com>
Date: Fri, 05 Jun 2026 19:02:14 -0500
Subject: [PATCH v3 11/23] dmaengine: sdxi: Add client context alloc and
 release APIs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260605-sdxi-base-v3-11-4d38ca2bdffe@amd.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780704140; l=7890;
 i=nathan.lynch@amd.com; s=20260410; h=from:subject:message-id;
 bh=bg5O6c12/89MBViyHySgKBGfrFpvaHJA7C+k35wt+Xk=;
 b=b2eWWMlJFn47HBaF90EaILUcVFrLeyTss8WVO8xbtXgltu/vm0TPi+mZ/j7kzMQsepeKzHGmU
 BkH4MZ3BkSNAf8eV7BjpUML8Jp3sCJxawCa/wh4y4+lxKNFsM/98KcF
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=PK4ozhq+/z9/2Jl5rgDmvHa9raVomv79qM8p1RAFpEw=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260410 with auth_id=728
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Expose sdxi_cxt_new() and sdxi_cxt_exit(), which are the rest of the
driver's entry points to creating and releasing SDXI contexts.

Track client contexts in a device-wide allocating xarray, mapping
context ID to the context object. The admin context always has ID 0,
so begin allocations at 1. Define a local sdxi_cxt_id class to
facilitate early allocation (before committing more resources) and
automatic release of context IDs.

Introduce new code to invalidate a context's entry in the L1 table on
deallocation.

Support for starting and stopping contexts will be added in changes to
follow.

The only expected user of sdxi_cxt_new() and sdxi_cxt_exit() at this
point is the DMA engine provider code where a client context per
channel will be created.

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/sdxi/context.c | 122 +++++++++++++++++++++++++++++++++++++++++++++
 drivers/dma/sdxi/context.h |  13 +++++
 drivers/dma/sdxi/device.c  |   8 +++
 drivers/dma/sdxi/sdxi.h    |   2 +
 4 files changed, 145 insertions(+)

diff --git a/drivers/dma/sdxi/context.c b/drivers/dma/sdxi/context.c
index cc99fe9ecf92..2f9a29df5d9c 100644
--- a/drivers/dma/sdxi/context.c
+++ b/drivers/dma/sdxi/context.c
@@ -44,6 +44,10 @@ static void sdxi_free_cxt(struct sdxi_cxt *cxt)
 	struct sdxi_dev *sdxi = cxt->sdxi;
 	struct sdxi_sq *sq = cxt->sq;
 
+	/* Release the id if this is a client context. */
+	if (cxt->id)
+		WARN_ON(xa_erase(&sdxi->client_cxts, cxt->id) != cxt);
+
 	if (cxt->cxt_ctl)
 		dma_pool_free(sdxi->cxt_ctl_pool, cxt->cxt_ctl,
 			      cxt->cxt_ctl_dma);
@@ -154,6 +158,16 @@ static int configure_cxt_ctl(struct sdxi_cxt_ctl *ctl, const struct sdxi_cxt_ctl
 	return 0;
 }
 
+static void invalidate_cxtl_ctl(struct sdxi_cxt_ctl *ctl)
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
@@ -208,6 +222,16 @@ static int configure_L1_entry(struct sdxi_cxt_L1_ent *ent,
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
 /*
  * Make the context control structure hierarchy valid from the POV of
  * the SDXI implementation. This may eventually involve allocation of
@@ -258,6 +282,17 @@ static int sdxi_publish_cxt(const struct sdxi_cxt *cxt)
 	/* todo: need to send DSC_CXT_UPD to admin */
 }
 
+/* Invalidate a context. */
+static void sdxi_rescind_cxt(struct sdxi_cxt *cxt)
+{
+	u8 l1_idx = ID_TO_L1_INDEX(cxt->id);
+	struct sdxi_cxt_L1_ent *ent = &cxt->sdxi->L1_table->entry[l1_idx];
+
+	invalidate_L1_entry(ent);
+	invalidate_cxtl_ctl(cxt->cxt_ctl);
+	/* todo: need to send DSC_CXT_UPD to admin */
+}
+
 static void free_admin_cxt(void *ptr)
 {
 	struct sdxi_dev *sdxi = ptr;
@@ -288,3 +323,90 @@ int sdxi_admin_cxt_init(struct sdxi_dev *sdxi)
 
 	return devm_add_action_or_reset(sdxi->dev, free_admin_cxt, sdxi);
 }
+
+/*
+ * Temporary owner for context id until it can be assigned to a
+ * context object; enables scope-based cleanup.
+ */
+struct sdxi_cxt_id {
+	struct sdxi_dev *sdxi;
+	u16 index;
+};
+
+static void sdxi_cxt_id_dtor(const struct sdxi_cxt_id *cxt_id)
+{
+	if (cxt_id->index == 0)
+		return;
+	WARN_ON(xa_erase(&cxt_id->sdxi->client_cxts, cxt_id->index) != NULL);
+}
+
+static struct sdxi_cxt_id sdxi_cxt_id_ctor(struct sdxi_dev *sdxi)
+{
+	struct xa_limit limit = XA_LIMIT(1, sdxi->max_cxtid);
+	u32 index;
+
+	return (struct sdxi_cxt_id) {
+		.sdxi = sdxi,
+		.index = xa_alloc(&sdxi->client_cxts, &index, NULL,
+				  limit, GFP_KERNEL) ? 0 : (u16)index,
+	};
+}
+
+DEFINE_CLASS(sdxi_cxt_id, struct sdxi_cxt_id, sdxi_cxt_id_dtor(&_T),
+	     sdxi_cxt_id_ctor(sdxi), struct sdxi_dev *sdxi)
+
+static bool sdxi_cxt_id_valid(const struct sdxi_cxt_id *cxt_id)
+{
+	return cxt_id->index > 0;
+}
+
+/*
+ * Transfer ownership of the id to the context object, recording the
+ * context pointer in the device's client_cxt xarray. sdxi_cxt_free()
+ * is responsible for releasing the id from now on.
+ */
+static void sdxi_cxt_id_assign(struct sdxi_cxt *cxt, struct sdxi_cxt_id *cxt_id)
+{
+	/* We reserved the space in the constructor so this should not fail. */
+	WARN_ON(xa_store(&cxt_id->sdxi->client_cxts,
+			 cxt_id->index, cxt, GFP_KERNEL));
+	cxt->id = cxt_id->index;
+	cxt_id->index = 0;
+}
+
+/*
+ * Allocate a context for in-kernel use. Starting the context is the
+ * caller's responsibility.
+ */
+struct sdxi_cxt *sdxi_cxt_new(struct sdxi_dev *sdxi)
+{
+	/*
+	 * Ensure an ID is available before allocating memory for the
+	 * context and its control structures.
+	 */
+	CLASS(sdxi_cxt_id, id)(sdxi);
+	if (!sdxi_cxt_id_valid(&id))
+		return NULL;
+
+	struct sdxi_cxt *cxt __free(sdxi_cxt) = sdxi_alloc_cxt(sdxi);
+	if (!cxt)
+		return NULL;
+
+	sdxi_cxt_id_assign(cxt, &id);
+
+	cxt->db = sdxi->dbs + cxt->id * sdxi->db_stride;
+
+	if (sdxi_publish_cxt(cxt))
+		return NULL;
+
+	return_ptr(cxt);
+}
+
+void sdxi_cxt_exit(struct sdxi_cxt *cxt)
+{
+	if (WARN_ON(sdxi_cxt_is_admin(cxt)))
+		return;
+
+	sdxi_rescind_cxt(cxt);
+	sdxi_free_cxt(cxt);
+}
diff --git a/drivers/dma/sdxi/context.h b/drivers/dma/sdxi/context.h
index d89e026a7736..42e377bb2446 100644
--- a/drivers/dma/sdxi/context.h
+++ b/drivers/dma/sdxi/context.h
@@ -59,6 +59,19 @@ struct sdxi_cxt {
 
 int sdxi_admin_cxt_init(struct sdxi_dev *sdxi);
 
+struct sdxi_cxt *sdxi_cxt_new(struct sdxi_dev *sdxi);
+void sdxi_cxt_exit(struct sdxi_cxt *cxt);
+
+static inline struct sdxi_cxt *to_admin_cxt(const struct sdxi_cxt *cxt)
+{
+	return cxt->sdxi->admin_cxt;
+}
+
+static inline bool sdxi_cxt_is_admin(const struct sdxi_cxt *cxt)
+{
+	return cxt == to_admin_cxt(cxt);
+}
+
 static inline void sdxi_cxt_push_doorbell(struct sdxi_cxt *cxt, u64 index)
 {
 	writeq(index, cxt->db);
diff --git a/drivers/dma/sdxi/device.c b/drivers/dma/sdxi/device.c
index b875d8cdb58a..d3d1ad2f2eff 100644
--- a/drivers/dma/sdxi/device.c
+++ b/drivers/dma/sdxi/device.c
@@ -18,6 +18,7 @@
 #include <linux/minmax.h>
 #include <linux/slab.h>
 #include <linux/time.h>
+#include <linux/xarray.h>
 
 #include "context.h"
 #include "hw.h"
@@ -333,6 +334,7 @@ int sdxi_register(struct device *dev, const struct sdxi_bus_ops *ops)
 
 	sdxi->dev = dev;
 	sdxi->bus_ops = ops;
+	xa_init_flags(&sdxi->client_cxts, XA_FLAGS_ALLOC1);
 	dev_set_drvdata(dev, sdxi);
 
 	err = sdxi->bus_ops->init(sdxi);
@@ -346,6 +348,12 @@ EXPORT_SYMBOL_NS_GPL(sdxi_register, "SDXI");
 void sdxi_unregister(struct device *dev)
 {
 	struct sdxi_dev *sdxi = dev_get_drvdata(dev);
+	struct sdxi_cxt *cxt;
+	unsigned long index;
+
+	xa_for_each(&sdxi->client_cxts, index, cxt)
+		sdxi_cxt_exit(cxt);
+	xa_destroy(&sdxi->client_cxts);
 
 	sdxi_dev_stop(sdxi);
 }
diff --git a/drivers/dma/sdxi/sdxi.h b/drivers/dma/sdxi/sdxi.h
index a15b97135308..4e29d1f90dae 100644
--- a/drivers/dma/sdxi/sdxi.h
+++ b/drivers/dma/sdxi/sdxi.h
@@ -12,6 +12,7 @@
 #include <linux/dev_printk.h>
 #include <linux/io.h>
 #include <linux/types.h>
+#include <linux/xarray.h>
 
 #include "mmio.h"
 
@@ -59,6 +60,7 @@ struct sdxi_dev {
 	struct dma_pool *cst_blk_pool;
 
 	struct sdxi_cxt *admin_cxt;
+	struct xarray client_cxts; /* context id -> (struct sdxi_cxt *) */
 
 	const struct sdxi_bus_ops *bus_ops;
 };

-- 
2.54.0

