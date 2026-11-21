From: Cody Kang <codykang.hk@gmail.com>
Date: Sat, 21 Nov 2026 15:40:50 +0800
Subject: [PATCH v3 11/17] drm/spacemit: add Saturn DPU DRM device driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-k3-display-v3-11-ec419e8e96b8@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795246844; l=10267;
 i=codykang.hk@gmail.com; s=codykang; h=from:subject:message-id;
 bh=1LLB7ck/Lz0FSwwHejBfJ5Pj0yWwrzMJKJvxXMU6xuA=;
 b=9pYbXeciEjnf32sOqi+9dGMRyDmcoK6SIxZwf0R30SQFjCQ44DnEjZEP5Q3MK2L0pESnh8HS8
 VQAgAs+DSTCA/BuZ4Du4RHS6JCsQfxQVPZdJOwc2ssrrYZhsc9m1nVH
X-Developer-Key: i=codykang.hk@gmail.com; a=ed25519;
 pk=Osn6/cs9Su/mHHw4P19cmVc3v2FMQfiWahjsN0vEkuk=
X-Endpoint-Received: by B4 Relay for codykang.hk@gmail.com/codykang with auth_id=895
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Cody Kang <codykang@vsit.ai>

Add the DRM device for the SpacemiT K3 Saturn display processing unit
and hook the driver up to the build. The SoC has two DPU instances;
each drives one CRTC that scans out a single primary plane in linear
RGB at up to 3840x2160@60 and feeds a downstream DP/eDP controller
over an OF-graph endpoint. Buffers use drm_gem_shmem_helper. The
AFBC/compressed decode path is not exposed and writeback is not
implemented.

The write-combining mapping of the scanout buffers is from Sarah Emery
<sarah.emery@canonical.com>.

Signed-off-by: Cody Kang <codykang@vsit.ai>

---
v3:
- map scanout buffers write-combining (Sarah Emery); build the sg table
  when a dumb buffer is created, so the zeroes it was cleared with are
  written back before anything is drawn
- bound framebuffers by what the RDMA registers can address instead of
  by the largest mode (Icenowy Zheng)
- stop the component match loop on the first error; depend on PM
- add a GEM object wrapper carrying the display MMU table (Thomas
  Zimmermann)
v2:
- check for an ERR_PTR component match before
  component_master_add_with_match() (Sashiko)
- add a comment explaining why commit_tail waits for flip_done before
  commit_hw_done (Sashiko)
---
 drivers/gpu/drm/Kconfig                 |   1 +
 drivers/gpu/drm/Makefile                |   1 +
 drivers/gpu/drm/spacemit/Kconfig        |  18 +++
 drivers/gpu/drm/spacemit/Makefile       |  12 ++
 drivers/gpu/drm/spacemit/spacemit_drm.c | 204 ++++++++++++++++++++++++++++++++
 5 files changed, 236 insertions(+)

diff --git a/drivers/gpu/drm/Kconfig b/drivers/gpu/drm/Kconfig
index 61111d50b1c65..76abdfb25dc44 100644
--- a/drivers/gpu/drm/Kconfig
+++ b/drivers/gpu/drm/Kconfig
@@ -345,6 +345,7 @@ source "drivers/gpu/drm/renesas/Kconfig"
 source "drivers/gpu/drm/rockchip/Kconfig"
 source "drivers/gpu/drm/sitronix/Kconfig"
 source "drivers/gpu/drm/solomon/Kconfig"
+source "drivers/gpu/drm/spacemit/Kconfig"
 source "drivers/gpu/drm/sprd/Kconfig"
 source "drivers/gpu/drm/sti/Kconfig"
 source "drivers/gpu/drm/stm/Kconfig"
diff --git a/drivers/gpu/drm/Makefile b/drivers/gpu/drm/Makefile
index 2c6bc093a923a..d0ef32d224382 100644
--- a/drivers/gpu/drm/Makefile
+++ b/drivers/gpu/drm/Makefile
@@ -204,6 +204,7 @@ obj-$(CONFIG_DRM_MSM) += msm/
 obj-$(CONFIG_DRM_TEGRA) += tegra/
 obj-$(CONFIG_DRM_STM) += stm/
 obj-$(CONFIG_DRM_STI) += sti/
+obj-$(CONFIG_DRM_SPACEMIT) += spacemit/
 obj-y 			+= imx/
 obj-$(CONFIG_DRM_INGENIC) += ingenic/
 obj-$(CONFIG_DRM_LOGICVC) += logicvc/
diff --git a/drivers/gpu/drm/spacemit/Kconfig b/drivers/gpu/drm/spacemit/Kconfig
new file mode 100644
index 0000000000000..8326a7b98151a
--- /dev/null
+++ b/drivers/gpu/drm/spacemit/Kconfig
@@ -0,0 +1,18 @@
+# SPDX-License-Identifier: GPL-2.0
+
+config DRM_SPACEMIT
+	tristate "DRM support for SpacemiT display controllers"
+	depends on DRM && OF && MMU
+	depends on PM
+	depends on ARCH_SPACEMIT || COMPILE_TEST
+	select DRM_CLIENT_SELECTION
+	select DRM_KMS_HELPER
+	select DRM_GEM_SHMEM_HELPER
+	select REGMAP_MMIO
+	help
+	  Choose this option if you have a SpacemiT SoC with the Saturn
+	  display processing unit, such as the K3. The DPU scans out
+	  framebuffers through its private display MMU and feeds a
+	  DisplayPort or embedded DisplayPort controller.
+
+	  If M is selected the module will be called spacemit-drm.
diff --git a/drivers/gpu/drm/spacemit/Makefile b/drivers/gpu/drm/spacemit/Makefile
new file mode 100644
index 0000000000000..b3b148000cf7b
--- /dev/null
+++ b/drivers/gpu/drm/spacemit/Makefile
@@ -0,0 +1,12 @@
+# SPDX-License-Identifier: GPL-2.0
+
+spacemit-drm-y := spacemit_drm.o \
+		  spacemit_crtc.o \
+		  spacemit_cmdlist.o \
+		  spacemit_planes.o \
+		  spacemit_dmmu.o \
+		  dpu/dpu_saturn.o \
+		  dpu/dpu_saturn_hee.o \
+		  dpu/saturn_fbcmem.o
+
+obj-$(CONFIG_DRM_SPACEMIT) += spacemit-drm.o
diff --git a/drivers/gpu/drm/spacemit/spacemit_drm.c b/drivers/gpu/drm/spacemit/spacemit_drm.c
new file mode 100644
index 0000000000000..eb3cb5e302556
--- /dev/null
+++ b/drivers/gpu/drm/spacemit/spacemit_drm.c
@@ -0,0 +1,204 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Copyright (C) 2025-2026 SpacemiT Co., Ltd.
+ *
+ */
+
+#include <linux/component.h>
+#include <linux/of_graph.h>
+#include <linux/slab.h>
+
+#include <drm/drm_atomic_helper.h>
+#include <drm/drm_dumb_buffers.h>
+#include <drm/drm_fbdev_shmem.h>
+#include <drm/drm_framebuffer.h>
+#include <drm/drm_gem_framebuffer_helper.h>
+#include <drm/drm_gem_shmem_helper.h>
+#include <drm/drm_of.h>
+
+#include "spacemit_crtc.h"
+#include "spacemit_dmmu.h"
+#include "spacemit_drm.h"
+
+#define DRIVER_NAME	"spacemit"
+#define DRIVER_DESC	"SpacemiT SoC DRM driver"
+#define DRIVER_MAJOR	1
+#define DRIVER_MINOR	0
+
+static void spacemit_drm_atomic_commit_tail(struct drm_atomic_commit *old_state)
+{
+	struct drm_device *dev = old_state->dev;
+
+	/*
+	 * Enables before planes, and planes on active CRTCs only: the DPU is
+	 * powered from atomic_enable to atomic_disable.
+	 */
+	drm_atomic_helper_commit_modeset_disables(dev, old_state);
+
+	drm_atomic_helper_commit_modeset_enables(dev, old_state);
+
+	drm_atomic_helper_commit_planes(dev, old_state,
+					DRM_PLANE_COMMIT_ACTIVE_ONLY);
+
+	/*
+	 * Flip first, hw_done second: each channel has two command lists
+	 * written alternately, and the engine may re-read the previous one
+	 * until the next CFG_RDY has been consumed. Holding the next commit
+	 * back until this one's vblank keeps it from rewriting a list still
+	 * in use.
+	 */
+	drm_atomic_helper_wait_for_flip_done(dev, old_state);
+
+	drm_atomic_helper_commit_hw_done(old_state);
+
+	drm_atomic_helper_cleanup_planes(dev, old_state);
+}
+
+static const struct drm_mode_config_helper_funcs spacemit_drm_mode_config_helper = {
+	.atomic_commit_tail = spacemit_drm_atomic_commit_tail,
+};
+
+static const struct drm_mode_config_funcs spacemit_drm_mode_config_funcs = {
+	.fb_create = drm_gem_fb_create,
+	.atomic_check = drm_atomic_helper_check,
+	.atomic_commit = drm_atomic_helper_commit,
+};
+
+int spacemit_drm_mode_config_init(struct drm_device *drm)
+{
+	int ret;
+
+	ret = drmm_mode_config_init(drm);
+	if (ret)
+		return ret;
+
+	drm->mode_config.min_width = 1;
+	drm->mode_config.min_height = 1;
+	/*
+	 * Framebuffer bounds come from the RDMA register widths: a 16-bit
+	 * byte stride (16383 pixels at 32 bpp) and 16-bit image dimensions.
+	 * The 3840x2160 output limit is enforced per CRTC in mode_valid.
+	 */
+	drm->mode_config.max_width = SPACEMIT_DPU_MAX_FB_WIDTH;
+	drm->mode_config.max_height = SPACEMIT_DPU_MAX_FB_HEIGHT;
+
+	drm->mode_config.funcs = &spacemit_drm_mode_config_funcs;
+	drm->mode_config.helper_private = &spacemit_drm_mode_config_helper;
+
+	return 0;
+}
+
+static void spacemit_gem_free(struct drm_gem_object *obj)
+{
+	spacemit_dmmu_release(obj);
+	drm_gem_shmem_free(to_drm_gem_shmem_obj(obj));
+}
+
+/* drm_gem_shmem_funcs with a free that also drops the DMMU table. */
+static const struct drm_gem_object_funcs spacemit_gem_funcs = {
+	.free = spacemit_gem_free,
+	.print_info = drm_gem_shmem_object_print_info,
+	.pin = drm_gem_shmem_object_pin,
+	.unpin = drm_gem_shmem_object_unpin,
+	.get_sg_table = drm_gem_shmem_object_get_sg_table,
+	.vmap = drm_gem_shmem_object_vmap,
+	.vunmap = drm_gem_shmem_object_vunmap,
+	.mmap = drm_gem_shmem_object_mmap,
+	.vm_ops = &drm_gem_shmem_vm_ops,
+};
+
+static struct drm_gem_object *spacemit_gem_create_object(struct drm_device *drm,
+							 size_t size)
+{
+	struct spacemit_gem_object *sgem;
+
+	sgem = kzalloc_obj(*sgem);
+	if (!sgem)
+		return ERR_PTR(-ENOMEM);
+
+	mutex_init(&sgem->tbl_lock);
+	sgem->base.map_wc = true;
+	sgem->base.base.funcs = &spacemit_gem_funcs;
+
+	return &sgem->base.base;
+}
+
+/*
+ * A new buffer's pages are cleared through the cached linear map, while
+ * everything drawn afterwards goes through a write-combining mapping. Build
+ * the sg table now: mapping it writes the cached zeroes back before anything
+ * is drawn. Left to the first scanout, they would land on top of the picture.
+ */
+static int spacemit_gem_dumb_create(struct drm_file *file,
+				    struct drm_device *drm,
+				    struct drm_mode_create_dumb *args)
+{
+	struct drm_gem_shmem_object *shmem;
+	struct sg_table *sgt;
+	int ret;
+
+	ret = drm_mode_size_dumb(drm, args, 0, 0);
+	if (ret)
+		return ret;
+
+	shmem = drm_gem_shmem_create(drm, args->size);
+	if (IS_ERR(shmem))
+		return PTR_ERR(shmem);
+
+	sgt = drm_gem_shmem_get_pages_sgt(shmem);
+	if (IS_ERR(sgt))
+		ret = PTR_ERR(sgt);
+	else
+		ret = drm_gem_handle_create(file, &shmem->base, &args->handle);
+
+	/* On success the handle holds the reference. */
+	drm_gem_object_put(&shmem->base);
+
+	return ret;
+}
+
+DEFINE_DRM_GEM_FOPS(spacemit_drm_fops);
+
+const struct drm_driver spacemit_drm_drv = {
+	.driver_features = DRIVER_GEM | DRIVER_MODESET | DRIVER_ATOMIC,
+	.fops = &spacemit_drm_fops,
+
+	.gem_prime_import_sg_table = drm_gem_shmem_prime_import_sg_table,
+	.dumb_create = spacemit_gem_dumb_create,
+	.gem_create_object = spacemit_gem_create_object,
+	DRM_FBDEV_SHMEM_DRIVER_OPS,
+
+	.name		= DRIVER_NAME,
+	.desc		= DRIVER_DESC,
+	.major		= DRIVER_MAJOR,
+	.minor		= DRIVER_MINOR,
+};
+
+int spacemit_drm_of_component_probe(struct device *dev)
+{
+	struct component_match *match = NULL;
+	struct device_node *remote, *ep;
+
+	/* The DPU is the drm root: its OF graph names the DP/eDP components. */
+	for_each_endpoint_of_node(dev->of_node, ep) {
+		remote = of_graph_get_remote_port_parent(ep);
+		if (!remote)
+			continue;
+		if (of_device_is_available(remote))
+			drm_of_component_match_add(dev, &match,
+						   component_compare_of,
+						   remote);
+		of_node_put(remote);
+		if (IS_ERR(match)) {
+			of_node_put(ep);
+			return PTR_ERR(match);
+		}
+	}
+
+	if (!match)
+		return dev_err_probe(dev, -ENODEV,
+				     "no downstream component available\n");
+
+	return component_master_add_with_match(dev, &spacemit_drm_master_ops,
+					       match);
+}

-- 
2.43.0

