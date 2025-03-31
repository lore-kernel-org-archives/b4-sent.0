From: Mark Dietzer <git@doridian.net>
Date: Mon, 31 Mar 2025 10:03:33 -0700
Subject: [PATCH v3] drm: panel-backlight-quirks: Add Framework 16 panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250331-framework16-drm-quirks-v3-1-7fd29770a918@doridian.net>
X-B4-Tracking: v=1; b=H4sIAOXK6mcC/4WOQW7DIBBFrxKx7lhAbAxd5R5VFgSGepRi3MF1W
 0W+e4kv0M2X3uI/vYeoyIRVvJ4egnGjSmVucH45iTD5+R2BYmOhpR6k1hYS+4zfhe/KQOQMn1/
 E9wpjfxtslHI8WyPaeWFM9HOI366NE5cM68ToD50KzlilEPo49NBb6eEWpGsTtXMOLRpz8cvSJ
 V/X7OmjCyU/vRPVtfDv0bvpp/3ftE2DgjAmn6xJA7p4iYUpkp+7GVdx3ff9D8XlE+8HAQAA
X-Change-ID: 20250228-framework16-drm-quirks-74b58d007386
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Mark Dietzer <git@doridian.net>, 
 =?utf-8?q?Thomas_Wei=C3=9Fschuh?= <linux@weissschuh.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1743440617; l=1963;
 i=git@doridian.net; s=20250228; h=from:subject:message-id;
 bh=ZU/61npGl+rwUoUEE7wnye9HmuwhwaVSQG0fvTUZY9k=;
 b=8cNITSsSusv0HSWzqGUPM3xOgLyl5BeDJyoHuVZMAJik6fSOLLTq4zTFDMXsj5MLfJEtXbeZE
 3n6etJtw7WbAPeF+zTDTX6GnDHDArlR3+lK58lLwozmr4tSAg296RSn
X-Developer-Key: i=git@doridian.net; a=ed25519;
 pk=XY9bZ7EBhoLNoRt6zd2/vutpAXC3tsX6OytpZHjbUsQ=
X-Endpoint-Received: by B4 Relay for git@doridian.net/20250228 with auth_id=353
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Similarly for the Framework 13 panels already handled in those quirks,
the 16 can be helped by the same kind of patch.

I have run this on my own 16 for multiple months (hard coding the value to
0 before the quirks made it upstream) and it has resulted in a darker
minimum brightness (as expected) and no issues.

The Framework community threads between the 13 and 16 for this improvement
are the same one, so user reports in the link below will be mixed and
likely more focused on the 13.

Link: https://community.frame.work/t/solved-even-lower-screen-brightness/25711/60

Signed-off-by: Mark Dietzer <git@doridian.net>
Reviewed-by: Thomas Weißschuh <linux@weissschuh.net>
---
Changes in v3:
- Fix the EDID, first submission was incorrect
- Link to v2: https://lore.kernel.org/r/20250228-framework16-drm-quirks-v2-1-c7faf86f5e9d@doridian.net
---
 drivers/gpu/drm/drm_panel_backlight_quirks.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/gpu/drm/drm_panel_backlight_quirks.c b/drivers/gpu/drm/drm_panel_backlight_quirks.c
index c477d98ade2b41314d4218281ced7d3c4d087769..1370fd02f0e0667ef8ec76839d415092102e02c8 100644
--- a/drivers/gpu/drm/drm_panel_backlight_quirks.c
+++ b/drivers/gpu/drm/drm_panel_backlight_quirks.c
@@ -41,6 +41,14 @@ static const struct drm_panel_min_backlight_quirk drm_panel_min_backlight_quirks
 		.ident.name = "NE135A1M-NY1",
 		.min_brightness = 0,
 	},
+	/* 16 inch panel */
+	{
+		.dmi_match.field = DMI_BOARD_VENDOR,
+		.dmi_match.value = "Framework",
+		.ident.panel_id = drm_edid_encode_panel_id('B', 'O', 'E', 0x0bc9),
+		.ident.name = "NE160QDM-NZ6",
+		.min_brightness = 0,
+	},
 };
 
 static bool drm_panel_min_backlight_quirk_matches(const struct drm_panel_min_backlight_quirk *quirk,

---
base-commit: 76544811c850a1f4c055aa182b513b7a843868ea
change-id: 20250228-framework16-drm-quirks-74b58d007386

Best regards,
-- 
Mark Dietzer <git@doridian.net>

