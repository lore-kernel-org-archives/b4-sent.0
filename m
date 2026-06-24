From: Jack Wu <jackbb_wu@compal.com>
Date: Wed, 24 Jun 2026 18:04:08 +0800
Subject: [PATCH v3 2/7] net: wwan: t9xx: Add control plane transaction
 layer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260624-t9xx_driver_v1-v3-2-73ff03f60c48@compal.com>
References: <20260624-t9xx_driver_v1-v3-0-73ff03f60c48@compal.com>
In-Reply-To: <20260624-t9xx_driver_v1-v3-0-73ff03f60c48@compal.com>
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
 Shuah Khan <skhan@linuxfoundation.org>
Cc: linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-doc@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782295454; l=9011;
 i=jackbb_wu@compal.com; s=20260526; h=from:subject:message-id;
 bh=2wEEAYpyboBOd2NRA32d/IQjWJfXJYcdXuqBVZ2g+YA=;
 b=BXGnB10dTlBmQcQE5pDU2oZlxlgjjhCzWY68P6S0ZwED1De78tVUN8Im0p2lkyMuveyE3idVD
 kuU/OdeTq8JC/ryV4CK7Ns4m5yc6GWE5xj/vQaiH0TazvUwlgY0MGPF
X-Developer-Key: i=jackbb_wu@compal.com; a=ed25519;
 pk=VH1prTWixNl8OEUPPSfII3p46MzJpQN8J3+ecE1tZXg=
X-Endpoint-Received: by B4 Relay for jackbb_wu@compal.com/20260526 with auth_id=793
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The control plane implements TX services that reside in the
transaction layer. The services receive the packets from the
port layer and call the corresponding DMA components to
transmit data to the device. Meanwhile, TX services receive
and manage the port control commands from the port layer.

The control plane implements RX services that reside in the
transaction layer. The services receive the downlink packets
from the modem and transfer the packets to the corresponding
port layer interfaces.

Signed-off-by: Jack Wu <jackbb_wu@compal.com>
---
 drivers/net/wwan/Kconfig                    |  5 +++
 drivers/net/wwan/t9xx/Makefile              |  5 +--
 drivers/net/wwan/t9xx/mtk_ctrl_plane.c      | 48 +++++++++++++++++++++++++++++
 drivers/net/wwan/t9xx/mtk_ctrl_plane.h      | 22 +++++++++++++
 drivers/net/wwan/t9xx/mtk_dev.c             | 44 ++++++++++++++++++++++++++
 drivers/net/wwan/t9xx/mtk_dev.h             |  5 +++
 drivers/net/wwan/t9xx/pcie/Makefile         | 10 ++++++
 drivers/net/wwan/t9xx/pcie/mtk_pci.c        | 10 +++---
 drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h | 21 +++++++++++++
 9 files changed, 163 insertions(+), 7 deletions(-)

diff --git a/drivers/net/wwan/Kconfig b/drivers/net/wwan/Kconfig
index 4cee537c739f..7019b44494f8 100644
--- a/drivers/net/wwan/Kconfig
+++ b/drivers/net/wwan/Kconfig
@@ -124,6 +124,7 @@ config MTK_T7XX
 config MTK_T9XX
 	tristate "MediaTek PCIe 5G WWAN modem T9xx device"
 	depends on PCI
+	select MTK_T9XX_PCI
 	select NET_DEVLINK
 	help
 	  Enables MediaTek PCIe based 5G WWAN modem (T9xx series) device.
@@ -133,6 +134,10 @@ config MTK_T9XX
 
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
index 000000000000..07938f3e6fe2
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_ctrl_plane.c
@@ -0,0 +1,48 @@
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
+ * Frees the control plane block associated with @mdev.
+ */
+void mtk_ctrl_exit(struct mtk_md_dev *mdev)
+{
+	struct mtk_ctrl_blk *ctrl_blk = mdev->ctrl_blk;
+
+	devm_kfree(mdev->dev, ctrl_blk);
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
index 000000000000..f254ca7ed877
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_dev.c
@@ -0,0 +1,44 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#include <linux/module.h>
+
+#include "mtk_dev.h"
+
+struct mtk_md_dev *mtk_dev_alloc(struct device *pdev, const struct mtk_dev_ops *dev_ops)
+{
+	struct mtk_md_dev *mdev;
+
+	mdev = devm_kzalloc(pdev, sizeof(*mdev), GFP_KERNEL);
+	if (!mdev)
+		return NULL;
+
+	mdev->dev_ops = dev_ops;
+	mdev->dev = pdev;
+	return mdev;
+}
+EXPORT_SYMBOL(mtk_dev_alloc);
+
+void mtk_dev_free(struct mtk_md_dev *mdev)
+{
+	struct device *dev = mdev->dev;
+
+	devm_kfree(dev, mdev);
+}
+EXPORT_SYMBOL(mtk_dev_free);
+
+static int __init mtk_common_drv_init(void)
+{
+	return 0;
+}
+module_init(mtk_common_drv_init);
+
+static void __exit mtk_common_drv_exit(void)
+{
+}
+module_exit(mtk_common_drv_exit);
+
+MODULE_DESCRIPTION("MediaTek T9xx PCIe WWAN driver");
+MODULE_LICENSE("GPL");
diff --git a/drivers/net/wwan/t9xx/mtk_dev.h b/drivers/net/wwan/t9xx/mtk_dev.h
index 8278a0e2875e..bb3ea68890ea 100644
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
@@ -105,4 +107,7 @@ static inline int mtk_dev_send_dev_evt(struct mtk_md_dev *mdev, u32 dev_evt)
 	return mdev->dev_ops->send_dev_evt(mdev, dev_evt);
 }
 
+struct mtk_md_dev *mtk_dev_alloc(struct device *pdev, const struct mtk_dev_ops *dev_ops);
+void mtk_dev_free(struct mtk_md_dev *mdev);
+
 #endif /* __MTK_DEV_H__ */
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
index c6a7196fcdd6..90b33dd6effd 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_pci.c
+++ b/drivers/net/wwan/t9xx/pcie/mtk_pci.c
@@ -14,6 +14,7 @@
 #include <linux/module.h>
 
 #include "mtk_dev.h"
+#include "mtk_trans_ctrl.h"
 #include "mtk_pci.h"
 #include "mtk_pci_reg.h"
 
@@ -467,6 +468,7 @@ static u32 mtk_pci_ext_h2d_evt_hw_bits(u32 chs)
 
 	SET_HW_BITS(hw_bits, chs, MHCCIF_RC2EP_EVT_DEVICE_RESET,
 		    DEV_EVT_H2D_DEVICE_RESET);
+
 	return LE32_TO_U32(cpu_to_le32(hw_bits));
 }
 
@@ -908,13 +910,11 @@ static int mtk_pci_probe(struct pci_dev *pdev, const struct pci_device_id *id)
 	struct mtk_md_dev *mdev;
 	int ret;
 
-	mdev = devm_kzalloc(dev, sizeof(*mdev), GFP_KERNEL);
+	mdev = mtk_dev_alloc(dev, &pci_hw_ops);
 	if (!mdev) {
 		ret = -ENOMEM;
 		goto log_err;
 	}
-	mdev->dev_ops = &pci_hw_ops;
-	mdev->dev = dev;
 
 	priv = devm_kzalloc(dev, sizeof(*priv), GFP_KERNEL);
 	if (!priv) {
@@ -991,7 +991,7 @@ static int mtk_pci_probe(struct pci_dev *pdev, const struct pci_device_id *id)
 free_priv_data:
 	devm_kfree(dev, priv);
 free_cntx_data:
-	devm_kfree(dev, mdev);
+	mtk_dev_free(mdev);
 log_err:
 	dev_err(dev, "Failed to probe device, ret=%d\n", ret);
 
@@ -1017,7 +1017,7 @@ static void mtk_pci_remove(struct pci_dev *pdev)
 	pci_load_and_free_saved_state(pdev, &priv->saved_state);
 
 	devm_kfree(dev, priv);
-	devm_kfree(dev, mdev);
+	mtk_dev_free(mdev);
 }
 
 static pci_ers_result_t mtk_pci_error_detected(struct pci_dev *pdev,
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

