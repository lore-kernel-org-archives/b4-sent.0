From: Vasilij Markin <vasilij.kernel@tototo.si>
Date: Thu, 24 Sep 2026 21:25:13 +0200
Subject: [PATCH] drm/appletbdrm: Add suspend and resume support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260924-appletbdrm-pm-v1-1-0e5432132161@tototo.si>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDSyMT3cSCgpzUkqSUolzdglxds6QUIyMDYwvTpNQkJaCegqLUtMwKsHn
 RsbW1AO3TfuZfAAAA
X-Change-ID: 20260924-appletbdrm-pm-6bd220385beb
To: Aun-Ali Zaidi <admin@kodeit.net>, Aditya Garg <aditya.garg@linux.dev>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Kerem Karabay <kekrby@gmail.com>, Atharva Tiwari <evepolonium@gmail.com>, 
 Vasilij Markin <vasilij.kernel@tototo.si>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790277915; l=4094;
 i=vasilij.kernel@tototo.si; s=20260924; h=from:subject:message-id;
 bh=U9TR53zPKdFsJOhaemvo6rCzlInILyrXYml8JDZPnyk=;
 b=TDq3ZsRwuEwNu59ZQph4synn4jS5RIHLjQWWEEQ1iV6mWja7AsKaW1jcKVJ+sYZcGMgh+Yz6n
 0JnFJZZ07KXC3UPflQN1J5unSjpSBKv3EeENWVBxJgkMeJHQG2Io53J
X-Developer-Key: i=vasilij.kernel@tototo.si; a=ed25519;
 pk=GBDozjDEYjDf6fxRiVINxMYHaGbpq/11fq4B6pdR7Gs=
X-Endpoint-Received: by B4 Relay for vasilij.kernel@tototo.si/20260924 with auth_id=1057
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver has no USB power management callbacks, so the USB core
unbinds it before system suspend and binds it again on resume. The DRM
device is unregistered and registered again on every suspend and resume
cycle, userspace driving the Touch Bar through it (such as tiny-dfr)
loses its device, and the Touch Bar stays dark after resume.

Implement suspend and resume with drm_mode_config_helper_suspend() and
drm_mode_config_helper_resume(), so the device stays registered and the
last committed state is restored on resume. If the device was reset
while suspended, repeat the probe-time handshake first.

Fixes: 0670c2f56e45 ("drm/tiny: add driver for Apple Touch Bars in x86 Macs")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Vasilij Markin <vasilij.kernel@tototo.si>
---
Tested on a MacBookPro16,2 with this change backported to 7.2.7, deep (S3)
suspend by closing the lid, tiny-dfr 0.3.7. Without it the driver is probed
again on every resume and systemd stops tiny-dfr; with it tiny-dfr keeps
running, the driver is not probed again and the Touch Bar shows its content
right after resume. The reset_resume path is untested: the device never came
back reset.

Kernels before commit 3d95f93b30b8 ("drm/appletbdrm: Convert to atomic_create_state")
also need the plane reset hook to free the existing state, otherwise
drm_mode_config_reset() on resume hits WARN_ON(plane->state) in
appletbdrm_primary_plane_reset() and leaks the old state. 7.2.y is such a
kernel; the tested backport carries that change as a separate patch.

Built on drm-misc-next (c4c54ffd6) with W=1 without warnings.
---
 drivers/gpu/drm/tiny/appletbdrm.c | 43 +++++++++++++++++++++++++++++++++++++++
 1 file changed, 43 insertions(+)

diff --git a/drivers/gpu/drm/tiny/appletbdrm.c b/drivers/gpu/drm/tiny/appletbdrm.c
index 4297d9c11..024ad8bf6 100644
--- a/drivers/gpu/drm/tiny/appletbdrm.c
+++ b/drivers/gpu/drm/tiny/appletbdrm.c
@@ -30,6 +30,7 @@
 #include <drm/drm_gem_atomic_helper.h>
 #include <drm/drm_gem_framebuffer_helper.h>
 #include <drm/drm_gem_shmem_helper.h>
+#include <drm/drm_modeset_helper.h>
 #include <drm/drm_plane.h>
 #include <drm/drm_print.h>
 #include <drm/drm_probe_helper.h>
@@ -821,6 +822,45 @@ static void appletbdrm_shutdown(struct usb_interface *intf)
 	drm_atomic_helper_shutdown(&adev->drm);
 }
 
+static int appletbdrm_suspend(struct usb_interface *intf, pm_message_t message)
+{
+	struct appletbdrm_device *adev = usb_get_intfdata(intf);
+
+	return drm_mode_config_helper_suspend(&adev->drm);
+}
+
+static int appletbdrm_resume(struct usb_interface *intf)
+{
+	struct appletbdrm_device *adev = usb_get_intfdata(intf);
+
+	return drm_mode_config_helper_resume(&adev->drm);
+}
+
+static int appletbdrm_reset_resume(struct usb_interface *intf)
+{
+	struct appletbdrm_device *adev = usb_get_intfdata(intf);
+	struct drm_device *drm = &adev->drm;
+	int ret;
+
+	/*
+	 * A reset puts the device back into its initial state, where it
+	 * expects the same handshake as during probe
+	 */
+	ret = appletbdrm_get_information(adev);
+	if (ret) {
+		drm_err(drm, "Failed to get display information\n");
+		return ret;
+	}
+
+	ret = appletbdrm_signal_readiness(adev);
+	if (ret) {
+		drm_err(drm, "Failed to signal readiness\n");
+		return ret;
+	}
+
+	return drm_mode_config_helper_resume(drm);
+}
+
 static const struct usb_device_id appletbdrm_usb_id_table[] = {
 	{ USB_DEVICE_INTERFACE_CLASS(0x05ac, 0x8302, USB_CLASS_AUDIO_VIDEO) },
 	{}
@@ -832,6 +872,9 @@ static struct usb_driver appletbdrm_usb_driver = {
 	.probe		= appletbdrm_probe,
 	.disconnect	= appletbdrm_disconnect,
 	.shutdown	= appletbdrm_shutdown,
+	.suspend	= appletbdrm_suspend,
+	.resume		= appletbdrm_resume,
+	.reset_resume	= appletbdrm_reset_resume,
 	.id_table	= appletbdrm_usb_id_table,
 };
 module_usb_driver(appletbdrm_usb_driver);

---
base-commit: c4c54ffd65555ac5316f8faf4d7dc8c815877937
change-id: 20260924-appletbdrm-pm-6bd220385beb

Best regards,
-- 
Vasilij Markin <vasilij.kernel@tototo.si>

