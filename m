From: Jack Wu <jackbb_wu@compal.com>
Date: Fri, 28 Aug 2026 17:17:19 +0800
Subject: [PATCH v7 2/6] net: wwan: t9xx: Add control plane transaction
 layer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260828-t9xx_driver_v1-v7-2-bf8f6074d88a@compal.com>
References: <20260828-t9xx_driver_v1-v7-0-bf8f6074d88a@compal.com>
In-Reply-To: <20260828-t9xx_driver_v1-v7-0-bf8f6074d88a@compal.com>
To: Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Sergey Ryazanov <ryazanov.s.a@gmail.com>, 
 Johannes Berg <johannes@sipsolutions.net>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Jack Wu <jackbb_wu@compal.com>, Wen-Zhi Huang <wen-zhi.huang@mediatek.com>, 
 Shi-Wei Yeh <shi-wei.yeh@mediatek.com>, 
 Minano Tseng <Minano.tseng@mediatek.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, Robert Yu <robert_yu@compal.com>, 
 Jeff Chang <Jeff_Chang@compal.com>
Cc: linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-doc@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787908678; l=6974;
 i=jackbb_wu@compal.com; s=20260526; h=from:subject:message-id;
 bh=vuOoF1S4yacoIe/fJXVMIUwk0KIIejR9ydhwr36eXio=;
 b=zhbOpa+zWXvDVB+yAmJ+Shda5AxTXn2yfqs4qu3I2BRaBtyqTLhxlHqBh2gDrNoaZmaor4UC4
 ILIzT+ZJsLYBlPB7XONRY5yqk7ezuWY0eoIbMzCmg5UBxmjFDN8xaPa
X-Developer-Key: i=jackbb_wu@compal.com; a=ed25519;
 pk=VH1prTWixNl8OEUPPSfII3p46MzJpQN8J3+ecE1tZXg=
X-Endpoint-Received: by B4 Relay for jackbb_wu@compal.com/20260526 with auth_id=793
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce the control plane and transaction layer framework
for the T9XX WWAN driver. This patch adds the core data
structures (mtk_ctrl_blk, mtk_ctrl_trans) and initialization
entry points that subsequent patches build upon.

Split PCIe-specific objects into a separate mtk_t9xx_pcie
module gated by the hidden MTK_T9XX_PCI config symbol.

The control plane block (ctrl_blk) serves as the central
context for managing the transaction layer, port layer, and
FSM interactions. The actual DMA engine and TX/RX service
implementations are added in subsequent patches.

Signed-off-by: Jack Wu <jackbb_wu@compal.com>
---
 drivers/net/wwan/Kconfig                    |  9 ++++--
 drivers/net/wwan/t9xx/Makefile              |  5 ++--
 drivers/net/wwan/t9xx/mtk_ctrl_plane.c      | 46 +++++++++++++++++++++++++++++
 drivers/net/wwan/t9xx/mtk_ctrl_plane.h      | 22 ++++++++++++++
 drivers/net/wwan/t9xx/mtk_dev.c             | 11 +++++++
 drivers/net/wwan/t9xx/mtk_dev.h             |  2 ++
 drivers/net/wwan/t9xx/pcie/Makefile         | 10 +++++++
 drivers/net/wwan/t9xx/pcie/mtk_pci.c        |  1 +
 drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h | 21 +++++++++++++
 9 files changed, 123 insertions(+), 4 deletions(-)

diff --git a/drivers/net/wwan/Kconfig b/drivers/net/wwan/Kconfig
index 55c45af410ee..aeaed8f058ec 100644
--- a/drivers/net/wwan/Kconfig
+++ b/drivers/net/wwan/Kconfig
@@ -124,14 +124,19 @@ config MTK_T7XX
 config MTK_T9XX
 	tristate "MediaTek PCIe 5G WWAN modem T9xx device"
 	depends on PCI && ACPI
+	select MTK_T9XX_PCI
 	help
 	  Enables MediaTek PCIe based 5G WWAN modem (T9xx series) device.
 
-	  To compile this driver as a module, choose M here: the module will be
-	  called mtk_t9xx.
+	  To compile this driver as a module, choose M here: the modules will
+	  be called mtk_t9xx and mtk_t9xx_pcie.
 
 	  If unsure, say N.
 
+config MTK_T9XX_PCI
+	tristate
+	depends on PCI
+
 endif # WWAN
 
 endmenu
diff --git a/drivers/net/wwan/t9xx/Makefile b/drivers/net/wwan/t9xx/Makefile
index 6f2dd3f91454..ae9d6f2344ab 100644
--- a/drivers/net/wwan/t9xx/Makefile
+++ b/drivers/net/wwan/t9xx/Makefile
@@ -4,7 +4,8 @@ ccflags-y += -I$(src)/pcie
 ccflags-y += -I$(src)
 
 obj-$(CONFIG_MTK_T9XX) += mtk_t9xx.o
+obj-$(CONFIG_MTK_T9XX_PCI) += pcie/
 
 mtk_t9xx-y := \
-	pcie/mtk_pci.o \
-	pcie/mtk_pci_drv_m9xx.o
+	mtk_dev.o \
+	mtk_ctrl_plane.o
diff --git a/drivers/net/wwan/t9xx/mtk_ctrl_plane.c b/drivers/net/wwan/t9xx/mtk_ctrl_plane.c
new file mode 100644
index 000000000000..65a20407173d
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_ctrl_plane.c
@@ -0,0 +1,46 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2022, MediaTek Inc.
+ * Copyright (c) 2022-2023, Intel Corporation.
+ */
+
+#include <linux/device.h>
+
+#include "mtk_ctrl_plane.h"
+
+/**
+ * mtk_ctrl_init() - Initialize the control plane block.
+ * @mdev: Pointer to the MTK modem device.
+ *
+ * Allocates and initializes the control plane block
+ * associated with @mdev.
+ *
+ * Return: 0 on success, -ENOMEM on allocation failure.
+ */
+int mtk_ctrl_init(struct mtk_md_dev *mdev)
+{
+	struct mtk_ctrl_blk *ctrl_blk;
+
+	ctrl_blk = devm_kzalloc(mdev->dev, sizeof(*ctrl_blk), GFP_KERNEL);
+	if (!ctrl_blk)
+		return -ENOMEM;
+
+	ctrl_blk->mdev = mdev;
+	mdev->ctrl_blk = ctrl_blk;
+
+	return 0;
+}
+EXPORT_SYMBOL(mtk_ctrl_init);
+
+/**
+ * mtk_ctrl_exit() - Clean up the control plane block.
+ * @mdev: Pointer to the MTK modem device.
+ *
+ * Clears the control plane block pointer. The allocation
+ * itself is managed by devres and freed on driver detach.
+ */
+void mtk_ctrl_exit(struct mtk_md_dev *mdev)
+{
+	mdev->ctrl_blk = NULL;
+}
+EXPORT_SYMBOL(mtk_ctrl_exit);
diff --git a/drivers/net/wwan/t9xx/mtk_ctrl_plane.h b/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
new file mode 100644
index 000000000000..c141876ef95d
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
@@ -0,0 +1,22 @@
+/* SPDX-License-Identifier: GPL-2.0-only
+ *
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#ifndef __MTK_CTRL_PLANE_H__
+#define __MTK_CTRL_PLANE_H__
+
+#include <linux/kref.h>
+#include <linux/skbuff.h>
+
+#include "mtk_dev.h"
+
+struct mtk_ctrl_blk {
+	struct mtk_md_dev *mdev;
+	struct mtk_ctrl_trans *trans;
+};
+
+int mtk_ctrl_init(struct mtk_md_dev *mdev);
+void mtk_ctrl_exit(struct mtk_md_dev *mdev);
+
+#endif /* __MTK_CTRL_PLANE_H__ */
diff --git a/drivers/net/wwan/t9xx/mtk_dev.c b/drivers/net/wwan/t9xx/mtk_dev.c
new file mode 100644
index 000000000000..50f77d5a210c
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_dev.c
@@ -0,0 +1,11 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#include <linux/module.h>
+
+#include "mtk_dev.h"
+
+MODULE_DESCRIPTION("MediaTek T9xx PCIe WWAN driver");
+MODULE_LICENSE("GPL");
diff --git a/drivers/net/wwan/t9xx/mtk_dev.h b/drivers/net/wwan/t9xx/mtk_dev.h
index 8278a0e2875e..9843171fe2ae 100644
--- a/drivers/net/wwan/t9xx/mtk_dev.h
+++ b/drivers/net/wwan/t9xx/mtk_dev.h
@@ -36,6 +36,7 @@ enum mtk_dev_evt_d2h {
 };
 
 struct mtk_md_dev;
+struct mtk_ctrl_blk;
 
 struct mtk_dev_ops {
 	u32 (*get_dev_state)(struct mtk_md_dev *mdev);
@@ -57,6 +58,7 @@ struct mtk_md_dev {
 	void *hw_priv;
 	u32 hw_ver;
 	char dev_str[MTK_DEV_STR_LEN];
+	struct mtk_ctrl_blk *ctrl_blk;
 };
 
 static inline u32 mtk_dev_get_dev_state(struct mtk_md_dev *mdev)
diff --git a/drivers/net/wwan/t9xx/pcie/Makefile b/drivers/net/wwan/t9xx/pcie/Makefile
new file mode 100644
index 000000000000..7410d1796d27
--- /dev/null
+++ b/drivers/net/wwan/t9xx/pcie/Makefile
@@ -0,0 +1,10 @@
+# SPDX-License-Identifier: GPL-2.0-only
+
+ccflags-y += -I$(src)
+ccflags-y += -I$(src)/..
+
+obj-$(CONFIG_MTK_T9XX_PCI) += mtk_t9xx_pcie.o
+
+mtk_t9xx_pcie-y := \
+	mtk_pci_drv_m9xx.o \
+	mtk_pci.o
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_pci.c b/drivers/net/wwan/t9xx/pcie/mtk_pci.c
index a89780390dd2..c2370fdbf6e8 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_pci.c
+++ b/drivers/net/wwan/t9xx/pcie/mtk_pci.c
@@ -14,6 +14,7 @@
 #include <linux/module.h>
 
 #include "mtk_dev.h"
+#include "mtk_trans_ctrl.h"
 #include "mtk_pci.h"
 #include "mtk_pci_reg.h"
 
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h b/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h
new file mode 100644
index 000000000000..d6de4c43b529
--- /dev/null
+++ b/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h
@@ -0,0 +1,21 @@
+/* SPDX-License-Identifier: GPL-2.0-only
+ *
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#ifndef __MTK_TRANS_CTRL_H__
+#define __MTK_TRANS_CTRL_H__
+
+#include <linux/kref.h>
+#include <linux/list.h>
+#include <linux/skbuff.h>
+#include <linux/types.h>
+
+#include "mtk_dev.h"
+
+struct mtk_ctrl_trans {
+	struct mtk_ctrl_blk *ctrl_blk;
+	struct mtk_md_dev *mdev;
+};
+
+#endif

-- 
2.34.1

