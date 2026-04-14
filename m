From: Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
Date: Tue, 14 Apr 2026 22:01:15 +0530
Subject: [PATCH 1/3] drivers: base: Add generic context device bus
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260414-computebus-v1-1-4d904d40926a@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776184278; l=3013;
 i=ekansh.gupta@oss.qualcomm.com; s=20260223; h=from:subject:message-id;
 bh=GiaW9KX6EnyHl15uXUaLI85Eugyx6gIsQQrGnKwyVVk=;
 b=g7ZvTKbHA9UTo3rRc56oQRClDN77YoCoOIyf0Ch0pvK4S/d5lszMPmM5fNmU56g6YpXEOAu9x
 J6BS+tcG340ACkYknZbhTqxrn/ex62ByFElTbD0dzk54v75d4aqeryz
X-Developer-Key: i=ekansh.gupta@oss.qualcomm.com; a=ed25519;
 pk=n0SepARizye+pYjhjg1RA5J+Nq4+IJbyRcBybU+/ERQ=
X-Endpoint-Received: by B4 Relay for ekansh.gupta@oss.qualcomm.com/20260223 with auth_id=647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a new generic bus type for synthetic context bank devices
that require IOMMU context isolation. This bus provides a shared
infrastructure for accelerator and GPU drivers that create virtual
devices representing IOMMU context banks.

Currently, drivers like host1x implement their own bus types for
context devices. This generic implementation allows multiple drivers
to share the same bus infrastructure, simplifying the IOMMU subsystem
integration and reducing code duplication.

Signed-off-by: Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
---
 drivers/base/Kconfig        |  3 +++
 drivers/base/Makefile       |  1 +
 drivers/base/context_bus.c  | 24 ++++++++++++++++++++++++
 include/linux/context_bus.h | 15 +++++++++++++++
 4 files changed, 43 insertions(+)

diff --git a/drivers/base/Kconfig b/drivers/base/Kconfig
index f7d385cbd3ba..479bc4bb442b 100644
--- a/drivers/base/Kconfig
+++ b/drivers/base/Kconfig
@@ -4,6 +4,9 @@ menu "Generic Driver Options"
 config AUXILIARY_BUS
 	bool
 
+config CONTEXT_DEVICE_BUS
+	bool
+
 config UEVENT_HELPER
 	bool "Support for uevent helper"
 	help
diff --git a/drivers/base/Makefile b/drivers/base/Makefile
index 8074a10183dc..ab9a0b2dc73b 100644
--- a/drivers/base/Makefile
+++ b/drivers/base/Makefile
@@ -8,6 +8,7 @@ obj-y			:= component.o core.o bus.o dd.o syscore.o \
 			   topology.o container.o property.o cacheinfo.o \
 			   swnode.o faux.o
 obj-$(CONFIG_AUXILIARY_BUS) += auxiliary.o
+obj-$(CONFIG_CONTEXT_DEVICE_BUS) += context_bus.o
 obj-$(CONFIG_DEVTMPFS)	+= devtmpfs.o
 obj-y			+= power/
 obj-$(CONFIG_ISA_BUS_API)	+= isa.o
diff --git a/drivers/base/context_bus.c b/drivers/base/context_bus.c
new file mode 100644
index 000000000000..6ddb6c27bf69
--- /dev/null
+++ b/drivers/base/context_bus.c
@@ -0,0 +1,24 @@
+// SPDX-License-Identifier: GPL-2.0-only
+// Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
+
+#include <linux/context_bus.h>
+#include <linux/init.h>
+
+const struct bus_type context_device_bus_type = {
+	.name = "context-device",
+};
+EXPORT_SYMBOL_GPL(context_device_bus_type);
+
+static int __init context_device_bus_init(void)
+{
+	int err;
+
+	err = bus_register(&context_device_bus_type);
+	if (err < 0) {
+		pr_err("context-device bus registration failed: %d\n", err);
+		return err;
+	}
+
+	return 0;
+}
+postcore_initcall(context_device_bus_init);
diff --git a/include/linux/context_bus.h b/include/linux/context_bus.h
new file mode 100644
index 000000000000..0cd44cb5b147
--- /dev/null
+++ b/include/linux/context_bus.h
@@ -0,0 +1,15 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+/*
+ * Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
+ */
+
+#ifndef __LINUX_CONTEXT_BUS_H
+#define __LINUX_CONTEXT_BUS_H
+
+#include <linux/device.h>
+
+#ifdef CONFIG_CONTEXT_DEVICE_BUS
+extern const struct bus_type context_device_bus_type;
+#endif
+
+#endif /* __LINUX_CONTEXT_BUS_H */

-- 
2.34.1

