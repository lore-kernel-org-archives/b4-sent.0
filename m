From: Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
Date: Tue, 14 Apr 2026 22:01:17 +0530
Subject: [PATCH 3/3] misc: fastrpc: Use context device bus for compute
 banks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260414-computebus-v1-3-4d904d40926a@oss.qualcomm.com>
References: <20260414-computebus-v1-0-4d904d40926a@oss.qualcomm.com>
In-Reply-To: <20260414-computebus-v1-0-4d904d40926a@oss.qualcomm.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Mikko Perttunen <mperttunen@nvidia.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Arnd Bergmann <arnd@arndb.de>, Srinivas Kandagatla <srini@kernel.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Bharath Kumar <quic_bkumar@quicinc.com>, 
 Chenna Kesava Raju <quic_chennak@quicinc.com>
Cc: linux-kernel@vger.kernel.org, driver-core@lists.linux.dev, 
 dri-devel@lists.freedesktop.org, linux-tegra@vger.kernel.org, 
 iommu@lists.linux.dev, linux-arm-msm@vger.kernel.org, 
 Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776184278; l=9736;
 i=ekansh.gupta@oss.qualcomm.com; s=20260223; h=from:subject:message-id;
 bh=o6iny1LWE3z7mcZmAk9jzq3tTNYPqB65PUC0PwHJvS8=;
 b=A0Yhanj3vlPKRDGFbJ31fb+GP3yvJ3vVGI/TW8GczKwhQXoHfKEAqo8oQ+ryO8I/vlHnPX3da
 vt4BrUk/2XYBeE3DODY4IDLuujnk3xKRlrjczVYtz6ZuLPXhdc6lNOU
X-Developer-Key: i=ekansh.gupta@oss.qualcomm.com; a=ed25519;
 pk=n0SepARizye+pYjhjg1RA5J+Nq4+IJbyRcBybU+/ERQ=
X-Endpoint-Received: by B4 Relay for ekansh.gupta@oss.qualcomm.com/20260223 with auth_id=647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace the platform driver approach for compute bank (CB) devices
with the generic context_device_bus_type. Compute bank devices are
synthetic IOMMU context banks, not real platform devices, so using
the context device bus provides a more accurate representation in
the device model.

Currently, fastrpc used of_platform_populate() to create platform
devices for each "qcom,fastrpc-compute-cb" DT node, with a platform
driver (fastrpc_cb_driver) to handle probe/remove. This approach
had a race condition: device nodes were created before channel
resources (like spin_lock) were initialized, and probe was async,
so applications could open the device before sessions were available.

This patch addresses the race by manually creating and configuring
CB devices synchronously during fastrpc_rpmsg_probe(), after all
channel resources are initialized. The approach follows the pattern
used in host1x_memory_context_list_init().

Signed-off-by: Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
---
 drivers/misc/Kconfig   |   1 +
 drivers/misc/fastrpc.c | 180 ++++++++++++++++++++++++++++++++++---------------
 2 files changed, 125 insertions(+), 56 deletions(-)

diff --git a/drivers/misc/Kconfig b/drivers/misc/Kconfig
index 00683bf06258..b501462a4548 100644
--- a/drivers/misc/Kconfig
+++ b/drivers/misc/Kconfig
@@ -304,6 +304,7 @@ config QCOM_FASTRPC
 	depends on RPMSG
 	select DMA_SHARED_BUFFER
 	select QCOM_SCM
+	select CONTEXT_DEVICE_BUS
 	help
 	  Provides a communication mechanism that allows for clients to
 	  make remote method invocations across processor boundary to
diff --git a/drivers/misc/fastrpc.c b/drivers/misc/fastrpc.c
index 1080f9acf70a..f66fd3eea5fa 100644
--- a/drivers/misc/fastrpc.c
+++ b/drivers/misc/fastrpc.c
@@ -13,9 +13,9 @@
 #include <linux/module.h>
 #include <linux/of_address.h>
 #include <linux/of.h>
-#include <linux/platform_device.h>
+#include <linux/of_device.h>
 #include <linux/sort.h>
-#include <linux/of_platform.h>
+#include <linux/context_bus.h>
 #include <linux/rpmsg.h>
 #include <linux/scatterlist.h>
 #include <linux/slab.h>
@@ -250,6 +250,18 @@ struct fastrpc_invoke_ctx {
 	struct fastrpc_channel_ctx *cctx;
 };
 
+/**
+ * struct fastrpc_cb_device - Compute bank device wrapper
+ * @dev: Device structure
+ * @sess: Back-pointer to the session context
+ */
+struct fastrpc_cb_device {
+	struct device dev;
+	struct fastrpc_session_ctx *sess;
+};
+
+#define to_fastrpc_cb_device(d) container_of(d, struct fastrpc_cb_device, dev)
+
 struct fastrpc_session_ctx {
 	struct device *dev;
 	int sid;
@@ -2190,92 +2202,156 @@ static const struct file_operations fastrpc_fops = {
 	.compat_ioctl = fastrpc_device_ioctl,
 };
 
-static int fastrpc_cb_probe(struct platform_device *pdev)
+static void fastrpc_cb_dev_release(struct device *dev)
+{
+	struct fastrpc_cb_device *cb_dev = to_fastrpc_cb_device(dev);
+
+	of_node_put(dev->of_node);
+	kfree(cb_dev);
+}
+
+static int fastrpc_create_cb_device(struct fastrpc_channel_ctx *cctx,
+				    struct device *parent,
+				    struct device_node *cb_node)
 {
-	struct fastrpc_channel_ctx *cctx;
 	struct fastrpc_session_ctx *sess;
-	struct device *dev = &pdev->dev;
-	int i, sessions = 0;
+	struct fastrpc_cb_device *cb_dev;
 	unsigned long flags;
-	int rc;
-	u32 dma_bits;
-
-	cctx = dev_get_drvdata(dev->parent);
-	if (!cctx)
-		return -EINVAL;
+	int i, sessions = 0, rc;
+	u32 dma_bits, sid = 0;
 
-	of_property_read_u32(dev->of_node, "qcom,nsessions", &sessions);
+	/* Read SID early so it can be used in the device name */
+	of_property_read_u32(cb_node, "reg", &sid);
+	of_property_read_u32(cb_node, "qcom,nsessions", &sessions);
 
 	spin_lock_irqsave(&cctx->lock, flags);
 	if (cctx->sesscount >= FASTRPC_MAX_SESSIONS) {
-		dev_err(&pdev->dev, "too many sessions\n");
+		dev_err(parent, "too many sessions\n");
 		spin_unlock_irqrestore(&cctx->lock, flags);
 		return -ENOSPC;
 	}
 	dma_bits = cctx->soc_data->dma_addr_bits_default;
+	if (cctx->domain_id == CDSP_DOMAIN_ID)
+		dma_bits = cctx->soc_data->dma_addr_bits_cdsp;
+
 	sess = &cctx->session[cctx->sesscount++];
 	sess->used = false;
 	sess->valid = true;
-	sess->dev = dev;
-	dev_set_drvdata(dev, sess);
+	sess->sid = sid;
+	spin_unlock_irqrestore(&cctx->lock, flags);
 
-	if (cctx->domain_id == CDSP_DOMAIN_ID)
-		dma_bits = cctx->soc_data->dma_addr_bits_cdsp;
+	cb_dev = kzalloc_obj(*cb_dev);
+	if (!cb_dev)
+		return -ENOMEM;
 
-	if (of_property_read_u32(dev->of_node, "reg", &sess->sid))
-		dev_info(dev, "FastRPC Session ID not specified in DT\n");
+	cb_dev->sess = sess;
 
-	if (sessions > 0) {
-		struct fastrpc_session_ctx *dup_sess;
+	device_initialize(&cb_dev->dev);
+	cb_dev->dev.parent = parent;
+	cb_dev->dev.bus = &context_device_bus_type;
+	cb_dev->dev.release = fastrpc_cb_dev_release;
+	cb_dev->dev.of_node = of_node_get(cb_node);
+	cb_dev->dev.dma_mask = &cb_dev->dev.coherent_dma_mask;
+	cb_dev->dev.coherent_dma_mask = DMA_BIT_MASK(32);
+	dev_set_name(&cb_dev->dev, "%s:compute-cb@%u", dev_name(parent), sid);
 
+	rc = device_add(&cb_dev->dev);
+	if (rc) {
+		dev_err(parent, "failed to add CB device: %d\n", rc);
+		goto err_put;
+	}
+
+	rc = of_dma_configure(&cb_dev->dev, cb_node, true);
+	if (rc) {
+		dev_err(parent, "of_dma_configure failed for CB device: %d\n", rc);
+		goto err_del;
+	}
+
+	rc = dma_set_mask(&cb_dev->dev, DMA_BIT_MASK(dma_bits));
+	if (rc) {
+		dev_err(parent, "%u-bit DMA enable failed\n", dma_bits);
+		goto err_del;
+	}
+
+	sess->dev = &cb_dev->dev;
+
+	if (sessions > 0) {
+		spin_lock_irqsave(&cctx->lock, flags);
 		for (i = 1; i < sessions; i++) {
+			struct fastrpc_session_ctx *dup_sess;
+
 			if (cctx->sesscount >= FASTRPC_MAX_SESSIONS)
 				break;
 			dup_sess = &cctx->session[cctx->sesscount++];
 			memcpy(dup_sess, sess, sizeof(*dup_sess));
 		}
-	}
-	spin_unlock_irqrestore(&cctx->lock, flags);
-	rc = dma_set_mask(dev, DMA_BIT_MASK(dma_bits));
-	if (rc) {
-		dev_err(dev, "%u-bit DMA enable failed\n", dma_bits);
-		return rc;
+		spin_unlock_irqrestore(&cctx->lock, flags);
 	}
 
 	return 0;
+
+err_del:
+	device_del(&cb_dev->dev);
+err_put:
+	of_node_put(cb_dev->dev.of_node);
+	put_device(&cb_dev->dev);
+	return rc;
 }
 
-static void fastrpc_cb_remove(struct platform_device *pdev)
+static void fastrpc_depopulate_cb_devices(struct fastrpc_channel_ctx *cctx)
 {
-	struct fastrpc_channel_ctx *cctx = dev_get_drvdata(pdev->dev.parent);
-	struct fastrpc_session_ctx *sess = dev_get_drvdata(&pdev->dev);
 	unsigned long flags;
-	int i;
+	int i, j;
 
 	spin_lock_irqsave(&cctx->lock, flags);
 	for (i = 0; i < FASTRPC_MAX_SESSIONS; i++) {
-		if (cctx->session[i].sid == sess->sid) {
+		if (cctx->session[i].valid) {
 			cctx->session[i].valid = false;
 			cctx->sesscount--;
 		}
 	}
 	spin_unlock_irqrestore(&cctx->lock, flags);
+
+	for (i = 0; i < FASTRPC_MAX_SESSIONS; i++) {
+		struct device *dev = cctx->session[i].dev;
+
+		if (!dev)
+			continue;
+
+		/* Unregister the device once */
+		device_unregister(dev);
+
+		/* Clear this dev pointer from all sessions that share it */
+		for (j = i; j < FASTRPC_MAX_SESSIONS; j++) {
+			if (cctx->session[j].dev == dev)
+				cctx->session[j].dev = NULL;
+		}
+	}
 }
 
-static const struct of_device_id fastrpc_match_table[] = {
-	{ .compatible = "qcom,fastrpc-compute-cb", },
-	{}
-};
+static int fastrpc_populate_cb_devices(struct fastrpc_channel_ctx *cctx,
+					struct device *parent,
+					struct device_node *parent_node)
+{
+	struct device_node *child;
+	int ret = 0;
 
-static struct platform_driver fastrpc_cb_driver = {
-	.probe = fastrpc_cb_probe,
-	.remove = fastrpc_cb_remove,
-	.driver = {
-		.name = "qcom,fastrpc-cb",
-		.of_match_table = fastrpc_match_table,
-		.suppress_bind_attrs = true,
-	},
-};
+	for_each_child_of_node(parent_node, child) {
+		if (!of_device_is_compatible(child, "qcom,fastrpc-compute-cb"))
+			continue;
+
+		ret = fastrpc_create_cb_device(cctx, parent, child);
+		if (ret) {
+			dev_err(parent, "failed to create CB device for %s: %d\n",
+				child->name, ret);
+			of_node_put(child);
+			fastrpc_depopulate_cb_devices(cctx);
+			return ret;
+		}
+	}
+
+	return 0;
+}
 
 static int fastrpc_device_register(struct device *dev, struct fastrpc_channel_ctx *cctx,
 				   bool is_secured, const char *domain)
@@ -2441,7 +2517,7 @@ static int fastrpc_rpmsg_probe(struct rpmsg_device *rpdev)
 	data->domain_id = domain_id;
 	data->rpdev = rpdev;
 
-	err = of_platform_populate(rdev->of_node, NULL, NULL, rdev);
+	err = fastrpc_populate_cb_devices(data, rdev, rdev->of_node);
 	if (err)
 		goto err_deregister_fdev;
 
@@ -2496,7 +2572,7 @@ static void fastrpc_rpmsg_remove(struct rpmsg_device *rpdev)
 	if (cctx->remote_heap)
 		fastrpc_buf_free(cctx->remote_heap);
 
-	of_platform_depopulate(&rpdev->dev);
+	fastrpc_depopulate_cb_devices(cctx);
 
 	fastrpc_channel_ctx_put(cctx);
 }
@@ -2558,16 +2634,9 @@ static int fastrpc_init(void)
 {
 	int ret;
 
-	ret = platform_driver_register(&fastrpc_cb_driver);
-	if (ret < 0) {
-		pr_err("fastrpc: failed to register cb driver\n");
-		return ret;
-	}
-
 	ret = register_rpmsg_driver(&fastrpc_driver);
 	if (ret < 0) {
 		pr_err("fastrpc: failed to register rpmsg driver\n");
-		platform_driver_unregister(&fastrpc_cb_driver);
 		return ret;
 	}
 
@@ -2577,7 +2646,6 @@ module_init(fastrpc_init);
 
 static void fastrpc_exit(void)
 {
-	platform_driver_unregister(&fastrpc_cb_driver);
 	unregister_rpmsg_driver(&fastrpc_driver);
 }
 module_exit(fastrpc_exit);

-- 
2.34.1

