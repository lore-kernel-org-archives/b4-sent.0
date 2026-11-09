From: Andreas Claesson <andreas@aclaesson.com>
Date: Mon, 09 Nov 2026 19:55:52 +0000
Subject: [PATCH] HID: corsair: cancel LED work again after unregistering
 the LED
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-hid-corsair-k90-uaf-v1-1-0621c2c5c451@aclaesson.com>
X-B4-Tracking: v=1; b=H4sIAEcl8moC/yXMQQqDQAxA0atI1gYmCpXpVUoX0xg1LWhJtAji3
 R3r8i3+38DFVBzuxQYmP3WdxgwqC+Ahjb2gttlQhepGFCIO2iJP5kkNPzHgkjoM3BBRbFhqgVx
 +TTpd/9fH87Ivr7fwfK5g3w9+suEldwAAAA==
X-Change-ID: 20261109-hid-corsair-k90-uaf-0c711197ce3e
To: Benjamin Tissoires <bentiss@kernel.org>, 
 Chen Changcheng <chenchangcheng@kylinos.cn>, Jiri Kosina <jikos@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794254152; l=4132;
 i=andreas@aclaesson.com; s=20261109; h=from:subject:message-id;
 bh=OH06v+FHNPldYATurhUtH3EMaR24kIgI5PheNIJyWHI=;
 b=67wwBo9EE2Opk/wXvX8JtEQkwIRYSLop3Kp9pZzHqtgd7u7iJhkdVOeRUZNfR/gzfDBAxFa7v
 LusorGfeDgZARwBhZRjKpYuWTAqJa1UuWRwA6PPNg3FwV53Q3grBdpN
X-Developer-Key: i=andreas@aclaesson.com; a=ed25519;
 pk=oC+38UX0rqcrEjNMgnKAF1zmrTUMbQ2aH/P5Z4TZOIQ=
X-Endpoint-Received: by B4 Relay for andreas@aclaesson.com/20261109 with auth_id=1465
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit eb51c9f8cb4f ("HID: corsair: cancel worker before unregistering
LED to fix use-after-free") moved cancel_work_sync() in front of
led_classdev_unregister() in k90_cleanup_backlight() and
k90_cleanup_macro_functions().

led_classdev_unregister() turns the LED off unless
LED_RETAIN_AT_SHUTDOWN is set. That calls k90_brightness_set(), which
unconditionally does schedule_work() on the same work item. The work is
therefore queued again after it was cancelled, and the structure that
embeds it is freed right afterwards:

  k90_cleanup_macro_functions()
    cancel_work_sync(&k90->record_led.work)
    led_classdev_unregister(&k90->record_led.cdev)
      led_set_brightness(LED_OFF)
        k90_brightness_set()
          schedule_work(&led->work)        <-- re-queued
    kfree(k90)                             <-- frees the queued work_struct

When the work later runs, the workqueue dereferences the freed
work_struct and k90_record_led_work() reads led->removed from freed
memory. A USB device that enumerates as a K90 and is then unplugged
triggers this reliably. With CONFIG_DEBUG_OBJECTS_WORK it shows up as:

  ODEBUG: free active (active state 0) object: ffff88803b8772c8 object type: work_struct hint: k90_record_led_work+0x0/0x1e0
  WARNING: lib/debugobjects.c:632 at debug_print_object+0xec/0x230
  Workqueue: usb_hub_wq hub_event
  Call Trace:
   debug_check_no_obj_freed+0x2e3/0x450 lib/debugobjects.c:1201
   kfree+0x13e/0x650 mm/slub.c:6923
   k90_cleanup_macro_functions drivers/hid/hid-corsair.c:547 [inline]
   corsair_remove+0xfd/0x260 drivers/hid/hid-corsair.c:602
   hid_device_remove+0xc5/0x1c0 drivers/hid/hid-core.c:2897
   ...
   usbhid_disconnect+0x9f/0xc0 drivers/hid/usbhid/hid-core.c:1486

(with ODEBUG enabled, work_fixup_free() cancels the work and hides the
use-after-free. Without it, the freed work item is executed.)

Keep the existing cancel_work_sync() before unregistering, which waits
for a worker that may already be past the 'removed' check, and cancel
the work once more after led_classdev_unregister() so the work queued
by the LED-off request is gone before the memory is freed. A re-queued
work that manages to run before the second cancel still sees
'removed == true' while the structure is alive and returns early.

Fixes: eb51c9f8cb4f ("HID: corsair: cancel worker before unregistering LED to fix use-after-free")
Cc: stable@vger.kernel.org
Signed-off-by: Andreas Claesson <andreas@aclaesson.com>
---
Found with syzkaller (USB emulation, KASAN + ODEBUG) on mainline
f66469d9905b. Both the record LED and the backlight paths reproduce
(hint: k90_record_led_work / k90_backlight_work); a minimised
3-call syzkaller reproducer is available on request. With this patch,
200 probe/removal cycles per path gave no ODEBUG or KASAN reports,
against ODEBUG on roughly half of removals without it.
---
 drivers/hid/hid-corsair.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/hid/hid-corsair.c b/drivers/hid/hid-corsair.c
index 278c6efb565d..75c862f5f783 100644
--- a/drivers/hid/hid-corsair.c
+++ b/drivers/hid/hid-corsair.c
@@ -526,6 +526,8 @@ static void k90_cleanup_backlight(struct hid_device *dev)
 		drvdata->backlight->removed = true;
 		cancel_work_sync(&drvdata->backlight->work);
 		led_classdev_unregister(&drvdata->backlight->cdev);
+		/* unregister turns the LED off, which re-queues the work */
+		cancel_work_sync(&drvdata->backlight->work);
 		kfree(drvdata->backlight->cdev.name);
 		kfree(drvdata->backlight);
 	}
@@ -542,6 +544,8 @@ static void k90_cleanup_macro_functions(struct hid_device *dev)
 		k90->record_led.removed = true;
 		cancel_work_sync(&k90->record_led.work);
 		led_classdev_unregister(&k90->record_led.cdev);
+		/* unregister turns the LED off, which re-queues the work */
+		cancel_work_sync(&k90->record_led.work);
 		kfree(k90->record_led.cdev.name);
 
 		kfree(k90);

---
base-commit: f66469d9905b39d2c260a15d7d6db450f4db67c1
change-id: 20261109-hid-corsair-k90-uaf-0c711197ce3e

Best regards,
--  
Andreas Claesson <andreas@aclaesson.com>

