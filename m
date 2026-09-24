From: Nikolay Plastinin <plaztininikolai@gmail.com>
Date: Thu, 24 Sep 2026 14:09:50 +0800
Subject: [PATCH] leds: trigger: input-events: Restore previous brightness
 on input
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260924-leds-input-events-brightness-v1-1-b0ceff3a2343@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqDMBAF0KvIrDugoZraqxQXUX91QKaSiVIQ7
 25w+TbvIEMUGL2LgyJ2MflpRvUoaJiDTmAZs8mVrilb9+QFo7HouiXGDk3GfZRpTgozDr4JaIP
 3/aumXKwRX/nf/ac7zwsKPWR2bgAAAA==
X-Change-ID: 20260924-leds-input-events-brightness-a76ae9a77b85
To: Lee Jones <lee@kernel.org>, Pavel Machek <pavel@kernel.org>
Cc: Hans de Goede <hansg@kernel.org>, linux-leds@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Nikolay Plastinin <plaztininikolai@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790230189; l=5164;
 i=plaztininikolai@gmail.com; s=20260924; h=from:subject:message-id;
 bh=9fTT6vvDmUwr05vJ+INi1EAlZ6Qq/4jBiJx926Ym6ag=;
 b=iSyqaocEPGAyae/34hitEU9b3XpMlSKVdJgT46oKncr840/8VDDay0kerys/Yhhth8K+cuDrR
 gehFFcUudZeBsxTK90iMBubAwVE4h8szv54Pd4qKVmJ+rGgpz4ZeeyT
X-Developer-Key: i=plaztininikolai@gmail.com; a=ed25519;
 pk=bmHrETa14IbiLNkJSoiLqUMni+IeSFwhOSDM4vVFN4s=
X-Endpoint-Received: by B4 Relay for plaztininikolai@gmail.com/20260924 with auth_id=1052
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The trigger turns the LEDs back on with LED_FULL, which the LED core
clamps to max_brightness. For keyboard backlights with several levels,
such as asus::kbd_backlight, this means the backlight always comes back
at maximum after being idle instead of at the level the user picked.

Remember the brightness in blink_brightness before turning the LEDs off
and use it when turning them back on, as the netdev trigger does.
Brightness changes made while the trigger is active are picked up too.
This needs per-LED handling, so convert the trigger from the simple
trigger API to a regular trigger with an activate callback.

Tested on an ASUS ROG Flow X13 GV302XV: with the keyboard backlight at
level 1, it now comes back at level 1 after going idle instead of at 3.
A level changed with the brightness hotkeys while the trigger is active
is restored after the next idle period as well.

Assisted-by: Claude Opus 5.5
Signed-off-by: Nikolay Plastinin <plaztininikolai@gmail.com>
---
This came up while looking at a keyboard backlight idle timeout for ASUS
laptops in asusctl:
https://github.com/OpenGamingCollective/asusctl/issues/98

The trigger walks trig->led_cdevs under rcu_read_lock() the same way
led_trigger_event() does. I can add a helper in led-triggers.c instead
if that is preferred.
---
 drivers/leds/trigger/ledtrig-input-events.c | 56 +++++++++++++++++++++++++----
 1 file changed, 50 insertions(+), 6 deletions(-)

diff --git a/drivers/leds/trigger/ledtrig-input-events.c b/drivers/leds/trigger/ledtrig-input-events.c
index d057b2a23..d1ef14ae8 100644
--- a/drivers/leds/trigger/ledtrig-input-events.c
+++ b/drivers/leds/trigger/ledtrig-input-events.c
@@ -10,6 +10,7 @@
 #include <linux/leds.h>
 #include <linux/module.h>
 #include <linux/moduleparam.h>
+#include <linux/rculist.h>
 #include <linux/slab.h>
 #include <linux/spinlock.h>
 #include <linux/workqueue.h>
@@ -28,7 +29,48 @@ static struct input_events_data {
 	unsigned long led_off_time;
 } input_events_data;
 
-static struct led_trigger *input_events_led_trigger;
+static int input_events_activate(struct led_classdev *led_cdev)
+{
+	struct input_events_data *data = &input_events_data;
+	unsigned long flags;
+
+	spin_lock_irqsave(&data->lock, flags);
+
+	if (led_cdev->brightness)
+		led_cdev->blink_brightness = led_cdev->brightness;
+	if (!led_cdev->blink_brightness)
+		led_cdev->blink_brightness = led_cdev->max_brightness;
+
+	led_set_brightness(led_cdev, data->led_on ? led_cdev->blink_brightness : LED_OFF);
+
+	spin_unlock_irqrestore(&data->lock, flags);
+
+	return 0;
+}
+
+static struct led_trigger input_events_led_trigger = {
+	.name = "input-events",
+	.activate = input_events_activate,
+};
+
+/* Must be called with input_events_data.lock held */
+static void input_events_set_leds(bool on)
+{
+	struct led_classdev *led_cdev;
+
+	rcu_read_lock();
+	list_for_each_entry_rcu(led_cdev, &input_events_led_trigger.led_cdevs, trig_list) {
+		/*
+		 * Remember the brightness the LED was last set to, so that it
+		 * is restored instead of max brightness on the next input event.
+		 */
+		if (led_cdev->brightness)
+			led_cdev->blink_brightness = led_cdev->brightness;
+
+		led_set_brightness(led_cdev, on ? led_cdev->blink_brightness : LED_OFF);
+	}
+	rcu_read_unlock();
+}
 
 static void led_input_events_work(struct work_struct *work)
 {
@@ -42,7 +84,7 @@ static void led_input_events_work(struct work_struct *work)
 	 * running before a new event pushed led_off_time back.
 	 */
 	if (time_after_eq(jiffies, data->led_off_time)) {
-		led_trigger_event(input_events_led_trigger, LED_OFF);
+		input_events_set_leds(false);
 		data->led_on = false;
 	}
 
@@ -59,7 +101,7 @@ static void input_events_event(struct input_handle *handle, unsigned int type,
 	spin_lock_irqsave(&data->lock, flags);
 
 	if (!data->led_on) {
-		led_trigger_event(input_events_led_trigger, LED_FULL);
+		input_events_set_leds(true);
 		data->led_on = true;
 	}
 	data->led_off_time = jiffies + led_off_delay;
@@ -138,11 +180,13 @@ static int __init input_events_init(void)
 	INIT_DELAYED_WORK(&input_events_data.work, led_input_events_work);
 	spin_lock_init(&input_events_data.lock);
 
-	led_trigger_register_simple("input-events", &input_events_led_trigger);
+	ret = led_trigger_register(&input_events_led_trigger);
+	if (ret)
+		return ret;
 
 	ret = input_register_handler(&input_events_handler);
 	if (ret) {
-		led_trigger_unregister_simple(input_events_led_trigger);
+		led_trigger_unregister(&input_events_led_trigger);
 		return ret;
 	}
 
@@ -153,7 +197,7 @@ static void __exit input_events_exit(void)
 {
 	input_unregister_handler(&input_events_handler);
 	cancel_delayed_work_sync(&input_events_data.work);
-	led_trigger_unregister_simple(input_events_led_trigger);
+	led_trigger_unregister(&input_events_led_trigger);
 }
 
 module_init(input_events_init);

---
base-commit: f475845eaf3d749114a63270bf2efea459e14dd2
change-id: 20260924-leds-input-events-brightness-a76ae9a77b85

Best regards,
-- 
Nikolay Plastinin <plaztininikolai@gmail.com>

