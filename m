From: Jack Wu <jackbb_wu@compal.com>
Date: Wed, 25 Nov 2026 14:27:15 +0800
Subject: [PATCH net-next v13 2/6] net: wwan: t9xx: Add control plane
 transaction layer framework
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-t9xx_driver_v1-v13-2-92d9be5fb51e@compal.com>
References: <20261125-t9xx_driver_v1-v13-0-92d9be5fb51e@compal.com>
In-Reply-To: <20261125-t9xx_driver_v1-v13-0-92d9be5fb51e@compal.com>
To: Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Sergey Ryazanov <ryazanov.s.a@gmail.com>, 
 Johannes Berg <johannes@sipsolutions.net>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Jack Wu <jackbb_wu@compal.com>, 
 Wen-Zhi Huang <wen-zhi.huang@mediatek.com>, 
 Shi-Wei Yeh <shi-wei.yeh@mediatek.com>, 
 Minano Tseng <Minano.tseng@mediatek.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, Robert Yu <robert_yu@compal.com>, 
 Jeff Chang <Jeff_Chang@compal.com>, Eric Dumazet <edumazet@kernel.org>, 
 Eric Dumazet <edumazet@kernel.org>
Cc: linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-doc@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795588037; l=4358;
 i=jackbb_wu@compal.com; s=20260526; h=from:subject:message-id;
 bh=zSDBqT4BY6TNZmOsjeeRLHg7Yj+X8Pi/vmZtc8ZE+0E=;
 b=DcAWWsz0XFyJu6JgGBTXZFTnyI1gkyWKf3vGJJxS9+XOIB5Tt7DAO18zLrZzbIJuEz2YssdVb
 iQOj+N69tzrDFOHdbFwauqsvB29vx5ODTLa6K00FWVodZMH1hnl5yBe
X-Developer-Key: i=jackbb_wu@compal.com; a=ed25519;
 pk=VH1prTWixNl8OEUPPSfII3p46MzJpQN8J3+ecE1tZXg=
X-Endpoint-Received: by B4 Relay for jackbb_wu@compal.com/20260526 with auth_id=793
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce the control plane and transaction layer framework
for the T9XX WWAN driver. This patch adds the core data
structures (mtk_ctrl_blk, mtk_ctrl_trans) and initialization
entry points that subsequent patches build upon.

The control plane block (ctrl_blk) starts out with only the
device back-pointer and an opaque pointer to the transport
context; later patches add the port layer and FSM hooks to
it. The actual DMA engine and TX/RX service
implementations are added in subsequent patches, and
mtk_ctrl_init() and mtk_ctrl_exit() get their first callers
there, in pcie/mtk_trans_ctrl.c.

Signed-off-by: Jack Wu <jackbb_wu@compal.com>
---
 drivers/net/wwan/t9xx/Makefile              |  1 +
 drivers/net/wwan/t9xx/mtk_ctrl_plane.c      | 45 +++++++++++++++++++++++++++++
 drivers/net/wwan/t9xx/mtk_ctrl_plane.h      | 19 ++++++++++++
 drivers/net/wwan/t9xx/mtk_dev.h             |  3 ++
 drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h | 15 ++++++++++
 5 files changed, 83 insertions(+)

diff --git a/drivers/net/wwan/t9xx/Makefile b/drivers/net/wwan/t9xx/Makefile
index 0eb5fb1be0e2..65b3c1f70c36 100644
--- a/drivers/net/wwan/t9xx/Makefile
+++ b/drivers/net/wwan/t9xx/Makefile
@@ -3,4 +3,5 @@
 obj-$(CONFIG_MTK_T9XX) += mtk_t9xx.o
 
 mtk_t9xx-y := \
+	mtk_ctrl_plane.o \
 	pcie/mtk_pci.o
diff --git a/drivers/net/wwan/t9xx/mtk_ctrl_plane.c b/drivers/net/wwan/t9xx/mtk_ctrl_plane.c
new file mode 100644
index 000000000000..b755b6f03a72
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_ctrl_plane.c
@@ -0,0 +1,45 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2022, MediaTek Inc.
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
+ * associated with @mdev.  Runs once per bind; the allocation is
+ * devres managed and is released at unbind, not by
+ * mtk_ctrl_exit().
+ *
+ * Return: 0 on success, -ENOMEM on allocation failure.
+ */
+int mtk_ctrl_init(struct mtk_md_dev *mdev)
+{
+	struct mtk_ctrl_blk *ctrl_blk;
+
+	ctrl_blk = devm_kzalloc_obj(mdev->dev, *ctrl_blk);
+	if (!ctrl_blk)
+		return -ENOMEM;
+
+	ctrl_blk->mdev = mdev;
+	mdev->ctrl_blk = ctrl_blk;
+
+	return 0;
+}
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
diff --git a/drivers/net/wwan/t9xx/mtk_ctrl_plane.h b/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
new file mode 100644
index 000000000000..16b60eeb0aaf
--- /dev/null
+++ b/drivers/net/wwan/t9xx/mtk_ctrl_plane.h
@@ -0,0 +1,19 @@
+/* SPDX-License-Identifier: GPL-2.0-only
+ *
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#ifndef __MTK_CTRL_PLANE_H__
+#define __MTK_CTRL_PLANE_H__
+
+#include "mtk_dev.h"
+
+struct mtk_ctrl_blk {
+	struct mtk_md_dev *mdev;
+	void *ctrl_hw_priv;
+};
+
+int mtk_ctrl_init(struct mtk_md_dev *mdev);
+void mtk_ctrl_exit(struct mtk_md_dev *mdev);
+
+#endif /* __MTK_CTRL_PLANE_H__ */
diff --git a/drivers/net/wwan/t9xx/mtk_dev.h b/drivers/net/wwan/t9xx/mtk_dev.h
index d969a04d4413..fe2cd8c95719 100644
--- a/drivers/net/wwan/t9xx/mtk_dev.h
+++ b/drivers/net/wwan/t9xx/mtk_dev.h
@@ -26,11 +26,14 @@ enum mtk_dev_evt_d2h {
 	DEV_EVT_D2H_ASYNC_HS_NOTIFY_MD	= BIT(6),
 };
 
+struct mtk_ctrl_blk;
+
 /* mtk_md_dev defines the structure of MTK modem device */
 struct mtk_md_dev {
 	struct device *dev;
 	void *hw_priv;
 	u32 hw_ver;
+	struct mtk_ctrl_blk *ctrl_blk;
 };
 
 #endif /* __MTK_DEV_H__ */
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h b/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h
new file mode 100644
index 000000000000..1827cb1d4959
--- /dev/null
+++ b/drivers/net/wwan/t9xx/pcie/mtk_trans_ctrl.h
@@ -0,0 +1,15 @@
+/* SPDX-License-Identifier: GPL-2.0-only
+ *
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#ifndef __MTK_TRANS_CTRL_H__
+#define __MTK_TRANS_CTRL_H__
+
+#include "../mtk_dev.h"
+
+struct mtk_ctrl_trans {
+	struct mtk_md_dev *mdev;
+};
+
+#endif

-- 
2.34.1

