From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 27 Jul 2026 19:44:25 -0500
Subject: [PATCH] drm/panel: chipwealth-ch13726a: Fix washed out colors on
 120hz mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260727-ch13726a-washout-v1-1-bf869ddfc5cf@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MTQqAIBBA4avIrBPSSqOrRAurMWejof2BdPek5
 bd4L0PCSJhgYBkiXpQo+AJRMVic8RtyWotB1lLVWmq+ONFoqQy/TXLhPHjXou2tUd2MCkq2R7T
 0/Mtxet8PXhZZYGIAAAA=
X-Change-ID: 20260727-ch13726a-washout-54ef8fa65be6
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785199475; l=2151;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=g/5SbkmC5RAHR0XS4bGD1LzSsL/iHrUXQcUx6GYaBS4=;
 b=zqizgOxduvcvgbyRXHN36jqHklor2L3TpekQi18GYWn2Cs5sPkdQlY5+wC/MaGFyK63E0/GNv
 oq9kehJydQ/BlL1dnaDEPQMWRHjCzTMkhz9oWzb1ROz95akgdX7MSow
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The issue was determined to be two-fold:

1. The non-continuous clock dropping into LPM during blanks causes
   voltage drift at 120hz enough to affect the gamma curve.

2. The agressive horizontal blanking width did not allow enough settle
   time, further compounding the voltage drift.

In addition to switching to continuous clock, burst mode is also enabled
to further stabilize the blank intervals.

Assisted-by: Gemini:2.5-Pro
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
For the initial submission, the washed out colors were expected to need
to be fixed by a color profile. However, further investigation showed
there was a problem with the timings.
---
 drivers/gpu/drm/panel/panel-chipwealth-ch13726a.c | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-chipwealth-ch13726a.c b/drivers/gpu/drm/panel/panel-chipwealth-ch13726a.c
index 562dc573528dd..92f0c4f1587cb 100644
--- a/drivers/gpu/drm/panel/panel-chipwealth-ch13726a.c
+++ b/drivers/gpu/drm/panel/panel-chipwealth-ch13726a.c
@@ -128,11 +128,11 @@ static int ch13726a_unprepare(struct drm_panel *panel)
 static const struct drm_display_mode thor_bottom_modes[] = {
 	{
 		/* 120Hz */
-		.clock = (1080 + 28 + 4 + 36) * (1240 + 16 + 4 + 8) * 120 / 1000,
+		.clock = (1080 + 60 + 8 + 60) * (1240 + 16 + 4 + 8) * 120 / 1000,
 		.hdisplay = 1080,
-		.hsync_start = 1080 + 28,
-		.hsync_end = 1080 + 28 + 4,
-		.htotal = 1080 + 28 + 4 + 36,
+		.hsync_start = 1080 + 60,
+		.hsync_end = 1080 + 28 + 8,
+		.htotal = 1080 + 28 + 4 + 60,
 		.vdisplay = 1240,
 		.vsync_start = 1240 + 16,
 		.vsync_end = 1240 + 16 + 4,
@@ -281,7 +281,7 @@ static int ch13726a_probe(struct mipi_dsi_device *dsi)
 	dsi->lanes = 4;
 	dsi->format = MIPI_DSI_FMT_RGB888;
 	dsi->mode_flags = MIPI_DSI_MODE_VIDEO |
-			  MIPI_DSI_CLOCK_NON_CONTINUOUS;
+			  MIPI_DSI_MODE_VIDEO_BURST;
 
 	ctx->panel.prepare_prev_first = true;
 

---
base-commit: 0d33d21e47d9dc66f91e44da3fc9220c74d93df7
change-id: 20260727-ch13726a-washout-54ef8fa65be6

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

