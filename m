From: Cody Kang <codykang.hk@gmail.com>
Date: Sat, 21 Nov 2026 15:40:48 +0800
Subject: [PATCH v3 09/17] drm/spacemit: add Saturn DPU hardware backend
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-k3-display-v3-9-ec419e8e96b8@gmail.com>
References: <20261121-k3-display-v3-0-ec419e8e96b8@gmail.com>
In-Reply-To: <20261121-k3-display-v3-0-ec419e8e96b8@gmail.com>
To: David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Yixun Lan <dlan@kernel.org>, 
 Troy Mitchell <troy.mitchell@linux.spacemit.com>, 
 Vinod Koul <vkoul@kernel.org>, Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Haylen Chu <heylenay@4d2.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Yao Zi <me@ziyao.cc>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@baylibre.com>, 
 Guodong Xu <docular.xu@gmail.com>, Icenowy Zheng <uwu@icenowy.me>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Sarah Emery <sarah.emery@canonical.com>, 
 Ze Huang <ze.huang@oss.qualcomm.com>, Dmitry Baryshkov <lumag@kernel.org>
Cc: Cody Kang <codykang@vsit.ai>, dri-devel@lists.freedesktop.org, 
 linux-riscv@lists.infradead.org, devicetree@vger.kernel.org, 
 spacemit@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-phy@lists.infradead.org, linux-clk@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795246844; l=42709;
 i=codykang.hk@gmail.com; s=codykang; h=from:subject:message-id;
 bh=qChsrT0cXJkz/NJbjnnlAxplnDwndu/8I5rGsubNLbw=;
 b=NEBrSgZLvNrrbCy1pgvZ/pRz5xroAogvwOtWVxVNPNbguRamPydxSRtWwI8aXsOwqH6r1edrY
 PF86aB5LSd1AvhkFKXOIv5+OsCnjaNaCQsjy07Pqjd2weLegBYjQoej
X-Developer-Key: i=codykang.hk@gmail.com; a=ed25519;
 pk=Osn6/cs9Su/mHHw4P19cmVc3v2FMQfiWahjsN0vEkuk=
X-Endpoint-Received: by B4 Relay for codykang.hk@gmail.com/codykang with auth_id=895
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Cody Kang <codykang@vsit.ai>

Add the register-level programming of one Saturn instance: clock and
reset bring-up, scene control and timing generator setup, RDMA channel
and composer layer programming, RDMA line-buffer sizing, interrupt
dispatch and the CFG_RDY/vsync handshake that paces commits. The KMS
layer calls the backend directly.

Signed-off-by: Cody Kang <codykang@vsit.ai>

---
v3:
- drop the tracepoints (Thomas Zimmermann)
- drop the ops table and inline the forwarding helpers (Thomas
  Zimmermann)
- drop the constant-fill path; the plane always uses RDMA channel 0
  (Thomas Zimmermann)
- size the RDMA line buffer per plane instead of arbitrating between
  channels (Thomas Zimmermann)
- submit only the compose list from the CRTC flush; the planes' lists
  are no longer sorted and submitted there (Thomas Zimmermann)
- arm the commit's event from the CFG_RDY interrupt and deliver it
  through the vblank machinery (Thomas Zimmermann)
- leave the DPU's pixel clock at the rate it has; on DP and eDP the PHY
  PLL is the pixel clock (Guodong Xu)
- return IRQ_NONE when no status bit was pending, disable the clocks in
  reverse enable order, drop a stray dma_rmb() and definitions nothing
  reads
- commit message: drop the reference to an upcoming patch
v2:
- drop the dead INT_VSYNC_UPDATE clear; the enum member goes away in
  patch 08 (Sashiko)
- drop the cmdlist parameter from saturn_hee_crtc_cmdlist(), matching
  the crtc_cmdlist op change in patch 08
---
 drivers/gpu/drm/spacemit/dpu/dpu_saturn.c          | 353 +++++++++++
 drivers/gpu/drm/spacemit/dpu/dpu_saturn_hee.c      | 670 +++++++++++++++++++++
 drivers/gpu/drm/spacemit/dpu/saturn_fbcmem.c       |  66 ++
 drivers/gpu/drm/spacemit/dpu/saturn_fbcmem.h       |  16 +
 drivers/gpu/drm/spacemit/dpu/saturn_regs/ops_hee.h |  47 ++
 5 files changed, 1152 insertions(+)

diff --git a/drivers/gpu/drm/spacemit/dpu/dpu_saturn.c b/drivers/gpu/drm/spacemit/dpu/dpu_saturn.c
new file mode 100644
index 0000000000000..704e64fb9ec7e
--- /dev/null
+++ b/drivers/gpu/drm/spacemit/dpu/dpu_saturn.c
@@ -0,0 +1,353 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (C) 2025-2026 SpacemiT Co., Ltd.
+ *
+ */
+
+#include <linux/clk.h>
+#include <linux/iopoll.h>
+#include <linux/regmap.h>
+#include <linux/timer.h>
+#include <linux/types.h>
+
+#include <drm/drm_atomic.h>
+#include <drm/drm_atomic_helper.h>
+#include <drm/drm_fourcc.h>
+#include <drm/drm_print.h>
+#include <drm/drm_vblank.h>
+
+#include "../spacemit_cmdlist.h"
+#include "../spacemit_dmmu.h"
+#include "../spacemit_dpu_ids.h"
+#include "../spacemit_dpu_reg.h"
+#include "../spacemit_drm.h"
+#include "dpu_saturn.h"
+#include "saturn_regs/ops_hee.h"
+
+static const struct dpu_format_id primary_fmts[] = {
+	{ DRM_FORMAT_XRGB8888, 8, 32 },
+	{ DRM_FORMAT_ARGB8888, 4, 32 },
+	{ DRM_FORMAT_XBGR8888, 9, 32 },
+	{ DRM_FORMAT_ABGR8888, 5, 32 },
+	{ DRM_FORMAT_RGBX8888, 10, 32 },
+	{ DRM_FORMAT_RGBA8888, 6, 32 },
+	{ DRM_FORMAT_BGRX8888, 11, 32 },
+	{ DRM_FORMAT_BGRA8888, 7, 32 },
+	{ DRM_FORMAT_ABGR2101010, 1, 32 },
+	{ DRM_FORMAT_RGB888, 12, 24 },
+	{ DRM_FORMAT_BGR888, 13, 24 },
+	{ DRM_FORMAT_RGB565, 22, 16 },
+	{ DRM_FORMAT_BGR565, 23, 16 },
+};
+
+/* Read channels per instance. */
+#define SATURN_HEE_RDMA_NUM	4
+
+/* A commit whose CFG_RDY is not taken within this time is reported. */
+#define SATURN_CFG_RDY_TIMEOUT_MS	3000
+
+/* Wait for the previous CFG_RDY to be consumed before the block is set up. */
+#define SATURN_CFG_IDLE_POLL_US		100
+#define SATURN_CFG_IDLE_TIMEOUT_US	(200 * USEC_PER_MSEC)
+
+static const u32 saturn_hee_fbcmem_sizes[] = {
+	89600, /* 87.5 KiB */
+	15360, /* 15 KiB */
+};
+
+const struct spacemit_hw_device spacemit_k3_saturn_dpu = {
+	.rdma_nums = SATURN_HEE_RDMA_NUM,
+	.n_formats = ARRAY_SIZE(primary_fmts),
+	.formats = primary_fmts,
+	.n_fbcmems = ARRAY_SIZE(saturn_hee_fbcmem_sizes),
+	.fbcmem_sizes = saturn_hee_fbcmem_sizes,
+};
+
+void saturn_enable_irq_mask(struct spacemit_crtc *a_crtc, bool enable,
+			    u32 offset, u32 mask)
+{
+	struct spacemit_drm_private *priv = a_crtc->crtc.dev->dev_private;
+	struct spacemit_hw_device *hwdev = priv->hwdev;
+
+	if (!priv->clocks_on)
+		return;
+
+	regmap_update_bits(hwdev->regmap, offset, mask, enable ? mask : 0);
+}
+
+int spacemit_dpu_parse_clocks(struct device *dev, struct dpu_clk_context *clk_ctx)
+{
+	clk_ctx->pxclk = devm_clk_get(dev, "pxclk");
+	if (IS_ERR(clk_ctx->pxclk))
+		return dev_err_probe(dev, PTR_ERR(clk_ctx->pxclk),
+				     "failed to get pxclk\n");
+
+	clk_ctx->mclk = devm_clk_get(dev, "mclk");
+	if (IS_ERR(clk_ctx->mclk))
+		return dev_err_probe(dev, PTR_ERR(clk_ctx->mclk),
+				     "failed to get mclk\n");
+
+	clk_ctx->escclk = devm_clk_get(dev, "escclk");
+	if (IS_ERR(clk_ctx->escclk))
+		return dev_err_probe(dev, PTR_ERR(clk_ctx->escclk),
+				     "failed to get escclk\n");
+
+	clk_ctx->aclk = devm_clk_get(dev, "aclk");
+	if (IS_ERR(clk_ctx->aclk))
+		return dev_err_probe(dev, PTR_ERR(clk_ctx->aclk),
+				     "failed to get aclk\n");
+
+	clk_ctx->dscclk = devm_clk_get(dev, "dscclk");
+	if (IS_ERR(clk_ctx->dscclk))
+		return dev_err_probe(dev, PTR_ERR(clk_ctx->dscclk),
+				     "failed to get dscclk\n");
+
+	return 0;
+}
+
+/*
+ * Bring @clk to the rate nearest @rate. A clock that refuses is reported and
+ * left as it is: the rates are targets, not requirements.
+ */
+static void spacemit_dpu_clk_set_rate(struct device *dev, struct clk *clk,
+				      unsigned long rate, const char *name)
+{
+	long rounded = clk_round_rate(clk, rate);
+	int ret;
+
+	if (rounded < 0) {
+		dev_warn_ratelimited(dev, "%s: no rate near %lu Hz: %ld\n",
+				     name, rate, rounded);
+		return;
+	}
+
+	ret = clk_set_rate(clk, rounded);
+	if (ret)
+		dev_warn_ratelimited(dev, "%s: failed to set %ld Hz: %d\n",
+				     name, rounded, ret);
+}
+
+int spacemit_dpu_enable_clocks(struct spacemit_drm_private *priv)
+{
+	struct dpu_clk_context *clk_ctx = &priv->clk_ctx;
+	int ret;
+
+	/*
+	 * Rate left alone: the mode's pixel clock is the DP PHY's PLL. This
+	 * input only has to run for the "lcd" reset to reach the DPU.
+	 */
+	ret = clk_prepare_enable(clk_ctx->pxclk);
+	if (ret)
+		goto err;
+
+	ret = clk_prepare_enable(clk_ctx->mclk);
+	if (ret)
+		goto err_pxclk;
+	spacemit_dpu_clk_set_rate(priv->dev, clk_ctx->mclk, DPU_MCLK_DEFAULT,
+				  "mclk");
+
+	/* The escape clock only has to run for the "esc" reset to propagate. */
+	ret = clk_prepare_enable(clk_ctx->escclk);
+	if (ret)
+		goto err_mclk;
+
+	ret = clk_prepare_enable(clk_ctx->aclk);
+	if (ret)
+		goto err_escclk;
+	spacemit_dpu_clk_set_rate(priv->dev, clk_ctx->aclk, DPU_AXICLK_DEFAULT,
+				  "aclk");
+
+	ret = clk_prepare_enable(clk_ctx->dscclk);
+	if (ret)
+		goto err_aclk;
+
+	return 0;
+
+err_aclk:
+	clk_disable_unprepare(clk_ctx->aclk);
+err_escclk:
+	clk_disable_unprepare(clk_ctx->escclk);
+err_mclk:
+	clk_disable_unprepare(clk_ctx->mclk);
+err_pxclk:
+	clk_disable_unprepare(clk_ctx->pxclk);
+err:
+	dev_err(priv->dev, "failed to enable DPU clocks: %d\n", ret);
+	return ret;
+}
+
+void spacemit_dpu_disable_clocks(struct spacemit_drm_private *priv)
+{
+	struct dpu_clk_context *clk_ctx = &priv->clk_ctx;
+
+	clk_disable_unprepare(clk_ctx->dscclk);
+	clk_disable_unprepare(clk_ctx->aclk);
+	clk_disable_unprepare(clk_ctx->escclk);
+	clk_disable_unprepare(clk_ctx->mclk);
+	clk_disable_unprepare(clk_ctx->pxclk);
+}
+
+u8 spacemit_plane_hw_get_format_id(u32 format)
+{
+	unsigned int i;
+
+	for (i = 0; i < ARRAY_SIZE(primary_fmts); i++) {
+		if (primary_fmts[i].format == format)
+			return primary_fmts[i].id;
+	}
+
+	return SPACEMIT_DPU_INVALID_FORMAT_ID;
+}
+
+/* Complete a commit whose lists the engine will not confirm any more. */
+void spacemit_dpu_complete_event(struct spacemit_crtc *a_crtc)
+{
+	struct drm_crtc *crtc = &a_crtc->crtc;
+	struct drm_pending_vblank_event *event;
+	unsigned long flags;
+
+	spin_lock_irqsave(&crtc->dev->event_lock, flags);
+	event = a_crtc->event;
+	a_crtc->event = NULL;
+	if (event)
+		drm_crtc_send_vblank_event(crtc, event);
+	spin_unlock_irqrestore(&crtc->dev->event_lock, flags);
+
+	if (event)
+		drm_crtc_vblank_put(crtc);
+}
+
+void spacemit_cfg_rdy_timer_handler(struct timer_list *t)
+{
+	struct spacemit_crtc *a_crtc = timer_container_of(a_crtc, t,
+							  cfg_rdy_timer);
+
+	drm_err_ratelimited(a_crtc->crtc.dev, "CFG_RDY handshake timeout\n");
+	/* A CFG_RDY that still comes belongs to no commit any more. */
+	saturn_hee_enable_irq(a_crtc, INT_CFG_RDY, false);
+	spacemit_dpu_complete_event(a_crtc);
+}
+
+void spacemit_dpu_init(struct spacemit_crtc *a_crtc,
+		       const struct drm_display_mode *mode)
+{
+	struct spacemit_drm_private *priv = a_crtc->crtc.dev->dev_private;
+	struct spacemit_hw_device *hwdev = priv->hwdev;
+	u32 val;
+
+	if (!priv->clocks_on)
+		return;
+
+	if (read_poll_timeout(saturn_hee_get_cfg_rdy, val, val == 0,
+			      SATURN_CFG_IDLE_POLL_US,
+			      SATURN_CFG_IDLE_TIMEOUT_US, false, a_crtc, hwdev))
+		drm_err(a_crtc->crtc.dev, "wait for cfg ready timed out\n");
+
+	saturn_hee_dpu_init(a_crtc, mode);
+}
+
+void spacemit_dpu_uninit(struct spacemit_crtc *a_crtc)
+{
+	struct spacemit_drm_private *priv = a_crtc->crtc.dev->dev_private;
+
+	if (!priv->clocks_on)
+		return;
+
+	saturn_hee_irq_enable(a_crtc, false);
+}
+
+/* The read channels of the planes this CRTC scans out after the commit. */
+u32 saturn_conf_dpuctrl_rdma(struct drm_atomic_commit *state,
+			     const struct drm_crtc_state *crtc_state)
+{
+	struct drm_plane *plane;
+	u32 rdma_en = 0;
+
+	drm_for_each_plane_mask(plane, crtc_state->crtc->dev,
+				crtc_state->plane_mask) {
+		const struct drm_plane_state *plane_state =
+				drm_atomic_get_new_plane_state(state, plane);
+
+		/* A plane the commit does not touch keeps its current state. */
+		if (!plane_state)
+			plane_state = plane->state;
+		if (plane_state->visible)
+			rdma_en |= BIT(to_spacemit_plane(plane)->rdma_id);
+	}
+
+	return rdma_en;
+}
+
+/* Returns false when none of the pending status bits was this CRTC's. */
+bool spacemit_dpu_online_isr(struct spacemit_crtc *a_crtc)
+{
+	u32 irq_raw, irq_bit, irq_ur_bit, handled;
+	struct spacemit_drm_private *priv = a_crtc->crtc.dev->dev_private;
+	struct spacemit_hw_device *hwdev = priv->hwdev;
+
+	irq_raw = saturn_hee_get_int_sts(hwdev);
+	irq_bit = saturn_hee_get_irq_bit(INT_UNDERRUN);
+	irq_ur_bit = irq_raw & irq_bit;
+	handled = irq_ur_bit;
+	if (irq_ur_bit && !a_crtc->ur_reported) {
+		saturn_hee_clr_int_sts(a_crtc, irq_ur_bit);
+		drm_err_ratelimited(a_crtc->crtc.dev, "underrun\n");
+		a_crtc->ur_reported = true;
+	}
+	irq_bit = saturn_hee_get_irq_bit(INT_CFG_RDY);
+	if (irq_raw & irq_bit) {
+		saturn_hee_clr_int_sts(a_crtc, irq_bit);
+		timer_delete(&a_crtc->cfg_rdy_timer);
+		a_crtc->ur_reported = false;
+		saturn_hee_enable_irq(a_crtc, INT_CFG_RDY, false);
+		handled |= irq_bit;
+
+		/* The lists are taken: the next vblank completes the commit. */
+		spin_lock(&a_crtc->crtc.dev->event_lock);
+		if (a_crtc->event) {
+			drm_crtc_arm_vblank_event(&a_crtc->crtc, a_crtc->event);
+			a_crtc->event = NULL;
+		}
+		spin_unlock(&a_crtc->crtc.dev->event_lock);
+	}
+	irq_bit = saturn_hee_get_irq_bit(INT_VSYNC);
+	if (irq_raw & irq_bit) {
+		saturn_hee_clr_int_sts(a_crtc, irq_bit);
+		drm_crtc_handle_vblank(&a_crtc->crtc);
+		handled |= irq_bit;
+	}
+	irq_bit = saturn_hee_get_irq_bit(INT_REST) | irq_ur_bit;
+	if (irq_raw & irq_bit) {
+		saturn_hee_clr_int_sts(a_crtc, irq_bit);
+		handled |= irq_raw & irq_bit;
+	}
+
+	return handled;
+}
+
+void spacemit_dpu_run(struct drm_crtc *crtc, struct drm_atomic_commit *state)
+{
+	struct spacemit_crtc *a_crtc = to_spacemit_crtc(crtc);
+	struct spacemit_drm_private *priv = a_crtc->crtc.dev->dev_private;
+	struct spacemit_hw_device *hwdev = priv->hwdev;
+
+	saturn_hee_conf_dpuctrl(crtc, state);
+
+	/* flush all config register writes before CFG_RDY is raised */
+	mb();
+
+	/* Ack first: one left by a commit that timed out is not this one's. */
+	saturn_hee_clr_int_sts(a_crtc, saturn_hee_get_irq_bit(INT_CFG_RDY));
+	saturn_hee_enable_irq(a_crtc, INT_CFG_RDY, true);
+
+	mod_timer(&a_crtc->cfg_rdy_timer,
+		  jiffies + msecs_to_jiffies(SATURN_CFG_RDY_TIMEOUT_MS));
+	saturn_hee_cfg_ready(a_crtc, hwdev);
+
+	if (unlikely(a_crtc->is_1st_f)) {
+		drm_dbg(a_crtc->crtc.dev, "DPU start\n");
+		a_crtc->is_1st_f = false;
+		saturn_hee_sw_start(a_crtc, hwdev);
+	}
+}
+
diff --git a/drivers/gpu/drm/spacemit/dpu/dpu_saturn_hee.c b/drivers/gpu/drm/spacemit/dpu/dpu_saturn_hee.c
new file mode 100644
index 0000000000000..1a194fe7cc7ba
--- /dev/null
+++ b/drivers/gpu/drm/spacemit/dpu/dpu_saturn_hee.c
@@ -0,0 +1,670 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (C) 2025-2026 SpacemiT Co., Ltd.
+ *
+ */
+
+#include <linux/regmap.h>
+
+#include <drm/drm_atomic.h>
+#include <drm/drm_blend.h>
+#include <drm/drm_framebuffer.h>
+#include <drm/drm_print.h>
+
+#include "../spacemit_cmdlist.h"
+#include "../spacemit_dmmu.h"
+#include "../spacemit_dpu_ids.h"
+#include "../spacemit_dpu_reg.h"
+#include "dpu_saturn.h"
+#include "saturn_fbcmem.h"
+#include "saturn_regs/ops_hee.h"
+#include "saturn_regs/reg_map_hee.h"
+
+#define SATURN_WRITE_TBU_REGS(hwdev, base, reg_id, cl_tbu) \
+do {\
+	dpu_write(hwdev, MMU_TBU_REG, base, tbu_base_addr##reg_id##_low, \
+		  tbu->ttb_pa[reg_id] & 0xFFFFFFFF, cl_tbu); \
+	dpu_write(hwdev, MMU_TBU_REG, base, tbu_base_addr##reg_id##_high, \
+		  (tbu->ttb_pa[reg_id] >> 32) & 0xFFF, cl_tbu); \
+	dpu_write(hwdev, MMU_TBU_REG, base, tbu_va##reg_id, \
+		 (tbu->tbu_va[reg_id] >> 12), cl_tbu); \
+	dpu_write(hwdev, MMU_TBU_REG, base, \
+		  tbu_size##reg_id, tbu->ttb_size[reg_id], cl_tbu); \
+	dpu_write(hwdev, MMU_TBU_REG, base, \
+		  vsync_update_en, 1, cl_tbu); \
+} while (0)
+
+#define SATURN_WRITE_RDMA_ADDR_REG(hwdev, reg_id, rdma_id, addr, cl_rdma) \
+do { \
+	dpu_write(hwdev, RDMA_PATH_X_REG, RDMA_BASE_ADDR[rdma_id], \
+		  base_addr##reg_id##_low_ly0, (addr) & 0xFFFFFFFF, cl_rdma); \
+	dpu_write(hwdev, RDMA_PATH_X_REG, RDMA_BASE_ADDR[rdma_id], \
+		  base_addr##reg_id##_high_ly0, ((addr) >> 32) & 0xFFF, \
+		  cl_rdma); \
+} while (0)
+
+static const u32 RDMA_BASE_ADDR[] = {
+	RDMA0_BASE_ADDR,
+	RDMA1_BASE_ADDR,
+	RDMA2_BASE_ADDR,
+	RDMA3_BASE_ADDR,
+};
+
+static const u32 MMU_TBU_BASE_ADDR_ARRAY[] = {
+	TBU0_ADDR, TBU1_ADDR, TBU2_ADDR, TBU3_ADDR,
+	TBU4_ADDR, TBU5_ADDR, TBU6_ADDR, TBU7_ADDR,
+};
+
+void saturn_hee_enable_irq(struct spacemit_crtc *a_crtc,
+			   enum spacemit_dpu_irq irq_id, bool enable)
+{
+	saturn_enable_irq_mask(a_crtc, enable,
+			       DPU_INT_BASE_ADDR + DPU_ONLINE_IRQ_MSK,
+			       saturn_hee_get_irq_bit(irq_id));
+}
+
+void saturn_hee_cfg_ready(struct spacemit_crtc *a_crtc,
+			  struct spacemit_hw_device *hwdev)
+{
+	u32 base = DPU_SCENE_CTL_ADDR(COMPOSER1);
+
+	saturn_hee_enable_irq(a_crtc, INT_UNDERRUN, true);
+	a_crtc->ur_mask_armed = true;
+	dpu_write(hwdev, DPU_CTL_REG, base, both_cfg_rdy, 1);
+}
+
+void saturn_hee_sw_start(struct spacemit_crtc *a_crtc,
+			 struct spacemit_hw_device *hwdev)
+{
+	u32 base;
+
+	base = DPU_SCENE_CTL_ADDR(COMPOSER1);
+	dpu_write_reg(hwdev, DPU_CTL_REG, base, sw_start, 1);
+}
+
+static void saturn_init_tmg(struct spacemit_crtc *a_crtc,
+			    const struct drm_display_mode *mode)
+{
+	u32 base = TMG0_BASE_ADDR;
+	struct spacemit_drm_private *priv = a_crtc->crtc.dev->dev_private;
+	struct spacemit_hw_device *hwdev = priv->hwdev;
+	u16 vfp, vbp, vsync, hfp, hbp, hsync;
+	void __iomem *tmg_addr;
+	u32 value;
+
+	tmg_addr = hwdev->base + TMG0_BASE_ADDR;
+
+	hsync = mode->hsync_end - mode->hsync_start;
+	hbp = mode->htotal - mode->hsync_end;
+	hfp = mode->hsync_start - mode->hdisplay;
+	vsync = mode->vsync_end - mode->vsync_start;
+	vbp = mode->vtotal - mode->vsync_end;
+	vfp = mode->vsync_start - mode->vdisplay;
+	drm_dbg(a_crtc->crtc.dev, "timing " DRM_MODE_FMT "\n", DRM_MODE_ARG(mode));
+
+	dpu_write(hwdev, TMG_REG, base, disp_ready_man_en, 0);
+	dpu_write(hwdev, TMG_REG, base, background_r, 0);
+	dpu_write(hwdev, TMG_REG, base, background_g, 0x0);
+	dpu_write(hwdev, TMG_REG, base, background_b, 0xff);
+	dpu_write(hwdev, TMG_REG, base, eof_1st_ln_dly_num, vfp - 7);
+	dpu_write(hwdev, TMG_REG, base, eof_2nd_ln_dly_num, vfp - 6);
+	dpu_write(hwdev, TMG_REG, base, split_en, 0);
+	dpu_write(hwdev, TMG_REG, base, cmd_screen, 0);
+	dpu_write(hwdev, TMG_REG, base, cmd_wait_en, 0);
+	dpu_write(hwdev, TMG_REG, base, cmd_wait_te, 0);
+	dpu_write(hwdev, TMG_REG, base, sof_pre_ln_num, 0);
+	dpu_write(hwdev, TMG_REG, base, hfp, hfp);
+	dpu_write(hwdev, TMG_REG, base, hbp, hbp);
+	dpu_write(hwdev, TMG_REG, base, vfp, vfp);
+	dpu_write(hwdev, TMG_REG, base, vbp, vbp);
+	dpu_write(hwdev, TMG_REG, base, hsync_width, hsync);
+	dpu_write(hwdev, TMG_REG, base, vsync_width, vsync);
+	dpu_write(hwdev, TMG_REG, base, hsp, 1);
+	dpu_write(hwdev, TMG_REG, base, vsp, 1);
+	dpu_write(hwdev, TMG_REG, base, h_active, mode->hdisplay);
+	dpu_write(hwdev, TMG_REG, base, v_active, mode->vdisplay);
+	dpu_write(hwdev, TMG_REG, base, fm_timing_en, 1);
+	/* The pipeline always hands RGB888 to the DP/eDP encoder. */
+	dpu_write(hwdev, TMG_REG, base, user, OUTFMT_RGB888);
+
+	value = readl(tmg_addr + 4 * dpu_field_word(TMG_REG, vfp));
+	value &= ~dpu_field_mask(TMG_REG, vfp);
+	value |= vfp;
+	writel(value, tmg_addr + 4 * dpu_field_word(TMG_REG, vfp));
+
+	dpu_write(hwdev, TMG_REG, base, vsync_align_with_hsync, 1);
+}
+
+static void saturn_init_regs(struct spacemit_crtc *a_crtc,
+			     const struct drm_display_mode *mode)
+{
+	struct spacemit_drm_private *priv = a_crtc->crtc.dev->dev_private;
+	struct spacemit_hw_device *hwdev = priv->hwdev;
+	u32 base;
+
+	base = CMP1_BASE_ADDR;
+	dpu_write(hwdev, CMPS_X_REG, base, bg_color_b, 0x0);
+	dpu_write(hwdev, CMPS_X_REG, base, bg_color_r, 0x0);
+	dpu_write(hwdev, CMPS_X_REG, base, bg_color_g, 0x0);
+	dpu_write(hwdev, CMPS_X_REG, base, bg_color_a, 0xFF);
+	dpu_write(hwdev, CMPS_X_REG, base, module_enable, 1);
+	dpu_write(hwdev, CMPS_X_REG, base, layer00_en, 0);
+	dpu_write(hwdev, CMPS_X_REG, base, layer01_en, 0);
+	dpu_write(hwdev, CMPS_X_REG, base, layer02_en, 0);
+	dpu_write(hwdev, CMPS_X_REG, base, layer03_en, 0);
+	dpu_write(hwdev, CMPS_X_REG, base, layer04_en, 0);
+	dpu_write(hwdev, CMPS_X_REG, base, layer05_en, 0);
+	dpu_write(hwdev, CMPS_X_REG, base, layer06_en, 0);
+	dpu_write(hwdev, CMPS_X_REG, base, layer07_en, 0);
+	dpu_write(hwdev, CMPS_X_REG, base, layer08_en, 0);
+	dpu_write(hwdev, CMPS_X_REG, base, layer09_en, 0);
+	dpu_write(hwdev, CMPS_X_REG, base, layer10_en, 0);
+	dpu_write(hwdev, CMPS_X_REG, base, layer11_en, 0);
+	dpu_write(hwdev, CMPS_X_REG, base, layer12_en, 0);
+	dpu_write(hwdev, CMPS_X_REG, base, layer13_en, 0);
+	dpu_write(hwdev, CMPS_X_REG, base, layer14_en, 0);
+	dpu_write(hwdev, CMPS_X_REG, base, layer15_en, 0);
+
+	base = EE_ADDR;
+	dpu_write(hwdev, EE_REG, base, m_benable, 0);
+
+	saturn_init_tmg(a_crtc, mode);
+}
+
+static void saturn_setup_dma_top(struct spacemit_crtc *a_crtc)
+{
+	u32 base = DMA_TOP_BASE_ADDR;
+	struct spacemit_drm_private *priv = a_crtc->crtc.dev->dev_private;
+	struct spacemit_hw_device *hwdev = priv->hwdev;
+
+	dpu_write(hwdev, DMA_TOP_REG, base, image_rr_ratio, 0x10);
+	dpu_write(hwdev, DMA_TOP_REG, base, pixel_num_th, 4);
+
+	dpu_write(hwdev, DMA_TOP_REG, base, rdma_timeout_limit, 0xFFFE);
+	dpu_write(hwdev, DMA_TOP_REG, base, wdma_timeout_limit, 0xFFFF);
+}
+
+static void saturn_setup_mmu_top(struct spacemit_crtc *a_crtc)
+{
+	unsigned int rd_outs_num = RD_OUTS_NUM / 2;
+	u32 base = MMU_TOP_BASE_ADDR;
+	struct spacemit_drm_private *priv = a_crtc->crtc.dev->dev_private;
+	struct spacemit_hw_device *hwdev = priv->hwdev;
+
+	dpu_write(hwdev, MMU_TOP_REG, base, rdma_timelimit, RDMA_TIMELIMIT);
+
+	dpu_write(hwdev, MMU_TOP_REG, base, sram0_tlb_axi_port_sel, 0);
+	dpu_write(hwdev, MMU_TOP_REG, base, sram1_tlb_axi_port_sel, 0);
+	dpu_write(hwdev, MMU_TOP_REG, base, dmac0_rd_outs_num, rd_outs_num);
+	dpu_write(hwdev, MMU_TOP_REG, base, dmac1_rd_outs_num, rd_outs_num);
+}
+
+void saturn_hee_irq_enable(struct spacemit_crtc *a_crtc, bool enable)
+{
+	u32 offset = DPU_INT_BASE_ADDR + DPU_ONLINE_IRQ_MSK;
+	u32 mask;
+
+	mask = saturn_hee_get_irq_bit(INT_UNDERRUN) |
+	       saturn_hee_get_irq_bit(INT_CFG_RDY);
+	if (enable) {
+		struct spacemit_drm_private *priv =
+				a_crtc->crtc.dev->dev_private;
+
+		/*
+		 * Ack first: a surviving status bit would fire as the mask
+		 * opens.
+		 */
+		regmap_write(priv->hwdev->regmap,
+			     DPU_INT_BASE_ADDR + DPU_ONLINE_IRQ_STS, mask);
+	}
+	saturn_enable_irq_mask(a_crtc, enable, offset, mask);
+	a_crtc->ur_mask_armed = enable;
+}
+
+void saturn_hee_dpu_init(struct spacemit_crtc *a_crtc,
+			 const struct drm_display_mode *mode)
+{
+	saturn_init_regs(a_crtc, mode);
+	saturn_setup_dma_top(a_crtc);
+	saturn_setup_mmu_top(a_crtc);
+	saturn_hee_irq_enable(a_crtc, true);
+}
+
+#define SATURN_WRITE_COMPOSER_LAYER(id_name) \
+do {\
+	dpu_write(hwdev, CMPS_X_REG, base, layer ## id_name ## _colorkey_en,	\
+		  0, cl_cmp);					\
+	dpu_write(hwdev, CMPS_X_REG, base, layer ## id_name ## _blend_mode,	\
+		  blend_mode, cl_cmp);				\
+	dpu_write(hwdev, CMPS_X_REG, base, layer ## id_name ## _blend_sel,	\
+		  alpha_sel, cl_cmp);				\
+	dpu_write(hwdev, CMPS_X_REG, base, layer ## id_name ## _layer_alpha,	\
+		  alpha, cl_cmp);					\
+	dpu_write(hwdev, CMPS_X_REG, base, layer ## id_name ## _alpha_ratio,	\
+		  0, cl_cmp);					\
+	dpu_write(hwdev, CMPS_X_REG, base, layer ## id_name ## _area_left,	\
+		  crtc_x, cl_cmp);					\
+	dpu_write(hwdev, CMPS_X_REG, base, layer ## id_name ## _area_top,	\
+		  crtc_y, cl_cmp);					\
+	dpu_write(hwdev, CMPS_X_REG, base, layer ## id_name ## _area_right,	\
+		  crtc_x + crtc_w - 1, cl_cmp);			\
+	dpu_write(hwdev, CMPS_X_REG, base, layer ## id_name ## _area_bottom,	\
+		  crtc_y + crtc_h - 1, cl_cmp);			\
+	dpu_write(hwdev, CMPS_X_REG, base, layer ## id_name ## _solid_en,	\
+		  0, cl_cmp);				\
+	dpu_write(hwdev, CMPS_X_REG, base, layer ## id_name ## _dma_id,	\
+		  rdma_id, cl_cmp);			\
+	dpu_write(hwdev, CMPS_X_REG, base, layer ## id_name ## _en, 1, cl_cmp); \
+} while (0)
+
+static void saturn_write_fbcmem_regs(struct spacemit_hw_device *hwdev,
+				     struct drm_plane_state *state, u32 base,
+				     struct cmdlist_regs *cl_rdma)
+{
+	u32 size = to_spacemit_plane_state(state)->fbcmem_size;
+	u32 val;
+
+	/* The plane owns the front of its bank: the base address stays 0. */
+	val = FIELD_PREP(dpu_field_mask(RDMA_PATH_X_REG, fbc_mem_map), 1) |
+	      FIELD_PREP(dpu_field_mask(RDMA_PATH_X_REG, fbc_mem_size), size);
+	dpu_write_word(hwdev, base,
+		       dpu_field_word(RDMA_PATH_X_REG, fbc_mem_size), val,
+		       cl_rdma);
+}
+
+void saturn_hee_plane_update_hw_channel(struct drm_plane *plane,
+					struct drm_plane_state *state,
+					const struct drm_display_mode *mode)
+{
+	struct spacemit_crtc *a_crtc = to_spacemit_crtc(state->crtc);
+	struct drm_framebuffer *fb = state->fb;
+	struct spacemit_plane_state *spacemit_plane_state =
+			to_spacemit_plane_state(state);
+	struct cmdlist_regs *cl_cmp = a_crtc->cl_cmp;
+	u32 rdma_id = to_spacemit_plane(plane)->rdma_id;
+	u8 alpha = state->alpha >> 8;
+	u16 pixel_alpha = state->pixel_blend_mode;
+	u32 src_w, src_h, src_x, src_y;
+	u32 crtc_w, crtc_h, crtc_x, crtc_y;
+	u32 alpha_sel, blend_mode = 0;
+	u32 base;
+	struct spacemit_drm_private *priv = plane->dev->dev_private;
+	struct spacemit_hw_device *hwdev = priv->hwdev;
+	struct cmdlist_regs *cl_rdma = to_spacemit_plane(plane)->cl_rdma;
+
+	/* Clipped by drm_atomic_helper_check_plane_state(); src is 16.16. */
+	src_x = state->src.x1 >> 16;
+	src_y = state->src.y1 >> 16;
+	src_w = drm_rect_width(&state->src) >> 16;
+	src_h = drm_rect_height(&state->src) >> 16;
+
+	crtc_x = state->dst.x1;
+	crtc_y = state->dst.y1;
+	crtc_w = drm_rect_width(&state->dst);
+	crtc_h = drm_rect_height(&state->dst);
+
+	drm_dbg(plane->dev, "crtc_x %u crtc_y %u\n", crtc_x, crtc_y);
+
+	base = RDMA_BASE_ADDR[rdma_id];
+	/* linear scanout only: the FBC decode path is not exposed */
+	dpu_write(hwdev, RDMA_PATH_X_REG, base, layer_mode, 0, cl_rdma);
+	dpu_write(hwdev, RDMA_PATH_X_REG, base, layer_cmpsr_id, COMPOSER1,
+		  cl_rdma);
+	/*
+	 * force online-mode routing whatever the bootloader left behind
+	 */
+	dpu_write(hwdev, RDMA_PATH_X_REG, base, is_offline, 0, cl_rdma);
+	dpu_write(hwdev, RDMA_PATH_X_REG, base, is_two_layers, 0, cl_rdma);
+
+	dpu_write(hwdev, RDMA_PATH_X_REG, base, img_width_ly0, fb->width,
+		  cl_rdma);
+	dpu_write(hwdev, RDMA_PATH_X_REG, base, img_height_ly0, fb->height,
+		  cl_rdma);
+	dpu_write(hwdev, RDMA_PATH_X_REG, base, bbox_start_x_ly0, src_x,
+		  cl_rdma);
+	dpu_write(hwdev, RDMA_PATH_X_REG, base, bbox_start_y_ly0, src_y,
+		  cl_rdma);
+	dpu_write(hwdev, RDMA_PATH_X_REG, base, bbox_end_x_ly0,
+		  src_x + src_w - 1, cl_rdma);
+	dpu_write(hwdev, RDMA_PATH_X_REG, base, bbox_end_y_ly0,
+		  src_y + src_h - 1, cl_rdma);
+
+	saturn_write_fbcmem_regs(hwdev, state, base, cl_rdma);
+
+	dpu_write(hwdev, RDMA_PATH_X_REG, base, rot_mode_ly0, 0, cl_rdma);
+	dpu_write(hwdev, RDMA_PATH_X_REG, base, uv_swap, 0, cl_rdma);
+	dpu_write(hwdev, RDMA_PATH_X_REG, base, pixel_format,
+		  spacemit_plane_state->format, cl_rdma);
+
+	switch (pixel_alpha) {
+	case DRM_MODE_BLEND_COVERAGE:
+		blend_mode = 0x0;
+		break;
+	case DRM_MODE_BLEND_PREMULTI:
+		blend_mode = 0x1;
+		break;
+	case DRM_MODE_BLEND_PIXEL_NONE:
+		blend_mode = 0x0;
+		break;
+	default:
+		drm_err(plane->dev, "unsupported blend mode for pixel alpha\n");
+	}
+
+	if (fb->format->has_alpha && pixel_alpha != DRM_MODE_BLEND_PIXEL_NONE) {
+		if (alpha != 0xff)
+			alpha_sel = 0x2;
+		else
+			alpha_sel = 0x1;
+	} else {
+		blend_mode = 0x0;
+		alpha_sel = 0x0;
+	}
+
+	base = CMP1_BASE_ADDR;
+	dpu_write(hwdev, CMPS_X_REG, base, dst_w, mode->hdisplay, cl_cmp);
+	dpu_write(hwdev, CMPS_X_REG, base, dst_h, mode->vdisplay, cl_cmp);
+
+	SATURN_WRITE_COMPOSER_LAYER(00);
+	spacemit_cmdlist_regs_packing(spacemit_crtc_to_cl(state->crtc), CMDLIST_MOD_COMP,
+				      cl_cmp);
+}
+
+void saturn_hee_plane_disable_hw_channel(struct drm_plane *plane,
+					 struct drm_crtc *crtc)
+{
+	u32 base = CMP1_BASE_ADDR;
+	struct spacemit_drm_private *priv = plane->dev->dev_private;
+	struct spacemit_hw_device *hwdev = priv->hwdev;
+	struct cmdlist_regs *cl_cmp = to_spacemit_crtc(crtc)->cl_cmp;
+
+	dpu_write(hwdev, CMPS_X_REG, base, layer00_en, 0, cl_cmp);
+
+	spacemit_cmdlist_regs_packing(spacemit_crtc_to_cl(crtc), CMDLIST_MOD_COMP,
+				      cl_cmp);
+}
+
+void saturn_hee_conf_dpuctrl(struct drm_crtc *crtc,
+			     struct drm_atomic_commit *state)
+{
+	struct drm_crtc_state *crtc_state =
+			drm_atomic_get_new_crtc_state(state, crtc);
+	u32 rdma_en;
+	u32 base;
+	u32 pp_base = POST_PIPE_ADDR;
+	struct spacemit_drm_private *priv = crtc->dev->dev_private;
+	struct spacemit_hw_device *hwdev = priv->hwdev;
+	struct spacemit_crtc *a_crtc = to_spacemit_crtc(crtc);
+	const struct drm_display_mode *mode = &crtc_state->adjusted_mode;
+	struct cmdlist_regs *pp_cl = a_crtc->cl_pp;
+
+	base = DPU_SCENE_CTL_ADDR(COMPOSER1);
+	rdma_en = saturn_conf_dpuctrl_rdma(state, crtc_state);
+
+	/* The post-pipe needs its input size even when it processes nothing. */
+	dpu_write_word(hwdev, pp_base, 0, 0, pp_cl);
+	dpu_write(hwdev, POSTPIPE_REG, pp_base, m_inwidth, mode->hdisplay,
+		  pp_cl);
+	dpu_write(hwdev, POSTPIPE_REG, pp_base, m_inheight, mode->vdisplay,
+		  pp_cl);
+
+	spacemit_cmdlist_regs_packing(spacemit_crtc_to_cl(crtc), CMDLIST_MOD_COMP, pp_cl);
+
+	dpu_write(hwdev, DPU_CTL_REG, base, nml_scl_en, 0);
+	dpu_write(hwdev, DPU_CTL_REG, base, nml_rch_en, rdma_en);
+	dpu_write(hwdev, DPU_CTL_REG, base, timing_inter0, 8);
+	dpu_write(hwdev, DPU_CTL_REG, base, timing_inter1, 8);
+	dpu_write(hwdev, DPU_CTL_REG, base, video_mod, 1);
+	dpu_write(hwdev, DPU_CTL_REG, base, dbg_mod, 0);
+
+	dpu_write(hwdev, DPU_CTL_REG, base, nml_outctl_en, 0x1);
+	dpu_write(hwdev, DPU_CTL_REG, base, nml_frm_timing_en, 2);
+
+	spacemit_cmdlist_submit_crtc(a_crtc);
+}
+
+u32 saturn_hee_get_cfg_rdy(struct spacemit_crtc *a_crtc,
+			   struct spacemit_hw_device *hwdev)
+{
+	u32 base = DPU_SCENE_CTL_ADDR(COMPOSER1);
+
+	return dpu_read_word(hwdev, base,
+			     dpu_field_word(DPU_CTL_REG, both_cfg_rdy));
+}
+
+u32 saturn_hee_get_int_sts(struct spacemit_hw_device *hwdev)
+{
+	return dpu_read_word(hwdev, DPU_INT_BASE_ADDR, DPU_ONLINE_IRQ_STS / 4);
+}
+
+static const struct spacemit_crtc_irq_bitfield {
+	enum spacemit_dpu_irq irq_id;
+	u32 irq_bit;
+} irq_list[] = {
+	[INT_UNDERRUN] = {INT_UNDERRUN, DPU_INT_FRM_TIMING_UNFLOW},
+	[INT_CFG_RDY] = {INT_CFG_RDY, DPU_INT_CFG_RDY_CLR},
+	[INT_VSYNC] = {INT_VSYNC, DPU_INT_FRM_TIMING_VSYNC},
+	[INT_EOF] = {INT_EOF, DPU_INT_FRM_TIMING_EOF},
+	[INT_REST] = {INT_REST, DPU_REST_INT_BITS},
+};
+
+u32 saturn_hee_get_irq_bit(enum spacemit_dpu_irq irq_id)
+{
+	return irq_list[irq_id].irq_bit;
+}
+
+void saturn_hee_clr_int_sts(struct spacemit_crtc *a_crtc, u32 data)
+{
+	struct spacemit_drm_private *priv = a_crtc->crtc.dev->dev_private;
+	struct spacemit_hw_device *hwdev = priv->hwdev;
+
+	regmap_write(hwdev->regmap, DPU_INT_BASE_ADDR + DPU_ONLINE_IRQ_STS,
+		     data);
+	if ((saturn_hee_get_irq_bit(INT_UNDERRUN) & data) &&
+	    a_crtc->ur_mask_armed) {
+		saturn_hee_enable_irq(a_crtc, INT_UNDERRUN, false);
+		a_crtc->ur_mask_armed = false;
+	}
+}
+
+void saturn_hee_enable_cmdlist(struct spacemit_crtc *a_crtc, struct spacemit_hw_device *hwdev,
+			       int id, bool enable)
+{
+	u32 base = DPU_SCENE_CTL_ADDR(COMPOSER1);
+	u32 val;
+
+	dpu_write_reg_arr(hwdev, DPU_CTL_TOP_REG, DPU_CTRL_BASE_ADDR,
+			  dpu_ctl_top_reg_0, id, cmdlist_rch_en,
+			  enable ? 1 : 0);
+	/* One layer per channel: clear its vertical-reuse bit. */
+	val = dpu_read_reg(hwdev, DPU_CTL_REG, base, nml_rch_vrt_reuse);
+	val &= ~BIT(id);
+	dpu_write(hwdev, DPU_CTL_REG, base, nml_rch_vrt_reuse, val);
+}
+
+void saturn_hee_cfg_cmdlist(struct spacemit_hw_device *hwdev, int id, u32 chy,
+			    u32 addrl, u32 addrh)
+{
+	dpu_write_reg_arr(hwdev, CMDLIST_REG, CMDLIST_BASE_ADDR,
+			  cmdlist_reg_48, id, cmdlist_ch_y_first, chy);
+	dpu_write_reg_arr(hwdev, CMDLIST_REG, CMDLIST_BASE_ADDR,
+			  cmdlist_reg_0, id, cmdlist_ch_start_addrl, addrl);
+	dpu_write_reg_arr(hwdev, CMDLIST_REG, CMDLIST_BASE_ADDR,
+			  cmdlist_reg_16, id, cmdlist_ch_start_addrh, addrh);
+}
+
+void saturn_hee_rdma_dmmu(struct spacemit_hw_device *hwdev, u8 tbu_id, struct tbu_instance *tbu,
+			  struct drm_framebuffer *fb,
+			  struct cmdlist_regs *cl_rdma,
+			  struct drm_plane *plane)
+{
+	u32 base, val;
+	u8 rdma_id = tbu_id / 2;
+	struct cmdlist_regs *cl_tbu = to_spacemit_plane(plane)->cl_tbu;
+
+	SATURN_WRITE_RDMA_ADDR_REG(hwdev, 0, rdma_id, tbu->tbu_va[0], cl_rdma);
+	SATURN_WRITE_RDMA_ADDR_REG(hwdev, 1, rdma_id, tbu->tbu_va[1], cl_rdma);
+	SATURN_WRITE_RDMA_ADDR_REG(hwdev, 2, rdma_id, tbu->tbu_va[2], cl_rdma);
+
+	base = RDMA_BASE_ADDR[rdma_id];
+	dpu_write(hwdev, RDMA_PATH_X_REG, base, rdma_stride0_layer0,
+		  fb->pitches[0], cl_rdma);
+	dpu_write(hwdev, RDMA_PATH_X_REG, base, rdma_stride1_layer0,
+		  fb->pitches[1], cl_rdma);
+
+	base = MMU_TBU_BASE_ADDR_ARRAY[tbu_id];
+	SATURN_WRITE_TBU_REGS(hwdev, base, 0, cl_tbu);
+	SATURN_WRITE_TBU_REGS(hwdev, base, 1, cl_tbu);
+	SATURN_WRITE_TBU_REGS(hwdev, base, 2, cl_tbu);
+
+	/* Linear scanout of one plane: the mode and plane count stay 0. */
+	val = FIELD_PREP(dpu_field_mask(MMU_TBU_REG, tbu_en), 1) |
+	      FIELD_PREP(dpu_field_mask(MMU_TBU_REG, tbu_burst_limit_en), 1) |
+	      FIELD_PREP(dpu_field_mask(MMU_TBU_REG, tlb_fetch_active_en), 1) |
+	      FIELD_PREP(dpu_field_mask(MMU_TBU_REG, tbu_qos), DPU_QOS_URGENT);
+	dpu_write_word(hwdev, base, dpu_field_word(MMU_TBU_REG, tbu_en), val,
+		       cl_tbu);
+	spacemit_cmdlist_regs_packing(spacemit_plane_to_cl(plane), CMDLIST_MOD_DMMU, cl_tbu);
+}
+
+struct cmdlist_header {
+	u64 next_list_addr : 39;
+	/* reserved */
+	u32: 1;
+	u32 nod_len : 16;
+	/* 1: the last cmdlist node, 2: pending node, otherwise 0 */
+	u32 nod_type : 2;
+	u32 next_nod_secu : 1;
+	u64 wait_event_low    : 5;
+	u64 wait_event    : 59;
+	/* reserved */
+	u32: 5;
+};
+
+struct cmdlist_row {
+	u32 module_cfg_addr   : 19;
+	u32 module_cfg_strobe : 12;
+	/* the last row tag = 1, else tag = 0. */
+	u32 row_eof_tag       : 1;
+	u32 module_regs[3];
+};
+
+/* DMA stream layout consumed by the cmdlist engine; it relies on the sizes. */
+static_assert(sizeof(struct cmdlist_header) == CMDLIST_HEADER_SIZE);
+static_assert(sizeof(struct cmdlist_row) == 16);
+
+#define CL_HEADER_SZ sizeof(struct cmdlist_header)
+#define CL_ROW_SZ    sizeof(struct cmdlist_row)
+
+#define CMDLIST_RDMA_CFG_RDY(ch) BIT(ch)
+#define CMDLIST_CMPS_CFG_RDY(ch) BIT((ch) + 20)
+
+#define CMDLIST_WAIT_EVENT_BIT_RDMA_RELOAD BIT(4)
+#define CMDLIST_WAIT_EVENT_BIT_CMPS_RELOAD BIT(6)
+
+/* Returns false, without writing, when the row would overrun the buffer. */
+bool saturn_hee_cmdlist_fill_data_row(struct cmdlist *cl, u32 strobe,
+				      u32 offset, u32 value[])
+{
+	struct cmdlist_row *row;
+	u8 i;
+
+	if (CL_HEADER_SZ + (cl->nod_len + 1) * CL_ROW_SZ > cl->size)
+		return false;
+
+	/* The buffer is reused: write the whole row, end tag included. */
+	row = (struct cmdlist_row *)((char *)cl->va + CL_HEADER_SZ) + cl->nod_len;
+	*row = (struct cmdlist_row) {
+		.module_cfg_addr = offset >> 2,
+		.module_cfg_strobe = strobe,
+	};
+
+	for (i = 0; i < CMDLIST_ROW_REGS; i++) {
+		if (strobe & CMDLIST_REG_STROBE(i))
+			row->module_regs[i] = value[i];
+	}
+
+	return true;
+}
+
+/*
+ * Close a list: the compose-start row (plane lists only), the CFG_RDY row that
+ * ends it, and the header. A list is a single node, so the header never
+ * chains to another.
+ */
+void saturn_hee_cmdlist_fill_conf_row(struct cmdlist *cl, u32 ch_y)
+{
+	struct cmdlist_header *header;
+	struct cmdlist_row *row;
+	struct drm_device *drm;
+	u8 rch_id = 0;
+	u32 wait_event_bits = 0, cfg_rdy_bits = 0;
+
+	if (cl->type == CMDLIST_PLANE) {
+		rch_id = to_spacemit_plane(cl->plane)->rdma_id;
+		drm = cl->plane->dev;
+	} else {
+		drm = cl->crtc->dev;
+	}
+
+	/* At most two rows are appended below; bail before overrunning. */
+	if (drm_WARN_ONCE(drm, CL_HEADER_SZ + (cl->nod_len + 2) * CL_ROW_SZ > cl->size,
+			  "cmdlist buffer full (type %u, rows %u)\n",
+			  cl->type, cl->nod_len))
+		return;
+
+	header = (struct cmdlist_header *)(cl->va);
+	row = (struct cmdlist_row *)((char *)header + CL_HEADER_SZ + cl->nod_len * CL_ROW_SZ);
+
+	if (cl->type == CMDLIST_PLANE) {
+		/* The composer must start fetching 24 lines ahead of the layer. */
+		*row = (struct cmdlist_row) {
+			.module_cfg_addr = (DPU_CTRL_BASE_ADDR +
+					    CMDLIST_CH_START_CMPS_Y + rch_id * 4) >> 2,
+			.module_cfg_strobe = CMDLIST_REG_STROBE(0),
+			.module_regs[0] = ch_y >= 24 ? ch_y - 24 : 0,
+		};
+		cl->nod_len++;
+		row++;
+	}
+
+	if (cl->mode_mask & CMDLIST_MOD_RDMA) {
+		wait_event_bits |= CMDLIST_WAIT_EVENT_BIT_RDMA_RELOAD;
+		cfg_rdy_bits |= CMDLIST_RDMA_CFG_RDY(rch_id);
+	}
+	if (cl->mode_mask & CMDLIST_MOD_COMP) {
+		wait_event_bits |= CMDLIST_WAIT_EVENT_BIT_CMPS_RELOAD;
+		cfg_rdy_bits |= CMDLIST_CMPS_CFG_RDY(COMPOSER1);
+	}
+	*row = (struct cmdlist_row) {
+		.module_cfg_addr = (DPU_CTRL_BASE_ADDR + CMDLIST_CFG_READY) >> 2,
+		.module_cfg_strobe = CMDLIST_REG_STROBE(0),
+		.row_eof_tag = 1,
+		.module_regs[0] = cfg_rdy_bits,
+	};
+	cl->nod_len++;
+
+	header->nod_type = 1;			/* last (and only) node */
+	header->nod_len = cl->nod_len + 1;	/* include header */
+	header->wait_event_low = wait_event_bits & 0x1F;
+	header->wait_event = wait_event_bits >> 5;
+}
+
+void saturn_hee_crtc_cmdlist(struct spacemit_hw_device *hwdev, dma_addr_t pa,
+			     u8 crtc_id)
+{
+	u8 ch = hwdev->rdma_nums + 2 + crtc_id;
+	u32 val;
+
+	dpu_write_reg_arr(hwdev, CMDLIST_REG, CMDLIST_BASE_ADDR, cmdlist_reg_48,
+			  ch, cmdlist_ch_y_first, 0);
+	val = (lower_32_bits(pa) & CMDLIST_ADDRL_ALIGN_MASK) >>
+	      CMDLIST_ADDRL_ALIGN_BITS;
+	dpu_write_reg_arr(hwdev, CMDLIST_REG, CMDLIST_BASE_ADDR, cmdlist_reg_0,
+			  ch, cmdlist_ch_start_addrl, val);
+	dpu_write_reg_arr(hwdev, CMDLIST_REG, CMDLIST_BASE_ADDR, cmdlist_reg_16,
+			  ch, cmdlist_ch_start_addrh, upper_32_bits(pa));
+	dpu_write_reg_arr(hwdev, DPU_CTL_TOP_REG, DPU_CTRL_BASE_ADDR,
+			  dpu_ctl_top_reg_10, COMPOSER1, cmdlist_cmps_top_en, 1);
+	dpu_write_reg_arr(hwdev, DPU_CTL_TOP_REG, DPU_CTRL_BASE_ADDR,
+			  dpu_ctl_top_reg_10, COMPOSER1, cmdlist_cmps_other_en, 1);
+}
diff --git a/drivers/gpu/drm/spacemit/dpu/saturn_fbcmem.c b/drivers/gpu/drm/spacemit/dpu/saturn_fbcmem.c
new file mode 100644
index 0000000000000..47dda7180f323
--- /dev/null
+++ b/drivers/gpu/drm/spacemit/dpu/saturn_fbcmem.c
@@ -0,0 +1,66 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (C) 2025-2026 SpacemiT Co., Ltd.
+ *
+ */
+
+#include <linux/stddef.h>
+
+#include <drm/drm_atomic.h>
+#include <drm/drm_fourcc.h>
+#include <drm/drm_framebuffer.h>
+#include <drm/drm_mode.h>
+
+#include "../spacemit_cmdlist.h"
+#include "saturn_fbcmem.h"
+
+static int saturn_raw_plane_mem_size(u32 drm_4cc_fmt, u32 plane_crop_width,
+				     u32 *output_mem_size)
+{
+	const struct drm_format_info *info;
+	u32 ret_mem_size;
+	u32 line_bytes;
+
+	info = drm_format_info(drm_4cc_fmt);
+	if (info->num_planes != 1 || info->is_yuv)
+		return -EINVAL;
+
+	/* The crop width is at most the 16-bit image width, so this fits. */
+	line_bytes = drm_format_info_min_pitch(info, 0, plane_crop_width);
+	if (!line_bytes)
+		return -EINVAL;
+
+	/* The hardware requires 64-byte rounding. */
+	ret_mem_size = roundup(line_bytes, 64);
+	ret_mem_size = ret_mem_size / 32;
+
+	if (output_mem_size)
+		*output_mem_size = ret_mem_size;
+
+	return 0;
+}
+
+/*
+ * Size the plane's share of the RDMA line buffer. Each pair of read
+ * channels owns one bank; the primary plane is alone on channel 0 and takes
+ * the front of bank 0, so the only check is that it fits.
+ */
+int saturn_cal_layer_fbcmem_size(struct drm_plane *plane,
+				 struct drm_plane_state *state)
+{
+	struct spacemit_plane_state *pstate = to_spacemit_plane_state(state);
+	struct spacemit_drm_private *priv = plane->dev->dev_private;
+	struct spacemit_plane *p = to_spacemit_plane(plane);
+	u32 bank = priv->hwdev->fbcmem_sizes[p->rdma_id / 2] / FBCMEM_UNIT;
+	u32 drm_4cc_fmt = pstate->state.fb->format->format;
+	u32 crop_w = drm_rect_width(&pstate->state.src) >> 16;
+	int ret;
+
+	/* Only linear sizing: the compressed path is not exposed. */
+	ret = saturn_raw_plane_mem_size(drm_4cc_fmt, crop_w,
+					&pstate->fbcmem_size);
+	if (ret)
+		return ret;
+
+	return pstate->fbcmem_size > bank ? -ENOSPC : 0;
+}
diff --git a/drivers/gpu/drm/spacemit/dpu/saturn_fbcmem.h b/drivers/gpu/drm/spacemit/dpu/saturn_fbcmem.h
new file mode 100644
index 0000000000000..ea9189ea738d5
--- /dev/null
+++ b/drivers/gpu/drm/spacemit/dpu/saturn_fbcmem.h
@@ -0,0 +1,16 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#ifndef _SATURN_FBCMEM_H_
+#define _SATURN_FBCMEM_H_
+
+#include <drm/drm_plane.h>
+
+#include "../spacemit_crtc.h"
+#include "../spacemit_dpu_reg.h"
+#include "dpu_saturn.h"
+
+#define FBCMEM_UNIT	(32) /* fbcmem is 32 bytes per unit */
+
+int saturn_cal_layer_fbcmem_size(struct drm_plane *plane,
+				 struct drm_plane_state *state);
+
+#endif
diff --git a/drivers/gpu/drm/spacemit/dpu/saturn_regs/ops_hee.h b/drivers/gpu/drm/spacemit/dpu/saturn_regs/ops_hee.h
new file mode 100644
index 0000000000000..58501261fae9d
--- /dev/null
+++ b/drivers/gpu/drm/spacemit/dpu/saturn_regs/ops_hee.h
@@ -0,0 +1,47 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Copyright (C) 2025-2026 SpacemiT Co., Ltd.
+ *
+ */
+
+#ifndef _SATURN_OPS_HEE_H_
+#define _SATURN_OPS_HEE_H_
+
+#include "../../spacemit_crtc.h"
+
+void saturn_hee_enable_irq(struct spacemit_crtc *a_crtc,
+			   enum spacemit_dpu_irq irq_id, bool enable);
+void saturn_hee_cfg_ready(struct spacemit_crtc *a_crtc,
+			  struct spacemit_hw_device *hwdev);
+void saturn_hee_sw_start(struct spacemit_crtc *a_crtc,
+			 struct spacemit_hw_device *hwdev);
+void saturn_hee_dpu_init(struct spacemit_crtc *a_crtc,
+			 const struct drm_display_mode *mode);
+void saturn_hee_plane_update_hw_channel(struct drm_plane *plane,
+					struct drm_plane_state *state,
+					const struct drm_display_mode *mode);
+void saturn_hee_plane_disable_hw_channel(struct drm_plane *plane,
+					 struct drm_crtc *crtc);
+void saturn_hee_irq_enable(struct spacemit_crtc *a_crtc, bool enable);
+void saturn_hee_conf_dpuctrl(struct drm_crtc *crtc,
+			     struct drm_atomic_commit *state);
+u32 saturn_hee_get_cfg_rdy(struct spacemit_crtc *a_crtc,
+			   struct spacemit_hw_device *hwdev);
+u32 saturn_hee_get_int_sts(struct spacemit_hw_device *hwdev);
+u32 saturn_hee_get_irq_bit(enum spacemit_dpu_irq irq_id);
+void saturn_hee_clr_int_sts(struct spacemit_crtc *a_crtc, u32 data);
+void saturn_hee_enable_cmdlist(struct spacemit_crtc *a_crtc,
+			       struct spacemit_hw_device *hwdev, int id,
+			       bool enable);
+void saturn_hee_cfg_cmdlist(struct spacemit_hw_device *hwdev, int id, u32 chy,
+			    u32 addrl, u32 addrh);
+void saturn_hee_rdma_dmmu(struct spacemit_hw_device *hwdev, u8 tbu_id,
+			  struct tbu_instance *tbu, struct drm_framebuffer *fb,
+			  struct cmdlist_regs *cl_rdma,
+			  struct drm_plane *plane);
+bool saturn_hee_cmdlist_fill_data_row(struct cmdlist *cl, u32 strobe,
+				      u32 offset, u32 value[]);
+void saturn_hee_cmdlist_fill_conf_row(struct cmdlist *cl, u32 ch_y);
+void saturn_hee_crtc_cmdlist(struct spacemit_hw_device *hwdev, dma_addr_t pa,
+			     u8 crtc_id);
+#endif

-- 
2.43.0

