From: Wayne Ho <wayneho219@gmail.com>
Date: Thu, 01 Oct 2026 14:45:12 +0800
Subject: [PATCH 2/2] Documentation: ABI: leds: document timer, heartbeat
 and activity attributes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261001-docs-leds-abi-trigger-attrs-v1-2-54f0529bf0f6@gmail.com>
References: <20261001-docs-leds-abi-trigger-attrs-v1-0-54f0529bf0f6@gmail.com>
In-Reply-To: <20261001-docs-leds-abi-trigger-attrs-v1-0-54f0529bf0f6@gmail.com>
To: Pavel Machek <pavel@kernel.org>, Lee Jones <lee@kernel.org>
Cc: linux-leds@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790837130; l=5409;
 i=wayneho219@gmail.com; s=20261001; h=from:subject:message-id;
 bh=XUkqfCwSdokMBSaYM8CnAm/LMcz5dJg/PFsQuhlJmYg=;
 b=dpBLf5qqQwK8XX8Dupz35Es0QJkYVCaTXEwYyZx+1d0oSrpe0DivDube/pA60bLfFvqcCH7lV
 cCYz96CgTKiDMch79uOaGor96lfoLsWuWlSrrJN4/DG4vp1dUDdZf0R
X-Developer-Key: i=wayneho219@gmail.com; a=ed25519;
 pk=j25LRSikYRlv0PpovZSgSrCQwsy7WDzIYum/mydUa3A=
X-Endpoint-Received: by B4 Relay for wayneho219@gmail.com/20261001 with auth_id=1093
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The delay_on and delay_off attributes created by the timer trigger and
the invert attribute created by the heartbeat and activity triggers
are not documented. They share their sysfs paths with the oneshot
trigger attributes, so adding a separate entry per trigger would make
get_abi.py warn about the same path being defined more than once.

Move the delay_on, delay_off and invert entries from
sysfs-class-led-trigger-oneshot to sysfs-class-led and describe the
behaviour of each trigger that creates them.

Signed-off-by: Wayne Ho <wayneho219@gmail.com>
---
 Documentation/ABI/testing/sysfs-class-led          | 68 ++++++++++++++++++++++
 .../ABI/testing/sysfs-class-led-trigger-oneshot    | 29 ---------
 2 files changed, 68 insertions(+), 29 deletions(-)

diff --git a/Documentation/ABI/testing/sysfs-class-led b/Documentation/ABI/testing/sysfs-class-led
index c72cb1e0..f438fb83 100644
--- a/Documentation/ABI/testing/sysfs-class-led
+++ b/Documentation/ABI/testing/sysfs-class-led
@@ -86,3 +86,71 @@ Description:
 		Invert the LED on/off state. This parameter is specific to
 		the backlight trigger. It is useful when driving a LED which
 		is intended to indicate a device in a standby like state.
+
+What:		/sys/class/leds/<led>/delay_on
+Date:		March 2006
+KernelVersion:	2.6.17
+Contact:	linux-leds@vger.kernel.org
+Description:
+		This attribute is only present when the LED's trigger is
+		set to "timer" or "oneshot".
+
+		For the "timer" trigger, specifies for how many milliseconds
+		the LED has to stay on in each cycle of a repeating on/off
+		blink. Writing a new value restarts the blink immediately.
+		Defaults to 500 ms.
+
+		For the "oneshot" trigger, specifies for how many
+		milliseconds the LED has to stay at LED_FULL brightness
+		after it has been armed. Defaults to 100 ms.
+
+What:		/sys/class/leds/<led>/delay_off
+Date:		March 2006
+KernelVersion:	2.6.17
+Contact:	linux-leds@vger.kernel.org
+Description:
+		This attribute is only present when the LED's trigger is
+		set to "timer" or "oneshot".
+
+		For the "timer" trigger, specifies for how many milliseconds
+		the LED has to stay off in each cycle of a repeating on/off
+		blink. Writing a new value restarts the blink immediately.
+		Defaults to 500 ms; together with the default delay_on this
+		gives a 1 Hz blink.
+
+		For the "oneshot" trigger, specifies for how many
+		milliseconds the LED has to stay at LED_OFF brightness
+		after it has been armed. Defaults to 100 ms.
+
+What:		/sys/class/leds/<led>/invert
+Date:		Jun 2012
+KernelVersion:	3.6
+Contact:	linux-leds@vger.kernel.org
+Description:
+		This attribute is only present when the LED's trigger is
+		set to "oneshot", "heartbeat" or "activity". Any non-zero
+		value written is stored as 1, so reading it back returns
+		0 or 1.
+
+		For the "oneshot" trigger, reverses the blink logic. If set
+		to 0 (default) blink on for delay_on ms, then blink off for
+		delay_off ms, leaving the LED normally off. If set to 1,
+		blink off for delay_off ms, then blink on for delay_on ms,
+		leaving the LED normally on. Setting this value also
+		immediately changes the LED state.
+
+		For the "heartbeat" trigger, inverts the heartbeat pattern.
+		If set to 0 (default) the LED stays off most of the time and
+		blinks briefly on. If set to 1 the LED stays on most of the
+		time and blinks briefly off. Unlike "oneshot", the new value
+		only takes effect at the next phase of the pattern.
+
+		For the "activity" trigger, inverts the on/off states of the
+		CPU activity blink. If set to 0 (default) the LED is mostly
+		off when the system is idle and stays on longer as CPU usage
+		grows. If set to 1 the LED is mostly on when idle and stays
+		off longer as CPU usage grows. The new value only takes
+		effect at the next on/off transition.
+
+		This is unrelated to the /sys/class/leds/<led>/inverted
+		attribute, which is specific to the backlight trigger.
diff --git a/Documentation/ABI/testing/sysfs-class-led-trigger-oneshot b/Documentation/ABI/testing/sysfs-class-led-trigger-oneshot
index 378a3a4d..3532f13d 100644
--- a/Documentation/ABI/testing/sysfs-class-led-trigger-oneshot
+++ b/Documentation/ABI/testing/sysfs-class-led-trigger-oneshot
@@ -1,32 +1,3 @@
-What:		/sys/class/leds/<led>/delay_on
-Date:		Jun 2012
-KernelVersion:	3.6
-Contact:	linux-leds@vger.kernel.org
-Description:
-		Specifies for how many milliseconds the LED has to stay at
-		LED_FULL brightness after it has been armed.
-		Defaults to 100 ms.
-
-What:		/sys/class/leds/<led>/delay_off
-Date:		Jun 2012
-KernelVersion:	3.6
-Contact:	linux-leds@vger.kernel.org
-Description:
-		Specifies for how many milliseconds the LED has to stay at
-		LED_OFF brightness after it has been armed.
-		Defaults to 100 ms.
-
-What:		/sys/class/leds/<led>/invert
-Date:		Jun 2012
-KernelVersion:	3.6
-Contact:	linux-leds@vger.kernel.org
-Description:
-		Reverse the blink logic. If set to 0 (default) blink on for
-		delay_on ms, then blink off for delay_off ms, leaving the LED
-		normally off. If set to 1, blink off for delay_off ms, then
-		blink on for delay_on ms, leaving the LED normally on.
-		Setting this value also immediately changes the LED state.
-
 What:		/sys/class/leds/<led>/shot
 Date:		Jun 2012
 KernelVersion:	3.6

-- 
Git-155)

