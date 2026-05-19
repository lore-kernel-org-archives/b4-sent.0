From: Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
Date: Tue, 19 May 2026 11:45:54 +0530
Subject: [PATCH 04/15] accel/qda: Add compute bus for QDA context banks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260519-qda-series-v1-4-b2d984c297f8@oss.qualcomm.com>
References: <20260519-qda-series-v1-0-b2d984c297f8@oss.qualcomm.com>
In-Reply-To: <20260519-qda-series-v1-0-b2d984c297f8@oss.qualcomm.com>
To: Oded Gabbay <ogabbay@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Sumit Semwal <sumit.semwal@linaro.org>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>
Cc: Bharath Kumar <quic_bkumar@quicinc.com>, 
 Chenna Kesava Raju <quic_chennak@quicinc.com>, srini@kernel.org, 
 dmitry.baryshkov@oss.qualcomm.com, andersson@kernel.org, 
 konradybcio@kernel.org, robin.clark@oss.qualcomm.com, 
 linux-kernel@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 linux-doc@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 iommu@lists.linux.dev, linux-media@vger.kernel.org, 
 linaro-mm-sig@lists.linaro.org, 
 Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779171352; l=6291;
 i=ekansh.gupta@oss.qualcomm.com; s=20260223; h=from:subject:message-id;
 bh=aL7Q8kX8EN5MN2nmToCpPMht6Mh43LKYJcsO1FMcoBk=;
 b=9gZyuC9sX+2+l73JrnFAjjCd2y/5yVVQSJHOJRSTkOyRmr98wS2QFszHlzrywKiXEYnsDaWnc
 PmdCKZc/7APDHgDedYTSVv0Z9lA7wV0f5FQpf7LiDP8esmYAkTjIZ9M
X-Developer-Key: i=ekansh.gupta@oss.qualcomm.com; a=ed25519;
 pk=n0SepARizye+pYjhjg1RA5J+Nq4+IJbyRcBybU+/ERQ=
X-Endpoint-Received: by B4 Relay for ekansh.gupta@oss.qualcomm.com/20260223 with auth_id=647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a custom virtual bus (qda-compute-cb) for managing IOMMU
context bank (CB) devices used by the QDA driver.

IOMMU context banks are synthetic constructs — they are not real
platform devices and do not appear as children of a platform bus node
in the device tree. Using a platform driver to represent them was
therefore incorrect and introduced a probe-ordering race: device nodes
were created before the RPMsg channel resources were fully initialized,
and because probe runs asynchronously, user-space could open a CB
device and attempt to start a session before the underlying transport
was ready.

The qda-compute-cb bus solves this by allowing the main QDA driver to
create CB devices explicitly and under its own control, making their
lifetime strictly subordinate to the parent qda_dev. The bus provides
a dma_configure callback that calls of_dma_configure() so that each CB
device gets its own IOMMU domain derived from its device-tree node,
enabling per-session memory isolation.

The bus type and the CB device constructor (create_qda_cb_device) are
exported for use by the QDA memory manager.

A hidden Kconfig symbol (DRM_ACCEL_QDA_COMPUTE_BUS) is introduced and
automatically selected by DRM_ACCEL_QDA so that the bus initialisation
runs via postcore_initcall before any QDA device probes.

Assisted-by: Claude:claude-4-6-sonnet
Signed-off-by: Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
---
 drivers/accel/Makefile              |  1 +
 drivers/accel/qda/Kconfig           |  4 +++
 drivers/accel/qda/Makefile          |  2 ++
 drivers/accel/qda/qda_compute_bus.c | 68 +++++++++++++++++++++++++++++++++++++
 include/linux/qda_compute_bus.h     | 32 +++++++++++++++++
 5 files changed, 107 insertions(+)

diff --git a/drivers/accel/Makefile b/drivers/accel/Makefile
index 58c08dd5f389..9ed843cd293f 100644
--- a/drivers/accel/Makefile
+++ b/drivers/accel/Makefile
@@ -6,4 +6,5 @@ obj-$(CONFIG_DRM_ACCEL_HABANALABS)	+= habanalabs/
 obj-$(CONFIG_DRM_ACCEL_IVPU)		+= ivpu/
 obj-$(CONFIG_DRM_ACCEL_QAIC)		+= qaic/
 obj-$(CONFIG_DRM_ACCEL_QDA)		+= qda/
+obj-$(CONFIG_DRM_ACCEL_QDA_COMPUTE_BUS) += qda/
 obj-$(CONFIG_DRM_ACCEL_ROCKET)		+= rocket/
\ No newline at end of file
diff --git a/drivers/accel/qda/Kconfig b/drivers/accel/qda/Kconfig
index 484d21ff1b55..2a61a4dda054 100644
--- a/drivers/accel/qda/Kconfig
+++ b/drivers/accel/qda/Kconfig
@@ -3,11 +3,15 @@
 # Qualcomm DSP accelerator driver
 #
 
+config DRM_ACCEL_QDA_COMPUTE_BUS
+	bool
+
 config DRM_ACCEL_QDA
 	tristate "Qualcomm DSP accelerator"
 	depends on DRM_ACCEL
 	depends on ARCH_QCOM || COMPILE_TEST
 	depends on RPMSG
+	select DRM_ACCEL_QDA_COMPUTE_BUS
 	help
 	  Enables the DRM-based accelerator driver for Qualcomm's Hexagon DSPs.
 	  This driver provides a standardized interface for offloading computational
diff --git a/drivers/accel/qda/Makefile b/drivers/accel/qda/Makefile
index dbe809067a8b..424176f652a5 100644
--- a/drivers/accel/qda/Makefile
+++ b/drivers/accel/qda/Makefile
@@ -8,3 +8,5 @@ obj-$(CONFIG_DRM_ACCEL_QDA)	:= qda.o
 qda-y := \
 	qda_drv.o \
 	qda_rpmsg.o
+
+obj-$(CONFIG_DRM_ACCEL_QDA_COMPUTE_BUS) += qda_compute_bus.o
diff --git a/drivers/accel/qda/qda_compute_bus.c b/drivers/accel/qda/qda_compute_bus.c
new file mode 100644
index 000000000000..c59d977e924d
--- /dev/null
+++ b/drivers/accel/qda/qda_compute_bus.c
@@ -0,0 +1,68 @@
+// SPDX-License-Identifier: GPL-2.0-only
+// Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
+#include <linux/device.h>
+#include <linux/init.h>
+#include <linux/of.h>
+#include <linux/of_device.h>
+#include <linux/qda_compute_bus.h>
+#include <linux/slab.h>
+
+static int qda_cb_bus_dma_configure(struct device *dev)
+{
+	return of_dma_configure(dev, dev->of_node, true);
+}
+
+const struct bus_type qda_cb_bus_type = {
+	.name = "qda-compute-cb",
+	.dma_configure = qda_cb_bus_dma_configure,
+};
+EXPORT_SYMBOL_GPL(qda_cb_bus_type);
+
+static void release_qda_cb_device(struct device *dev)
+{
+	of_node_put(dev->of_node);
+	kfree(dev);
+}
+
+struct device *create_qda_cb_device(struct device *parent_device, const char *name,
+				    u64 dma_mask, struct device_node *of_node)
+{
+	struct device *dev;
+	int ret;
+
+	dev = kzalloc_obj(*dev);
+	if (!dev)
+		return ERR_PTR(-ENOMEM);
+
+	dev->release = release_qda_cb_device;
+	dev->bus = &qda_cb_bus_type;
+	dev->parent = parent_device;
+	dev->coherent_dma_mask = dma_mask;
+	dev->dma_mask = &dev->coherent_dma_mask;
+	dev->of_node = of_node_get(of_node);
+
+	dev_set_name(dev, "%s", name);
+
+	ret = device_register(dev);
+	if (ret) {
+		put_device(dev);
+		return ERR_PTR(ret);
+	}
+
+	return dev;
+}
+EXPORT_SYMBOL_GPL(create_qda_cb_device);
+
+static int __init qda_cb_bus_init(void)
+{
+	int err;
+
+	err = bus_register(&qda_cb_bus_type);
+	if (err < 0) {
+		pr_err("qda-compute-cb bus registration failed: %d\n", err);
+		return err;
+	}
+	return 0;
+}
+
+postcore_initcall(qda_cb_bus_init);
diff --git a/include/linux/qda_compute_bus.h b/include/linux/qda_compute_bus.h
new file mode 100644
index 000000000000..90bf248c7285
--- /dev/null
+++ b/include/linux/qda_compute_bus.h
@@ -0,0 +1,32 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+/*
+ * Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
+ */
+
+#ifndef __QDA_COMPUTE_BUS_H__
+#define __QDA_COMPUTE_BUS_H__
+
+#include <linux/device.h>
+
+/*
+ * Custom bus type for QDA compute context bank (CB) devices
+ *
+ * This bus type is used for manually created CB devices that represent
+ * IOMMU context banks. The custom bus allows proper IOMMU configuration
+ * and device management for these virtual devices.
+ */
+#ifdef CONFIG_DRM_ACCEL_QDA_COMPUTE_BUS
+extern const struct bus_type qda_cb_bus_type;
+
+struct device *create_qda_cb_device(struct device *parent_device, const char *name,
+				    u64 dma_mask, struct device_node *of_node);
+#else
+static inline struct device *create_qda_cb_device(struct device *parent_device,
+						  const char *name, u64 dma_mask,
+						  struct device_node *of_node)
+{
+	return ERR_PTR(-ENODEV);
+}
+#endif
+
+#endif /* __QDA_COMPUTE_BUS_H__ */

-- 
2.34.1

