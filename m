From: Kylie C <kyliepc@proton.me>
Date: Wed, 25 Nov 2026 07:38:29 -0500
Subject: [PATCH] drm/fbdev-client: Don't restore while fbcon isn't bound
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-fbdev-no-early-restore-v1-1-f81dc7acf3ad@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQrCMBBG4auUWTtgQlPRq4iLpvmrI5LITFuU0
 rsbdfkt3lvJoAKjU7OSYhGTkivcrqHh1ucrWFI1+b3vnPOBx5iwcC6MXh9vVthUFJwOrg1tAOK
 xoxo/FaO8fuPz5W+b4x3D9L3Rtn0AljY7xHoAAAA=
X-Change-ID: 20261125-fbdev-no-early-restore-d714545eeb96
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Kylie C <kyliepc@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795610315; l=1165;
 i=kyliepc@proton.me; s=20261022; h=from:subject:message-id;
 bh=2N+1pHpr6q4BPQmblStjA3/pJkTxrz1YV0M42dq9rME=;
 b=+w3aqPeBetmqfZ1x45FXHC4bGkF8NiQGgsL+Lm9O5wJAcxwluT9qHEz5JW1ulNKXSTl+D5pq+
 e/403IBKrbwC1BZx3Po3y0h8tKqko9wgniubf3B3Qs8lmp4u4/ShY3j
X-Developer-Key: i=kyliepc@proton.me; a=ed25519;
 pk=T/yRT5OdlaWnEmvYU6894i5NEH44SmsyRlMNTde5DDs=
X-Endpoint-Received: by B4 Relay for kyliepc@proton.me/20261022 with auth_id=1285
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With deferred console takeover, fbcon hasn't bound to
that framebuffer yet, so there is no console to bring back. Restoring
it only replaces what the last DRM client left on screen, with an empty
framebuffer breaking flicker-free boot.

Only restore on lastclose once fbcon has bound to the framebuffer.

Signed-off-by: Kylie C <kyliepc@proton.me>
---
 drivers/gpu/drm/clients/drm_fbdev_client.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/gpu/drm/clients/drm_fbdev_client.c b/drivers/gpu/drm/clients/drm_fbdev_client.c
index eec463d19943..7981d613e652 100644
--- a/drivers/gpu/drm/clients/drm_fbdev_client.c
+++ b/drivers/gpu/drm/clients/drm_fbdev_client.c
@@ -50,6 +50,9 @@ static int drm_fbdev_client_restore(struct drm_client_dev *client, bool force)
 	if (!fb_helper->info || !fb_helper->fb)
 		return 0;
 
+	if (!force && !fb_helper->info->fbcon_par)
+		return 0;
+
 	drm_fb_helper_restore_fbdev_mode_unlocked(fb_helper, force);
 
 	return 0;

---
base-commit: a2853fd7f6217573dfb780809663683d5b9c5835
change-id: 20261125-fbdev-no-early-restore-d714545eeb96

Best regards,
--  
Kylie C <kyliepc@proton.me>

