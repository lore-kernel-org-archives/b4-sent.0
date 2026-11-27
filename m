From: Ani Aggarwal <antiani100@gmail.com>
Date: Fri, 27 Nov 2026 10:21:52 -0800
Subject: [PATCH] drm/i915/psr: Add quirk to ignore PSR setup time on Dell
 XPS 15 9520
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-xps9520-psr-setup-time-v1-1-692c17859301@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQ6CQAxFr0K6tpGpYKJXMS6YoUCNDJN2MCSEu
 wu6fD//vRWMVdjgXqyg/BGTKe7gTgWEoYk9o7Q7A5V0dY4qXJLdaioxmaJxnhNmGRkDVe2ldhQ
 68rDLSbmT5Rd+PP9ss39xyEftePjGGL02MQzHNKn0Es+tjigx8xsjLxm27Qum12K/ogAAAA==
X-Change-ID: 20261124-xps9520-psr-setup-time-c24d3512cf2b
To: intel-gfx@lists.freedesktop.org, intel-xe@lists.freedesktop.org
Cc: Jani Nikula <jani.nikula@linux.intel.com>, 
 =?utf-8?q?Jouni_H=C3=B6gander?= <jouni.hogander@intel.com>, 
 Rodrigo Vivi <rodrigo.vivi@intel.com>, stable@vger.kernel.org, 
 Ani Aggarwal <antiani100@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795803721; l=4349;
 i=antiani100@gmail.com; s=20261125; h=from:subject:message-id;
 bh=318c4BOjroDNrkIKKte4IuzP8nHEwhcDbXg4u+A0OqA=;
 b=kke/ZkF1cQ+rI/ACJJ74rhj0beBUuKU0hWmQSckrVUM/VjiyuIVg2l/HwJXBAy/LKaNVtH5Xt
 bLBST0JCmlMDzOvTwEhm/PxeyXF4eMthSxW+/r6mphGGJ1Zh+C76PMI
X-Developer-Key: i=antiani100@gmail.com; a=ed25519;
 pk=lKco5sHiv9Mkqd7wU58OKQWw9dm6Hv4Pe7jGlp3eSsw=
X-Endpoint-Received: by B4 Relay for antiani100@gmail.com/20261125 with auth_id=1668
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Samsung OLED panel (EDID SDC 0x414d, sink OUI ba:41:59) in the
Dell XPS 15 9520 reports a PSR setup time of 330 us: DPCD 0x071 bits
3:1 are 000b, the default encoding. Its only mode, 3456x2160@60 with a
528.19 MHz pixel clock, htotal 4016 and vtotal 2192, has a 32 line
vertical blank of about 243 us. intel_psr_entry_setup_frames()
therefore rejects PSR on this display version 13 (ADL-P) platform:

  PSR condition failed: PSR setup time (330 us) too long

so the panel never gets PSR, DC5/DC6 are never entered and the package
does not go below PC3 with the panel on.

Forcing the check to pass (a 220 us setup time, which fits the vblank)
lets PSR1 enable. The sink enters self refresh on a static screen, no
PSR aux or sink errors were seen, and idle package C-state residency
moves from PC2/PC3 to PC6 and PC8.

Before display version 20 the setup time is only compared with the
vblank length and is not programmed into the hardware, so add a DPCD
quirk for this machine and panel that skips the check.

Closes: https://gitlab.freedesktop.org/drm/i915/kernel/-/issues/17943
Cc: stable@vger.kernel.org
Signed-off-by: Ani Aggarwal <antiani100@gmail.com>
---
Tested on 6.18.64 with this backported; build-tested with W=1 on
drm-intel-next.

This is my first patch, please let me know if I need to change anything!
---
 drivers/gpu/drm/i915/display/intel_psr.c    |  9 +++++++++
 drivers/gpu/drm/i915/display/intel_quirks.c | 16 ++++++++++++++++
 drivers/gpu/drm/i915/display/intel_quirks.h |  1 +
 3 files changed, 26 insertions(+)

diff --git a/drivers/gpu/drm/i915/display/intel_psr.c b/drivers/gpu/drm/i915/display/intel_psr.c
index 438cb1502..5a7a35bfb 100644
--- a/drivers/gpu/drm/i915/display/intel_psr.c
+++ b/drivers/gpu/drm/i915/display/intel_psr.c
@@ -1347,6 +1347,15 @@ static int intel_psr_entry_setup_frames(struct intel_dp *intel_dp,
 		return -ETIME;
 	}
 
+	/*
+	 * Before display version 20 the setup time is only checked against
+	 * the vblank length, never programmed, so a quirk can skip the check
+	 * for panels that report a setup time they don't need.
+	 */
+	if (DISPLAY_VER(display) < 20 &&
+	    intel_has_dpcd_quirk(intel_dp, QUIRK_IGNORE_PSR_SETUP_TIME))
+		return 0;
+
 	if (intel_usecs_to_scanlines(adjusted_mode, psr_setup_time) >
 	    adjusted_mode->crtc_vtotal - adjusted_mode->crtc_vdisplay - 1) {
 		if (DISPLAY_VER(display) >= 20) {
diff --git a/drivers/gpu/drm/i915/display/intel_quirks.c b/drivers/gpu/drm/i915/display/intel_quirks.c
index ec3a79c87..cce29a9b6 100644
--- a/drivers/gpu/drm/i915/display/intel_quirks.c
+++ b/drivers/gpu/drm/i915/display/intel_quirks.c
@@ -94,6 +94,14 @@ static void quirk_disable_edp_panel_replay(struct intel_dp *intel_dp)
 	drm_info(display->drm, "Applying disable Panel Replay quirk\n");
 }
 
+static void quirk_ignore_psr_setup_time(struct intel_dp *intel_dp)
+{
+	struct intel_display *display = to_intel_display(intel_dp);
+
+	intel_set_dpcd_quirk(intel_dp, QUIRK_IGNORE_PSR_SETUP_TIME);
+	drm_info(display->drm, "Applying ignore PSR setup time quirk\n");
+}
+
 static void quirk_disable_psr2(struct intel_display *display)
 {
 	intel_set_quirk(display, QUIRK_DISABLE_PSR2);
@@ -303,6 +311,14 @@ static const struct intel_dpcd_quirk intel_dpcd_quirks[] = {
 		.sink_oui = SINK_OUI(0x00, 0x22, 0xb9),
 		.hook = quirk_disable_edp_panel_replay,
 	},
+	/* Dell XPS 15 9520 with the 3.5K OLED panel */
+	{
+		.device = 0x46a6,
+		.subsystem_vendor = 0x1028,
+		.subsystem_device = 0x0b19,
+		.sink_oui = SINK_OUI(0xba, 0x41, 0x59),
+		.hook = quirk_ignore_psr_setup_time,
+	},
 	/* Dell XPS 16 DA16260 */
 	{
 		.device = DEVICE_ID_ANY,
diff --git a/drivers/gpu/drm/i915/display/intel_quirks.h b/drivers/gpu/drm/i915/display/intel_quirks.h
index c64d0fc39..1d05fd439 100644
--- a/drivers/gpu/drm/i915/display/intel_quirks.h
+++ b/drivers/gpu/drm/i915/display/intel_quirks.h
@@ -25,6 +25,7 @@ enum intel_quirk_id {
 	QUIRK_DISABLE_PSR2,
 	QUIRK_ENABLE_DPCD_BACKLIGHT,
 	QUIRK_ALLOW_EDP_JOINER,
+	QUIRK_IGNORE_PSR_SETUP_TIME,
 };
 
 void intel_init_quirks(struct intel_display *display);

---
base-commit: accacc0e5e1f1446af365770e88d344b7786ac82
change-id: 20261124-xps9520-psr-setup-time-c24d3512cf2b

Best regards,
--  
Ani Aggarwal <antiani100@gmail.com>

