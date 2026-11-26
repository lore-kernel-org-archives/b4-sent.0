From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 26 Nov 2026 19:51:28 +0000
Subject: [PATCH v5 2/4] iommu/rockchip: Add rockchip_iommu_restore()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-iep2-v5-2-3deac0976f10@gmail.com>
References: <20261126-iep2-v5-0-3deac0976f10@gmail.com>
In-Reply-To: <20261126-iep2-v5-0-3deac0976f10@gmail.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-rockchip@lists.infradead.org, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, iommu@lists.linux.dev, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Alex Bee <knaerzche@gmail.com>, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795722687; l=2709;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=R0H+lHztEJpQyhHftKqrGxobTadThHr2EDqVCQv3DQg=;
 b=amwYeQOaVvCSbjB2xfboms8H0EAgda42FrMdyTTwQLEIRgpuSprKYHp8gj5qjLI4RJXqWxTfl
 Y3eod4qxFJrDKZBWFMHHPgN3ajF2/p79dfdrZC2AA4r5u1FI2/t81iA
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some masters reset their IOMMU along with themselves. The RK3588 IEP2
does: after its soft reset, paging is off and its DMA is untranslated.

Add a helper to reprogram the IOMMU of such a master, so that its
driver need not attach and detach an empty domain to do it. rkvdec
does the same with rkvdec_iommu_restore().

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/iommu/rockchip-iommu.c        | 36 +++++++++++++++++++++++++++++++++++
 include/soc/rockchip/rockchip_iommu.h | 17 +++++++++++++++++
 2 files changed, 53 insertions(+)

diff --git a/drivers/iommu/rockchip-iommu.c b/drivers/iommu/rockchip-iommu.c
index 21af2f621c76..81cad102929e 100644
--- a/drivers/iommu/rockchip-iommu.c
+++ b/drivers/iommu/rockchip-iommu.c
@@ -27,6 +27,8 @@
 #include <linux/spinlock.h>
 #include <linux/string_choices.h>
 
+#include <soc/rockchip/rockchip_iommu.h>
+
 #include "iommu-pages.h"
 
 /** MMU register offsets */
@@ -1349,6 +1351,40 @@ static int __maybe_unused rk_iommu_resume(struct device *dev)
 	return rk_iommu_enable(iommu);
 }
 
+/**
+ * rockchip_iommu_restore() - Reprogram the IOMMU of a master after its reset
+ * @dev: master device, runtime active, with no DMA in flight
+ *
+ * Some masters reset their IOMMU with themselves, which turns paging off.
+ *
+ * Context: may sleep.
+ *
+ * Return: 0 on success or a negative error code.
+ */
+int rockchip_iommu_restore(struct device *dev)
+{
+	struct rk_iommu *iommu;
+	int ret;
+
+	if (!device_iommu_mapped(dev) ||
+	    dev->iommu->iommu_dev->ops != &rk_iommu_ops)
+		return 0;
+
+	iommu = rk_iommu_from_dev(dev);
+	if (!iommu || iommu->domain == &rk_identity_domain)
+		return 0;
+
+	ret = pm_runtime_get_if_in_use(iommu->dev);
+	if (ret <= 0)
+		return ret;
+
+	ret = rk_iommu_enable(iommu);
+	pm_runtime_put(iommu->dev);
+
+	return ret;
+}
+EXPORT_SYMBOL_GPL(rockchip_iommu_restore);
+
 static const struct dev_pm_ops rk_iommu_pm_ops = {
 	SET_RUNTIME_PM_OPS(rk_iommu_suspend, rk_iommu_resume, NULL)
 	SET_SYSTEM_SLEEP_PM_OPS(pm_runtime_force_suspend,
diff --git a/include/soc/rockchip/rockchip_iommu.h b/include/soc/rockchip/rockchip_iommu.h
new file mode 100644
index 000000000000..79fdd898a0fc
--- /dev/null
+++ b/include/soc/rockchip/rockchip_iommu.h
@@ -0,0 +1,17 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+
+#ifndef __SOC_ROCKCHIP_IOMMU_H__
+#define __SOC_ROCKCHIP_IOMMU_H__
+
+struct device;
+
+#ifdef CONFIG_ROCKCHIP_IOMMU
+int rockchip_iommu_restore(struct device *dev);
+#else
+static inline int rockchip_iommu_restore(struct device *dev)
+{
+	return 0;
+}
+#endif
+
+#endif /* __SOC_ROCKCHIP_IOMMU_H__ */

-- 
2.55.0

