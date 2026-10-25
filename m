From: Haipeng Lin <jimmie.lin@gmail.com>
Date: Sat, 24 Oct 2026 20:24:00 -0400
Subject: [PATCH] drm/panel-edp: disable the backlight before powering off
 panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261024-sp11-bl-upstream-1-v1-1-d39bfaf9afbc@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAyMT3eICQ0PdpBzd0oLikqLUxFxdQ91UMzNDs0QzixSzNAMloMaCotS
 0zAqwodGxtbUA0eaJsWQAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792887854; l=4817;
 i=jimmie.lin@gmail.com; s=20261011; h=from:subject:message-id;
 bh=Ad1iSx6+Lkqh9DkZeY8irIQ3hUZslhOvNah24ewp07A=;
 b=PogfgUqfM2SzGF0yLihQqRwvLshIXA7c0iqTKAbXu3RzurqjhsnfnnS2SZ8SfVxRdSC7DzfEd
 V7qdqNst1DzCD3vex6ve2i0T8eyEINM48JC+gywDQmJOuwrHr9yr7ve
X-Developer-Key: i=jimmie.lin@gmail.com; a=ed25519;
 pk=3KDRF1RQ/9A7ZUVTdRVEZnVrGltdmq1bRocsOYeXezI=
X-Endpoint-Received: by B4 Relay for jimmie.lin@gmail.com/20261011 with auth_id=1164
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If the display pipeline takes longer than the runtime-PM autosuspend
delay (1 s) to bind after the panel probes, panel-edp's runtime suspend
powers the panel off while the backlight is still on: pwm-backlight
inherits the enable state left by the firmware at probe and keeps the
enable GPIO high. The panel supply is thus cut without first disabling
the backlight, leaving BL_EN asserted across a panel power cycle.

On the Surface Pro 11 LCD (LGD0779), leaving BL_EN high across this
power cycle appears to leave the backlight controller in an incorrect
state: brightness is pinned near maximum with a greatly reduced
dimming range. Subsequent brightness changes update the PWM duty, but
do not restore it to normal. Cycling the backlight off and on at
unchanged brightness restores the full range.

The first drm_panel_enable() does not recover from this because
pwm-backlight still considers itself enabled and leaves BL_EN high.

Disable the attached backlight in panel_edp_suspend() before marking
AUX unpowered and cutting panel power. This ensures that the first
modeset enables the backlight after panel power and video are ready.
When DRM has already disabled the backlight, it remains off.

Verified on the Surface Pro 11 LCD by delaying display pipeline bind
past the autosuspend timeout. BL_EN now drops before panel power is
cut, and brightness control works at the first modeset.

Fixes: 5540cf8f3e8d ("drm/panel-edp: Implement generic "edp-panel"s probed by EDID")
Link: https://github.com/dwhinham/archiso-aarch64-sp11/issues/41
Assisted-by: claude-fable:5
Signed-off-by: Haipeng Lin <jimmie.lin@gmail.com>
---
Can reproduce on an installed system on Surface Pro 11 LCD (X1P-64-100,
LGD0779 LCD) by booting with modprobe.blacklist=phy_qcom_qmp_combo then
loading that module manually after ~20s. This delays DPU component bind
past the panel's runtime autosuspend timeout.

A/B tested against the same v7.2 tree:

- Unpatched: panel VDD off 3.5s..20.5s while BL_EN stays high.
after the first modeset brightness is pinned near max brightness with
a "collapsed" dimming range. sysfs brightness writes still reprogram
the PMIC LPG. One bl_power off/on cycle at unchanged brightness 
restores the full range.

- Patched: BL_EN drops ~300us before the VDD cut and rises again after
panel power+link at the first modeset. full brightness range works.

Tracing and functional testing on the SP11 shows unchanged sequencing
for fast boots, DPMS off/on, and system suspend/resume.

Two cases would benefit from testing on other hardware:
1. AUX-controlled backlights
The disable is placed before drm_dp_dpcd_set_powered(false) and
regulator_disable() so the panel remains accessible if disabling its
backlight requires AUX writes. But I have not tested this since my 
LCD is GPIO/PWM based.

2. Panels with shared/always-on supplies and no panel enable GPIO
These panels may continue displaying the firmware framebuffer during
the pre-first-modeset runtime suspend. This change will turn off their
attached backlight during that interval, potentially making the boot
display go dark earlier. This matches the driver's powered-off state,
but I have not tested that configuration.

Testing on other panel-edp systems particularly with pwm-backlight,
would be appreciated.
---
 drivers/gpu/drm/panel/panel-edp.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/drivers/gpu/drm/panel/panel-edp.c b/drivers/gpu/drm/panel/panel-edp.c
index 94bc54c3833a..87f9c13380be 100644
--- a/drivers/gpu/drm/panel/panel-edp.c
+++ b/drivers/gpu/drm/panel/panel-edp.c
@@ -21,6 +21,7 @@
  * DEALINGS IN THE SOFTWARE.
  */
 
+#include <linux/backlight.h>
 #include <linux/debugfs.h>
 #include <linux/delay.h>
 #include <linux/gpio/consumer.h>
@@ -413,6 +414,18 @@ static int panel_edp_suspend(struct device *dev)
 {
 	struct panel_edp *p = dev_get_drvdata(dev);
 
+	/*
+	 * eDP panel power sequencing requires the backlight to be off
+	 * whenever the panel is powered off. Before the first modeset the
+	 * backlight driver may still hold the enable state inherited from
+	 * the firmware, and some panels' backlight controllers come up in a
+	 * wrong dimming mode if their enable line stays high across a panel
+	 * power cycle. Sync the backlight off here so that the backlight
+	 * enable from drm_panel_enable() performs a true power-on in the
+	 * correct order.
+	 */
+	backlight_disable(p->base.backlight);
+
 	drm_dp_dpcd_set_powered(p->aux, false);
 	gpiod_set_value_cansleep(p->enable_gpio, 0);
 	regulator_disable(p->supply);

---
base-commit: cf61bef3801c3c9d0d8c39026b7b2fb242898a3a
change-id: 20261024-sp11-bl-upstream-1-e6616a68d6f0

Best regards,
-- 
Haipeng Lin <jimmie.lin@gmail.com>

