From: Adam Azuddin <azuddinadam@gmail.com>
Date: Sat, 26 Sep 2026 21:18:11 +0800
Subject: [PATCH] drm/appletbdrm: Fix incorrect error message on encoder
 attach failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260926-fix-err-msg-appletbdrm-v1-1-bb578a7dbdda@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM3QrCMAyG4VsZOV6gy7DY3YrsYD9ZjbhZkinC6
 L1b9fCB73sPMFZhg646QPklJo+toKkrmK7DFhllLgZy5F0gj4u8kVVxtYhDSnfex1lX9O3ZnxY
 KLQUH5ZyUy/IXvvR/23O88bR/a5DzByRmf756AAAA
X-Change-ID: 20260926-fix-err-msg-appletbdrm-63865f293290
To: Aun-Ali Zaidi <admin@kodeit.net>, Aditya Garg <aditya.garg@linux.dev>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Atharva Tiwari <evepolonium@gmail.com>, Kerem Karabay <kekrby@gmail.com>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Adam Azuddin <azuddinadam@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790428776; l=1145;
 i=azuddinadam@gmail.com; s=20260926; h=from:subject:message-id;
 bh=7QDII02ehFVK+b+s6cXociss9QRFT9PtnypaxLiG1UI=;
 b=eehGGRf63XYAZCL1BZESAk49qgPoTAXmb+GEmbTUA3+r2sU32mtzxtvdtOw8Bp4nZ8e4aw9Lh
 EJyO9ShXV9OAfCArGh8/VXYVtMMqSX6zCNh/AkOEaHxs/PpkpnZ31gN
X-Developer-Key: i=azuddinadam@gmail.com; a=ed25519;
 pk=ncFYTl3bFc1mmBvcpoYe65cGkYmui+zk5C3ufOQqR9s=
X-Endpoint-Received: by B4 Relay for azuddinadam@gmail.com/20260926 with auth_id=1066
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

drm_connector_attach_encoder() replaced an earlier call to
drm_simple_display_pipe_init() during review, but the error message
logged on failure was not updated to match and still refers to the
old call.

Fixes: 0670c2f56e45 ("drm/tiny: add driver for Apple Touch Bars in x86 Macs")
Signed-off-by: Adam Azuddin <azuddinadam@gmail.com>
---
 drivers/gpu/drm/tiny/appletbdrm.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/tiny/appletbdrm.c b/drivers/gpu/drm/tiny/appletbdrm.c
index 4297d9c1125e..91a51b513911 100644
--- a/drivers/gpu/drm/tiny/appletbdrm.c
+++ b/drivers/gpu/drm/tiny/appletbdrm.c
@@ -724,7 +724,7 @@ static int appletbdrm_setup_mode_config(struct appletbdrm_device *adev)
 	ret = drm_connector_attach_encoder(connector, encoder);
 
 	if (ret) {
-		drm_err(drm, "Failed to initialize simple display pipe\n");
+		drm_err(drm, "Failed to attach connector to encoder\n");
 		return ret;
 	}
 

---
base-commit: 98c7fc4219b93f953ee85c07fb6c8256046aba73
change-id: 20260926-fix-err-msg-appletbdrm-63865f293290

Best regards,
--  
Adam Azuddin <azuddinadam@gmail.com>

