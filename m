From: Nathan Lynch <nathan.lynch@amd.com>
Date: Fri, 10 Apr 2026 08:07:21 -0500
Subject: [PATCH 11/23] dmaengine: sdxi: Add client context alloc and
 release APIs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260410-sdxi-base-v1-11-1d184cb5c60a@amd.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775826467; l=7502;
 i=nathan.lynch@amd.com; s=20260410; h=from:subject:message-id;
 bh=L09ifU2t1M66vemGzv844gf5trJUsLLPkMvoKJ9/BWU=;
 b=1wnV9tnj4bjG+TusTQcZRbOfOcwafacenADlcgVb9vf+dMBelEbNHJutiK8mBDq5FrgtayL7e
 ee9XuJBASLiANTLPt64q12nZrouPjHd6BC0fpsloQuUxvtXK3JyRrYk
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=PK4ozhq+/z9/2Jl5rgDmvHa9raVomv79qM8p1RAFpEw=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260410 with auth_id=728
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Expose sdxi_cxt_new() and sdxi_cxt_exit(), which are the rest of the
driver's entry points to creating and releasing SDXI contexts.

Track client contexts in a device-wide allocating xarray, mapping
context ID to the context object. The admin context always has ID 0,
so begin allocations at 1. Define a local class for ID allocation to
facilitate automatic release of an ID if an error is encountered when
"publishing" a context to the L1 table.

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
 drivers/dma/sdxi/context.c | 111 +++++++++++++++++++++++++++++++++++++++++++++
 drivers/dma/sdxi/context.h |  13 ++++++
 drivers/dma/sdxi/device.c  |   8 ++++
 drivers/dma/sdxi/sdxi.h    |   2 +
 4 files changed, 134 insertions(+)

diff --git a/drivers/dma/sdxi/context.c b/drivers/dma/sdxi/context.c
index 934c487b4774..7cae140c0a20 100644
--- a/drivers/dma/sdxi/context.c
+++ b/drivers/dma/sdxi/context.c
@@ -155,6 +155,16 @@ static int configure_cxt_ctl(struct sdxi_cxt_ctl *ctl, const struct sdxi_cxt_ctl
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
@@ -209,6 +219,16 @@ static int configure_L1_entry(struct sdxi_cxt_L1_ent *ent,
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
@@ -259,6 +279,17 @@ static int sdxi_publish_cxt(const struct sdxi_cxt *cxt)
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
 void sdxi_cxt_push_doorbell(struct sdxi_cxt *cxt, u64 index)
 {
 	/* Ensure preceding write index increment is visible. */
@@ -266,6 +297,61 @@ void sdxi_cxt_push_doorbell(struct sdxi_cxt *cxt, u64 index)
 	iowrite64(index, cxt->db);
 }
 
+/* Enable automatic cleanup of an allocated context ID */
+struct __class_sdxi_cxt_id {
+	struct sdxi_dev *sdxi;
+	s32 id;
+};
+
+#define sdxi_cxt_id_null ((struct __class_sdxi_cxt_id){ NULL, -1 })
+#define take_sdxi_cxt_id(x) __get_and_null(x, sdxi_cxt_id_null)
+
+DEFINE_CLASS(sdxi_alloc_cxt_id, struct __class_sdxi_cxt_id,
+	if (_T.id >= 0)
+		xa_erase(&_T.sdxi->client_cxts, _T.id),
+	((struct __class_sdxi_cxt_id){
+		.sdxi = sdxi,
+		.id = ({
+			struct xa_limit limit = XA_LIMIT(1, sdxi->max_cxtid);
+			u32 id;
+			int err = xa_alloc(&sdxi->client_cxts, &id, cxt,
+					   limit, GFP_KERNEL);
+			err ? err : id;
+		}),
+	}),
+	struct sdxi_dev *sdxi, struct sdxi_cxt *cxt)
+
+/*
+ * Allocate the context ID; link the context back to the device;
+ * perform some final initialization of the context based on the ID
+ * allocated; update the context tables.
+ */
+static int register_cxt(struct sdxi_dev *sdxi, struct sdxi_cxt *cxt)
+{
+	int err;
+
+	CLASS(sdxi_alloc_cxt_id, slot)(sdxi, cxt);
+	if (slot.id < 0)
+		return slot.id;
+
+	cxt->sdxi = sdxi;
+	cxt->id = slot.id;
+	cxt->db = sdxi->dbs + slot.id * sdxi->db_stride;
+
+	err = sdxi_publish_cxt(cxt);
+	if (err)
+		return err;
+
+	take_sdxi_cxt_id(slot);
+	return 0;
+}
+
+static void unregister_cxt(struct sdxi_cxt *cxt)
+{
+	sdxi_rescind_cxt(cxt);
+	xa_erase(&cxt->sdxi->client_cxts, cxt->id);
+}
+
 static void free_admin_cxt(void *ptr)
 {
 	struct sdxi_dev *sdxi = ptr;
@@ -296,3 +382,28 @@ int sdxi_admin_cxt_init(struct sdxi_dev *sdxi)
 
 	return devm_add_action_or_reset(sdxi_to_dev(sdxi), free_admin_cxt, sdxi);
 }
+
+/*
+ * Allocate a context for in-kernel use. Starting the context is the
+ * caller's responsibility.
+ */
+struct sdxi_cxt *sdxi_cxt_new(struct sdxi_dev *sdxi)
+{
+	struct sdxi_cxt *cxt __free(sdxi_cxt) = sdxi_alloc_cxt(sdxi);
+	if (!cxt)
+		return NULL;
+
+	if (register_cxt(sdxi, cxt))
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
+	unregister_cxt(cxt);
+	sdxi_free_cxt(cxt);
+}
diff --git a/drivers/dma/sdxi/context.h b/drivers/dma/sdxi/context.h
index c34acd730acb..5cd78e883c8d 100644
--- a/drivers/dma/sdxi/context.h
+++ b/drivers/dma/sdxi/context.h
@@ -58,6 +58,19 @@ struct sdxi_cxt {
 
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
 void sdxi_cxt_push_doorbell(struct sdxi_cxt *cxt, u64 index);
 
 #endif /* DMA_SDXI_CONTEXT_H */
diff --git a/drivers/dma/sdxi/device.c b/drivers/dma/sdxi/device.c
index 15f61d1ce490..aaff6b15325a 100644
--- a/drivers/dma/sdxi/device.c
+++ b/drivers/dma/sdxi/device.c
@@ -12,6 +12,7 @@
 #include <linux/dmapool.h>
 #include <linux/log2.h>
 #include <linux/slab.h>
+#include <linux/xarray.h>
 
 #include "context.h"
 #include "hw.h"
@@ -302,6 +303,7 @@ int sdxi_register(struct device *dev, const struct sdxi_bus_ops *ops)
 
 	sdxi->dev = dev;
 	sdxi->bus_ops = ops;
+	xa_init_flags(&sdxi->client_cxts, XA_FLAGS_ALLOC1);
 	dev_set_drvdata(dev, sdxi);
 
 	err = sdxi->bus_ops->init(sdxi);
@@ -314,6 +316,12 @@ int sdxi_register(struct device *dev, const struct sdxi_bus_ops *ops)
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
index 426101875334..da33719735ab 100644
--- a/drivers/dma/sdxi/sdxi.h
+++ b/drivers/dma/sdxi/sdxi.h
@@ -12,6 +12,7 @@
 #include <linux/dev_printk.h>
 #include <linux/io-64-nonatomic-lo-hi.h>
 #include <linux/types.h>
+#include <linux/xarray.h>
 
 #include "mmio.h"
 
@@ -61,6 +62,7 @@ struct sdxi_dev {
 	struct dma_pool *cst_blk_pool;
 
 	struct sdxi_cxt *admin_cxt;
+	struct xarray client_cxts; /* context id -> (struct sdxi_cxt *) */
 
 	const struct sdxi_bus_ops *bus_ops;
 };

-- 
2.53.0

