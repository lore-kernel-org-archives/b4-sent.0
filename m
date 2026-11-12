From: Angel Gabriel Crispin Valdivia <angelcrispinvaldivia@gmail.com>
Date: Wed, 11 Nov 2026 22:34:11 -0500
Subject: [PATCH v2 4/4] drm/fl2000: Add KMS display pipeline
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-fl2000-upstream-v2-4-201f87708cb0@gmail.com>
References: <20261111-fl2000-upstream-v2-0-201f87708cb0@gmail.com>
In-Reply-To: <20261111-fl2000-upstream-v2-0-201f87708cb0@gmail.com>
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Angel Gabriel Crispin Valdivia <angelcrispinvaldivia@gmail.com>
Cc: linux-kernel@vger.kernel.org, dri-devel@lists.freedesktop.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794454449; l=55488;
 i=angelcrispinvaldivia@gmail.com; s=20261106; h=from:subject:message-id;
 bh=PxDcK1Nsb4l1vWAHOti3hW47Tx0kqXrFeYnSw92jV5o=;
 b=fRq9cxZrxqU4eS7XZkdu769sorDAYgZJKDNRCiSNyr+QHwCuzlOmmvUClDnRYlbWXMHX3F+bH
 KKPiO4qzIn5DUulGQ4AS5GWldPBlSNzppNEcAbkWzGZULejSKGzzW1Q
X-Developer-Key: i=angelcrispinvaldivia@gmail.com; a=ed25519;
 pk=80bQU/p2R0pLIfdfJaB5I/2obI+RxQHondq5DEM0tbg=
X-Endpoint-Received: by B4 Relay for angelcrispinvaldivia@gmail.com/20261106 with auth_id=1425
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Register the DRM device from the probe, and connect the pieces:

- a primary plane, a CRTC and an encoder, with GEM SHMEM framebuffers
  accessed through the shadow-plane helpers. The device takes RGB888 or
  RGB565: XRGB8888 is converted to the former and RGB565 goes as it is,
  and the plane rejects what the USB link cannot carry at the mode. The
  framebuffer is only read by the CPU, so it does not need to be
  physically contiguous. The primary plane converts each damaged
  rectangle into the stream's shadow frame
- mode validation and PLL search in mode_valid and mode_fixup (which
  adjusts the clock), and FL2000 programming in mode_set_nofb, before the
  bridge is enabled. The PLL cannot make most pixel clocks exactly:
  digital sinks are only offered modes it hits within 500 ppm, while the
  VGA output accepts 5000 ppm, since an analog monitor does not notice
  that but does notice a changed htotal
- the HDMI connector from drm_bridge_connector_init() on the encoder the
  IT66121 bridge is attached to. It is polled, as the bridge has no hot
  plug interrupt of its own
- the analog VGA output of the chip, which adapters with a VGA
  connector expose next to the HDMI one: a DAC encoder and a VGA
  connector on the same CRTC (the two encoders are clones of each
  other). The chip has one monitor sense input, which follows
  whichever monitor is plugged in, so the VGA connector reports a
  monitor when the chip senses one and the IT66121 does not; the EDID
  is read with the FL2000 I2C engine, and without one the standard
  timings are offered
- fbdev emulation
- the FL2000 interrupt endpoint, which reports monitor and IT66121
  events and triggers a hotplug event
- system sleep and USB resets, which stop the display and start it again
  without unbinding: the compositor does not see an unplug. The chips
  may have lost power, so they are set up from scratch

Tested on x86_64 with a UGREEN USB 3.0 adapter with HDMI and VGA
connectors (FL2000DX + IT66121FN): a 1920x1080 monitor on HDMI and an
old 1366x768 monitor without a usable EDID on VGA. EDID, mode setting
in XRGB8888 and RGB565, plugging and unplugging monitors, system sleep,
USB resets and a GNOME Wayland desktop work, with one frame per refresh
on the link. Adapters with a VGA connector only (no IT66121) are not
supported.

Signed-off-by: Angel Gabriel Crispin Valdivia <angelcrispinvaldivia@gmail.com>
---
 drivers/gpu/drm/fl2000/Makefile           |   5 +-
 drivers/gpu/drm/fl2000/fl2000.h           |  33 ++
 drivers/gpu/drm/fl2000/fl2000_drm.c       | 902 ++++++++++++++++++++++++++++++
 drivers/gpu/drm/fl2000/fl2000_drv.c       |  56 +-
 drivers/gpu/drm/fl2000/fl2000_interrupt.c | 226 ++++++++
 drivers/gpu/drm/fl2000/fl2000_vga.c       | 223 ++++++++
 6 files changed, 1437 insertions(+), 8 deletions(-)

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
index e6a7de0f7..9a8ee7927 100644
--- a/drivers/gpu/drm/fl2000/fl2000.h
+++ b/drivers/gpu/drm/fl2000/fl2000.h
@@ -100,6 +100,30 @@ void fl2000_stream_note_render(struct fl2000_stream *stream, unsigned int conv_u
 int fl2000_stream_enable(struct fl2000_stream *stream);
 void fl2000_stream_disable(struct fl2000_stream *stream);
 
+/* Interrupt polling task */
+struct fl2000_intr;
+struct fl2000_intr *fl2000_intr_create(struct usb_device *usb_dev, struct regmap *regmap,
+				       struct drm_device *drm);
+void fl2000_intr_quiesce(struct fl2000_intr *intr);
+void fl2000_intr_suspend(struct fl2000_intr *intr);
+int fl2000_intr_start(struct fl2000_intr *intr);
+int fl2000_intr_monitor_connected(struct fl2000_intr *intr);
+void fl2000_intr_destroy(struct fl2000_intr *intr);
+
+/* VGA output: a DAC encoder and connector next to the HDMI ones, on the same CRTC */
+struct fl2000_vga {
+	struct drm_encoder encoder;
+	struct drm_connector connector;
+	struct i2c_adapter *adapter;
+	struct fl2000_intr *intr;
+	/* The HDMI transmitter shares the chip's monitor sense with this output */
+	struct drm_bridge *hdmi_bridge;
+};
+
+int fl2000_vga_init(struct drm_device *drm, struct fl2000_vga *vga, struct drm_crtc *crtc,
+		    struct drm_encoder *hdmi_encoder, struct i2c_adapter *adapter,
+		    struct fl2000_intr *intr);
+
 /* I2C adapter interface creation */
 struct i2c_adapter *fl2000_i2c_init(struct usb_interface *interface, struct regmap *regmap);
 int fl2000_ddc_read_block(struct i2c_adapter *adapter, u8 *buf, unsigned int block, size_t len);
@@ -123,4 +147,13 @@ int fl2000_stream_interrupts(struct regmap *regmap, bool enable);
 int fl2000_read_status(struct regmap *regmap, u32 *status);
 int fl2000_i2c_dword(struct regmap *regmap, bool read, u16 addr, u8 offset, u32 *data);
 
+/* DRM device creation */
+struct fl2000_device;
+struct fl2000_device *fl2000_drm_create(struct usb_interface *interface, struct regmap *regmap,
+					struct i2c_adapter *adapter, struct drm_bridge *bridge);
+void fl2000_drm_destroy(struct fl2000_device *fdev);
+void fl2000_drm_hotplug(struct drm_device *drm, u32 events);
+int fl2000_drm_suspend(struct fl2000_device *fdev);
+int fl2000_drm_resume(struct fl2000_device *fdev);
+
 #endif /* FL2000_H */
diff --git a/drivers/gpu/drm/fl2000/fl2000_drm.c b/drivers/gpu/drm/fl2000/fl2000_drm.c
new file mode 100644
index 000000000..04efcf583
--- /dev/null
+++ b/drivers/gpu/drm/fl2000/fl2000_drm.c
@@ -0,0 +1,902 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * (C) Copyright 2012, Red Hat
+ * (C) Copyright 2018-2020, Artem Mygaiev
+ */
+
+#include <linux/bitfield.h>
+#include <linux/math64.h>
+
+#include <drm/clients/drm_client_setup.h>
+#include <drm/drm_bridge_connector.h>
+#include <drm/drm_connector.h>
+#include <drm/drm_fbdev_shmem.h>
+#include <drm/drm_gem_atomic_helper.h>
+#include <drm/drm_managed.h>
+#include <drm/drm_modeset_helper.h>
+#include <drm/drm_probe_helper.h>
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
+/* What the timing registers can hold */
+#define FL2000_MAX_WIDTH  FIELD_MAX(FL2000_VGA_HSYNC1_HACTIVE)
+#define FL2000_MAX_HEIGHT FIELD_MAX(FL2000_VGA_VSYNC1_VACTIVE)
+#define FL2000_MAX_HTOTAL FIELD_MAX(FL2000_VGA_HSYNC1_HTOTAL)
+#define FL2000_MAX_VTOTAL FIELD_MAX(FL2000_VGA_VSYNC1_VTOTAL)
+
+/*
+ * RGB565 goes to the device as it is. RGB888 is what it takes otherwise, and XRGB8888, which all of
+ * userspace expects, is converted to it.
+ */
+static const u32 fl2000_pixel_formats[] = {
+	DRM_FORMAT_XRGB8888,
+	DRM_FORMAT_RGB565,
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
+/* Bytes per pixel that the device is sent for a framebuffer */
+static unsigned int fl2000_fb_bytes_pix(const struct drm_framebuffer *fb)
+{
+	return fb->format->format == DRM_FORMAT_RGB565 ? 2 : 3;
+}
+
+/*
+ * Can the USB link carry @mode at @bytes_pix bytes per pixel? The FL2000 has a line buffer and no
+ * frame buffer: it takes the active pixels of exactly one frame per refresh, so the stream needs
+ * the rate of the active area, not the pixel clock.
+ */
+static bool fl2000_link_fits(enum usb_device_speed speed, const struct drm_display_mode *mode,
+			     unsigned int bytes_pix)
+{
+	u32 total = (u32)mode->htotal * mode->vtotal;
+	u64 max_bw, rate;
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
+		return false;
+	}
+
+	if (!total)
+		return false;
+
+	/* Active pixels per second; at most 500 MHz x 4095 x 4095 (see fl2000_mode_check()) */
+	rate = div_u64((u64)mode->clock * 1000 * mode->hdisplay * mode->vdisplay, total);
+
+	return rate * bytes_pix <= max_bw;
+}
+
+struct fl2000_device {
+	struct usb_device *usb_dev;
+	struct drm_device drm;
+	struct drm_plane plane;
+	struct drm_crtc crtc;
+	struct drm_encoder encoder;
+	struct fl2000_vga vga;
+	/*
+	 * Lives as long as the DRM device, not the USB one: a commit that was on its way when the
+	 * adapter was unplugged can still reach it, with userspace holding the device open.
+	 */
+	struct fl2000_stream *stream;
+	struct fl2000_intr *intr;
+	struct regmap *regmap;
+	struct i2c_adapter *adapter;
+	struct drm_bridge *bridge;
+};
+
+static inline struct fl2000_device *to_fl2000_device(struct drm_device *drm)
+{
+	return container_of(drm, struct fl2000_device, drm);
+}
+
+DEFINE_DRM_GEM_FOPS(fl2000_drm_driver_fops);
+
+/*
+ * Mode config cleanup is managed by drmm_mode_config_init(), and the display
+ * pipeline is shut down on unbind, so no .release callback is needed.
+ */
+static struct drm_driver fl2000_drm_driver = {
+	.driver_features = DRIVER_ATOMIC | DRIVER_GEM | DRIVER_MODESET,
+	.fops = &fl2000_drm_driver_fops,
+
+	.dumb_create = drm_gem_shmem_dumb_create,
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
+/*
+ * What the device is sent is set up along with the mode, and the stream sizes its buffers from it:
+ * a framebuffer that changes it takes a full mode set.
+ */
+static int fl2000_atomic_check(struct drm_device *drm, struct drm_atomic_commit *state)
+{
+	struct drm_plane *plane = &to_fl2000_device(drm)->plane;
+	const struct drm_plane_state *new_state = drm_atomic_get_new_plane_state(state, plane);
+	const struct drm_plane_state *old_state = drm_atomic_get_old_plane_state(state, plane);
+
+	if (new_state && new_state->crtc && new_state->fb &&
+	    (!old_state->fb ||
+	     fl2000_fb_bytes_pix(old_state->fb) != fl2000_fb_bytes_pix(new_state->fb))) {
+		struct drm_crtc_state *crtc_state = drm_atomic_get_crtc_state(state,
+									      new_state->crtc);
+
+		if (IS_ERR(crtc_state))
+			return PTR_ERR(crtc_state);
+
+		crtc_state->mode_changed = true;
+	}
+
+	return drm_atomic_helper_check(drm, state);
+}
+
+static const struct drm_mode_config_funcs fl2000_mode_config_funcs = {
+	.fb_create = drm_gem_fb_create_with_dirty,
+	.atomic_check = fl2000_atomic_check,
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
+ * Check a mode against the limits of the chip and find its PLL setting, accepting a pixel clock off
+ * by up to @max_ppm parts per million. @clock is what the PLL really makes, in Hz. The timings of
+ * the mode are never touched.
+ */
+static enum drm_mode_status fl2000_mode_check(const struct drm_display_mode *mode,
+					      struct fl2000_pll *pll, u32 *clock, u64 max_ppm)
+{
+	/*
+	 * The core checks only the modes it probes against mode_config's limits. A mode set by
+	 * userspace gets here as it is, and the stream sizes its buffers from it: a mode the
+	 * primary plane does not even cover could make that size overflow.
+	 */
+	if (mode->hdisplay > FL2000_MAX_WIDTH || mode->htotal > FL2000_MAX_HTOTAL)
+		return MODE_BAD_HVALUE;
+
+	if (mode->vdisplay > FL2000_MAX_HEIGHT || mode->vtotal > FL2000_MAX_VTOTAL)
+		return MODE_BAD_VVALUE;
+
+	if (mode->clock > FL2000_MAX_PIXCLOCK / 1000)
+		return MODE_CLOCK_HIGH;
+
+	/* To keep precision use clock multiplied by 10^6 */
+	if (fl2000_pll_calc((u64)mode->clock * 1000 * FL2000_PLL_PRECISION, pll, clock) >= max_ppm)
+		return MODE_NOCLOCK;
+
+	return MODE_OK;
+}
+
+static enum drm_mode_status fl2000_crtc_mode_valid(struct drm_crtc *crtc,
+						   const struct drm_display_mode *mode)
+{
+	struct fl2000_pll pll;
+	enum drm_mode_status status;
+	u32 clock;
+
+	status = fl2000_mode_check(mode, &pll, &clock, FL2000_PPM_ERR_MAX_VGA);
+	if (status != MODE_OK)
+		return status;
+
+	/* Whatever the framebuffer: the plane checks the format it has */
+	if (!fl2000_link_fits(to_fl2000_device(crtc->dev)->usb_dev->speed, mode, 2))
+		return MODE_CLOCK_HIGH;
+
+	return MODE_OK;
+}
+
+/* The clock of the mode becomes the one the PLL makes for it */
+static bool fl2000_crtc_mode_fixup(struct drm_crtc *crtc, const struct drm_display_mode *mode,
+				   struct drm_display_mode *adjusted_mode)
+{
+	struct fl2000_pll pll;
+	u32 clock;
+
+	if (fl2000_mode_check(mode, &pll, &clock, FL2000_PPM_ERR_MAX_VGA) != MODE_OK)
+		return false;
+
+	adjusted_mode->clock = clock / 1000;
+
+	return true;
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
+	int ret;
+
+	if (new_plane_state->crtc)
+		new_crtc_state = drm_atomic_get_new_crtc_state(state, new_plane_state->crtc);
+
+	ret = drm_atomic_helper_check_plane_state(new_plane_state, new_crtc_state,
+						  DRM_PLANE_NO_SCALING, DRM_PLANE_NO_SCALING,
+						  false, false);
+	if (ret)
+		return ret;
+
+	if (new_plane_state->visible &&
+	    !fl2000_link_fits(to_fl2000_device(plane->dev)->usb_dev->speed,
+			      &new_crtc_state->adjusted_mode,
+			      fl2000_fb_bytes_pix(new_plane_state->fb)))
+		return -EINVAL;
+
+	return 0;
+}
+
+/*
+ * Only the damaged rectangles are converted, into the stream's shadow frame,
+ * which is the one persistent copy every outgoing buffer is built from. One by
+ * one rather than their bounding box: damage in two opposite corners would cost
+ * a whole frame, and a compositor copying into a rotation of buffers (Mutter
+ * 51.1) only keeps the damage current.
+ */
+static void fl2000_plane_atomic_update(struct drm_plane *plane, struct drm_atomic_commit *state)
+{
+	struct drm_plane_state *old_plane_state = drm_atomic_get_old_plane_state(state, plane);
+	struct drm_plane_state *plane_state = drm_atomic_get_new_plane_state(state, plane);
+	struct drm_shadow_plane_state *shadow_plane_state = to_drm_shadow_plane_state(plane_state);
+	struct fl2000_device *fdev = to_fl2000_device(plane->dev);
+	struct drm_framebuffer *fb = plane_state->fb;
+	struct drm_atomic_helper_damage_iter iter;
+	struct drm_rect damage, src;
+	unsigned int damage_px = 0;
+	ktime_t start;
+	int idx;
+
+	if (!fb)
+		return; /* plane is disabled */
+
+	if (drm_gem_fb_begin_cpu_access(fb, DMA_FROM_DEVICE))
+		return;
+
+	if (drm_dev_enter(plane->dev, &idx)) {
+		start = ktime_get();
+		drm_rect_fp_to_int(&src, &plane_state->src);
+		drm_atomic_helper_damage_iter_init(&iter, old_plane_state, plane_state);
+		drm_atomic_for_each_plane_damage(&iter, &damage) {
+			fl2000_stream_compress(fdev->stream, &shadow_plane_state->data[0],
+					       drm_gem_is_imported(fb->obj[0]), fb->pitches[0],
+					       &src, &damage);
+			damage_px += drm_rect_width(&damage) * drm_rect_height(&damage);
+		}
+		if (damage_px)
+			fl2000_stream_note_render(fdev->stream,
+						  (unsigned int)ktime_us_delta(ktime_get(), start),
+						  damage_px);
+		drm_dev_exit(idx);
+	}
+
+	drm_gem_fb_end_cpu_access(fb, DMA_FROM_DEVICE);
+}
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
+/*
+ * Reset the FL2000 with its I2C engine idle. An operation of the engine is a sequence of register
+ * accesses, by the EDID read or the IT66121 regmap at any moment, and it would not survive a reset
+ * or a write to its control register in the middle.
+ */
+static void fl2000_reset_locked(struct fl2000_device *fdev)
+{
+	i2c_lock_bus(fdev->adapter, I2C_LOCK_SEGMENT);
+	fl2000_reset(fdev->regmap);
+	i2c_unlock_bus(fdev->adapter, I2C_LOCK_SEGMENT);
+}
+
+/* Bring the chip to where it can be used, at bind time or when it may have lost power */
+static void fl2000_chip_setup(struct fl2000_device *fdev)
+{
+	i2c_lock_bus(fdev->adapter, I2C_LOCK_SEGMENT);
+	fl2000_reset(fdev->regmap);
+	fl2000_usb_magic(fdev->regmap);
+	i2c_unlock_bus(fdev->adapter, I2C_LOCK_SEGMENT);
+
+	fl2000_enable_sink_interrupts(fdev->regmap);
+}
+
+/* Runs before the bridge is enabled: the IT66121 is programmed with the FL2000 clocking it */
+static void fl2000_crtc_mode_set_nofb(struct drm_crtc *crtc)
+{
+	struct drm_device *drm = crtc->dev;
+	struct fl2000_device *fdev = to_fl2000_device(drm);
+	struct regmap *regmap = fdev->regmap;
+	const struct drm_display_mode *mode = &crtc->state->mode;
+	const struct drm_display_mode *adjusted_mode = &crtc->state->adjusted_mode;
+	struct fl2000_timings timings;
+	struct fl2000_pll pll;
+	unsigned int bytes_pix;
+	u32 clock;
+	int idx, ret;
+
+	/* The same as in mode_fixup, which found one */
+	if (WARN_ON(fl2000_mode_check(mode, &pll, &clock, FL2000_PPM_ERR_MAX_VGA) != MODE_OK))
+		return;
+	/* The CRTC needs a primary plane to be enabled, and this state is the one being applied */
+	bytes_pix = fl2000_fb_bytes_pix(fdev->plane.state->fb);
+
+	/* The registers go with the USB device */
+	if (!drm_dev_enter(drm, &idx))
+		return;
+
+	drm_dbg(drm, "Mode requested:  " DRM_MODE_FMT "\n", DRM_MODE_ARG(mode));
+	drm_dbg(drm, "Mode configured: " DRM_MODE_FMT "\n", DRM_MODE_ARG(adjusted_mode));
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
+	fl2000_set_pll(regmap, &pll);
+
+	/* Reset FL2000 and confirm PLL settings */
+	fl2000_reset_locked(fdev);
+
+	/* Set timings settings */
+	fl2000_set_timings(regmap, &timings);
+
+	/* Pixel format according to number of bytes per pixel */
+	fl2000_set_pixfmt(regmap, bytes_pix);
+
+	/* Configure frame transfers */
+	fl2000_set_transfers(regmap);
+
+	/* The reset may have cleared them, and monitors are to be heard of at all times */
+	fl2000_enable_sink_interrupts(regmap);
+
+	fl2000_afe_magic(regmap);
+
+	/* Too late to fail the commit: without buffers the stream just does not start */
+	ret = fl2000_stream_mode_set(fdev->stream, mode->hdisplay, mode->vdisplay, bytes_pix);
+	if (ret)
+		drm_err(drm, "Cannot allocate the stream buffers (%d)\n", ret);
+
+	drm_dev_exit(idx);
+}
+
+static void fl2000_crtc_atomic_enable(struct drm_crtc *crtc, struct drm_atomic_commit *state)
+{
+	struct fl2000_device *fdev = to_fl2000_device(crtc->dev);
+	int idx;
+
+	if (drm_dev_enter(crtc->dev, &idx)) {
+		fl2000_stream_interrupts(fdev->regmap, true);
+
+		fl2000_stream_enable(fdev->stream);
+
+		drm_dev_exit(idx);
+	}
+}
+
+static void fl2000_crtc_atomic_disable(struct drm_crtc *crtc, struct drm_atomic_commit *state)
+{
+	struct fl2000_device *fdev = to_fl2000_device(crtc->dev);
+	int idx;
+
+	fl2000_stream_disable(fdev->stream);
+
+	if (drm_dev_enter(crtc->dev, &idx)) {
+		fl2000_stream_interrupts(fdev->regmap, false);
+		drm_dev_exit(idx);
+	}
+}
+
+static const struct drm_crtc_helper_funcs fl2000_crtc_helper_funcs = {
+	.mode_valid = fl2000_crtc_mode_valid,
+	.mode_fixup = fl2000_crtc_mode_fixup,
+	.atomic_check = drm_crtc_helper_atomic_check,
+	.mode_set_nofb = fl2000_crtc_mode_set_nofb,
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
+	u32 clock;
+
+	return fl2000_mode_check(mode, &pll, &clock, FL2000_PPM_ERR_MAX);
+}
+
+/*
+ * HDMI has always run with the monitor sense forced, so it stays so whenever HDMI is driven.
+ * Driving VGA alone leaves it to the chip, which then powers the DAC by itself and notices the
+ * cable being unplugged.
+ */
+static void fl2000_hdmi_encoder_force_connect(struct drm_encoder *encoder, bool force)
+{
+	int idx;
+
+	if (drm_dev_enter(encoder->dev, &idx)) {
+		fl2000_force_connect(to_fl2000_device(encoder->dev)->regmap, force);
+		drm_dev_exit(idx);
+	}
+}
+
+static void fl2000_hdmi_encoder_atomic_enable(struct drm_encoder *encoder,
+					      struct drm_atomic_commit *state)
+{
+	fl2000_hdmi_encoder_force_connect(encoder, true);
+}
+
+static void fl2000_hdmi_encoder_atomic_disable(struct drm_encoder *encoder,
+					       struct drm_atomic_commit *state)
+{
+	fl2000_hdmi_encoder_force_connect(encoder, false);
+}
+
+static const struct drm_encoder_helper_funcs fl2000_hdmi_encoder_helper_funcs = {
+	.mode_valid = fl2000_hdmi_encoder_mode_valid,
+	.atomic_enable = fl2000_hdmi_encoder_atomic_enable,
+	.atomic_disable = fl2000_hdmi_encoder_atomic_disable,
+};
+
+/**
+ * fl2000_drm_hotplug() - tell userspace that a monitor came, went or changed
+ * @drm: DRM device
+ * @events: the sink event bits of the status register that were seen
+ *
+ * Called from the interrupt work, which is stopped before the bridge goes away.
+ */
+void fl2000_drm_hotplug(struct drm_device *drm, u32 events)
+{
+	struct fl2000_device *fdev = to_fl2000_device(drm);
+	int idx;
+
+	if (events & FL2000_VGA_STATUS_HDMI_EVENT) {
+		int ret = it66121_ack_interrupts(fdev->bridge);
+
+		if (ret)
+			drm_dbg(drm, "Cannot acknowledge IT66121 interrupts (%d)\n", ret);
+	}
+
+	if (!drm_dev_enter(drm, &idx))
+		return;
+
+	drm_kms_helper_hotplug_event(drm);
+
+	drm_dev_exit(idx);
+}
+
+/**
+ * fl2000_drm_destroy() - stop the display and take the DRM device away from userspace
+ * @fdev: the DRM device
+ *
+ * Called when the USB interfaces are unbound.
+ */
+void fl2000_drm_destroy(struct fl2000_device *fdev)
+{
+	struct drm_device *drm = &fdev->drm;
+
+	/* No hotplug events for a node that is about to disappear */
+	fl2000_intr_quiesce(fdev->intr);
+	drm_kms_helper_poll_fini(drm);
+
+	/* Block userspace access and shut down the display pipeline */
+	drm_dev_unplug(drm);
+	drm_atomic_helper_shutdown(drm);
+
+	/* Already stopped, unless it was left running by a shutdown that failed */
+	fl2000_stream_disable(fdev->stream);
+
+	fl2000_intr_destroy(fdev->intr);
+}
+
+/**
+ * fl2000_drm_suspend() - stop the display for system sleep or a USB reset
+ * @fdev: the DRM device
+ *
+ * Called once for the device, before any of its interfaces is suspended. The USB core goes on with
+ * the sleep even if this fails, so the stream is stopped anyway, and fl2000_drm_resume() sets the
+ * chips up again in any case.
+ *
+ * Return: 0 on success, a negative error code otherwise
+ */
+int fl2000_drm_suspend(struct fl2000_device *fdev)
+{
+	int ret;
+
+	/* No hotplug events while going to sleep */
+	fl2000_intr_suspend(fdev->intr);
+
+	/* Saves the state, turns the outputs off and stops the stream */
+	ret = drm_mode_config_helper_suspend(&fdev->drm);
+	if (ret) {
+		drm_err(&fdev->drm, "Cannot save the display state (%d)\n", ret);
+		fl2000_stream_disable(fdev->stream);
+	}
+
+	return ret;
+}
+
+/**
+ * fl2000_drm_resume() - bring the display back after system sleep or a USB reset
+ * @fdev: the DRM device
+ *
+ * Called once for the device, when all of it is awake again, also after a reset-resume. The chips
+ * may have lost power: they are set up as at bind time before the saved state is restored.
+ *
+ * Return: 0 on success, a negative error code otherwise
+ */
+int fl2000_drm_resume(struct fl2000_device *fdev)
+{
+	struct regmap *regmap = fdev->regmap;
+	int ret = 0;
+
+	/* First, as the IT66121 is reached through the FL2000 I2C engine */
+	fl2000_regmap_drop_cache(regmap);
+
+	it66121_resume(fdev->bridge);
+
+	/* The same order as in fl2000_drm_create() */
+	fl2000_chip_setup(fdev);
+
+	/* There is nothing to restore if saving the state failed */
+	if (fdev->drm.mode_config.suspend_state) {
+		ret = drm_mode_config_helper_resume(&fdev->drm);
+		if (ret)
+			drm_err(&fdev->drm, "Cannot restore the display after sleep (%d)\n", ret);
+	}
+
+	/* Without interrupts the connectors are still polled */
+	fl2000_intr_start(fdev->intr);
+
+	drm_kms_helper_hotplug_event(&fdev->drm);
+
+	return ret;
+}
+
+static void fl2000_stream_release(struct drm_device *drm, void *res)
+{
+	fl2000_stream_destroy(res);
+}
+
+/**
+ * fl2000_drm_create() - set up and register the DRM device
+ * @interface: USB interface the device belongs to
+ * @regmap: FL2000 registers
+ * @adapter: FL2000 I2C adapter
+ * @bridge: IT66121 bridge
+ *
+ * Return: the DRM device, or an ERR_PTR() on failure
+ */
+struct fl2000_device *fl2000_drm_create(struct usb_interface *interface, struct regmap *regmap,
+					struct i2c_adapter *adapter, struct drm_bridge *bridge)
+{
+	int ret = 0;
+	struct usb_device *usb_dev = interface_to_usbdev(interface);
+	struct fl2000_device *fdev;
+	struct drm_device *drm;
+	struct device *dma_dev;
+	struct drm_mode_config *mode_config;
+	struct drm_connector_list_iter conn_iter;
+	struct drm_connector *connector;
+
+	dev_dbg(&interface->dev, "Creating the FL2000 DRM device\n");
+
+	fdev = devm_drm_dev_alloc(&interface->dev, &fl2000_drm_driver, struct fl2000_device, drm);
+	if (IS_ERR(fdev)) {
+		dev_err(&interface->dev, "Cannot allocate DRM structure (%pe)\n", fdev);
+		return fdev;
+	}
+	drm = &fdev->drm;
+	fdev->usb_dev = usb_dev;
+	fdev->regmap = regmap;
+	fdev->adapter = adapter;
+	fdev->bridge = bridge;
+
+	/* A USB device cannot DMA by itself: dma-buf imports go through its host controller */
+	dma_dev = usb_intf_get_dma_device(interface);
+	if (dma_dev) {
+		drm_dev_set_dma_dev(drm, dma_dev);
+		put_device(dma_dev);
+	} else {
+		drm_warn(drm, "No DMA device: framebuffers from another GPU cannot be used\n");
+	}
+
+	ret = drmm_mode_config_init(drm);
+	if (ret) {
+		drm_err(drm, "Cannot initialize DRM mode (%d)\n", ret);
+		return ERR_PTR(ret);
+	}
+
+	mode_config = &drm->mode_config;
+	mode_config->funcs = &fl2000_mode_config_funcs;
+	mode_config->max_width = FL2000_MAX_WIDTH;
+	mode_config->max_height = FL2000_MAX_HEIGHT;
+
+	ret = drm_universal_plane_init(drm, &fdev->plane, 0, &fl2000_plane_funcs,
+				       fl2000_pixel_formats, ARRAY_SIZE(fl2000_pixel_formats),
+				       fl2000_plane_format_modifiers, DRM_PLANE_TYPE_PRIMARY, NULL);
+	if (ret) {
+		drm_err(drm, "Cannot initialize plane (%d)\n", ret);
+		return ERR_PTR(ret);
+	}
+	drm_plane_helper_add(&fdev->plane, &fl2000_plane_helper_funcs);
+
+	/*
+	 * Enable the damage-clips property the update path relies on
+	 * (drm_atomic_helper_damage_merged()).
+	 */
+	drm_plane_enable_fb_damage_clips(&fdev->plane);
+
+	ret = drmm_crtc_init_with_planes(drm, &fdev->crtc, &fdev->plane, NULL,
+					 &fl2000_crtc_funcs, NULL);
+	if (ret) {
+		drm_err(drm, "Cannot initialize CRTC (%d)\n", ret);
+		return ERR_PTR(ret);
+	}
+	drm_crtc_helper_add(&fdev->crtc, &fl2000_crtc_helper_funcs);
+	fdev->plane.possible_crtcs = drm_crtc_mask(&fdev->crtc);
+
+	/* The FL2000 is programmed from the CRTC; the IT66121 bridge hangs off this encoder */
+	ret = drmm_encoder_init(drm, &fdev->encoder, NULL, DRM_MODE_ENCODER_NONE, NULL);
+	if (ret) {
+		drm_err(drm, "Cannot initialize encoder (%d)\n", ret);
+		return ERR_PTR(ret);
+	}
+	fdev->encoder.possible_crtcs = drm_crtc_mask(&fdev->crtc);
+	drm_encoder_helper_add(&fdev->encoder, &fl2000_hdmi_encoder_helper_funcs);
+
+	/* Start streaming interface */
+	fdev->stream = fl2000_stream_create(usb_dev);
+	if (IS_ERR(fdev->stream)) {
+		ret = PTR_ERR(fdev->stream);
+		drm_err(drm, "Cannot create stream (%d)\n", ret);
+		return ERR_PTR(ret);
+	}
+
+	ret = drmm_add_action_or_reset(drm, fl2000_stream_release, fdev->stream);
+	if (ret)
+		return ERR_PTR(ret);
+
+	fdev->intr = fl2000_intr_create(usb_dev, regmap, drm);
+	if (IS_ERR(fdev->intr)) {
+		ret = PTR_ERR(fdev->intr);
+		drm_err(drm, "Cannot set up interrupts (%d)\n", ret);
+		return ERR_PTR(ret);
+	}
+
+	/* The display driver makes the connector, from what the bridge reports */
+	ret = drm_bridge_attach(&fdev->encoder, bridge, NULL, DRM_BRIDGE_ATTACH_NO_CONNECTOR);
+	if (ret) {
+		drm_err(drm, "Cannot attach bridge (%d)\n", ret);
+		goto err_destroy_intr;
+	}
+
+	/*
+	 * The HDMI connector is the generic one of the bridge chain: the IT66121 attached without
+	 * a connector of its own and reports the hot plug line and the EDID.
+	 */
+	connector = drm_bridge_connector_init(drm, &fdev->encoder);
+	if (IS_ERR(connector)) {
+		ret = PTR_ERR(connector);
+		drm_err(drm, "Cannot initialize HDMI connector (%d)\n", ret);
+		goto err_destroy_intr;
+	}
+
+	/* The VGA output looks at the bridge the HDMI encoder has by now */
+	ret = fl2000_vga_init(drm, &fdev->vga, &fdev->crtc, &fdev->encoder, adapter,
+			      fdev->intr);
+	if (ret) {
+		drm_err(drm, "Cannot initialize VGA output (%d)\n", ret);
+		goto err_destroy_intr;
+	}
+
+	drm_mode_config_reset(drm);
+
+	fl2000_chip_setup(fdev);
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
+		goto err_destroy_intr;
+	}
+
+	/* Without interrupts the connectors are still polled */
+	fl2000_intr_start(fdev->intr);
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
+	return fdev;
+
+err_destroy_intr:
+	fl2000_intr_destroy(fdev->intr);
+
+	return ERR_PTR(ret);
+}
diff --git a/drivers/gpu/drm/fl2000/fl2000_drv.c b/drivers/gpu/drm/fl2000/fl2000_drv.c
index 31d153553..663fb5daa 100644
--- a/drivers/gpu/drm/fl2000/fl2000_drv.c
+++ b/drivers/gpu/drm/fl2000/fl2000_drv.c
@@ -35,6 +35,9 @@ struct fl2000_devs {
 	struct regmap *regmap;
 	struct i2c_adapter *adapter;
 	struct drm_bridge *bridge;
+	struct fl2000_device *fdev;
+	/* The display was stopped for system sleep or a reset and has not been restarted yet */
+	bool suspended;
 };
 
 /* Interface 0 is what the driver is probing: claim the others */
@@ -116,10 +119,20 @@ static int fl2000_probe(struct usb_interface *interface, const struct usb_device
 	if (ret)
 		goto err_destroy_bridge;
 
+	devs->fdev = fl2000_drm_create(interface, devs->regmap, devs->adapter, devs->bridge);
+	if (IS_ERR(devs->fdev)) {
+		ret = PTR_ERR(devs->fdev);
+		goto err_release_interfaces;
+	}
+
 	usb_set_intfdata(interface, devs);
 
 	return 0;
 
+err_release_interfaces:
+	for (int i = FL2000_USBIF_AVCONTROL + 1; i < FL2000_USBIF_NUM; i++)
+		usb_set_intfdata(usb_ifnum_to_if(usb_dev, i), NULL);
+	fl2000_release_interfaces(usb_dev, interface);
 err_destroy_bridge:
 	it66121_destroy(devs->bridge);
 
@@ -138,26 +151,52 @@ static void fl2000_disconnect(struct usb_interface *interface)
 	for (int i = 0; i < FL2000_USBIF_NUM; i++)
 		usb_set_intfdata(usb_ifnum_to_if(usb_dev, i), NULL);
 
+	fl2000_drm_destroy(devs->fdev);
 	it66121_destroy(devs->bridge);
 
 	/* Last, as devs goes with interface 0, which may be one of these */
 	fl2000_release_interfaces(usb_dev, interface);
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
-	/*
-	 * Nothing to save yet. Providing the callback keeps the USB core from
-	 * unbinding the driver across system sleep.
-	 */
-	dev_dbg(&interface->dev, "suspend\n");
+	struct fl2000_devs *devs = usb_get_intfdata(interface);
 
-	return 0;
+	if (!devs || devs->suspended)
+		return 0;
+
+	/* Even if this fails: the USB core ignores the error during system sleep and goes on */
+	devs->suspended = true;
+
+	return fl2000_drm_suspend(devs->fdev);
 }
 
 static int fl2000_resume(struct usb_interface *interface)
 {
-	dev_dbg(&interface->dev, "resume\n");
+	struct fl2000_devs *devs = usb_get_intfdata(interface);
+
+	if (!devs || !devs->suspended)
+		return 0;
+
+	devs->suspended = false;
+
+	return fl2000_drm_resume(devs->fdev);
+}
+
+/*
+ * A reset of the USB device (the storage function of the adapter asks for one when it times out)
+ * is the same as far as the display goes. Nonzero would make the USB core unbind the driver.
+ */
+static int fl2000_pre_reset(struct usb_interface *interface)
+{
+	fl2000_suspend(interface, PMSG_SUSPEND);
 
 	return 0;
 }
@@ -168,6 +207,9 @@ static struct usb_driver fl2000_driver = {
 	.disconnect = fl2000_disconnect,
 	.suspend = fl2000_suspend,
 	.resume = fl2000_resume,
+	.reset_resume = fl2000_resume,
+	.pre_reset = fl2000_pre_reset,
+	.post_reset = fl2000_resume,
 	.id_table = fl2000_id_table,
 	.supports_autosuspend = false,
 	.disable_hub_initiated_lpm = true,
diff --git a/drivers/gpu/drm/fl2000/fl2000_interrupt.c b/drivers/gpu/drm/fl2000/fl2000_interrupt.c
new file mode 100644
index 000000000..8f8f9fac1
--- /dev/null
+++ b/drivers/gpu/drm/fl2000/fl2000_interrupt.c
@@ -0,0 +1,226 @@
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
+	struct regmap *regmap;
+	struct drm_device *drm;
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
+	ret = fl2000_read_status(intr->regmap, status);
+	if (ret)
+		return ret;
+
+	atomic_or(*status & FL2000_SINK_EVENTS, &intr->events);
+
+	return 0;
+}
+
+/**
+ * fl2000_intr_monitor_connected() - does the FL2000 sense a monitor on its monitor input
+ * @intr: interrupt context
+ *
+ * The chip powers the DAC and the PLL only while this is the case. On the boards with both
+ * outputs the input follows whichever monitor is connected, so it does not tell VGA from HDMI.
+ * While HDMI is being driven the sense is forced on and tells nothing: that counts as not sensing,
+ * or an HDMI monitor going away would look like a VGA one showing up, until the CRTC is disabled.
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
+	if (fl2000_force_connect_active(intr->regmap))
+		return 0;
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
+static void fl2000_intr_completion(struct urb *urb)
+{
+	int ret;
+	struct usb_device *usb_dev = urb->dev;
+	struct fl2000_intr *intr = urb->context;
+
+	ret = fl2000_urb_status(usb_dev, urb->status);
+	if (ret) {
+		/* Killed on purpose (suspend, unplug) is no reason to complain */
+		if (ret != -ENOENT && ret != -ECONNRESET && ret != -ESHUTDOWN)
+			dev_err(&usb_dev->dev, "Stopping interrupts\n");
+		return;
+	}
+
+	/* Processing reads registers over USB, which sleeps: defer it to a work item */
+	queue_work(intr->work_queue, &intr->work);
+
+	/* Restart urb. It may be getting poisoned, or the device may have just gone. */
+	ret = usb_submit_urb(urb, GFP_ATOMIC);
+	if (ret && ret != -EPERM && ret != -ENODEV)
+		dev_err(&usb_dev->dev, "URB submission failed (%d)\n", ret);
+}
+
+/**
+ * fl2000_intr_create() - interrupt processing context creation
+ * @usb_dev: FL2000 USB device
+ * @regmap: FL2000 registers
+ * @drm: DRM device that receives the hotplug events
+ *
+ * Called when the DRM device is set up. fl2000_intr_start() starts polling the interrupt endpoint.
+ *
+ * Return: interrupt context, or an ERR_PTR() on failure
+ */
+struct fl2000_intr *fl2000_intr_create(struct usb_device *usb_dev, struct regmap *regmap,
+				       struct drm_device *drm)
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
+	intr = kzalloc_obj(*intr);
+	if (!intr)
+		return ERR_PTR(-ENOMEM);
+
+	intr->usb_dev = usb_dev;
+	intr->regmap = regmap;
+	intr->drm = drm;
+	INIT_WORK(&intr->work, &fl2000_intr_work);
+	atomic_set(&intr->events, 0);
+
+	ret = -ENOMEM;
+	intr->urb = usb_alloc_urb(0, GFP_KERNEL);
+	if (!intr->urb)
+		goto err_destroy;
+
+	intr->buf = usb_alloc_coherent(usb_dev, INTR_BUFSIZE, GFP_KERNEL, &intr->transfer_dma);
+	if (!intr->buf)
+		goto err_destroy;
+
+	intr->work_queue = alloc_ordered_workqueue("fl2000_interrupt", 0);
+	if (!intr->work_queue)
+		goto err_destroy;
+
+	/* Interrupt URB configuration is static, including allocated buffer */
+	usb_fill_int_urb(intr->urb, usb_dev, usb_rcvintpipe(usb_dev, usb_endpoint_num(desc)),
+			 intr->buf, INTR_BUFSIZE, fl2000_intr_completion, intr, desc->bInterval);
+	intr->urb->transfer_dma = intr->transfer_dma;
+	intr->urb->transfer_flags |= URB_NO_TRANSFER_DMA_MAP;
+
+	return intr;
+
+err_destroy:
+	fl2000_intr_destroy(intr);
+
+	return ERR_PTR(ret);
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
+ * Unlike fl2000_intr_quiesce(), the URB can be submitted again by fl2000_intr_start().
+ */
+void fl2000_intr_suspend(struct fl2000_intr *intr)
+{
+	usb_kill_urb(intr->urb);
+	cancel_work_sync(&intr->work);
+}
+
+/**
+ * fl2000_intr_start() - poll the interrupt endpoint
+ * @intr: interrupt context
+ *
+ * When the display is ready to hear about monitors: its hotplug events must find the DRM device
+ * registered, and after system sleep the pipeline restored.
+ *
+ * Return: 0 on success, the URB submission error otherwise
+ */
+int fl2000_intr_start(struct fl2000_intr *intr)
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
+void fl2000_intr_destroy(struct fl2000_intr *intr)
+{
+	usb_poison_urb(intr->urb);
+	cancel_work_sync(&intr->work);
+	if (intr->work_queue)
+		destroy_workqueue(intr->work_queue);
+	usb_free_coherent(intr->usb_dev, INTR_BUFSIZE, intr->buf, intr->transfer_dma);
+	usb_free_urb(intr->urb);
+	kfree(intr);
+}
diff --git a/drivers/gpu/drm/fl2000/fl2000_vga.c b/drivers/gpu/drm/fl2000/fl2000_vga.c
new file mode 100644
index 000000000..01e77d11c
--- /dev/null
+++ b/drivers/gpu/drm/fl2000/fl2000_vga.c
@@ -0,0 +1,223 @@
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
+
+	drm_dev_exit(idx);
+
+	return status;
+}
+
+/* The EDID is read through the FL2000 I2C engine */
+static int fl2000_vga_get_modes(struct drm_connector *connector)
+{
+	struct fl2000_vga *vga = to_fl2000_vga(connector);
+	const struct drm_edid *drm_edid;
+	int count = 0, idx;
+
+	if (!drm_dev_enter(connector->dev, &idx))
+		return 0;
+
+	drm_edid = drm_edid_read_custom(connector, fl2000_vga_read_block, vga);
+	drm_edid_connector_update(connector, drm_edid);
+	if (drm_edid)
+		count = drm_edid_connector_add_modes(connector);
+	drm_edid_free(drm_edid);
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
+static void fl2000_vga_release(struct drm_device *drm, void *res)
+{
+	struct fl2000_vga *vga = res;
+
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

