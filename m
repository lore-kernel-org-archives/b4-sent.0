From: Jack Wu <jackbb_wu@compal.com>
Date: Fri, 29 May 2026 18:31:46 +0800
Subject: [PATCH 07/11] net: wwan: t9xx: Introduce data plane hardware
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260529-t9xx_driver_v1-v1-7-bdbfe2c01e57@compal.com>
References: <20260529-t9xx_driver_v1-v1-0-bdbfe2c01e57@compal.com>
In-Reply-To: <20260529-t9xx_driver_v1-v1-0-bdbfe2c01e57@compal.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780050704; l=113171;
 i=jackbb_wu@compal.com; s=20260526; h=from:subject:message-id;
 bh=GqGD1OU3ChS39G006EUGhniQYtw/vcHc+n6QkbmLkDc=;
 b=RVjuesjyyRzPGAsKpX3CCts2PdydmBPvr8a7FroEEDTb46A+4UVgrz85khg81pjBPpgV4i4jn
 6xWG9IzQeoIBvTRfRTYD6Lrjd5zWedE7WznwbkqM8RLqEDst8I2/fv/
X-Developer-Key: i=jackbb_wu@compal.com; a=ed25519;
 pk=VH1prTWixNl8OEUPPSfII3p46MzJpQN8J3+ecE1tZXg=
X-Endpoint-Received: by B4 Relay for jackbb_wu@compal.com/20260526 with auth_id=793
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Data Plane Modem AP Interface (DPMAIF) hardware layer
provides hardware abstraction for the upper layer
(DPMAIF HIF). It implements functions to do the data plane
hardware's configuration, TX/RX control and interrupt
handling.

Signed-off-by: Jack Wu <jackbb_wu@compal.com>
---
 drivers/net/wwan/t9xx/pcie/Makefile              |    5 +-
 drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv.c      | 1586 ++++++++++++++++++++++
 drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv.h      |  259 ++++
 drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv_m9xx.c |  687 ++++++++++
 drivers/net/wwan/t9xx/pcie/mtk_dpmaif_reg.h      |  387 ++++++
 drivers/net/wwan/t9xx/pcie/mtk_dpmaif_reg_m9xx.h |   37 +
 drivers/net/wwan/t9xx/pcie/mtk_dpmaif_ring.c     |  168 +++
 drivers/net/wwan/t9xx/pcie/mtk_dpmaif_ring.h     |  161 +++
 drivers/net/wwan/t9xx/pcie/mtk_pci.h             |    1 +
 drivers/net/wwan/t9xx/pcie/mtk_pci_drv_m9xx.c    |    1 +
 10 files changed, 3291 insertions(+), 1 deletion(-)

diff --git a/drivers/net/wwan/t9xx/pcie/Makefile b/drivers/net/wwan/t9xx/pcie/Makefile
index 5252f158b058..78a765f8e79a 100644
--- a/drivers/net/wwan/t9xx/pcie/Makefile
+++ b/drivers/net/wwan/t9xx/pcie/Makefile
@@ -7,9 +7,12 @@ obj-$(CONFIG_MTK_T9XX_PCI) += mtk_t9xx_pcie.o
 
 mtk_t9xx_pcie-y := \
 	mtk_pci_drv_m9xx.o \
+	mtk_dpmaif_drv_m9xx.o \
 	mtk_cldma_drv_m9xx.o \
 	mtk_ctrl_cfg_m9xx.o \
 	mtk_pci.o \
 	mtk_trans_ctrl.o \
 	mtk_cldma.o \
-	mtk_cldma_drv.o
+	mtk_dpmaif_drv.o \
+	mtk_cldma_drv.o \
+	mtk_dpmaif_ring.o
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv.c b/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv.c
new file mode 100644
index 000000000000..3fd2b33d1199
--- /dev/null
+++ b/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv.c
@@ -0,0 +1,1586 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#define pr_fmt(fmt) "DATA_DRV:" fmt
+
+#include <linux/delay.h>
+
+#include "mtk_dev.h"
+#include "mtk_dpmaif_drv.h"
+#include "mtk_dpmaif_reg.h"
+#include "mtk_pci.h"
+#include "mtk_pci_reg.h"
+
+static int mtk_dpmaif_drv_dl_add_bat_cnt(struct dpmaif_drv_info *drv_info,
+					 u8 bat_id, u32 bat_entry_cnt);
+
+u32 mtk_dpmaif_drv_get_ul_intr_mask(struct dpmaif_drv_info *drv_info)
+{
+	if (drv_info->priv_ops && drv_info->priv_ops->get_ul_intr_mask)
+		return drv_info->priv_ops->get_ul_intr_mask(drv_info);
+
+	return mtk_pci_read32(drv_info->mdev, drv_info->regs->ao_base + DPMAIF_PD_AP_UL_L2TIMR0);
+}
+
+u32 mtk_dpmaif_drv_get_dl_intr_mask(struct dpmaif_drv_info *drv_info, u8 q_id)
+{
+	if (q_id != DPMAIF_DLQ2)
+		return mtk_pci_read32(drv_info->mdev, drv_info->regs->ao_base +
+				DPMAIF_PD_AP_DL_L2TIMR0);
+	else
+		return mtk_pci_read32(drv_info->mdev, drv_info->regs->pd_base +
+				NRL2_DPMAIF_MISC_PD_APDL12_MASK_RW);
+}
+
+static int mtk_dpmaif_drv_init_mode(struct dpmaif_drv_info *drv_info)
+{
+	u32 val, cnt = 0;
+	int ret;
+
+	/* Initialize dpmaif sram. */
+	val = mtk_pci_read32(drv_info->mdev, drv_info->regs->pd_base + NRL2_DPMAIF_AP_MISC_MEM_CLR);
+	val |= DPMAIF_MEM_CLR_MASK;
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + NRL2_DPMAIF_AP_MISC_MEM_CLR, val);
+
+	do {
+		if (!(mtk_pci_read32(drv_info->mdev,
+				     drv_info->regs->pd_base + NRL2_DPMAIF_AP_MISC_MEM_CLR) &
+				     DPMAIF_MEM_CLR_MASK))
+			break;
+
+		udelay(POLL_INTERVAL_US);
+	} while (++cnt < POLL_MAX_TIMES);
+
+	if (cnt >= POLL_MAX_TIMES) {
+		dev_err((drv_info->mdev)->dev, "Failed to initialize sram\n");
+		return -DATA_HW_REG_TIMEOUT;
+	}
+
+	if (drv_info->priv_ops && drv_info->priv_ops->dynamic_sram_init) {
+		ret = drv_info->priv_ops->dynamic_sram_init(drv_info);
+		if (unlikely(ret < 0))
+			return ret;
+	}
+
+	/* Set DPMAIF AP port mode. */
+	val = mtk_pci_read32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_AO_DL_RDY_CHK_THRES);
+	val &= ~DPMAIF_PORT_MODE_MSK;
+	val |= DPMAIF_PORT_MODE_PCIE;
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_AO_DL_RDY_CHK_THRES, val);
+
+	/* Set CG enable. */
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + NRL2_DPMAIF_AP_MISC_CG_EN, 0x7F);
+
+	/* Config SW PCIe mode. */
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + NRL2_DPMAIF_UL_RESERVE_AO_RW,
+			DPMAIF_PCIE_MODE_SET_VALUE);
+	if (drv_info->priv_ops && drv_info->priv_ops->set_pcie_domain)
+		drv_info->priv_ops->set_pcie_domain(drv_info);
+
+	return 0;
+}
+
+int mtk_dpmaif_drv_ul_intr_init(struct dpmaif_drv_info *drv_info)
+{
+	const struct dpmaif_intr_cfg *intr_cfg = &drv_info->cfg->intr_cfg;
+	u32 cnt = 0;
+
+	/* clear UL interrupt */
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_PD_AP_UL_L2TISAR0,
+			0xFFFFFFFF);
+	/* unmask ul_l2intrs_enable interrupt */
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->ao_base + DPMAIF_PD_AP_UL_L2TICR0,
+			intr_cfg->ul_l2intrs_enable);
+	/* mask ul_l2intrs_disable interrupt */
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->ao_base + DPMAIF_PD_AP_UL_L2TISR0,
+			intr_cfg->ul_l2intrs_disable);
+	mtk_pci_read32(drv_info->mdev, drv_info->regs->ao_base + DPMAIF_PD_AP_UL_L2TISR0);
+	do {
+		if (((mtk_pci_read32(drv_info->mdev,
+				     drv_info->regs->ao_base + DPMAIF_PD_AP_UL_L2TIMR0) &
+					  intr_cfg->ul_l2intrs_disable) ==
+					  intr_cfg->ul_l2intrs_disable))
+			break;
+
+		udelay(POLL_INTERVAL_US);
+	} while (++cnt < POLL_MAX_TIMES);
+
+	if (cnt >= POLL_MAX_TIMES) {
+		dev_err((drv_info->mdev)->dev,
+			"Failed to set UL interrupt mask, mask=0x%08x\n",
+			mtk_pci_read32(drv_info->mdev,
+				       drv_info->regs->ao_base + DPMAIF_PD_AP_UL_L2TIMR0));
+		return -DATA_HW_REG_TIMEOUT;
+	}
+
+	return 0;
+}
+
+static int mtk_dpmaif_drv_init_intr(struct dpmaif_drv_info *drv_info)
+{
+	const struct dpmaif_intr_cfg *intr_cfg = &drv_info->cfg->intr_cfg;
+	u32 cnt = 0, cfg;
+	int ret;
+
+	if (drv_info->priv_ops && drv_info->priv_ops->ul_intr_init)
+		ret = drv_info->priv_ops->ul_intr_init(drv_info);
+	else
+		ret = mtk_dpmaif_drv_ul_intr_init(drv_info);
+
+	if (unlikely(ret < 0))
+		return ret;
+
+	/* clear DLQ0/1 interrupt */
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_PD_AP_DL_L2TISAR0,
+			0xFFFFFFFF);
+	/* unmask dl_l2intrs_enable interrupt */
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->ao_base + DPMAIF_PD_AP_DL_L2TICR0,
+			intr_cfg->dl_l2intrs_enable);
+	/* mask dl_l2intrs_disable interrupt */
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->ao_base + DPMAIF_PD_AP_DL_L2TISR0,
+			intr_cfg->dl_l2intrs_disable);
+	mtk_pci_read32(drv_info->mdev, drv_info->regs->ao_base + DPMAIF_PD_AP_DL_L2TISR0);
+
+	do {
+		if (((mtk_pci_read32(drv_info->mdev,
+				     drv_info->regs->ao_base + DPMAIF_PD_AP_DL_L2TIMR0) &
+				      intr_cfg->dl_l2intrs_disable) ==
+				      intr_cfg->dl_l2intrs_disable))
+			break;
+
+		udelay(POLL_INTERVAL_US);
+	} while (++cnt < POLL_MAX_TIMES);
+
+	if (cnt >= POLL_MAX_TIMES) {
+		dev_err((drv_info->mdev)->dev,
+			"Failed to set DL interrupt mask, mask=0x%08x\n",
+			mtk_pci_read32(drv_info->mdev,
+				       drv_info->regs->ao_base + DPMAIF_PD_AP_DL_L2TIMR0));
+		return -DATA_HW_REG_TIMEOUT;
+	}
+
+	if (drv_info->cfg->rx_cfg.rxq_cnt >= DPMAIF_DLQ2 + 1) {
+		/* clear DLQ2 interrupt */
+		mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base +
+			NRL2_DPMAIF_AP_MISC_APDL_L2TISAR1, 0xFFFFFFFF);
+		/* unmask dl2_l2intrs_enable interrupt */
+		mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base +
+				NRL2_DPMAIF_MISC_PD_APDL12_MASK_CLR,
+				intr_cfg->dl2_l2intrs_enable);
+		/* mask dl2_l2intrs_disable interrupt */
+		mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base +
+			NRL2_DPMAIF_MISC_PD_APDL12_MASK_SET, intr_cfg->dl2_l2intrs_disable);
+		mtk_pci_read32(drv_info->mdev, drv_info->regs->pd_base +
+			NRL2_DPMAIF_MISC_PD_APDL12_MASK_SET);
+		cnt = 0;
+		do {
+			if (((mtk_pci_read32(drv_info->mdev, drv_info->regs->pd_base +
+					NRL2_DPMAIF_MISC_PD_APDL12_MASK_RW) &
+					intr_cfg->dl2_l2intrs_disable) ==
+					intr_cfg->dl2_l2intrs_disable))
+				break;
+
+			udelay(POLL_INTERVAL_US);
+		} while (++cnt < POLL_MAX_TIMES);
+
+		if (cnt >= POLL_MAX_TIMES) {
+			dev_err((drv_info->mdev)->dev,
+				"Failed to set DL2 interrupt mask, mask=0x%08x\n",
+				mtk_pci_read32(drv_info->mdev,
+					       drv_info->regs->pd_base +
+					       NRL2_DPMAIF_MISC_PD_APDL12_MASK_RW));
+			return -DATA_HW_REG_TIMEOUT;
+		}
+	}
+
+	/* init IP busy */
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_PD_AP_IP_BUSY, 0xFFFFFFFF);
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->ao_base + DPMAIF_PD_AP_DLUL_IP_BUSY_MASK,
+			intr_cfg->udl_ip_busy_disable);
+
+	/* init HPC */
+	cfg = mtk_pci_read32(drv_info->mdev,
+			     drv_info->regs->ao_base + NRL2_DPMAIF_AO_UL_AP_L1TIMR0);
+	cfg |= intr_cfg->hpc_disable;
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->ao_base + NRL2_DPMAIF_AO_UL_AP_L1TIMR0,
+			cfg);
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + NRL2_DPMAIF_HPC_INTR_MASK,
+			0xFFFF);
+
+	return 0;
+}
+
+static void mtk_dpmaif_drv_set_hpc_cntl(struct dpmaif_drv_info *drv_info)
+{
+	u32 cfg;
+
+	if (drv_info->priv_ops && drv_info->priv_ops->set_hpc_cntl) {
+		drv_info->priv_ops->set_hpc_cntl(drv_info);
+		return;
+	}
+
+	cfg = DPMAIF_HPC_LRO_PATH_DF & 0x3;
+	cfg |= (DPMAIF_HPC_ADD_MODE_DF & 0x3) << 2;
+	cfg |= (DPMAIF_HASH_PRIME_DF & 0xF) << 4;
+	cfg |= (DPMAIF_HPC_NUM_DF & 0xFF) << 8;
+
+	/* Configuration include hpc dlq path, hpc add mode, hash prime, hpc total number. */
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + NRL2_DPMAIF_AO_DL_HPC_CNTL, cfg);
+}
+
+static void mtk_dpmaif_drv_set_agg_cfg(struct dpmaif_drv_info *drv_info, bool enable)
+{
+	u32 cfg;
+
+	cfg = DPMAIF_AGG_MAX_LEN_DF & 0xFFFF;
+	cfg |= (DPMAIF_AGG_TBL_ENT_NUM_DF & 0xFFFF) << 16;
+
+	/* Configuration include agg max length, agg table number. */
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + NRL2_DPMAIF_AO_DL_LRO_AGG_CFG,
+			cfg);
+	cfg = mtk_pci_read32(drv_info->mdev,
+			     drv_info->regs->pd_base + NRL2_DPMAIF_AO_DL_RDY_CHK_FRG_THRES);
+	if (enable)
+		mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base +
+			NRL2_DPMAIF_AO_DL_RDY_CHK_FRG_THRES, cfg | (0xFF << 20));
+	else
+		mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base +
+			NRL2_DPMAIF_AO_DL_RDY_CHK_FRG_THRES, cfg & 0xF00FFFFF);
+}
+
+static int mtk_dpmaif_drv_init_features(struct dpmaif_drv_info *drv_info)
+{
+	if (drv_info->cfg->cap & DATA_HW_F_HPC)
+		mtk_dpmaif_drv_set_hpc_cntl(drv_info);
+
+	/* Explicitly disable LRO aggregation at init time. */
+	mtk_dpmaif_drv_set_agg_cfg(drv_info, false);
+
+	return 0;
+}
+
+static void mtk_dpmaif_drv_dl_set_ao_remain_minsz(struct dpmaif_drv_info *drv_info,
+						  u32 sz)
+{
+	u32 val;
+
+	val = mtk_pci_read32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_AO_DL_PKTINFO_CONO);
+	val &= ~DPMAIF_BAT_REMAIN_MINSZ_MSK;
+	val |= ((sz / DPMAIF_BAT_REMAIN_SZ_BASE) << 8) & DPMAIF_BAT_REMAIN_MINSZ_MSK;
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_AO_DL_PKTINFO_CONO, val);
+}
+
+static void mtk_dpmaif_drv_dl_set_ao_bat_bufsz(struct dpmaif_drv_info *drv_info,
+					       u32 buf_sz)
+{
+	u32 val;
+
+	val = mtk_pci_read32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_AO_DL_PKTINFO_CON2);
+	val &= ~DPMAIF_BAT_BUF_SZ_MSK;
+	val |= ((buf_sz / DPMAIF_BAT_BUFFER_SZ_BASE) << 8) & DPMAIF_BAT_BUF_SZ_MSK;
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_AO_DL_PKTINFO_CON2, val);
+}
+
+static void mtk_dpmaif_drv_dl_set_ao_bat_rsv_length(struct dpmaif_drv_info *drv_info,
+						    u32 length)
+{
+	u32 val;
+
+	val = mtk_pci_read32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_AO_DL_PKTINFO_CON2);
+	val &= ~DPMAIF_BAT_RSV_LEN_MSK;
+	val |= length & DPMAIF_BAT_RSV_LEN_MSK;
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_AO_DL_PKTINFO_CON2, val);
+}
+
+static void mtk_dpmaif_drv_dl_set_ao_bid_maxcnt(struct dpmaif_drv_info *drv_info, u32 cnt)
+{
+	u32 val;
+
+	val = mtk_pci_read32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_AO_DL_PKTINFO_CONO);
+	val &= ~DPMAIF_BAT_BID_MAXCNT_MSK;
+	val |= (cnt << 16) & DPMAIF_BAT_BID_MAXCNT_MSK;
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_AO_DL_PKTINFO_CONO, val);
+}
+
+static void mtk_dpmaif_drv_dl_set_pkt_alignment(struct dpmaif_drv_info *drv_info,
+						bool enable, u32 mode)
+{
+	u32 val;
+
+	val = mtk_pci_read32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_AO_DL_RDY_CHK_THRES);
+	val &= ~DPMAIF_PKT_ALIGN_MSK;
+	if (enable) {
+		val |= DPMAIF_PKT_ALIGN_EN;
+		val |= (mode << 22) & DPMAIF_PKT_ALIGN_MSK;
+	}
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_AO_DL_RDY_CHK_THRES, val);
+}
+
+static void mtk_dpmaif_drv_dl_set_pit_seqnum(struct dpmaif_drv_info *drv_info, u32 seq)
+{
+	u32 val;
+
+	val = mtk_pci_read32(drv_info->mdev,
+			     drv_info->regs->pd_base + NRL2_DPMAIF_AO_DL_PIT_SEQ_END);
+	val &= ~DPMAIF_DL_PIT_SEQ_MSK;
+	val |= seq & DPMAIF_DL_PIT_SEQ_MSK;
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + NRL2_DPMAIF_AO_DL_PIT_SEQ_END,
+			val);
+}
+
+static void mtk_dpmaif_drv_dl_set_ao_mtu(struct dpmaif_drv_info *drv_info, u32 mtu_sz)
+{
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_AO_DL_PKTINFO_CON1,
+			mtu_sz);
+}
+
+static void mtk_dpmaif_drv_dl_set_ao_pit_chknum(struct dpmaif_drv_info *drv_info,
+						u32 number)
+{
+	u32 val;
+
+	val = mtk_pci_read32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_AO_DL_PKTINFO_CON2);
+	val &= ~DPMAIF_PIT_CHK_NUM_MSK;
+	val |= (number << 24) & DPMAIF_PIT_CHK_NUM_MSK;
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_AO_DL_PKTINFO_CON2, val);
+}
+
+static void mtk_dpmaif_drv_dl_set_ao_bat_check_threshold(struct dpmaif_drv_info *drv_info,
+							 u32 size)
+{
+	u32 val;
+
+	val = mtk_pci_read32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_AO_DL_RDY_CHK_THRES);
+	val &= ~DPMAIF_BAT_CHECK_THRES_MSK;
+	val |= (size << 16) & DPMAIF_BAT_CHECK_THRES_MSK;
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_AO_DL_RDY_CHK_THRES, val);
+}
+
+static void mtk_dpmaif_drv_dl_set_bat_base_addr(struct dpmaif_drv_info *drv_info,
+						u64 addr, u8 bat_id)
+{
+	u32 lb_addr = (u32)(addr & 0xFFFFFFFF);
+	u32 hb_addr = (u32)(addr >> 32);
+	u64 addr1, addr2;
+
+	if (bat_id == DPMAIF_BAT0) {
+		addr1 = drv_info->regs->pd_base + DPMAIF_PD_DL_BAT_INIT_CON0;
+		addr2 = drv_info->regs->pd_base + DPMAIF_PD_DL_BAT_INIT_CON3;
+	} else {
+		addr1 = drv_info->regs->pd2_base + DPMAIF_DL_2_BAT_INIT_CON0;
+		addr2 = drv_info->regs->pd2_base + DPMAIF_DL_2_BAT_INIT_CON3;
+	}
+
+	mtk_pci_write32(drv_info->mdev, addr1, lb_addr);
+	mtk_pci_write32(drv_info->mdev, addr2, hb_addr);
+}
+
+static void mtk_dpmaif_drv_dl_set_bat_size(struct dpmaif_drv_info *drv_info, u32 size, u8 bat_id)
+{
+	u64 addr;
+	u32 val;
+
+	if (bat_id == DPMAIF_BAT0)
+		addr = drv_info->regs->pd_base + DPMAIF_PD_DL_BAT_INIT_CON1;
+	else
+		addr = drv_info->regs->pd2_base + DPMAIF_DL_2_BAT_INIT_CON1;
+
+	val = mtk_pci_read32(drv_info->mdev, addr);
+	val &= ~DPMAIF_BAT_SIZE_MSK;
+	val |= size & DPMAIF_BAT_SIZE_MSK;
+	mtk_pci_write32(drv_info->mdev, addr, val);
+}
+
+static void mtk_dpmaif_drv_dl_bat_en(struct dpmaif_drv_info *drv_info, bool enable, u8 bat_id)
+{
+	u64 addr;
+	u32 val;
+
+	if (bat_id == DPMAIF_BAT0)
+		addr = drv_info->regs->pd_base + DPMAIF_PD_DL_BAT_INIT_CON1;
+	else
+		addr = drv_info->regs->pd2_base + DPMAIF_DL_2_BAT_INIT_CON1;
+
+	val = mtk_pci_read32(drv_info->mdev, addr);
+	if (enable)
+		val |= DPMAIF_BAT_EN_MSK;
+	else
+		val &= ~DPMAIF_BAT_EN_MSK;
+
+	mtk_pci_write32(drv_info->mdev, addr, val);
+	mtk_pci_read32(drv_info->mdev, addr);
+}
+
+static int mtk_dpmaif_drv_dl_bat_init_done(struct dpmaif_drv_info *drv_info,
+					   u8 bat_id, u32 init_mode)
+{
+	u32 cnt = 0, dl_bat_init;
+	u64 addr;
+
+	dl_bat_init = init_mode;
+	dl_bat_init |= DPMAIF_DL_BAT_INIT_EN;
+
+	if (bat_id == DPMAIF_BAT0)
+		addr = drv_info->regs->pd_base + DPMAIF_PD_DL_BAT_INIT;
+	else
+		addr = drv_info->regs->pd2_base + DPMAIF_DL_2_BAT_INIT;
+
+	do {
+		if (!(mtk_pci_read32(drv_info->mdev, addr) & DPMAIF_DL_BAT_INIT_NOT_READY)) {
+			mtk_pci_write32(drv_info->mdev, addr, dl_bat_init);
+			break;
+		}
+
+		udelay(POLL_INTERVAL_US);
+	} while (++cnt < POLL_MAX_TIMES);
+
+	if (cnt >= POLL_MAX_TIMES) {
+		dev_err((drv_info->mdev)->dev,
+			"Failed to initialize bat,init_mode=%u\n", init_mode);
+		return -DATA_HW_REG_TIMEOUT;
+	}
+
+	cnt = 0;
+	do {
+		if (!((mtk_pci_read32(drv_info->mdev, addr) & DPMAIF_DL_BAT_INIT_NOT_READY)))
+			return 0;
+
+		udelay(POLL_INTERVAL_US);
+	} while (++cnt < POLL_MAX_TIMES);
+
+	dev_err((drv_info->mdev)->dev, "Failed to initialize bat done,init_mode=%u\n", init_mode);
+
+	return -DATA_HW_REG_TIMEOUT;
+}
+
+static void mtk_dpmaif_drv_dl_set_pit_base_addr(struct dpmaif_drv_info *drv_info, u64 addr, u8 q_id)
+{
+	u32 lb_addr = (u32)(addr & 0xFFFFFFFF);
+	u32 hb_addr = (u32)(addr >> 32);
+
+	if (q_id != DPMAIF_DLQ2) {
+		mtk_pci_write32(drv_info->mdev,
+				drv_info->regs->pd_base + NRL2_DPMAIF_DL_LROPIT_INIT_CON0,
+			lb_addr);
+		mtk_pci_write32(drv_info->mdev,
+				drv_info->regs->pd_base + NRL2_DPMAIF_DL_LROPIT_INIT_CON4,
+			hb_addr);
+	} else {
+		mtk_pci_write32(drv_info->mdev,
+				drv_info->regs->pd2_base + DPMAIF_DL_2_PIT_INIT_CON0,
+			lb_addr);
+		mtk_pci_write32(drv_info->mdev,
+				drv_info->regs->pd2_base + DPMAIF_DL_2_PIT_INIT_CON4,
+			hb_addr);
+	}
+}
+
+static void mtk_dpmaif_drv_dl_set_pit_size(struct dpmaif_drv_info *drv_info, u32 size, u8 q_id)
+{
+	u32 val;
+
+	if (q_id != DPMAIF_DLQ2) {
+		val = mtk_pci_read32(drv_info->mdev,
+				     drv_info->regs->pd_base +
+				     NRL2_DPMAIF_DL_LROPIT_INIT_CON1);
+		val &= ~DPMAIF_PIT_SIZE_MSK;
+		val |= size & DPMAIF_PIT_SIZE_MSK;
+		mtk_pci_write32(drv_info->mdev,
+				drv_info->regs->pd_base + NRL2_DPMAIF_DL_LROPIT_INIT_CON1,
+				val);
+		mtk_pci_write32(drv_info->mdev,
+				drv_info->regs->pd_base + NRL2_DPMAIF_DL_LROPIT_INIT_CON2,
+				0);
+		mtk_pci_write32(drv_info->mdev,
+				drv_info->regs->pd_base + NRL2_DPMAIF_DL_LROPIT_INIT_CON3,
+				0);
+		mtk_pci_write32(drv_info->mdev,
+				drv_info->regs->pd_base + NRL2_DPMAIF_DL_LROPIT_INIT_CON5,
+				0);
+		mtk_pci_write32(drv_info->mdev,
+				drv_info->regs->pd_base + NRL2_DPMAIF_DL_LROPIT_INIT_CON6,
+				0);
+	} else {
+		val = mtk_pci_read32(drv_info->mdev,
+				     drv_info->regs->pd2_base + DPMAIF_DL_2_PIT_INIT_CON1);
+		val &= ~DPMAIF_PIT_SIZE_MSK;
+		val |= size & DPMAIF_PIT_SIZE_MSK;
+		mtk_pci_write32(drv_info->mdev,
+				drv_info->regs->pd2_base + DPMAIF_DL_2_PIT_INIT_CON1,
+				val);
+	}
+}
+
+static void mtk_dpmaif_drv_dl_pit_en(struct dpmaif_drv_info *drv_info, bool enable, u8 q_id)
+{
+	u32 val, addr, mask;
+
+	if (q_id != DPMAIF_DLQ2) {
+		addr = drv_info->regs->pd_base + NRL2_DPMAIF_DL_LROPIT_INIT_CON3;
+		mask = DPMAIF_LROPIT_EN_MSK;
+	} else {
+		addr = drv_info->regs->pd2_base + DPMAIF_DL_2_PIT_INIT_CON3;
+		mask = DPMAIF_DL2_PIT_EN_MSK;
+	}
+
+	val = mtk_pci_read32(drv_info->mdev, addr);
+	if (enable)
+		val |= mask;
+	else
+		val &= ~mask;
+
+	mtk_pci_write32(drv_info->mdev, addr, val);
+}
+
+static int mtk_dpmaif_drv_dl_pit_init_done(struct dpmaif_drv_info *drv_info, u32 pit_idx)
+{
+	int cnt = 0, dl_pit_init;
+	u32 addr;
+
+	if (pit_idx != DPMAIF_DLQ2) {
+		dl_pit_init = DPMAIF_DL_PIT_INIT_ALLSET;
+		dl_pit_init |= pit_idx << DPMAIF_LROPIT_CHAN_OFS;
+		dl_pit_init |= DPMAIF_DL_PIT_INIT_EN;
+		addr = drv_info->regs->pd_base + NRL2_DPMAIF_DL_LROPIT_INIT;
+	} else {
+		dl_pit_init = DPMAIF_DL_PIT_INIT_ALLSET;
+		dl_pit_init |= DPMAIF_DL_PIT_INIT_EN;
+		addr = drv_info->regs->pd2_base + DPMAIF_DL_2_PIT_INIT;
+	}
+
+	do {
+		if (!(mtk_pci_read32(drv_info->mdev, addr) & DPMAIF_DL_PIT_INIT_NOT_READY)) {
+			mtk_pci_write32(drv_info->mdev, addr, dl_pit_init);
+			break;
+		}
+
+		udelay(POLL_INTERVAL_US);
+	} while (++cnt < POLL_MAX_TIMES);
+
+	if (cnt >= POLL_MAX_TIMES) {
+		dev_err((drv_info->mdev)->dev, "Failed to initialize pit%u\n", pit_idx);
+		return -DATA_HW_REG_TIMEOUT;
+	}
+
+	cnt = 0;
+	do {
+		if (!((mtk_pci_read32(drv_info->mdev, addr) & DPMAIF_DL_PIT_INIT_NOT_READY)))
+			return 0;
+
+		udelay(POLL_INTERVAL_US);
+	} while (++cnt < POLL_MAX_TIMES);
+
+	dev_err((drv_info->mdev)->dev, "Failed to initialize pit%u done\n", pit_idx);
+
+	return -DATA_HW_REG_TIMEOUT;
+}
+
+static int mtk_dpmaif_drv_config_dlq_pit_hw(struct dpmaif_drv_info *drv_info, u8 q_num,
+					    struct dpmaif_rxq_cfg *dlq)
+{
+	mtk_dpmaif_drv_dl_set_pit_base_addr(drv_info, (u64)dlq->pit_base, q_num);
+	mtk_dpmaif_drv_dl_set_pit_size(drv_info, dlq->pit_cnt, q_num);
+	mtk_dpmaif_drv_dl_pit_en(drv_info, true, q_num);
+
+	return mtk_dpmaif_drv_dl_pit_init_done(drv_info, q_num);
+}
+
+static int mtk_dpmaif_drv_dlq_all_en(struct dpmaif_drv_info *drv_info, bool enable)
+{
+	int ret;
+	u8 i;
+
+	for (i = 0; i < drv_info->cfg->rx_cfg.bat_ring_num; i++) {
+		mtk_dpmaif_drv_dl_bat_en(drv_info, enable, i);
+		ret = mtk_dpmaif_drv_dl_bat_init_done(drv_info, i,
+						      DPMAIF_DL_BAT_INIT_ONLY_ENABLE_BIT);
+		if (ret < 0)
+			return ret;
+	}
+
+	return 0;
+}
+
+static int mtk_dpmaif_drv_init_dlq(struct dpmaif_drv_info *drv_info)
+{
+	struct dpmaif_rx_cfg *rx_cfg = &drv_info->cfg->rx_cfg;
+	u32 i, val;
+	int ret;
+
+	/* common dl init */
+	if (rx_cfg->pkt_alignment == 64)
+		mtk_dpmaif_drv_dl_set_pkt_alignment(drv_info, true, DPMAIF_PKT_ALIGN64_MODE);
+	else if (rx_cfg->pkt_alignment == 128)
+		mtk_dpmaif_drv_dl_set_pkt_alignment(drv_info, true, DPMAIF_PKT_ALIGN128_MODE);
+	else
+		mtk_dpmaif_drv_dl_set_pkt_alignment(drv_info, false, 0);
+
+	mtk_dpmaif_drv_dl_set_ao_mtu(drv_info, rx_cfg->mtu);
+	mtk_dpmaif_drv_dl_set_ao_remain_minsz(drv_info, DPMAIF_HW_BAT_REMAIN);
+	mtk_dpmaif_drv_dl_set_ao_bat_rsv_length(drv_info, rx_cfg->normal_bat_rsv_length);
+	mtk_dpmaif_drv_dl_set_ao_bid_maxcnt(drv_info, DPMAIF_HW_PKT_BIDCNT);
+	/* Bat cache enable. */
+	val = mtk_pci_read32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_PD_DL_BAT_INIT_CON1);
+	val |= DPMAIF_DL_BAT_CACHE_PRI;
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_PD_DL_BAT_INIT_CON1, val);
+
+	/* Common initialize normal bat. */
+	mtk_dpmaif_drv_dl_set_ao_bat_check_threshold(drv_info, DPMAIF_HW_CHK_BAT_NUM);
+	mtk_dpmaif_drv_dl_set_ao_bat_bufsz(drv_info, rx_cfg->bats[0].buf_size);
+
+	/* Initialize BAT rings. */
+	for (i = 0; i < rx_cfg->bat_ring_num; i++) {
+		mtk_dpmaif_drv_dl_set_bat_base_addr(drv_info,
+						    (u64)rx_cfg->bats[i].bat_base, i);
+		mtk_dpmaif_drv_dl_set_bat_size(drv_info, rx_cfg->bats[i].bat_cnt, i);
+		mtk_dpmaif_drv_dl_bat_en(drv_info, false, i);
+		ret = mtk_dpmaif_drv_dl_bat_init_done(drv_info, i, DPMAIF_DL_BAT_INIT_ALLSET);
+		if (ret < 0)
+			return ret;
+
+		ret = mtk_dpmaif_drv_dl_add_bat_cnt(drv_info, i, rx_cfg->bats[i].real_reload_cnt);
+		if (ret < 0)
+			return ret;
+	}
+
+	/* Initialize pit information. */
+	/* Pit burst enable. */
+	val = mtk_pci_read32(drv_info->mdev,
+			     drv_info->regs->pd_base + DPMAIF_AO_DL_RDY_CHK_THRES);
+	val |= DPMAIF_DL_BURST_PIT_EN;
+	mtk_pci_write32(drv_info->mdev,
+			drv_info->regs->pd_base + DPMAIF_AO_DL_RDY_CHK_THRES, val);
+	mtk_dpmaif_drv_dl_set_ao_pit_chknum(drv_info, DPMAIF_HW_CHK_PIT_NUM);
+	/* Currently, use rxqs[0] to config. */
+	mtk_dpmaif_drv_dl_set_pit_seqnum(drv_info, rx_cfg->rxqs[0].pit_seq_max);
+
+	for (i = 0; i < rx_cfg->rxq_cnt; i++) {
+		ret = mtk_dpmaif_drv_config_dlq_pit_hw(drv_info, i, &rx_cfg->rxqs[i]);
+		if (ret < 0)
+			return ret;
+	}
+
+	ret = mtk_dpmaif_drv_dlq_all_en(drv_info, true);
+	if (ret < 0)
+		return ret;
+
+	return 0;
+}
+
+static void mtk_dpmaif_drv_ul_update_drb_size(struct dpmaif_drv_info *drv_info,
+					      u8 q_num, u32 size)
+{
+	u32 old_size;
+	u64 addr;
+
+	addr = drv_info->regs->pd_base + DPMAIF_PD_UL_CHNL0_CON1 + 0x10 * q_num;
+	old_size = mtk_pci_read32(drv_info->mdev, addr);
+	old_size &= ~DPMAIF_DRB_SIZE_MSK;
+	old_size |= size & DPMAIF_DRB_SIZE_MSK;
+	mtk_pci_write32(drv_info->mdev, addr, old_size);
+}
+
+static void mtk_dpmaif_drv_ul_update_drb_base_addr(struct dpmaif_drv_info *drv_info,
+						   u8 q_num, u64 addr)
+{
+	u32 lb_addr = (u32)(addr & 0xFFFFFFFF);
+	u32 hb_addr = (u32)(addr >> 32);
+
+	mtk_pci_write32(drv_info->mdev,
+			drv_info->regs->pd_base + DPMAIF_PD_UL_CHNL0_CON0 + 0x10 * q_num, lb_addr);
+	mtk_pci_write32(drv_info->mdev,
+			drv_info->regs->pd_base + DPMAIF_PD_UL_CHNL0_CON2 + 0x10 * q_num, hb_addr);
+}
+
+static void mtk_dpmaif_drv_ul_rdy_en(struct dpmaif_drv_info *drv_info, u8 q_num, bool ready)
+{
+	u32 ul_rdy_en;
+
+	ul_rdy_en = mtk_pci_read32(drv_info->mdev,
+				   drv_info->regs->ao_base + DPMAIF_PD_UL_CHNL_ARB0);
+	if (ready)
+		ul_rdy_en |= BIT(q_num);
+	else
+		ul_rdy_en &= ~BIT(q_num);
+
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->ao_base + DPMAIF_PD_UL_CHNL_ARB0,
+			ul_rdy_en);
+}
+
+static void mtk_dpmaif_drv_ul_arb_en(struct dpmaif_drv_info *drv_info, u8 q_num, bool enable)
+{
+	u32 ul_arb_en;
+
+	ul_arb_en = mtk_pci_read32(drv_info->mdev,
+				   drv_info->regs->ao_base + DPMAIF_PD_UL_CHNL_ARB0);
+	if (enable)
+		ul_arb_en |= BIT(q_num + 8);
+	else
+		ul_arb_en &= ~BIT(q_num + 8);
+
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->ao_base + DPMAIF_PD_UL_CHNL_ARB0,
+			ul_arb_en);
+}
+
+static void mtk_dpmaif_drv_init_ulq(struct dpmaif_drv_info *drv_info)
+{
+	struct dpmaif_tx_cfg *tx_cfg = &drv_info->cfg->tx_cfg;
+	struct dpmaif_txq_cfg *ulq;
+	u32 i;
+
+	for (i = 0; i < tx_cfg->txq_cnt; i++) {
+		ulq = &tx_cfg->txqs[i];
+		mtk_dpmaif_drv_ul_update_drb_size(drv_info, i,
+						  ulq->drb_cnt * DPMAIF_UL_DRB_ENTRY_WORD);
+		mtk_dpmaif_drv_ul_update_drb_base_addr(drv_info, i, (u64)ulq->drb_base);
+		mtk_dpmaif_drv_ul_rdy_en(drv_info, i, true);
+		mtk_dpmaif_drv_ul_arb_en(drv_info, i, true);
+	}
+}
+
+static int mtk_dpmaif_drv_init_done(struct dpmaif_drv_info *drv_info)
+{
+	u32 val, cnt = 0;
+
+	/* Sync default value to SRAM. */
+	val = mtk_pci_read32(drv_info->mdev,
+			     drv_info->regs->pd_base + NRL2_DPMAIF_AP_MISC_OVERWRITE_CFG);
+	val |= DPMAIF_SRAM_SYNC_MASK;
+	mtk_pci_write32(drv_info->mdev,
+			drv_info->regs->pd_base + NRL2_DPMAIF_AP_MISC_OVERWRITE_CFG, val);
+	do {
+		if (!(mtk_pci_read32(drv_info->mdev,
+				     drv_info->regs->pd_base + NRL2_DPMAIF_AP_MISC_OVERWRITE_CFG) &
+				     DPMAIF_SRAM_SYNC_MASK))
+			break;
+
+		udelay(POLL_INTERVAL_US);
+	} while (++cnt < POLL_MAX_TIMES);
+
+	if (cnt >= POLL_MAX_TIMES) {
+		dev_err((drv_info->mdev)->dev, "Failed to sync default value to sram\n");
+		return -DATA_HW_REG_TIMEOUT;
+	}
+
+	/* UL configure done. */
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->ao_base + NRL2_DPMAIF_AO_UL_INIT_SET,
+			DPMAIF_UL_INIT_DONE_MASK);
+	drv_info->cfg->tx_cfg.txq_all_enable = true;
+
+	/* DL configure done. */
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->ao_base + NRL2_DPMAIF_AO_DL_INIT_SET,
+			DPMAIF_DL_INIT_DONE_MASK);
+	drv_info->cfg->rx_cfg.rxq_all_enable = true;
+
+	/* clear dummy interrupts */
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_PD_AP_UL_L2TISAR0,
+			0xFFFFFFFF);
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_PD_AP_DL_L2TISAR0,
+			0xFFFFFFFF);
+
+	return 0;
+}
+
+static void mtk_dpmaif_drv_ulq_all_en(struct dpmaif_drv_info *drv_info, bool enable)
+{
+	u32 ul_arb_en;
+
+	ul_arb_en = mtk_pci_read32(drv_info->mdev,
+				   drv_info->regs->ao_base + DPMAIF_PD_UL_CHNL_ARB0);
+	if (enable)
+		ul_arb_en |= DPMAIF_UL_ALL_QUE_ARB_EN;
+	else
+		ul_arb_en &= ~DPMAIF_UL_ALL_QUE_ARB_EN;
+
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->ao_base + DPMAIF_PD_UL_CHNL_ARB0,
+			ul_arb_en);
+	mtk_pci_read32(drv_info->mdev, drv_info->regs->ao_base + DPMAIF_PD_UL_CHNL_ARB0);
+}
+
+static bool mtk_dpmaif_drv_ul_all_idle_check(struct dpmaif_drv_info *drv_info)
+{
+	bool is_idle = false;
+	u32 ul_dbg_sta;
+
+	ul_dbg_sta = mtk_pci_read32(drv_info->mdev,
+				    drv_info->regs->pd_base + DPMAIF_PD_UL_DBG_STA2);
+	if ((ul_dbg_sta & DPMAIF_UL_IDLE_STS_MSK) == DPMAIF_UL_IDLE_STS)
+		is_idle = true;
+
+	return is_idle;
+}
+
+static int mtk_dpmaif_drv_stop_ulq(struct dpmaif_drv_info *drv_info)
+{
+	int cnt = 0;
+
+	/* Disable HW arb and check idle. */
+	mtk_dpmaif_drv_ulq_all_en(drv_info, false);
+
+	do {
+		if (mtk_dpmaif_drv_ul_all_idle_check(drv_info))
+			return 0;
+
+		udelay(POLL_INTERVAL_US);
+	} while (++cnt < POLL_MAX_TIMES);
+
+	dev_err((drv_info->mdev)->dev,
+		"Failed to stop ul queue, sta=0x%08x\n",
+		mtk_pci_read32(drv_info->mdev,
+			       drv_info->regs->pd_base + DPMAIF_PD_UL_DBG_STA2));
+
+	return -DATA_HW_REG_TIMEOUT;
+}
+
+static bool mtk_dpmaif_drv_dl_is_idle(struct dpmaif_drv_info *drv_info)
+{
+	bool is_idle = false;
+	u32 dl_dbg_sta;
+
+	dl_dbg_sta = mtk_pci_read32(drv_info->mdev,
+				    drv_info->regs->pd_base + DPMAIF_PD_DL_DBG_STA1);
+	if ((dl_dbg_sta & DPMAIF_DL_IDLE_STS) == DPMAIF_DL_IDLE_STS)
+		is_idle = true;
+
+	return is_idle;
+}
+
+static u32 mtk_dpmaif_drv_dl_get_wridx(struct dpmaif_drv_info *drv_info)
+{
+	return ((mtk_pci_read32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_AO_DL_PIT_STA3)) &
+		DPMAIF_DL_PIT_WRIDX_MSK);
+}
+
+static u32 mtk_dpmaif_drv_dl_get_pit_ridx(struct dpmaif_drv_info *drv_info)
+{
+	return ((mtk_pci_read32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_AO_DL_PIT_STA2)) &
+		DPMAIF_DL_PIT_WRIDX_MSK);
+}
+
+static int mtk_dpmaif_drv_stop_dlq(struct dpmaif_drv_info *drv_info)
+{
+	u32 cnt = 0, wridx, ridx;
+	int ret;
+
+	ret = mtk_dpmaif_drv_dlq_all_en(drv_info, false);
+	if (ret < 0)
+		return ret;
+
+	/* check idle */
+	do {
+		if (mtk_dpmaif_drv_dl_is_idle(drv_info))
+			break;
+
+		udelay(POLL_INTERVAL_US);
+	} while (++cnt < POLL_MAX_TIMES);
+
+	if (cnt >= POLL_MAX_TIMES) {
+		dev_err((drv_info->mdev)->dev,
+			"Failed to stop dl queue, sta=0x%08x\n",
+			mtk_pci_read32(drv_info->mdev,
+				       drv_info->regs->pd_base + DPMAIF_PD_DL_DBG_STA1));
+		return -DATA_HW_REG_TIMEOUT;
+	}
+
+	/* check middle pit sync done. */
+	cnt = 0;
+	do {
+		wridx = mtk_dpmaif_drv_dl_get_wridx(drv_info);
+		ridx = mtk_dpmaif_drv_dl_get_pit_ridx(drv_info);
+		if (wridx == ridx)
+			return 0;
+
+		udelay(POLL_INTERVAL_US);
+	} while (++cnt < POLL_MAX_TIMES);
+
+	dev_err((drv_info->mdev)->dev, "Failed to check middle pit sync\n");
+
+	return -DATA_HW_REG_TIMEOUT;
+}
+
+u32 mtk_dpmaif_drv_get_dl_lv2_sts(struct dpmaif_drv_info *drv_info, u8 q_id)
+{
+	if (q_id != DPMAIF_DLQ2)
+		return mtk_pci_read32(drv_info->mdev, drv_info->regs->pd_base +
+				DPMAIF_PD_AP_DL_L2TISAR0);
+	else
+		return mtk_pci_read32(drv_info->mdev, drv_info->regs->pd_base +
+				NRL2_DPMAIF_AP_MISC_APDL_L2TISAR1);
+}
+
+u32 mtk_dpmaif_drv_get_ul_lv2_sts(struct dpmaif_drv_info *drv_info)
+{
+	return mtk_pci_read32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_PD_AP_UL_L2TISAR0);
+}
+
+static int mtk_dpmaif_drv_mask_ulq_intr(struct dpmaif_drv_info *drv_info, u32 q_num)
+{
+	u32 cnt = 0, ui_que_done_mask;
+
+	if (drv_info->priv_ops && drv_info->priv_ops->mask_ulq_intr)
+		return drv_info->priv_ops->mask_ulq_intr(drv_info, q_num);
+
+	ui_que_done_mask = BIT(q_num + DP_UL_INT_DONE_OFFSET) & DPMAIF_UL_INT_QDONE_MSK;
+
+	do {
+		if (!(cnt++ % REWRITE_TIMES)) {
+			mtk_pci_write32(drv_info->mdev,
+					drv_info->regs->ao_base + DPMAIF_PD_AP_UL_L2TISR0,
+					ui_que_done_mask);
+			mtk_pci_read32(drv_info->mdev,
+				       drv_info->regs->ao_base + DPMAIF_PD_AP_UL_L2TISR0);
+		}
+
+		if ((mtk_pci_read32(drv_info->mdev,
+				    drv_info->regs->ao_base + DPMAIF_PD_AP_UL_L2TIMR0) &
+				    ui_que_done_mask)) {
+			return 0;
+		}
+
+		udelay(POLL_INTERVAL_US);
+	} while (cnt < POLL_MAX_TIMES);
+
+	dev_err((drv_info->mdev)->dev,
+		"Failed to mask ulq%u interrupt done, sta=0x%08x\n",
+		q_num, mtk_pci_read32(drv_info->mdev,
+				      drv_info->regs->ao_base + DPMAIF_PD_AP_UL_L2TIMR0));
+
+	return -DATA_HW_REG_TIMEOUT;
+}
+
+static int mtk_dpmaif_drv_ul_mask_all_tx_done_intr(struct dpmaif_drv_info *drv_info)
+{
+	int ret = 0;
+	u8 i;
+
+	for (i = 0; i < drv_info->cfg->tx_cfg.txq_cnt; i++) {
+		ret = mtk_dpmaif_drv_mask_ulq_intr(drv_info, i);
+		if (ret < 0)
+			break;
+	}
+
+	return ret;
+}
+
+void mtk_dpmaif_drv_ul_mask_multi_tx_done_intr(struct dpmaif_drv_info *drv_info,
+					       u8 q_mask)
+{
+	u32 i;
+
+	for (i = 0; i < drv_info->cfg->tx_cfg.txq_cnt; i++) {
+		if (q_mask & BIT(i))
+			mtk_dpmaif_drv_mask_ulq_intr(drv_info, i);
+	}
+}
+
+static void mtk_dpmaif_drv_unmask_ulq_intr(struct dpmaif_drv_info *drv_info, u32 q_num)
+{
+	u32 ui_que_done_mask;
+
+	if (drv_info->priv_ops && drv_info->priv_ops->unmask_ulq_intr) {
+		drv_info->priv_ops->unmask_ulq_intr(drv_info, q_num);
+		return;
+	}
+
+	ui_que_done_mask = BIT(q_num + DP_UL_INT_DONE_OFFSET) & DPMAIF_UL_INT_QDONE_MSK;
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->ao_base + DPMAIF_PD_AP_UL_L2TICR0,
+			ui_que_done_mask);
+}
+
+static void mtk_dpmaif_drv_ul_unmask_all_tx_done_intr(struct dpmaif_drv_info *drv_info)
+{
+	u8 i;
+
+	for (i = 0; i < drv_info->cfg->tx_cfg.txq_cnt; i++)
+		mtk_dpmaif_drv_unmask_ulq_intr(drv_info, i);
+}
+
+static void mtk_dpmaif_drv_clr_ul_done_status(struct dpmaif_drv_info *drv_info, u8 qno)
+{
+	u32 val, l2tisar0;
+
+	/* get TX interrupt status. */
+	l2tisar0 = mtk_dpmaif_drv_get_ul_lv2_sts(drv_info);
+	val = l2tisar0 & DPMAIF_UL_INT_QDONE & BIT(DP_UL_INT_DONE_OFFSET + qno);
+
+	/* ulq status. */
+	if (val) {
+		/* clear ulq done status */
+		mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_PD_AP_UL_L2TISAR0,
+				val);
+	}
+}
+
+void mtk_dpmaif_drv_mask_dl_batcnt_len_err_intr(struct dpmaif_drv_info *drv_info, u8 bat_id)
+{
+	if (bat_id == DPMAIF_BAT0) {
+		mtk_pci_write32(drv_info->mdev, drv_info->regs->ao_base + DPMAIF_PD_AP_DL_L2TISR0,
+				DPMAIF_DL_INT_BATCNT_LEN_ERR_MSK);
+		mtk_pci_read32(drv_info->mdev, drv_info->regs->ao_base + DPMAIF_PD_AP_DL_L2TISR0);
+	} else {
+		mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base +
+			NRL2_DPMAIF_MISC_PD_APDL12_MASK_SET, DPMAIF_DL2_INT_BATCNT_LEN_ERR_MSK);
+		mtk_pci_read32(drv_info->mdev, drv_info->regs->pd_base +
+			NRL2_DPMAIF_MISC_PD_APDL12_MASK_SET);
+	}
+}
+
+static void mtk_dpmaif_drv_unmask_dl_batcnt_len_err_intr(struct dpmaif_drv_info *drv_info,
+							 u8 bat_id)
+{
+	if (bat_id == DPMAIF_BAT0)
+		mtk_pci_write32(drv_info->mdev, drv_info->regs->ao_base + DPMAIF_PD_AP_DL_L2TICR0,
+				DPMAIF_DL_INT_BATCNT_LEN_ERR_MSK);
+	else
+		mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base +
+				NRL2_DPMAIF_MISC_PD_APDL12_MASK_CLR,
+				DPMAIF_DL2_INT_BATCNT_LEN_ERR_MSK);
+}
+
+void mtk_dpmaif_drv_dlq_mask_pit_cnt_len_err_intr(struct dpmaif_drv_info *drv_info, u8 qno)
+{
+	if (qno == DPMAIF_DLQ0) {
+		mtk_pci_write32(drv_info->mdev,
+				drv_info->regs->ao_base + NRL2_DPMAIF_AO_UL_APDL_L2TIMSR0,
+				DPMAIF_DL_INT_DLQ0_PITCNT_LEN_ERR_MSK);
+	} else if (qno == DPMAIF_DLQ1) {
+		mtk_pci_write32(drv_info->mdev,
+				drv_info->regs->ao_base + NRL2_DPMAIF_AO_UL_APDL_L2TIMSR0,
+				DPMAIF_DL_INT_DLQ1_PITCNT_LEN_ERR_MSK);
+	} else {
+		mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base +
+			NRL2_DPMAIF_MISC_PD_APDL12_MASK_SET,
+			DPMAIF_DL_INT_DLQ2_PITCNT_LEN_ERR_MSK);
+		mtk_pci_read32(drv_info->mdev, drv_info->regs->pd_base +
+			NRL2_DPMAIF_MISC_PD_APDL12_MASK_SET);
+		return;
+	}
+
+	mtk_pci_read32(drv_info->mdev, drv_info->regs->ao_base + NRL2_DPMAIF_AO_UL_APDL_L2TIMSR0);
+}
+
+static void
+	mtk_dpmaif_drv_dlq_unmask_pit_cnt_len_err_intr(struct dpmaif_drv_info *drv_info,
+						       u8 qno)
+{
+	if (qno == DPMAIF_DLQ0) {
+		mtk_pci_write32(drv_info->mdev,
+				drv_info->regs->ao_base + NRL2_DPMAIF_AO_UL_APDL_L2TIMCR0,
+				DPMAIF_DL_INT_DLQ0_PITCNT_LEN_ERR_MSK);
+	} else if (qno == DPMAIF_DLQ1) {
+		mtk_pci_write32(drv_info->mdev,
+				drv_info->regs->ao_base + NRL2_DPMAIF_AO_UL_APDL_L2TIMCR0,
+				DPMAIF_DL_INT_DLQ1_PITCNT_LEN_ERR_MSK);
+	} else {
+		mtk_pci_write32(drv_info->mdev,
+				drv_info->regs->pd_base +
+				NRL2_DPMAIF_MISC_PD_APDL12_MASK_CLR,
+				DPMAIF_DL_INT_DLQ2_PITCNT_LEN_ERR_MSK);
+	}
+}
+
+int mtk_dpmaif_drv_dlq_mask_rx_done_intr(struct dpmaif_drv_info *drv_info, u8 q_id)
+{
+	u64 mask_addr = drv_info->regs->ao_base + DPMAIF_PD_AP_DL_L2TIMR0;
+	u64 addr = drv_info->regs->ao_base + DPMAIF_PD_AP_DL_L2TISR0;
+	u32 cnt = 0, di_que_done_mask;
+
+	if (q_id == DPMAIF_DLQ0) {
+		di_que_done_mask = DPMAIF_DL_INT_DLQ0_QDONE_MSK;
+	} else if (q_id == DPMAIF_DLQ1) {
+		di_que_done_mask = DPMAIF_DL_INT_DLQ1_QDONE_MSK;
+	} else {
+		di_que_done_mask = DPMAIF_DL_INT_DLQ2_QDONE_MSK;
+		addr = drv_info->regs->pd_base + NRL2_DPMAIF_MISC_PD_APDL12_MASK_SET;
+		mask_addr = drv_info->regs->pd_base + NRL2_DPMAIF_MISC_PD_APDL12_MASK_RW;
+	}
+
+	/* Check mask status. */
+	do {
+		if (!(cnt++ % REWRITE_TIMES)) {
+			mtk_pci_write32(drv_info->mdev, addr, di_que_done_mask);
+			mtk_pci_read32(drv_info->mdev, addr);
+		}
+
+		if ((mtk_pci_read32(drv_info->mdev, mask_addr) & di_que_done_mask))
+			return 0;
+
+		udelay(POLL_INTERVAL_US);
+	} while (cnt < POLL_MAX_TIMES);
+
+	dev_err((drv_info->mdev)->dev,
+		"Failed to mask dlq%u interrupt, sta=0x%08x\n",
+		q_id, mtk_pci_read32(drv_info->mdev, mask_addr));
+	WARN_ON_ONCE(true);
+
+	return -DATA_HW_REG_TIMEOUT;
+}
+
+static int mtk_dpmaif_drv_dl_mask_all_rx_done_intr(struct dpmaif_drv_info *drv_info)
+{
+	int ret = 0;
+	u8 i;
+
+	for (i = 0; i < drv_info->cfg->rx_cfg.rxq_cnt; i++) {
+		ret = mtk_dpmaif_drv_dlq_mask_rx_done_intr(drv_info, i);
+		if (ret < 0)
+			break;
+	}
+
+	return ret;
+}
+
+static void mtk_dpmaif_drv_dl_unmask_rx_done_intr(struct dpmaif_drv_info *drv_info, u8 qno)
+{
+	u64 addr = drv_info->regs->ao_base + DPMAIF_PD_AP_DL_L2TICR0;
+	u32 di_que_done_mask;
+
+	if (qno == DPMAIF_DLQ0) {
+		di_que_done_mask = DPMAIF_DL_INT_DLQ0_QDONE_MSK;
+	} else if (qno == DPMAIF_DLQ1) {
+		di_que_done_mask = DPMAIF_DL_INT_DLQ1_QDONE_MSK;
+	} else {
+		di_que_done_mask = DPMAIF_DL2_INT_DLQ2_QDONE;
+		addr = drv_info->regs->pd_base + NRL2_DPMAIF_MISC_PD_APDL12_MASK_CLR;
+	}
+
+	mtk_pci_write32(drv_info->mdev, addr, di_que_done_mask);
+	mtk_pci_read32(drv_info->mdev, addr);
+}
+
+static void mtk_dpmaif_drv_dl_unmask_all_rx_done_intr(struct dpmaif_drv_info *drv_info)
+{
+	u8 i;
+
+	for (i = 0; i < drv_info->cfg->rx_cfg.rxq_cnt; i++)
+		mtk_dpmaif_drv_dl_unmask_rx_done_intr(drv_info, i);
+}
+
+static int mtk_dpmaif_drv_dl_add_pit_cnt(struct dpmaif_drv_info *drv_info, u32 qno,
+					 u32 pit_remain_cnt)
+{
+	u32 cnt = 0, dl_update, addr;
+
+	dl_update = pit_remain_cnt & 0x3FFFF;
+
+	if (qno != DPMAIF_DLQ2) {
+		dl_update |= DPMAIF_DL_ADD_UPDATE | (qno << DPMAIF_ADD_LRO_PIT_CHAN_OFS);
+		addr = drv_info->regs->pd_base + NRL2_DPMAIF_DL_LROPIT_ADD;
+	} else {
+		dl_update |= DPMAIF_DL_ADD_UPDATE;
+		addr = drv_info->regs->pd2_base + DPMAIF_DL_2_PIT_ADD;
+	}
+
+	do {
+		if (!(mtk_pci_read32(drv_info->mdev, addr) & DPMAIF_DL_ADD_NOT_READY)) {
+			mtk_pci_write32(drv_info->mdev, addr, dl_update);
+			break;
+		}
+
+		udelay(POLL_INTERVAL_US);
+	} while (++cnt < POLL_MAX_TIMES);
+
+	if (cnt >= POLL_MAX_TIMES) {
+		dev_err((drv_info->mdev)->dev,
+			"Failed to add dlq%u pit, cnt=%u\n", qno, pit_remain_cnt);
+		return -DATA_HW_REG_TIMEOUT;
+	}
+
+	cnt = 0;
+	do {
+		if (!((mtk_pci_read32(drv_info->mdev, addr) & DPMAIF_DL_ADD_NOT_READY)))
+			return 0;
+
+		udelay(POLL_INTERVAL_US);
+	} while (++cnt < POLL_MAX_TIMES);
+
+	dev_err((drv_info->mdev)->dev,
+		"Failed to add dlq%u pit done, cnt=%u\n", qno, pit_remain_cnt);
+
+	return -DATA_HW_REG_TIMEOUT;
+}
+
+static int mtk_dpmaif_drv_dl_add_bat_cnt(struct dpmaif_drv_info *drv_info,
+					 u8 bat_id, u32 bat_entry_cnt)
+{
+	u32 cnt = 0, dl_bat_update;
+	u64 addr;
+
+	dl_bat_update = bat_entry_cnt & 0xFFFF;
+	dl_bat_update |= DPMAIF_DL_ADD_UPDATE;
+
+	if (bat_id == DPMAIF_BAT0)
+		addr = drv_info->regs->pd_base + DPMAIF_PD_DL_BAT_ADD;
+	else
+		addr = drv_info->regs->pd2_base + DPMAIF_DL_2_BAT_ADD;
+
+	do {
+		if (!(mtk_pci_read32(drv_info->mdev, addr) & DPMAIF_DL_ADD_NOT_READY)) {
+			mtk_pci_write32(drv_info->mdev, addr, dl_bat_update);
+			break;
+		}
+
+		udelay(POLL_INTERVAL_US);
+	} while (++cnt < POLL_MAX_TIMES);
+
+	if (cnt >= POLL_MAX_TIMES) {
+		dev_err((drv_info->mdev)->dev, "Failed to add bat, cnt=%u\n", bat_entry_cnt);
+		return -DATA_HW_REG_TIMEOUT;
+	}
+
+	cnt = 0;
+	do {
+		if (!(mtk_pci_read32(drv_info->mdev, addr) & DPMAIF_DL_ADD_NOT_READY))
+			return 0;
+
+		udelay(POLL_INTERVAL_US);
+	} while (++cnt < POLL_MAX_TIMES);
+
+	dev_err((drv_info->mdev)->dev, "Failed to add bat done, cnt=%u\n", bat_entry_cnt);
+
+	return -DATA_HW_REG_TIMEOUT;
+}
+
+static int mtk_dpmaif_drv_ul_add_drb(struct dpmaif_drv_info *drv_info, u8 q_num, u32 drb_cnt)
+{
+	u32 drb_entry_cnt = drb_cnt * DPMAIF_UL_DRB_ENTRY_WORD;
+	u32 cnt = 0, ul_update;
+	u64 addr;
+
+	ul_update = drb_entry_cnt & 0xFFFF;
+	ul_update |= DPMAIF_UL_ADD_UPDATE;
+
+	if (q_num == 4)
+		addr = drv_info->regs->pd_base + NRL2_DPMAIF_UL_ADD_DESC_CH4;
+	else
+		addr = drv_info->regs->pd_base + DPMAIF_PD_UL_ADD_DESC_CH + 0x4 * q_num;
+
+	do {
+		if (!(mtk_pci_read32(drv_info->mdev, addr) & DPMAIF_UL_ADD_NOT_READY)) {
+			mtk_pci_write32(drv_info->mdev, addr, ul_update);
+			break;
+		}
+
+		udelay(POLL_INTERVAL_US);
+	} while (++cnt < POLL_MAX_TIMES);
+
+	if (cnt >= POLL_MAX_TIMES) {
+		dev_err((drv_info->mdev)->dev, "Failed to add ulq%u drb, cnt=%u\n", q_num, drb_cnt);
+		return -DATA_HW_REG_TIMEOUT;
+	}
+
+	cnt = 0;
+	do {
+		if (!(mtk_pci_read32(drv_info->mdev, addr) & DPMAIF_UL_ADD_NOT_READY))
+			return 0;
+
+		udelay(POLL_INTERVAL_US);
+	} while (++cnt < POLL_MAX_TIMES);
+
+	dev_err((drv_info->mdev)->dev, "Failed to add ulq%u drb done, cnt=%u\n", q_num, drb_cnt);
+
+	return -DATA_HW_REG_TIMEOUT;
+}
+
+static int mtk_dpmaif_drv_dl_get_pit_wridx(struct dpmaif_drv_info *drv_info, u32 qno)
+{
+	u32 pit_wridx;
+
+	if (qno != DPMAIF_DLQ2) {
+		pit_wridx = mtk_pci_read32(drv_info->mdev, drv_info->regs->pd_base +
+			NRL2_DPMAIF_AO_DL_LRO_STA5 + qno * 0x20) & DPMAIF_DL_PIT_WRIDX_MSK;
+	} else {
+		pit_wridx = mtk_pci_read32(drv_info->mdev, drv_info->regs->pd2_base +
+			DPMAIF_DL_2_STA13) & DPMAIF_DL_PIT_WRIDX_MSK;
+	}
+
+	if (unlikely(pit_wridx >= drv_info->cfg->rx_cfg.rxqs[qno].pit_cnt))
+		return -DATA_HW_REG_CHK_FAIL;
+
+	return pit_wridx;
+}
+
+static int mtk_dpmaif_drv_dl_get_pit_rdidx(struct dpmaif_drv_info *drv_info, u32 qno)
+{
+	u32 pit_rdidx;
+
+	if (qno != DPMAIF_DLQ2) {
+		pit_rdidx = mtk_pci_read32(drv_info->mdev, drv_info->regs->pd_base +
+			NRL2_DPMAIF_AO_DL_LRO_STA6 + qno * 0x20) & DPMAIF_DL_PIT_WRIDX_MSK;
+	} else {
+		pit_rdidx = mtk_pci_read32(drv_info->mdev, drv_info->regs->pd2_base +
+			DPMAIF_DL_2_STA14) & DPMAIF_DL_PIT_WRIDX_MSK;
+	}
+
+	if (unlikely(pit_rdidx >= drv_info->cfg->rx_cfg.rxqs[qno].pit_cnt))
+		return -DATA_HW_REG_CHK_FAIL;
+
+	return pit_rdidx;
+}
+
+static int mtk_dpmaif_drv_dl_get_bat_ridx(struct dpmaif_drv_info *drv_info, u8 bat_id)
+{
+	u32 bat_ridx;
+
+	if (bat_id == DPMAIF_BAT0)
+		bat_ridx = mtk_pci_read32(drv_info->mdev,
+					  drv_info->regs->pd_base + DPMAIF_AO_DL_BAT_STA2) &
+			    DPMAIF_DL_BAT_WRIDX_MSK;
+	else
+		bat_ridx = mtk_pci_read32(drv_info->mdev,
+					  drv_info->regs->pd2_base + DPMAIF_DL_2_STA4) &
+				DPMAIF_DL_2_BAT_WRIDX_MSK;
+
+	if (unlikely(bat_ridx >= drv_info->cfg->rx_cfg.bats[bat_id].bat_cnt))
+		return -DATA_HW_REG_CHK_FAIL;
+
+	return bat_ridx;
+}
+
+static int mtk_dpmaif_drv_dl_get_bat_wridx(struct dpmaif_drv_info *drv_info, u8 bat_id)
+{
+	u32 bat_wridx;
+
+	if (bat_id == DPMAIF_BAT0)
+		bat_wridx = mtk_pci_read32(drv_info->mdev,
+					   drv_info->regs->pd_base + DPMAIF_AO_DL_BAT_STA3) &
+					   DPMAIF_DL_BAT_WRIDX_MSK;
+	else
+		bat_wridx = (mtk_pci_read32(drv_info->mdev,
+			   drv_info->regs->pd2_base + DPMAIF_DL_2_STA4) >> 16) &
+			   DPMAIF_DL_2_BAT_WRIDX_MSK;
+
+	if (unlikely(bat_wridx >= drv_info->cfg->rx_cfg.bats[bat_id].bat_cnt))
+		return -DATA_HW_REG_CHK_FAIL;
+
+	return bat_wridx;
+}
+
+static int mtk_dpmaif_drv_ul_get_drb_ridx(struct dpmaif_drv_info *drv_info, u8 qno)
+{
+	u32 drb_ridx;
+	u64 addr;
+
+	addr = drv_info->regs->pd_base + drv_info->regs->ao_ul_ch0_sta + 0x4 * qno;
+
+	drb_ridx = mtk_pci_read32(drv_info->mdev, addr) >> 16;
+	drb_ridx = drb_ridx / DPMAIF_UL_DRB_ENTRY_WORD;
+
+	if (unlikely(drb_ridx >= drv_info->cfg->tx_cfg.txqs[qno].drb_cnt))
+		return -DATA_HW_REG_CHK_FAIL;
+
+	return drb_ridx;
+}
+
+int mtk_dpmaif_drv_init_com(struct dpmaif_drv_info *drv_info, void *data)
+{
+	if (mtk_dpmaif_drv_init_mode(drv_info) < 0)
+		return -DATA_HW_REG_CHK_FAIL;
+
+	if (mtk_dpmaif_drv_init_intr(drv_info) < 0)
+		return -DATA_HW_REG_CHK_FAIL;
+
+	if (mtk_dpmaif_drv_init_features(drv_info) < 0)
+		return -DATA_HW_REG_CHK_FAIL;
+
+	if (mtk_dpmaif_drv_init_dlq(drv_info) < 0)
+		return -DATA_HW_REG_CHK_FAIL;
+
+	mtk_dpmaif_drv_init_ulq(drv_info);
+
+	if (mtk_dpmaif_drv_init_done(drv_info) < 0)
+		return -DATA_HW_REG_CHK_FAIL;
+
+	return 0;
+}
+
+int mtk_dpmaif_drv_start_queue(struct dpmaif_drv_info *drv_info, enum dpmaif_drv_dir dir)
+{
+	int ret;
+
+	if (dir == DPMAIF_TX) {
+		if (unlikely(drv_info->cfg->tx_cfg.txq_all_enable))
+			return 0;
+
+		mtk_dpmaif_drv_ulq_all_en(drv_info, true);
+		mtk_dpmaif_drv_ul_unmask_all_tx_done_intr(drv_info);
+		drv_info->cfg->tx_cfg.txq_all_enable = true;
+	} else {
+		if (unlikely(drv_info->cfg->rx_cfg.rxq_all_enable))
+			return 0;
+
+		ret = mtk_dpmaif_drv_dlq_all_en(drv_info, true);
+		if (ret < 0)
+			return ret;
+
+		mtk_dpmaif_drv_dl_unmask_all_rx_done_intr(drv_info);
+		drv_info->cfg->rx_cfg.rxq_all_enable = true;
+	}
+
+	return 0;
+}
+
+int mtk_dpmaif_drv_stop_queue(struct dpmaif_drv_info *drv_info, enum dpmaif_drv_dir dir)
+{
+	int ret;
+
+	if (dir == DPMAIF_TX) {
+		if (unlikely(!drv_info->cfg->tx_cfg.txq_all_enable))
+			return 0;
+
+		ret = mtk_dpmaif_drv_stop_ulq(drv_info);
+		if (ret < 0)
+			return ret;
+
+		ret = mtk_dpmaif_drv_ul_mask_all_tx_done_intr(drv_info);
+		if (ret < 0)
+			return ret;
+
+		drv_info->cfg->tx_cfg.txq_all_enable = false;
+	} else {
+		if (unlikely(!drv_info->cfg->rx_cfg.rxq_all_enable))
+			return 0;
+
+		ret = mtk_dpmaif_drv_stop_dlq(drv_info);
+		if (ret < 0)
+			return ret;
+
+		ret = mtk_dpmaif_drv_dl_mask_all_rx_done_intr(drv_info);
+		if (ret < 0)
+			return ret;
+
+		drv_info->cfg->rx_cfg.rxq_all_enable = false;
+	}
+
+	return 0;
+}
+
+void mtk_dpmaif_drv_clr_ip_busy_sts(struct dpmaif_drv_info *drv_info)
+{
+	u32 ip_busy_sts;
+
+	/* Get AP IP busy status. */
+	ip_busy_sts = mtk_pci_read32(drv_info->mdev,
+				     drv_info->regs->pd_base + DPMAIF_PD_AP_IP_BUSY);
+
+	/* Clear AP IP busy. */
+	mtk_pci_write32(drv_info->mdev,
+			drv_info->regs->pd_base + DPMAIF_PD_AP_IP_BUSY, ip_busy_sts);
+}
+
+int mtk_dpmaif_drv_intr_handle_com(struct dpmaif_drv_info *drv_info, void *data, u8 irq_id)
+{
+	return drv_info->cfg->intr_cfg.irqs[irq_id].handle(drv_info, data);
+}
+
+int mtk_dpmaif_drv_intr_complete_com(struct dpmaif_drv_info *drv_info,
+				     enum dpmaif_drv_intr_type type, u8 id, u64 data)
+{
+	switch (type) {
+	case DPMAIF_INTR_UL_DONE:
+		if (data == DPMAIF_CLEAR_INTR)
+			mtk_dpmaif_drv_clr_ul_done_status(drv_info, id);
+		else
+			mtk_dpmaif_drv_unmask_ulq_intr(drv_info, id);
+		break;
+	case DPMAIF_INTR_DL_BATCNT_LEN_ERR:
+		mtk_dpmaif_drv_unmask_dl_batcnt_len_err_intr(drv_info, id);
+		break;
+	case DPMAIF_INTR_DL_PITCNT_LEN_ERR:
+		mtk_dpmaif_drv_dlq_unmask_pit_cnt_len_err_intr(drv_info, id);
+		break;
+	case DPMAIF_INTR_DL_DONE:
+		mtk_dpmaif_drv_dl_unmask_rx_done_intr(drv_info, id);
+		break;
+	default:
+		break;
+	}
+
+	return 0;
+}
+
+int mtk_dpmaif_drv_send_doorbell_com(struct dpmaif_drv_info *drv_info,
+				     enum dpmaif_drv_ring_type type, u8 id, u32 cnt)
+{
+	int ret = 0;
+
+	switch (type) {
+	case DPMAIF_PIT:
+		ret = mtk_dpmaif_drv_dl_add_pit_cnt(drv_info, id, cnt);
+		break;
+	case DPMAIF_BAT:
+		ret = mtk_dpmaif_drv_dl_add_bat_cnt(drv_info, id, cnt);
+		break;
+	case DPMAIF_DRB:
+		ret = mtk_dpmaif_drv_ul_add_drb(drv_info, id, cnt);
+		break;
+	default:
+		break;
+	}
+
+	return ret;
+}
+
+int mtk_dpmaif_drv_get_ring_idx(struct dpmaif_drv_info *drv_info,
+				enum dpmaif_drv_ring_idx index, u8 q_id)
+{
+	int ret = 0;
+
+	switch (index) {
+	case DPMAIF_PIT_WIDX:
+		ret = mtk_dpmaif_drv_dl_get_pit_wridx(drv_info, q_id);
+		break;
+	case DPMAIF_PIT_RIDX:
+		ret = mtk_dpmaif_drv_dl_get_pit_rdidx(drv_info, q_id);
+		break;
+	case DPMAIF_BAT_WIDX:
+		ret = mtk_dpmaif_drv_dl_get_bat_wridx(drv_info, q_id);
+		break;
+	case DPMAIF_BAT_RIDX:
+		ret = mtk_dpmaif_drv_dl_get_bat_ridx(drv_info, q_id);
+		break;
+
+	case DPMAIF_DRB_WIDX:
+		break;
+
+	case DPMAIF_DRB_RIDX:
+		ret = mtk_dpmaif_drv_ul_get_drb_ridx(drv_info, q_id);
+		break;
+	default:
+		break;
+	}
+
+	return ret;
+}
+
+void mtk_dpmaif_drv_ul_mask_intr(struct dpmaif_drv_info *drv_info, u32 mask)
+{
+	u32 cnt = 0;
+
+	if (drv_info->priv_ops && drv_info->priv_ops->mask_ul_intr) {
+		drv_info->priv_ops->mask_ul_intr(drv_info, mask);
+		return;
+	}
+
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->ao_base + DPMAIF_PD_AP_UL_L2TISR0,
+			mask);
+	mtk_pci_read32(drv_info->mdev, drv_info->regs->ao_base + DPMAIF_PD_AP_UL_L2TISR0);
+
+	do {
+		if ((mtk_pci_read32(drv_info->mdev,
+				    drv_info->regs->ao_base + DPMAIF_PD_AP_UL_L2TIMR0) &
+				    mask) == mask)
+			return;
+
+		udelay(POLL_INTERVAL_US);
+	} while (++cnt < POLL_MAX_TIMES);
+
+	dev_err((drv_info->mdev)->dev,
+		"Failed to mask interrupt done, sta=0x%08x\n",
+		mtk_pci_read32(drv_info->mdev,
+			       drv_info->regs->ao_base + DPMAIF_PD_AP_UL_L2TIMR0));
+
+	WARN_ON_ONCE(true);
+}
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv.h b/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv.h
new file mode 100644
index 000000000000..5a68d2431063
--- /dev/null
+++ b/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv.h
@@ -0,0 +1,259 @@
+/* SPDX-License-Identifier: GPL-2.0-only
+ *
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#ifndef __MTK_DPMAIF_DRV_H__
+#define __MTK_DPMAIF_DRV_H__
+
+#include "mtk_dpmaif_ring.h"
+
+#define DATA_HW_F_HPC BIT(7)
+
+#define DPMAIF_RXQ_CNT_MAX 3
+#define DPMAIF_TXQ_CNT_MAX 5
+#define DPMAIF_IRQ_CNT_MAX 5
+
+enum dpmaif_drv_dir {
+	DPMAIF_TX,
+	DPMAIF_RX,
+};
+
+struct dpmaif_drv_intr {
+	enum dpmaif_drv_dir dir;
+	unsigned int q_mask;
+	unsigned int mode;
+};
+
+enum mtk_drv_err {
+	DATA_ERR_STOP_MAX = 10,
+	DATA_HW_REG_TIMEOUT,
+	DATA_HW_REG_CHK_FAIL,
+	DATA_FLOW_CHK_ERR,
+	DATA_DMA_MAP_ERR,
+	DATA_DL_ONCE_MORE,
+	DATA_PIT_SEQ_CHK_FAIL,
+	DATA_LOW_MEM_TYPE_MAX,
+	DATA_LOW_MEM_DRB,
+	DATA_LOW_MEM_BAT,
+	DATA_LOW_MEM_PIT,
+	DATA_LOW_MEM_SKB,
+	DATA_HW_UNK_PKT,
+};
+
+enum {
+	DPMAIF_CLEAR_INTR,
+	DPMAIF_UNMASK_INTR,
+};
+
+enum dpmaif_drv_dlq_id {
+	DPMAIF_DLQ0 = 0,
+	DPMAIF_DLQ1,
+	DPMAIF_DLQ2,
+	DPMAIF_DLQ_MAX
+};
+
+enum dpmaif_drv_bat_id {
+	DPMAIF_BAT0 = 0,
+	DPMAIF_BAT1,
+};
+
+enum dpmaif_drv_ring_type {
+	DPMAIF_PIT,
+	DPMAIF_BAT,
+	DPMAIF_DRB,
+};
+
+enum dpmaif_drv_ring_idx {
+	DPMAIF_PIT_WIDX,
+	DPMAIF_PIT_RIDX,
+	DPMAIF_BAT_WIDX,
+	DPMAIF_BAT_RIDX,
+	DPMAIF_DRB_WIDX,
+	DPMAIF_DRB_RIDX,
+};
+
+struct dpmaif_drv_regs {
+	unsigned long ao_base;
+	unsigned long pd_base;
+	unsigned long pd2_base;
+	unsigned long ao_ul_ch0_sta;
+};
+
+struct dpmaif_tx_srv_cfg {
+	unsigned char vq_cnt;
+	const unsigned char *vqs;
+	int nice;
+};
+
+struct dpmaif_tx_srvs_cfg {
+	unsigned char tx_vq_cnt;
+	unsigned char tx_srv_cnt;
+	const struct dpmaif_tx_srv_cfg *tx_srvs;
+};
+
+struct dpmaif_txq_cfg {
+	dma_addr_t drb_base;
+	const unsigned int drb_cnt;
+};
+
+struct dpmaif_tx_cfg {
+	bool txq_all_enable;
+	const unsigned char txq_cnt;
+	struct dpmaif_txq_cfg *txqs;
+};
+
+struct dpmaif_rxq_cfg {
+	dma_addr_t pit_base;
+	const unsigned int pit_cnt;
+	const unsigned int pit_seq_max;
+	const unsigned char bat_ring_id;
+};
+
+struct dpmaif_bat_cfg {
+	dma_addr_t bat_base;
+	const unsigned int bat_cnt;
+	unsigned int buf_size;
+	unsigned int reload_cnt;
+	/* actual buffer count allocated during init */
+	unsigned int real_reload_cnt;
+};
+
+struct dpmaif_rx_cfg {
+	bool rxq_all_enable;
+	unsigned int mtu;
+	const unsigned int normal_bat_rsv_length;
+	const unsigned int pkt_alignment;
+	const unsigned char bat_ring_num;
+	struct dpmaif_bat_cfg *bats;
+	const unsigned char rxq_cnt;
+	struct dpmaif_rxq_cfg *rxqs;
+	/* Prefetch count required for DPMAIF Read */
+	const unsigned char bat_wrap_cnt;
+};
+
+struct dpmaif_drv_info;
+struct dpmaif_drv_intr_info;
+
+struct dpmaif_irq_cfg {
+	const unsigned int id;
+	int (*handle)(struct dpmaif_drv_info *drv_info, struct dpmaif_drv_intr_info *intr_info);
+};
+
+struct dpmaif_intr_cfg {
+	u32 ul3_l2intrs_enable;
+	u32 ul3_l2intrs_disable;
+	u32 ul_l2intrs_enable;
+	u32 ul_l2intrs_disable;
+	u32 dl_l2intrs_enable;
+	u32 dl_l2intrs_disable;
+	u32 dl2_l2intrs_enable;
+	u32 dl2_l2intrs_disable;
+	u32 udl_ip_busy_disable;
+	u32 hpc_disable;
+	unsigned char irq_cnt;
+	const struct dpmaif_irq_cfg *irqs;
+};
+
+struct dpmaif_drv_cfg {
+	const u32 cap;
+	const struct dpmaif_tx_srvs_cfg tx_srvs_cfg;
+	struct dpmaif_tx_cfg tx_cfg;
+	struct dpmaif_rx_cfg rx_cfg;
+	const struct dpmaif_intr_cfg intr_cfg;
+};
+
+struct dpmaif_priv_ops {
+	void (*set_pcie_domain)(struct dpmaif_drv_info *drv_info);
+	u32 (*get_ul_intr_mask)(struct dpmaif_drv_info *drv_info);
+	int (*dynamic_sram_init)(struct dpmaif_drv_info *drv_info);
+	int (*ul_intr_init)(struct dpmaif_drv_info *drv_info);
+	int (*mask_ulq_intr)(struct dpmaif_drv_info *drv_info, u32 q_num);
+	void (*unmask_ulq_intr)(struct dpmaif_drv_info *drv_info, u32 q_num);
+	void (*mask_ul_intr)(struct dpmaif_drv_info *drv_info, u32 mask);
+	void (*set_hpc_cntl)(struct dpmaif_drv_info *drv_info);
+	void (*set_dlq_timeout)(struct dpmaif_drv_info *drv_info);
+	void (*clr_dlq_timeout)(struct dpmaif_drv_info *drv_info);
+};
+
+struct dpmaif_drv_info {
+	struct mtk_md_dev *mdev;
+	struct dpmaif_drv_ops *drv_ops;
+	struct dpmaif_priv_ops *priv_ops;
+	const struct dpmaif_drv_regs *regs;
+	struct dpmaif_drv_cfg *cfg;
+};
+
+enum dpmaif_drv_intr_type {
+	DPMAIF_INTR_MIN = 0,
+	/* uplink part */
+	DPMAIF_INTR_UL_DONE,
+	DPMAIF_INTR_UL_DRB_EMPTY,
+	DPMAIF_INTR_UL_MD_NOTREADY,
+	DPMAIF_INTR_UL_MD_PWR_NOTREADY,
+	DPMAIF_INTR_UL_LEN_ERR,
+
+	/* downlink part */
+	DPMAIF_INTR_DL_LEGACY_DONE,
+	DPMAIF_INTR_DL_SKB_LEN_ERR,
+	DPMAIF_INTR_DL_BATCNT_LEN_ERR,
+	DPMAIF_INTR_DL_PKT_EMPTY_SET,
+	DPMAIF_INTR_DL_MTU_ERR,
+
+	DPMAIF_INTR_DL_PITCNT_LEN_ERR,
+	DPMAIF_INTR_DL_HPC_ENT_TYPE_ERR,
+	DPMAIF_INTR_DL_DONE,
+
+	/* traffic sync */
+	DPMAIF_INTR_TRAS_SYNC,
+	DPMAIF_INTR_MAX
+};
+
+#define DPMAIF_INTR_COUNT ((DPMAIF_INTR_MAX) - (DPMAIF_INTR_MIN) - 1)
+
+struct dpmaif_drv_intr_info {
+	unsigned char intr_cnt;
+	enum dpmaif_drv_intr_type intr_types[DPMAIF_INTR_COUNT];
+	/* it's a queue mask or queue index */
+	u32 intr_queues[DPMAIF_INTR_COUNT];
+};
+
+/* This structure defines the management hooks for dpmaif devices. */
+struct dpmaif_drv_ops {
+	/* Initialize dpmaif hardware. */
+	int (*init)(struct dpmaif_drv_info *drv_info, void *data);
+	/* Start dpmaif hardware transaction and unmask dpmaif interrupt. */
+	int (*start_queue)(struct dpmaif_drv_info *drv_info, enum dpmaif_drv_dir dir);
+	/* Stop dpmaif hardware transaction and mask dpmaif interrupt. */
+	int (*stop_queue)(struct dpmaif_drv_info *drv_info, enum dpmaif_drv_dir dir);
+	int (*intr_handle)(struct dpmaif_drv_info *drv_info, void *data, u8 irq_id);
+	/* Unmask or clear dpmaif interrupt. */
+	int (*intr_complete)(struct dpmaif_drv_info *drv_info, enum dpmaif_drv_intr_type type,
+			     u8 q_id, u64 data);
+	int (*send_doorbell)(struct dpmaif_drv_info *drv_info, enum dpmaif_drv_ring_type type,
+			     u8 q_id, u32 cnt);
+	int (*get_ring_idx)(struct dpmaif_drv_info *drv_info, enum dpmaif_drv_ring_idx index,
+			    u8 q_id);
+	int (*get_rx_info)(void *pit, struct dpmaif_rx_info *rx_info, u32 pit_seq_expect, u8 q_id);
+	void (*fill_tx_info)(void *drb, struct dpmaif_tx_info *tx_info, int type);
+};
+
+static inline int mtk_dpmaif_drv_intr_handle(struct dpmaif_drv_info *drv_info,
+					     void *data, u8 irq_id)
+{
+	return drv_info->drv_ops->intr_handle(drv_info, data, irq_id);
+}
+
+static inline int mtk_dpmaif_drv_intr_complete(struct dpmaif_drv_info *drv_info,
+					       enum dpmaif_drv_intr_type type, u8 q_id, u64 data)
+{
+	return drv_info->drv_ops->intr_complete(drv_info, type, q_id, data);
+}
+
+static inline int mtk_dpmaif_drv_send_doorbell(struct dpmaif_drv_info *drv_info,
+					       enum dpmaif_drv_ring_type type, u8 q_id, u32 cnt)
+{
+	return drv_info->drv_ops->send_doorbell(drv_info, type, q_id, cnt);
+}
+
+#endif
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv_m9xx.c b/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv_m9xx.c
new file mode 100644
index 000000000000..a1b86424852d
--- /dev/null
+++ b/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_drv_m9xx.c
@@ -0,0 +1,687 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#define pr_fmt(fmt) "DATA_DRV_M9XX: " fmt
+
+#include <linux/delay.h>
+
+#include "mtk_dev.h"
+#include "mtk_dpmaif_drv.h"
+#include "mtk_dpmaif_reg_m9xx.h"
+#include "mtk_dpmaif_ring.h"
+#include "mtk_pci.h"
+
+enum dpmaif_drv_irq_src {
+	DPMAIF_IRQ_SRC0_DLQ0,
+	DPMAIF_IRQ_SRC1_DLQ1,
+	DPMAIF_IRQ_SRC2_UL_DONE,
+	DPMAIF_IRQ_SRC3_DLQ2,
+	DPMAIF_IRQ_SRC4_TRANS_SYNC
+};
+
+static int mtk_dpmaif_drv_irq_src0(struct dpmaif_drv_info *drv_info,
+				   struct dpmaif_drv_intr_info *intr_info);
+static int mtk_dpmaif_drv_irq_src1(struct dpmaif_drv_info *drv_info,
+				   struct dpmaif_drv_intr_info *intr_info);
+static int mtk_dpmaif_drv_irq_src2(struct dpmaif_drv_info *drv_info,
+				   struct dpmaif_drv_intr_info *intr_info);
+static int mtk_dpmaif_drv_irq_src3(struct dpmaif_drv_info *drv_info,
+				   struct dpmaif_drv_intr_info *intr_info);
+static int mtk_dpmaif_drv_irq_src4(struct dpmaif_drv_info *drv_info,
+				   struct dpmaif_drv_intr_info *intr_info);
+
+static const struct dpmaif_drv_regs regs = {
+	.ao_base = DPMAIF_DEV_AO_BASE,
+	.pd_base = DPMAIF_DEV_PD_BASE,
+	.pd2_base = DPMAIF_DEV_PD2_BASE,
+	.ao_ul_ch0_sta = NRL2_DPMAIF_AO_UL_CH0_STA,
+};
+
+static const unsigned char tx_srv0_vqs[] = {3};
+static const unsigned char tx_srv1_vqs[] = {1};
+static const unsigned char tx_srv2_vqs[] = {0, 4};
+static const struct dpmaif_tx_srv_cfg tx_srvs[] = {
+			{
+				.vq_cnt = ARRAY_SIZE(tx_srv0_vqs),
+				.vqs = tx_srv0_vqs,
+				.nice = -20,
+			},
+			{
+				.vq_cnt = ARRAY_SIZE(tx_srv1_vqs),
+				.vqs = tx_srv1_vqs,
+				.nice = -15,
+			},
+			{
+				.vq_cnt = ARRAY_SIZE(tx_srv2_vqs),
+				.vqs = tx_srv2_vqs,
+				.nice = -10,
+			},
+};
+
+static struct dpmaif_txq_cfg txqs[] = {
+	{
+		.drb_cnt = 2048,
+	},
+	{
+		.drb_cnt = 2048,
+	},
+	{
+		.drb_cnt = 128,
+	},
+	{
+		.drb_cnt = 1024,
+	},
+	{
+		.drb_cnt = 2048,
+	},
+};
+
+static struct dpmaif_bat_cfg bats[] = {
+	{
+	.bat_cnt = 32768,
+	.reload_cnt = 3072,
+	},
+	{
+	.bat_cnt = 1024,
+	.reload_cnt = 512,
+	},
+};
+
+static struct dpmaif_rxq_cfg rxqs[] = {
+	{
+	.pit_cnt = 32768,
+	.bat_ring_id = 0,
+	.pit_seq_max = 251,
+	},
+	{
+	.pit_cnt = 32768,
+	.bat_ring_id = 0,
+	.pit_seq_max = 251,
+	},
+	{
+	.pit_cnt = 2048,
+	.bat_ring_id = 1,
+	.pit_seq_max = 251,
+	},
+};
+
+static const struct dpmaif_irq_cfg irqs[] = {
+	{
+	.id = MTK_IRQ_SRC_DPMAIF,
+	.handle = mtk_dpmaif_drv_irq_src0,
+	},
+	{
+	.id = MTK_IRQ_SRC_DPMAIF2,
+	.handle = mtk_dpmaif_drv_irq_src1,
+	},
+	{
+	.id = MTK_IRQ_SRC_DPMAIF3,
+	.handle = mtk_dpmaif_drv_irq_src2,
+	},
+	{
+	.id = MTK_IRQ_SRC_DPMAIF6,
+	.handle = mtk_dpmaif_drv_irq_src3,
+	},
+	{
+	.id = MTK_IRQ_SRC_TRAS_SYNC,
+	.handle = mtk_dpmaif_drv_irq_src4,
+	},
+};
+
+static struct dpmaif_drv_cfg drv_cfg = {
+	.cap = DATA_HW_F_HPC,
+	.tx_srvs_cfg = {
+		.tx_vq_cnt = ARRAY_SIZE(txqs),
+		.tx_srv_cnt = ARRAY_SIZE(tx_srvs),
+		.tx_srvs = tx_srvs,
+	},
+	.tx_cfg = {
+		.txq_cnt = ARRAY_SIZE(txqs),
+		.txqs = txqs,
+	},
+	.rx_cfg = {
+		.normal_bat_rsv_length = 0,
+		.pkt_alignment = 64,
+		.mtu = 9000,
+		.bat_ring_num = ARRAY_SIZE(bats),
+		.bats = bats,
+		.rxq_cnt = ARRAY_SIZE(rxqs),
+		.rxqs = rxqs,
+		.bat_wrap_cnt = 48,
+	},
+	.intr_cfg = {
+		.ul3_l2intrs_disable = DPMAIF_UL3_INT_VALID_MSK & ~DPMAIF_UL_INT_QDONE_MSK,
+		.ul3_l2intrs_enable = DPMAIF_UL_INT_QDONE_MSK,
+		.ul_l2intrs_disable = DPMAIF_UL_INT_VALID_MSK & ~DPMAIF_UL_INT_QDONE_MSK,
+		.ul_l2intrs_enable = DPMAIF_UL_INT_QDONE_MSK,
+		.dl_l2intrs_disable = DPMAIF_DL_INT_VALID_MSK & ~(DPMAIF_DL_INT_DLQ0_QDONE_MSK |
+			DPMAIF_DL_INT_DLQ1_QDONE_MSK | DPMAIF_DL_INT_DLQ0_PITCNT_LEN_ERR_MSK |
+			DPMAIF_DL_INT_DLQ1_PITCNT_LEN_ERR_MSK | DPMAIF_DL_INT_BATCNT_LEN_ERR_MSK),
+		.dl_l2intrs_enable = DPMAIF_DL_INT_DLQ0_QDONE_MSK |
+			DPMAIF_DL_INT_DLQ1_QDONE_MSK | DPMAIF_DL_INT_DLQ0_PITCNT_LEN_ERR_MSK |
+			DPMAIF_DL_INT_DLQ1_PITCNT_LEN_ERR_MSK | DPMAIF_DL_INT_BATCNT_LEN_ERR_MSK,
+		.dl2_l2intrs_disable = DPMAIF_DL2_INT_OTHER_MSK & ~(DPMAIF_DL_INT_DLQ2_QDONE_MSK |
+			DPMAIF_DL_INT_DLQ2_PITCNT_LEN_ERR_MSK | DPMAIF_DL2_INT_BATCNT_LEN_ERR_MSK),
+		.dl2_l2intrs_enable = DPMAIF_DL_INT_DLQ2_QDONE_MSK |
+			DPMAIF_DL_INT_DLQ2_PITCNT_LEN_ERR_MSK | DPMAIF_DL2_INT_BATCNT_LEN_ERR_MSK,
+		.udl_ip_busy_disable = DPMAIF_UDL_IP_BUSY_MSK,
+		.hpc_disable = DPMAIF_DL_INT_Q2APTOP_MSK |
+			DPMAIF_DL_INT_Q2TOQ1_MSK | DPMAIF_UL_TOP0_INT_MSK,
+		.irq_cnt = ARRAY_SIZE(irqs),
+		.irqs = irqs,
+	},
+};
+
+static u32 mtk_dpmaif_drv_get_ul_intr_mask_m9xx(struct dpmaif_drv_info *drv_info)
+{
+	return mtk_pci_read32(drv_info->mdev, drv_info->regs->pd_base +
+				DPMAIF_PD_AP_UL_L2TIMR0_NEXT);
+}
+
+static int mtk_dpmaif_drv_dynamic_sram_init(struct dpmaif_drv_info *drv_info)
+{
+	u32 sram_addr_tbl[][2] = {
+			{0xFFFF0100, 0x8033F000},
+			{0xFFFF0200, 0x801DF000},
+			{0xFFFF0400, 0x805FF000},
+			{0xFFFF1000, 0x8033F000},
+			{0xFFFF4000, 0x80443000},
+			{0xFFFF8000, 0x80177000},
+	};
+	u32 sram_cnt;
+	u32 cnt = 0;
+	u32 i;
+
+	sram_cnt = ARRAY_SIZE(sram_addr_tbl);
+	for (i = 0; i < sram_cnt; i++) {
+		mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base +
+				NRL2_DPMAIF_AP_MISC_SRAM_INIT_SET1, sram_addr_tbl[i][0]);
+		mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base +
+				NRL2_DPMAIF_AP_MISC_SRAM_INIT_SET0, sram_addr_tbl[i][1]);
+
+		do {
+			if (!(mtk_pci_read32(drv_info->mdev, drv_info->regs->pd_base +
+				NRL2_DPMAIF_AP_MISC_SRAM_INIT_SET0) & DPMAIF_AP_PD_SRAM_EN_BIT))
+				break;
+
+			udelay(POLL_INTERVAL_US);
+		} while (++cnt < POLL_MAX_TIMES);
+
+		if (cnt >= POLL_MAX_TIMES) {
+			dev_err((drv_info->mdev)->dev, "Failed to initialize dynamic sram%d\n", i);
+			return -DATA_HW_REG_TIMEOUT;
+		}
+		cnt = 0;
+	}
+
+	return 0;
+}
+
+static int mtk_dpmaif_drv_ul_intr_init_m9xx(struct dpmaif_drv_info *drv_info)
+{
+	const struct dpmaif_intr_cfg *intr_cfg = &drv_info->cfg->intr_cfg;
+	u32 cnt = 0;
+	int ret;
+
+	ret = mtk_dpmaif_drv_ul_intr_init(drv_info);
+	if (unlikely(ret < 0))
+		return ret;
+
+	/* clear UL interrupt */
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_PD_AP_UL_L2TISAR0,
+			0xFFFFFFFF);
+	/* unmask ul3_l2intrs_enable interrupt */
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_PD_AP_UL_L2TICR0_NEXT,
+			intr_cfg->ul3_l2intrs_enable);
+	/* mask ul3_l2intrs_disable interrupt */
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_PD_AP_UL_L2TISR0_NEXT,
+			intr_cfg->ul3_l2intrs_disable);
+	mtk_pci_read32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_PD_AP_UL_L2TISR0_NEXT);
+	do {
+		if (((mtk_pci_read32(drv_info->mdev,
+				     drv_info->regs->pd_base + DPMAIF_PD_AP_UL_L2TIMR0_NEXT) &
+					  intr_cfg->ul3_l2intrs_disable) ==
+					  intr_cfg->ul3_l2intrs_disable))
+			break;
+
+		udelay(POLL_INTERVAL_US);
+	} while (++cnt < POLL_MAX_TIMES);
+
+	if (cnt >= POLL_MAX_TIMES) {
+		dev_err((drv_info->mdev)->dev,
+			"Failed to set UL interrupt mask, mask=0x%08x\n",
+			mtk_pci_read32(drv_info->mdev,
+				       drv_info->regs->pd_base +
+				       DPMAIF_PD_AP_UL_L2TIMR0_NEXT));
+		return -DATA_HW_REG_TIMEOUT;
+	}
+
+	return 0;
+}
+
+static int mtk_dpmaif_drv_mask_ulq_intr(struct dpmaif_drv_info *drv_info, u32 q_num)
+{
+	u32 cnt = 0, ui_que_done_mask;
+
+	ui_que_done_mask = BIT(q_num + DP_UL_INT_DONE_OFFSET) & DPMAIF_UL_INT_QDONE_MSK;
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_PD_AP_UL_L2TISR0_NEXT,
+			ui_que_done_mask);
+	mtk_pci_read32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_PD_AP_UL_L2TISR0_NEXT);
+
+	do {
+		if ((mtk_pci_read32(drv_info->mdev,
+				    drv_info->regs->pd_base + DPMAIF_PD_AP_UL_L2TIMR0_NEXT) &
+					ui_que_done_mask))
+			return 0;
+
+		udelay(POLL_INTERVAL_US);
+	} while (++cnt < POLL_MAX_TIMES);
+
+	dev_err((drv_info->mdev)->dev,
+		"Failed to mask ulq%u interrupt done, sta=0x%08x\n",
+		q_num, mtk_pci_read32(drv_info->mdev,
+				      drv_info->regs->pd_base +
+				      DPMAIF_PD_AP_UL_L2TIMR0_NEXT));
+
+	return -DATA_HW_REG_TIMEOUT;
+}
+
+static void mtk_dpmaif_drv_unmask_ulq_intr(struct dpmaif_drv_info *drv_info, u32 q_num)
+{
+	u32 ui_que_done_mask;
+
+	ui_que_done_mask = BIT(q_num + DP_UL_INT_DONE_OFFSET) & DPMAIF_UL_INT_QDONE_MSK;
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_PD_AP_UL_L2TICR0_NEXT,
+			ui_que_done_mask);
+}
+
+static void mtk_dpmaif_drv_mask_ul_intr(struct dpmaif_drv_info *drv_info, u32 mask)
+{
+	u32 cnt = 0;
+
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_PD_AP_UL_L2TISR0_NEXT,
+			mask);
+	mtk_pci_read32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_PD_AP_UL_L2TISR0_NEXT);
+
+	do {
+		if ((mtk_pci_read32(drv_info->mdev,
+				    drv_info->regs->pd_base + DPMAIF_PD_AP_UL_L2TIMR0_NEXT) &
+					mask) == mask)
+			return;
+
+		udelay(POLL_INTERVAL_US);
+	} while (++cnt < POLL_MAX_TIMES);
+
+	dev_err((drv_info->mdev)->dev,
+		"Failed to mask interrupt done, sta=0x%08x\n",
+		mtk_pci_read32(drv_info->mdev,
+			       drv_info->regs->pd_base +
+			       DPMAIF_PD_AP_UL_L2TIMR0_NEXT));
+
+	WARN_ON_ONCE(true);
+}
+
+static void mtk_dpmaif_drv_set_hpc_cntl_m9xx(struct dpmaif_drv_info *drv_info)
+{
+	u32 cfg;
+
+	cfg = DPMAIF_HPC_LRO_PATH_DF & 0x3;
+	cfg |= (DPMAIF_HPC_ADD_MODE_DF & 0x3) << 2;
+	cfg |= (DPMAIF_HASH_PRIME_DF & 0xF) << 4;
+	cfg |= (DPMAIF_HPC_NUM_M9XX & 0xFF) << 8;
+
+	/* Configuration include hpc dlq path, hpc add mode, hash prime, hpc total number. */
+	mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + NRL2_DPMAIF_AO_DL_HPC_CNTL, cfg);
+}
+
+static void mtk_dpmaif_drv_set_dlq_timeout_m9xx(struct dpmaif_drv_info *drv_info)
+{
+	u32 val, i;
+
+	for (i = 0; i < DPMAIF_HPC_NUM_EXT; i++) {
+		val = mtk_pci_read32(drv_info->mdev, drv_info->regs->pd2_base +
+				     NRL2_DPMAIF_PD_DL_LROPIT_TIMEOUT5 + ((i >> 1) << 2));
+
+		if (i % 2)
+			val = (val & 0xFFFF) | (DPMAIF_LRO_TIMEOUT_THRES_DF << 16);
+		else
+			val = (val & 0xFFFF0000) | DPMAIF_LRO_TIMEOUT_THRES_DF;
+
+		mtk_pci_write32(drv_info->mdev, drv_info->regs->pd2_base +
+				NRL2_DPMAIF_PD_DL_LROPIT_TIMEOUT5 + ((i >> 1) << 2), val);
+	}
+}
+
+static void mtk_dpmaif_drv_clr_dlq_timeout_m9xx(struct dpmaif_drv_info *drv_info)
+{
+	u32 val, i;
+
+	for (i = 0; i < DPMAIF_HPC_NUM_EXT; i++) {
+		val = mtk_pci_read32(drv_info->mdev, drv_info->regs->pd2_base +
+				     NRL2_DPMAIF_PD_DL_LROPIT_TIMEOUT5 + ((i >> 1) << 2));
+
+		if (i % 2)
+			val = (val & 0xFFFF) | BIT(16);
+		else
+			val = (val & 0xFFFF0000) | 1;
+
+		mtk_pci_write32(drv_info->mdev, drv_info->regs->pd2_base +
+				NRL2_DPMAIF_PD_DL_LROPIT_TIMEOUT5 + ((i >> 1) << 2), val);
+	}
+}
+
+static void mtk_dpmaif_drv_set_pcie_domain(struct dpmaif_drv_info *drv_info)
+{
+	/* set HW pcie domain */
+	mtk_pci_write32(drv_info->mdev,
+			drv_info->regs->pd2_base + DPMAIF_DL_RESOURCE_DOMAIN, 0x000A9AAA);
+}
+
+static struct dpmaif_priv_ops dpmaif_priv_ops_m9xx = {
+	.set_pcie_domain = mtk_dpmaif_drv_set_pcie_domain,
+	.get_ul_intr_mask = mtk_dpmaif_drv_get_ul_intr_mask_m9xx,
+	.dynamic_sram_init = mtk_dpmaif_drv_dynamic_sram_init,
+	.ul_intr_init = mtk_dpmaif_drv_ul_intr_init_m9xx,
+	.mask_ulq_intr = mtk_dpmaif_drv_mask_ulq_intr,
+	.unmask_ulq_intr = mtk_dpmaif_drv_unmask_ulq_intr,
+	.mask_ul_intr = mtk_dpmaif_drv_mask_ul_intr,
+	.set_hpc_cntl = mtk_dpmaif_drv_set_hpc_cntl_m9xx,
+	.set_dlq_timeout = mtk_dpmaif_drv_set_dlq_timeout_m9xx,
+	.clr_dlq_timeout = mtk_dpmaif_drv_clr_dlq_timeout_m9xx,
+};
+
+static void mtk_dpmaif_drv_cfg_get(struct dpmaif_drv_info *drv_info)
+{
+	drv_info->regs = &regs;
+	drv_info->cfg = &drv_cfg;
+	drv_info->priv_ops = &dpmaif_priv_ops_m9xx;
+}
+
+static void mtk_dpmaif_drv_reset(struct dpmaif_drv_info *drv_info)
+{
+	u32 mask;
+	/* Set DPMAIF infra CG en */
+	mtk_pci_write32(drv_info->mdev, DPMAIF_AP_INFRA_CG_SET, DPMAIF_AP_INFRA_CG_BIT);
+	udelay(2);
+
+	/* Glitch protect on */
+	mask = mtk_pci_read32(drv_info->mdev, DPMAIF_AP_INFRA_GLITCH_PORT);
+	mask &= ~DPMAIF_AP_GLITCH_PROT_BIT;
+	mtk_pci_write32(drv_info->mdev, DPMAIF_AP_INFRA_GLITCH_PORT, mask);
+	udelay(2);
+
+	/* AO&PD reset assert&de-assert */
+	mtk_pci_write32(drv_info->mdev, DPMAIF_AP_AO_RGU_ASSERT, DPMAIF_AP_AO_RST_BIT);
+	udelay(2);
+	mtk_pci_write32(drv_info->mdev, DPMAIF_AP_RGU_ASSERT, DPMAIF_AP_RST_BIT);
+	udelay(2);
+	mtk_pci_write32(drv_info->mdev, DPMAIF_AP_AO_RGU_DEASSERT, DPMAIF_AP_AO_RST_BIT);
+	udelay(2);
+	mtk_pci_write32(drv_info->mdev, DPMAIF_AP_RGU_DEASSERT, DPMAIF_AP_RST_BIT);
+	udelay(2);
+
+	/* Glitch protect off */
+	mask = mtk_pci_read32(drv_info->mdev, DPMAIF_AP_INFRA_GLITCH_PORT);
+	mask |= DPMAIF_AP_GLITCH_PROT_BIT;
+	mtk_pci_write32(drv_info->mdev, DPMAIF_AP_INFRA_GLITCH_PORT, mask);
+	udelay(2);
+
+	/* Set DPMAIF infra CG off */
+	mtk_pci_write32(drv_info->mdev, DPMAIF_AP_INFRA_CG_CLR, DPMAIF_AP_INFRA_CG_BIT);
+	udelay(2);
+}
+
+static u32 mtk_dpmaif_drv_irq_src0_filter(struct dpmaif_drv_info *drv_info, u32 l2risar0,
+					  u32 l2rimr0)
+{
+	if (l2rimr0 & DPMAIF_DL_INT_DLQ0_QDONE_MSK)
+		l2risar0 &= ~DPMAIF_DL_INT_DLQ0_QDONE;
+
+	if (l2rimr0 & DPMAIF_DL_INT_DLQ0_PITCNT_LEN_ERR_MSK)
+		l2risar0 &= ~DPMAIF_DL_INT_DLQ0_PITCNT_LEN_ERR;
+
+	if (l2rimr0 & DPMAIF_DL_INT_BATCNT_LEN_ERR_MSK)
+		l2risar0 &= ~DPMAIF_DL_INT_BATCNT_LEN_ERR;
+
+	return l2risar0;
+}
+
+static int mtk_dpmaif_drv_irq_src0(struct dpmaif_drv_info *drv_info,
+				   struct dpmaif_drv_intr_info *intr_info)
+{
+	u32 val, ori_l2risar0, l2risar0, l2rimr0;
+
+	ori_l2risar0 = mtk_dpmaif_drv_get_dl_lv2_sts(drv_info, DPMAIF_DLQ0);
+	l2rimr0 = mtk_dpmaif_drv_get_dl_intr_mask(drv_info, DPMAIF_DLQ0);
+
+	/* filter care interrupt status. */
+	l2risar0 = ori_l2risar0 & (DPMAIF_DL_INT_DLQ0_QDONE | DPMAIF_DL_INT_DLQ0_PITCNT_LEN_ERR |
+		DPMAIF_DL_INT_BATCNT_LEN_ERR |
+		DPMAIF_DL_INT_DLQ_QDONE);
+	if (l2risar0) {
+		/* Filter to get DL unmasked interrupts */
+		l2risar0 = mtk_dpmaif_drv_irq_src0_filter(drv_info, l2risar0, l2rimr0);
+
+		val = l2risar0 & DPMAIF_DL_INT_BATCNT_LEN_ERR;
+		if (val) {
+			intr_info->intr_types[intr_info->intr_cnt] = DPMAIF_INTR_DL_BATCNT_LEN_ERR;
+			intr_info->intr_queues[intr_info->intr_cnt] = DPMAIF_BAT0;
+			intr_info->intr_cnt++;
+			mtk_dpmaif_drv_mask_dl_batcnt_len_err_intr(drv_info, DPMAIF_BAT0);
+		}
+
+		val = l2risar0 & DPMAIF_DL_INT_DLQ0_PITCNT_LEN_ERR;
+		if (val) {
+			intr_info->intr_types[intr_info->intr_cnt] = DPMAIF_INTR_DL_PITCNT_LEN_ERR;
+			intr_info->intr_queues[intr_info->intr_cnt] = DPMAIF_DLQ0;
+			intr_info->intr_cnt++;
+			mtk_dpmaif_drv_dlq_mask_pit_cnt_len_err_intr(drv_info, DPMAIF_DLQ0);
+		}
+
+		val = l2risar0 & DPMAIF_DL_INT_DLQ0_QDONE;
+		if (val) {
+			if (!mtk_dpmaif_drv_dlq_mask_rx_done_intr(drv_info, DPMAIF_DLQ0)) {
+				intr_info->intr_types[intr_info->intr_cnt] = DPMAIF_INTR_DL_DONE;
+				intr_info->intr_queues[intr_info->intr_cnt] = DPMAIF_DLQ0;
+				intr_info->intr_cnt++;
+			}
+		}
+
+		/* Clear interrupt status. */
+		mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_PD_AP_DL_L2TISAR0,
+				l2risar0);
+	}
+
+	mtk_dpmaif_drv_clr_ip_busy_sts(drv_info);
+
+	return 0;
+}
+
+static u32 mtk_dpmaif_drv_irq_src1_filter(struct dpmaif_drv_info *drv_info, u32 l2risar0,
+					  u32 l2rimr0)
+{
+	if (l2rimr0 & DPMAIF_DL_INT_DLQ1_QDONE_MSK)
+		l2risar0 &= ~DPMAIF_DL_INT_DLQ1_QDONE;
+
+	if (l2rimr0 & DPMAIF_DL_INT_DLQ1_PITCNT_LEN_ERR_MSK)
+		l2risar0 &= ~DPMAIF_DL_INT_DLQ1_PITCNT_LEN_ERR;
+
+	return l2risar0;
+}
+
+static int mtk_dpmaif_drv_irq_src1(struct dpmaif_drv_info *drv_info,
+				   struct dpmaif_drv_intr_info *intr_info)
+{
+	u32 val, ori_l2risar0, l2risar0, l2rimr0;
+
+	ori_l2risar0 = mtk_dpmaif_drv_get_dl_lv2_sts(drv_info, DPMAIF_DLQ1);
+	l2rimr0 = mtk_dpmaif_drv_get_dl_intr_mask(drv_info, DPMAIF_DLQ1);
+
+	/* filter care interrupt status. */
+	l2risar0 = ori_l2risar0 & (DPMAIF_DL_INT_DLQ1_QDONE | DPMAIF_DL_INT_DLQ1_PITCNT_LEN_ERR);
+	if (l2risar0) {
+		/* Filter to get DL unmasked interrupts */
+		l2risar0 = mtk_dpmaif_drv_irq_src1_filter(drv_info, l2risar0, l2rimr0);
+
+		val = l2risar0 & DPMAIF_DL_INT_DLQ1_PITCNT_LEN_ERR;
+		if (val) {
+			intr_info->intr_types[intr_info->intr_cnt] = DPMAIF_INTR_DL_PITCNT_LEN_ERR;
+			intr_info->intr_queues[intr_info->intr_cnt] = DPMAIF_DLQ1;
+			intr_info->intr_cnt++;
+			mtk_dpmaif_drv_dlq_mask_pit_cnt_len_err_intr(drv_info, DPMAIF_DLQ1);
+		}
+
+		val = l2risar0 & DPMAIF_DL_INT_DLQ1_QDONE;
+		if (val) {
+			if (!mtk_dpmaif_drv_dlq_mask_rx_done_intr(drv_info, DPMAIF_DLQ1)) {
+				intr_info->intr_types[intr_info->intr_cnt] = DPMAIF_INTR_DL_DONE;
+				intr_info->intr_queues[intr_info->intr_cnt] = DPMAIF_DLQ1;
+				intr_info->intr_cnt++;
+			}
+		}
+
+		/* Clear interrupt status. */
+		mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_PD_AP_DL_L2TISAR0,
+				l2risar0);
+	}
+
+	mtk_dpmaif_drv_clr_ip_busy_sts(drv_info);
+
+	return 0;
+}
+
+static int mtk_dpmaif_drv_irq_src2(struct dpmaif_drv_info *drv_info,
+				   struct dpmaif_drv_intr_info *intr_info)
+{
+	u32 ori_l2tisar0, l2tisar0, l2timr0;
+	static u32 cnt;
+	u8 q_mask;
+	u32 val;
+
+	ori_l2tisar0 = mtk_dpmaif_drv_get_ul_lv2_sts(drv_info);
+	l2timr0 = mtk_dpmaif_drv_get_ul_intr_mask(drv_info);
+
+	/* Check and process interrupt. */
+	l2tisar0 = ori_l2tisar0 & (~l2timr0);
+	if (l2tisar0) {
+		cnt = 0;
+		val = l2tisar0 & DPMAIF_UL_INT_QDONE;
+		if (val) {
+			q_mask = val >> DP_UL_INT_DONE_OFFSET & DPMAIF_ULQS;
+			mtk_dpmaif_drv_ul_mask_multi_tx_done_intr(drv_info, q_mask);
+			intr_info->intr_types[intr_info->intr_cnt] = DPMAIF_INTR_UL_DONE;
+			intr_info->intr_queues[intr_info->intr_cnt] = val >> DP_UL_INT_DONE_OFFSET;
+			intr_info->intr_cnt++;
+		} else {
+			mtk_dpmaif_drv_ul_mask_intr(drv_info, l2tisar0);
+		}
+
+		/* clear interrupt status */
+		mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base + DPMAIF_PD_AP_UL_L2TISAR0,
+				l2tisar0);
+	}
+
+	mtk_dpmaif_drv_clr_ip_busy_sts(drv_info);
+
+	return 0;
+}
+
+static int mtk_dpmaif_drv_irq_src4(struct dpmaif_drv_info *drv_info,
+				   struct dpmaif_drv_intr_info *intr_info)
+{
+	intr_info->intr_types[intr_info->intr_cnt] = DPMAIF_INTR_TRAS_SYNC;
+	intr_info->intr_cnt++;
+
+	return 0;
+}
+
+static u32 mtk_dpmaif_drv_irq_src6_filter(struct dpmaif_drv_info *drv_info,
+					  u32 l2risar1, u32 l2rimr1)
+{
+	if (l2rimr1 & DPMAIF_DL_INT_DLQ2_QDONE_MSK)
+		l2risar1 &= ~DPMAIF_DL2_INT_DLQ2_QDONE;
+
+	if (l2rimr1 & DPMAIF_DL_INT_DLQ2_PITCNT_LEN_ERR_MSK)
+		l2risar1 &= ~DPMAIF_DL2_INT_DLQ2_PITCNT_LEN_ERR;
+
+	if (l2rimr1 & DPMAIF_DL2_INT_BATCNT_LEN_ERR_MSK)
+		l2risar1 &= ~DPMAIF_DL2_INT_BATCNT_LEN_ERR;
+
+	return l2risar1;
+}
+
+static int mtk_dpmaif_drv_irq_src3(struct dpmaif_drv_info *drv_info,
+				   struct dpmaif_drv_intr_info *intr_info)
+{
+	u32 val, ori_l2risar1, l2risar1, l2rimr1;
+
+	ori_l2risar1 = mtk_dpmaif_drv_get_dl_lv2_sts(drv_info, DPMAIF_DLQ2);
+	l2rimr1 = mtk_dpmaif_drv_get_dl_intr_mask(drv_info, DPMAIF_DLQ2);
+
+	/* filter care interrupt status. */
+	l2risar1 = ori_l2risar1 & (DPMAIF_DL2_INT_DLQ2_QDONE | DPMAIF_DL2_INT_BATCNT_LEN_ERR |
+			DPMAIF_DL2_INT_DLQ2_PITCNT_LEN_ERR);
+
+	if (l2risar1) {
+		/* Filter to get DL unmasked interrupts */
+		l2risar1 = mtk_dpmaif_drv_irq_src6_filter(drv_info, l2risar1, l2rimr1);
+
+		val = l2risar1 & DPMAIF_DL2_INT_BATCNT_LEN_ERR;
+		if (val) {
+			intr_info->intr_types[intr_info->intr_cnt] = DPMAIF_INTR_DL_BATCNT_LEN_ERR;
+			intr_info->intr_queues[intr_info->intr_cnt] = DPMAIF_BAT1;
+			intr_info->intr_cnt++;
+			mtk_dpmaif_drv_mask_dl_batcnt_len_err_intr(drv_info, DPMAIF_BAT1);
+		}
+
+		val = l2risar1 & DPMAIF_DL2_INT_DLQ2_PITCNT_LEN_ERR;
+		if (val) {
+			intr_info->intr_types[intr_info->intr_cnt] = DPMAIF_INTR_DL_PITCNT_LEN_ERR;
+			intr_info->intr_queues[intr_info->intr_cnt] = DPMAIF_DLQ2;
+			intr_info->intr_cnt++;
+			mtk_dpmaif_drv_dlq_mask_pit_cnt_len_err_intr(drv_info, DPMAIF_DLQ2);
+		}
+
+		val = l2risar1 & DPMAIF_DL2_INT_DLQ2_QDONE;
+		if (val) {
+			if (!mtk_dpmaif_drv_dlq_mask_rx_done_intr(drv_info, DPMAIF_DLQ2)) {
+				intr_info->intr_types[intr_info->intr_cnt] = DPMAIF_INTR_DL_DONE;
+				intr_info->intr_queues[intr_info->intr_cnt] = DPMAIF_DLQ2;
+				intr_info->intr_cnt++;
+			}
+		}
+
+		/* Clear interrupt status. */
+		mtk_pci_write32(drv_info->mdev, drv_info->regs->pd_base +
+				NRL2_DPMAIF_AP_MISC_APDL_L2TISAR1, l2risar1);
+	}
+
+	mtk_dpmaif_drv_clr_ip_busy_sts(drv_info);
+
+	return 0;
+}
+
+static int mtk_dpmaif_drv_init_m9xx(struct dpmaif_drv_info *drv_info, void *data)
+{
+	int ret;
+
+	mtk_dpmaif_drv_cfg_get(drv_info);
+	mtk_dpmaif_drv_reset(drv_info);
+	ret = mtk_dpmaif_drv_init_com(drv_info, data);
+
+	return ret;
+}
+
+struct dpmaif_drv_ops dpmaif_drv_ops_m9xx = {
+	.init = mtk_dpmaif_drv_init_m9xx,
+	.start_queue = mtk_dpmaif_drv_start_queue,
+	.stop_queue = mtk_dpmaif_drv_stop_queue,
+	.intr_handle = mtk_dpmaif_drv_intr_handle_com,
+	.intr_complete = mtk_dpmaif_drv_intr_complete_com,
+	.send_doorbell = mtk_dpmaif_drv_send_doorbell_com,
+	.get_ring_idx = mtk_dpmaif_drv_get_ring_idx,
+	.get_rx_info = mtk_dpmaif_get_rx_info,
+	.fill_tx_info = mtk_dpmaif_fill_tx_info,
+};
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_reg.h b/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_reg.h
new file mode 100644
index 000000000000..6c40d4ff5a04
--- /dev/null
+++ b/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_reg.h
@@ -0,0 +1,387 @@
+/* SPDX-License-Identifier: GPL-2.0-only
+ *
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#ifndef __MTK_DPMAIF_REG_H__
+#define __MTK_DPMAIF_REG_H__
+
+/* 2ms -> 2 * 1000 / 10 = 200 */
+#define POLL_MAX_TIMES		200
+#define POLL_INTERVAL_US	10
+#define REWRITE_TIMES		20
+
+/* dpmaif pd domain regisers */
+#define DPMAIF_AO_BASE			0
+#define BASE_NADDR_NRL2_DPMAIF_AO_UL		((unsigned long)(DPMAIF_AO_BASE))
+#define BASE_NADDR_NRL2_DPMAIF_AO_DL		((unsigned long)(DPMAIF_AO_BASE + 0x400))
+
+/* dpmaif uplink */
+#define NRL2_DPMAIF_AO_UL_INIT_SET		(BASE_NADDR_NRL2_DPMAIF_AO_UL + 0x0)
+#define NRL2_DPMAIF_AO_UL_CHNL_ARB0		(BASE_NADDR_NRL2_DPMAIF_AO_UL + 0x1C)
+#define NRL2_DPMAIF_AO_UL_AP_L2TIMR0		(BASE_NADDR_NRL2_DPMAIF_AO_UL + 0x80)
+#define NRL2_DPMAIF_AO_UL_AP_L2TIMCR0		(BASE_NADDR_NRL2_DPMAIF_AO_UL + 0x84)
+#define NRL2_DPMAIF_AO_UL_AP_L2TIMSR0		(BASE_NADDR_NRL2_DPMAIF_AO_UL + 0x88)
+#define NRL2_DPMAIF_AO_UL_AP_L1TIMR0		(BASE_NADDR_NRL2_DPMAIF_AO_UL + 0x8C)
+#define NRL2_DPMAIF_AO_UL_APDL_L2TIMR0		(BASE_NADDR_NRL2_DPMAIF_AO_UL + 0x90)
+#define NRL2_DPMAIF_AO_UL_APDL_L2TIMCR0		(BASE_NADDR_NRL2_DPMAIF_AO_UL + 0x94)
+#define NRL2_DPMAIF_AO_UL_APDL_L2TIMSR0		(BASE_NADDR_NRL2_DPMAIF_AO_UL + 0x98)
+#define NRL2_DPMAIF_AO_UL_AP_DL_UL_IP_BUSY_MASK	(BASE_NADDR_NRL2_DPMAIF_AO_UL + 0x9C)
+
+/* dpmaif downlink. */
+#define NRL2_DPMAIF_AO_DL_INIT_SET		(BASE_NADDR_NRL2_DPMAIF_AO_DL + 0x0)
+#define NRL2_DPMAIF_AO_DL_LROPIT_INIT_CON5	(BASE_NADDR_NRL2_DPMAIF_AO_DL + 0x28)
+#define NRL2_DPMAIF_AO_DL_LROPIT_TRIG_THRES	(BASE_NADDR_NRL2_DPMAIF_AO_DL + 0x34)
+
+/* dpmaif uplink config. */
+#define DPMAIF_PD_UL_CHNL_ARB0		NRL2_DPMAIF_AO_UL_CHNL_ARB0
+
+#define DPMAIF_PD_AP_UL_L2TIMR0		NRL2_DPMAIF_AO_UL_AP_L2TIMR0
+#define DPMAIF_PD_AP_UL_L2TICR0		NRL2_DPMAIF_AO_UL_AP_L2TIMCR0
+#define DPMAIF_PD_AP_UL_L2TISR0		NRL2_DPMAIF_AO_UL_AP_L2TIMSR0
+
+#define DPMAIF_PD_AP_DL_L2TIMR0		NRL2_DPMAIF_AO_UL_APDL_L2TIMR0
+#define DPMAIF_PD_AP_DL_L2TICR0		NRL2_DPMAIF_AO_UL_APDL_L2TIMCR0
+#define DPMAIF_PD_AP_DL_L2TISR0		NRL2_DPMAIF_AO_UL_APDL_L2TIMSR0
+
+#define DPMAIF_PD_AP_DLUL_IP_BUSY_MASK	NRL2_DPMAIF_AO_UL_AP_DL_UL_IP_BUSY_MASK
+
+/* dpmaif pd domain regisers */
+#define DPMAIF_PD_BASE			0
+#define BASE_NADDR_NRL2_DPMAIF_UL	((unsigned long)(DPMAIF_PD_BASE))
+#define BASE_NADDR_NRL2_DPMAIF_DL	((unsigned long)(DPMAIF_PD_BASE + 0x100))
+#define BASE_NADDR_NRL2_DPMAIF_AP_MISC	((unsigned long)(DPMAIF_PD_BASE + 0x400))
+#define BASE_NADDR_NRL2_DPMAIF_PD_SRAM_UL	((unsigned long)(DPMAIF_PD_BASE + 0xD00))
+#define BASE_NADDR_NRL2_DPMAIF_PD_SRAM_DL	((unsigned long)(DPMAIF_PD_BASE + 0xC00))
+#define BASE_NADDR_NRL2_DPMAIF_DL_LRO_REMOVEAO_IDX	((unsigned long)(DPMAIF_PD_BASE + 0x900))
+#define BASE_NADDR_NRL2_DPMAIF_MMW_HPC		((unsigned long)(DPMAIF_PD_BASE + 0x600))
+
+/* dpmaif uplink . */
+#define NRL2_DPMAIF_UL_DBG_STA2		(BASE_NADDR_NRL2_DPMAIF_UL + 0x88)
+#define NRL2_DPMAIF_UL_RESERVE_AO_RW	(BASE_NADDR_NRL2_DPMAIF_UL + 0xAC)
+#define NRL2_DPMAIF_UL_ADD_DESC_CH0	(BASE_NADDR_NRL2_DPMAIF_UL + 0xB0)
+#define NRL2_DPMAIF_UL_ADD_DESC_CH4	(BASE_NADDR_NRL2_DPMAIF_UL + 0xE0)
+
+/* dpmaif downlink. */
+#define NRL2_DPMAIF_DL_BAT_INIT			(BASE_NADDR_NRL2_DPMAIF_DL + 0x00)
+#define NRL2_DPMAIF_DL_BAT_ADD			(BASE_NADDR_NRL2_DPMAIF_DL + 0x04)
+#define NRL2_DPMAIF_DL_BAT_INIT_CON0		(BASE_NADDR_NRL2_DPMAIF_DL + 0x08)
+#define NRL2_DPMAIF_DL_BAT_INIT_CON1		(BASE_NADDR_NRL2_DPMAIF_DL + 0x0C)
+#define NRL2_DPMAIF_DL_PIT_INIT_CON5		(BASE_NADDR_NRL2_DPMAIF_DL + 0x14)
+#define NRL2_DPMAIF_DL_PIT_INIT			(BASE_NADDR_NRL2_DPMAIF_DL + 0x20)
+#define NRL2_DPMAIF_DL_PIT_ADD			(BASE_NADDR_NRL2_DPMAIF_DL + 0x24)
+#define NRL2_DPMAIF_DL_PIT_INIT_CON0		(BASE_NADDR_NRL2_DPMAIF_DL + 0x28)
+#define NRL2_DPMAIF_DL_PIT_INIT_CON1		(BASE_NADDR_NRL2_DPMAIF_DL + 0x2C)
+#define NRL2_DPMAIF_DL_PIT_INIT_CON2		(BASE_NADDR_NRL2_DPMAIF_DL + 0x30)
+#define NRL2_DPMAIF_DL_PIT_INIT_CON3		(BASE_NADDR_NRL2_DPMAIF_DL + 0x34)
+#define NRL2_DPMAIF_DL_BAT_INIT_CON3		(BASE_NADDR_NRL2_DPMAIF_DL + 0x50)
+#define NRL2_DPMAIF_DL_PIT_INIT_CON4		(BASE_NADDR_NRL2_DPMAIF_DL + 0x54)
+#define NRL2_DPMAIF_DL_UL_INTR_TRAS_CON		(BASE_NADDR_NRL2_DPMAIF_DL + 0xAC)
+#define NRL2_DPMAIF_DL_DBG_STA1			(BASE_NADDR_NRL2_DPMAIF_DL + 0xB4)
+
+/* dpmaif misc. */
+#define NRL2_DPMAIF_AP_MISC_AP_L2TISAR0		(BASE_NADDR_NRL2_DPMAIF_AP_MISC + 0x00)
+#define NRL2_DPMAIF_AP_MISC_APDL_L2TISAR0	(BASE_NADDR_NRL2_DPMAIF_AP_MISC + 0x50)
+#define NRL2_DPMAIF_AP_MISC_AP_IP_BUSY		(BASE_NADDR_NRL2_DPMAIF_AP_MISC + 0x60)
+#define NRL2_DPMAIF_AP_MISC_CG_EN		(BASE_NADDR_NRL2_DPMAIF_AP_MISC + 0x68)
+#define NRL2_DPMAIF_AP_MISC_OVERWRITE_CFG	(BASE_NADDR_NRL2_DPMAIF_AP_MISC + 0x90)
+#define NRL2_DPMAIF_AP_MISC_MEM_CLR		(BASE_NADDR_NRL2_DPMAIF_AP_MISC + 0x94)
+
+/* dpmaif uplink sram. */
+#define NRL2_DPMAIF_AO_UL_CHNL0_CON0		(BASE_NADDR_NRL2_DPMAIF_PD_SRAM_UL + 0x10)
+#define NRL2_DPMAIF_AO_UL_CHNL0_CON1		(BASE_NADDR_NRL2_DPMAIF_PD_SRAM_UL + 0x14)
+#define NRL2_DPMAIF_AO_UL_CHNL0_CON2		(BASE_NADDR_NRL2_DPMAIF_PD_SRAM_UL + 0x18)
+
+/* dpmaif downlink sram. */
+#define NRL2_DPMAIF_AO_DL_PKTINFO_CON0		(BASE_NADDR_NRL2_DPMAIF_PD_SRAM_DL + 0x0)
+#define NRL2_DPMAIF_AO_DL_PKTINFO_CON1		(BASE_NADDR_NRL2_DPMAIF_PD_SRAM_DL + 0x4)
+#define NRL2_DPMAIF_AO_DL_PKTINFO_CON2		(BASE_NADDR_NRL2_DPMAIF_PD_SRAM_DL + 0x8)
+#define NRL2_DPMAIF_AO_DL_RDY_CHK_THRES		(BASE_NADDR_NRL2_DPMAIF_PD_SRAM_DL + 0xC)
+#define NRL2_DPMAIF_AO_DL_RDY_CHK_FRG_THRES	(BASE_NADDR_NRL2_DPMAIF_PD_SRAM_DL + 0x10)
+#define NRL2_DPMAIF_AO_DL_LRO_AGG_CFG		(BASE_NADDR_NRL2_DPMAIF_PD_SRAM_DL + 0x20)
+#define NRL2_DPMAIF_AO_DL_LROPIT_TIMEOUT0	(BASE_NADDR_NRL2_DPMAIF_PD_SRAM_DL + 0x24)
+#define NRL2_DPMAIF_AO_DL_LROPIT_TIMEOUT1	(BASE_NADDR_NRL2_DPMAIF_PD_SRAM_DL + 0x28)
+#define NRL2_DPMAIF_AO_DL_HPC_CNTL		(BASE_NADDR_NRL2_DPMAIF_PD_SRAM_DL + 0x38)
+#define NRL2_DPMAIF_AO_DL_PIT_SEQ_END		(BASE_NADDR_NRL2_DPMAIF_PD_SRAM_DL + 0x40)
+#define NRL2_DPMAIF_AO_DL_BAT_STA2		(BASE_NADDR_NRL2_DPMAIF_PD_SRAM_DL + 0xD8)
+#define NRL2_DPMAIF_AO_DL_BAT_STA3		(BASE_NADDR_NRL2_DPMAIF_PD_SRAM_DL + 0xDC)
+#define NRL2_DPMAIF_AO_DL_PIT_STA2		(BASE_NADDR_NRL2_DPMAIF_PD_SRAM_DL + 0xEC)
+#define NRL2_DPMAIF_AO_DL_PIT_STA3		(BASE_NADDR_NRL2_DPMAIF_PD_SRAM_DL + 0x60)
+#define NRL2_DPMAIF_AO_DL_FRGBAT_STA2		(BASE_NADDR_NRL2_DPMAIF_PD_SRAM_DL + 0x78)
+#define NRL2_DPMAIF_AO_DL_LRO_STA5		(BASE_NADDR_NRL2_DPMAIF_PD_SRAM_DL + 0xA4)
+#define NRL2_DPMAIF_AO_DL_LRO_STA6		(BASE_NADDR_NRL2_DPMAIF_PD_SRAM_DL + 0xA8)
+
+/* dpmaif hpc. */
+#define NRL2_DPMAIF_HPC_INTR_MASK		(BASE_NADDR_NRL2_DPMAIF_MMW_HPC + 0xF4)
+
+/* dpmaif LRO. */
+#define NRL2_DPMAIF_DL_LROPIT_INIT		(BASE_NADDR_NRL2_DPMAIF_DL_LRO_REMOVEAO_IDX + 0x0)
+#define NRL2_DPMAIF_DL_LROPIT_ADD		(BASE_NADDR_NRL2_DPMAIF_DL_LRO_REMOVEAO_IDX + 0x10)
+#define NRL2_DPMAIF_DL_LROPIT_INIT_CON0		(BASE_NADDR_NRL2_DPMAIF_DL_LRO_REMOVEAO_IDX + 0x14)
+#define NRL2_DPMAIF_DL_LROPIT_INIT_CON1		(BASE_NADDR_NRL2_DPMAIF_DL_LRO_REMOVEAO_IDX + 0x18)
+#define NRL2_DPMAIF_DL_LROPIT_INIT_CON2		(BASE_NADDR_NRL2_DPMAIF_DL_LRO_REMOVEAO_IDX + 0x1C)
+#define NRL2_DPMAIF_DL_LROPIT_INIT_CON3		(BASE_NADDR_NRL2_DPMAIF_DL_LRO_REMOVEAO_IDX + 0x20)
+#define NRL2_DPMAIF_DL_LROPIT_INIT_CON4		(BASE_NADDR_NRL2_DPMAIF_DL_LRO_REMOVEAO_IDX + 0x24)
+#define NRL2_DPMAIF_DL_LROPIT_INIT_CON5		(BASE_NADDR_NRL2_DPMAIF_DL_LRO_REMOVEAO_IDX + 0x28)
+#define NRL2_DPMAIF_DL_LROPIT_INIT_CON6		(BASE_NADDR_NRL2_DPMAIF_DL_LRO_REMOVEAO_IDX + 0x2C)
+
+/* dpmaif uplink config. */
+#define DPMAIF_PD_UL_CHNL0_CON0		NRL2_DPMAIF_AO_UL_CHNL0_CON0
+#define DPMAIF_PD_UL_CHNL0_CON1		NRL2_DPMAIF_AO_UL_CHNL0_CON1
+#define DPMAIF_PD_UL_CHNL0_CON2		NRL2_DPMAIF_AO_UL_CHNL0_CON2
+#define DPMAIF_PD_UL_ADD_DESC_CH	NRL2_DPMAIF_UL_ADD_DESC_CH0
+#define DPMAIF_PD_UL_DBG_STA2		NRL2_DPMAIF_UL_DBG_STA2
+
+/* dpmaif downlink config. */
+#define DPMAIF_PD_DL_BAT_INIT		NRL2_DPMAIF_DL_BAT_INIT
+#define DPMAIF_PD_DL_BAT_ADD		NRL2_DPMAIF_DL_BAT_ADD
+#define DPMAIF_PD_DL_BAT_INIT_CON0	NRL2_DPMAIF_DL_BAT_INIT_CON0
+#define DPMAIF_PD_DL_BAT_INIT_CON1	NRL2_DPMAIF_DL_BAT_INIT_CON1
+#define DPMAIF_PD_DL_BAT_INIT_CON3	NRL2_DPMAIF_DL_BAT_INIT_CON3
+#define DPMAIF_PD_DL_DBG_STA1		NRL2_DPMAIF_DL_DBG_STA1
+#define DPMAIF_PD_DL_UL_TRAS_INTR_CON   NRL2_DPMAIF_DL_UL_INTR_TRAS_CON
+
+/* dpmaif pd ap misc, ul misc config. */
+#define DPMAIF_PD_AP_UL_L2TISAR0	NRL2_DPMAIF_AP_MISC_AP_L2TISAR0
+#define DPMAIF_PD_AP_DL_L2TISAR0	NRL2_DPMAIF_AP_MISC_APDL_L2TISAR0
+#define DPMAIF_PD_AP_IP_BUSY		NRL2_DPMAIF_AP_MISC_AP_IP_BUSY
+
+/* dpmaif dl config. */
+#define DPMAIF_AO_DL_PKTINFO_CONO	NRL2_DPMAIF_AO_DL_PKTINFO_CON0
+#define DPMAIF_AO_DL_PKTINFO_CON1	NRL2_DPMAIF_AO_DL_PKTINFO_CON1
+#define DPMAIF_AO_DL_PKTINFO_CON2	NRL2_DPMAIF_AO_DL_PKTINFO_CON2
+#define DPMAIF_AO_DL_RDY_CHK_THRES	NRL2_DPMAIF_AO_DL_RDY_CHK_THRES
+#define DPMAIF_AO_DL_BAT_STA2		NRL2_DPMAIF_AO_DL_BAT_STA2
+#define DPMAIF_AO_DL_BAT_STA3		NRL2_DPMAIF_AO_DL_BAT_STA3
+#define DPMAIF_AO_DL_PIT_STA2		NRL2_DPMAIF_AO_DL_PIT_STA2
+#define DPMAIF_AO_DL_PIT_STA3		NRL2_DPMAIF_AO_DL_PIT_STA3
+#define DPMAIF_AO_DL_FRG_CHK_THRES	NRL2_DPMAIF_AO_DL_RDY_CHK_FRG_THRES
+#define DPMAIF_AO_DL_FRG_STA2		NRL2_DPMAIF_AO_DL_FRGBAT_STA2
+
+#define NRL2_DPMAIF_DLY_IRQ_TIMER3		(BASE_NADDR_NRL2_DPMAIF_PD_SRAM_UL + 0x1C)
+#define NRL2_DPMAIF_DLY_IRQ_TIMER4		(BASE_NADDR_NRL2_DPMAIF_PD_SRAM_UL + 0x2C)
+#define NRL2_DPMAIF_DLY_IRQ_TIMER5		(BASE_NADDR_NRL2_DPMAIF_PD_SRAM_UL + 0x3C)
+#define NRL2_DPMAIF_DLY_IRQ_TIMER6		(BASE_NADDR_NRL2_DPMAIF_PD_SRAM_UL + 0x60)
+#define NRL2_DPMAIF_DLY_IRQ_TIMER7		(BASE_NADDR_NRL2_DPMAIF_PD_SRAM_UL + 0x64)
+#define NRL2_DPMAIF_AO_DL_DLY_IRQ_TIMER1	(BASE_NADDR_NRL2_DPMAIF_PD_SRAM_DL + 0x58)
+#define NRL2_DPMAIF_AO_DL_DLY_IRQ_TIMER2	(BASE_NADDR_NRL2_DPMAIF_PD_SRAM_DL + 0x5C)
+
+/* dpmaif dl2 config. */
+#define BASE_ADDR_NRL2_DPMAIF_DL_2_CFG			0x1000UL
+
+#define BASE_ADDR_MMW_DPMAIF_PD_MISC2_CFG		0xF00UL
+
+#define BASE_ADDR_NRL2_DPMAIF_AP_MISC_CFG		0x400UL
+#define BASE_ADDR_MMW_DPMAIF_PD_MISC_CFG		0xE00UL
+#define BASE_ADDR_NRL2_DPMAIF_DL_2_CFG_SRAM		0UL
+
+#define DPMAIF_DL_RESOURCE_DOMAIN			(BASE_ADDR_NRL2_DPMAIF_DL_2_CFG_SRAM + 0x8)
+
+#define DPMAIF_DL_2_BAT_INIT_CON0                (BASE_ADDR_NRL2_DPMAIF_DL_2_CFG + 0x08)
+#define DPMAIF_DL_2_BAT_INIT_CON3                (BASE_ADDR_NRL2_DPMAIF_DL_2_CFG + 0x50)
+#define DPMAIF_DL_2_BAT_INIT_CON1                (BASE_ADDR_NRL2_DPMAIF_DL_2_CFG + 0x0C)
+#define DPMAIF_DL_2_BAT_INIT                     (BASE_ADDR_NRL2_DPMAIF_DL_2_CFG + 0x00)
+#define DPMAIF_DL_2_PIT_INIT_CON0                (BASE_ADDR_NRL2_DPMAIF_DL_2_CFG + 0x28)
+#define DPMAIF_DL_2_PIT_INIT_CON4                (BASE_ADDR_NRL2_DPMAIF_DL_2_CFG + 0x54)
+#define DPMAIF_DL_2_PIT_INIT_CON1                (BASE_ADDR_NRL2_DPMAIF_DL_2_CFG + 0x2C)
+#define DPMAIF_DL_2_PIT_INIT_CON3                (BASE_ADDR_NRL2_DPMAIF_DL_2_CFG + 0x34)
+#define DPMAIF_DL_2_PIT_INIT                     (BASE_ADDR_NRL2_DPMAIF_DL_2_CFG + 0x20)
+#define DPMAIF_DL_2_STA13                        (BASE_ADDR_NRL2_DPMAIF_DL_2_CFG + 0x18)
+#define DPMAIF_DL_2_STA14                        (BASE_ADDR_NRL2_DPMAIF_DL_2_CFG + 0x1C)
+#define DPMAIF_DL_2_STA4                         (BASE_ADDR_NRL2_DPMAIF_DL_2_CFG + 0x90)
+#define DPMAIF_DL_2_BAT_ADD                      (BASE_ADDR_NRL2_DPMAIF_DL_2_CFG + 0x04)
+#define DPMAIF_DL_2_PIT_ADD                      (BASE_ADDR_NRL2_DPMAIF_DL_2_CFG + 0x24)
+
+#define NRL2_DPMAIF_AP_MISC_APDL_L2TISAR1        (BASE_ADDR_NRL2_DPMAIF_AP_MISC_CFG + 0x54)
+
+#define NRL2_DPMAIF_MISC_PD_APDL12_MASK_SET		(BASE_ADDR_MMW_DPMAIF_PD_MISC_CFG + 0x60)
+#define NRL2_DPMAIF_MISC_PD_APDL12_MASK_CLR		(BASE_ADDR_MMW_DPMAIF_PD_MISC_CFG + 0x64)
+#define NRL2_DPMAIF_MISC_PD_APDL12_MASK_RW		(BASE_ADDR_MMW_DPMAIF_PD_MISC_CFG + 0x68)
+
+#define DPMAIF_ULQS			0x1F
+#define DPMAIF_UL_ADD_NOT_READY		BIT(31)
+#define DPMAIF_UL_ADD_UPDATE		BIT(31)
+#define DPMAIF_UL_ALL_QUE_ARB_EN	(DPMAIF_ULQS << 8)
+
+#define DPMAIF_DL_ADD_UPDATE		BIT(31)
+#define DPMAIF_DL_ADD_NOT_READY		BIT(31)
+#define DPMAIF_DL_FRG_ADD_UPDATE	BIT(16)
+
+#define DPMAIF_DL_BAT_INIT_ALLSET	BIT(0)
+#define DPMAIF_DL_BAT_FRG_INIT		BIT(16)
+#define DPMAIF_DL_BAT_INIT_EN		BIT(31)
+#define DPMAIF_DL_BAT_INIT_NOT_READY	BIT(31)
+#define DPMAIF_DL_BAT_INIT_ONLY_ENABLE_BIT	0
+
+#define DPMAIF_DL_PIT_INIT_ALLSET	BIT(0)
+#define DPMAIF_DL_PIT_INIT_EN		BIT(31)
+#define DPMAIF_DL_PIT_INIT_NOT_READY	BIT(31)
+
+#define DPMAIF_PKT_ALIGN64_MODE		0
+#define DPMAIF_PKT_ALIGN128_MODE	1
+
+#define DPMAIF_BAT_REMAIN_SZ_BASE	16
+#define DPMAIF_BAT_BUFFER_SZ_BASE	128
+#define DPMAIF_FRG_BUFFER_SZ_BASE	128
+
+#define DPMAIF_PIT_SIZE_MSK		0x3FFFF
+
+#define DPMAIF_BAT_EN_MSK		BIT(16)
+#define DPMAIF_FRG_EN_MSK		BIT(28)
+#define DPMAIF_BAT_SIZE_MSK		0xFFFF
+
+#define DPMAIF_BAT_BID_MAXCNT_MSK	0xFFFF0000
+#define DPMAIF_BAT_REMAIN_MINSZ_MSK	0x0000FF00
+#define DPMAIF_PIT_CHK_NUM_MSK		0xFF000000
+#define DPMAIF_BAT_BUF_SZ_MSK		0x0001FF00
+#define DPMAIF_FRG_BUF_SZ_MSK		0x0001FF00
+#define DPMAIF_BAT_RSV_LEN_MSK		0x000000FF
+#define DPMAIF_PKT_ALIGN_MSK		(0x3 << 22)
+
+#define DPMAIF_BAT_CHECK_THRES_MSK	(0x3F << 16)
+#define DPMAIF_FRG_CHECK_THRES_MSK	0xFF
+#define DPMAIF_PKT_ALIGN_EN		BIT(23)
+#define DPMAIF_DRB_SIZE_MSK		0x0000FFFF
+
+#define DPMAIF_DL_PIT_WRIDX_MSK		0x3FFFF
+#define DPMAIF_DL_BAT_WRIDX_MSK		0x3FFFF
+#define DPMAIF_DL_FRG_WRIDX_MSK		0x3FFFF
+
+/* DPMAIF_PD_UL_DBG_STA2 */
+#define DPMAIF_UL_IDLE_STS_MSK		BIT(11)
+#define DPMAIF_UL_IDLE_STS		BIT(11)
+
+/* DPMAIF_PD_DL_DBG_STA1 */
+#define DPMAIF_DL_IDLE_STS		BIT(23)
+#define DPMAIF_DL_PKT_CHECKSUM_EN	BIT(31)
+#define DPMAIF_PORT_MODE_MSK		BIT(30)
+#define DPMAIF_PORT_MODE_PCIE		BIT(30)
+
+/* BASE_NADDR_NRL2_DPMAIF_WDMA */
+#define DPMAIF_DL_BAT_CACHE_PRI		BIT(22)
+#define DPMAIF_DL_BURST_PIT_EN		BIT(13)
+#define DPMAIF_MEM_CLR_MASK		BIT(0)
+#define DPMAIF_SRAM_SYNC_MASK		BIT(0)
+#define DPMAIF_UL_INIT_DONE_MASK	BIT(0)
+#define DPMAIF_DL_INIT_DONE_MASK	BIT(0)
+
+#define DPMAIF_DL_PIT_SEQ_MSK		0xFF
+#define DPMAIF_PCIE_MODE_SET_VALUE	0x55
+
+#define DPMAIF_UDL_IP_BUSY_MSK		BIT(0)
+
+#define DP_UL_INT_DONE_OFFSET		0
+#define DP_UL_INT_EMPTY_OFFSET		5
+#define DP_UL_INT_MD_NOTRDY_OFFSET	10
+#define DP_UL_INT_PWR_NOTRDY_OFFSET	15
+#define DP_UL_INT_LEN_ERR_OFFSET	20
+
+/* Enable and mask/unmaks UL interrupt mask */
+#define DPMAIF_UL_INT_QDONE_MSK			(DPMAIF_ULQS << DP_UL_INT_DONE_OFFSET)
+#define DPMAIF_UL_TOP0_INT_MSK			BIT(9)
+#define DPMAIF_UL_INT_VALID_MSK			0x1FFFFFF
+#define DPMAIF_UL3_INT_VALID_MSK		0x3FFFFFFF
+
+/* UL interrupt status */
+#define DPMAIF_UL_INT_QDONE		(DPMAIF_ULQS << DP_UL_INT_DONE_OFFSET)
+
+/* Enable and  Mask/unmask DL interrupt mask */
+#define DPMAIF_DL_INT_DLQ_QDONE_MSK		BIT(0)
+#define DPMAIF_DL_INT_BATCNT_LEN_ERR_MSK	BIT(2)
+#define DPMAIF_DL_INT_DLQ_PITCNT_LEN_ERR_MSK	BIT(3)
+#define DPMAIF_DL_INT_DLQ0_QDONE_MSK		BIT(8)
+#define DPMAIF_DL_INT_DLQ1_QDONE_MSK		BIT(9)
+#define DPMAIF_DL_INT_DLQ0_PITCNT_LEN_ERR_MSK	BIT(10)
+#define DPMAIF_DL_INT_DLQ1_PITCNT_LEN_ERR_MSK	BIT(11)
+#define DPMAIF_DL_INT_Q2TOQ1_MSK		BIT(24)
+#define DPMAIF_DL_INT_Q2APTOP_MSK		BIT(25)
+#define DPMAIF_DL_INT_VALID_MSK			0x1FFF
+
+/* DL interrupt status */
+#define DPMAIF_DL_INT_DLQ_QDONE			BIT(0)
+#define DPMAIF_DL_INT_BATCNT_LEN_ERR		BIT(2)
+#define DPMAIF_DL_INT_DLQ_PITCNT_LEN_ERR	BIT(3)
+#define DPMAIF_DL_INT_DLQ0_PITCNT_LEN_ERR	BIT(8)
+#define DPMAIF_DL_INT_DLQ1_PITCNT_LEN_ERR	BIT(9)
+#define DPMAIF_DL_INT_DLQ0_QDONE		BIT(13)
+#define DPMAIF_DL_INT_DLQ1_QDONE		BIT(14)
+
+/* DPMAIF LRO HW configure */
+#define DPMAIF_HPC_LRO_PATH_DF			3
+
+/* 0: HPC rules add by HW; 1: HPC rules add by Host */
+#define DPMAIF_HPC_ADD_MODE_DF			0
+#define DPMAIF_HPC_NUM_DF			8
+#define DPMAIF_AGG_MAX_LEN_DF			65535
+#define DPMAIF_AGG_TBL_ENT_NUM_DF		50
+#define DPMAIF_HASH_PRIME_DF			13
+#define DPMAIF_MID_TIMEOUT_THRES_DF		100
+#define DPMAIF_LRO_TIMEOUT_THRES_DF		100
+#define DPMAIF_LRO_PRS_THRES_DF			10
+#define DPMAIF_LRO_HASH_BIT_CHOOSE_DF		0
+
+#define DPMAIF_LROPIT_EN_MSK			0x100000
+#define DPMAIF_LROPIT_CHAN_OFS			16
+#define DPMAIF_ADD_LRO_PIT_CHAN_OFS		20
+
+#define DPMAIF_DL_PIT_BYTE_SIZE		16
+#define DPMAIF_DL_BAT_BYTE_SIZE		8
+#define DPMAIF_DL_FRG_BYTE_SIZE		8
+#define DPMAIF_UL_DRB_BYTE_SIZE		16
+
+#define DPMAIF_UL_DRB_ENTRY_WORD	(DPMAIF_UL_DRB_BYTE_SIZE >> 2)
+#define DPMAIF_DL_PIT_ENTRY_WORD	(DPMAIF_DL_PIT_BYTE_SIZE >> 2)
+#define DPMAIF_DL_BAT_ENTRY_WORD	(DPMAIF_DL_BAT_BYTE_SIZE >> 2)
+
+#define DPMAIF_HW_BAT_REMAIN		64
+#define DPMAIF_HW_PKT_BIDCNT		1
+
+#define DPMAIF_HW_CHK_BAT_NUM		62
+#define DPMAIF_HW_CHK_FRG_NUM		DPMAIF_HW_CHK_BAT_NUM
+#define DPMAIF_HW_CHK_PIT_NUM		(2 * DPMAIF_HW_CHK_BAT_NUM)
+
+#define DPMAIF_DL_2_BAT_WRIDX_MSK   0xFFFF
+#define DPMAIF_DL2_PIT_EN_MSK       BIT(0)
+
+/* Mask/unmask DL2 interrupt mask */
+#define DPMAIF_DL_INT_DLQ2_QDONE_MSK            BIT(0)
+#define DPMAIF_DL2_INT_BATCNT_LEN_ERR_MSK       BIT(2)
+#define DPMAIF_DL_INT_DLQ2_PITCNT_LEN_ERR_MSK   BIT(3)
+#define DPMAIF_DL2_INT_OTHER_MSK                0xFF00FF
+
+/* DL2 interrupt status */
+#define DPMAIF_DL2_INT_DLQ2_QDONE           BIT(0)
+#define DPMAIF_DL2_INT_BATCNT_LEN_ERR       BIT(2)
+#define DPMAIF_DL2_INT_DLQ2_PITCNT_LEN_ERR  BIT(3)
+#define DLQ2_INTR_MSK                       0xFF
+
+#define DPMAIF_HASH_DEFAULT_VALUE	0
+#define DPMAIF_HASH_DEFAULT_V_MASK  0xFFFFFF00
+
+void mtk_dpmaif_drv_ul_mask_intr(struct dpmaif_drv_info *drv_info, u32 mask);
+void mtk_dpmaif_drv_dlq_mask_pit_cnt_len_err_intr(struct dpmaif_drv_info *drv_info, u8 qno);
+void mtk_dpmaif_drv_mask_dl_batcnt_len_err_intr(struct dpmaif_drv_info *drv_info, u8 bat_id);
+void mtk_dpmaif_drv_ul_mask_multi_tx_done_intr(struct dpmaif_drv_info *drv_info, u8 q_mask);
+u32 mtk_dpmaif_drv_get_dl_lv2_sts(struct dpmaif_drv_info *drv_info, u8 q_id);
+u32 mtk_dpmaif_drv_get_dl_intr_mask(struct dpmaif_drv_info *drv_info, u8 q_id);
+int mtk_dpmaif_drv_dlq_mask_rx_done_intr(struct dpmaif_drv_info *drv_info, u8 q_id);
+u32 mtk_dpmaif_drv_get_ul_lv2_sts(struct dpmaif_drv_info *drv_info);
+void mtk_dpmaif_drv_clr_ip_busy_sts(struct dpmaif_drv_info *drv_info);
+int mtk_dpmaif_drv_ul_intr_init(struct dpmaif_drv_info *drv_info);
+
+u32 mtk_dpmaif_drv_get_ul_intr_mask(struct dpmaif_drv_info *drv_info);
+
+int mtk_dpmaif_drv_init_com(struct dpmaif_drv_info *drv_info, void *data);
+int mtk_dpmaif_drv_start_queue(struct dpmaif_drv_info *drv_info,
+			       enum dpmaif_drv_dir dir);
+int mtk_dpmaif_drv_stop_queue(struct dpmaif_drv_info *drv_info,
+			      enum dpmaif_drv_dir dir);
+int mtk_dpmaif_drv_intr_complete_com(struct dpmaif_drv_info *drv_info,
+				     enum dpmaif_drv_intr_type type, u8 id, u64 data);
+int mtk_dpmaif_drv_send_doorbell_com(struct dpmaif_drv_info *drv_info,
+				     enum dpmaif_drv_ring_type type, u8 id, u32 cnt);
+int mtk_dpmaif_drv_get_ring_idx(struct dpmaif_drv_info *drv_info,
+				enum dpmaif_drv_ring_idx index, u8 q_id);
+int mtk_dpmaif_drv_intr_handle_com(struct dpmaif_drv_info *drv_info, void *data, u8 irq_id);
+
+#endif
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_reg_m9xx.h b/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_reg_m9xx.h
new file mode 100644
index 000000000000..808d0cc0e6dc
--- /dev/null
+++ b/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_reg_m9xx.h
@@ -0,0 +1,37 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+#ifndef __MTK_DPMAIF_DRV_M9XX_H__
+#define __MTK_DPMAIF_DRV_M9XX_H__
+
+#include "mtk_dpmaif_reg.h"
+
+#define DPMAIF_DEV_PD_BASE		0x1022D000
+#define DPMAIF_DEV_PD2_BASE		0x10260000
+#define DPMAIF_DEV_AO_BASE		0x10011000
+
+#define NRL2_DPMAIF_AO_UL_CH0_STA	(BASE_NADDR_NRL2_DPMAIF_PD_SRAM_UL + 0xE0)
+
+/* DPMAIF AO register */
+#define DPMAIF_AP_RGU_ASSERT		0x10001120
+#define DPMAIF_AP_RGU_DEASSERT		0x10001124
+#define DPMAIF_AP_RST_BIT		BIT(4)
+#define DPMAIF_AP_AO_RGU_ASSERT		0x10001140
+#define DPMAIF_AP_AO_RGU_DEASSERT	0x10001144
+#define DPMAIF_AP_AO_RST_BIT		BIT(3)
+#define DPMAIF_AP_INFRA_CG_CLR          0x100010E0
+#define DPMAIF_AP_INFRA_CG_SET          0x100010E4
+#define DPMAIF_AP_INFRA_CG_BIT          BIT(15)
+#define DPMAIF_AP_INFRA_GLITCH_PORT     0x10001208
+#define DPMAIF_AP_GLITCH_PROT_BIT       BIT(15)
+#define DPMAIF_AP_PD_SRAM_EN_BIT	BIT(31)
+
+#define NRL2_DPMAIF_AP_MISC_SRAM_INIT_SET0		(BASE_NADDR_NRL2_DPMAIF_AP_MISC + 0xC0)
+#define NRL2_DPMAIF_AP_MISC_SRAM_INIT_SET1		(BASE_NADDR_NRL2_DPMAIF_AP_MISC + 0xC4)
+#define DPMAIF_PD_AP_UL_L2TIMR0_NEXT			(BASE_ADDR_MMW_DPMAIF_PD_MISC2_CFG + 0x60)
+#define DPMAIF_PD_AP_UL_L2TICR0_NEXT			(BASE_ADDR_MMW_DPMAIF_PD_MISC2_CFG + 0x5C)
+#define DPMAIF_PD_AP_UL_L2TISR0_NEXT			(BASE_ADDR_MMW_DPMAIF_PD_MISC2_CFG + 0x58)
+
+#define NRL2_DPMAIF_PD_DL_LROPIT_TIMEOUT5       0x40
+
+#define DPMAIF_HPC_NUM_EXT		8
+#define DPMAIF_HPC_NUM_M9XX		(DPMAIF_HPC_NUM_DF + DPMAIF_HPC_NUM_EXT)
+#endif
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_ring.c b/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_ring.c
new file mode 100644
index 000000000000..a8e183b5f4ee
--- /dev/null
+++ b/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_ring.c
@@ -0,0 +1,168 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#define pr_fmt(fmt) "DATA_RING:" fmt
+
+#include <linux/delay.h>
+#include <linux/bitfield.h>
+#include <linux/kernel.h>
+#include <linux/printk.h>
+#include "mtk_dpmaif_drv.h"
+#include "mtk_dpmaif_ring.h"
+
+#define PIT_PD_DATA_LEN		GENMASK(31, 16) /* Indicates the data length of current packet. */
+#define PIT_PD_BUF_ID		GENMASK(15, 3) /* The low order of buffer index */
+#define PIT_PD_BUF_TYPE		BIT(2) /* 0b: normal BAT entry; 1b: fragment BAT entry */
+#define PIT_PD_CONT		BIT(1) /* 0b: last entry; 1b: more entry */
+#define PIT_PD_PKT_TYPE		BIT(0) /* 0b: normal PIT entry; 1b: message PIT entry */
+
+#define PIT_PD_DLQ_DONE		GENMASK(31, 30)
+#define PIT_PD_ULQ_DONE		GENMASK(29, 24)
+/* The header length of transport layer and internet layer. */
+#define PIT_PD_HD_OFFSET	GENMASK(23, 19)
+#define PIT_PD_BI_F		GENMASK(18, 17)
+#define PIT_PD_IG		BIT(16)
+#define PIT_PD_RSV		GENMASK(15, 11)
+#define PIT_PD_H_BID		GENMASK(10, 8) /* The high order of buffer index */
+#define PIT_PD_SEQ		GENMASK(7, 0) /* PIT sequence */
+
+#define PIT_MSG_DP		BIT(31) /* Indicates software to drop this packet if set. */
+#define PIT_MSG_DW1_RSV1	GENMASK(30, 27)
+#define PIT_MSG_NET_TYPE	GENMASK(26, 24)
+#define PIT_MSG_CHNL_ID		GENMASK(23, 16) /* channel index */
+#define PIT_MSG_DW1_RSV2	GENMASK(15, 12)
+#define PIT_MSG_HPC_IDX		GENMASK(11, 8)
+#define PIT_MSG_SRC_QID		GENMASK(7, 5)
+#define PIT_MSG_ERR		BIT(4)
+#define PIT_MSG_CHECKSUM	GENMASK(3, 2)
+#define PIT_MSG_CONT		BIT(1) /* 0b: last entry; 1b: more entry */
+#define PIT_MSG_PKT_TYPE	BIT(0) /* 0b: normal PIT entry; 1b: message PIT entry */
+
+#define PIT_MSG_HP_IDX		GENMASK(31, 27)
+#define PIT_MSG_CMD		GENMASK(26, 24)
+#define PIT_MSG_DW2_RSV		GENMASK(23, 21)
+#define PIT_MSG_FLOW		GENMASK(20, 16)
+#define PIT_MSG_COUNT_L		GENMASK(15, 0)
+
+#define PIT_MSG_HASH		GENMASK(31, 24) /* Hash value calculated by Hardware using packet */
+#define PIT_MSG_DW3_RSV1	GENMASK(23, 18)
+#define PIT_MSG_PRO		GENMASK(17, 16)
+#define PIT_MSG_VBID		GENMASK(15, 3)
+#define PIT_MSG_DW3_RSV2	GENMASK(2, 0)
+
+#define PIT_MSG_DLQ_DONE	GENMASK(31, 30)
+#define PIT_MSG_ULQ_DONE	GENMASK(29, 24)
+#define PIT_MSG_IP		BIT(23)
+#define PIT_MSG_DW4_RSV1	BIT(22)
+#define PIT_MSG_MR		GENMASK(21, 20)
+#define PIT_MSG_DW4_RSV2	GENMASK(19, 17)
+#define PIT_MSG_IG		BIT(16)
+#define PIT_MSG_DW4_RSV3	GENMASK(15, 11)
+#define PIT_MSG_H_BID		GENMASK(10, 8)
+#define PIT_MSG_PIT_SEQ		GENMASK(7, 0)
+
+#define DPMAIF_POLL_STEP 20
+#define DPMAIF_POLL_PIT_CNT_MAX 100
+
+#define DRB_MSG_PKT_LEN		GENMASK(31, 16) /* The length of a whole packet. */
+#define DRB_MSG_DW1_RSV		GENMASK(15, 3)
+#define DRB_MSG_CONT		BIT(2) /* 0b: last entry; 1b: more entry */
+#define DRB_MSG_DTYP		GENMASK(1, 0) /* 00b: normal DRB entry; 01b: message DRB entry */
+
+#define DRB_MSG_DW2_RSV1	GENMASK(31, 30)
+#define DRB_MSG_L4_CHK		BIT(29) /* 0b: disable layer4 checksum offload; 1b: enable */
+#define DRB_MSG_IP_CHK		BIT(28) /* 0b: disable IP checksum, 1b: enable IP checksum */
+#define DRB_MSG_DW2_RSV2	BIT(27)
+#define DRB_MSG_NET_TYPE	GENMASK(26, 24)
+#define DRB_MSG_CHNL_ID		GENMASK(23, 16) /* channel index */
+#define DRB_MSG_COUNT_L		GENMASK(15, 0)
+
+#define DRB_PD_DATA_LEN		GENMASK(31, 16) /* the length of a payload. */
+#define DRB_PD_RSV		GENMASK(15, 3)
+#define DRB_PD_CONT		BIT(2)/* 0b: last entry; 1b: more entry */
+#define DRB_PD_DTYP		GENMASK(1, 0) /* 00b: normal DRB entry; 01b: message DRB entry. */
+
+int mtk_dpmaif_get_rx_info(void *pit, struct dpmaif_rx_info *rx_info, u32 pit_seq_expect,
+			   u8 q_id)
+{
+	struct dpmaif_pd_pit *pd_pit = (struct dpmaif_pd_pit *)pit;
+	int ret = -DATA_PIT_SEQ_CHK_FAIL;
+	struct dpmaif_msg_pit *msg_pit;
+	u64 dma_addr;
+	u32 cnt = 0;
+
+	/* The longest check time is 2ms, step is 20us */
+	do {
+		rx_info->pit_pd_seq = FIELD_GET(PIT_PD_SEQ, le32_to_cpu(pd_pit->pd_footer));
+		if (rx_info->pit_pd_seq == pit_seq_expect) {
+			ret = 0;
+			break;
+		}
+
+		udelay(DPMAIF_POLL_STEP);
+	} while (++cnt < DPMAIF_POLL_PIT_CNT_MAX);
+
+	if (unlikely(ret < 0))
+		goto out;
+
+	rx_info->msg_pit = FIELD_GET(PIT_PD_PKT_TYPE, le32_to_cpu(pd_pit->pd_header));
+	if (rx_info->msg_pit) {
+		msg_pit = (struct dpmaif_msg_pit *)pit;
+		rx_info->pit_msg_chnl_id = FIELD_GET(PIT_MSG_CHNL_ID, le32_to_cpu(msg_pit->dword1));
+		rx_info->pit_msg_checksum = FIELD_GET(PIT_MSG_CHECKSUM,
+						      le32_to_cpu(msg_pit->dword1));
+		rx_info->pit_msg_err = FIELD_GET(PIT_MSG_ERR, le32_to_cpu(msg_pit->dword1));
+		rx_info->pit_msg_dp = FIELD_GET(PIT_MSG_DP, le32_to_cpu(msg_pit->dword1));
+		rx_info->pit_msg_hash = FIELD_GET(PIT_MSG_HASH, le32_to_cpu(msg_pit->dword3));
+		rx_info->pit_msg_pro = FIELD_GET(PIT_MSG_PRO, le32_to_cpu(msg_pit->dword3));
+		rx_info->pit_msg_ip = FIELD_GET(PIT_MSG_IP, le32_to_cpu(msg_pit->dword4));
+	} else {
+		rx_info->normal_bat = FIELD_GET(PIT_PD_BUF_TYPE, le32_to_cpu(pd_pit->pd_header));
+		rx_info->pit_pd_cur_bid = (FIELD_GET(PIT_PD_H_BID,
+				le32_to_cpu(pd_pit->pd_footer)) << 13) +
+				FIELD_GET(PIT_PD_BUF_ID, le32_to_cpu(pd_pit->pd_header));
+		rx_info->pit_pd_data_len = FIELD_GET(PIT_PD_DATA_LEN,
+						     le32_to_cpu(pd_pit->pd_header));
+		rx_info->pit_pd_hd_offset = FIELD_GET(PIT_PD_HD_OFFSET,
+						      le32_to_cpu(pd_pit->pd_footer)) << 2;
+		rx_info->pit_continue = FIELD_GET(PIT_PD_CONT,
+						  le32_to_cpu(pd_pit->pd_header));
+		dma_addr = le32_to_cpu(pd_pit->addr_high);
+		rx_info->pit_pd_dma_addr = (dma_addr << 32) + le32_to_cpu(pd_pit->addr_low);
+	}
+
+out:
+	return ret;
+}
+
+void mtk_dpmaif_fill_tx_info(void *drb, struct dpmaif_tx_info *tx_info, int type)
+{
+	struct dpmaif_msg_drb *msg_drb;
+	struct dpmaif_pd_drb *pd_drb;
+
+	if (type == MSG_DRB) {
+		msg_drb = (struct dpmaif_msg_drb *)drb;
+		msg_drb->msg_header1 = cpu_to_le32(FIELD_PREP(DRB_MSG_DTYP, MSG_DRB) |
+			       FIELD_PREP(DRB_MSG_CONT, DPMAIF_DRB_MORE) |
+			       FIELD_PREP(DRB_MSG_PKT_LEN, tx_info->msg_pkt_len));
+		msg_drb->msg_header2 = cpu_to_le32(FIELD_PREP(DRB_MSG_COUNT_L,
+							      tx_info->msg_count_l) |
+			FIELD_PREP(DRB_MSG_CHNL_ID, tx_info->msg_channel_id) |
+			FIELD_PREP(DRB_MSG_L4_CHK, tx_info->msg_txcsum) |
+			FIELD_PREP(DRB_MSG_NET_TYPE, tx_info->msg_network_type));
+	} else {
+		pd_drb = (struct dpmaif_pd_drb *)drb;
+		pd_drb->pd_header = cpu_to_le32(FIELD_PREP(DRB_PD_DTYP, PD_DRB));
+		if (tx_info->pd_is_last)
+			pd_drb->pd_header |= cpu_to_le32(FIELD_PREP(DRB_PD_CONT,
+					DPMAIF_DRB_LASTONE));
+		else
+			pd_drb->pd_header |= cpu_to_le32(FIELD_PREP(DRB_PD_CONT, DPMAIF_DRB_MORE));
+
+		pd_drb->pd_header |= cpu_to_le32(FIELD_PREP(DRB_PD_DATA_LEN, tx_info->pd_data_len));
+		pd_drb->addr_low = cpu_to_le32(lower_32_bits(tx_info->pd_data_dma_addr));
+		pd_drb->addr_high = cpu_to_le32(upper_32_bits(tx_info->pd_data_dma_addr));
+	}
+}
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_ring.h b/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_ring.h
new file mode 100644
index 000000000000..20db9be37cac
--- /dev/null
+++ b/drivers/net/wwan/t9xx/pcie/mtk_dpmaif_ring.h
@@ -0,0 +1,161 @@
+/* SPDX-License-Identifier: GPL-2.0-only
+ *
+ * Copyright (c) 2022, MediaTek Inc.
+ */
+
+#ifndef __MTK_DPMAIF_RING_H__
+#define __MTK_DPMAIF_RING_H__
+
+#include <linux/bitops.h>
+#include <linux/types.h>
+
+/* drb c_bit */
+#define DPMAIF_DRB_LASTONE	0x00
+#define DPMAIF_DRB_MORE		0x01
+
+/* pit c_bit */
+#define DPMAIF_PIT_LASTONE	0x00
+#define DPMAIF_PIT_MORE		0x01
+
+/* pit Pro_bit */
+#define DPMAIF_PIT_TCP 0x01
+#define DPMAIF_PIT_UDP 0x02
+
+/* pit IP_bit */
+#define DPMAIF_PIT_IPV4 0x00
+#define DPMAIF_PIT_IPV6 0x01
+
+enum dpmaif_rcsum_state {
+	CS_RESULT_INVALID = -1,
+	CS_RESULT_PASS = 0,
+	CS_RESULT_FAIL = 1,
+	CS_RESULT_NOTSUPP = 2,
+	CS_RESULT_RSV = 3
+};
+
+/* pit type */
+enum dpmaif_pit_type {
+	PD_PIT = 0,
+	MSG_PIT,
+};
+
+/* RX: buffer address table */
+struct dpmaif_bat {
+	__le32 buf_addr_low;
+	__le32 buf_addr_high;
+};
+
+struct dpmaif_rx_info {
+	u32 pit_pd_seq;
+	u32 msg_pit;
+	u32 pit_msg_chnl_id;
+	u32 pit_msg_checksum;
+	u32 pit_msg_err;
+	u32 pit_msg_dp;
+	u32 pit_msg_hash;
+	u32 pit_msg_pro;
+	u32 pit_msg_ip;
+	u32 normal_bat;
+	u32 pit_pd_cur_bid;
+	u32 pit_pd_data_len;
+	u32 pit_pd_hd_offset;
+	u32 pit_continue;
+	u64 pit_pd_dma_addr;
+};
+
+struct dpmaif_pd_pit {
+	__le32 pd_header;
+	__le32 addr_low;
+	__le32 addr_high;
+	__le32 pd_footer;
+};
+
+struct dpmaif_msg_pit {
+	__le32 dword1;
+	__le32 dword2;
+	__le32 dword3;
+	__le32 dword4;
+};
+
+struct dpmaif_tx_info {
+	u32 msg_pkt_len;
+	u16 msg_count_l;
+	u16 msg_network_type;
+	u8 msg_channel_id;
+	u8 msg_txcsum;
+	dma_addr_t pd_data_dma_addr;
+	u32 pd_data_len;
+	u8 pd_is_last;
+};
+
+struct dpmaif_msg_drb {
+	__le32 msg_header1;
+	__le32 msg_header2;
+	__le32 msg_rsv1;
+	__le32 msg_rsv2;
+};
+
+struct dpmaif_pd_drb {
+	__le32 pd_header;
+	__le32 addr_low;
+	__le32 addr_high;
+	__le32 pd_rsv;
+};
+
+/* drb->type */
+enum dpmaif_drb_type {
+	PD_DRB,
+	MSG_DRB,
+};
+
+static inline unsigned int mtk_dpmaif_ring_buf_get_next_idx(unsigned int buf_len,
+							    unsigned int buf_idx)
+{
+	buf_idx++;
+
+	return buf_idx < buf_len ? buf_idx : 0;
+}
+
+static inline unsigned int mtk_dpmaif_ring_buf_readable(unsigned int total_cnt, unsigned int rd_idx,
+							unsigned int  wr_idx)
+{
+	unsigned int pkt_cnt;
+
+	if (wr_idx >= rd_idx)
+		pkt_cnt = wr_idx - rd_idx;
+	else
+		pkt_cnt = total_cnt + wr_idx - rd_idx;
+
+	return pkt_cnt;
+}
+
+static inline unsigned int mtk_dpmaif_ring_buf_writable(unsigned int total_cnt,
+							unsigned int rel_idx, unsigned int wr_idx)
+{
+	unsigned int pkt_cnt;
+
+	if (wr_idx < rel_idx)
+		pkt_cnt = rel_idx - wr_idx - 1;
+	else
+		pkt_cnt = total_cnt + rel_idx - wr_idx - 1;
+
+	return pkt_cnt;
+}
+
+static inline unsigned int mtk_dpmaif_ring_buf_releasable(unsigned int total_cnt,
+							  unsigned int rel_idx, unsigned int rd_idx)
+{
+	unsigned int pkt_cnt;
+
+	if (rel_idx <= rd_idx)
+		pkt_cnt = rd_idx - rel_idx;
+	else
+		pkt_cnt = total_cnt + rd_idx - rel_idx;
+
+	return pkt_cnt;
+}
+
+int mtk_dpmaif_get_rx_info(void *pit, struct dpmaif_rx_info *rx_info, u32 pit_seq_expect, u8 q_id);
+void mtk_dpmaif_fill_tx_info(void *drb, struct dpmaif_tx_info *tx_info, int type);
+
+#endif
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_pci.h b/drivers/net/wwan/t9xx/pcie/mtk_pci.h
index 700879f9b21e..bb657aa786b6 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_pci.h
+++ b/drivers/net/wwan/t9xx/pcie/mtk_pci.h
@@ -22,6 +22,7 @@ enum mtk_irq_src {
 	MTK_IRQ_SRC_PM_LOCK,
 	MTK_IRQ_SRC_DPMAIF3,
 	MTK_IRQ_SRC_DPMAIF6,
+	MTK_IRQ_SRC_TRAS_SYNC,
 	MTK_IRQ_SRC_MAX
 };
 
diff --git a/drivers/net/wwan/t9xx/pcie/mtk_pci_drv_m9xx.c b/drivers/net/wwan/t9xx/pcie/mtk_pci_drv_m9xx.c
index 88b44142afb7..560a3b81a279 100644
--- a/drivers/net/wwan/t9xx/pcie/mtk_pci_drv_m9xx.c
+++ b/drivers/net/wwan/t9xx/pcie/mtk_pci_drv_m9xx.c
@@ -64,6 +64,7 @@ const struct mtk_pci_dev_cfg mtk_dev_cfg_0900 = {
 		[MTK_IRQ_SRC_PM_LOCK] = 0,
 		[MTK_IRQ_SRC_DPMAIF3] = 7,
 		[MTK_IRQ_SRC_DPMAIF6]  = 10,
+		[MTK_IRQ_SRC_TRAS_SYNC] = 9,
 	},
 	.atr_init = mtk_pci_atr_init_m9xx,
 };

-- 
2.34.1

