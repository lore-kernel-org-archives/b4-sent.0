From: Brett Mastbergen <brett.mastbergen@gmail.com>
Date: Tue, 16 Sep 2025 14:24:54 -0400
Subject: [PATCH] drm: panel-orientation-quirks: Add quirk for Chuwi
 MiniBook X
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250916-chuwi-panel-quirk-v1-1-ec5c6aa5a663@gmail.com>
X-B4-Tracking: v=1; b=H4sIAHWryWgC/2XNQQqDMBCF4avIrDugQUV7FekiiRMzKKlOsBXEu
 xvduvzhfbwdIglThHe2g9CPI39DiuKVgfU6DITcpwaVqypvixqtX/+Msw404bKyjOjKxpWqqVp
 je0jO6EhoRAfrL/kA12YWcrzdv93nOE4znA24hwAAAA==
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Brett Mastbergen <brett.mastbergen@gmail.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758047099; l=1282;
 i=brett.mastbergen@gmail.com; s=20250916; h=from:subject:message-id;
 bh=hjeEkEZrq81jIeV1Zh4tI40Z7QvRSV1nwJznGMlUFzg=;
 b=P+80FJjJ5/Fu5amObDeSy9W/HX8DmfuYaF/n3NtyHrXQyU+frsUt2EiXWQD08UUHrE+v8YGlJ
 ynhiqLdQZZzALoZDTeM299z5wQNU6PFofeIB5bMSFLCNpjg/9WdrqzP
X-Developer-Key: i=brett.mastbergen@gmail.com; a=ed25519;
 pk=KMdTG5jy0i293GjuHrtMAg0aedFD0HL3VOJ6hZ3YJAA=
X-Endpoint-Received: by B4 Relay for brett.mastbergen@gmail.com/20250916 with auth_id=525
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This adds a DMI orientation quirk for the Chuwi MiniBook X which
has a display mounted 90 degrees rotated.

Signed-off-by: Brett Mastbergen <brett.mastbergen@gmail.com>
---
 drivers/gpu/drm/drm_panel_orientation_quirks.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/gpu/drm/drm_panel_orientation_quirks.c b/drivers/gpu/drm/drm_panel_orientation_quirks.c
index 3a218fb592ce..70fc2eb292ff 100644
--- a/drivers/gpu/drm/drm_panel_orientation_quirks.c
+++ b/drivers/gpu/drm/drm_panel_orientation_quirks.c
@@ -283,6 +283,13 @@ static const struct dmi_system_id orientation_data[] = {
 		  DMI_EXACT_MATCH(DMI_PRODUCT_NAME, "Hi10 pro tablet"),
 		},
 		.driver_data = (void *)&lcd1200x1920_rightside_up,
+	}, {	/* Chuwi MiniBook X */
+		.matches = {
+		  DMI_EXACT_MATCH(DMI_SYS_VENDOR,
+				  "CHUWI Innovation And Technology(ShenZhen)co.,Ltd"),
+		  DMI_EXACT_MATCH(DMI_PRODUCT_NAME, "MiniBook X"),
+		},
+		.driver_data = (void *)&lcd1200x1920_rightside_up,
 	}, {	/* Dynabook K50 */
 		.matches = {
 		  DMI_EXACT_MATCH(DMI_SYS_VENDOR, "Dynabook Inc."),

---
base-commit: 46a51f4f5edade43ba66b3c151f0e25ec8b69cb6
change-id: 20250916-chuwi-panel-quirk-f48f42859bcd

Best regards,
-- 
Brett Mastbergen <brett.mastbergen@gmail.com>

