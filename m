From: Nikolay Plastinin <plaztininikolai@gmail.com>
Date: Fri, 30 Oct 2026 21:51:31 +0800
Subject: [PATCH v4 1/2] leds: triggers: Add led_trigger_for_each_led()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261030-leds-input-events-brightness-v4-1-5ea0ead7480c@gmail.com>
References: <20261030-leds-input-events-brightness-v4-0-5ea0ead7480c@gmail.com>
In-Reply-To: <20261030-leds-input-events-brightness-v4-0-5ea0ead7480c@gmail.com>
To: Lee Jones <lee@kernel.org>, Pavel Machek <pavel@kernel.org>
Cc: Hans de Goede <hansg@kernel.org>, linux-leds@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Nikolay Plastinin <plaztininikolai@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793368292; l=1697;
 i=plaztininikolai@gmail.com; s=20260924; h=from:subject:message-id;
 bh=XB1M/17vbfVXqMrEZDyY+zPssA2UXsnOCNxpwiGlg0U=;
 b=FR34tIg3//iHwMs2rey0Ta4U8G7CGbCRx2PqsqZ++LBMVS81BF8v31+B9S8Z6yiuUYeejSgxm
 C2XRvwdiyFnDGwMa5YJKvI2b6FcwYFTbnwxqM4R2zpYJTfU9oa6WQ/w
X-Developer-Key: i=plaztininikolai@gmail.com; a=ed25519;
 pk=bmHrETa14IbiLNkJSoiLqUMni+IeSFwhOSDM4vVFN4s=
X-Endpoint-Received: by B4 Relay for plaztininikolai@gmail.com/20260924 with auth_id=1052
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

led_trigger_event() sets one brightness for all LEDs using a trigger.
A trigger which restores a different brightness per LED needs to iterate
over the attached LEDs instead.

Add led_trigger_for_each_led(), a wrapper around list_for_each_entry_rcu(),
so triggers can perform this iteration without spelling out the list
members. Document that callers must hold the RCU read lock throughout
the iteration and must not sleep while accessing the LEDs.

Assisted-by: LLM
Signed-off-by: Nikolay Plastinin <plaztininikolai@gmail.com>
---
 include/linux/leds.h | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/include/linux/leds.h b/include/linux/leds.h
index a515f075c..675c58661 100644
--- a/include/linux/leds.h
+++ b/include/linux/leds.h
@@ -11,6 +11,7 @@
 #include <dt-bindings/leds/common.h>
 #include <linux/device.h>
 #include <linux/mutex.h>
+#include <linux/rculist.h>
 #include <linux/rwsem.h>
 #include <linux/spinlock.h>
 #include <linux/timer.h>
@@ -502,6 +503,17 @@ struct led_trigger {
 	const struct attribute_group **groups;
 };
 
+/**
+ * led_trigger_for_each_led - iterate over the LEDs attached to a trigger
+ * @pos: struct led_classdev pointer used as the loop cursor
+ * @trig: trigger whose LEDs are iterated
+ *
+ * The caller must hold the RCU read lock throughout the iteration and must
+ * not sleep while accessing the LEDs.
+ */
+#define led_trigger_for_each_led(pos, trig) \
+	list_for_each_entry_rcu(pos, &(trig)->led_cdevs, trig_list)
+
 /*
  * Currently the attributes in struct led_trigger::groups are added directly to
  * the LED device. As this might change in the future, the following

-- 
2.56.0

