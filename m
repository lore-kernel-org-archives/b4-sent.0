From: Cody Kang <codykang.hk@gmail.com>
Date: Sat, 21 Nov 2026 15:40:49 +0800
Subject: [PATCH v3 10/17] drm/spacemit: add Saturn DPU KMS pipeline
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-k3-display-v3-10-ec419e8e96b8@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795246844; l=30546;
 i=codykang.hk@gmail.com; s=codykang; h=from:subject:message-id;
 bh=vx0FZl2po1JRzj3iXmprIz2HfmNRRWV6cIxuhufnpIc=;
 b=elPrfgnZaZqovHuQqI6vg46oZWQGPvtxJgTcKpmCARSoeO4psP9pgAKCGwA7JW3143hCdrV10
 wRKsimkJ8k6BLGa1cHBIvViFtzTFXJr47WtRzC1SBkaOBhXojXeVkxz
X-Developer-Key: i=codykang.hk@gmail.com; a=ed25519;
 pk=Osn6/cs9Su/mHHw4P19cmVc3v2FMQfiWahjsN0vEkuk=
X-Endpoint-Received: by B4 Relay for codykang.hk@gmail.com/codykang with auth_id=895
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Cody Kang <codykang@vsit.ai>

Add the atomic KMS implementation on top of the hardware backend: one
CRTC and one primary plane per DPU instance. The plane's atomic_check
sizes its share of the RDMA line buffer and prepare_fb builds the
framebuffer's DMMU table; atomic commit fills the per-channel command
lists and arms the CFG_RDY handshake, and the commit's event is
delivered at the vblank after the engine has taken the lists. The DPU
is powered through runtime PM.

Signed-off-by: Cody Kang <codykang@vsit.ai>

---
v3:
- use atomic_create_state; .reset is gone from the CRTC and plane funcs
  in v7.4-rc1
- drop the ops table between the KMS code and the DPU backend (Thomas
  Zimmermann)
- drop the tracepoints; use drm_dbg() and drm_WARN_ON() (Thomas
  Zimmermann)
- wrap only the hardware access in drm_dev_enter() (Thomas Zimmermann)
- enable vblank after programming the mode, and initialise vblank after
  drm_mode_config_reset() (Thomas Zimmermann)
- program the plane from the clipped rectangles; drop the 1:1 and
  zero-size source checks (Thomas Zimmermann)
- submit the plane's command list from its atomic_update, and turn its
  channel off when the plane is disabled (Thomas Zimmermann)
- size the line buffer in the plane's atomic_check; no allocation in
  atomic_check (Thomas Zimmermann)
- add prepare_fb: build the display MMU table there and wait for the
  buffer's fences (Thomas Zimmermann)
- stop the boot loader's pipeline at probe instead of at the first
  modeset, and request the interrupt after it (Thomas Zimmermann)
- power the DPU through runtime PM instead of from atomic_disable
  (Thomas Zimmermann)
- release the drm_device when the aggregate unbinds, and stop output
  polling before its components unbind; take the mode and the plane
  state from the commit
- reject a framebuffer with an offset, a src_x beyond the DMMU table
  padding, or a buffer larger than one TBU can map
- reject modes above 3840x2160 in the CRTC's mode_valid (Icenowy Zheng)
- do not advertise a gamma table (Guodong Xu)
v2:
- put all five DPU reset lines behind one reset_control_bulk_* pair
  (Philipp Zabel, Guodong Xu)
- keep the online IRQ alive across drm_dev_unregister() and
  drm_atomic_helper_shutdown() in unbind (Sashiko)
- free the per-state DMA buffers in the plane .reset path instead of
  bypassing the custom state destructor (Sashiko)
- release the duplicated state's references on the rdmas allocation
  failure path in crtc duplicate_state (Sashiko)
- set clocks_on only after dpu_pm_resume() has enabled the clocks
  (Sashiko)
---
 drivers/gpu/drm/spacemit/spacemit_crtc.c   | 589 +++++++++++++++++++++++++++++
 drivers/gpu/drm/spacemit/spacemit_planes.c | 332 ++++++++++++++++
 2 files changed, 921 insertions(+)

diff --git a/drivers/gpu/drm/spacemit/spacemit_crtc.c b/drivers/gpu/drm/spacemit/spacemit_crtc.c
new file mode 100644
index 0000000000000..c1257444dd150
--- /dev/null
+++ b/drivers/gpu/drm/spacemit/spacemit_crtc.c
@@ -0,0 +1,589 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (C) 2025-2026 SpacemiT Co., Ltd.
+ *
+ */
+
+#include <linux/aperture.h>
+#include <linux/component.h>
+#include <linux/delay.h>
+#include <linux/dma-mapping.h>
+#include <linux/interrupt.h>
+#include <linux/module.h>
+#include <linux/of.h>
+#include <linux/of_graph.h>
+#include <linux/platform_device.h>
+#include <linux/pm_runtime.h>
+#include <linux/property.h>
+#include <linux/regmap.h>
+#include <linux/reset.h>
+#include <linux/timer.h>
+
+#include <drm/clients/drm_client_setup.h>
+#include <drm/drm_atomic_helper.h>
+#include <drm/drm_drv.h>
+#include <drm/drm_managed.h>
+#include <drm/drm_print.h>
+#include <drm/drm_probe_helper.h>
+#include <drm/drm_vblank.h>
+
+#include "dpu/dpu_saturn.h"
+#include "dpu/saturn_regs/ops_hee.h"
+#include "dpu/saturn_regs/saturn_fields.h"
+#include "spacemit_cmdlist.h"
+#include "spacemit_crtc.h"
+#include "spacemit_dmmu.h"
+#include "spacemit_drm.h"
+
+static void spacemit_crtc_atomic_enable(struct drm_crtc *crtc,
+					struct drm_atomic_commit *state)
+{
+	struct drm_crtc_state *crtc_state =
+			drm_atomic_get_new_crtc_state(state, crtc);
+	const struct drm_display_mode *mode = &crtc_state->adjusted_mode;
+	struct spacemit_crtc *a_crtc = to_spacemit_crtc(crtc);
+	struct spacemit_drm_private *priv = crtc->dev->dev_private;
+	int idx;
+	int ret;
+
+	/*
+	 * Not pm_runtime_resume_and_get(): atomic_disable runs and drops this
+	 * reference even when the power-up failed.
+	 */
+	ret = pm_runtime_get_sync(priv->dev);
+	if (ret < 0) {
+		/* The resume callback has said what failed. */
+		drm_dbg(crtc->dev, "DPU power-up failed: %d\n", ret);
+		return;
+	}
+
+	if (drm_dev_enter(crtc->dev, &idx)) {
+		spacemit_dpu_init(a_crtc, mode);
+		a_crtc->is_1st_f = true;
+		drm_dev_exit(idx);
+	}
+
+	drm_crtc_vblank_on(&a_crtc->crtc);
+}
+
+static void spacemit_crtc_atomic_disable(struct drm_crtc *crtc,
+					 struct drm_atomic_commit *state)
+{
+	struct drm_crtc_state *crtc_state =
+			drm_atomic_get_new_crtc_state(state, crtc);
+	struct spacemit_crtc *a_crtc = to_spacemit_crtc(crtc);
+	struct drm_device *drm = a_crtc->crtc.dev;
+	struct spacemit_drm_private *priv = drm->dev_private;
+	int idx;
+
+	if (drm_dev_enter(drm, &idx)) {
+		spacemit_dpu_uninit(a_crtc);
+		drm_dev_exit(idx);
+	}
+
+	drm_crtc_vblank_off(&a_crtc->crtc);
+
+	/* A commit may still be waiting for CFG_RDY: stop its watchdog. */
+	timer_delete_sync(&a_crtc->cfg_rdy_timer);
+
+	pm_runtime_put_sync(priv->dev);
+
+	/* No further vblank will come; complete the disable event here. */
+	spacemit_dpu_complete_event(a_crtc);
+	spin_lock_irq(&drm->event_lock);
+	if (crtc_state->event) {
+		drm_crtc_send_vblank_event(crtc, crtc_state->event);
+		crtc_state->event = NULL;
+	}
+	spin_unlock_irq(&drm->event_lock);
+}
+
+/* Planes write composer rows into the CRTC list, so open it before them. */
+static void spacemit_crtc_atomic_begin(struct drm_crtc *crtc,
+				       struct drm_atomic_commit *state)
+{
+	struct spacemit_crtc *a_crtc = to_spacemit_crtc(crtc);
+
+	spacemit_cmdlist_ring_next(a_crtc->cl, &a_crtc->cl_cur);
+}
+
+static void spacemit_crtc_atomic_flush(struct drm_crtc *crtc,
+				       struct drm_atomic_commit *state)
+{
+	struct drm_crtc_state *crtc_state =
+			drm_atomic_get_new_crtc_state(state, crtc);
+	struct spacemit_crtc *a_crtc = to_spacemit_crtc(crtc);
+	struct spacemit_drm_private *priv = crtc->dev->dev_private;
+	int idx;
+
+	/*
+	 * The event releases the next commit, which rewrites the other
+	 * command list and points the engine at it. Hold the event until
+	 * CFG_RDY says the engine has taken this commit's lists; the
+	 * interrupt then arms it for the following vblank.
+	 */
+	spin_lock_irq(&crtc->dev->event_lock);
+	if (crtc_state->event) {
+		if (drm_crtc_vblank_get(crtc) == 0)
+			a_crtc->event = crtc_state->event;
+		else
+			drm_crtc_send_vblank_event(crtc, crtc_state->event);
+		crtc_state->event = NULL;
+	}
+	spin_unlock_irq(&crtc->dev->event_lock);
+
+	/* clocks_on is false here only after a failed power-up. */
+	if (priv->clocks_on && drm_dev_enter(crtc->dev, &idx)) {
+		spacemit_dpu_run(crtc, state);
+		drm_dev_exit(idx);
+	} else {
+		spacemit_dpu_complete_event(a_crtc);
+	}
+}
+
+static int spacemit_crtc_enable_vblank(struct drm_crtc *crtc)
+{
+	saturn_hee_enable_irq(to_spacemit_crtc(crtc), INT_VSYNC, true);
+
+	return 0;
+}
+
+static void spacemit_crtc_disable_vblank(struct drm_crtc *crtc)
+{
+	saturn_hee_enable_irq(to_spacemit_crtc(crtc), INT_VSYNC, false);
+}
+
+static enum drm_mode_status
+spacemit_crtc_mode_valid(struct drm_crtc *crtc,
+			 const struct drm_display_mode *mode)
+{
+	if (mode->hdisplay > SPACEMIT_DPU_MAX_HDISPLAY)
+		return MODE_BAD_HVALUE;
+	if (mode->vdisplay > SPACEMIT_DPU_MAX_VDISPLAY)
+		return MODE_BAD_VVALUE;
+
+	return MODE_OK;
+}
+
+static const struct drm_crtc_helper_funcs spacemit_crtc_helper_funcs = {
+	.mode_valid = spacemit_crtc_mode_valid,
+	.atomic_begin = spacemit_crtc_atomic_begin,
+	.atomic_flush = spacemit_crtc_atomic_flush,
+	.atomic_enable = spacemit_crtc_atomic_enable,
+	.atomic_disable = spacemit_crtc_atomic_disable,
+};
+
+static const struct drm_crtc_funcs spacemit_crtc_funcs = {
+	.set_config = drm_atomic_helper_set_config,
+	.page_flip = drm_atomic_helper_page_flip,
+	.atomic_create_state = drm_atomic_helper_crtc_create_state,
+	.atomic_duplicate_state = drm_atomic_helper_crtc_duplicate_state,
+	.atomic_destroy_state = drm_atomic_helper_crtc_destroy_state,
+	.enable_vblank = spacemit_crtc_enable_vblank,
+	.disable_vblank = spacemit_crtc_disable_vblank,
+};
+
+static void spacemit_crtc_put_port(struct drm_device *drm, void *port)
+{
+	of_node_put(port);
+}
+
+static struct spacemit_crtc *spacemit_crtc_create(struct drm_device *drm,
+						  struct drm_plane *primary,
+						  struct device_node *port)
+{
+	struct spacemit_crtc *a_crtc;
+	int err;
+
+	a_crtc = drmm_crtc_alloc_with_planes(drm, struct spacemit_crtc, crtc,
+					     primary, NULL,
+					     &spacemit_crtc_funcs, NULL);
+	if (IS_ERR(a_crtc)) {
+		drm_err(drm, "failed to init crtc\n");
+		return a_crtc;
+	}
+
+	/*
+	 * drm_of_find_possible_crtcs() walks crtc->port for the life of the
+	 * drm_device.
+	 */
+	a_crtc->crtc.port = of_node_get(port);
+	err = drmm_add_action_or_reset(drm, spacemit_crtc_put_port, port);
+	if (err)
+		return ERR_PTR(err);
+
+	drm_crtc_helper_add(&a_crtc->crtc, &spacemit_crtc_helper_funcs);
+
+	err = spacemit_cmdlist_ring_init(drm, a_crtc->cl, CMDLIST_CRTC, NULL,
+					 &a_crtc->crtc);
+	if (err)
+		return ERR_PTR(err);
+
+	a_crtc->cl_cmp = spacemit_cmdlist_regs_alloc(drm, CMPS_X_REG__NWORDS);
+	a_crtc->cl_pp = spacemit_cmdlist_regs_alloc(drm, POSTPIPE_REG__NWORDS);
+	if (!a_crtc->cl_cmp || !a_crtc->cl_pp)
+		return ERR_PTR(-ENOMEM);
+
+	return a_crtc;
+}
+
+/* The one plane and the one CRTC of a DPU instance. */
+static struct spacemit_crtc *spacemit_drm_pipeline_init(struct drm_device *drm)
+{
+	struct spacemit_crtc *a_crtc;
+	struct device_node *port;
+	struct drm_plane *plane;
+
+	plane = spacemit_plane_init(drm);
+	if (IS_ERR(plane))
+		return ERR_CAST(plane);
+
+	port = of_graph_get_port_by_id(drm->dev->of_node, 0);
+	if (!port)
+		return ERR_PTR(dev_err_probe(drm->dev, -EINVAL,
+					     "no output port\n"));
+
+	a_crtc = spacemit_crtc_create(drm, plane, port);
+	of_node_put(port);
+	if (IS_ERR(a_crtc))
+		return a_crtc;
+
+	timer_setup(&a_crtc->cfg_rdy_timer, spacemit_cfg_rdy_timer_handler, 0);
+
+	return a_crtc;
+}
+
+static irqreturn_t spacemit_dpu_isr(int irq, void *data)
+{
+	struct spacemit_drm_private *priv = data;
+	struct spacemit_crtc *a_crtc = priv->a_crtc;
+
+	if (!a_crtc)
+		return IRQ_NONE;
+
+	/* Reading a clock-gated DPU's status registers stalls the bus. */
+	if (unlikely(!READ_ONCE(priv->clocks_on)))
+		return IRQ_NONE;
+
+	/*
+	 * Not under drm_dev_enter(): an unplugged device raises interrupts
+	 * until its CRTC is off, and they still have to be acked.
+	 */
+	return spacemit_dpu_online_isr(a_crtc) ? IRQ_HANDLED : IRQ_NONE;
+}
+
+/*
+ * Acquire at probe, not at bind: the aggregate can rebind without this device
+ * detaching, and the exclusive resets would not be handed out a second time.
+ */
+static int spacemit_dpu_hw_resources_init(struct spacemit_drm_private *priv,
+					  struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	int n_rstc;
+	int ret;
+
+	ret = spacemit_dpu_parse_clocks(dev, &priv->clk_ctx);
+	if (ret)
+		return ret;
+
+	priv->pipe_resets[0].id = "lcd";
+	priv->pipe_resets[1].id = "esc";
+	priv->pipe_resets[2].id = "mclk";
+	priv->pipe_resets[3].id = "aclk";
+	priv->pipe_resets[4].id = "dsc";
+	n_rstc = ARRAY_SIZE(priv->pipe_resets);
+	ret = devm_reset_control_bulk_get_exclusive(dev, n_rstc,
+						    priv->pipe_resets);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to get resets\n");
+
+	/*
+	 * The boot loader may leave its boot-logo pipeline running. Stop it
+	 * here with the resets alone (the clocks are not ours to gate yet)
+	 * and hold them until the first enable brings the block up.
+	 */
+	ret = reset_control_bulk_assert(n_rstc, priv->pipe_resets);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to assert resets\n");
+	usleep_range(10000, 20000);
+
+	priv->irq_online = platform_get_irq_byname(pdev, "online");
+	if (priv->irq_online < 0)
+		return priv->irq_online;
+
+	/* Keep the line disabled until bind: the handler needs bind state. */
+	return devm_request_irq(dev, priv->irq_online, spacemit_dpu_isr,
+				IRQF_NO_AUTOEN, "DPU_ONLINE", priv);
+}
+
+static const struct regmap_config spacemit_dpu_regmap_config = {
+	.name		= "dpu",
+	.reg_bits	= 32,
+	.val_bits	= 32,
+	.reg_stride	= 4,
+	.max_register	= 0x53ffc,	/* 0x54000-byte DPU register window */
+};
+
+static int spacemit_drm_master_bind(struct device *dev)
+{
+	struct spacemit_drm_private *priv = dev_get_drvdata(dev);
+	struct spacemit_crtc *a_crtc;
+	struct drm_device *drm;
+	int ret;
+
+	ret = aperture_remove_all_conflicting_devices(spacemit_drm_drv.name);
+	if (ret)
+		return dev_err_probe(dev, ret,
+				     "failed to remove existing framebuffers\n");
+
+	/*
+	 * Bind-scoped, not devm: the aggregate can rebind without this
+	 * device being re-probed, and each bind must release its own
+	 * drm_device.
+	 */
+	drm = drm_dev_alloc(&spacemit_drm_drv, dev);
+	if (IS_ERR(drm))
+		return PTR_ERR(drm);
+	priv->ddev = drm;
+	drm->dev_private = priv;
+
+	ret = spacemit_drm_mode_config_init(drm);
+	if (ret)
+		goto err_dc;
+
+	a_crtc = spacemit_drm_pipeline_init(drm);
+	if (IS_ERR(a_crtc)) {
+		ret = PTR_ERR(a_crtc);
+		goto err_dc;
+	}
+	priv->a_crtc = a_crtc;
+
+	/*
+	 * component_bind_all() unbinds what it bound before returning an error.
+	 */
+	ret = component_bind_all(dev, drm);
+	if (ret) {
+		dev_err_probe(dev, ret, "failed to bind all components\n");
+		goto err_dc;
+	}
+
+	drm_mode_config_reset(drm);
+
+	ret = drm_vblank_init(drm, drm->mode_config.num_crtc);
+	if (ret) {
+		dev_err_probe(dev, ret, "failed to initialize vblank\n");
+		goto err_unbind_all;
+	}
+
+	drmm_kms_helper_poll_init(drm);
+	drm_helper_hpd_irq_event(drm);
+
+	enable_irq(priv->irq_online);
+
+	ret = drm_dev_register(drm, 0);
+	if (ret < 0)
+		goto err_disable_irq;
+	drm_client_setup(drm, NULL);
+
+	return 0;
+
+err_disable_irq:
+	disable_irq(priv->irq_online);
+
+err_unbind_all:
+	component_unbind_all(dev, drm);
+err_dc:
+	/*
+	 * .shutdown tests priv->ddev; never leave it on a half-initialised
+	 * device.
+	 */
+	priv->ddev = NULL;
+	priv->a_crtc = NULL;
+	drm_dev_put(drm);
+	return ret;
+}
+
+static void spacemit_drm_master_unbind(struct device *dev)
+{
+	struct spacemit_drm_private *priv = dev_get_drvdata(dev);
+	struct drm_device *drm = priv->ddev;
+
+	/*
+	 * A process may keep the card open past this point. Unplug, so that
+	 * its ioctls fail and the drm_dev_enter() sections keep off the
+	 * registers. The commits that follow still turn the outputs off: the
+	 * CRTC drops its runtime PM reference, and the suspend resets the DPU.
+	 * The interrupt stays alive until then, for a commit that was already
+	 * waiting on it.
+	 */
+	drm_dev_unplug(drm);
+	/* An open file keeps the drm_device, and its poll worker, alive. */
+	drm_kms_helper_poll_fini(drm);
+	drm_atomic_helper_shutdown(drm);
+
+	disable_irq(priv->irq_online);
+
+	component_unbind_all(dev, drm);
+
+	/* .shutdown and a later re-bind must not touch the stale instance. */
+	priv->ddev = NULL;
+	priv->a_crtc = NULL;
+
+	drm_dev_put(drm);
+}
+
+const struct component_master_ops spacemit_drm_master_ops = {
+	.bind = spacemit_drm_master_bind,
+	.unbind = spacemit_drm_master_unbind,
+};
+
+static int spacemit_dpu_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	const struct spacemit_hw_device *hwdev_template;
+	struct spacemit_drm_private *priv;
+	int ret;
+
+	/* A display MMU entry holds a 26-bit page frame number. */
+	ret = dma_set_mask_and_coherent(dev, DMA_BIT_MASK(38));
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to set DMA mask\n");
+
+	priv = devm_kzalloc(dev, sizeof(*priv), GFP_KERNEL);
+	if (!priv)
+		return -ENOMEM;
+	priv->dev = dev;
+	dev_set_drvdata(dev, priv);
+
+	/* The match data is shared const; the MMIO mapping is per-instance. */
+	hwdev_template = device_get_match_data(dev);
+	if (!hwdev_template)
+		return -ENODEV;
+	priv->hwdev = devm_kmemdup(dev, hwdev_template,
+				   sizeof(*hwdev_template), GFP_KERNEL);
+	if (!priv->hwdev)
+		return -ENOMEM;
+
+	priv->hwdev->base = devm_platform_ioremap_resource(pdev, 0);
+	if (IS_ERR(priv->hwdev->base))
+		return PTR_ERR(priv->hwdev->base);
+
+	priv->hwdev->regmap = devm_regmap_init_mmio(dev, priv->hwdev->base,
+						    &spacemit_dpu_regmap_config);
+	if (IS_ERR(priv->hwdev->regmap))
+		return dev_err_probe(dev, PTR_ERR(priv->hwdev->regmap),
+				     "failed to init DPU regmap\n");
+
+	ret = spacemit_dpu_hw_resources_init(priv, pdev);
+	if (ret)
+		return ret;
+
+	/* Held in reset with the clocks off: the suspended state. */
+	ret = devm_pm_runtime_enable(dev);
+	if (ret)
+		return ret;
+
+	return spacemit_drm_of_component_probe(dev);
+}
+
+static void spacemit_dpu_remove(struct platform_device *pdev)
+{
+	component_master_del(&pdev->dev, &spacemit_drm_master_ops);
+}
+
+static void spacemit_dpu_shutdown(struct platform_device *pdev)
+{
+	struct spacemit_drm_private *priv = dev_get_drvdata(&pdev->dev);
+	struct drm_device *drm = priv->ddev;
+
+	/* Not bound: nothing was ever enabled. */
+	if (!drm)
+		return;
+
+	drm_atomic_helper_shutdown(drm);
+}
+
+static int spacemit_dpu_runtime_suspend(struct device *dev)
+{
+	struct spacemit_drm_private *priv = dev_get_drvdata(dev);
+	int ret;
+
+	/*
+	 * Close the ISR's MMIO gate, then let a handler that is already past
+	 * it finish before the clocks stop.
+	 */
+	WRITE_ONCE(priv->clocks_on, false);
+	synchronize_irq(priv->irq_online);
+
+	/*
+	 * Assert before gating: a reset asserted into an already-gated block
+	 * has no clock edges to propagate on and leaves the register file
+	 * untouched.
+	 */
+	ret = reset_control_bulk_assert(ARRAY_SIZE(priv->pipe_resets),
+					priv->pipe_resets);
+	if (ret)
+		dev_warn(dev, "failed to assert resets: %d\n", ret);
+	usleep_range(10000, 20000);
+
+	spacemit_dpu_disable_clocks(priv);
+
+	return 0;
+}
+
+static int spacemit_dpu_runtime_resume(struct device *dev)
+{
+	struct spacemit_drm_private *priv = dev_get_drvdata(dev);
+	int ret;
+
+	ret = reset_control_bulk_deassert(ARRAY_SIZE(priv->pipe_resets),
+					  priv->pipe_resets);
+	if (ret) {
+		dev_err(dev, "failed to deassert resets: %d\n", ret);
+		return ret;
+	}
+
+	ret = spacemit_dpu_enable_clocks(priv);
+	if (ret) {
+		reset_control_bulk_assert(ARRAY_SIZE(priv->pipe_resets),
+					  priv->pipe_resets);
+		return ret;
+	}
+
+	/* The DPU must settle after reset deassert or CFG_RDY races the flush. */
+	usleep_range(10000, 20000);
+	WRITE_ONCE(priv->clocks_on, true);
+
+	return 0;
+}
+
+static const struct dev_pm_ops spacemit_dpu_pm_ops = {
+	RUNTIME_PM_OPS(spacemit_dpu_runtime_suspend, spacemit_dpu_runtime_resume,
+		       NULL)
+};
+
+static const struct of_device_id spacemit_dpu_match_table[] = {
+	{
+		.compatible = "spacemit,k3-saturn-dpu",
+		.data = &spacemit_k3_saturn_dpu,
+	},
+	{},
+};
+MODULE_DEVICE_TABLE(of, spacemit_dpu_match_table);
+
+static struct platform_driver spacemit_dpu_driver = {
+	.probe = spacemit_dpu_probe,
+	.remove = spacemit_dpu_remove,
+	.shutdown = spacemit_dpu_shutdown,
+	.driver = {
+		.name = "spacemit-dpu-drv",
+		.of_match_table = spacemit_dpu_match_table,
+		.pm = pm_ptr(&spacemit_dpu_pm_ops),
+		.suppress_bind_attrs = true,
+	},
+};
+module_platform_driver(spacemit_dpu_driver);
+
+MODULE_DESCRIPTION("SpacemiT DRM KMS master driver");
+MODULE_LICENSE("GPL");
diff --git a/drivers/gpu/drm/spacemit/spacemit_planes.c b/drivers/gpu/drm/spacemit/spacemit_planes.c
new file mode 100644
index 0000000000000..c49a2e1572771
--- /dev/null
+++ b/drivers/gpu/drm/spacemit/spacemit_planes.c
@@ -0,0 +1,332 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (C) 2025-2026 SpacemiT Co., Ltd.
+ *
+ */
+
+#include <linux/bits.h>
+#include <linux/slab.h>
+
+#include <drm/drm_atomic.h>
+#include <drm/drm_atomic_helper.h>
+#include <drm/drm_blend.h>
+#include <drm/drm_drv.h>
+#include <drm/drm_framebuffer.h>
+#include <drm/drm_gem.h>
+#include <drm/drm_gem_atomic_helper.h>
+#include <drm/drm_plane.h>
+#include <drm/drm_print.h>
+
+#include "dpu/dpu_saturn.h"
+#include "dpu/saturn_fbcmem.h"
+#include "dpu/saturn_regs/ops_hee.h"
+#include "dpu/saturn_regs/saturn_fields.h"
+#include "spacemit_cmdlist.h"
+#include "spacemit_dmmu.h"
+#include "spacemit_drm.h"
+
+/* The AFBC decoder exists but no modifier has been validated on hardware. */
+static const u64 supported_format_modifiers[] = {
+	DRM_FORMAT_MOD_LINEAR,
+	DRM_FORMAT_MOD_INVALID
+};
+
+struct spacemit_plane *to_spacemit_plane(struct drm_plane *plane)
+{
+	return container_of(plane, struct spacemit_plane, plane);
+}
+
+static int spacemit_plane_atomic_check(struct drm_plane *plane,
+				       struct drm_atomic_commit *atomic_state)
+{
+	struct drm_plane_state *state =
+			drm_atomic_get_new_plane_state(atomic_state, plane);
+	struct drm_framebuffer *fb = state->fb;
+	struct spacemit_plane_state *cur_state = to_spacemit_plane_state(state);
+	struct drm_crtc_state *crtc_state = NULL;
+	int ret;
+
+	if (state->crtc)
+		crtc_state = drm_atomic_get_new_crtc_state(atomic_state,
+							   state->crtc);
+
+	ret = drm_atomic_helper_check_plane_state(state, crtc_state,
+						  DRM_PLANE_NO_SCALING,
+						  DRM_PLANE_NO_SCALING,
+						  true, false);
+	if (ret)
+		return ret;
+
+	if (!state->visible)
+		return 0;
+
+	/* The width limit bounds the default pitch; userspace may pass a larger one. */
+	if (fb->pitches[0] > SPACEMIT_DPU_MAX_PITCH) {
+		drm_dbg(plane->dev, "pitch %u exceeds the stride field\n",
+			fb->pitches[0]);
+		return -EINVAL;
+	}
+
+	/* Scanout starts at the first byte of the buffer object. */
+	if (fb->offsets[0]) {
+		drm_dbg(plane->dev, "framebuffer offset %u is not supported\n",
+			fb->offsets[0]);
+		return -EINVAL;
+	}
+
+	if (state->src.x1 >> 16 > SPACEMIT_DMMU_MAX_SRC_X) {
+		drm_dbg(plane->dev, "src_x %d exceeds the DMMU table padding\n",
+			state->src.x1 >> 16);
+		return -EINVAL;
+	}
+
+	if (fb->obj[0]->size >> PAGE_SHIFT > SPACEMIT_DMMU_MAX_PAGES) {
+		drm_dbg(plane->dev, "buffer of %zu bytes exceeds one TBU\n",
+			fb->obj[0]->size);
+		return -EINVAL;
+	}
+
+	if (saturn_cal_layer_fbcmem_size(plane, state)) {
+		drm_dbg(plane->dev, "invalid fbcmem size\n");
+		return -EINVAL;
+	}
+
+	cur_state->format = spacemit_plane_hw_get_format_id(fb->format->format);
+	if (cur_state->format == SPACEMIT_DPU_INVALID_FORMAT_ID) {
+		drm_dbg(plane->dev, "unsupported format %p4cc\n",
+			&fb->format->format);
+		return -EINVAL;
+	}
+
+	return 0;
+}
+
+static void spacemit_plane_program(struct drm_plane *plane,
+				   struct drm_plane_state *state,
+				   const struct drm_display_mode *mode)
+{
+	struct spacemit_plane *p = to_spacemit_plane(plane);
+	u32 rdma_id = p->rdma_id;
+
+	spacemit_cmdlist_ring_next(p->cl, &p->cl_cur);
+
+	saturn_hee_plane_update_hw_channel(plane, state, mode);
+	spacemit_dmmu_map(state->fb, rdma_id * 2, p->cl_rdma, plane);
+	spacemit_cmdlist_regs_packing(spacemit_plane_to_cl(plane), CMDLIST_MOD_RDMA,
+				      p->cl_rdma);
+
+	spacemit_cmdlist_submit_plane(plane, state);
+}
+
+/* Take the layer out of the composition and stop its read channel. */
+static void spacemit_plane_off(struct drm_plane *plane, struct drm_crtc *crtc)
+{
+	struct spacemit_drm_private *priv = plane->dev->dev_private;
+	struct spacemit_plane *p = to_spacemit_plane(plane);
+
+	saturn_hee_plane_disable_hw_channel(plane, crtc);
+	saturn_hee_enable_cmdlist(to_spacemit_crtc(crtc), priv->hwdev,
+				  p->rdma_id, false);
+}
+
+static void spacemit_plane_atomic_update(struct drm_plane *plane,
+					 struct drm_atomic_commit *state)
+{
+	struct drm_plane_state *new_state =
+			drm_atomic_get_new_plane_state(state, plane);
+	struct drm_crtc_state *crtc_state =
+			drm_atomic_get_new_crtc_state(state, new_state->crtc);
+	struct spacemit_drm_private *priv = plane->dev->dev_private;
+	int idx;
+
+	if (priv->clocks_on && drm_dev_enter(plane->dev, &idx)) {
+		/* A plane moved off the screen has no rectangle to program. */
+		if (new_state->visible)
+			spacemit_plane_program(plane, new_state,
+					       &crtc_state->adjusted_mode);
+		else
+			spacemit_plane_off(plane, new_state->crtc);
+		drm_dev_exit(idx);
+	}
+}
+
+static void spacemit_plane_atomic_disable(struct drm_plane *plane,
+					  struct drm_atomic_commit *state)
+{
+	struct drm_plane_state *old_state =
+			drm_atomic_get_old_plane_state(state, plane);
+	struct spacemit_drm_private *priv = plane->dev->dev_private;
+	int idx;
+
+	if (priv->clocks_on && drm_dev_enter(plane->dev, &idx)) {
+		spacemit_plane_off(plane, old_state->crtc);
+		drm_dev_exit(idx);
+	}
+}
+
+static struct drm_plane_state *
+spacemit_plane_atomic_create_state(struct drm_plane *plane)
+{
+	struct spacemit_plane_state *s;
+
+	s = kzalloc_obj(*s);
+	if (!s)
+		return ERR_PTR(-ENOMEM);
+
+	__drm_atomic_helper_plane_state_init(&s->state, plane);
+
+	return &s->state;
+}
+
+static struct drm_plane_state *
+spacemit_plane_atomic_duplicate_state(struct drm_plane *plane)
+{
+	struct spacemit_plane_state *s;
+	struct spacemit_plane_state *old_state =
+			to_spacemit_plane_state(plane->state);
+
+	s = kzalloc_obj(*s);
+	if (!s)
+		return NULL;
+
+	__drm_atomic_helper_plane_duplicate_state(plane, &s->state);
+
+	s->format = old_state->format;
+	s->fbcmem_size = old_state->fbcmem_size;
+
+	return &s->state;
+}
+
+static void spacemit_plane_atomic_destroy_state(struct drm_plane *plane,
+						struct drm_plane_state *state)
+{
+	__drm_atomic_helper_plane_destroy_state(state);
+
+	kfree(to_spacemit_plane_state(state));
+}
+
+static int spacemit_plane_create_properties(struct spacemit_plane *p)
+{
+	unsigned int support_modes = BIT(DRM_MODE_BLEND_PIXEL_NONE) |
+		BIT(DRM_MODE_BLEND_PREMULTI) |
+		BIT(DRM_MODE_BLEND_COVERAGE);
+	int ret;
+
+	ret = drm_plane_create_alpha_property(&p->plane);
+	if (ret)
+		return ret;
+
+	return drm_plane_create_blend_mode_property(&p->plane, support_modes);
+}
+
+/* Collect the buffer's fences and build its DMMU table once. */
+static int spacemit_plane_prepare_fb(struct drm_plane *plane,
+				     struct drm_plane_state *state)
+{
+	int ret;
+
+	if (!state->fb)
+		return 0;
+
+	ret = drm_gem_plane_helper_prepare_fb(plane, state);
+	if (ret)
+		return ret;
+
+	return spacemit_dmmu_prepare(state->fb->obj[0]);
+}
+
+static const struct drm_plane_helper_funcs spacemit_plane_helper_funcs = {
+	.prepare_fb = spacemit_plane_prepare_fb,
+	.atomic_check = spacemit_plane_atomic_check,
+	.atomic_update = spacemit_plane_atomic_update,
+	.atomic_disable = spacemit_plane_atomic_disable,
+};
+
+static void spacemit_plane_atomic_print_state(struct drm_printer *p,
+					      const struct drm_plane_state *state)
+{
+	const struct spacemit_plane_state *s = to_spacemit_plane_state(state);
+
+	drm_printf(p, "\tformat-id=%u\n", s->format);
+	drm_printf(p, "\tfbcmem-size=%u\n", s->fbcmem_size);
+}
+
+static const struct drm_plane_funcs spacemit_plane_funcs = {
+	.update_plane = drm_atomic_helper_update_plane,
+	.disable_plane	= drm_atomic_helper_disable_plane,
+	.atomic_create_state = spacemit_plane_atomic_create_state,
+	.atomic_duplicate_state = spacemit_plane_atomic_duplicate_state,
+	.atomic_destroy_state = spacemit_plane_atomic_destroy_state,
+	.atomic_print_state = spacemit_plane_atomic_print_state,
+};
+
+struct drm_plane *spacemit_plane_init(struct drm_device *drm)
+{
+	struct spacemit_plane *p;
+	int err, j;
+	u32 *formats;
+	struct spacemit_drm_private *priv = drm->dev_private;
+	struct spacemit_hw_device *hwdev = priv->hwdev;
+	u8 n_formats = hwdev->n_formats;
+	u8 n_fbcmems = hwdev->n_fbcmems;
+	u8 n_rdmas = hwdev->rdma_nums;
+	u32 plane_crtc_mask;
+
+	if (n_fbcmems * 2 != n_rdmas) {
+		drm_err(drm, "mismatched rdma/fbcmem counts: %d vs %d\n",
+			n_rdmas, n_fbcmems);
+		return ERR_PTR(-EINVAL);
+	}
+
+	for (j = 0; j < n_fbcmems; j++) {
+		if (hwdev->fbcmem_sizes[j] < FBCMEM_UNIT) {
+			drm_err(drm, "invalid fbcmem_sizes[%d] = %u\n",
+				j, hwdev->fbcmem_sizes[j]);
+			return ERR_PTR(-EINVAL);
+		}
+	}
+
+	formats = kcalloc(n_formats, sizeof(*formats), GFP_KERNEL);
+	if (!formats)
+		return ERR_PTR(-ENOMEM);
+
+	/*
+	 * The CRTC is created right after this, so its index is the current
+	 * count.
+	 */
+	plane_crtc_mask = BIT(drm->mode_config.num_crtc);
+
+	for (j = 0; j < n_formats; j++)
+		formats[j] = hwdev->formats[j].format;
+
+	p = drmm_universal_plane_alloc(drm, struct spacemit_plane, plane,
+				       plane_crtc_mask, &spacemit_plane_funcs,
+				       formats, n_formats,
+				       supported_format_modifiers,
+				       DRM_PLANE_TYPE_PRIMARY, NULL);
+	kfree(formats);
+	if (IS_ERR(p)) {
+		drm_err(drm, "failed to init primary plane\n");
+		return ERR_CAST(p);
+	}
+
+	/* The single primary plane owns the first read channel. */
+	p->rdma_id = 0;
+
+	drm_plane_helper_add(&p->plane, &spacemit_plane_helper_funcs);
+
+	err = spacemit_cmdlist_ring_init(drm, p->cl, CMDLIST_PLANE, &p->plane, NULL);
+	if (err)
+		return ERR_PTR(err);
+
+	err = spacemit_plane_create_properties(p);
+	if (err)
+		return ERR_PTR(err);
+
+	p->cl_rdma = spacemit_cmdlist_regs_alloc(drm, RDMA_PATH_X_REG__NWORDS);
+	p->cl_tbu = spacemit_cmdlist_regs_alloc(drm, MMU_TBU_REG__NWORDS);
+	if (!p->cl_rdma || !p->cl_tbu)
+		return ERR_PTR(-ENOMEM);
+
+	return &p->plane;
+}

-- 
2.43.0

