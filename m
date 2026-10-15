From: Vasilij Markin <vasilij.kernel@tototo.si>
Date: Thu, 15 Oct 2026 23:47:36 +0200
Subject: [PATCH v3] drm/appletbdrm: Add suspend and resume support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-appletbdrm-pm-v3-1-47377176619a@tototo.si>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WMwQrCMBBEf6Xs2UiyaYN66n9ID41Z7YJtQxKCU
 vLvpr3LzOUNzNsgUmCKcGs2CJQ58rpU0KcGHtO4vEiwqwwo0cgrtmL0/k3JujALPwtjHaLUl86
 ShfrxgZ78OXz3ofLEMa3he+iz2td/pqyEEpK6VqOqNapP655zZBhKKT8aGqKFqgAAAA==
X-Change-ID: 20260924-appletbdrm-pm-6bd220385beb
To: Aun-Ali Zaidi <admin@kodeit.net>, Aditya Garg <aditya.garg@linux.dev>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: Lukas Wunner <lukas@wunner.de>, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, Kerem Karabay <kekrby@gmail.com>, 
 Atharva Tiwari <evepolonium@gmail.com>, 
 Atharva Tiwari <atharvatiwarilinuxdev@gmail.com>, 
 Vasilij Markin <vasilij.kernel@tototo.si>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792100875; l=5223;
 i=vasilij.kernel@tototo.si; s=20260924; h=from:subject:message-id;
 bh=5WU2l1yPzf1T2QcmJPYERBCb+bsgaXl69kOpDB1ET3A=;
 b=L8RuW0f7e5ePRHSayGYmLP0GmLimZrmKkQo03AWEkmKWav4xyzZw5ClUTpdEQy8NwefW8Xkk6
 ILAawydc6GHDHWmpMcpzAQqCV6wJBQ10HkOEaYlnoRffLUWIi0pYoaI
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
Tested on a MacBookPro16,2 with this change backported to the t2linux
7.2.11 kernel, deep (S3) suspend by closing the lid, tiny-dfr 0.3.7, 7
suspend/resume cycles. On this kernel the Touch Bar display is reset on
every resume ("usb 5-6: reset high-speed USB device number 7 using
t2bce_core"), so reset_resume runs each time: the driver is not probed
again, tiny-dfr keeps running and the Touch Bar shows its content right
after resume. Without reset_resume (v2) the same reset makes the USB core
unbind and probe the driver again, and the Touch Bar stays dark. The error
path in reset_resume is untested: the handshake never failed.

Kernels before commit 3d95f93b30b8 ("drm/appletbdrm: Convert to atomic_create_state")
also need the plane reset hook to free the existing state, otherwise
drm_mode_config_reset() on resume hits WARN_ON(plane->state) in
appletbdrm_primary_plane_reset() and leaks the old state. 7.2.y is such a
kernel; the tested backport carries that change as a separate patch.

Built on drm-misc-next (1c01801c3) with W=1 without warnings.
---
Changes in v3:
- Bring back reset_resume: v2 dropped it because the device was not reset
  on resume, but with the t2bce driver of the t2linux 7.2.11 kernel it is
  reset on every resume, and without reset_resume the driver is probed
  again (Sashiko review of v2).
- In reset_resume, call drm_mode_config_helper_resume() even if the probe
  handshake fails, so that the state saved on suspend is released
  (Sashiko review of v1).
- Rebase on current drm-misc-next.
- Link to v2: https://lore.kernel.org/all/586d0b39-40c8-4f3d-a786-c1085f87b858@linux.dev/

Changes in v2 (sent by Aditya Garg):
- Remove reset_resume.
- Link to v1: https://lore.kernel.org/r/20260924-appletbdrm-pm-v1-1-0e5432132161@tototo.si
---
 drivers/gpu/drm/tiny/appletbdrm.c | 46 +++++++++++++++++++++++++++++++++++++++
 1 file changed, 46 insertions(+)

diff --git a/drivers/gpu/drm/tiny/appletbdrm.c b/drivers/gpu/drm/tiny/appletbdrm.c
index 4297d9c11..350dc598c 100644
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
@@ -821,6 +822,48 @@ static void appletbdrm_shutdown(struct usb_interface *intf)
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
+	int ret, resume_ret;
+
+	/*
+	 * A reset puts the device back into its initial state, where it
+	 * expects the same handshake as during probe. Resume the DRM side
+	 * even if the handshake fails, so that the state saved on suspend
+	 * is released.
+	 */
+	ret = appletbdrm_get_information(adev);
+	if (ret) {
+		drm_err(drm, "Failed to get display information\n");
+		goto resume;
+	}
+
+	ret = appletbdrm_signal_readiness(adev);
+	if (ret)
+		drm_err(drm, "Failed to signal readiness\n");
+
+resume:
+	resume_ret = drm_mode_config_helper_resume(drm);
+
+	return ret ? ret : resume_ret;
+}
+
 static const struct usb_device_id appletbdrm_usb_id_table[] = {
 	{ USB_DEVICE_INTERFACE_CLASS(0x05ac, 0x8302, USB_CLASS_AUDIO_VIDEO) },
 	{}
@@ -832,6 +875,9 @@ static struct usb_driver appletbdrm_usb_driver = {
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
base-commit: 1c01801c393ef934286e19f03374999c858e6a20
change-id: 20260924-appletbdrm-pm-6bd220385beb

Best regards,
-- 
Vasilij Markin <vasilij.kernel@tototo.si>

