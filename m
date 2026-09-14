From: Jack Wu <jackbb_wu@compal.com>
Date: Mon, 14 Sep 2026 18:31:52 +0800
Subject: [PATCH v8 1/6] net: wwan: t9xx: Add PCIe core
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260914-t9xx_driver_v1-v8-1-5206c2e6bea0@compal.com>
References: <20260914-t9xx_driver_v1-v8-0-5206c2e6bea0@compal.com>
In-Reply-To: <20260914-t9xx_driver_v1-v8-0-5206c2e6bea0@compal.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789381913; l=47428;
 i=jackbb_wu@compal.com; s=20260526; h=from:subject:message-id;
 bh=DeaSYxY34Rn/h5KYDIireLxP6pqTx1OKsBcqgBK5ej4=;
 b=IUoVWUs5sTUn0OOkiWN7NtXXxvUel+0e936ooKghk//UDFodfJBmiiu1CNw5VoFFKRz+kyRqE
 eKKJauxC+9rAZYe1qHyk7KRxWFBD9f2MO9d/OPd5RK+9iAe0yOFN2rt
X-Developer-Key: i=jackbb_wu@compal.com; a=ed25519;
 pk=VH1prTWixNl8OEUPPSfII3p46MzJpQN8J3+ecE1tZXg=
X-Endpoint-Received: by B4 Relay for jackbb_wu@compal.com/20260526 with auth_id=793
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Registers the T900 device driver with the kernel. Set up all
the fundamental configurations for the device: PCIe layer,
Modem Host Cross Core Interface (MHCCIF), modem common control
operations, build infrastructure and MAINTAINERS entry.

* PCIe layer code implements driver probe and removal, MSI-X
  interrupt initialization and de-initialization, and the way
  of resetting the device.
* MHCCIF provides the interrupt channels used for the boot
  handshake and for the host-to-device reset doorbell.
* Modem common control operations provide the basic read/write
  functions of the device's hardware registers,
  mask/unmask/get/clear functions of the device's interrupt
  registers and inquiry functions of the device's status.
* Add MAINTAINERS entry for the MediaTek T9XX 5G WWAN modem
  device driver.

Removal resets the modem.  There is no software reset that
returns the device from running firmware to a state the next
probe can boot, and the next driver load has to redo the
device handshake and status sync, so mtk_pci_remove()
evaluates MRST._RST on the device's own ACPI node.

Signed-off-by: Jack Wu <jackbb_wu@compal.com>
---
 MAINTAINERS                                   |   11 +
 drivers/net/wwan/Kconfig                      |   11 +
 drivers/net/wwan/Makefile                     |    1 +
 drivers/net/wwan/t9xx/Makefile                |   10 +
 drivers/net/wwan/t9xx/mtk_dev.h               |  108 +++
 drivers/net/wwan/t9xx/pcie/mtk_pci.c          | 1020 +++++++++++++++++++++++++
 drivers/net/wwan/t9xx/pcie/mtk_pci.h          |  180 +++++
 drivers/net/wwan/t9xx/pcie/mtk_pci_drv_m9xx.c |   65 ++
 drivers/net/wwan/t9xx/pcie/mtk_pci_reg.h      |   68 ++
 9 files changed, 1474 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 461a3eed6129..8f13ef7440ce 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -16494,6 +16494,17 @@ L:	netdev@vger.kernel.org
 S:	Supported
 F:	drivers/net/wwan/t7xx/
 
+MEDIATEK T9XX 5G WWAN MODEM DRIVER
+M:	Jack Wu <jackbb_wu@compal.com>
+M:	Robert Yu <robert_yu@compal.com>
+M:	Jeff Chang <Jeff_Chang@compal.com>
+R:	Wen-Zhi Huang <wen-zhi.huang@mediatek.com>
+R:	Shi-Wei Yeh <shi-wei.yeh@mediatek.com>
+R:	Minano Tseng <Minano.tseng@mediatek.com>
+L:	netdev@vger.kernel.org
+S:	Supported
+F:	drivers/net/wwan/t9xx/
+
 MEDIATEK USB3 DRD IP DRIVER
 M:	Chunfeng Yun <chunfeng.yun@mediatek.com>
 L:	linux-usb@vger.kernel.org
diff --git a/drivers/net/wwan/Kconfig b/drivers/net/wwan/Kconfig
index 88df55d78d90..55c45af410ee 100644
--- a/drivers/net/wwan/Kconfig
+++ b/drivers/net/wwan/Kconfig
@@ -121,6 +121,17 @@ config MTK_T7XX
 
 	  If unsure, say N.
 
+config MTK_T9XX
+	tristate "MediaTek PCIe 5G WWAN modem T9xx device"
+	depends on PCI && ACPI
+	help
+	  Enables MediaTek PCIe based 5G WWAN modem (T9xx series) device.
+
+	  To compile this driver as a module, choose M here: the module will be
+	  called mtk_t9xx.
+
+	  If unsure, say N.
+
 endif # WWAN
 
 endmenu
diff --git a/drivers/net/wwan/Makefile b/drivers/net/wwan/Makefile
index 3960c0ae2445..7361eef4c472 100644
--- a/drivers/net/wwan/Makefile
+++ b/drivers/net/wwan/Makefile
@@ -14,3 +14,4 @@ obj-$(CONFIG_QCOM_BAM_DMUX) += qcom_bam_dmux.o
 obj-$(CONFIG_RPMSG_WWAN_CTRL) += rpmsg_wwan_ctrl.o
 obj-$(CONFIG_IOSM) += iosm/
 obj-$(CONFIG_MTK_T7XX) += t7xx/
+obj-$(CONFIG_MTK_T9XX) += t9xx/
diff --git a/drivers/net/wwan/t9xx/Makefile b/drivers/net/wwan/t9xx/Makefile
new file mode 100644
index 000000000000..6f2dd3f91454
--- /dev/null
+++ b/drivers/net/wwan/t9xx/Makefile
@@ -0,0 +1,10 @@
+# SPDX-License-Identifier: GPL-2.0-only
+
+ccflags-y += -I$(src)/pcie
+ccflags-y += -I$(src)
+
+obj-$(CONFIG_MTK_T9XX) += mtk_t9xx.o
+
+mtk_t9xx-y := \
+	pcie/mtk_pci.o \
+	pcie/mtk_pci_drv_m9xx.o
diff --git a/drivers/net/wwan/t9xx/mtk_dev.h b/drivers/net/wwan/t9xx/mtk_dev.h
new file mode 100644
index 000000000000..8278a0e2875e
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_dev.h
@@ -0,0 +1,108 @@
+/* SPDX-License-Identifier: GPL-2.0-only
+ *
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#ifndef __MTK_DEV_H__
+#define __MTK_DEV_H__
+
+#include <linux/dma-mapping.h>
+#include <linux/dmapool.h>
+#include <linux/kernel.h>
+#include <linux/module.h>
+#include <linux/sched.h>
+#include <linux/slab.h>
+#include <linux/spinlock.h>
+
+#define MTK_DEV_STR_LEN 16
+
+enum mtk_user_id {
+	MTK_USER_MIN,
+	MTK_USER_CTRL,
+	MTK_USER_DATA,
+	MTK_USER_MAX
+};
+
+enum mtk_dev_evt_h2d {
+	DEV_EVT_H2D_DEVICE_RESET	= BIT(2),
+	DEV_EVT_H2D_MAX			= BIT(5)
+};
+
+enum mtk_dev_evt_d2h {
+	DEV_EVT_D2H_BOOT_FLOW_SYNC	= BIT(4),
+	DEV_EVT_D2H_ASYNC_HS_NOTIFY_SAP = BIT(5),
+	DEV_EVT_D2H_ASYNC_HS_NOTIFY_MD	= BIT(6),
+	DEV_EVT_D2H_MAX			= BIT(11)
+};
+
+struct mtk_md_dev;
+
+struct mtk_dev_ops {
+	u32 (*get_dev_state)(struct mtk_md_dev *mdev);
+	void (*ack_dev_state)(struct mtk_md_dev *mdev, u32 state);
+	u32 (*get_dev_cfg)(struct mtk_md_dev *mdev);
+	int (*register_dev_evt)(struct mtk_md_dev *mdev, u32 dev_evt,
+				int (*evt_cb)(u32 status, void *data), void *data);
+	void (*unregister_dev_evt)(struct mtk_md_dev *mdev, u32 dev_evt);
+	void (*mask_dev_evt)(struct mtk_md_dev *mdev, u32 dev_evt);
+	void (*unmask_dev_evt)(struct mtk_md_dev *mdev, u32 dev_evt);
+	void (*clear_dev_evt)(struct mtk_md_dev *mdev, u32 dev_evt);
+	int (*send_dev_evt)(struct mtk_md_dev *mdev, u32 dev_evt);
+};
+
+/* mtk_md_dev defines the structure of MTK modem device */
+struct mtk_md_dev {
+	struct device *dev;
+	const struct mtk_dev_ops *dev_ops;
+	void *hw_priv;
+	u32 hw_ver;
+	char dev_str[MTK_DEV_STR_LEN];
+};
+
+static inline u32 mtk_dev_get_dev_state(struct mtk_md_dev *mdev)
+{
+	return mdev->dev_ops->get_dev_state(mdev);
+}
+
+static inline void mtk_dev_ack_dev_state(struct mtk_md_dev *mdev, u32 state)
+{
+	return mdev->dev_ops->ack_dev_state(mdev, state);
+}
+
+static inline u32 mtk_dev_get_dev_cfg(struct mtk_md_dev *mdev)
+{
+	return mdev->dev_ops->get_dev_cfg(mdev);
+}
+
+static inline int mtk_dev_register_dev_evt(struct mtk_md_dev *mdev, u32 dev_evt,
+					   int (*evt_cb)(u32 status, void *data), void *data)
+{
+	return mdev->dev_ops->register_dev_evt(mdev, dev_evt, evt_cb, data);
+}
+
+static inline void mtk_dev_unregister_dev_evt(struct mtk_md_dev *mdev, u32 dev_evt)
+{
+	mdev->dev_ops->unregister_dev_evt(mdev, dev_evt);
+}
+
+static inline void mtk_dev_mask_dev_evt(struct mtk_md_dev *mdev, u32 dev_evt)
+{
+	mdev->dev_ops->mask_dev_evt(mdev, dev_evt);
+}
+
+static inline void mtk_dev_unmask_dev_evt(struct mtk_md_dev *mdev, u32 dev_evt)
+{
+	mdev->dev_ops->unmask_dev_evt(mdev, dev_evt);
+}
+
+static inline void mtk_dev_clear_dev_evt(struct mtk_md_dev *mdev, u32 dev_evt)
+{
+	mdev->dev_ops->clear_dev_evt(mdev, dev_evt);
+}
+
+static inline int mtk_dev_send_dev_evt(struct mtk_md_dev *mdev, u32 dev_evt)
+{
+	return mdev->dev_ops->send_dev_evt(mdev, dev_evt);
+}
+
+#endif /* __MTK_DEV_H__ */
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_pci.c b/drivers/net/wwan/t9xx/pcie/mtk_pci.c
new file mode 100644
index 000000000000..eb72efc19652
--- /dev/null
+++ b/drivers/net/wwan/t9xx/pcie/mtk_pci.c
@@ -0,0 +1,1020 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#include <linux/acpi.h>
+#include <linux/aer.h>
+#include <linux/bitfield.h>
+#include <linux/debugfs.h>
+#include <linux/device.h>
+#include <linux/dma-mapping.h>
+#include <linux/kernel.h>
+#include <linux/module.h>
+
+#include "mtk_dev.h"
+#include "mtk_pci.h"
+#include "mtk_pci_reg.h"
+
+#define MTK_PCI_TRANSPARENT_ATR_SIZE	(0x3F)
+#define MTK_PCI_MINIMUM_ATR_SIZE	(0x1000)
+#define ATR_SIZE_LO32_MASK		GENMASK_ULL(31, 0)
+#define ATR_SIZE_HI32_MASK		GENMASK_ULL(63, 32)
+#define ATR_SIZE_BIAS_FROM_LO32		2
+#define ATR_ADDR_ALIGN_MASK		0xFFFFF000
+#define ATR_EN				BIT(0)
+#define ATR_PARAM_OFFSET		16
+#define SET_HW_BITS(dest, chs, mhccif, dev)		\
+	({						\
+		if ((chs) & (dev))					\
+			(dest) |= FIELD_PREP(mhccif, 1);		\
+	})
+
+struct mtk_mhccif_cb {
+	struct list_head entry;
+	int (*evt_cb)(u32 status, void *data);
+	void *data;
+	u32 chs;
+};
+
+/**
+ * mtk_pci_setup_atr() - Configure a PCIe address translation rule
+ * @mdev: MTK MD device
+ * @cfg: ATR configuration parameters
+ *
+ * Return: 0 on success, negative error code on failure.
+ */
+int mtk_pci_setup_atr(struct mtk_md_dev *mdev, struct mtk_atr_cfg *cfg)
+{
+	struct mtk_pci_priv *priv = mdev->hw_priv;
+	u32 addr, val, size_h, size_l;
+	int atr_size, pos, offset;
+
+	if (cfg->transparent) {
+		/* No address conversion is performed */
+		atr_size = MTK_PCI_TRANSPARENT_ATR_SIZE;
+	} else {
+		if (cfg->size < MTK_PCI_MINIMUM_ATR_SIZE)
+			cfg->size = MTK_PCI_MINIMUM_ATR_SIZE;
+
+		if (cfg->src_addr & (cfg->size - 1)) {
+			dev_err(mdev->dev, "Invalid atr src addr is not aligned to size\n");
+			return -EFAULT;
+		}
+
+		if (cfg->trsl_addr & (cfg->size - 1)) {
+			dev_err(mdev->dev,
+				"Invalid atr trsl addr is not aligned to size, %llx, %llx\n",
+				cfg->trsl_addr, cfg->size - 1);
+			return -EFAULT;
+		}
+
+		size_l = FIELD_GET(ATR_SIZE_LO32_MASK, cfg->size);
+		size_h = FIELD_GET(ATR_SIZE_HI32_MASK, cfg->size);
+		pos = ffs(size_l);
+		if (pos) {
+			atr_size = pos - ATR_SIZE_BIAS_FROM_LO32;
+		} else {
+			pos = ffs(size_h);
+			atr_size = pos + 32 - ATR_SIZE_BIAS_FROM_LO32;
+		}
+	}
+
+	/* Calculate table offset */
+	offset = ATR_PORT_OFFSET * cfg->port + ATR_TABLE_OFFSET * cfg->table;
+
+	addr = REG_ATR_PCIE_WIN0_T0_SRC_ADDR_MSB + offset;
+	val = (u32)(cfg->src_addr >> 32);
+	mtk_pci_mac_write32(priv, addr, val);
+
+	addr = REG_ATR_PCIE_WIN0_T0_TRSL_ADDR_MSB + offset;
+	val = (u32)(cfg->trsl_addr >> 32);
+	mtk_pci_mac_write32(priv, addr, val);
+
+	addr = REG_ATR_PCIE_WIN0_T0_TRSL_ADDR_LSB + offset;
+	val = (u32)(cfg->trsl_addr & ATR_ADDR_ALIGN_MASK);
+	mtk_pci_mac_write32(priv, addr, val);
+
+	/* TRSL_PARAM */
+	addr = REG_ATR_PCIE_WIN0_T0_TRSL_PARAM + offset;
+	val = (cfg->trsl_param << ATR_PARAM_OFFSET) | cfg->trsl_id;
+	mtk_pci_mac_write32(priv, addr, val);
+
+	/* Enable ATR last, after translation target is fully programmed */
+	addr = REG_ATR_PCIE_WIN0_T0_SRC_ADDR_LSB + offset;
+	val = (u32)(cfg->src_addr & ATR_ADDR_ALIGN_MASK) | (atr_size << 1) | ATR_EN;
+	mtk_pci_mac_write32(priv, addr, val);
+
+	/* Ensure ATR is set */
+	mtk_pci_mac_read32(priv, addr);
+
+	return 0;
+}
+
+/**
+ * mtk_pci_atr_disable() - Disable all PCIe address translation rules
+ * @priv: MTK PCI private data
+ */
+void mtk_pci_atr_disable(struct mtk_pci_priv *priv)
+{
+	int port, tbl, offset;
+	u32 val;
+
+	/* Disable all ATR table for all ports */
+	for (port = ATR_SRC_PCI_WIN0; port <= ATR_SRC_AXIS_3; port++)
+		for (tbl = 0; tbl < ATR_TABLE_NUM_PER_ATR; tbl++) {
+			/* Calculate table offset */
+			offset = ATR_PORT_OFFSET * port + ATR_TABLE_OFFSET * tbl;
+			val = mtk_pci_mac_read32(priv, REG_ATR_PCIE_WIN0_T0_SRC_ADDR_LSB + offset);
+			val = val & (~BIT(0));
+			/* Disable table by SRC_ADDR_L */
+			mtk_pci_mac_write32(priv, REG_ATR_PCIE_WIN0_T0_SRC_ADDR_LSB + offset, val);
+		}
+}
+
+/**
+ * mtk_pci_get_dev_state() - Read the device state from the modem
+ * @mdev: MTK MD device
+ *
+ * Return: Device state value.
+ */
+u32 mtk_pci_get_dev_state(struct mtk_md_dev *mdev)
+{
+	return mtk_pci_mac_read32(mdev->hw_priv, REG_PCIE_DEBUG_DUMMY_7);
+}
+
+/**
+ * mtk_pci_ack_dev_state() - Acknowledge the device state to the modem
+ * @mdev: MTK MD device
+ * @state: State value to acknowledge
+ */
+void mtk_pci_ack_dev_state(struct mtk_md_dev *mdev, u32 state)
+{
+	mtk_pci_mac_write32(mdev->hw_priv, REG_PCIE_DEBUG_DUMMY_7, state);
+}
+
+/**
+ * mtk_pci_get_irq_id() - Map an IRQ source to its hardware IRQ ID
+ * @mdev: MTK MD device
+ * @irq_src: IRQ source enum
+ *
+ * Return: IRQ ID on success, -EINVAL on failure.
+ */
+int mtk_pci_get_irq_id(struct mtk_md_dev *mdev, enum mtk_irq_src irq_src)
+{
+	struct mtk_pci_priv *priv = mdev->hw_priv;
+	const int *irq_tbl = priv->cfg->irq_tbl;
+	int irq_id = -EINVAL;
+
+	if (irq_src > MTK_IRQ_SRC_MIN && irq_src < MTK_IRQ_SRC_MAX) {
+		irq_id = irq_tbl[irq_src];
+		if (irq_id < 0 || irq_id >= MTK_IRQ_CNT_MAX)
+			irq_id = -EINVAL;
+	}
+
+	return irq_id;
+}
+
+/**
+ * mtk_pci_get_virq_id() - Get the Linux virtual IRQ for a hardware IRQ ID
+ * @mdev: MTK MD device
+ * @irq_id: Hardware IRQ ID
+ *
+ * Return: Virtual IRQ number on success, negative error code on failure.
+ */
+int mtk_pci_get_virq_id(struct mtk_md_dev *mdev, int irq_id)
+{
+	struct pci_dev *pdev = to_pci_dev(mdev->dev);
+	struct mtk_pci_priv *priv = mdev->hw_priv;
+
+	if (irq_id < 0 || irq_id >= priv->irq_cnt)
+		return -EINVAL;
+
+	return pci_irq_vector(pdev, irq_id);
+}
+
+/**
+ * mtk_pci_register_irq() - Register a callback for a hardware IRQ
+ * @mdev: MTK MD device
+ * @irq_id: Hardware IRQ ID
+ * @irq_cb: Callback function
+ * @data: Private data passed to callback
+ *
+ * Return: 0 on success, negative error code on failure.
+ */
+int mtk_pci_register_irq(struct mtk_md_dev *mdev, int irq_id,
+			 int (*irq_cb)(int irq_id, void *data), void *data)
+{
+	struct mtk_pci_priv *priv = mdev->hw_priv;
+
+	if ((irq_id < 0 || irq_id >= MTK_IRQ_CNT_MAX) || !irq_cb)
+		return -EINVAL;
+
+	spin_lock(&priv->irq_cb_lock);
+	if (priv->irq_cb_list[irq_id]) {
+		spin_unlock(&priv->irq_cb_lock);
+		dev_err(mdev->dev,
+			"Unable to register irq, irq_id=%d, it's already been register by %ps.\n",
+			irq_id, priv->irq_cb_list[irq_id]);
+		return -EFAULT;
+	}
+	priv->irq_cb_data[irq_id] = data;
+	smp_wmb(); /* Ensure data is visible before callback */
+	WRITE_ONCE(priv->irq_cb_list[irq_id], irq_cb);
+	spin_unlock(&priv->irq_cb_lock);
+
+	return 0;
+}
+
+/**
+ * mtk_pci_unregister_irq() - Unregister a hardware IRQ callback
+ * @mdev: MTK MD device
+ * @irq_id: Hardware IRQ ID
+ *
+ * Return: 0 on success, negative error code on failure.
+ */
+int mtk_pci_unregister_irq(struct mtk_md_dev *mdev, int irq_id)
+{
+	struct mtk_pci_priv *priv = mdev->hw_priv;
+	int virq_id;
+
+	if (irq_id < 0 || irq_id >= MTK_IRQ_CNT_MAX)
+		return -EINVAL;
+
+	if (!READ_ONCE(priv->irq_cb_list[irq_id])) {
+		dev_err(mdev->dev, "irq_id=%d has not been registered\n", irq_id);
+		return -EFAULT;
+	}
+
+	/* Stop the source and wait for in-flight handlers
+	 * before the callback or its data can disappear.
+	 */
+	mtk_pci_mask_irq(mdev, irq_id);
+	virq_id = mtk_pci_get_virq_id(mdev, irq_id);
+	if (virq_id >= 0)
+		synchronize_irq(virq_id);
+
+	spin_lock(&priv->irq_cb_lock);
+	WRITE_ONCE(priv->irq_cb_list[irq_id], NULL);
+	priv->irq_cb_data[irq_id] = NULL;
+	spin_unlock(&priv->irq_cb_lock);
+
+	return 0;
+}
+
+/**
+ * mtk_pci_mask_irq() - Mask (disable) a hardware IRQ
+ * @mdev: MTK MD device
+ * @irq_id: Hardware IRQ ID
+ *
+ * Return: 0 on success, negative error code on failure.
+ */
+int mtk_pci_mask_irq(struct mtk_md_dev *mdev, int irq_id)
+{
+	struct mtk_pci_priv *priv = mdev->hw_priv;
+
+	if (irq_id < 0 || irq_id >= MTK_IRQ_CNT_MAX ||
+	    priv->irq_type != PCI_IRQ_MSIX) {
+		dev_err(mdev->dev, "Failed to mask irq: input irq_id=%d\n", irq_id);
+		return -EINVAL;
+	}
+
+	mtk_pci_mac_write32(priv, REG_IMASK_HOST_MSIX_CLR_GRP0_0, BIT(irq_id));
+
+	return 0;
+}
+
+/**
+ * mtk_pci_unmask_irq() - Unmask (enable) a hardware IRQ
+ * @mdev: MTK MD device
+ * @irq_id: Hardware IRQ ID
+ *
+ * Return: 0 on success, negative error code on failure.
+ */
+int mtk_pci_unmask_irq(struct mtk_md_dev *mdev, int irq_id)
+{
+	struct mtk_pci_priv *priv = mdev->hw_priv;
+
+	if (irq_id < 0 || irq_id >= MTK_IRQ_CNT_MAX ||
+	    priv->irq_type != PCI_IRQ_MSIX) {
+		dev_err(mdev->dev, "Failed to unmask irq: input irq_id=%d\n", irq_id);
+		return -EINVAL;
+	}
+
+	mtk_pci_mac_write32(priv, REG_IMASK_HOST_MSIX_SET_GRP0_0, BIT(irq_id));
+
+	return 0;
+}
+
+/**
+ * mtk_pci_clear_irq() - Clear (acknowledge) a hardware IRQ
+ * @mdev: MTK MD device
+ * @irq_id: Hardware IRQ ID
+ *
+ * Return: 0 on success, negative error code on failure.
+ */
+int mtk_pci_clear_irq(struct mtk_md_dev *mdev, int irq_id)
+{
+	struct mtk_pci_priv *priv = mdev->hw_priv;
+
+	if (irq_id < 0 || irq_id >= MTK_IRQ_CNT_MAX ||
+	    priv->irq_type != PCI_IRQ_MSIX) {
+		dev_err(mdev->dev, "Failed to clear irq: input irq_id=%d\n", irq_id);
+		return -EINVAL;
+	}
+
+	mtk_pci_mac_write32(priv, REG_MSIX_ISTATUS_HOST_GRP0_0, BIT(irq_id));
+
+	return 0;
+}
+
+static u32 mtk_pci_ext_d2h_evt_hw_bits(u32 chs)
+{
+	u32 hw_bits = 0;
+
+	SET_HW_BITS(hw_bits, chs, MHCCIF_EP2RC_EVT_BOOT_FLOW_SYNC,
+		    DEV_EVT_D2H_BOOT_FLOW_SYNC);
+	SET_HW_BITS(hw_bits, chs, MHCCIF_EP2RC_EVT_ASYNC_HS_NOTIFY_SAP,
+		    DEV_EVT_D2H_ASYNC_HS_NOTIFY_SAP);
+	SET_HW_BITS(hw_bits, chs, MHCCIF_EP2RC_EVT_ASYNC_HS_NOTIFY_MD,
+		    DEV_EVT_D2H_ASYNC_HS_NOTIFY_MD);
+
+	return hw_bits;
+}
+
+static u32 mtk_pci_ext_d2h_evt_chs(u32 hw_bits)
+{
+	u32 chs = 0;
+
+	if (!hw_bits)
+		return chs;
+
+	chs = FIELD_PREP(DEV_EVT_D2H_BOOT_FLOW_SYNC,
+			 FIELD_GET(MHCCIF_EP2RC_EVT_BOOT_FLOW_SYNC, hw_bits)) |
+	      FIELD_PREP(DEV_EVT_D2H_ASYNC_HS_NOTIFY_SAP,
+			 FIELD_GET(MHCCIF_EP2RC_EVT_ASYNC_HS_NOTIFY_SAP, hw_bits)) |
+	      FIELD_PREP(DEV_EVT_D2H_ASYNC_HS_NOTIFY_MD,
+			 FIELD_GET(MHCCIF_EP2RC_EVT_ASYNC_HS_NOTIFY_MD, hw_bits));
+
+	return chs;
+}
+
+/**
+ * mtk_pci_register_ext_evt() - Register a callback for MHCCIF device events
+ * @mdev: MTK MD device
+ * @chs: Bitmask of event channels to register
+ * @evt_cb: Callback function
+ * @data: Private data passed to callback
+ *
+ * Return: 0 on success, negative error code on failure.
+ */
+int mtk_pci_register_ext_evt(struct mtk_md_dev *mdev, u32 chs,
+			     int (*evt_cb)(u32 status, void *data), void *data)
+{
+	struct mtk_pci_priv *priv = mdev->hw_priv;
+	struct mtk_mhccif_cb *cb;
+	int ret = 0;
+
+	if (!chs || !evt_cb)
+		return -EINVAL;
+
+	spin_lock_bh(&priv->mhccif_lock);
+	list_for_each_entry(cb, &priv->mhccif_cb_list, entry) {
+		if (cb->chs & chs) {
+			ret = -EFAULT;
+			dev_err(mdev->dev,
+				"Unable to register evt, intersection: chs=0x%08x&0x%08x cb=%ps\n",
+				chs, cb->chs, cb->evt_cb);
+			goto err_spin_unlock;
+		}
+	}
+	cb = kzalloc(sizeof(*cb), GFP_ATOMIC);
+	if (!cb) {
+		ret = -ENOMEM;
+		goto err_spin_unlock;
+	}
+	cb->evt_cb = evt_cb;
+	cb->data = data;
+	cb->chs = chs;
+	list_add_tail(&cb->entry, &priv->mhccif_cb_list);
+err_spin_unlock:
+	spin_unlock_bh(&priv->mhccif_lock);
+
+	return ret;
+}
+
+/**
+ * mtk_pci_unregister_ext_evt() - Unregister an MHCCIF device event callback
+ * @mdev: MTK MD device
+ * @chs: Bitmask of event channels to unregister
+ */
+void mtk_pci_unregister_ext_evt(struct mtk_md_dev *mdev, u32 chs)
+{
+	struct mtk_pci_priv *priv = mdev->hw_priv;
+	struct mtk_mhccif_cb *cb, *next;
+
+	if (!chs)
+		return;
+
+	spin_lock_bh(&priv->mhccif_lock);
+	list_for_each_entry_safe(cb, next, &priv->mhccif_cb_list, entry) {
+		if (cb->chs == chs) {
+			list_del(&cb->entry);
+			kfree(cb);
+			goto out;
+		}
+	}
+	dev_warn(mdev->dev,
+		 "Unable to unregister evt, no chs=0x%08x has been registered.\n", chs);
+out:
+	spin_unlock_bh(&priv->mhccif_lock);
+}
+
+/**
+ * mtk_pci_mask_ext_evt() - Mask (disable) MHCCIF device events
+ * @mdev: MTK MD device
+ * @chs: Bitmask of event channels to mask
+ */
+void mtk_pci_mask_ext_evt(struct mtk_md_dev *mdev, u32 chs)
+{
+	struct mtk_pci_priv *priv = mdev->hw_priv;
+	u32 hw_bits = mtk_pci_ext_d2h_evt_hw_bits(chs);
+
+	mtk_pci_write32(mdev, priv->cfg->mhccif_rc_base_addr +
+			MHCCIF_EP2RC_SW_INT_EAP_MASK_SET, hw_bits);
+}
+
+/**
+ * mtk_pci_unmask_ext_evt() - Unmask (enable) MHCCIF device events
+ * @mdev: MTK MD device
+ * @chs: Bitmask of event channels to unmask
+ */
+void mtk_pci_unmask_ext_evt(struct mtk_md_dev *mdev, u32 chs)
+{
+	struct mtk_pci_priv *priv = mdev->hw_priv;
+	u32 hw_bits = mtk_pci_ext_d2h_evt_hw_bits(chs);
+
+	mtk_pci_write32(mdev, priv->cfg->mhccif_rc_base_addr +
+			MHCCIF_EP2RC_SW_INT_EAP_MASK_CLR, hw_bits);
+}
+
+/**
+ * mtk_pci_clear_ext_evt() - Clear (acknowledge) MHCCIF device events
+ * @mdev: MTK MD device
+ * @chs: Bitmask of event channels to clear
+ */
+void mtk_pci_clear_ext_evt(struct mtk_md_dev *mdev, u32 chs)
+{
+	struct mtk_pci_priv *priv = mdev->hw_priv;
+	u32 hw_bits = mtk_pci_ext_d2h_evt_hw_bits(chs);
+
+	mtk_pci_write32(mdev, priv->cfg->mhccif_rc_base_addr +
+			MHCCIF_EP2RC_SW_INT_ACK, hw_bits);
+}
+
+static u32 mtk_pci_ext_h2d_evt_hw_bits(u32 chs)
+{
+	u32 hw_bits = 0;
+
+	SET_HW_BITS(hw_bits, chs, MHCCIF_RC2EP_EVT_DEVICE_RESET,
+		    DEV_EVT_H2D_DEVICE_RESET);
+	return hw_bits;
+}
+
+/**
+ * mtk_pci_send_ext_evt() - Send an MHCCIF event to the modem
+ * @mdev: MTK MD device
+ * @ch: Event channel to trigger (must be a single bit)
+ *
+ * Return: 0 on success, negative error code on failure.
+ */
+int mtk_pci_send_ext_evt(struct mtk_md_dev *mdev, u32 ch)
+{
+	struct mtk_pci_priv *priv = mdev->hw_priv;
+	u32 rc_base, hw_bits;
+
+	rc_base = priv->cfg->mhccif_rc_base_addr;
+
+	/* Only allow one ch to be triggered at a time */
+	if (!is_power_of_2(ch)) {
+		dev_err(mdev->dev, "Unsupported ext evt ch=0x%08x\n", ch);
+		return -EINVAL;
+	}
+
+	hw_bits = mtk_pci_ext_h2d_evt_hw_bits(ch);
+	if (!hw_bits) {
+		dev_err(mdev->dev, "Unmapped ext evt ch=0x%08x\n", ch);
+		return -EINVAL;
+	}
+
+	mtk_pci_write32(mdev, rc_base + MHCCIF_RC2EP_SW_BSY, hw_bits);
+	mtk_pci_write32(mdev, rc_base + MHCCIF_RC2EP_SW_TCHNUM, ffs(hw_bits) - 1);
+	return 0;
+}
+
+static u32 mtk_pci_get_ext_evt_hw_status(struct mtk_md_dev *mdev)
+{
+	struct mtk_pci_priv *priv = mdev->hw_priv;
+
+	return mtk_pci_read32(mdev, priv->cfg->mhccif_rc_base_addr +
+			      MHCCIF_EP2RC_SW_INT_STS);
+}
+
+static void mtk_pci_ack_ext_evt_hw(struct mtk_md_dev *mdev, u32 hw_bits)
+{
+	struct mtk_pci_priv *priv = mdev->hw_priv;
+
+	mtk_pci_write32(mdev, priv->cfg->mhccif_rc_base_addr +
+			MHCCIF_EP2RC_SW_INT_ACK, hw_bits);
+	/* Ensure the ack lands before level 1 is cleared */
+	mtk_pci_read32(mdev, priv->cfg->mhccif_rc_base_addr +
+		       MHCCIF_EP2RC_SW_INT_STS);
+}
+
+/**
+ * mtk_pci_pldr() - Reset the modem via its ACPI MRST._RST method
+ * @mdev: MTK MD device
+ *
+ * Return:
+ * * 0       - Success, device was reset.
+ * * -ENODEV - No ACPI, no handle or no MRST._RST method.  Device
+ *             untouched.
+ * * -EIO    - MRST._RST failed.  Device untouched, still running;
+ *             a different reset may be attempted.
+ */
+int mtk_pci_pldr(struct mtk_md_dev *mdev)
+{
+	struct acpi_buffer buffer = { ACPI_ALLOCATE_BUFFER, NULL };
+	acpi_status acpi_ret;
+	acpi_handle handle;
+
+	if (acpi_disabled) {
+		dev_err(mdev->dev, "Unsupported, acpi function isn't enable\n");
+		return -ENODEV;
+	}
+
+	handle = ACPI_HANDLE(mdev->dev);
+	if (!handle) {
+		dev_err(mdev->dev, "Unsupported, acpi handle isn't found\n");
+		return -ENODEV;
+	}
+	if (!acpi_has_method(handle, "MRST._RST")) {
+		dev_err(mdev->dev, "Unsupported, pldr method isn't supported\n");
+		return -ENODEV;
+	}
+	acpi_ret = acpi_evaluate_object(handle, "MRST._RST", NULL, &buffer);
+	if (ACPI_FAILURE(acpi_ret)) {
+		dev_err(mdev->dev, "Failed to execute MRST._RST method: %s\n",
+			acpi_format_exception(acpi_ret));
+		return -EIO;
+	}
+	acpi_os_free(buffer.pointer);
+
+	return 0;
+}
+
+/**
+ * mtk_pci_get_dev_cfg() - Read the device configuration from the modem
+ * @mdev: MTK MD device
+ *
+ * Return: Device configuration value.
+ */
+u32 mtk_pci_get_dev_cfg(struct mtk_md_dev *mdev)
+{
+	u32 val;
+
+	val = mtk_pci_mac_read32(mdev->hw_priv, REG_PCIE_DEBUG_DUMMY_4);
+	return (val >> MTK_CFG_INFO_BIT_SHIFT);
+}
+
+/**
+ * mtk_pci_link_check() - Check if the PCIe link to the modem is active
+ * @mdev: MTK MD device
+ *
+ * Return: true if the device is present, false otherwise.
+ */
+bool mtk_pci_link_check(struct mtk_md_dev *mdev)
+{
+	return pci_device_is_present(to_pci_dev(mdev->dev));
+}
+
+static void mtk_mhccif_isr_work(struct work_struct *work)
+{
+	struct mtk_pci_priv *priv =
+		container_of(work, struct mtk_pci_priv, mhccif_work);
+	struct mtk_md_dev *mdev = priv->irq_desc->mdev;
+	struct mtk_mhccif_cb *cb;
+	u32 stat, mask, chs;
+
+	stat = mtk_pci_get_ext_evt_hw_status(mdev);
+	mask = mtk_pci_read32(mdev, priv->cfg->mhccif_rc_base_addr
+		+ MHCCIF_EP2RC_SW_INT_EAP_MASK);
+	if (unlikely(stat == U32_MAX && !(mtk_pci_link_check(mdev)))) {
+		/* When link failed, we don't need to unmask/clear. */
+		dev_err(mdev->dev, "Failed to check link in MHCCIF handler.\n");
+		return;
+	}
+
+	stat &= ~mask;
+	/* Acknowledge level 2 before dispatch: an event that re-asserts
+	 * while a callback runs must survive as a new status bit.
+	 */
+	if (stat)
+		mtk_pci_ack_ext_evt_hw(mdev, stat);
+
+	chs = mtk_pci_ext_d2h_evt_chs(stat);
+	/* Callbacks must not sleep or modify mhccif_cb_list */
+	spin_lock_bh(&priv->mhccif_lock);
+	list_for_each_entry(cb, &priv->mhccif_cb_list, entry) {
+		if (cb->chs & chs)
+			cb->evt_cb(cb->chs & chs, cb->data);
+	}
+	spin_unlock_bh(&priv->mhccif_lock);
+
+	mtk_pci_clear_irq(mdev, priv->mhccif_irq_id);
+	mtk_pci_unmask_irq(mdev, priv->mhccif_irq_id);
+}
+
+static const struct  pci_device_id t9xx_pci_table[] = {
+	MTK_PCI_DEV_CFG(0x0900, mtk_dev_cfg_0900),
+	CEI_PCI_DEV_CFG(0x01CA, mtk_dev_cfg_0900),
+	{/* end: all zeroes */}
+};
+
+MODULE_DEVICE_TABLE(pci, t9xx_pci_table);
+
+static int mtk_pci_bar_init(struct mtk_md_dev *mdev)
+{
+	struct pci_dev *pdev = to_pci_dev(mdev->dev);
+	struct mtk_pci_priv *priv = mdev->hw_priv;
+
+	priv->mac_reg_base = pcim_iomap_region(pdev, MTK_BAR_0_1_IDX,
+					       mdev->dev_str);
+	if (IS_ERR(priv->mac_reg_base)) {
+		dev_err(mdev->dev, "Failed to map BAR0/1\n");
+		return PTR_ERR(priv->mac_reg_base);
+	}
+
+	priv->bar23_addr = pcim_iomap_region(pdev, MTK_BAR_2_3_IDX,
+					     mdev->dev_str);
+	if (IS_ERR(priv->bar23_addr)) {
+		dev_err(mdev->dev, "Failed to map BAR2/3\n");
+		return PTR_ERR(priv->bar23_addr);
+	}
+
+	/* We use MD view base address "0" to observe registers */
+	priv->ext_reg_base = priv->bar23_addr - ATR_PCIE_REG_TRSL_ADDR;
+
+	return 0;
+}
+
+static int mtk_mhccif_irq_cb(int irq_id, void *data)
+{
+	struct mtk_md_dev *mdev = data;
+	struct mtk_pci_priv *priv;
+
+	priv = mdev->hw_priv;
+	queue_work(system_highpri_wq, &priv->mhccif_work);
+
+	return 0;
+}
+
+static int mtk_mhccif_init(struct mtk_md_dev *mdev)
+{
+	struct mtk_pci_priv *priv = mdev->hw_priv;
+	int ret;
+
+	INIT_LIST_HEAD(&priv->mhccif_cb_list);
+	spin_lock_init(&priv->mhccif_lock);
+	INIT_WORK(&priv->mhccif_work, mtk_mhccif_isr_work);
+
+	/* The write below goes through the BAR 2/3 ATR window, so this
+	 * function must run after priv->cfg->atr_init().
+	 * Mask every channel; consumers unmask the channels they need.
+	 * Do NOT ack here: EP2RC status bits are latched one-shot
+	 * notifications (e.g. BOOT_FLOW_SYNC raised before the driver
+	 * loads) that the device never re-sends.  Masking blocks
+	 * delivery but preserves the bit for delivery on unmask; an
+	 * ack would erase it and the boot flow would hang silently.
+	 */
+	mtk_pci_write32(mdev, priv->cfg->mhccif_rc_base_addr +
+			MHCCIF_EP2RC_SW_INT_EAP_MASK_SET, U32_MAX);
+
+	ret = mtk_pci_get_irq_id(mdev, MTK_IRQ_SRC_MHCCIF);
+	if (ret < 0) {
+		dev_err(mdev->dev, "Failed to get mhccif_irq_id. ret=%d\n", ret);
+		return ret;
+	}
+	priv->mhccif_irq_id = ret;
+
+	ret = mtk_pci_register_irq(mdev, priv->mhccif_irq_id, mtk_mhccif_irq_cb, mdev);
+	if (ret) {
+		dev_err(mdev->dev, "Failed to register mhccif_irq callback\n");
+		return ret;
+	}
+
+	return 0;
+}
+
+static void mtk_mhccif_exit(struct mtk_md_dev *mdev)
+{
+	struct mtk_pci_priv *priv = mdev->hw_priv;
+	struct mtk_mhccif_cb *cb, *tmp;
+
+	mtk_pci_unregister_irq(mdev, priv->mhccif_irq_id);
+	cancel_work_sync(&priv->mhccif_work);
+
+	list_for_each_entry_safe(cb, tmp, &priv->mhccif_cb_list, entry) {
+		list_del(&cb->entry);
+		kfree(cb);
+	}
+}
+
+static irqreturn_t mtk_pci_irq_handler(struct mtk_md_dev *mdev, u32 irq_state)
+{
+	struct mtk_pci_priv *priv = mdev->hw_priv;
+	int irq_id;
+
+	/* Check whether each set bit has a callback, if has, call it */
+	do {
+		int (*cb)(int irq_id, void *data);
+
+		irq_id = fls(irq_state) - 1;
+		irq_state &= ~BIT(irq_id);
+		cb = READ_ONCE(priv->irq_cb_list[irq_id]);
+		if (likely(cb)) {
+			smp_rmb(); /* Ensure data is read after callback */
+			cb(irq_id, priv->irq_cb_data[irq_id]);
+		} else {
+			dev_err_ratelimited(mdev->dev,
+					    "Unhandled irq_id=%d, no callback for it.\n",
+					    irq_id);
+			mtk_pci_clear_irq(mdev, irq_id);
+		}
+	} while (irq_state);
+
+	return IRQ_HANDLED;
+}
+
+static irqreturn_t mtk_pci_irq_msix(int irq, void *data)
+{
+	struct mtk_pci_irq_desc *irq_desc = data;
+	struct mtk_md_dev *mdev = irq_desc->mdev;
+	struct mtk_pci_priv *priv;
+	u32 irq_state, irq_enable;
+
+	priv = mdev->hw_priv;
+	irq_state = mtk_pci_mac_read32(priv, REG_MSIX_ISTATUS_HOST_GRP0_0);
+	irq_enable = mtk_pci_mac_read32(priv, REG_IMASK_HOST_MSIX_GRP0_0);
+	irq_state &= irq_enable;
+
+	if (unlikely(irq_state == U32_MAX && irq_enable == U32_MAX))
+		return IRQ_NONE; /* device gone */
+
+	irq_state &= irq_desc->msix_bits; /* scope to this vector */
+	if (unlikely(!irq_state))
+		return IRQ_NONE;
+
+	/* Mask the bit; the consumer unmasks it when it is done */
+	mtk_pci_mac_write32(priv, REG_IMASK_HOST_MSIX_CLR_GRP0_0, irq_state);
+
+	return mtk_pci_irq_handler(mdev, irq_state);
+}
+
+static int mtk_pci_request_irq_msix(struct mtk_md_dev *mdev)
+{
+	struct mtk_pci_priv *priv = mdev->hw_priv;
+	struct mtk_pci_irq_desc *irq_desc;
+	struct pci_dev *pdev;
+	int ret, i;
+
+	pdev = to_pci_dev(mdev->dev);
+	irq_desc = priv->irq_desc;
+
+	priv->irq_cnt = MTK_IRQ_CNT_MAX;
+	priv->irq_type = PCI_IRQ_MSIX;
+
+	for (i = 0; i < MTK_IRQ_CNT_MAX; i++) {
+		irq_desc[i].mdev = mdev;
+		irq_desc[i].msix_bits = BIT(i);
+		snprintf(irq_desc[i].name, MTK_IRQ_NAME_LEN, "msix%d-%s", i, mdev->dev_str);
+		ret = pci_request_irq(pdev, i, mtk_pci_irq_msix, NULL,
+				      &irq_desc[i], "%s", irq_desc[i].name);
+		if (ret) {
+			dev_err(mdev->dev, "Failed to request %s: ret=%d\n",
+				irq_desc[i].name, ret);
+			for (i--; i >= 0; i--)
+				pci_free_irq(pdev, i, &irq_desc[i]);
+			priv->irq_cnt = 0;
+			priv->irq_type = 0;
+			return ret;
+		}
+	}
+
+	return 0;
+}
+
+static int mtk_pci_request_irq(struct mtk_md_dev *mdev)
+{
+	struct pci_dev *pdev = to_pci_dev(mdev->dev);
+	int ret;
+
+	ret = pci_alloc_irq_vectors(pdev, MTK_IRQ_CNT_MAX,
+				    MTK_IRQ_CNT_MAX, PCI_IRQ_MSIX);
+	if (ret < 0) {
+		dev_err(mdev->dev,
+			"Unable to alloc %d MSI-X vectors: ret=%d\n",
+			MTK_IRQ_CNT_MAX, ret);
+		return ret;
+	}
+
+	ret = mtk_pci_request_irq_msix(mdev);
+	if (ret)
+		pci_free_irq_vectors(pdev);
+
+	return ret;
+}
+
+static void mtk_pci_free_irq(struct mtk_md_dev *mdev)
+{
+	struct pci_dev *pdev = to_pci_dev(mdev->dev);
+	struct mtk_pci_priv *priv = mdev->hw_priv;
+	int i;
+
+	for (i = 0; i < priv->irq_cnt; i++)
+		pci_free_irq(pdev, i, &priv->irq_desc[i]);
+
+	pci_free_irq_vectors(pdev);
+}
+
+static const struct mtk_dev_ops pci_hw_ops = {
+	.get_dev_state = mtk_pci_get_dev_state,
+	.ack_dev_state = mtk_pci_ack_dev_state,
+	.get_dev_cfg = mtk_pci_get_dev_cfg,
+	.register_dev_evt = mtk_pci_register_ext_evt,
+	.unregister_dev_evt = mtk_pci_unregister_ext_evt,
+	.mask_dev_evt = mtk_pci_mask_ext_evt,
+	.unmask_dev_evt = mtk_pci_unmask_ext_evt,
+	.clear_dev_evt = mtk_pci_clear_ext_evt,
+	.send_dev_evt = mtk_pci_send_ext_evt,
+};
+
+static int mtk_pci_probe(struct pci_dev *pdev, const struct pci_device_id *id)
+{
+	struct device *dev = &pdev->dev;
+	struct mtk_pci_priv *priv;
+	struct mtk_md_dev *mdev;
+	int ret;
+
+	mdev = devm_kzalloc(dev, sizeof(*mdev), GFP_KERNEL);
+	if (!mdev) {
+		ret = -ENOMEM;
+		goto log_err;
+	}
+	mdev->dev_ops = &pci_hw_ops;
+	mdev->dev = dev;
+
+	priv = devm_kzalloc(dev, sizeof(*priv), GFP_KERNEL);
+	if (!priv) {
+		ret = -ENOMEM;
+		goto log_err;
+	}
+
+	pci_set_drvdata(pdev, mdev);
+	priv->cfg = (void *)id->driver_data;
+	priv->mdev = mdev;
+	mdev->hw_ver  = pdev->device;
+	mdev->hw_priv = priv;
+	mdev->dev     = dev;
+	snprintf(mdev->dev_str, MTK_DEV_STR_LEN, "%02x%02x%d",
+		 pdev->bus->number, PCI_SLOT(pdev->devfn), PCI_FUNC(pdev->devfn));
+	if (pdev->state_saved)
+		pci_restore_state(pdev);
+
+	ret = pcim_enable_device(pdev);
+	if (ret) {
+		dev_err(mdev->dev, "Failed to enable pci device.\n");
+		goto log_err;
+	}
+
+	ret = dma_set_mask_and_coherent(&pdev->dev, DMA_BIT_MASK(64));
+	if (ret) {
+		dev_err(mdev->dev, "Failed to set DMA Mask and Coherent. (ret=%d)\n", ret);
+		goto log_err;
+	}
+
+	ret = mtk_pci_bar_init(mdev);
+	if (ret)
+		goto log_err;
+
+	ret = priv->cfg->atr_init(mdev);
+	if (ret)
+		goto log_err;
+
+	spin_lock_init(&priv->irq_cb_lock);
+
+	ret = mtk_mhccif_init(mdev);
+	if (ret)
+		goto log_err;
+
+	/* Mask every source before the handlers go in, so a source
+	 * left enabled by firmware or a previous bind cannot fire
+	 * into a half-initialised driver.
+	 */
+	mtk_pci_mac_write32(priv, REG_IMASK_HOST_MSIX_CLR_GRP0_0, U32_MAX);
+
+	ret = mtk_pci_request_irq(mdev);
+	if (ret)
+		goto free_mhccif;
+
+	pci_set_master(pdev);
+	mtk_pci_unmask_irq(mdev, priv->mhccif_irq_id);
+
+	if (!mtk_pci_link_check(mdev)) {
+		ret = -ENOLINK;
+		goto clear_master;
+	}
+
+	ret = pci_save_state(pdev);
+	if (ret) {
+		dev_err(mdev->dev, "Failed to save PCI state: %d\n", ret);
+		goto clear_master;
+	}
+
+	priv->saved_state = pci_store_saved_state(pdev);
+	if (!priv->saved_state) {
+		ret = -ENOMEM;
+		goto clear_master;
+	}
+
+	return 0;
+
+clear_master:
+	pci_clear_master(pdev);
+	mtk_pci_free_irq(mdev);
+free_mhccif:
+	mtk_mhccif_exit(mdev);
+log_err:
+	dev_err(dev, "Failed to probe device, ret=%d\n", ret);
+
+	return ret;
+}
+
+static void mtk_pci_remove(struct pci_dev *pdev)
+{
+	struct mtk_md_dev *mdev = pci_get_drvdata(pdev);
+	struct mtk_pci_priv *priv = mdev->hw_priv;
+	struct device *dev = &pdev->dev;
+	int ret;
+
+	/* Silence every source before tearing anything down. */
+	mtk_pci_mac_write32(priv, REG_IMASK_HOST_MSIX_CLR_GRP0_0, U32_MAX);
+
+	/* Unregisters the callback (masks and synchronises the vector),
+	 * then cancels the work.  With the callback gone the work cannot
+	 * be requeued.
+	 */
+	mtk_mhccif_exit(mdev);
+	mtk_pci_free_irq(mdev);
+	pci_clear_master(pdev);
+
+	/* Reset last: the endpoint comes back at power-on defaults,
+	 * so no MMIO, config write or MSI-X teardown may follow it.
+	 */
+	ret = mtk_pci_pldr(mdev);
+	if (ret && mtk_pci_link_check(mdev)) {
+		dev_warn(dev, "PLDR failed (%d), trying MHCCIF reset\n", ret);
+		if (mtk_pci_send_ext_evt(mdev, DEV_EVT_H2D_DEVICE_RESET))
+			dev_err(dev, "MHCCIF reset failed\n");
+	}
+
+	pci_load_and_free_saved_state(pdev, &priv->saved_state);
+}
+
+static pci_ers_result_t mtk_pci_error_detected(struct pci_dev *pdev,
+					       pci_channel_state_t state)
+{
+	struct mtk_md_dev *mdev = pci_get_drvdata(pdev);
+
+	dev_err(mdev->dev, "AER detected: pci_channel_state_t=%d\n", state);
+
+	/* AER recovery not supported, disconnect the device */
+	return PCI_ERS_RESULT_DISCONNECT;
+}
+
+static const struct pci_error_handlers mtk_pci_err_handler = {
+	.error_detected = mtk_pci_error_detected,
+};
+
+static struct pci_driver mtk_pci_drv = {
+	.name = "mtk_pci_drv",
+	.id_table = t9xx_pci_table,
+	.probe = mtk_pci_probe,
+	.remove = mtk_pci_remove,
+	.err_handler = &mtk_pci_err_handler
+};
+
+module_pci_driver(mtk_pci_drv);
+
+MODULE_DESCRIPTION("MediaTek T9xx PCIe WWAN driver pcie layer");
+MODULE_LICENSE("GPL");
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_pci.h b/drivers/net/wwan/t9xx/pcie/mtk_pci.h
new file mode 100644
index 000000000000..f6fdf9a251f7
--- /dev/null
+++ b/drivers/net/wwan/t9xx/pcie/mtk_pci.h
@@ -0,0 +1,180 @@
+/* SPDX-License-Identifier: GPL-2.0-only
+ *
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#ifndef __MTK_PCI_H__
+#define __MTK_PCI_H__
+
+#include <linux/pci.h>
+
+#include "../mtk_dev.h"
+
+enum mtk_irq_src {
+	MTK_IRQ_SRC_MIN,
+	MTK_IRQ_SRC_MHCCIF,
+	MTK_IRQ_SRC_DPMAIF,
+	MTK_IRQ_SRC_DPMAIF2,
+	MTK_IRQ_SRC_CLDMA0,
+	MTK_IRQ_SRC_CLDMA1,
+	MTK_IRQ_SRC_CLDMA2,
+	MTK_IRQ_SRC_CLDMA3,
+	MTK_IRQ_SRC_PM_LOCK,
+	MTK_IRQ_SRC_DPMAIF3,
+	MTK_IRQ_SRC_DPMAIF6,
+	MTK_IRQ_SRC_MAX
+};
+
+enum mtk_atr_src_port {
+	ATR_SRC_PCI_WIN0 = 0,
+	ATR_SRC_PCI_WIN1,
+	ATR_SRC_AXIS_0,
+	ATR_SRC_AXIS_1,
+	ATR_SRC_AXIS_2,
+	ATR_SRC_AXIS_3,
+};
+
+enum mtk_atr_dst_port {
+	ATR_DST_PCI_TRX = 0,
+	ATR_DST_AXIM_0 = 4,
+	ATR_DST_AXIM_1,
+	ATR_DST_AXIM_2,
+	ATR_DST_AXIM_3,
+};
+
+#define MTK_PCI_CLASS                 0x0D4000
+#define MTK_PCI_VENDOR_ID             0x14C3
+#define CEI_PCI_VENDOR_ID             0x03F0
+
+#define MTK_CFG_INFO_BIT_SHIFT        4
+
+#define MTK_PCI_DEV_CFG(id, cfg) \
+{ \
+	PCI_DEVICE(MTK_PCI_VENDOR_ID, id), \
+	MTK_PCI_CLASS, PCI_ANY_ID, \
+	.driver_data = (kernel_ulong_t)&(cfg), \
+}
+
+#define CEI_PCI_DEV_CFG(id, cfg) \
+{ \
+	PCI_DEVICE(CEI_PCI_VENDOR_ID, id), \
+	MTK_PCI_CLASS, PCI_ANY_ID, \
+	.driver_data = (kernel_ulong_t)&(cfg), \
+}
+
+#define MTK_BAR_0_1_IDX                 0
+#define MTK_BAR_2_3_IDX                 2
+
+#define MTK_IRQ_CNT_MAX				32
+#define MTK_IRQ_NAME_LEN			32
+
+#define ATR_PORT_OFFSET				0x100
+#define ATR_TABLE_OFFSET			0x20
+#define ATR_TABLE_NUM_PER_ATR			8
+#define ATR_PCIE_REG_TRSL_ADDR			0x10000000
+#define ATR_PCIE_REG_SIZE			0x00400000
+#define ATR_PCIE_REG_PORT			ATR_SRC_PCI_WIN0
+#define ATR_PCIE_REG_TABLE_NUM			1
+#define ATR_PCIE_REG_TRSL_PORT			ATR_DST_AXIM_0
+#define ATR_PCIE_DEV_DMA_SRC_ADDR		0x00000000
+#define ATR_PCIE_DEV_DMA_TRANSPARENT		1
+#define ATR_PCIE_DEV_DMA_SIZE			0
+#define ATR_PCIE_DEV_DMA_TABLE_NUM		0
+#define ATR_PCIE_DEV_DMA_TRSL_ADDR		0x00000000
+
+struct mtk_pci_irq_desc {
+	struct mtk_md_dev *mdev;
+	u32 msix_bits;
+	char name[MTK_IRQ_NAME_LEN];
+};
+
+struct mtk_pci_dev_cfg {
+	u32 mhccif_rc_base_addr;
+	int irq_tbl[MTK_IRQ_SRC_MAX];
+	int (*atr_init)(struct mtk_md_dev *mdev);
+};
+
+extern const struct mtk_pci_dev_cfg mtk_dev_cfg_0900;
+
+struct mtk_pci_priv {
+	struct mtk_md_dev *mdev;
+	const struct mtk_pci_dev_cfg *cfg;
+	void __iomem *bar23_addr;
+	void __iomem *mac_reg_base;
+	void __iomem *ext_reg_base;
+	int irq_cnt;
+	int irq_type;
+	/* irq_cb_lock: protects irq_cb_list[] and irq_cb_data[] */
+	spinlock_t irq_cb_lock;
+	void *irq_cb_data[MTK_IRQ_CNT_MAX];
+
+	int (*irq_cb_list[MTK_IRQ_CNT_MAX])(int irq_id, void *data);
+	struct mtk_pci_irq_desc irq_desc[MTK_IRQ_CNT_MAX];
+	struct list_head mhccif_cb_list;
+	/* mhccif_lock: lock to protect mhccif_cb_list */
+	spinlock_t mhccif_lock;
+	struct work_struct mhccif_work;
+	int mhccif_irq_id;
+	struct pci_saved_state *saved_state;
+};
+
+struct mtk_atr_cfg {
+	u64 src_addr;
+	u64 trsl_addr;
+	u64 size;
+	u32 port;      /* Port number */
+	u32 table;     /* Table number (8 tables for each port) */
+	u32 trsl_id;
+	u32 trsl_param;
+	u32 transparent;
+};
+
+/* BAR 0/1 MMIO access */
+static inline u32 mtk_pci_mac_read32(struct mtk_pci_priv *priv, u64 addr)
+{
+	return ioread32(priv->mac_reg_base + addr);
+}
+
+static inline void mtk_pci_mac_write32(struct mtk_pci_priv *priv, u64 addr, u32 val)
+{
+	iowrite32(val, priv->mac_reg_base + addr);
+}
+
+/* BAR 2/3 MMIO access */
+static inline u32 mtk_pci_read32(struct mtk_md_dev *mdev, u64 addr)
+{
+	return ioread32(((struct mtk_pci_priv *)mdev->hw_priv)->ext_reg_base + addr);
+}
+
+static inline void mtk_pci_write32(struct mtk_md_dev *mdev, u64 addr, u32 val)
+{
+	iowrite32(val, ((struct mtk_pci_priv *)mdev->hw_priv)->ext_reg_base + addr);
+}
+
+/* Device operations */
+u32 mtk_pci_get_dev_state(struct mtk_md_dev *mdev);
+void mtk_pci_ack_dev_state(struct mtk_md_dev *mdev, u32 state);
+u32 mtk_pci_get_dev_cfg(struct mtk_md_dev *mdev);
+/* IRQ Related operations */
+int mtk_pci_get_irq_id(struct mtk_md_dev *mdev, enum mtk_irq_src irq_src);
+int mtk_pci_get_virq_id(struct mtk_md_dev *mdev, int irq_id);
+int mtk_pci_register_irq(struct mtk_md_dev *mdev, int irq_id,
+			 int (*irq_cb)(int irq_id, void *data), void *data);
+int mtk_pci_unregister_irq(struct mtk_md_dev *mdev, int irq_id);
+int mtk_pci_mask_irq(struct mtk_md_dev *mdev, int irq_id);
+int mtk_pci_unmask_irq(struct mtk_md_dev *mdev, int irq_id);
+int mtk_pci_clear_irq(struct mtk_md_dev *mdev, int irq_id);
+/* External event related */
+int mtk_pci_register_ext_evt(struct mtk_md_dev *mdev, u32 chs,
+			     int (*evt_cb)(u32 status, void *data), void *data);
+void mtk_pci_unregister_ext_evt(struct mtk_md_dev *mdev, u32 chs);
+void mtk_pci_mask_ext_evt(struct mtk_md_dev *mdev, u32 chs);
+void mtk_pci_unmask_ext_evt(struct mtk_md_dev *mdev, u32 chs);
+void mtk_pci_clear_ext_evt(struct mtk_md_dev *mdev, u32 chs);
+int mtk_pci_send_ext_evt(struct mtk_md_dev *mdev, u32 ch);
+int mtk_pci_pldr(struct mtk_md_dev *mdev);
+bool mtk_pci_link_check(struct mtk_md_dev *mdev);
+int mtk_pci_setup_atr(struct mtk_md_dev *mdev, struct mtk_atr_cfg *cfg);
+void mtk_pci_atr_disable(struct mtk_pci_priv *priv);
+
+#endif /* __MTK_PCI_H__ */
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_pci_drv_m9xx.c b/drivers/net/wwan/t9xx/pcie/mtk_pci_drv_m9xx.c
new file mode 100644
index 000000000000..acdd914428ad
--- /dev/null
+++ b/drivers/net/wwan/t9xx/pcie/mtk_pci_drv_m9xx.c
@@ -0,0 +1,65 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+#include <linux/types.h>
+#include "mtk_pci.h"
+#include "mtk_pci_reg.h"
+
+static int mtk_pci_atr_init_m9xx(struct mtk_md_dev *mdev)
+{
+	struct pci_dev *pdev = to_pci_dev(mdev->dev);
+	struct mtk_pci_priv *priv = mdev->hw_priv;
+	struct mtk_atr_cfg cfg;
+	int port, ret;
+
+	mtk_pci_atr_disable(priv);
+
+	/* Config ATR for RC to access device's register */
+	cfg.src_addr = pci_resource_start(pdev, MTK_BAR_2_3_IDX);
+	cfg.size = ATR_PCIE_REG_SIZE;
+	cfg.trsl_addr = ATR_PCIE_REG_TRSL_ADDR;
+	cfg.port = ATR_PCIE_REG_PORT;
+	cfg.table = ATR_PCIE_REG_TABLE_NUM;
+	cfg.trsl_id = ATR_PCIE_REG_TRSL_PORT;
+	cfg.trsl_param = 0x0;
+	cfg.transparent = 0x0;
+	ret = mtk_pci_setup_atr(mdev, &cfg);
+	if (ret)
+		return ret;
+
+	/* Config ATR for EP to access RC's memory */
+	for (port = ATR_SRC_AXIS_0; port <= ATR_SRC_AXIS_3; port++) {
+		cfg.src_addr = ATR_PCIE_DEV_DMA_SRC_ADDR;
+		cfg.size = ATR_PCIE_DEV_DMA_SIZE;
+		cfg.trsl_addr = ATR_PCIE_DEV_DMA_TRSL_ADDR;
+		cfg.port = port;
+		cfg.table = ATR_PCIE_DEV_DMA_TABLE_NUM;
+		cfg.trsl_id = ATR_DST_PCI_TRX;
+		cfg.trsl_param = 0x0;
+		/* Enable transparent translation */
+		cfg.transparent = ATR_PCIE_DEV_DMA_TRANSPARENT;
+		ret = mtk_pci_setup_atr(mdev, &cfg);
+		if (ret)
+			return ret;
+	}
+
+	return 0;
+}
+
+const struct mtk_pci_dev_cfg mtk_dev_cfg_0900 = {
+	.mhccif_rc_base_addr = 0x1000A000,
+	.irq_tbl = {
+		[MTK_IRQ_SRC_DPMAIF]  = 24,
+		[MTK_IRQ_SRC_CLDMA0]  = 27,
+		[MTK_IRQ_SRC_CLDMA1]  = 26,
+		[MTK_IRQ_SRC_CLDMA2]  = 25,
+		[MTK_IRQ_SRC_MHCCIF]  = 28,
+		[MTK_IRQ_SRC_DPMAIF2] = 29,
+		[MTK_IRQ_SRC_CLDMA3]  = 31,
+		[MTK_IRQ_SRC_PM_LOCK] = 0,
+		[MTK_IRQ_SRC_DPMAIF3] = 7,
+		[MTK_IRQ_SRC_DPMAIF6]  = 10,
+	},
+	.atr_init = mtk_pci_atr_init_m9xx,
+};
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_pci_reg.h b/drivers/net/wwan/t9xx/pcie/mtk_pci_reg.h
new file mode 100644
index 000000000000..0fcbdb33deaf
--- /dev/null
+++ b/drivers/net/wwan/t9xx/pcie/mtk_pci_reg.h
@@ -0,0 +1,68 @@
+/* SPDX-License-Identifier: GPL-2.0-only
+ *
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#ifndef __MTK_PCI_REG_H__
+#define __MTK_PCI_REG_H__
+
+#define REG_PCIE_MISC_CTRL			0x0348
+#define REG_ATR_PCIE_WIN0_T0_SRC_ADDR_LSB	0x0600
+#define REG_ATR_PCIE_WIN0_T0_SRC_ADDR_MSB	0x0604
+#define REG_ATR_PCIE_WIN0_T0_TRSL_ADDR_LSB	0x0608
+#define REG_ATR_PCIE_WIN0_T0_TRSL_ADDR_MSB	0x060C
+#define REG_ATR_PCIE_WIN0_T0_TRSL_PARAM		0x0610
+#define REG_PCIE_DEBUG_DUMMY_3			0x0D0C
+#define REG_PCIE_DEBUG_DUMMY_4			0x0D10
+#define REG_PCIE_DEBUG_DUMMY_7			0x0D1C
+#define REG_MSIX_ISTATUS_HOST_GRP0_0		0x0F00
+#define REG_IMASK_HOST_MSIX_SET_GRP0_0		0x3000
+#define REG_IMASK_HOST_MSIX_CLR_GRP0_0		0x3080
+#define REG_IMASK_HOST_MSIX_GRP0_0		0x3100
+
+/* mhccif registers */
+#define MHCCIF_RC2EP_SW_BSY			0x4
+#define MHCCIF_RC2EP_SW_TCHNUM			0xC
+#define MHCCIF_RC2EP_EVT_RESERVED_FOR_CLDMA0	BIT(4)
+#define MHCCIF_RC2EP_EVT_RESERVED_FOR_CLDMA1	BIT(5)
+#define MHCCIF_RC2EP_EVT_RESERVED_FOR_CLDMA3	BIT(6)
+#define MHCCIF_RC2EP_EVT_RESERVED_FOR_CLDMA2	BIT(7)
+#define MHCCIF_RC2EP_EVT_RESERVED_FOR_DPMAIF	BIT(8)
+#define MHCCIF_RC2EP_EVT_PCIE_PM_SUSPEND_REQ	BIT(9)
+#define MHCCIF_RC2EP_EVT_PCIE_PM_RESUME_REQ	BIT(10)
+#define MHCCIF_RC2EP_EVT_PCIE_PM_SUSPEND_REQ_AP	BIT(11)
+#define MHCCIF_RC2EP_EVT_PCIE_PM_RESUME_REQ_AP	BIT(12)
+#define MHCCIF_RC2EP_EVT_DEVICE_RESET		BIT(13)
+#define MHCCIF_RC2EP_EVT_RESERVED_FOR_TEST	BIT(31)
+
+#define MHCCIF_EP2RC_SW_INT_STS			0x10
+#define MHCCIF_EP2RC_SW_INT_ACK			0x14
+#define MHCCIF_EP2RC_SW_INT_EAP_MASK		0x20
+#define MHCCIF_EP2RC_SW_INT_EAP_MASK_SET	0x30
+#define MHCCIF_EP2RC_SW_INT_EAP_MASK_CLR	0x40
+#define MHCCIF_EP2RC_SPARE_REG_1		0x0104
+#define MHCCIF_EP2RC_SPARE_REG_5		0x0114
+#define MHCCIF_EP2RC_SPARE_REG_13		0x0134
+#define MHCCIF_EP2RC_SPARE_REG_14		0x0138
+#define MHCCIF_EP2RC_EVT_BOOT_FLOW_SYNC		BIT(5)
+#define MHCCIF_EP2RC_EVT_RESERVED_FOR_CLDMA0	BIT(6)
+#define MHCCIF_EP2RC_EVT_RESERVED_FOR_CLDMA1	BIT(7)
+#define MHCCIF_EP2RC_EVT_RESERVED_FOR_CLDMA3	BIT(8)
+#define MHCCIF_EP2RC_EVT_RESERVED_FOR_CLDMA2	BIT(9)
+#define MHCCIF_EP2RC_EVT_RESERVED_FOR_DPMAIF	BIT(10)
+#define MHCCIF_EP2RC_EVT_PCIE_PM_SUSPEND_ACK	BIT(11)
+#define MHCCIF_EP2RC_EVT_PCIE_PM_RESUME_ACK	BIT(12)
+#define MHCCIF_EP2RC_EVT_PCIE_PM_SUSPEND_ACK_AP	BIT(13)
+#define MHCCIF_EP2RC_EVT_PCIE_PM_RESUME_ACK_AP	BIT(14)
+#define MHCCIF_EP2RC_EVT_ASYNC_HS_NOTIFY_SAP	BIT(15)
+#define MHCCIF_EP2RC_EVT_ASYNC_HS_NOTIFY_MD	BIT(16)
+#define MHCCIF_EP2RC_EVT_SOFT_OFF_NOTIFY	BIT(17)
+#define MHCCIF_EP2RC_EVT_MD_REBOOT		BIT(19)
+#define MHCCIF_EP2RC_EVT_MD_POWEROFF		BIT(20)
+#define MHCCIF_EP2RC_EVT_GNSS_ENABLE		BIT(21)
+#define MHCCIF_EP2RC_EVT_GNSS_DISABLE		BIT(22)
+#define MHCCIF_EP2RC_EVT_FRC_DONE_NOTIFY	BIT(24)
+#define MHCCIF_EP2RC_EVT_RESERVED_FOR_TEST1	BIT(30)
+#define MHCCIF_EP2RC_EVT_RESERVED_FOR_TEST2	BIT(31)
+
+#endif /* __MTK_PCI_REG_H__ */

-- 
2.34.1

