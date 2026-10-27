From: Haipeng Lin <jimmie.lin@gmail.com>
Date: Mon, 26 Oct 2026 21:13:02 -0400
Subject: [PATCH v2] drm/panel-edp: disable the backlight at probe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-sp11-bl-upstream-1-v2-1-efc84396adf1@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NQQqDMBBFryKz7pRMWkLtqvcoLhIz0QGjklhpE
 e/e1AN08+F9+O9vkDkJZ7hXGyReJcs0FtCnCtrejh2j+MKglTak9BXzTIRuwNecl8Q2IiEbQ8a
 amzdBQRnOiYO8D+mzKdxLXqb0OT5W+rV/dSuV8JfaBRtqG1z76KKV4dxOEZp937+Ogc2WtAAAA
 A==
X-Change-ID: 20261024-sp11-bl-upstream-1-e6616a68d6f0
To: Douglas Anderson <dianders@chromium.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>
Cc: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Linus Walleij <linusw@kernel.org>, Sam Ravnborg <sam@ravnborg.org>, 
 dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Dale Whinham <daleyo@gmail.com>, linux-arm-msm@vger.kernel.org, 
 aarch64-laptops@lists.linaro.org, Haipeng Lin <jimmie.lin@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793063673; l=4890;
 i=jimmie.lin@gmail.com; s=20261011; h=from:subject:message-id;
 bh=Wc0k3oO67F3S7EDiEGmSzJEvwEL5CUGbgzDoGXTLcs8=;
 b=+lS75aoCJDPrdFiEZL0w7xUoK2eON3nABsbxAPsz28j9zI94XDgBJQdLexqdioijrzqv2Zoxc
 8PH2eb3pR4aCab9gRf5IECpOmd6qj4Mb0NEo5JskcYdo1h4E3egOfbO
X-Developer-Key: i=jimmie.lin@gmail.com; a=ed25519;
 pk=3KDRF1RQ/9A7ZUVTdRVEZnVrGltdmq1bRocsOYeXezI=
X-Endpoint-Received: by B4 Relay for jimmie.lin@gmail.com/20261011 with auth_id=1164
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pwm-backlight can preserve the enabled state left by firmware to
support a seamless display handoff. However, panel-edp does not support
such a handoff. When probing a generic eDP panel, it powers the panel
on to read its EDID. If display pipeline binding takes longer than the
runtime-PM autosuspend delay, the panel is then powered off while the
backlight remains enabled.

On the Surface Pro 11 LCD (LGD0779), leaving BL_EN high across this
power cycle appears to leave the backlight controller in an incorrect
state: brightness is pinned near maximum with a greatly reduced
dimming range. Subsequent brightness changes update the PWM duty, but
do not restore it to normal. Cycling the backlight off and on at
unchanged brightness restores the full range.

The first drm_panel_enable() does not recover from this because
pwm-backlight still considers itself enabled and leaves BL_EN high.

Disable the backlight at probe, after acquiring it and before enabling
runtime PM. This clears the firmware's enabled state so the DRM panel
core turns the backlight on after panel power and video are ready at
the first modeset.

This also turns off the firmware display at probe on systems where it
previously remained lit until the first modeset.

Verified on the Surface Pro 11 LCD by delaying display pipeline bind
past the autosuspend timeout. BL_EN now drops at probe, before panel
runtime autosuspend, and brightness control works at the first modeset.

Fixes: 5540cf8f3e8d ("drm/panel-edp: Implement generic "edp-panel"s probed by EDID")
Link: https://github.com/dwhinham/archiso-aarch64-sp11/issues/41
Suggested-by: Douglas Anderson <dianders@chromium.org>
Assisted-by: LLM
Signed-off-by: Haipeng Lin <jimmie.lin@gmail.com>
---
Can reproduce on an installed system on Surface Pro 11 LCD (X1P-64-100,
LGD0779 LCD) by booting with modprobe.blacklist=phy_qcom_qmp_combo then
loading that module manually after ~20s. This delays DPU component bind
past the panel's runtime autosuspend timeout.

A/B tested against the same v7.2 tree:

- Unpatched: panel VDD off 3.5s..20.5s while BL_EN stays high.
After the first modeset brightness is pinned near max brightness with
a "collapsed" dimming range. sysfs brightness writes still reprogram
the PMIC LPG. One bl_power off/on cycle at unchanged brightness 
restores the full range.

- Patched v2: patch provides the same full brightness range on boot
(stalled or not) as the v1 patch. BL_EN drops at panel-edp probe,
~1s before VDD cut, rises ~0.5s after panel power at the first modeset.

Tracing and functional testing on the SP11 shows unchanged sequencing
for fast boots (without artificial delay), DPMS off/on, and system
suspend/resume.

Panels with shared/always-on supplies and no panel enable GPIO
may continue displaying the firmware framebuffer during the
runtime suspend before first modeset. With this change panel-edp
disables the backlight obtained through the backlight phandle at probe.
The DRM panel core enables the backlight again at the first modeset.
I have not tested this configuration.

Testing on other panel-edp systems particularly with pwm-backlight,
would be appreciated.
---
Changes in v2:
- Disables the backlight once at probe instead of
  in panel_edp_suspend() following Doug Anderson's suggestion.
- Only disable the backlight obtained through the backlight phandle.
  The driver's AUX backlight setup is untouched.
- Link to v1: https://lore.kernel.org/r/20261024-sp11-bl-upstream-1-v1-1-d39bfaf9afbc@gmail.com
---
 drivers/gpu/drm/panel/panel-edp.c | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/drivers/gpu/drm/panel/panel-edp.c b/drivers/gpu/drm/panel/panel-edp.c
index 94bc54c3833a..d019f4165674 100644
--- a/drivers/gpu/drm/panel/panel-edp.c
+++ b/drivers/gpu/drm/panel/panel-edp.c
@@ -21,6 +21,7 @@
  * DEALINGS IN THE SOFTWARE.
  */
 
+#include <linux/backlight.h>
 #include <linux/debugfs.h>
 #include <linux/delay.h>
 #include <linux/gpio/consumer.h>
@@ -918,6 +919,16 @@ static int panel_edp_probe(struct device *dev, const struct panel_desc *desc,
 	if (err)
 		return err;
 
+	/*
+	 * Backlight drivers may preserve the state left by firmware,
+	 * but panel-edp does not support seamless handoff.
+	 * Runtime PM may power off the panel before the first modeset,
+	 * leaving the backlight on.
+	 * Disable it here so the DRM panel core enables it in the correct
+	 * order at the first modeset.
+	 */
+	backlight_disable(panel->base.backlight);
+
 	/*
 	 * We use runtime PM for prepare / unprepare since those power the panel
 	 * on and off and those can be very slow operations. This is important

---
base-commit: cf61bef3801c3c9d0d8c39026b7b2fb242898a3a
change-id: 20261024-sp11-bl-upstream-1-e6616a68d6f0

Best regards,
-- 
Haipeng Lin <jimmie.lin@gmail.com>

