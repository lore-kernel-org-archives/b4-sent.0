From: Joseph Telaak <joseph@telaak.dev>
Date: Mon, 09 Nov 2026 14:03:40 -0500
Subject: [PATCH v2 04/11] leds: rgb: ktd202x: Fix a division by zero with
 long blinks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-ktd202x-et6326-v2-4-56e97c226658@telaak.dev>
References: <20261109-ktd202x-et6326-v2-0-56e97c226658@telaak.dev>
In-Reply-To: <20261109-ktd202x-et6326-v2-0-56e97c226658@telaak.dev>
To: Lee Jones <lee@kernel.org>, Pavel Machek <pavel@kernel.org>, 
 Griffin Kroah-Hartman <griffin@kroah.com>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: linux-leds@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hardening@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-doc@vger.kernel.org, stable@vger.kernel.org, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794251062; l=2494;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=7z9O3spgFaG/KPiRDFqlglhrq5SskileVglyCLyPmHI=;
 b=PSkHXAqlRN1p/zhRbsVHGWpSmXPInhNbyja/3AhCzWdTMSidWfocndbj7e1NVaDUdMZSlLrjj
 F4Eo9uAcoW2Bfdtc0L8GHr9Zvt4we5GyOo2+53NPumXmthGtlrR6tvd
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

blink_set() works out the on time as delay_on * 256 / (delay_on +
delay_off) in unsigned long, with delays straight from the timer
trigger's sysfs files:

- when the two delays add up to exactly 2^32 on 32 bit, or 2^64 on
  64 bit, the sum wraps to 0 and the kernel divides by zero, for
  example with "echo 2147483648" into both delay_on and delay_off.
  That oopses on x86 and gives an arbitrary result on MIPS and arm64.
- on 32 bit the product already overflows once delay_on is above about
  4.6 hours, and a sum that wraps sets the wrong period, so long blinks
  get an arbitrary duty cycle

Saturate the sum, and compute the on time with mul_u64_u64_div_u64().

Fixes: 0ebdb7210943 ("leds: Add ktd202x driver")
Cc: stable@vger.kernel.org
Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 drivers/leds/rgb/leds-ktd202x.c | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/drivers/leds/rgb/leds-ktd202x.c b/drivers/leds/rgb/leds-ktd202x.c
index 8c890ea5a754..feea33b7e885 100644
--- a/drivers/leds/rgb/leds-ktd202x.c
+++ b/drivers/leds/rgb/leds-ktd202x.c
@@ -9,10 +9,12 @@
 
 #include <linux/i2c.h>
 #include <linux/led-class-multicolor.h>
+#include <linux/math64.h>
 #include <linux/module.h>
 #include <linux/mutex.h>
 #include <linux/of.h>
 #include <linux/of_device.h>
+#include <linux/overflow.h>
 #include <linux/regmap.h>
 #include <linux/regulator/consumer.h>
 
@@ -296,7 +298,8 @@ static int ktd202x_blink_set(struct ktd202x_led *led, unsigned long *delay_on,
 	/* Convert into values the HW will understand. */
 
 	/* Integer representation of time of flash period */
-	delay_total_ms = *delay_on + *delay_off;
+	if (check_add_overflow(*delay_on, *delay_off, &delay_total_ms))
+		delay_total_ms = ULONG_MAX;
 	if (delay_total_ms < KTD202X_FLASH_PERIOD_MIN_MS)
 		num_steps = 0;
 	else
@@ -308,8 +311,8 @@ static int ktd202x_blink_set(struct ktd202x_led *led, unsigned long *delay_on,
 	 * Integer representation of percentage of LED ON time. A value of 0
 	 * keeps the LED dark, so use the shortest on time instead.
 	 */
-	on = (*delay_on * KTD202X_FLASH_ON_MAX) / (*delay_on + *delay_off);
-	on = max(on, 1);
+	on = mul_u64_u64_div_u64(*delay_on, KTD202X_FLASH_ON_MAX, delay_total_ms);
+	on = clamp(on, 1, KTD202X_FLASH_ON_MAX - 1);
 
 	/* Actually used delay_{on,off} values */
 	delay_total_ms = num_steps * KTD202X_FLASH_PERIOD_STEP_MS + KTD202X_FLASH_PERIOD_MIN_MS;

-- 
Git-155)

