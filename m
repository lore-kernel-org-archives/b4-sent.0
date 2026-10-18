From: Mike Anderson <mwwa919@gmail.com>
Date: Sun, 18 Oct 2026 16:12:40 -0400
Subject: [PATCH] drm/i915/dsi: Use owned panel/backlight GPIOs in VLV MIPI
 sequences
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261018-vlv-dsi-owned-gpios-v1-1-3ca18bcda670@gmail.com>
X-B4-Tracking: v=1; b=H4sIADco1WoC/yXMQQqDMBBA0avIrDvgpNBIr1JcaDLVkZJIpkZBv
 HtTXb7F/zsoJ2GFZ7VD4iwqMRTQrQI3dmFgFF8MpjYPqqnB/MnoVTCugT0Os0RF58nYvqO7ZQu
 lnBO/ZTuvr/ayLv3E7vtfwXH8ANQqkXx3AAAA
X-Change-ID: 20261018-vlv-dsi-owned-gpios-cd127ba137e7
To: Jani Nikula <jani.nikula@linux.intel.com>, 
 Rodrigo Vivi <rodrigo.vivi@intel.com>, intel-gfx@lists.freedesktop.org
Cc: Joonas Lahtinen <joonas.lahtinen@linux.intel.com>, 
 Tvrtko Ursulin <tursulin@ursulin.net>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Hans de Goede <hansg@kernel.org>, intel-xe@lists.freedesktop.org, 
 dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Mike Anderson <mwwa919@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792354368; l=5805;
 i=mwwa919@gmail.com; s=20261018; h=from:subject:message-id;
 bh=fqIda2quYt/iS4PsHXKJtfdrABxMHpRCeHK2kOAm+9k=;
 b=YPHI4gGMlKh/kb6yUfYInfnPvCZcDfrreT+IUEzcqj8yDTmMeypyE/LvfsSY7CklhtFaRTt2Q
 HYf2EATZ1JuCKiR8aNZuOhkZcMZnQCuOATJ0osAE1n4myfVScnPlcDL
X-Developer-Key: i=mwwa919@gmail.com; a=ed25519;
 pk=r8JyAI3thBa7smjCwoiNX+4TLbge6jj5Swldychd7nE=
X-Endpoint-Received: by B4 Relay for mwwa919@gmail.com/20261018 with auth_id=1231
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On VLV with PPS_BLC_SOC, intel_dsi_vbt_gpio_init() requests the
backlight and panel enable GPIOs (INT33FC:01 pins 10 and 11) for i915
itself. Since commit 8241b55f1ded ("drm/i915/dsi: Replace poking of VLV
GPIOs behind the driver's back") the GPIO elements of the VBT MIPI
sequences also request their pin through gpiolib, so when a sequence
toggles one of these two pins the request fails and the toggle is
dropped:

  i915 0000:00:02.0: [drm] *ERROR* GPIO index 10 request failed (-EBUSY)

Before that commit the pad registers were written directly, so the
sequences could still drive the pins i915 owned.

The Toshiba Encore 2 WT8-B (Bay Trail, DSI panel) uses pin 10 as the
panel reset line: MIPI_SEQ_ASSERT_RESET drives it low and
MIPI_SEQ_DEASSERT_RESET pulses it high-low-high. With every toggle
failing, the panel is never reset after i915 sends MIPI_SEQ_DISPLAY_OFF
during takeover and stays black, even though the backlight PWM and both
enable GPIOs read back as on. The tablet only has a usable display
with nomodeset.

When a VLV MIPI sequence targets pin 10 or 11 and i915 holds the
corresponding descriptor, set it through that descriptor instead of
requesting the pin a second time.

Fixes: 8241b55f1ded ("drm/i915/dsi: Replace poking of VLV GPIOs behind the driver's back")
Cc: stable@vger.kernel.org
Assisted-by: LLM sparse
Signed-off-by: Mike Anderson <mwwa919@gmail.com>
---
This patch was developed with an AI coding assistant (Claude Code,
Claude Opus 5.5): it ran the debugging session on the tablet (drm.debug
log, gpio/pwm debugfs), traced the -EBUSY to 8241b55f1ded, and wrote the
change and the changelog; I reviewed it and tested it on the hardware.

Testing, Toshiba Encore 2 WT8-B (Atom Z3735F, BIOS 2.10, VBT MIPI
sequence block v2, PPS_BLC_SOC):
- Arch Linux v7.2.11-arch1 with this patch backported (applies as is):
  the panel lights up at i915 takeover and the Xorg login screen shows;
  no "GPIO index ... request failed" errors; gpio-10/11 stay owned as
  "backlight"/"panel". Unpatched v7.2.11 and v6.18.57 give a black
  panel with five -EBUSY errors during boot.
- drm-intel-next: built intel_dsi_vbt.o for i915 (=m and =y) and for
  xe (=m) with W=1 and sparse (C=2, sparse v0.6.5-rc1): no new
  warnings.

Not tested: other VLV machines with PPS_BLC_SOC. Their behaviour only
changes when their VBT sequences touch pin 10 or 11, which currently
fails with -EBUSY anyway.
---
 drivers/gpu/drm/i915/display/intel_dsi_vbt.c | 32 +++++++++++++++++++++++-----
 1 file changed, 27 insertions(+), 5 deletions(-)

diff --git a/drivers/gpu/drm/i915/display/intel_dsi_vbt.c b/drivers/gpu/drm/i915/display/intel_dsi_vbt.c
index fe12041e9..85d1cdc6e 100644
--- a/drivers/gpu/drm/i915/display/intel_dsi_vbt.c
+++ b/drivers/gpu/drm/i915/display/intel_dsi_vbt.c
@@ -54,6 +54,10 @@
 #define MIPI_VIRTUAL_CHANNEL_SHIFT	1
 #define MIPI_PORT_SHIFT			3
 
+/* VLV NC pins of the backlight and panel enable GPIOs, see soc_panel_gpio_table */
+#define VLV_GPIO_NC_BACKLIGHT		10
+#define VLV_GPIO_NC_PANEL		11
+
 struct i2c_adapter_lookup {
 	u16 target_addr;
 	struct intel_dsi *intel_dsi;
@@ -247,10 +251,12 @@ static void soc_opaque_gpio_set_value(struct intel_connector *connector,
 	kfree(lookup);
 }
 
-static void vlv_gpio_set_value(struct intel_connector *connector,
+static void vlv_gpio_set_value(struct intel_dsi *intel_dsi,
 			       u8 gpio_source, u8 gpio_index, bool value)
 {
-	struct intel_display *display = to_intel_display(connector);
+	struct intel_display *display = to_intel_display(&intel_dsi->base);
+	struct intel_connector *connector = intel_dsi->attached_connector;
+	struct gpio_desc *gpio_desc = NULL;
 
 	/* XXX: this assumes vlv_gpio_table only has NC GPIOs. */
 	if (connector->panel.vbt.dsi.seq_version < 3) {
@@ -265,6 +271,22 @@ static void vlv_gpio_set_value(struct intel_connector *connector,
 		}
 	}
 
+	/*
+	 * With PPS_BLC_SOC, intel_dsi_vbt_gpio_init() already owns these pins,
+	 * so requesting them again fails with -EBUSY. Some VBTs still toggle
+	 * them in their MIPI sequences, e.g. as the panel reset line, so drive
+	 * them through the descriptors we hold.
+	 */
+	if (gpio_index == VLV_GPIO_NC_BACKLIGHT)
+		gpio_desc = intel_dsi->gpio_backlight;
+	else if (gpio_index == VLV_GPIO_NC_PANEL)
+		gpio_desc = intel_dsi->gpio_panel;
+
+	if (gpio_desc && connector->panel.vbt.dsi.config->pwm_blc == PPS_BLC_SOC) {
+		gpiod_set_value_cansleep(gpio_desc, value);
+		return;
+	}
+
 	soc_opaque_gpio_set_value(connector, gpio_index,
 				  "INT33FC:01", "Panel N", gpio_index, value);
 }
@@ -430,7 +452,7 @@ static const u8 *mipi_exec_gpio(struct intel_dsi *intel_dsi, const u8 *data)
 	else if (DISPLAY_VER(display) >= 9)
 		bxt_gpio_set_value(connector, gpio_index, value);
 	else if (display->platform.valleyview)
-		vlv_gpio_set_value(connector, gpio_source, gpio_number, value);
+		vlv_gpio_set_value(intel_dsi, gpio_source, gpio_number, value);
 	else if (display->platform.cherryview)
 		chv_gpio_set_value(connector, gpio_source, gpio_number, value);
 
@@ -886,8 +908,8 @@ static struct gpiod_lookup_table pmic_panel_gpio_table = {
 static struct gpiod_lookup_table soc_panel_gpio_table = {
 	.dev_id = "0000:00:02.0",
 	.table = {
-		GPIO_LOOKUP("INT33FC:01", 10, "backlight", GPIO_ACTIVE_HIGH),
-		GPIO_LOOKUP("INT33FC:01", 11, "panel", GPIO_ACTIVE_HIGH),
+		GPIO_LOOKUP("INT33FC:01", VLV_GPIO_NC_BACKLIGHT, "backlight", GPIO_ACTIVE_HIGH),
+		GPIO_LOOKUP("INT33FC:01", VLV_GPIO_NC_PANEL, "panel", GPIO_ACTIVE_HIGH),
 		{ }
 	},
 };

---
base-commit: 0507cc5a476af0b6d037b19248bdd20dbe27487d
change-id: 20261018-vlv-dsi-owned-gpios-cd127ba137e7

Best regards,
--  
Mike Anderson <mwwa919@gmail.com>

