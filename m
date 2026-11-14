From: Alexis Calin <alexiscalin@protonmail.com>
Date: Sat, 14 Nov 2026 16:06:32 +0100
Subject: [PATCH] drm/i915/backlight: Keep ACPI brightness requests while
 the display is off
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-i915-acpi-backlight-display-off-v1-1-9306f19d605a@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2NSwqEMBAFryK9tsH2B85VBhcxdvShaEiGQRHvb
 nBZUFRdFDVAI32yi4L+EbFvCSTPyM5mm5QxJqayKFsRqRmdNGysBw/GLium+ccjol/Nybtz3Fq
 pNIlD0TlKFR/U4XgP3/6+H987PfFxAAAA
X-Change-ID: 20261114-i915-acpi-backlight-display-off-6c13e114b09f
To: intel-gfx@lists.freedesktop.org, 
 Jani Nikula <jani.nikula@linux.intel.com>, 
 Rodrigo Vivi <rodrigo.vivi@intel.com>, 
 Joonas Lahtinen <joonas.lahtinen@linux.intel.com>, 
 Tvrtko Ursulin <tursulin@ursulin.net>
Cc: David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Jesse Barnes <jbarnes@virtuousgeek.org>, intel-xe@lists.freedesktop.org, 
 dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Alexis Calin <alexiscalin@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794668829; l=3928;
 i=alexiscalin@protonmail.com; s=20261114; h=from:subject:message-id;
 bh=yfV5siqoHW/ZsYrHAiTnfqWhV+mA/En7svlIUOMAlGQ=;
 b=R1pN8mDR1lCIq9lN2N09YjigxDNNUkgL6X2/m8UmvRxMuUpITR3BCsjacT8gMmKWXYeQ58TYV
 1gUs380NXXdD9iVWIbXJql5Qj7Q4QQsDbVEW87+PetIbKG0a/+6M/eN
X-Developer-Key: i=alexiscalin@protonmail.com; a=ed25519;
 pk=oNYBG1X8+3bGmJMn0tnt+BbJC1vI7dgqomx4pGPM+4c=
X-Endpoint-Received: by B4 Relay for alexiscalin@protonmail.com/20261114 with auth_id=1528
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

intel_backlight_set_acpi() returns early when the connector has no
crtc. This is meant for requests that the BIOS sends during driver init,
but the connector also has no crtc while the display is turned off, e.g.
when the desktop blanks the screen. A brightness request received then
is dropped, while asle_set_backlight() still reports it as done in CBLV.
When the display is turned on again, the backlight is enabled with the
old level.

With the ACPI video backlight interface, this happens on the GNOME idle
path: the screen is dimmed, then blanked, and on wake-up GNOME restores
the previous level while the display is still off. The panel then comes
back at the dimmed level, while the backlight class device and CBLV
report the restored one.

The crtc is only needed to program the hardware, as vlv_set_backlight()
gets the pipe from it. Store the new level in all cases, like
intel_panel_set_backlight() does for the native backlight interface, and
only program it when the backlight is enabled and there is a crtc. The
next backlight enable then uses the new level.

Fixes: 752aa88a1e78 ("drm/i915: make backlight functions take a connector")
Assisted-by: LLM
Signed-off-by: Alexis Calin <alexiscalin@protonmail.com>
---
Tested on a ThinkPad T480s (Kaby Lake-R) with coreboot firmware, which
makes Linux use the ACPI video backlight. With the display turned off
through Mutter's PowerSaveMode, a level written to acpi_video0 is
reported in CBLV, but without this patch the panel comes back at the
previous level (40 instead of 75 on 6.12.117). With this patch on
drm-tip, it comes back at the new level (75). The GNOME idle path was
also tested: after the idle dim (31) and blank, wake-up now restores the
level (74) instead of staying at 31. Brightness changes with the display
on and S3 suspend/resume behave as before. Not tested on VLV/CHV, where
programming the level needs the crtc.

checkpatch.pl in drm-tip reports the Assisted-by tag, as it predates
commit 816d9992d9ed ("coding-assistants: simplify attribution").
---
 drivers/gpu/drm/i915/display/intel_backlight.c | 18 ++++++++++--------
 1 file changed, 10 insertions(+), 8 deletions(-)

diff --git a/drivers/gpu/drm/i915/display/intel_backlight.c b/drivers/gpu/drm/i915/display/intel_backlight.c
index b128896cb1c2..3f2c75b249ed 100644
--- a/drivers/gpu/drm/i915/display/intel_backlight.c
+++ b/drivers/gpu/drm/i915/display/intel_backlight.c
@@ -310,13 +310,7 @@ void intel_backlight_set_acpi(const struct drm_connector_state *conn_state,
 	struct intel_panel *panel = &connector->panel;
 	u32 hw_level;
 
-	/*
-	 * Lack of crtc may occur during driver init because
-	 * connection_mutex isn't held across the entire backlight
-	 * setup + modeset readout, and the BIOS can issue the
-	 * requests at any time.
-	 */
-	if (!panel->backlight.present || !conn_state->crtc)
+	if (!panel->backlight.present)
 		return;
 
 	mutex_lock(&display->backlight.lock);
@@ -332,7 +326,15 @@ void intel_backlight_set_acpi(const struct drm_connector_state *conn_state,
 					 panel->backlight.level,
 					 panel->backlight.device->props.max_brightness);
 
-	if (panel->backlight.enabled)
+	/*
+	 * Lack of crtc may occur during driver init because
+	 * connection_mutex isn't held across the entire backlight
+	 * setup + modeset readout, and the BIOS can issue the
+	 * requests at any time. There is no crtc either while the
+	 * display is off. Keep the new level for the next backlight
+	 * enable, but only program it with a crtc.
+	 */
+	if (panel->backlight.enabled && conn_state->crtc)
 		intel_panel_actually_set_backlight(conn_state, hw_level);
 
 	mutex_unlock(&display->backlight.lock);

---
base-commit: 419bb0e4cadd214a0847010c02ade95e5fc511f7
change-id: 20261114-i915-acpi-backlight-display-off-6c13e114b09f

Best regards,
-- 
Alexis Calin <alexiscalin@protonmail.com>

