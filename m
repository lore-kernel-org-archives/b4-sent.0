From: Cody Kang <codykang.hk@gmail.com>
Date: Sat, 21 Nov 2026 15:40:47 +0800
Subject: [PATCH v3 08/17] drm/spacemit: add Saturn DPU core types, cmdlist
 and display MMU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-k3-display-v3-8-ec419e8e96b8@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795246844; l=31097;
 i=codykang.hk@gmail.com; s=codykang; h=from:subject:message-id;
 bh=gPCBG+QZ8eEWdXQgArafv65Uzxe/uhMusMeo6twZHQ0=;
 b=4KvXN1wTDtZmT5aUkPEVDmBxZzeHi8J4PRJy6S0N4GIyfKe5kUCehETjAOhqLNOivTdoNwqXJ
 CUDYg8226UtA8mBSeRR8YV6K4uEjH1xAG65EkPWqDlogtlAi2bCA6VO
X-Developer-Key: i=codykang.hk@gmail.com; a=ed25519;
 pk=Osn6/cs9Su/mHHw4P19cmVc3v2FMQfiWahjsN0vEkuk=
X-Endpoint-Received: by B4 Relay for codykang.hk@gmail.com/codykang with auth_id=895
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Cody Kang <codykang@vsit.ai>

Register programming of the Saturn DPU is batched: the driver builds
per-module register lists in memory and the hardware command-list
engine replays them once the driver raises config-ready (CFG_RDY),
while scanout buffers are mapped through the DPU's private address
translation unit (DMMU) rather than scanned out by physical address.

Add the shared driver types, the MMIO field accessors, the
command-list builder and the DMMU table code. Some DPU
configuration registers are write-only, so a read-modify-write would
corrupt neighbouring fields; byte- and halfword-aligned fields are
therefore written at their native width instead.

Signed-off-by: Cody Kang <codykang@vsit.ai>

---
v3:
- drop the tracepoints and dpu_trace.h (Thomas Zimmermann)
- drop the hardware callback table; the Saturn register code is called
  directly (Thomas Zimmermann)
- one command list per channel, allocated once; the grouping, sorting
  and chaining of lists is gone (Thomas Zimmermann)
- build the display MMU table once per GEM object (Thomas Zimmermann)
- use drm_WARN_ON_ONCE() in the DMMU table fill (Thomas Zimmermann)
- keep the clock handles and the power state in the device data
- commit message: the engine replays the lists on config-ready, not at
  frame boundaries
v2:
- hold the DPU reset lines as one reset_control_bulk_data
  pipe_resets[5] array in spacemit_drm_private and drop the pointers
  duplicated into struct spacemit_crtc (Philipp Zabel)
- drop the INT_VSYNC_UPDATE enum member; it never had an irq_list[]
  mapping and the register model has no such status bit (Sashiko)
- drop the unreachable multi-planar arms in spacemit_dmmu_map(); every
  advertised format is single-planar (Sashiko)
- drop the unused cmdlist parameter from the crtc_cmdlist op (Sashiko)
---
 drivers/gpu/drm/spacemit/dpu/dpu_saturn.h   |  36 +++++
 drivers/gpu/drm/spacemit/spacemit_cmdlist.c | 198 ++++++++++++++++++++++++++++
 drivers/gpu/drm/spacemit/spacemit_cmdlist.h | 133 +++++++++++++++++++
 drivers/gpu/drm/spacemit/spacemit_crtc.h    | 133 +++++++++++++++++++
 drivers/gpu/drm/spacemit/spacemit_dmmu.c    | 119 +++++++++++++++++
 drivers/gpu/drm/spacemit/spacemit_dmmu.h    |  80 +++++++++++
 drivers/gpu/drm/spacemit/spacemit_dpu_reg.h |  99 ++++++++++++++
 drivers/gpu/drm/spacemit/spacemit_drm.h     |  62 +++++++++
 8 files changed, 860 insertions(+)

diff --git a/drivers/gpu/drm/spacemit/dpu/dpu_saturn.h b/drivers/gpu/drm/spacemit/dpu/dpu_saturn.h
new file mode 100644
index 0000000000000..9f3c58166273c
--- /dev/null
+++ b/drivers/gpu/drm/spacemit/dpu/dpu_saturn.h
@@ -0,0 +1,36 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Copyright (C) 2025-2026 SpacemiT Co., Ltd.
+ *
+ */
+
+#ifndef _DPU_SATURN_H_
+#define _DPU_SATURN_H_
+
+#include "../spacemit_crtc.h"
+
+struct dpu_format_id {
+	u32 format;		/* DRM fourcc */
+	u8 id;
+	u8 bpp;			/* bits per pixel */
+};
+
+#define SPACEMIT_DPU_INVALID_FORMAT_ID	0xff
+
+int spacemit_dpu_parse_clocks(struct device *dev, struct dpu_clk_context *clk_ctx);
+int spacemit_dpu_enable_clocks(struct spacemit_drm_private *priv);
+void spacemit_dpu_disable_clocks(struct spacemit_drm_private *priv);
+void spacemit_dpu_init(struct spacemit_crtc *a_crtc,
+		       const struct drm_display_mode *mode);
+void spacemit_dpu_uninit(struct spacemit_crtc *a_crtc);
+void spacemit_dpu_run(struct drm_crtc *crtc, struct drm_atomic_commit *state);
+bool spacemit_dpu_online_isr(struct spacemit_crtc *a_crtc);
+u8 spacemit_plane_hw_get_format_id(u32 format);
+u32 saturn_conf_dpuctrl_rdma(struct drm_atomic_commit *state,
+			     const struct drm_crtc_state *crtc_state);
+extern const struct spacemit_hw_device spacemit_k3_saturn_dpu;
+void saturn_enable_irq_mask(struct spacemit_crtc *a_crtc, bool enable,
+			    u32 offset, u32 mask);
+void spacemit_cfg_rdy_timer_handler(struct timer_list *t);
+void spacemit_dpu_complete_event(struct spacemit_crtc *a_crtc);
+#endif
diff --git a/drivers/gpu/drm/spacemit/spacemit_cmdlist.c b/drivers/gpu/drm/spacemit/spacemit_cmdlist.c
new file mode 100644
index 0000000000000..fbd5c2d85eaa2
--- /dev/null
+++ b/drivers/gpu/drm/spacemit/spacemit_cmdlist.c
@@ -0,0 +1,198 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (C) 2025-2026 SpacemiT Co., Ltd.
+ *
+ */
+
+#include <linux/dma-mapping.h>
+#include <linux/string.h>
+
+#include <drm/drm_atomic.h>
+#include <drm/drm_managed.h>
+#include <drm/drm_print.h>
+
+#include "dpu/dpu_saturn.h"
+#include "dpu/saturn_regs/ops_hee.h"
+#include "spacemit_cmdlist.h"
+#include "spacemit_crtc.h"
+#include "spacemit_dpu_reg.h"
+#include "spacemit_drm.h"
+
+struct cmdlist *spacemit_plane_to_cl(struct drm_plane *plane)
+{
+	struct spacemit_plane *p = to_spacemit_plane(plane);
+
+	return &p->cl[p->cl_cur];
+}
+
+struct cmdlist *spacemit_crtc_to_cl(struct drm_crtc *crtc)
+{
+	struct spacemit_crtc *a_crtc = to_spacemit_crtc(crtc);
+
+	return &a_crtc->cl[a_crtc->cl_cur];
+}
+
+static void spacemit_cmdlist_ring_release(struct drm_device *drm, void *res)
+{
+	struct cmdlist *cl = res;
+	int i;
+
+	for (i = 0; i < CMDLIST_RING; i++) {
+		if (cl[i].va)
+			dma_free_coherent(drm->dev, cl[i].size, cl[i].va,
+					  cl[i].pa);
+	}
+}
+
+/* Allocate a channel's lists once, for the life of the DRM device. */
+int spacemit_cmdlist_ring_init(struct drm_device *drm, struct cmdlist cl[CMDLIST_RING],
+			       enum cmdlist_type type, struct drm_plane *plane,
+		      struct drm_crtc *crtc)
+{
+	int i;
+
+	for (i = 0; i < CMDLIST_RING; i++) {
+		cl[i].type = type;
+		cl[i].plane = plane;
+		cl[i].crtc = crtc;
+		cl[i].size = PER_CMDLIST_SIZE;
+		cl[i].va = dma_alloc_coherent(drm->dev, cl[i].size, &cl[i].pa,
+					      GFP_KERNEL);
+		if (!cl[i].va) {
+			spacemit_cmdlist_ring_release(drm, cl);
+			return -ENOMEM;
+		}
+	}
+
+	return drmm_add_action_or_reset(drm, spacemit_cmdlist_ring_release, cl);
+}
+
+/* Switch to the other list and empty it for this commit. */
+struct cmdlist *spacemit_cmdlist_ring_next(struct cmdlist cl[CMDLIST_RING], u8 *cur)
+{
+	struct cmdlist *next;
+
+	*cur ^= 1;
+	next = &cl[*cur];
+	next->nod_len = 0;
+	next->mode_mask = 0;
+	memset(next->va, 0, CMDLIST_HEADER_SIZE);
+
+	return next;
+}
+
+/* Allocated once at init: the commit tail has no way to fail. */
+struct cmdlist_regs *spacemit_cmdlist_regs_alloc(struct drm_device *drm,
+						 u16 nwords)
+{
+	struct cmdlist_regs *regs;
+
+	regs = drmm_kzalloc(drm, sizeof(*regs), GFP_KERNEL);
+	if (!regs)
+		return NULL;
+
+	regs->size = nwords;
+	regs->module = drmm_kcalloc(drm, nwords, sizeof(*regs->module),
+				    GFP_KERNEL);
+	regs->flags = drmm_kcalloc(drm, nwords, sizeof(*regs->flags),
+				   GFP_KERNEL);
+	if (!regs->module || !regs->flags)
+		return NULL;
+
+	return regs;
+}
+
+/* Append the words written to @cl_regs to @cl and empty the image. */
+void spacemit_cmdlist_regs_packing(struct cmdlist *cl, enum cmdlist_mode_type mod,
+				   struct cmdlist_regs *cl_regs)
+{
+	struct drm_device *drm;
+	u32 *reg_base;
+	int i;
+	u32 index;
+
+	drm = cl->type == CMDLIST_PLANE ? cl->plane->dev : cl->crtc->dev;
+
+	reg_base = cl_regs->module;
+
+	cl->mode_mask |= mod;
+
+	/* Allocated in spacemit_cmdlist_ring_init(); without it the writes vanish. */
+	if (drm_WARN_ON(drm, !cl->va))
+		goto out;
+
+	for (i = 0; i < cl_regs->size;) {
+		u32 value[CMDLIST_ROW_REGS] = {0x0};
+		u32 offset, strobe = 0;
+
+		if (cl_regs->flags[i]) {
+			offset = cl_regs->base + i * sizeof(u32);
+			for (u8 j = 0; j < CMDLIST_ROW_REGS; j++) {
+				index = i + j;
+				if (likely(index < cl_regs->size)) {
+					if (cl_regs->flags[index]) {
+						value[j] = reg_base[index];
+						strobe |= CMDLIST_REG_STROBE(j);
+					}
+				} else {
+					break;
+				}
+			}
+			if (!saturn_hee_cmdlist_fill_data_row(cl, strobe, offset,
+							      value)) {
+				drm_WARN_ONCE(drm, 1,
+					      "cmdlist buffer full (rows %u)\n",
+					      cl->nod_len);
+				goto out;
+			}
+			/*
+			 * the row covers the whole window; a shorter stride
+			 * would revisit covered words as duplicate rows
+			 */
+			i += CMDLIST_ROW_REGS;
+			cl->nod_len++;
+		} else {
+			i++;
+		}
+	}
+
+	drm_dbg(drm, "row_num = %d\n", cl->nod_len);
+out:
+	memset(cl_regs->flags, 0, cl_regs->size);
+}
+
+/*
+ * Terminate the plane's list and point its read channel at it; the engine
+ * replays it at the next CFG_RDY.
+ */
+void spacemit_cmdlist_submit_plane(struct drm_plane *plane,
+				   struct drm_plane_state *state)
+{
+	struct spacemit_plane *p = to_spacemit_plane(plane);
+	struct spacemit_crtc *a_crtc = to_spacemit_crtc(state->crtc);
+	struct spacemit_drm_private *priv = plane->dev->dev_private;
+	struct spacemit_hw_device *hwdev = priv->hwdev;
+	struct cmdlist *cl = spacemit_plane_to_cl(plane);
+	u32 addrl, addrh;
+
+	saturn_hee_cmdlist_fill_conf_row(cl, state->dst.y1);
+
+	addrl = (lower_32_bits(cl->pa) & CMDLIST_ADDRL_ALIGN_MASK) >>
+		CMDLIST_ADDRL_ALIGN_BITS;
+	addrh = upper_32_bits(cl->pa);
+
+	saturn_hee_enable_cmdlist(a_crtc, hwdev, p->rdma_id, false);
+	saturn_hee_cfg_cmdlist(hwdev, p->rdma_id, state->dst.y1, addrl, addrh);
+	saturn_hee_enable_cmdlist(a_crtc, hwdev, p->rdma_id, true);
+}
+
+/* Terminate the CRTC's compose list and point the composer channel at it. */
+void spacemit_cmdlist_submit_crtc(struct spacemit_crtc *a_crtc)
+{
+	struct drm_crtc *crtc = &a_crtc->crtc;
+	struct spacemit_drm_private *priv = crtc->dev->dev_private;
+	struct cmdlist *cl = spacemit_crtc_to_cl(crtc);
+
+	saturn_hee_cmdlist_fill_conf_row(cl, 0);
+	saturn_hee_crtc_cmdlist(priv->hwdev, cl->pa, drm_crtc_index(crtc));
+}
diff --git a/drivers/gpu/drm/spacemit/spacemit_cmdlist.h b/drivers/gpu/drm/spacemit/spacemit_cmdlist.h
new file mode 100644
index 0000000000000..ebf2e26f48188
--- /dev/null
+++ b/drivers/gpu/drm/spacemit/spacemit_cmdlist.h
@@ -0,0 +1,133 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Copyright (C) 2025-2026 SpacemiT Co., Ltd.
+ *
+ */
+
+#ifndef _SPACEMIT_CMDLIST_H_
+#define _SPACEMIT_CMDLIST_H_
+
+#include <linux/bits.h>
+#include <linux/io.h>
+#include <linux/types.h>
+
+#include <drm/drm_crtc.h>
+#include <drm/drm_plane.h>
+
+struct spacemit_crtc;
+struct spacemit_plane_state;
+
+#define PER_CMDLIST_SIZE             4096
+/* The engine's node header; rows follow it. Layout in dpu_saturn_hee.c. */
+#define CMDLIST_HEADER_SIZE          16
+#define CMDLIST_ROW_REGS	(3)
+
+/**
+ * enum cmdlist_type - what surface owns a cmdlist instance
+ * @CMDLIST_PLANE: Per-plane RDMA register batches.
+ * @CMDLIST_CRTC: Compose-side batches submitted on every flush.
+ */
+enum cmdlist_type {
+	CMDLIST_PLANE = 1,
+	CMDLIST_CRTC,
+};
+
+/**
+ * struct cmdlist - A DMA-backed batch of register writes replayed at CFG_RDY
+ * @nod_len: Number of register-write rows currently filled.
+ * @size: Capacity of the DMA buffer in bytes.
+ * @mode_mask: &enum cmdlist_mode_type bits of the blocks packed into the
+ *	       list; selects the wait events and CFG_RDY bits when it is closed.
+ * @va: Kernel virtual address of the DMA buffer.
+ * @pa: DMA address programmed into the cmdlist base register.
+ * @type: Originating surface; see &enum cmdlist_type.
+ * @plane: Owning plane for a %CMDLIST_PLANE list.
+ * @crtc: Owning CRTC for a %CMDLIST_CRTC list.
+ */
+struct cmdlist {
+	u16 nod_len;
+	u32 size;
+	u32 mode_mask;
+	void *va;
+	dma_addr_t pa;
+	u8 type;
+	struct drm_plane *plane;
+	struct drm_crtc *crtc;
+};
+
+/*
+ * Two lists per channel, used alternately: the engine may still re-read the
+ * list of the previous commit until the next CFG_RDY has been consumed, and
+ * every commit waits for that before it completes.
+ */
+#define CMDLIST_RING	2
+
+enum cmdlist_mode_type {
+	CMDLIST_MOD_RDMA = BIT(0),
+	CMDLIST_MOD_COMP = BIT(3),
+	CMDLIST_MOD_DMMU = BIT(6),
+};
+
+#define CMDLIST_REG_STROBE(index)	(0xf << ((index) * 4))
+
+#define CMDLIST_ADDRL_ALIGN_BITS               (4) /* From cmdlist_reg_0[] in CMDLIST_REG */
+#define CMDLIST_ADDRL_ALIGN_MASK \
+	((u32)(~(BIT(CMDLIST_ADDRL_ALIGN_BITS) - 1)))
+/*
+ * First touch seeds the word from a live MMIO read: only register blocks that
+ * read back what was written may be routed through cmdlist.
+ */
+#define cmdlist_write_reg(hwdev, module_name, module_base, field, data, cl_regs) \
+do { \
+	struct cmdlist_regs *cl_p = (cl_regs); \
+	u32 *__words = cl_p->module; \
+	const unsigned int __w = dpu_field_word(module_name, field); \
+	if (cl_p->flags[__w] == 0) { \
+		__words[__w] = readl((hwdev)->base + (module_base) + 4 * __w); \
+		cl_p->base = (module_base); \
+		cl_p->flags[__w] = 1; \
+	} \
+	__words[__w] &= ~dpu_field_mask(module_name, field); \
+	__words[__w] |= FIELD_PREP(dpu_field_mask(module_name, field), \
+				   (u32)(data)); \
+} while (0)
+
+/* Raw whole-word variant; no seeding needed. */
+#define cmdlist_write_word(module_base, word, data, cl_regs) \
+do { \
+	struct cmdlist_regs *cl_p = (cl_regs); \
+	u32 *__words = cl_p->module; \
+	cl_p->base = (module_base); \
+	cl_p->flags[(word)] = 1; \
+	__words[(word)] = (u32)(data); \
+} while (0)
+
+/**
+ * struct cmdlist_regs - Scratch image of one register block
+ * @base: Offset of the block the image currently describes.
+ * @size: Number of words in the block.
+ * @module: The words.
+ * @flags: Nonzero for each word written since the image was last packed.
+ */
+struct cmdlist_regs {
+	u32 base;
+	u16 size;
+	u32 *module;
+	u8 *flags;
+};
+
+struct cmdlist_regs *spacemit_cmdlist_regs_alloc(struct drm_device *drm,
+						 u16 nwords);
+void spacemit_cmdlist_regs_packing(struct cmdlist *cl, enum cmdlist_mode_type mod,
+				   struct cmdlist_regs *cl_regs);
+int spacemit_cmdlist_ring_init(struct drm_device *drm, struct cmdlist cl[CMDLIST_RING],
+			       enum cmdlist_type type, struct drm_plane *plane,
+		      struct drm_crtc *crtc);
+struct cmdlist *spacemit_cmdlist_ring_next(struct cmdlist cl[CMDLIST_RING], u8 *cur);
+void spacemit_cmdlist_submit_plane(struct drm_plane *plane,
+				   struct drm_plane_state *state);
+void spacemit_cmdlist_submit_crtc(struct spacemit_crtc *a_crtc);
+struct cmdlist *spacemit_plane_to_cl(struct drm_plane *plane);
+struct cmdlist *spacemit_crtc_to_cl(struct drm_crtc *crtc);
+
+#endif /* _SPACEMIT_CMDLIST_H_ */
diff --git a/drivers/gpu/drm/spacemit/spacemit_crtc.h b/drivers/gpu/drm/spacemit/spacemit_crtc.h
new file mode 100644
index 0000000000000..d1f7ebe5d1a9d
--- /dev/null
+++ b/drivers/gpu/drm/spacemit/spacemit_crtc.h
@@ -0,0 +1,133 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Copyright (C) 2025-2026 SpacemiT Co., Ltd.
+ *
+ */
+
+#ifndef _SPACEMIT_CRTC_H_
+#define _SPACEMIT_CRTC_H_
+
+#include <linux/container_of.h>
+#include <linux/timer.h>
+#include <linux/types.h>
+
+#include <drm/drm_crtc.h>
+#include <drm/drm_plane.h>
+
+#include "spacemit_cmdlist.h"
+#include "spacemit_drm.h"
+
+struct regmap;
+
+/* RDMA stride is a 16-bit byte count; img_width/height are 16-bit fields. */
+#define SPACEMIT_DPU_MAX_FB_WIDTH	(U16_MAX / 4)
+#define SPACEMIT_DPU_MAX_FB_HEIGHT	U16_MAX
+#define SPACEMIT_DPU_MAX_PITCH		U16_MAX
+/* K3 user manual ch.12: each DPU output is at most 3840x2160. */
+#define SPACEMIT_DPU_MAX_HDISPLAY	3840
+#define SPACEMIT_DPU_MAX_VDISPLAY	2160
+
+#define DPU_MCLK_DEFAULT	307200000
+#define DPU_AXICLK_DEFAULT	409000000
+
+enum spacemit_dpu_irq {
+	INT_UNDERRUN,
+	INT_CFG_RDY,
+	INT_VSYNC,
+	INT_EOF,
+	INT_REST,
+};
+
+/**
+ * struct spacemit_crtc - Per-instance state for a Saturn DPU CRTC
+ * @crtc: Embedded DRM CRTC; reachable via to_spacemit_crtc().
+ * @cfg_rdy_timer: Watchdog for a CFG_RDY that never arrives.
+ * @is_1st_f: True until the first frame of a new modeset is transferred.
+ * @event: The commit's event, held until the engine has taken its lists;
+ *	   under &drm_device.event_lock.
+ * @cl_cmp: Scratch image of the composer registers.
+ * @cl_pp: Scratch image of the post-pipe registers.
+ * @cl: The composer channel's command lists, written alternately.
+ * @cl_cur: Index of the list being built for the current commit.
+ * @ur_reported: True once an underrun has been logged since the last CFG_RDY.
+ * @ur_mask_armed: True while saturn_hee_clr_int_sts() may still mask the
+ *		   underrun IRQ.
+ */
+struct spacemit_crtc {
+	struct drm_crtc crtc;
+	struct timer_list cfg_rdy_timer;
+
+	bool is_1st_f;
+	struct drm_pending_vblank_event *event;
+
+	struct cmdlist_regs *cl_cmp;
+	struct cmdlist_regs *cl_pp;
+	struct cmdlist cl[CMDLIST_RING];
+	u8 cl_cur;
+
+	bool ur_reported;
+	bool ur_mask_armed;
+};
+
+static inline struct spacemit_crtc *to_spacemit_crtc(struct drm_crtc *crtc)
+{
+	return container_of(crtc, struct spacemit_crtc, crtc);
+}
+
+struct spacemit_hw_device;
+
+/**
+ * struct spacemit_plane - Subclassed drm_plane for the Saturn DPU
+ * @plane: Base DRM plane.
+ * @rdma_id: The RDMA read channel this plane scans out through, fixed at init.
+ * @cl: The channel's command lists, written alternately.
+ * @cl_cur: Index of the list being built for the current commit.
+ * @cl_rdma: Scratch image of the read channel's registers.
+ * @cl_tbu: Scratch image of the channel's TBU registers.
+ */
+struct spacemit_plane {
+	struct drm_plane plane;
+	u8 rdma_id;
+	struct cmdlist_regs *cl_rdma;
+	struct cmdlist_regs *cl_tbu;
+	struct cmdlist cl[CMDLIST_RING];
+	u8 cl_cur;
+};
+
+/**
+ * struct spacemit_plane_state - Subclassed drm_plane_state for the Saturn DPU
+ * @state: Embedded drm_plane_state; reachable via to_spacemit_plane_state().
+ * @format: DPU-internal pixel-format token translated from the fourcc.
+ * @fbcmem_size: Line-buffer units (FBCMEM_UNIT bytes) this plane needs.
+ */
+struct spacemit_plane_state {
+	struct drm_plane_state state;
+	u8 format;
+	u32 fbcmem_size;
+};
+
+struct spacemit_plane *to_spacemit_plane(struct drm_plane *plane);
+
+static inline struct
+spacemit_plane_state *
+to_spacemit_plane_state(const struct drm_plane_state *state)
+{
+	return container_of(state, struct spacemit_plane_state, state);
+}
+
+struct drm_plane *spacemit_plane_init(struct drm_device *drm);
+
+/*
+ * Per-revision Saturn DPU description. One static instance per DT compatible,
+ * copied at probe.
+ */
+struct spacemit_hw_device {
+	void __iomem *base;
+	struct regmap *regmap;
+	u8 rdma_nums;
+	u8 n_formats;
+	const struct dpu_format_id *formats;
+	u8 n_fbcmems;
+	const u32 *fbcmem_sizes;
+};
+#endif
diff --git a/drivers/gpu/drm/spacemit/spacemit_dmmu.c b/drivers/gpu/drm/spacemit/spacemit_dmmu.c
new file mode 100644
index 0000000000000..e886547cff6a3
--- /dev/null
+++ b/drivers/gpu/drm/spacemit/spacemit_dmmu.c
@@ -0,0 +1,119 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (C) 2023-2026 SpacemiT Co., Ltd.
+ *
+ */
+
+#include <linux/cleanup.h>
+#include <linux/dma-mapping.h>
+#include <linux/gfp.h>
+#include <linux/stddef.h>
+
+#include <drm/drm_framebuffer.h>
+#include <drm/drm_gem_shmem_helper.h>
+
+#include "dpu/saturn_regs/ops_hee.h"
+#include "spacemit_cmdlist.h"
+#include "spacemit_crtc.h"
+#include "spacemit_dmmu.h"
+#include "spacemit_dpu_reg.h"
+#include "spacemit_drm.h"
+
+static inline void spacemit_dmmu_fill_pgtable(struct drm_device *drm,
+					      struct dpu_mmu_tbl *tbl,
+					      struct sg_table *sgt)
+{
+	struct sg_dma_page_iter dma_iter;
+	u32 max_entries = tbl->size / 4;
+	u32 *ttbr = tbl->va;
+	u32 i = 0, n = 0, temp = 0;
+
+	for_each_sgtable_dma_page(sgt, &dma_iter, 0) {
+		/*
+		 * The table was sized from this object, so running past it is
+		 * a driver bug.
+		 */
+		if (drm_WARN_ON_ONCE(drm, n + HW_ALIGN_TTB_NUM >= max_entries))
+			break;
+		ttbr[n++] = SPACEMIT_DMMU_PFN_MASK &
+			    (sg_page_iter_dma_address(&dma_iter) >> PAGE_SHIFT);
+	}
+
+	if (drm_WARN_ON_ONCE(drm, !n))
+		return;
+
+	/*
+	 * The silicon over-fetches past the last entry; pad it to avoid a DDR
+	 * fault.
+	 */
+	temp = ttbr[n - 1];
+	for (i = 0; i < HW_ALIGN_TTB_NUM; i++)
+		ttbr[n++] = temp;
+}
+
+/*
+ * Build the translation table for @obj once. The table describes the buffer,
+ * not a plane state, so it lives with the object and is reused by every
+ * commit that scans the buffer out.
+ */
+int spacemit_dmmu_prepare(struct drm_gem_object *obj)
+{
+	struct spacemit_gem_object *sgem = to_spacemit_gem(obj);
+	struct drm_gem_shmem_object *shmem = &sgem->base;
+	struct device *dev = obj->dev->dev;
+	struct dpu_mmu_tbl tbl;
+	struct sg_table *sgt;
+
+	guard(mutex)(&sgem->tbl_lock);
+
+	if (sgem->mmu_tbl.va)
+		return 0;
+
+	/* An imported dma-buf has its sg table mapped for this device. */
+	if (drm_gem_is_imported(obj)) {
+		sgt = shmem->sgt;
+		if (!sgt)
+			return -EINVAL;
+	} else {
+		sgt = drm_gem_shmem_get_pages_sgt(shmem);
+		if (IS_ERR(sgt))
+			return PTR_ERR(sgt);
+	}
+
+	tbl.size = ((PAGE_ALIGN(obj->size) >> PAGE_SHIFT) + HW_ALIGN_TTB_NUM) * 4;
+	tbl.va = dma_alloc_coherent(dev, tbl.size, &tbl.pa, GFP_KERNEL);
+	if (!tbl.va)
+		return -ENOMEM;
+
+	spacemit_dmmu_fill_pgtable(obj->dev, &tbl, sgt);
+	sgem->mmu_tbl = tbl;
+
+	return 0;
+}
+
+void spacemit_dmmu_release(struct drm_gem_object *obj)
+{
+	struct spacemit_gem_object *sgem = to_spacemit_gem(obj);
+
+	if (sgem->mmu_tbl.va)
+		dma_free_coherent(obj->dev->dev, sgem->mmu_tbl.size,
+				  sgem->mmu_tbl.va, sgem->mmu_tbl.pa);
+	mutex_destroy(&sgem->tbl_lock);
+}
+
+/* Point the plane's TBU at the framebuffer's table; built in prepare_fb. */
+void spacemit_dmmu_map(struct drm_framebuffer *fb, u8 tbu_id,
+		       struct cmdlist_regs *cl_rdma, struct drm_plane *plane)
+{
+	struct spacemit_drm_private *priv = fb->dev->dev_private;
+	struct spacemit_hw_device *hwdev = priv->hwdev;
+	struct spacemit_gem_object *sgem = to_spacemit_gem(fb->obj[0]);
+	struct tbu_instance tbu = { };
+
+	/* Every advertised format is single-planar */
+	tbu.ttb_pa[0] = sgem->mmu_tbl.pa;
+	tbu.tbu_va[0] = TBU_BASE_VA(tbu_id);
+	tbu.ttb_size[0] = roundup(fb->obj[0]->size, PAGE_SIZE) >> PAGE_SHIFT;
+
+	saturn_hee_rdma_dmmu(hwdev, tbu_id, &tbu, fb, cl_rdma, plane);
+}
diff --git a/drivers/gpu/drm/spacemit/spacemit_dmmu.h b/drivers/gpu/drm/spacemit/spacemit_dmmu.h
new file mode 100644
index 0000000000000..b5a3b48d19893
--- /dev/null
+++ b/drivers/gpu/drm/spacemit/spacemit_dmmu.h
@@ -0,0 +1,80 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Copyright (C) 2025-2026 SpacemiT Co., Ltd.
+ *
+ */
+
+#ifndef _SPACEMIT_DMMU_H_
+#define _SPACEMIT_DMMU_H_
+
+#include <linux/bits.h>
+#include <linux/mutex.h>
+#include <linux/types.h>
+
+#include <drm/drm_file.h>
+#include <drm/drm_gem_shmem_helper.h>
+
+#include "spacemit_cmdlist.h"
+
+#define DPU_QOS_URGENT	4
+/* The TLB over-fetches past the table's end, further the larger src_x is. */
+#define SPACEMIT_DMMU_MAX_SRC_X	4096
+/* Entries of padding that cover the over-fetch at SPACEMIT_DMMU_MAX_SRC_X. */
+#define HW_ALIGN_TTB_NUM	60
+
+/* tbu_size is a 16-bit page count. */
+#define SPACEMIT_DMMU_MAX_PAGES	U16_MAX
+/* A table entry holds a 26-bit page frame number. */
+#define SPACEMIT_DMMU_PFN_MASK	GENMASK(25, 0)
+
+#define RD_OUTS_NUM             16
+#define RDMA_TIMELIMIT  0xFFFF
+
+#define BASE_VA         0x10000000ULL
+#define VA_STEP_PER_TBU 0x40000000ULL
+
+#define TBU_BASE_VA(tbu_id) ((u64)BASE_VA + (u64)VA_STEP_PER_TBU * (tbu_id))
+
+struct tbu_instance {
+	u64 ttb_pa[3];
+	u64 tbu_va[3];
+	u32 ttb_size[3];
+};
+
+/**
+ * struct dpu_mmu_tbl - DMMU translation table for one buffer object
+ * @size: Bytes of table, including the over-fetch padding.
+ * @va: CPU address of the table.
+ * @pa: DMA address programmed into the TBU.
+ */
+struct dpu_mmu_tbl {
+	u32 size;
+	void *va;
+	dma_addr_t pa;
+};
+
+/**
+ * struct spacemit_gem_object - shmem object plus its DMMU table
+ * @base: The shmem object.
+ * @mmu_tbl: Built on the first scanout of this buffer, freed with it.
+ * @tbl_lock: Serialises the lazy build between commits.
+ */
+struct spacemit_gem_object {
+	struct drm_gem_shmem_object base;
+	struct dpu_mmu_tbl mmu_tbl;
+	struct mutex tbl_lock;	/* serialises the build of @mmu_tbl */
+};
+
+static inline struct spacemit_gem_object *
+to_spacemit_gem(struct drm_gem_object *obj)
+{
+	return container_of(to_drm_gem_shmem_obj(obj), struct spacemit_gem_object,
+			    base);
+}
+
+int spacemit_dmmu_prepare(struct drm_gem_object *obj);
+void spacemit_dmmu_release(struct drm_gem_object *obj);
+void spacemit_dmmu_map(struct drm_framebuffer *fb, u8 tbu_id,
+		       struct cmdlist_regs *cl_rdma, struct drm_plane *plane);
+
+#endif /* _SPACEMIT_DMMU_H_ */
diff --git a/drivers/gpu/drm/spacemit/spacemit_dpu_reg.h b/drivers/gpu/drm/spacemit/spacemit_dpu_reg.h
new file mode 100644
index 0000000000000..4147f5f548f1c
--- /dev/null
+++ b/drivers/gpu/drm/spacemit/spacemit_dpu_reg.h
@@ -0,0 +1,99 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Copyright (C) 2025-2026 SpacemiT Co., Ltd.
+ *
+ * Saturn DPU register accessors.
+ */
+
+#ifndef _SPACEMIT_DPU_REG_H_
+#define _SPACEMIT_DPU_REG_H_
+
+#include <linux/bitfield.h>
+#include <linux/io.h>
+
+#include "dpu/saturn_regs/saturn_fields.h"
+
+#define dpu_field_word(module_name, field)	(module_name##__##field##_WORD)
+#define dpu_field_mask(module_name, field)	(module_name##__##field##_MASK)
+
+/* MMIO field read: returns the field value shifted down to bit 0. */
+#define dpu_read_reg(hwdev, module_name, module_base, field)		\
+	FIELD_GET(dpu_field_mask(module_name, field),			\
+		  readl((hwdev)->base + (module_base) +			\
+			4 * dpu_field_word(module_name, field)))
+
+/* MMIO raw 32-bit register read/write by word index within the block. */
+#define dpu_read_word(hwdev, module_base, word)				\
+	readl((hwdev)->base + (module_base) + 4 * (word))
+
+#define dpu_write_reg_word(hwdev, module_base, word, data)		\
+	writel((u32)(data), (hwdev)->base + (module_base) + 4 * (word))
+
+/*
+ * Not every DPU config word reads back what was written, so a byte- or
+ * halfword-aligned field is stored at its own width rather than read-modified.
+ */
+#define __dpu_mmio_field_write(__addr, __mask, data)			\
+do {									\
+	if ((__mask) == 0xffU)						\
+		writeb((u8)((data) & 0xffU), __addr);			\
+	else if ((__mask) == 0xff00U)					\
+		writeb((u8)((data) & 0xffU), (__addr) + 1);		\
+	else if ((__mask) == 0xff0000U)					\
+		writeb((u8)((data) & 0xffU), (__addr) + 2);		\
+	else if ((__mask) == 0xff000000U)				\
+		writeb((u8)((data) & 0xffU), (__addr) + 3);		\
+	else if ((__mask) == 0xffffU)					\
+		writew((u16)((data) & 0xffffU), __addr);		\
+	else if ((__mask) == 0xffff0000U)				\
+		writew((u16)((data) & 0xffffU), (__addr) + 2);		\
+	else if ((__mask) == 0xffffffffU)				\
+		writel((u32)(data), __addr);				\
+	else								\
+		writel((readl(__addr) & ~(__mask)) |			\
+		       FIELD_PREP(__mask, (u32)(data)), __addr);	\
+} while (0)
+
+#define dpu_write_reg(hwdev, module_name, module_base, field, data)	\
+do {									\
+	void __iomem *__waddr = (hwdev)->base + (module_base) +	\
+				4 * dpu_field_word(module_name, field);	\
+	__dpu_mmio_field_write(__waddr,					\
+			       dpu_field_mask(module_name, field), data); \
+} while (0)
+
+/* Field write into a register array element; the index is a runtime value. */
+#define dpu_write_reg_arr(hwdev, module_name, module_base, arr, i, field, data) \
+do {									\
+	void __iomem *__waddr = (hwdev)->base + (module_base) +	\
+		4 * module_name##__##arr##__##field##_WORD(i);		\
+	__dpu_mmio_field_write(__waddr,					\
+			       module_name##__##arr##__##field##_MASK,	\
+			       data);					\
+} while (0)
+
+/*
+ * Unified CPU/cmdlist field write; a NULL cl_regs selects the direct MMIO path.
+ */
+#define _dpu_write_reg(hwdev, module_name, module_base, field, data, cl_regs, ...) \
+do {									\
+	if ((cl_regs) != NULL)						\
+		cmdlist_write_reg(hwdev, module_name, module_base,	\
+				  field, data, cl_regs);		\
+	else								\
+		dpu_write_reg(hwdev, module_name, module_base, field,	\
+			      data);					\
+} while (0)
+
+#define dpu_write(...) _dpu_write_reg(__VA_ARGS__, NULL)
+
+/* Unified CPU/cmdlist raw-word write. */
+#define dpu_write_word(hwdev, module_base, word, data, cl_regs)	\
+do {									\
+	if ((cl_regs) != NULL)						\
+		cmdlist_write_word(module_base, word, data, cl_regs);	\
+	else								\
+		dpu_write_reg_word(hwdev, module_base, word, data);	\
+} while (0)
+
+#endif
diff --git a/drivers/gpu/drm/spacemit/spacemit_drm.h b/drivers/gpu/drm/spacemit/spacemit_drm.h
new file mode 100644
index 0000000000000..af969194057b8
--- /dev/null
+++ b/drivers/gpu/drm/spacemit/spacemit_drm.h
@@ -0,0 +1,62 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Copyright (C) 2025-2026 SpacemiT Co., Ltd.
+ *
+ */
+
+#ifndef _SPACEMIT_DRM_H_
+#define _SPACEMIT_DRM_H_
+
+#include <linux/clk.h>
+#include <linux/dma-mapping.h>
+#include <linux/reset.h>
+
+#include <drm/drm_atomic.h>
+#include <drm/drm_drv.h>
+#include <drm/drm_print.h>
+#include <drm/drm_probe_helper.h>
+#include <drm/drm_vblank.h>
+
+#include "spacemit_dmmu.h"
+
+/* The DPU's clock inputs, as named by the binding. */
+struct dpu_clk_context {
+	struct clk *pxclk;
+	struct clk *mclk;
+	struct clk *escclk;
+	struct clk *aclk;
+	struct clk *dscclk;
+};
+
+/**
+ * struct spacemit_drm_private - Top-level driver state for the SpacemiT DRM
+ * card
+ * @ddev: DRM device; lives from the component master bind to its unbind.
+ * @dev: The DPU platform device; the DPU is the drm subsystem root.
+ * @a_crtc: Per-DPU CRTC state; lives as long as @ddev.
+ * @hwdev: Per-revision Saturn DPU description.
+ * @clk_ctx: The DPU's clocks, acquired once at probe.
+ * @clocks_on: True while clocks run; MMIO on a gated DPU stalls the bus.
+ * @pipe_resets: The DPU reset lines, in assert order; bulk-deassert
+ *		 releases them in reverse.
+ * @irq_online: Online-compose IRQ; requested disabled, enabled at bind.
+ */
+struct spacemit_drm_private {
+	struct drm_device *ddev;
+	struct device *dev;
+	struct spacemit_crtc *a_crtc;
+	struct spacemit_hw_device *hwdev;
+
+	struct dpu_clk_context clk_ctx;
+	bool clocks_on;
+	struct reset_control_bulk_data pipe_resets[5];
+	int irq_online;
+};
+
+extern const struct drm_driver spacemit_drm_drv;
+extern const struct component_master_ops spacemit_drm_master_ops;
+
+int spacemit_drm_mode_config_init(struct drm_device *drm);
+int spacemit_drm_of_component_probe(struct device *dev);
+
+#endif /* _SPACEMIT_DRM_H_ */

-- 
2.43.0

