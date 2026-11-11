From: Andreas Claesson <andreas@aclaesson.com>
Date: Wed, 11 Nov 2026 09:43:56 +0000
Subject: [PATCH] HID: corsair: cancel record LED work before unregistering
 on probe error
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-hid-corsair-k90-fail-sysfs-v1-1-cc4e94fce0d7@aclaesson.com>
X-B4-Tracking: v=1; b=H4sIANs49GoC/yXMwQ6CMAyA4VchPdukcFgYr2I8zK2TAgHTCtEQ3
 p2p/+27/DsYq7BBV+2gvInJMhfUlwpiH+YHo6RiaKhxdQl7SRgXtSCKoyfMQSa0j2VDIuczUeK
 WPJTBUznL+ze/3v629T5wfH2PcBwnPpnfCX4AAAA=
X-Change-ID: 20261111-hid-corsair-k90-fail-sysfs-0069f00de809
To: Benjamin Tissoires <bentiss@kernel.org>, Jiri Kosina <jikos@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-input@vger.kernel.org, 
 Chen Changcheng <chenchangcheng@kylinos.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794390235; l=3216;
 i=andreas@aclaesson.com; s=20261109; h=from:subject:message-id;
 bh=AfZsCSc4vmh8r8ztMc4LlA/iXXjDtYgcw7FLeTP0TZ4=;
 b=9TRUvPQX7pyab172758im1GSniVTTXNwFXUY+kR4//I1tsTRUSsizsTzoIqidibHKqdgNTBx5
 Hhrh7fPINr+DvjmezlBQQzSKmB/RVx52GIG4if+MHcrwcwcMMq77Mx4
X-Developer-Key: i=andreas@aclaesson.com; a=ed25519;
 pk=oC+38UX0rqcrEjNMgnKAF1zmrTUMbQ2aH/P5Z4TZOIQ=
X-Endpoint-Received: by B4 Relay for andreas@aclaesson.com/20261109 with auth_id=1465
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit eb51c9f8cb4f ("HID: corsair: cancel worker before unregistering
LED to fix use-after-free") moved cancel_work_sync() in front of
led_classdev_unregister() in the removal paths, because
k90_record_led_work() checks led->removed only once and then
dereferences led->cdev.dev:

	if (led->removed)
		return;

	dev = led->cdev.dev->parent;

The fail_sysfs error path in k90_init_macro_functions() was not
converted and still unregisters the LED before cancelling the work.
The record LED is registered, and its brightness attribute writable,
before sysfs_create_group() runs. If a brightness write queues the work
and sysfs_create_group() then fails, a work item that has already
passed the removed check can dereference led->cdev.dev after
led_classdev_unregister() has freed it:

  CPU0                                  CPU1
  k90_init_macro_functions()
    led_classdev_register()
                                        k90_brightness_set()
                                          schedule_work()
                                        k90_record_led_work()
                                          if (led->removed) return;
    sysfs_create_group() fails
    record_led.removed = true
    led_classdev_unregister()
      device_unregister(cdev.dev)
                                          led->cdev.dev->parent  <-- UAF
    cancel_work_sync()

Cancel the work before unregistering, as the removal paths do. Keep the
cancel after led_classdev_unregister() as well, since unregistering
turns the LED off and k90_brightness_set() queues the work again.

The problem was pointed out by the Sashiko AI review of a related
patch. It was confirmed on a KASAN kernel with a debug-only change that
forces the sysfs_create_group() failure and widens the race window:
without this patch KASAN reports a slab-use-after-free in
k90_record_led_work(), with it the error path completes cleanly.

Fixes: 6f78193ee9ea ("HID: corsair: Add Corsair Vengeance K90 driver")
Cc: stable@vger.kernel.org
Link: https://sashiko.dev/#/bug/linux-2f786541-d064-428e-a1ab-d203d4112002
Signed-off-by: Andreas Claesson <andreas@aclaesson.com>
---
The Sashiko AI review of my earlier hid-corsair patch [1] pointed out
this pre-existing race in the probe error path. This patch is
independent of that one and applies on its own; the two touch
different functions.

[1] https://lore.kernel.org/r/20261109-hid-corsair-k90-uaf-v1-1-0621c2c5c451@aclaesson.com
---
 drivers/hid/hid-corsair.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/hid/hid-corsair.c b/drivers/hid/hid-corsair.c
index 278c6efb565d..768fbcafb3ad 100644
--- a/drivers/hid/hid-corsair.c
+++ b/drivers/hid/hid-corsair.c
@@ -507,6 +507,7 @@ static int k90_init_macro_functions(struct hid_device *dev)
 
 fail_sysfs:
 	k90->record_led.removed = true;
+	cancel_work_sync(&k90->record_led.work);
 	led_classdev_unregister(&k90->record_led.cdev);
 	cancel_work_sync(&k90->record_led.work);
 fail_record_led:

---
base-commit: f66469d9905b39d2c260a15d7d6db450f4db67c1
change-id: 20261111-hid-corsair-k90-fail-sysfs-0069f00de809

Best regards,
--  
Andreas Claesson <andreas@aclaesson.com>

