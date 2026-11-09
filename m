From: Joseph Telaak <joseph@telaak.dev>
Date: Mon, 09 Nov 2026 14:03:37 -0500
Subject: [PATCH v2 01/11] leds: rgb: ktd202x: Fix the flash period of short
 blinks on 32 bit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-ktd202x-et6326-v2-1-56e97c226658@telaak.dev>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794251062; l=1641;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=zfAMVaNdKcol9zMzD0rM6l30D7wHuzr1tcEVXAw473c=;
 b=N3ePYzao1Oy33AVtVloS1eSN5HorlfEqfYiwGCpK/9UfQ0WgR4y0zGA0KLJxov5unsBUOIlcU
 l8/79Di/Ld/Ar/xPNNor+Zu9A7mdqx+FY/UXchSqPkI02eTUPu8PxqM
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When delay_on + delay_off is below 256 ms, the unsigned subtraction of
KTD202X_FLASH_PERIOD_MIN_MS wraps. On 64 bit the result truncates to -1
or -2 and gets clamped to the shortest period, but on 32 bit it
truncates to 33554431 or 33554430 and gets clamped to the longest one,
so asking for a fast blink gives a blink every 16 seconds.

Compare before subtracting.

Fixes: 0ebdb7210943 ("leds: Add ktd202x driver")
Cc: stable@vger.kernel.org
Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 drivers/leds/rgb/leds-ktd202x.c | 10 +++++++---
 1 file changed, 7 insertions(+), 3 deletions(-)

diff --git a/drivers/leds/rgb/leds-ktd202x.c b/drivers/leds/rgb/leds-ktd202x.c
index 143020945e23..539cf425cdb7 100644
--- a/drivers/leds/rgb/leds-ktd202x.c
+++ b/drivers/leds/rgb/leds-ktd202x.c
@@ -296,9 +296,13 @@ static int ktd202x_blink_set(struct ktd202x_led *led, unsigned long *delay_on,
 	/* Convert into values the HW will understand. */
 
 	/* Integer representation of time of flash period */
-	num_steps = (*delay_on + *delay_off - KTD202X_FLASH_PERIOD_MIN_MS) /
-		    KTD202X_FLASH_PERIOD_STEP_MS;
-	num_steps = clamp(num_steps, 0, KTD202X_FLASH_PERIOD_MAX_STEPS);
+	delay_total_ms = *delay_on + *delay_off;
+	if (delay_total_ms < KTD202X_FLASH_PERIOD_MIN_MS)
+		num_steps = 0;
+	else
+		num_steps = min_t(unsigned long, KTD202X_FLASH_PERIOD_MAX_STEPS,
+				  (delay_total_ms - KTD202X_FLASH_PERIOD_MIN_MS) /
+				  KTD202X_FLASH_PERIOD_STEP_MS);
 
 	/* Integer representation of percentage of LED ON time */
 	on = (*delay_on * KTD202X_FLASH_ON_MAX) / (*delay_on + *delay_off);

-- 
Git-155)

