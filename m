From: Peter LaDow <pladow@gmail.com>
Date: Fri, 20 Nov 2026 06:58:55 -0800
Subject: [PATCH] leds: lp5860: Fix DOTONOFF register offsets
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261120-fix-lp5860-dotonoff-register-offset-calculation-v1-1-ec1e78842380@gmail.com>
X-B4-Tracking: v=1; b=H4sIAC5gAGsC/x3NQQrDIBBA0auEWXdAB7RNr1K6MGZMB0SD2lIIu
 XuHLv/m/QM6N+EO9+mAxh/pUouGvUwQX6FsjLJqAxny1pLBJF/Mu7t5g2sdtdSUsPEmfXBDjc4
 DY8jxncNQC5fFOU8U5vnqQNW9sRL/4+N5nj9lLTTVgQAAAA==
X-Change-ID: 20261120-fix-lp5860-dotonoff-register-offset-calculation-bb55622a9975
To: Lee Jones <lee@kernel.org>, Pavel Machek <pavel@kernel.org>, 
 Griffin Kroah-Hartman <griffin@kroah.com>, 
 Steffen Trumtrar <s.trumtrar@pengutronix.de>
Cc: linux-leds@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Peter LaDow <pladow@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795186748; l=7231;
 i=pladow@gmail.com; s=20261120; h=from:subject:message-id;
 bh=bHt1ff45vnpY9vEZH118XYhA+bCp4obPXckiyGuJFVc=;
 b=xm5/bsmtq8SaHgmesxVDzNODD6fIQtALeBheNLxhZLeLTNdQBkuHawXApA7mpQovnVbNoqnE/
 re55ApUk0VSCCMYqrvHoGmEFHZZf78mvRTmcbyfQpKx2JiaiFHcowMY
X-Developer-Key: i=pladow@gmail.com; a=ed25519;
 pk=GEdL9uXOAV0PnykeFpXX87oqKs0/Ac0qAUc4Oow7WN4=
X-Endpoint-Received: by B4 Relay for pladow@gmail.com/20261120 with auth_id=1585
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

According to the TI LP5860 datasheet, 18 dots per scanline are
spread across groups of 3 in the DOTONOFF0..DOTONOFF32 registers,
rather than spread across the entire range.  Update the register
offset calculation to correctly calculate the offset and mask
for scanlines 1 to 10.

Fixes: f0a66563aa2d ("leds: Add support for TI LP5860 LED driver chip")
Signed-off-by: Peter LaDow <pladow@gmail.com>
---
I logged a defect in drivers/leds/rgb/lp5860-core.c on the bugzilla
at kernel.org (but #222303).  Attached is a patch to fix the offset
calculation for the DOTONOFFn registers.

Per the LP5860 11 × 18 LED Matrix Driver Register Maps
(see https://www.ti.com/lit/ug/snvu786/snvu786.pdf), the DOTONOFF for each
of 18 current sinks are spread across 3 registers.  But the current
mainline code assumes they are tightly packed across all the registers.

This patch calculates the correct offsets by first determining which line
the appropriate dot is on.  It then chooses the appropriate starting
register offset for that line, then correctly calculates the mask.
The comments documenting the registers are longer than 100 columns
(108 columns to be exactly), but I think this is important to keep the
information clear.

In the bugzilla entry, I attached Python code that demonstrates the proper
calculation and how the mainline mismatches.  I also demonstrated the new
code correctly calculates the offsets to match the datasheet.
---
 drivers/leds/rgb/leds-lp5860-core.c | 67 +++++++++++++++++++++++++++++++++++--
 1 file changed, 65 insertions(+), 2 deletions(-)

diff --git a/drivers/leds/rgb/leds-lp5860-core.c b/drivers/leds/rgb/leds-lp5860-core.c
index e21d5f2302be..540463c615d4 100644
--- a/drivers/leds/rgb/leds-lp5860-core.c
+++ b/drivers/leds/rgb/leds-lp5860-core.c
@@ -19,10 +19,73 @@ static struct lp5860_led *mcled_cdev_to_led(struct led_classdev_mc *mc_cdev)
 	return container_of(mc_cdev, struct lp5860_led, mc_cdev);
 }
 
+// Per the datasheet for the TI LP5860 the DOT_ONOFFn registers group the 18
+// current sink lines across 3 registers, starting at offset 0x43.
+// From https://www.ti.com/lit/ds/symlink/lp5860.pdf:
+//
+// |  Register   | Address |    D7   |    D6   |    D5   |    D4   |    D3   |    D2   |    D1   |    D0   |
+// +-------------+---------+---------+---------+---------+---------+---------+---------+---------+---------+
+// | DOT_ONOFF0  |  043h   |   Dot   |   Dot   |   Dot   |   Dot   |   Dot   |   Dot   |   Dot   |   Dot   |
+// |             |         |  L0-CS7 |  L0-CS6 |  L0-CS5 |  L0-CS4 |  L0-CS3 |  L0-CS2 |  L0-CS1 |  L0-CS0 |
+// +-------------+---------+---------+---------+---------+---------+---------+---------+---------+---------+
+// | DOT_ONOFF1  |  044h   |   Dot   |   Dot   |   Dot   |   Dot   |   Dot   |   Dot   |   Dot   |   Dot   |
+// |             |         | L0-CS15 | L0-CS14 | L0-CS13 | L0-CS12 | L0-CS11 | L0-CS10 |  L0-CS9 |  L0-CS8 |
+// +-------------+---------+---------+---------+---------+---------+---------+---------+---------+---------+
+// | DOT_ONOFF2  |  045h   | Reserved                                                  |   Dot   |   Dot   |
+// |             |         |                                                           | L0-CS17 | L0-CS16 |
+// +-------------+---------+---------+---------+---------+---------+---------+---------+---------+---------+
+// | DOT_ONOFF3  |  046h   |   Dot   |   Dot   |   Dot   |   Dot   |   Dot   |   Dot   |   Dot   |   Dot   |
+// |             |         |  L1-CS7 |  L1-CS6 |  L1-CS5 |  L1-CS4 |  L1-CS3 |  L1-CS2 |  L1-CS1 |  L1-CS0 |
+// +-------------+---------+---------+---------+---------+---------+---------+---------+---------+---------+
+// | DOT_ONOFF4  |  047h   |   Dot   |   Dot   |   Dot   |   Dot   |   Dot   |   Dot   |   Dot   |   Dot   |
+// |             |         | L1-CS15 | L1-CS14 | L1-CS13 | L1-CS12 | L1-CS11 | L1-CS10 |  L1-CS9 |  L1-CS8 |
+// +-------------+---------+---------+---------+---------+---------+---------+---------+---------+---------+
+// | DOT_ONOFF5  |  048h   | Reserved                                                  |   Dot   |   Dot   |
+// |             |         |                                                           | L1-CS17 | L1-CS16 |
+// +-------------+---------+---------+---------+---------+---------+---------+---------+---------+---------+
+// ... (049h ... 060h)
+// +-------------+---------+---------+---------+---------+---------+---------+---------+---------+---------+
+// | DOT_ONOFF30 |  061h   |   Dot   |   Dot   |   Dot   |   Dot   |   Dot   |   Dot   |   Dot   |   Dot   |
+// |             |         | L10-CS7 | L10-CS6 | L10-CS5 | L10-CS4 | L10-CS3 | L10-CS2 | L10-CS1 | L10-CS0 |
+// +-------------+---------+---------+---------+---------+---------+---------+---------+---------+---------+
+// | DOT_ONOFF31 |  062h   |   Dot   |   Dot   |   Dot   |   Dot   |   Dot   |   Dot   |   Dot   |   Dot   |
+// |             |         |L10-CS15 |L10-CS14 |L10-CS13 |L10-CS12 |L10-CS11 |L10-CS10 | L10-CS9 | L10-CS8 |
+// +-------------+---------+---------+---------+---------+---------+---------+---------+---------+---------+
+// | DOT_ONOFF32 |  063h   | Reserved                                                  |   Dot   |   Dot   |
+// |             |         |                                                           |L10-CS17 |L10-CS16 |
+// +-------------+---------+---------+---------+---------+---------+---------+---------+---------+---------+
+//
+// LP5860_MAX_LED_CONSTANT is the number of LEDs per line.
+// LP5860_MAX_DOT_ONOFF_GROUP_NUM is the number of LEDs per register.
+// These are 18 and 8, respectively, for the LP5860.
+//
+// So to calculate which register to write, we do the following:
+//
+//   Which line? (NOTE: integer division, rounding to 0)
+//     line = dot / LP5860_MAX_LED_CONSTANT
+//
+//   Which current sink channel on the line?
+//     channel = dot % LP5860_MAX_LED_CONSTANT
+//
+//   Number of registers per line:
+//     ceil(LP5860_MAX_LED_CONSTANT / LP5860_MAX_DOT_ONOFF_GROUP_NUM)
+//
+//   Starting register for the line:
+//     line * DIV_ROUND_UP(LP5860_MAX_LED_CONSTANT, LP5860_MAX_DOT_ONOFF_GROUP_NUM)
+//
+//   Offset within the line:
+//     channel / LP5860_MAX_DOT_ONOFF_GROUP_NUM
 static int lp5860_set_dot_onoff(struct lp5860_led *led, unsigned int dot, bool enable)
 {
-	unsigned int offset = dot / LP5860_MAX_DOT_ONOFF_GROUP_NUM;
-	unsigned int mask = BIT(dot % LP5860_MAX_DOT_ONOFF_GROUP_NUM);
+	unsigned int line = dot / LP5860_MAX_LED_CONSTANT;
+	unsigned int channel = dot % LP5860_MAX_LED_CONSTANT;
+
+	// Calculate the register offset.
+	unsigned int offset = line * DIV_ROUND_UP(LP5860_MAX_LED_CONSTANT, LP5860_MAX_DOT_ONOFF_GROUP_NUM) +
+		channel / LP5860_MAX_DOT_ONOFF_GROUP_NUM;
+
+	// The bit within the register.
+	unsigned int mask = BIT(channel % LP5860_MAX_DOT_ONOFF_GROUP_NUM);
 
 	if (dot > LP5860_MAX_LED)
 		return -EINVAL;

---
base-commit: c016466c8c8b01af27ac66d97b64fa9c9e431a3d
change-id: 20261120-fix-lp5860-dotonoff-register-offset-calculation-bb55622a9975

Best regards,
--  
Peter LaDow <pladow@gmail.com>

