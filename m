From: Igor Velkov <iav@iav.lv>
Date: Mon, 16 Nov 2026 00:25:06 +0000
Subject: [PATCH v2 7/8] alarmtimer: Read the wakeup states of an RTC from
 linux,wakeup-states
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-b4-alarmtimer-rtc-priority-v2-7-b2c69721e489@iav.lv>
References: <20261116-b4-alarmtimer-rtc-priority-v2-0-b2c69721e489@iav.lv>
In-Reply-To: <20261116-b4-alarmtimer-rtc-priority-v2-0-b2c69721e489@iav.lv>
To: John Stultz <jstultz@google.com>, Thomas Gleixner <tglx@kernel.org>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>
Cc: Stephen Boyd <sboyd@kernel.org>, Miroslav Lichvar <mlichvar@redhat.com>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 linux-rtc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1842; i=iav@iav.lv;
 h=from:subject:message-id; bh=IOw/r59ERV9A/KJ7cZ9947oIWoc0hzz3hvG1MIMYEA4=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFm/fJOu52+V3Kv87MBnj7jEZ45F9nEb59hNeHe2pCP35
 vxz53TEO0pZGMS4GGTFFFkmHNK4lbHk6l9/D/MHMHNYmUCGMHBxCsBE1sxhZJhW/2+DlQt7upzN
 tadPLb8xBwS82vhn6mY+dWuv9rZ52r8Y/lfZ/nPsFH3P7rpnpUjtr67VX10aOvRf57jd4r1zl2O
 jNgcA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Every RTC is taken to wake the system from all suspend states, so the
first RTC with an alarm and a wakeup capable parent takes all of them.

Take the suspend states listed in the linux,wakeup-states property of the
RTC's parent instead, all of them without the property. An RTC with
"none" is not used.

On ODROID-HC4 this lets the pcf8563 wake the board from s2idle and
meson-vrtc from deep sleep.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
 kernel/time/alarmtimer.c | 16 ++++++++++++++--
 1 file changed, 14 insertions(+), 2 deletions(-)

diff --git a/kernel/time/alarmtimer.c b/kernel/time/alarmtimer.c
index 4153cce182a4..0770f4b0ca86 100644
--- a/kernel/time/alarmtimer.c
+++ b/kernel/time/alarmtimer.c
@@ -26,6 +26,7 @@
 #include <linux/freezer.h>
 #include <linux/compat.h>
 #include <linux/module.h>
+#include <linux/property.h>
 #include <linux/suspend.h>
 #include <linux/time_namespace.h>
 
@@ -111,10 +112,21 @@ static void alarmtimer_link_state(int state, struct device *dev)
 		dev_warn(&wakeup_ctl.pdev->dev, "Cannot link %s to %s\n", name, dev_name(dev));
 }
 
-/* Suspend states from which an alarm of the RTC on @dev wakes the system */
+/* Suspend states from linux,wakeup-states, all of them without the property */
 static unsigned long alarmtimer_wakeup_states(struct device *dev)
 {
-	return ALARMTIMER_STATES_ALL;
+	unsigned long states = 0;
+	int state;
+
+	if (!device_property_present(dev, "linux,wakeup-states"))
+		return ALARMTIMER_STATES_ALL;
+
+	for (state = ALARMTIMER_STATE_MIN; state < ALARMTIMER_STATE_MAX; state++) {
+		if (device_property_match_string(dev, "linux,wakeup-states",
+						 alarmtimer_state_names[state]) >= 0)
+			states |= BIT(state);
+	}
+	return states;
 }
 
 static int alarmtimer_rtc_add_device(struct device *dev)

-- 
2.43.0

