From: Angel Gabriel Crispin Valdivia <angelcrispinvaldivia@gmail.com>
Date: Thu, 05 Nov 2026 21:34:36 -0500
Subject: [PATCH RFC 4/4] drm/fl2000: Add KMS display pipeline
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-fl2000-upstream-v1-4-bb163ecb2309@gmail.com>
References: <20261105-fl2000-upstream-v1-0-bb163ecb2309@gmail.com>
In-Reply-To: <20261105-fl2000-upstream-v1-0-bb163ecb2309@gmail.com>
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Angel Gabriel Crispin Valdivia <angelcrispinvaldivia@gmail.com>
Cc: linux-kernel@vger.kernel.org, dri-devel@lists.freedesktop.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793932482; l=62279;
 i=angelcrispinvaldivia@gmail.com; s=20261106; h=from:subject:message-id;
 bh=g98QH4oZOcnwE6enjTTu6UgAZSYaMhzQ6MOKBAKstnQ=;
 b=2lecc1YYWewcZgpitrL5B89LBlofNeUKAE1M7u1pYn/bcDBSCM/qT12fKHqcp8LzjgjIuC48y
 ci24oCnVou/CKmLHipQMdu9jfweNieWp5ArUyy1QZ6tcmz/fyG/02nX
X-Developer-Key: i=angelcrispinvaldivia@gmail.com; a=ed25519;
 pk=80bQU/p2R0pLIfdfJaB5I/2obI+RxQHondq5DEM0tbg=
X-Endpoint-Received: by B4 Relay for angelcrispinvaldivia@gmail.com/20261106 with auth_id=1425
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Register the DRM device once all FL2000 interfaces are bound and the
IT66121 component is available, and connect the pieces:

- a primary plane, a cursor plane, a CRTC and an encoder, with GEM
  SHMEM framebuffers accessed through the shadow-plane helpers and
  XRGB8888 (and the two 10-bit formats compositors render in, reduced
  to 8 bits) as formats. The framebuffer is only read by the CPU, so it
  does not need to be physically contiguous. The primary plane passes
  its merged damage to the stream; the cursor plane hands over its
  sprite, or only its position when the framebuffer is unchanged.
  Without a cursor plane, compositors keep the pointer on the primary
  GPU and it never appears on this output
- mode validation and PLL search in the CRTC's atomic_check (which
  adjusts the clock in adjusted_mode), and FL2000 programming in
  mode_set_nofb, before the bridge is enabled. The PLL cannot make
  most pixel clocks exactly: digital sinks are only offered modes it
  hits within 500 ppm, while the VGA output accepts 5000 ppm, since an
  analog monitor does not notice that but does notice a changed htotal
- the HDMI connector from drm_bridge_connector_init() on the encoder the
  IT66121 bridge is attached to. It is polled, as the bridge has no hot
  plug interrupt of its own
- the analog VGA output of the chip, which adapters with a VGA
  connector expose next to the HDMI one: a DAC encoder and a VGA
  connector on the same CRTC (the two encoders are clones of each
  other). The chip has one monitor sense input, which follows
  whichever monitor is plugged in, so the VGA connector reports a
  monitor when the chip senses one and the IT66121 does not; the EDID
  is read with the FL2000 I2C engine, kept while the monitor stays, and
  without one the standard timings are offered
- vblank from the DRM vblank timer, as the FL2000 has no vblank
  interrupt, and fbdev emulation
- the FL2000 interrupt endpoint, which reports monitor and IT66121
  events and triggers a hotplug event

Tested on x86_64 with a UGREEN USB 3.0 adapter with HDMI and VGA
connectors (FL2000DX + IT66121FN): a 1920x1080 monitor on HDMI and an
old 1366x768 monitor without a usable EDID on VGA. EDID, mode setting
and a GNOME Wayland desktop work, with the cursor, at 59 frames per
second on the link and no measurable effect on the rest of the system.
Adapters with a VGA connector only (no IT66121) are not supported.

Signed-off-by: Angel Gabriel Crispin Valdivia <angelcrispinvaldivia@gmail.com>
---
 drivers/gpu/drm/fl2000/Makefile           |   5 +-
 drivers/gpu/drm/fl2000/fl2000.h           |  37 ++
 drivers/gpu/drm/fl2000/fl2000_drm.c       | 986 ++++++++++++++++++++++++++++++
 drivers/gpu/drm/fl2000/fl2000_drv.c       |  93 ++-
 drivers/gpu/drm/fl2000/fl2000_interrupt.c | 237 +++++++
 drivers/gpu/drm/fl2000/fl2000_vga.c       | 256 ++++++++
 6 files changed, 1602 insertions(+), 12 deletions(-)

diff --git a/drivers/gpu/drm/fl2000/Makefile b/drivers/gpu/drm/fl2000/Makefile
index 0671c867e..e3e9cb72b 100644
--- a/drivers/gpu/drm/fl2000/Makefile
+++ b/drivers/gpu/drm/fl2000/Makefile
@@ -1,10 +1,13 @@
 # SPDX-License-Identifier: GPL-2.0-only
 
 fl2000-y := \
+	fl2000_drm.o \
 	fl2000_drv.o \
 	fl2000_i2c.o \
+	fl2000_interrupt.o \
 	fl2000_it66121.o \
 	fl2000_registers.o \
-	fl2000_streaming.o
+	fl2000_streaming.o \
+	fl2000_vga.o
 
 obj-$(CONFIG_DRM_FL2000) += fl2000.o
diff --git a/drivers/gpu/drm/fl2000/fl2000.h b/drivers/gpu/drm/fl2000/fl2000.h
index d800d943e..ee452576e 100644
--- a/drivers/gpu/drm/fl2000/fl2000.h
+++ b/drivers/gpu/drm/fl2000/fl2000.h
@@ -131,6 +131,36 @@ void fl2000_stream_move_cursor(struct fl2000_stream *stream, int x, int y);
 int fl2000_stream_enable(struct fl2000_stream *stream);
 void fl2000_stream_disable(struct fl2000_stream *stream);
 
+/* Interrupt polling task */
+struct fl2000_intr;
+struct fl2000_intr *fl2000_intr_create(struct usb_device *usb_dev, struct drm_device *drm);
+void fl2000_intr_quiesce(struct fl2000_intr *intr);
+void fl2000_intr_suspend(struct fl2000_intr *intr);
+int fl2000_intr_resume(struct fl2000_intr *intr);
+int fl2000_intr_monitor_connected(struct fl2000_intr *intr);
+void fl2000_intr_destroy(struct usb_device *usb_dev);
+
+/* VGA output: a DAC encoder and connector next to the HDMI ones, on the same CRTC */
+struct drm_edid;
+struct fl2000_vga {
+	struct drm_encoder encoder;
+	struct drm_connector connector;
+	struct i2c_adapter *adapter;
+	struct fl2000_intr *intr;
+	/* The HDMI transmitter shares the chip's monitor sense with this output */
+	struct drm_bridge *hdmi_bridge;
+	/* EDID of the monitor, kept for as long as it stays connected; NULL if it has none */
+	const struct drm_edid *edid;
+	unsigned int edid_tries;
+	/* The monitor changed or went away: read the EDID again on the next probe */
+	bool edid_stale;
+};
+
+int fl2000_vga_init(struct drm_device *drm, struct fl2000_vga *vga, struct drm_crtc *crtc,
+		    struct drm_encoder *hdmi_encoder, struct i2c_adapter *adapter,
+		    struct fl2000_intr *intr);
+void fl2000_vga_sink_event(struct fl2000_vga *vga);
+
 /* I2C adapter interface creation */
 struct i2c_adapter *fl2000_i2c_init(struct usb_device *usb_dev);
 int fl2000_ddc_read_block(struct i2c_adapter *adapter, u8 *buf, unsigned int block, size_t len);
@@ -152,4 +182,11 @@ int fl2000_enable_interrupts(struct usb_device *usb_dev);
 int fl2000_read_status(struct usb_device *usb_dev, u32 *status);
 int fl2000_i2c_dword(struct usb_device *usb_dev, bool read, u16 addr, u8 offset, u32 *data);
 
+/* DRM device creation */
+int fl2000_drm_bind(struct device *master);
+void fl2000_drm_unbind(struct device *master);
+void fl2000_drm_hotplug(struct drm_device *drm, u32 events);
+int fl2000_drm_suspend(struct device *master);
+int fl2000_drm_resume(struct device *master);
+
 #endif /* FL2000_H */
diff --git a/drivers/gpu/drm/fl2000/fl2000_drm.c b/drivers/gpu/drm/fl2000/fl2000_drm.c
new file mode 100644
index 000000000..2c0c87854
--- /dev/null
+++ b/drivers/gpu/drm/fl2000/fl2000_drm.c
@@ -0,0 +1,986 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * (C) Copyright 2012, Red Hat
+ * (C) Copyright 2018-2020, Artem Mygaiev
+ */
+
+#include <linux/math64.h>
+
+#include <drm/clients/drm_client_setup.h>
+#include <drm/drm_bridge_connector.h>
+#include <drm/drm_connector.h>
+#include <drm/drm_fbdev_shmem.h>
+#include <drm/drm_gem_atomic_helper.h>
+#include <drm/drm_modeset_helper.h>
+#include <drm/drm_probe_helper.h>
+#include <drm/drm_vblank_helper.h>
+
+#include "fl2000.h"
+#include "fl2000_it66121.h"
+
+#define DRM_DRIVER_NAME "fl2000"
+#define DRM_DRIVER_DESC "Fresco Logic FL2000 USB display"
+
+#define DRM_DRIVER_MAJOR      0
+#define DRM_DRIVER_MINOR      0
+#define DRM_DRIVER_PATCHLEVEL 1
+
+/* Maximum supported resolution, no documented hardware limit */
+#define FL2000_MAX_WIDTH  4000
+#define FL2000_MAX_HEIGHT 4000
+
+/*
+ * 32-bit input. The 10-bit formats are accepted because the compositor hands
+ * us its scanout buffer as it is: Mutter renders ARGB2101010 and, when the
+ * secondary output cannot take that format, falls back to a copy path that
+ * has leaked GPU memory until the desktop stalled.
+ */
+#define FL2000_FB_BPP 32
+static const u32 fl2000_pixel_formats[] = {
+	DRM_FORMAT_XRGB8888,
+	DRM_FORMAT_XRGB2101010,
+	DRM_FORMAT_ARGB2101010,
+};
+
+/* The cursor sprite is blended into the outgoing frame by the CPU */
+static const u32 fl2000_cursor_formats[] = {
+	DRM_FORMAT_ARGB8888,
+};
+
+/*
+ * Maximum pixel clock set to 500MHz. It is hard to get more or less precise PLL configuration for
+ * higher clock.
+ */
+#define FL2000_MAX_PIXCLOCK 500000000
+
+/* PLL computing precision is 6 digits after the decimal point */
+#define FL2000_PLL_PRECISION 1000000
+
+/* Input xtal clock, Hz */
+#define FL2000_XTAL 10000000 /* 10 MHz */
+
+/* Internal vco clock min/max, Hz */
+#define FL2000_VCOCLOCK_MIN 62500000 /* 62.5 MHz */
+#define FL2000_VCOCLOCK_MAX 1000000000 /* 1 GHz */
+
+/*
+ * Maximum acceptable ppm error of the pixel clock. Digital sinks get the exact clock or nothing;
+ * an analog monitor locks to the line rate of whatever it is sent, so a clock off by half a
+ * percent goes unnoticed, while changing the length of a line (htotal) throws its sampling off.
+ */
+#define FL2000_PPM_ERR_MAX	500
+#define FL2000_PPM_ERR_MAX_VGA	5000
+
+/*
+ * Bulk payload the link sustains, bytes per second. High speed carries at most 13 packets of 512
+ * bytes per 125 us microframe (53 MB/s); SuperSpeed 500 MB/s after its 8b/10b encoding. Packet and
+ * link overhead are taken as 10 %. On SuperSpeed 1920x1080 at 60 Hz in RGB888 (373 MB/s) streams
+ * fine, and the vendor driver offers 1920x1200 at 60 Hz in RGB888 (415 MB/s). The FL2000 is a
+ * 5 Gb/s device: it never runs at SuperSpeed Plus.
+ */
+#define FL2000_BULK_BW_HIGH_SPEED  (53248000ull * 90 / 100)
+#define FL2000_BULK_BW_SUPER_SPEED (500000000ull * 90 / 100)
+
+/*
+ * Bytes per pixel the USB link can carry for @mode: 3 (RGB888), 2 (RGB565) or 0 for neither. The
+ * FL2000 has a line buffer and no frame buffer: it takes the active pixels of exactly one frame per
+ * refresh, so the stream needs the rate of the active area, not the pixel clock.
+ */
+static unsigned int fl2000_get_bytes_pix(enum usb_device_speed speed,
+					 const struct drm_display_mode *mode)
+{
+	u64 max_bw, rate;
+	u32 total = (u32)mode->htotal * mode->vtotal;
+	u64 bytes_pix;
+
+	switch (speed) {
+	case USB_SPEED_HIGH:
+		max_bw = FL2000_BULK_BW_HIGH_SPEED;
+		break;
+	case USB_SPEED_SUPER:
+	case USB_SPEED_SUPER_PLUS:
+		max_bw = FL2000_BULK_BW_SUPER_SPEED;
+		break;
+	default:
+		return 0;
+	}
+
+	if (!total)
+		return 0;
+
+	/* Active pixels per second; at most 500 MHz x 4000 x 4000, so no overflow */
+	rate = div_u64((u64)mode->clock * 1000 * mode->hdisplay * mode->vdisplay, total);
+	if (!rate)
+		return 0;
+
+	bytes_pix = div64_u64(max_bw, rate);
+	if (bytes_pix >= 3)
+		return 3; /* RGB888 */
+	if (bytes_pix == 2)
+		return 2; /* RGB565 */
+
+	/* RGB332 is not supported */
+	return 0;
+}
+
+struct fl2000_drm_if {
+	struct usb_device *usb_dev;
+	struct drm_device drm;
+	struct drm_plane plane;
+	/*
+	 * Without a cursor plane of its own the compositor keeps the pointer on
+	 * the primary GPU's hardware cursor, where it never reaches this output.
+	 */
+	struct drm_plane cursor;
+	struct drm_crtc crtc;
+	struct drm_encoder encoder;
+	struct fl2000_vga vga;
+	struct fl2000_stream *stream;
+	struct fl2000_intr *intr;
+	/* Set once userspace can see the device: events before that have nobody to tell */
+	bool registered;
+};
+
+static inline struct fl2000_drm_if *to_fl2000_drm_if(struct drm_device *drm)
+{
+	return container_of(drm, struct fl2000_drm_if, drm);
+}
+
+DEFINE_DRM_GEM_FOPS(fl2000_drm_driver_fops);
+
+/*
+ * Mode config cleanup is managed by drmm_mode_config_init(), and the display
+ * pipeline is shut down on unbind, so no .release callback is needed.
+ */
+static struct drm_driver fl2000_drm_driver = {
+	.driver_features = DRIVER_MODESET | DRIVER_GEM | DRIVER_ATOMIC,
+	.fops = &fl2000_drm_driver_fops,
+
+	/*
+	 * Paged shmem buffers: the framebuffer is only ever read by the CPU
+	 * (fl2000_stream_compress), never DMA'd to the device, so it does not
+	 * need to be physically contiguous.
+	 */
+	.dumb_create = drm_gem_shmem_dumb_create,
+	/*
+	 * Import with a mapping, not DRM_GEM_SHMEM_DRIVER_OPS' no-map import.
+	 * Mapping the attachment makes the exporter pin the buffer where this
+	 * device can reach it, system memory for amdgpu. Left unmapped, amdgpu
+	 * keeps it in VRAM and vmaps it as one linear range from where it
+	 * thinks it starts, which for a buffer split over several VRAM blocks
+	 * is right for the last block only: at 1360x768 and 1366x768 all but
+	 * the bottom ~10 % of the desktop came out black or garbled.
+	 */
+	.gem_prime_import = drm_gem_prime_import,
+	.gem_prime_import_sg_table = drm_gem_shmem_prime_import_sg_table,
+	DRM_FBDEV_SHMEM_DRIVER_OPS,
+
+	.name = DRM_DRIVER_NAME,
+	.desc = DRM_DRIVER_DESC,
+	.major = DRM_DRIVER_MAJOR,
+	.minor = DRM_DRIVER_MINOR,
+	.patchlevel = DRM_DRIVER_PATCHLEVEL,
+};
+
+static const struct drm_mode_config_funcs fl2000_mode_config_funcs = {
+	.fb_create = drm_gem_fb_create_with_dirty,
+	.atomic_check = drm_atomic_helper_check,
+	.atomic_commit = drm_atomic_helper_commit,
+};
+
+/* Integer division compute of ppm error */
+static u64 fl2000_pll_ppm_err(u64 clock_mil, u32 vco_clk, u32 divisor)
+{
+	u64 pll_clk_mil = div_u64((u64)vco_clk * FL2000_PLL_PRECISION, divisor);
+	u64 pll_clk_err;
+
+	/* Not using abs() here to avoid a possible overflow */
+	if (pll_clk_mil > clock_mil)
+		pll_clk_err = pll_clk_mil - clock_mil;
+	else
+		pll_clk_err = clock_mil - pll_clk_mil;
+
+	return div64_u64(pll_clk_err, div_u64(clock_mil, FL2000_PLL_PRECISION));
+}
+
+static inline u32 fl2000_pll_get_divisor(u64 clock_mil, u32 vco_clk, u64 *min_ppm_err)
+{
+	static const u32 divisor_arr[] = {
+		2,   4,	  6,   7,   8,	 9,   10,  11,	12,  13,  14,  15,  16,	 17,  18,  19,
+		20,  21,  22,  23,  24,	 25,  26,  27,	28,  29,  30,  31,  32,	 33,  34,  35,
+		36,  37,  38,  39,  40,	 41,  42,  43,	44,  45,  46,  47,  48,	 49,  50,  51,
+		52,  53,  54,  55,  56,	 57,  58,  59,	60,  61,  62,  63,  64,	 65,  66,  67,
+		68,  69,  70,  71,  72,	 73,  74,  75,	76,  77,  78,  79,  80,	 81,  82,  83,
+		84,  85,  86,  87,  88,	 89,  90,  91,	92,  93,  94,  95,  96,	 97,  98,  99,
+		100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115,
+		116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128
+	};
+	u32 best_divisor = 0;
+
+	for (int i = 0; i < ARRAY_SIZE(divisor_arr); i++) {
+		u32 divisor = divisor_arr[i];
+		u64 ppm_err = fl2000_pll_ppm_err(clock_mil, vco_clk, divisor);
+
+		if (ppm_err < *min_ppm_err) {
+			*min_ppm_err = ppm_err;
+			best_divisor = divisor;
+		}
+	}
+
+	return best_divisor;
+}
+
+/* Try to match pixel clock - find parameters with minimal PLL error */
+static u64 fl2000_pll_calc(u64 clock_mil, struct fl2000_pll *pll, u32 *clock_calculated)
+{
+	static const u32 prescaler_max = 2;
+	static const u32 multiplier_max = 128;
+	u64 min_ppm_err = (u64)(-1);
+
+	for (u32 prescaler = 1; prescaler <= prescaler_max; prescaler++)
+		for (u32 multiplier = 1; multiplier <= multiplier_max; multiplier++) {
+			/* Do not need precision here yet, no 10^6 multiply */
+			u32 vco_clk = FL2000_XTAL / prescaler * multiplier;
+			u32 divisor;
+
+			if (vco_clk < FL2000_VCOCLOCK_MIN || vco_clk > FL2000_VCOCLOCK_MAX)
+				continue;
+
+			divisor = fl2000_pll_get_divisor(clock_mil, vco_clk, &min_ppm_err);
+			if (divisor == 0)
+				continue;
+
+			pll->prescaler = prescaler;
+			pll->multiplier = multiplier;
+			pll->divisor = divisor;
+			if (vco_clk < 125000000)
+				pll->function = 0;
+			else if (vco_clk < 250000000)
+				pll->function = 1;
+			else if (vco_clk < 500000000)
+				pll->function = 2;
+			else
+				pll->function = 3;
+			*clock_calculated = vco_clk / divisor;
+		}
+
+	return min_ppm_err;
+}
+
+/*
+ * Find the PLL setting for a mode, accepting a pixel clock off by up to @max_ppm parts per
+ * million. The timings of the mode are never touched, only the clock the PLL can make for it.
+ */
+static int fl2000_mode_calc(const struct drm_display_mode *mode,
+			    struct drm_display_mode *adjusted_mode, struct fl2000_pll *pll,
+			    u64 max_ppm)
+{
+	u32 clock_calculated;
+	u64 ppm_err;
+
+	if (mode->clock * 1000 > FL2000_MAX_PIXCLOCK)
+		return -EINVAL;
+
+	/* To keep precision use clock multiplied by 10^6 */
+	ppm_err = fl2000_pll_calc((u64)mode->clock * 1000 * FL2000_PLL_PRECISION, pll,
+				  &clock_calculated);
+	if (ppm_err >= max_ppm)
+		return -EINVAL;
+
+	if (adjusted_mode) {
+		drm_mode_copy(adjusted_mode, mode);
+		adjusted_mode->clock = clock_calculated / 1000;
+	}
+
+	return 0;
+}
+
+static enum drm_mode_status fl2000_crtc_mode_valid(struct drm_crtc *crtc,
+						   const struct drm_display_mode *mode)
+{
+	struct fl2000_drm_if *drm_if = to_fl2000_drm_if(crtc->dev);
+	struct drm_display_mode adjusted_mode;
+	struct fl2000_pll pll;
+
+	/* Get PLL configuration and check if mode adjustments are needed */
+	if (fl2000_mode_calc(mode, &adjusted_mode, &pll, FL2000_PPM_ERR_MAX_VGA))
+		return MODE_BAD;
+
+	if (fl2000_get_bytes_pix(drm_if->usb_dev->speed, &adjusted_mode) == 0)
+		return MODE_CLOCK_HIGH;
+
+	return MODE_OK;
+}
+
+/*
+ * Primary plane
+ */
+
+static const u64 fl2000_plane_format_modifiers[] = {
+	DRM_FORMAT_MOD_LINEAR,
+	DRM_FORMAT_MOD_INVALID,
+};
+
+static int fl2000_plane_atomic_check(struct drm_plane *plane, struct drm_atomic_commit *state)
+{
+	struct drm_plane_state *new_plane_state = drm_atomic_get_new_plane_state(state, plane);
+	struct drm_crtc_state *new_crtc_state = NULL;
+	bool is_cursor = plane->type == DRM_PLANE_TYPE_CURSOR;
+
+	/* Clipping a larger sprite would put a truncated pointer on screen */
+	if (is_cursor && new_plane_state->fb &&
+	    (new_plane_state->fb->width > FL2000_CURSOR_MAX ||
+	     new_plane_state->fb->height > FL2000_CURSOR_MAX))
+		return -EINVAL;
+
+	if (new_plane_state->crtc)
+		new_crtc_state = drm_atomic_get_new_crtc_state(state, new_plane_state->crtc);
+
+	/* The cursor may be placed anywhere; the primary plane is the frame */
+	return drm_atomic_helper_check_plane_state(new_plane_state, new_crtc_state,
+						   DRM_PLANE_NO_SCALING, DRM_PLANE_NO_SCALING,
+						   is_cursor, false);
+}
+
+/*
+ * Only the damaged rectangle is converted, into the stream's shadow frame,
+ * which is the one persistent copy every outgoing buffer is built from.
+ */
+static void fl2000_plane_atomic_update(struct drm_plane *plane, struct drm_atomic_commit *state)
+{
+	struct drm_plane_state *old_plane_state = drm_atomic_get_old_plane_state(state, plane);
+	struct drm_plane_state *plane_state = drm_atomic_get_new_plane_state(state, plane);
+	struct drm_shadow_plane_state *shadow_plane_state = to_drm_shadow_plane_state(plane_state);
+	struct fl2000_drm_if *drm_if = to_fl2000_drm_if(plane->dev);
+	struct drm_framebuffer *fb = plane_state->fb;
+	struct drm_rect damage;
+	ktime_t start;
+	int idx;
+
+	if (!fb)
+		return; /* plane is disabled */
+
+	if (!drm_atomic_helper_damage_merged(old_plane_state, plane_state, &damage))
+		return;
+
+	if (drm_gem_fb_begin_cpu_access(fb, DMA_FROM_DEVICE))
+		return;
+
+	if (drm_dev_enter(plane->dev, &idx)) {
+		start = ktime_get();
+		fl2000_stream_compress(drm_if->stream, &shadow_plane_state->data[0],
+				       drm_gem_is_imported(fb->obj[0]), fb->format->format,
+				       fb->width, fb->height, fb->pitches[0], &damage);
+		fl2000_stream_note_render(drm_if->stream,
+					  (unsigned int)ktime_us_delta(ktime_get(), start),
+					  drm_rect_width(&damage) * drm_rect_height(&damage));
+		drm_dev_exit(idx);
+	}
+
+	drm_gem_fb_end_cpu_access(fb, DMA_FROM_DEVICE);
+}
+
+/*
+ * Hand the cursor sprite to the stream, which blends it into every outgoing
+ * frame. Moving the pointer keeps the same framebuffer and skips the copy.
+ */
+static void fl2000_cursor_atomic_update(struct drm_plane *plane, struct drm_atomic_commit *state)
+{
+	struct drm_plane_state *old_plane_state = drm_atomic_get_old_plane_state(state, plane);
+	struct drm_plane_state *plane_state = drm_atomic_get_new_plane_state(state, plane);
+	struct drm_shadow_plane_state *shadow_plane_state = to_drm_shadow_plane_state(plane_state);
+	struct fl2000_drm_if *drm_if = to_fl2000_drm_if(plane->dev);
+	struct drm_framebuffer *fb = plane_state->fb;
+	unsigned int w, h;
+	u32 *sprite;
+	int idx;
+
+	if (!fb || !plane_state->visible) {
+		fl2000_stream_set_cursor(drm_if->stream, NULL, 0, 0, 0, 0);
+		return;
+	}
+
+	if (fb == old_plane_state->fb && old_plane_state->visible) {
+		fl2000_stream_move_cursor(drm_if->stream, plane_state->crtc_x, plane_state->crtc_y);
+		return;
+	}
+
+	/* Size is bounded by the atomic check */
+	w = fb->width;
+	h = fb->height;
+
+	/* Repack into a tightly packed sprite: the framebuffer has its own pitch */
+	sprite = kmalloc_objs(*sprite, (size_t)w * h);
+	if (!sprite)
+		return;
+
+	if (drm_gem_fb_begin_cpu_access(fb, DMA_FROM_DEVICE))
+		goto out_free;
+
+	if (drm_dev_enter(plane->dev, &idx)) {
+		for (unsigned int y = 0; y < h; y++)
+			iosys_map_memcpy_from(sprite + (size_t)y * w, &shadow_plane_state->data[0],
+					      (size_t)y * fb->pitches[0], (size_t)w * sizeof(u32));
+
+		fl2000_stream_set_cursor(drm_if->stream, sprite, w, h, plane_state->crtc_x,
+					 plane_state->crtc_y);
+		drm_dev_exit(idx);
+	}
+
+	drm_gem_fb_end_cpu_access(fb, DMA_FROM_DEVICE);
+out_free:
+	kfree(sprite);
+}
+
+static const struct drm_plane_helper_funcs fl2000_cursor_helper_funcs = {
+	DRM_GEM_SHADOW_PLANE_HELPER_FUNCS,
+	.atomic_check = fl2000_plane_atomic_check,
+	.atomic_update = fl2000_cursor_atomic_update,
+};
+
+static const struct drm_plane_helper_funcs fl2000_plane_helper_funcs = {
+	DRM_GEM_SHADOW_PLANE_HELPER_FUNCS,
+	.atomic_check = fl2000_plane_atomic_check,
+	.atomic_update = fl2000_plane_atomic_update,
+};
+
+static const struct drm_plane_funcs fl2000_plane_funcs = {
+	.update_plane = drm_atomic_helper_update_plane,
+	.disable_plane = drm_atomic_helper_disable_plane,
+	.destroy = drm_plane_cleanup,
+	DRM_GEM_SHADOW_PLANE_FUNCS,
+};
+
+/*
+ * CRTC
+ */
+
+static int fl2000_crtc_atomic_check(struct drm_crtc *crtc, struct drm_atomic_commit *state)
+{
+	struct drm_crtc_state *crtc_state = drm_atomic_get_new_crtc_state(state, crtc);
+	struct fl2000_drm_if *drm_if = to_fl2000_drm_if(crtc->dev);
+	struct fl2000_pll pll;
+	int ret;
+
+	ret = drm_crtc_helper_atomic_check(crtc, state);
+	if (ret)
+		return ret;
+
+	if (!crtc_state->enable || !drm_atomic_crtc_needs_modeset(crtc_state))
+		return 0;
+
+	/* PLL configuration, with htotal and clock adjusted to what the PLL can produce */
+	ret = fl2000_mode_calc(&crtc_state->mode, &crtc_state->adjusted_mode, &pll,
+			       FL2000_PPM_ERR_MAX_VGA);
+	if (ret)
+		return ret;
+
+	/* The USB link must be able to carry the adjusted pixel clock */
+	if (!fl2000_get_bytes_pix(drm_if->usb_dev->speed, &crtc_state->adjusted_mode))
+		return -EINVAL;
+
+	return 0;
+}
+
+/*
+ * HDMI has always run with the monitor sense forced, so it stays so whenever HDMI is driven.
+ * Driving VGA alone leaves it to the chip, which then powers the DAC by itself and notices the
+ * cable being unplugged.
+ */
+static void fl2000_crtc_force_connect(struct fl2000_drm_if *drm_if,
+				      const struct drm_crtc_state *crtc_state)
+{
+	fl2000_force_connect(drm_if->usb_dev,
+			     crtc_state->encoder_mask & drm_encoder_mask(&drm_if->encoder));
+}
+
+/* Runs before the bridge is enabled: the IT66121 is programmed with the FL2000 clocking it */
+static void fl2000_crtc_mode_set_nofb(struct drm_crtc *crtc)
+{
+	struct drm_device *drm = crtc->dev;
+	struct fl2000_drm_if *drm_if = to_fl2000_drm_if(drm);
+	struct usb_device *usb_dev = drm_if->usb_dev;
+	const struct drm_display_mode *mode = &crtc->state->mode;
+	const struct drm_display_mode *adjusted_mode = &crtc->state->adjusted_mode;
+	struct fl2000_timings timings;
+	struct fl2000_pll pll;
+	unsigned int bytes_pix;
+
+	/*
+	 * Same computation as in atomic_check, which already validated the mode
+	 * and stored the adjusted htotal and clock in adjusted_mode.
+	 */
+	if (WARN_ON(fl2000_mode_calc(mode, NULL, &pll, FL2000_PPM_ERR_MAX_VGA)))
+		return;
+	bytes_pix = fl2000_get_bytes_pix(usb_dev->speed, adjusted_mode);
+
+	drm_dbg_kms(drm, "Mode requested:  " DRM_MODE_FMT "\n", DRM_MODE_ARG(mode));
+	drm_dbg_kms(drm, "Mode configured: " DRM_MODE_FMT "\n", DRM_MODE_ARG(adjusted_mode));
+
+	/* Prepare timing configuration */
+	timings.hactive = adjusted_mode->hdisplay;
+	timings.htotal = adjusted_mode->htotal;
+	timings.hsync_width = adjusted_mode->hsync_end - adjusted_mode->hsync_start;
+	timings.hstart = adjusted_mode->htotal - adjusted_mode->hsync_start + 1;
+	timings.vactive = adjusted_mode->vdisplay;
+	timings.vtotal = adjusted_mode->vtotal;
+	timings.vsync_width = adjusted_mode->vsync_end - adjusted_mode->vsync_start;
+	timings.vstart = adjusted_mode->vtotal - adjusted_mode->vsync_start + 1;
+
+	/* Set PLL settings */
+	fl2000_set_pll(usb_dev, &pll);
+
+	fl2000_crtc_force_connect(drm_if, crtc->state);
+
+	/* Reset FL2000 and confirm PLL settings */
+	fl2000_reset(usb_dev);
+
+	/* Set timings settings */
+	fl2000_set_timings(usb_dev, &timings);
+
+	/* Pixel format according to number of bytes per pixel */
+	fl2000_set_pixfmt(usb_dev, bytes_pix);
+
+	/* Configure frame transfers */
+	fl2000_set_transfers(usb_dev);
+
+	/* Enable interrupts */
+	fl2000_enable_interrupts(usb_dev);
+
+	fl2000_afe_magic(usb_dev);
+
+	fl2000_stream_mode_set(drm_if->stream, mode->hdisplay, mode->vdisplay, bytes_pix);
+}
+
+static void fl2000_crtc_atomic_enable(struct drm_crtc *crtc, struct drm_atomic_commit *state)
+{
+	struct fl2000_drm_if *drm_if = to_fl2000_drm_if(crtc->dev);
+
+	/* mode_set_nofb does not run when only the connector changed, and disable cleared it */
+	fl2000_crtc_force_connect(drm_if, drm_atomic_get_new_crtc_state(state, crtc));
+
+	fl2000_stream_enable(drm_if->stream);
+
+	drm_crtc_vblank_atomic_enable(crtc, state);
+}
+
+static void fl2000_crtc_atomic_disable(struct drm_crtc *crtc, struct drm_atomic_commit *state)
+{
+	struct fl2000_drm_if *drm_if = to_fl2000_drm_if(crtc->dev);
+
+	fl2000_stream_disable(drm_if->stream);
+
+	/* Nothing is shown any more: let the chip's own sense report the monitors again */
+	fl2000_force_connect(drm_if->usb_dev, false);
+
+	drm_crtc_vblank_atomic_disable(crtc, state);
+}
+
+static const struct drm_crtc_helper_funcs fl2000_crtc_helper_funcs = {
+	.mode_valid = fl2000_crtc_mode_valid,
+	.atomic_check = fl2000_crtc_atomic_check,
+	.mode_set_nofb = fl2000_crtc_mode_set_nofb,
+	.atomic_flush = drm_crtc_vblank_atomic_flush,
+	.atomic_enable = fl2000_crtc_atomic_enable,
+	.atomic_disable = fl2000_crtc_atomic_disable,
+};
+
+static const struct drm_crtc_funcs fl2000_crtc_funcs = {
+	.atomic_create_state = drm_atomic_helper_crtc_create_state,
+	.set_config = drm_atomic_helper_set_config,
+	.page_flip = drm_atomic_helper_page_flip,
+	.atomic_duplicate_state = drm_atomic_helper_crtc_duplicate_state,
+	.atomic_destroy_state = drm_atomic_helper_crtc_destroy_state,
+	/*
+	 * The FL2000 has no vblank interrupt: vblank events come from a timer
+	 * running at the mode's refresh rate.
+	 */
+	DRM_CRTC_VBLANK_TIMER_FUNCS,
+};
+
+/*
+ * Digital sinks are only offered the modes whose pixel clock the PLL hits closely: they expect the
+ * exact clock of the mode they advertised. The VGA output accepts a larger error.
+ */
+static enum drm_mode_status fl2000_hdmi_encoder_mode_valid(struct drm_encoder *encoder,
+							   const struct drm_display_mode *mode)
+{
+	struct fl2000_pll pll;
+
+	return fl2000_mode_calc(mode, NULL, &pll, FL2000_PPM_ERR_MAX) ? MODE_NOCLOCK : MODE_OK;
+}
+
+static const struct drm_encoder_helper_funcs fl2000_hdmi_encoder_helper_funcs = {
+	.mode_valid = fl2000_hdmi_encoder_mode_valid,
+};
+
+/**
+ * fl2000_drm_hotplug() - tell userspace that a monitor came, went or changed
+ * @drm: DRM device
+ * @events: the sink event bits of the status register that were seen
+ *
+ * Called from the interrupt work.
+ */
+void fl2000_drm_hotplug(struct drm_device *drm, u32 events)
+{
+	struct fl2000_drm_if *drm_if = to_fl2000_drm_if(drm);
+	int idx;
+
+	/* The device sends uevents only once it has been registered */
+	if (!smp_load_acquire(&drm_if->registered) || !drm_dev_enter(drm, &idx))
+		return;
+
+	if (events & (FL2000_VGA_STATUS_MONITOR_EVENT | FL2000_VGA_STATUS_EDID_EVENT))
+		fl2000_vga_sink_event(&drm_if->vga);
+
+	drm_kms_helper_hotplug_event(drm);
+
+	drm_dev_exit(idx);
+}
+
+static void fl2000_drm_if_release(struct device *dev, void *res)
+{
+	struct fl2000_drm_if *drm_if = *(struct fl2000_drm_if **)res;
+	struct drm_device *drm = &drm_if->drm;
+	struct usb_device *usb_dev = drm_if->usb_dev;
+
+	dev_dbg(dev, "Unbinding FL2000 master\n");
+
+	/* No hotplug events for a node that is about to disappear */
+	fl2000_intr_quiesce(drm_if->intr);
+	drm_kms_helper_poll_fini(drm);
+
+	/*
+	 * Block userspace access and shut down the display pipeline while all
+	 * the components are still bound.
+	 */
+	drm_dev_unplug(drm);
+	drm_atomic_helper_shutdown(drm);
+
+	/*
+	 * Detach bridge component. This release function runs with the global
+	 * component mutex held (component_master_del() -> master unbind ->
+	 * devres_release()), so it must never call component_del() - that would
+	 * self-deadlock. The IT66121 is destroyed by a usb_device devres instead.
+	 */
+	component_unbind_all(dev, drm);
+
+	/* Stop streaming interface */
+	fl2000_stream_destroy(usb_dev);
+
+	/* Stop interrupts interface */
+	fl2000_intr_destroy(usb_dev);
+
+	/*
+	 * Drop the driver's reference. The DRM device is freed when the last
+	 * userspace file is closed; it only pins the USB device, never the I2C
+	 * adapter, so the disconnect does not wait for userspace.
+	 */
+	drm_dev_put(drm);
+}
+
+/* The DRM device while the master is bound, NULL otherwise */
+static struct fl2000_drm_if *fl2000_drm_if_of(struct device *master)
+{
+	struct fl2000_drm_if **holder = devres_find(master, fl2000_drm_if_release, NULL, NULL);
+
+	return holder ? *holder : NULL;
+}
+
+/**
+ * fl2000_drm_suspend() - stop the display for system sleep
+ * @master: the component master
+ *
+ * Called once for the device, before any of its interfaces is suspended.
+ *
+ * Return: 0 on success, a negative error code otherwise, which aborts the sleep
+ */
+int fl2000_drm_suspend(struct device *master)
+{
+	struct fl2000_drm_if *drm_if = fl2000_drm_if_of(master);
+	struct drm_bridge *bridge;
+	int ret;
+
+	if (!drm_if)
+		return 0;
+
+	/* No hotplug events while going to sleep */
+	fl2000_intr_suspend(drm_if->intr);
+
+	/* Saves the state, turns the outputs off and stops the stream */
+	ret = drm_mode_config_helper_suspend(&drm_if->drm);
+	if (ret) {
+		fl2000_intr_resume(drm_if->intr);
+		return ret;
+	}
+
+	bridge = drm_bridge_chain_get_first_bridge(&drm_if->encoder);
+	if (bridge) {
+		it66121_suspend(bridge);
+		drm_bridge_put(bridge);
+	}
+
+	return 0;
+}
+
+/**
+ * fl2000_drm_resume() - bring the display back after system sleep
+ * @master: the component master
+ *
+ * Called once for the device, when all of it is awake again, also after a reset-resume. The chips
+ * may have lost power: they are set up as at bind time before the saved state is restored.
+ *
+ * Return: 0 on success, a negative error code otherwise
+ */
+int fl2000_drm_resume(struct device *master)
+{
+	struct fl2000_drm_if *drm_if = fl2000_drm_if_of(master);
+	struct usb_device *usb_dev;
+	struct drm_bridge *bridge;
+	int ret;
+
+	if (!drm_if)
+		return 0;
+	usb_dev = drm_if->usb_dev;
+
+	/* First, as the IT66121 is reached through the FL2000 I2C engine */
+	fl2000_regmap_drop_cache(usb_dev);
+
+	bridge = drm_bridge_chain_get_first_bridge(&drm_if->encoder);
+	if (bridge) {
+		it66121_resume(bridge);
+		drm_bridge_put(bridge);
+	}
+
+	/* The same order as in fl2000_drm_bind() */
+	fl2000_reset(usb_dev);
+	fl2000_usb_magic(usb_dev);
+
+	/* Without interrupts the connectors are still polled */
+	fl2000_intr_resume(drm_if->intr);
+
+	/* Another monitor may have been plugged in meanwhile */
+	fl2000_vga_sink_event(&drm_if->vga);
+
+	ret = drm_mode_config_helper_resume(&drm_if->drm);
+	if (ret)
+		drm_err(&drm_if->drm, "Cannot restore the display after sleep (%d)\n", ret);
+
+	drm_kms_helper_hotplug_event(&drm_if->drm);
+
+	return ret;
+}
+
+int fl2000_drm_bind(struct device *master)
+{
+	int ret = 0;
+	struct usb_device *usb_dev = to_usb_device(master->parent);
+	struct fl2000_drm_if *drm_if;
+	struct fl2000_drm_if **holder;
+	struct drm_device *drm;
+	struct drm_mode_config *mode_config;
+	struct drm_connector_list_iter conn_iter;
+	struct drm_connector *connector;
+
+	dev_dbg(master, "Binding FL2000 master\n");
+
+	/*
+	 * The DRM device is a child of the USB device, not of the I2C adapter
+	 * that is the component master. It holds a reference on its parent, and
+	 * i2c_del_adapter() (run when the USB device is unbound) waits for every
+	 * reference on the adapter: parenting it there deadlocks the hub worker
+	 * on unplug and no device enumerates again. The put is explicit, in
+	 * fl2000_drm_if_release().
+	 */
+	drm_if = __drm_dev_alloc(&usb_dev->dev, &fl2000_drm_driver, sizeof(*drm_if),
+				 offsetof(struct fl2000_drm_if, drm));
+	if (IS_ERR(drm_if)) {
+		dev_err(master, "Cannot allocate DRM structure (%pe)\n", drm_if);
+		return PTR_ERR(drm_if);
+	}
+	drm = &drm_if->drm;
+	drm_if->usb_dev = usb_dev;
+
+	/* A USB device cannot DMA by itself: dma-buf imports go through its host controller */
+	drm_dev_set_dma_dev(drm, usb_dev->bus->sysdev);
+
+	/*
+	 * Devres that fl2000_drm_unbind() releases to tear everything down,
+	 * registered once binding succeeded.
+	 */
+	holder = devres_alloc(fl2000_drm_if_release, sizeof(*holder), GFP_KERNEL);
+	if (!holder) {
+		drm_dev_put(drm);
+		return -ENOMEM;
+	}
+
+	ret = drmm_mode_config_init(drm);
+	if (ret) {
+		drm_err(drm, "Cannot initialize DRM mode (%d)\n", ret);
+		goto err_free_holder;
+	}
+
+	mode_config = &drm->mode_config;
+	mode_config->funcs = &fl2000_mode_config_funcs;
+	mode_config->min_width = 1;
+	mode_config->max_width = FL2000_MAX_WIDTH;
+	mode_config->min_height = 1;
+	mode_config->max_height = FL2000_MAX_HEIGHT;
+	/* Userspace sizes its sprite to this; a larger one is rejected */
+	mode_config->cursor_width = FL2000_CURSOR_MAX;
+	mode_config->cursor_height = FL2000_CURSOR_MAX;
+
+	ret = drm_universal_plane_init(drm, &drm_if->plane, 0, &fl2000_plane_funcs,
+				       fl2000_pixel_formats, ARRAY_SIZE(fl2000_pixel_formats),
+				       fl2000_plane_format_modifiers, DRM_PLANE_TYPE_PRIMARY, NULL);
+	if (ret) {
+		drm_err(drm, "Cannot initialize plane (%d)\n", ret);
+		goto err_free_holder;
+	}
+	drm_plane_helper_add(&drm_if->plane, &fl2000_plane_helper_funcs);
+
+	/*
+	 * Enable the damage-clips property the update path relies on
+	 * (drm_atomic_helper_damage_merged()).
+	 */
+	drm_plane_enable_fb_damage_clips(&drm_if->plane);
+
+	ret = drm_universal_plane_init(drm, &drm_if->cursor, 0, &fl2000_plane_funcs,
+				       fl2000_cursor_formats, ARRAY_SIZE(fl2000_cursor_formats),
+				       fl2000_plane_format_modifiers, DRM_PLANE_TYPE_CURSOR, NULL);
+	if (ret) {
+		drm_err(drm, "Cannot initialize cursor plane (%d)\n", ret);
+		goto err_free_holder;
+	}
+	drm_plane_helper_add(&drm_if->cursor, &fl2000_cursor_helper_funcs);
+
+	ret = drmm_crtc_init_with_planes(drm, &drm_if->crtc, &drm_if->plane, &drm_if->cursor,
+					 &fl2000_crtc_funcs, NULL);
+	if (ret) {
+		drm_err(drm, "Cannot initialize CRTC (%d)\n", ret);
+		goto err_free_holder;
+	}
+	drm_crtc_helper_add(&drm_if->crtc, &fl2000_crtc_helper_funcs);
+	drm_if->plane.possible_crtcs = drm_crtc_mask(&drm_if->crtc);
+	drm_if->cursor.possible_crtcs = drm_crtc_mask(&drm_if->crtc);
+
+	/* The FL2000 is programmed from the CRTC; the IT66121 bridge hangs off this encoder */
+	ret = drmm_encoder_init(drm, &drm_if->encoder, NULL, DRM_MODE_ENCODER_NONE, NULL);
+	if (ret) {
+		drm_err(drm, "Cannot initialize encoder (%d)\n", ret);
+		goto err_free_holder;
+	}
+	drm_if->encoder.possible_crtcs = drm_crtc_mask(&drm_if->crtc);
+	drm_encoder_helper_add(&drm_if->encoder, &fl2000_hdmi_encoder_helper_funcs);
+
+	/* Start streaming interface */
+	drm_if->stream = fl2000_stream_create(usb_dev);
+	if (IS_ERR(drm_if->stream)) {
+		ret = PTR_ERR(drm_if->stream);
+		drm_err(drm, "Cannot create stream (%d)\n", ret);
+		goto err_free_holder;
+	}
+
+	/* Start interrupts interface */
+	drm_if->intr = fl2000_intr_create(usb_dev, drm);
+	if (IS_ERR(drm_if->intr)) {
+		ret = PTR_ERR(drm_if->intr);
+		drm_err(drm, "Cannot start interrupt polling (%d)\n", ret);
+		goto err_destroy_stream;
+	}
+
+	/* Attach bridge */
+	ret = component_bind_all(master, drm);
+	if (ret) {
+		drm_err(drm, "Cannot attach bridge (%d)\n", ret);
+		goto err_destroy_intr;
+	}
+
+	/*
+	 * The HDMI connector is the generic one of the bridge chain: the IT66121 attached without
+	 * a connector of its own and reports the hot plug line and the EDID.
+	 */
+	connector = drm_bridge_connector_init(drm, &drm_if->encoder);
+	if (IS_ERR(connector)) {
+		ret = PTR_ERR(connector);
+		drm_err(drm, "Cannot initialize HDMI connector (%d)\n", ret);
+		goto err_unbind;
+	}
+
+	/*
+	 * The VGA output goes in after the bridge: the IT66121 attaches to the first encoder of
+	 * the device, which has to be the HDMI one.
+	 */
+	ret = fl2000_vga_init(drm, &drm_if->vga, &drm_if->crtc, &drm_if->encoder,
+			      i2c_verify_adapter(master), drm_if->intr);
+	if (ret) {
+		drm_err(drm, "Cannot initialize VGA output (%d)\n", ret);
+		goto err_unbind;
+	}
+
+	drm_mode_config_reset(drm);
+
+	ret = drm_vblank_init(drm, drm->mode_config.num_crtc);
+	if (ret) {
+		drm_err(drm, "Failed to initialize %d VBLANK(s) (%d)\n",
+			drm->mode_config.num_crtc, ret);
+		goto err_unbind;
+	}
+
+	fl2000_reset(usb_dev);
+	fl2000_usb_magic(usb_dev);
+
+	/*
+	 * Probe the connector before userspace can see the device. A compositor
+	 * that finds a new GPU reads the cached connector state without probing
+	 * it, and does not look again when the hotplug event follows; with an
+	 * unprobed connector it never enables the output until something else
+	 * makes it reload.
+	 */
+	mutex_lock(&drm->mode_config.mutex);
+	drm_connector_list_iter_begin(drm, &conn_iter);
+	drm_for_each_connector_iter(connector, &conn_iter)
+		drm_helper_probe_single_connector_modes(connector, FL2000_MAX_WIDTH,
+							FL2000_MAX_HEIGHT);
+	drm_connector_list_iter_end(&conn_iter);
+	mutex_unlock(&drm->mode_config.mutex);
+
+	ret = drm_dev_register(drm, 0);
+	if (ret) {
+		drm_err(drm, "Cannot register DRM device (%d)\n", ret);
+		goto err_unbind;
+	}
+
+	*holder = drm_if;
+	devres_add(master, holder);
+
+	/* From here on the interrupt work may tell userspace about monitors */
+	smp_store_release(&drm_if->registered, true);
+
+	/* Polls both connectors: events can be missed, and HDMI has no hot plug of its own */
+	drm_kms_helper_poll_init(drm);
+
+	/*
+	 * fbdev emulation, so the console can use the display. Last, because it
+	 * may set a mode right away and the reset above would undo it.
+	 */
+	drm_client_setup(drm, NULL);
+
+	return 0;
+
+err_unbind:
+	component_unbind_all(master, drm);
+err_destroy_intr:
+	fl2000_intr_destroy(usb_dev);
+err_destroy_stream:
+	fl2000_stream_destroy(usb_dev);
+err_free_holder:
+	devres_free(holder);
+	drm_dev_put(drm);
+	return ret;
+}
+
+void fl2000_drm_unbind(struct device *master)
+{
+	devres_release(master, fl2000_drm_if_release, NULL, NULL);
+}
diff --git a/drivers/gpu/drm/fl2000/fl2000_drv.c b/drivers/gpu/drm/fl2000/fl2000_drv.c
index 107eba92c..2e71f0aec 100644
--- a/drivers/gpu/drm/fl2000/fl2000_drv.c
+++ b/drivers/gpu/drm/fl2000/fl2000_drv.c
@@ -15,6 +15,9 @@
 #define USB_VENDOR_FRESCO_LOGIC 0x1D5C
 #define USB_PRODUCT_FL2000	0x2000
 
+#define FL2000_ALL_IFS \
+	(BIT(FL2000_USBIF_AVCONTROL) | BIT(FL2000_USBIF_STREAMING) | BIT(FL2000_USBIF_INTERRUPT))
+
 static const struct usb_device_id fl2000_id_table[] = {
 	{ USB_DEVICE_INTERFACE_CLASS(USB_VENDOR_FRESCO_LOGIC, USB_PRODUCT_FL2000, USB_CLASS_AV) },
 	{},
@@ -26,9 +29,41 @@ struct fl2000_devs {
 	struct regmap *regmap;
 	struct i2c_adapter *adapter;
 	struct i2c_client *bridge_client;
+	struct component_match *match;
 	int active_if;
+	/* The display was stopped for system sleep and has not been restarted yet */
+	bool suspended;
+};
+
+static const struct component_master_ops fl2000_master_ops = {
+	.bind = fl2000_drm_bind,
+	.unbind = fl2000_drm_unbind,
 };
 
+static int fl2000_compare(struct device *dev, void *data)
+{
+	struct i2c_client *client = i2c_verify_client(dev);
+	struct i2c_adapter *adapter = data;
+	static const char *const fl2000_supported_bridges[] = {
+		"fl2000-it66121",
+	};
+
+	/*
+	 * Only match clients sitting on this FL2000 instance's own I2C bus: a
+	 * client with a matching name may belong to another FL2000 device that
+	 * is disconnecting or re-enumerating concurrently.
+	 */
+	if (!client || client->adapter != adapter)
+		return 0;
+
+	/* Check this is a supported DRM bridge */
+	for (int i = 0; i < ARRAY_SIZE(fl2000_supported_bridges); i++)
+		if (!strncmp(fl2000_supported_bridges[i], client->name, sizeof(client->name)))
+			return 1;
+
+	return 0;
+}
+
 static struct fl2000_devs *fl2000_get_devices(struct usb_device *usb_dev)
 {
 	struct fl2000_devs *devs;
@@ -49,6 +84,8 @@ static struct fl2000_devs *fl2000_get_devices(struct usb_device *usb_dev)
 		return ERR_CAST(devs->adapter);
 	}
 
+	component_match_add(&devs->adapter->dev, &devs->match, fl2000_compare, devs->adapter);
+
 	dev_set_drvdata(&usb_dev->dev, devs);
 
 	return devs;
@@ -138,6 +175,16 @@ static int fl2000_probe(struct usb_interface *interface, const struct usb_device
 		break;
 	}
 
+	/* When all interfaces are up - proceed with registration */
+	if (devs->active_if == FL2000_ALL_IFS) {
+		ret = component_master_add_with_match(&devs->adapter->dev, &fl2000_master_ops,
+						      devs->match);
+		if (ret) {
+			dev_err(&usb_dev->dev, "Cannot register component master (%d)\n", ret);
+			return ret;
+		}
+	}
+
 	return ret;
 }
 
@@ -151,11 +198,18 @@ static void fl2000_disconnect(struct usb_interface *interface)
 		return;
 
 	/*
-	 * The IT66121 bridge is intentionally NOT destroyed here: disconnect
-	 * also runs for the transient unbind/rebind cycles of
-	 * usb_reset_device(), where the usb_device survives. Its destruction is
-	 * a devres of the usb_device, see fl2000_bridge_create().
+	 * The IT66121 bridge component is intentionally NOT destroyed here.
+	 * Disconnect also runs for the transient unbind/rebind cycles of
+	 * usb_reset_device(), where the usb_device (and the I2C adapter and
+	 * aggregate match data) survive: the component must persist across
+	 * those. Its destruction is a devres of the usb_device, see
+	 * fl2000_bridge_create(). Destroying it from the master unbind path is
+	 * also forbidden - component_del() would self-deadlock on the global
+	 * component mutex held across the unbind callback.
 	 */
+	if (devs->active_if == FL2000_ALL_IFS)
+		component_master_del(&devs->adapter->dev, &fl2000_master_ops);
+
 	switch (iface_num) {
 	case FL2000_USBIF_AVCONTROL:
 	case FL2000_USBIF_STREAMING:
@@ -170,15 +224,27 @@ static void fl2000_disconnect(struct usb_interface *interface)
 	}
 }
 
+/*
+ * System sleep. The USB core suspends the interfaces one by one, the last first, and resumes them
+ * in order once the device is awake. The display is one thing for all three: stop it at the first
+ * suspend, before any interface sleeps, and start it again at the first resume. The same callback
+ * serves a reset-resume, after which the chips are set up from scratch: without one the USB core
+ * would unbind and bind the driver again, which a running compositor sees as an unplug.
+ */
 static int fl2000_suspend(struct usb_interface *interface, pm_message_t message)
 {
 	struct usb_device *usb_dev = interface_to_usbdev(interface);
+	struct fl2000_devs *devs = dev_get_drvdata(&usb_dev->dev);
+	int ret;
 
-	/*
-	 * Nothing to save yet. Providing the callback keeps the USB core from
-	 * unbinding the driver across system sleep.
-	 */
-	dev_dbg(&usb_dev->dev, "suspend\n");
+	if (!devs || devs->suspended)
+		return 0;
+
+	ret = fl2000_drm_suspend(&devs->adapter->dev);
+	if (ret)
+		return ret;
+
+	devs->suspended = true;
 
 	return 0;
 }
@@ -186,10 +252,14 @@ static int fl2000_suspend(struct usb_interface *interface, pm_message_t message)
 static int fl2000_resume(struct usb_interface *interface)
 {
 	struct usb_device *usb_dev = interface_to_usbdev(interface);
+	struct fl2000_devs *devs = dev_get_drvdata(&usb_dev->dev);
 
-	dev_dbg(&usb_dev->dev, "resume\n");
+	if (!devs || !devs->suspended)
+		return 0;
 
-	return 0;
+	devs->suspended = false;
+
+	return fl2000_drm_resume(&devs->adapter->dev);
 }
 
 static struct usb_driver fl2000_driver = {
@@ -198,6 +268,7 @@ static struct usb_driver fl2000_driver = {
 	.disconnect = fl2000_disconnect,
 	.suspend = fl2000_suspend,
 	.resume = fl2000_resume,
+	.reset_resume = fl2000_resume,
 	.id_table = fl2000_id_table,
 	.supports_autosuspend = false,
 	.disable_hub_initiated_lpm = true,
diff --git a/drivers/gpu/drm/fl2000/fl2000_interrupt.c b/drivers/gpu/drm/fl2000/fl2000_interrupt.c
new file mode 100644
index 000000000..6ad0f1dd0
--- /dev/null
+++ b/drivers/gpu/drm/fl2000/fl2000_interrupt.c
@@ -0,0 +1,237 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * (C) Copyright 2017, Fresco Logic, Incorporated.
+ * (C) Copyright 2018-2020, Artem Mygaiev
+ */
+
+#include "fl2000.h"
+
+#define INTR_BUFSIZE 1
+
+struct fl2000_intr {
+	struct usb_device *usb_dev;
+	struct drm_device *drm;
+	u8 poll_interval;
+	struct urb *urb;
+	u8 *buf;
+	dma_addr_t transfer_dma;
+	struct work_struct work;
+	struct workqueue_struct *work_queue;
+	/* Sink events read by anyone, not yet reported to userspace */
+	atomic_t events;
+};
+
+#define FL2000_SINK_EVENTS (FL2000_VGA_STATUS_HDMI_EVENT | FL2000_VGA_STATUS_MONITOR_EVENT | \
+			    FL2000_VGA_STATUS_EDID_EVENT)
+
+/*
+ * The event bits of the status register clear on read, and both the work below and the connector
+ * detection read it: keep the events from every read until the work reports them.
+ */
+static int fl2000_intr_read_status(struct fl2000_intr *intr, u32 *status)
+{
+	int ret;
+
+	ret = fl2000_read_status(intr->usb_dev, status);
+	if (!ret)
+		atomic_or(*status & FL2000_SINK_EVENTS, &intr->events);
+
+	return ret;
+}
+
+/**
+ * fl2000_intr_monitor_connected() - does the FL2000 sense a monitor on its monitor input
+ * @intr: interrupt context
+ *
+ * The chip powers the DAC and the PLL only while this is the case. On the boards with both
+ * outputs the input follows whichever monitor is connected, so it does not tell VGA from HDMI.
+ *
+ * Return: 1 if a monitor is sensed, 0 if not, a negative error code if the status cannot be read
+ */
+int fl2000_intr_monitor_connected(struct fl2000_intr *intr)
+{
+	u32 status;
+	int ret;
+
+	ret = fl2000_intr_read_status(intr, &status);
+	if (ret)
+		return ret;
+
+	return !!(status & FL2000_VGA_STATUS_MONITOR_STATUS);
+}
+
+static void fl2000_intr_work(struct work_struct *work)
+{
+	u32 status, events;
+	struct fl2000_intr *intr = container_of(work, struct fl2000_intr, work);
+
+	if (fl2000_intr_read_status(intr, &status))
+		return;
+
+	events = atomic_xchg(&intr->events, 0);
+	if (events)
+		fl2000_drm_hotplug(intr->drm, events);
+}
+
+static void fl2000_intr_release(struct device *dev, void *res)
+{
+	struct fl2000_intr *intr = res;
+	struct usb_device *usb_dev = to_usb_device(dev);
+
+	usb_poison_urb(intr->urb);
+	cancel_work_sync(&intr->work);
+	if (intr->work_queue)
+		destroy_workqueue(intr->work_queue);
+	usb_free_coherent(usb_dev, INTR_BUFSIZE, intr->buf, intr->transfer_dma);
+	usb_free_urb(intr->urb);
+}
+
+static void fl2000_intr_completion(struct urb *urb)
+{
+	int ret;
+	struct usb_device *usb_dev = urb->dev;
+	struct fl2000_intr *intr = urb->context;
+
+	ret = fl2000_urb_status(usb_dev, urb->status);
+	if (ret) {
+		/* Killed on purpose (suspend, unplug) is no reason to complain */
+		if (ret != -ENOENT && ret != -ECONNRESET)
+			dev_err(&usb_dev->dev, "Stopping interrupts\n");
+		return;
+	}
+
+	/* Processing reads registers over USB, which sleeps: defer it to a work item */
+	queue_work(intr->work_queue, &intr->work);
+
+	/*
+	 * For interrupt URBs, as part of successful URB submission urb->interval is modified to
+	 * reflect the actual transfer period used, so we need to restore it.
+	 */
+	urb->interval = intr->poll_interval;
+	urb->start_frame = -1;
+
+	/* Restart urb */
+	ret = usb_submit_urb(urb, GFP_ATOMIC);
+	if (ret)
+		dev_err(&usb_dev->dev, "URB submission failed (%d)\n", ret);
+}
+
+/**
+ * fl2000_intr_create() - interrupt processing context creation
+ * @usb_dev: FL2000 USB device
+ * @drm: DRM device that receives the hotplug events
+ *
+ * Called on DRM master bind. Starts polling the interrupt endpoint.
+ *
+ * Return: interrupt context, or an ERR_PTR() on failure
+ */
+struct fl2000_intr *fl2000_intr_create(struct usb_device *usb_dev, struct drm_device *drm)
+{
+	int ret;
+	struct fl2000_intr *intr;
+	struct usb_endpoint_descriptor *desc;
+	struct usb_interface *interface = usb_ifnum_to_if(usb_dev, FL2000_USBIF_INTERRUPT);
+
+	/*
+	 * There's only one altsetting (#0) and one endpoint (#3) in the interrupt interface (#2)
+	 * but let's try and "find" it anyway.
+	 */
+	ret = usb_find_int_in_endpoint(interface->cur_altsetting, &desc);
+	if (ret) {
+		dev_err(&usb_dev->dev, "Cannot find interrupt endpoint\n");
+		return ERR_PTR(ret);
+	}
+
+	intr = devres_alloc(&fl2000_intr_release, sizeof(*intr), GFP_KERNEL);
+	if (!intr)
+		return ERR_PTR(-ENOMEM);
+	devres_add(&usb_dev->dev, intr);
+
+	intr->poll_interval = desc->bInterval;
+	intr->usb_dev = usb_dev;
+	intr->drm = drm;
+	INIT_WORK(&intr->work, &fl2000_intr_work);
+	atomic_set(&intr->events, 0);
+
+	intr->urb = usb_alloc_urb(0, GFP_KERNEL);
+	if (!intr->urb) {
+		devres_release(&usb_dev->dev, fl2000_intr_release, NULL, NULL);
+		return ERR_PTR(-ENOMEM);
+	}
+
+	intr->buf = usb_alloc_coherent(usb_dev, INTR_BUFSIZE, GFP_KERNEL, &intr->transfer_dma);
+	if (!intr->buf) {
+		devres_release(&usb_dev->dev, fl2000_intr_release, NULL, NULL);
+		return ERR_PTR(-ENOMEM);
+	}
+
+	intr->work_queue = alloc_ordered_workqueue("fl2000_interrupt", 0);
+	if (!intr->work_queue) {
+		devres_release(&usb_dev->dev, fl2000_intr_release, NULL, NULL);
+		return ERR_PTR(-ENOMEM);
+	}
+
+	/* Interrupt URB configuration is static, including allocated buffer */
+	usb_fill_int_urb(intr->urb, usb_dev, usb_rcvintpipe(usb_dev, 3), intr->buf, INTR_BUFSIZE,
+			 fl2000_intr_completion, intr, intr->poll_interval);
+	intr->urb->transfer_dma = intr->transfer_dma;
+	intr->urb->transfer_flags |= URB_NO_TRANSFER_DMA_MAP;
+
+	/* Start checking for interrupts */
+	ret = usb_submit_urb(intr->urb, GFP_KERNEL);
+	if (ret) {
+		dev_err(&usb_dev->dev, "URB submission failed (%d)\n", ret);
+		devres_release(&usb_dev->dev, fl2000_intr_release, NULL, NULL);
+		return ERR_PTR(ret);
+	}
+
+	return intr;
+}
+
+/**
+ * fl2000_intr_quiesce() - stop reporting hotplug events
+ * @intr: interrupt context
+ *
+ * Called before the DRM device is unplugged: an event raised after that would
+ * announce a change on a node that was just removed, and probing the connector
+ * would talk to hardware that is already gone.
+ */
+void fl2000_intr_quiesce(struct fl2000_intr *intr)
+{
+	usb_poison_urb(intr->urb);
+	cancel_work_sync(&intr->work);
+}
+
+/**
+ * fl2000_intr_suspend() - stop polling the interrupt endpoint for system sleep
+ * @intr: interrupt context
+ *
+ * Unlike fl2000_intr_quiesce(), the URB can be submitted again by fl2000_intr_resume().
+ */
+void fl2000_intr_suspend(struct fl2000_intr *intr)
+{
+	usb_kill_urb(intr->urb);
+	cancel_work_sync(&intr->work);
+}
+
+/**
+ * fl2000_intr_resume() - poll the interrupt endpoint again after system sleep
+ * @intr: interrupt context
+ *
+ * Return: 0 on success, the URB submission error otherwise
+ */
+int fl2000_intr_resume(struct fl2000_intr *intr)
+{
+	int ret;
+
+	ret = usb_submit_urb(intr->urb, GFP_KERNEL);
+	if (ret)
+		dev_err(&intr->usb_dev->dev, "URB submission failed (%d)\n", ret);
+
+	return ret;
+}
+
+void fl2000_intr_destroy(struct usb_device *usb_dev)
+{
+	devres_release(&usb_dev->dev, fl2000_intr_release, NULL, NULL);
+}
diff --git a/drivers/gpu/drm/fl2000/fl2000_vga.c b/drivers/gpu/drm/fl2000/fl2000_vga.c
new file mode 100644
index 000000000..322cd8b16
--- /dev/null
+++ b/drivers/gpu/drm/fl2000/fl2000_vga.c
@@ -0,0 +1,256 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * VGA output of the FL2000: the analog DAC of the chip, on an encoder and a connector of its own
+ * next to the HDMI ones. All of them share the one CRTC, so a compositor can use either output
+ * alone, and a dual-output adapter can show the same frame on both ("clone mode").
+ */
+
+#include <drm/drm_atomic_state_helper.h>
+#include <drm/drm_drv.h>
+#include <drm/drm_edid.h>
+#include <drm/drm_managed.h>
+#include <drm/drm_modes.h>
+
+#include "fl2000.h"
+#include "fl2000_it66121.h"
+
+/*
+ * Highest pixel clock offered on VGA, kHz. The DAC has no documented limit; 1920x1080 at 60 Hz is
+ * what the vendor advertises for it.
+ */
+#define FL2000_VGA_MAX_CLOCK 165000
+
+/* The first probes of a connection retry the EDID, in case the monitor is still waking up */
+#define FL2000_VGA_EDID_TRIES 3
+
+/* Offered as the preferred mode when there is no EDID: any VGA monitor takes it */
+#define FL2000_VGA_FALLBACK_WIDTH  1024
+#define FL2000_VGA_FALLBACK_HEIGHT 768
+
+/* Largest mode listed from the standard timings when there is no EDID */
+#define FL2000_VGA_NOEDID_WIDTH	 1920
+#define FL2000_VGA_NOEDID_HEIGHT 1200
+
+static inline struct fl2000_vga *to_fl2000_vga(struct drm_connector *connector)
+{
+	return container_of(connector, struct fl2000_vga, connector);
+}
+
+static int fl2000_vga_read_block(void *context, u8 *buf, unsigned int block, size_t len)
+{
+	struct fl2000_vga *vga = context;
+
+	return fl2000_ddc_read_block(vga->adapter, buf, block, len);
+}
+
+/*
+ * The chip has one monitor sense input, and on the adapters with both outputs it follows whichever
+ * monitor is plugged in. The HDMI transmitter has a hot plug line of its own, so a sensed monitor
+ * with no HDMI sink behind it is a VGA one. With both connected the HDMI sink wins and the VGA
+ * output reports nothing: it can still be forced on (video=VGA-1:e) to mirror the picture.
+ */
+static enum drm_connector_status fl2000_vga_sense(struct fl2000_vga *vga)
+{
+	int ret = fl2000_intr_monitor_connected(vga->intr);
+
+	if (ret < 0)
+		return connector_status_unknown;
+	if (!ret)
+		return connector_status_disconnected;
+
+	if (vga->hdmi_bridge) {
+		/*
+		 * Not knowing whether there is an HDMI sink is not the same as there being none:
+		 * two connected outputs on the one CRTC can leave a compositor with neither.
+		 */
+		ret = it66121_hpd_connected(vga->hdmi_bridge);
+		if (ret < 0)
+			return connector_status_unknown;
+		if (ret)
+			return connector_status_disconnected;
+	}
+
+	return connector_status_connected;
+}
+
+static int fl2000_vga_detect_ctx(struct drm_connector *connector,
+				 struct drm_modeset_acquire_ctx *ctx, bool force)
+{
+	struct fl2000_vga *vga = to_fl2000_vga(connector);
+	enum drm_connector_status status;
+	int idx;
+
+	if (!drm_dev_enter(connector->dev, &idx))
+		return connector_status_disconnected;
+
+	status = fl2000_vga_sense(vga);
+	if (status == connector_status_unknown)
+		/* An unreadable status says nothing: keep what userspace was told */
+		status = connector->status;
+	else if (status != connector_status_connected)
+		/* Whatever comes next may be another monitor: its EDID must be read again */
+		WRITE_ONCE(vga->edid_stale, true);
+
+	drm_dev_exit(idx);
+
+	return status;
+}
+
+/*
+ * The EDID is read through the FL2000 I2C engine. It is kept for as long as the monitor stays, and
+ * only a few probes try for it: a read that finds nothing is quick, but old monitors often do not
+ * answer DDC at all, and every probe runs with the mode config locked.
+ */
+static int fl2000_vga_get_modes(struct drm_connector *connector)
+{
+	struct fl2000_vga *vga = to_fl2000_vga(connector);
+	int count = 0, idx;
+
+	if (!drm_dev_enter(connector->dev, &idx))
+		return 0;
+
+	if (READ_ONCE(vga->edid_stale)) {
+		WRITE_ONCE(vga->edid_stale, false);
+		drm_edid_free(vga->edid);
+		vga->edid = NULL;
+		vga->edid_tries = 0;
+	}
+
+	if (!vga->edid && vga->edid_tries < FL2000_VGA_EDID_TRIES) {
+		vga->edid_tries++;
+		vga->edid = drm_edid_read_custom(connector, fl2000_vga_read_block, vga);
+		drm_dbg_kms(connector->dev, "VGA EDID read %s (try %u)\n",
+			    vga->edid ? "ok" : "failed", vga->edid_tries);
+	}
+
+	drm_edid_connector_update(connector, vga->edid);
+	if (vga->edid)
+		count = drm_edid_connector_add_modes(connector);
+
+	if (!count) {
+		/*
+		 * No EDID, or nothing usable in it: offer the standard timings and let 1024x768
+		 * be the default. Another mode can be chosen from the desktop, or forced on the
+		 * kernel command line (video=VGA-1:1366x768@60e), and an EDID file can replace
+		 * the missing one (drm.edid_firmware=VGA-1:edid/monitor.bin).
+		 */
+		count = drm_add_modes_noedid(connector, FL2000_VGA_NOEDID_WIDTH,
+					     FL2000_VGA_NOEDID_HEIGHT);
+		drm_set_preferred_mode(connector, FL2000_VGA_FALLBACK_WIDTH,
+				       FL2000_VGA_FALLBACK_HEIGHT);
+	}
+
+	drm_dev_exit(idx);
+
+	return count;
+}
+
+static const struct drm_connector_helper_funcs fl2000_vga_connector_helper_funcs = {
+	.get_modes = fl2000_vga_get_modes,
+	.detect_ctx = fl2000_vga_detect_ctx,
+};
+
+static const struct drm_connector_funcs fl2000_vga_connector_funcs = {
+	.fill_modes = drm_helper_probe_single_connector_modes,
+	.atomic_create_state = drm_atomic_helper_connector_create_state,
+	.atomic_duplicate_state = drm_atomic_helper_connector_duplicate_state,
+	.atomic_destroy_state = drm_atomic_helper_connector_destroy_state,
+};
+
+/*
+ * Applies to the VGA output only, both when probing and in atomic commits. The PLL limits are
+ * checked by the CRTC.
+ */
+static enum drm_mode_status fl2000_vga_encoder_mode_valid(struct drm_encoder *encoder,
+							  const struct drm_display_mode *mode)
+{
+	if (mode->clock > FL2000_VGA_MAX_CLOCK)
+		return MODE_CLOCK_HIGH;
+
+	return MODE_OK;
+}
+
+static const struct drm_encoder_helper_funcs fl2000_vga_encoder_helper_funcs = {
+	.mode_valid = fl2000_vga_encoder_mode_valid,
+};
+
+/**
+ * fl2000_vga_sink_event() - the chip reports that a monitor appeared, went away or changed EDID
+ * @vga: VGA output
+ *
+ * Called from the interrupt work. The EDID is read again by the next probe.
+ */
+void fl2000_vga_sink_event(struct fl2000_vga *vga)
+{
+	WRITE_ONCE(vga->edid_stale, true);
+}
+
+static void fl2000_vga_release(struct drm_device *drm, void *res)
+{
+	struct fl2000_vga *vga = res;
+
+	drm_edid_free(vga->edid);
+	drm_bridge_put(vga->hdmi_bridge);
+}
+
+/**
+ * fl2000_vga_init() - add the VGA encoder and connector
+ * @drm: DRM device
+ * @vga: VGA output to set up, part of the driver's device structure
+ * @crtc: the CRTC, which every output shares
+ * @hdmi_encoder: the encoder of the HDMI output, with its bridge already attached
+ * @adapter: the FL2000 I2C adapter, which carries the monitor's DDC
+ * @intr: interrupt context, to sense the monitor
+ *
+ * The HDMI bridge must be attached already, and nothing may be probed before this returns: the
+ * two encoders are marked as clones of each other, in both directions as the core requires.
+ *
+ * Return: 0 on success, a negative error code otherwise
+ */
+int fl2000_vga_init(struct drm_device *drm, struct fl2000_vga *vga, struct drm_crtc *crtc,
+		    struct drm_encoder *hdmi_encoder, struct i2c_adapter *adapter,
+		    struct fl2000_intr *intr)
+{
+	u32 clones;
+	int ret;
+
+	vga->adapter = adapter;
+	vga->intr = intr;
+	vga->hdmi_bridge = drm_bridge_chain_get_first_bridge(hdmi_encoder);
+
+	ret = drmm_add_action_or_reset(drm, fl2000_vga_release, vga);
+	if (ret)
+		return ret;
+
+	ret = drmm_encoder_init(drm, &vga->encoder, NULL, DRM_MODE_ENCODER_DAC, NULL);
+	if (ret)
+		return ret;
+	vga->encoder.possible_crtcs = drm_crtc_mask(crtc);
+	drm_encoder_helper_add(&vga->encoder, &fl2000_vga_encoder_helper_funcs);
+
+	/*
+	 * No ddc adapter: its transfers carry a single byte, so the EDID is read with
+	 * fl2000_ddc_read_block() instead of the DDC helpers.
+	 */
+	ret = drmm_connector_init(drm, &vga->connector, &fl2000_vga_connector_funcs,
+				  DRM_MODE_CONNECTOR_VGA, NULL);
+	if (ret)
+		return ret;
+	drm_connector_helper_add(&vga->connector, &fl2000_vga_connector_helper_funcs);
+
+	/*
+	 * The chip raises an event when the monitor comes or goes (fl2000_interrupt.c), but polling
+	 * recovers from one that was missed, and it costs a status read every few seconds.
+	 */
+	vga->connector.polled = DRM_CONNECTOR_POLL_CONNECT | DRM_CONNECTOR_POLL_DISCONNECT;
+
+	ret = drm_connector_attach_encoder(&vga->connector, &vga->encoder);
+	if (ret)
+		return ret;
+
+	clones = drm_encoder_mask(hdmi_encoder) | drm_encoder_mask(&vga->encoder);
+	hdmi_encoder->possible_clones = clones;
+	vga->encoder.possible_clones = clones;
+
+	return 0;
+}

-- 
2.56.0

