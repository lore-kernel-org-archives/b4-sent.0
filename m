From: Joseph Telaak <joseph@telaak.dev>
Date: Mon, 09 Nov 2026 14:03:39 -0500
Subject: [PATCH v2 03/11] leds: rgb: ktd202x: Never program an on time of
 zero
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-ktd202x-et6326-v2-3-56e97c226658@telaak.dev>
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
 linux-doc@vger.kernel.org, Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794251062; l=1420;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=EV1hmMaaQNopYbNm1qmtCvLAT8YUulReeH2UbRD8tX4=;
 b=5N6+AXHYwh9K+UQFzXUIn312YRX3LuAYUQmwV4Tgf5T/HL84uozk/eH7bTzjryK47HfTo6lmW
 x5nyDoLh/aUCzecIRTCZZ3cQgz72pFFGw2XO7KMPzCYYP9BfrvGUd40
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

blink_set() turns delay_on into a fraction of the period in 1/256 steps.
When delay_on is less than 1/256 of the period, for example 1 ms on and
1000 ms off, that fraction is 0: the LED stays dark, while the timer
trigger reports that it is blinking with delay_on = 0.

Use the shortest on time the hardware has, 1/256 of the period, and
report it back.

Fixes: 0ebdb7210943 ("leds: Add ktd202x driver")
Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 drivers/leds/rgb/leds-ktd202x.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/drivers/leds/rgb/leds-ktd202x.c b/drivers/leds/rgb/leds-ktd202x.c
index 482af28e8370..8c890ea5a754 100644
--- a/drivers/leds/rgb/leds-ktd202x.c
+++ b/drivers/leds/rgb/leds-ktd202x.c
@@ -304,8 +304,12 @@ static int ktd202x_blink_set(struct ktd202x_led *led, unsigned long *delay_on,
 				  (delay_total_ms - KTD202X_FLASH_PERIOD_MIN_MS) /
 				  KTD202X_FLASH_PERIOD_STEP_MS);
 
-	/* Integer representation of percentage of LED ON time */
+	/*
+	 * Integer representation of percentage of LED ON time. A value of 0
+	 * keeps the LED dark, so use the shortest on time instead.
+	 */
 	on = (*delay_on * KTD202X_FLASH_ON_MAX) / (*delay_on + *delay_off);
+	on = max(on, 1);
 
 	/* Actually used delay_{on,off} values */
 	delay_total_ms = num_steps * KTD202X_FLASH_PERIOD_STEP_MS + KTD202X_FLASH_PERIOD_MIN_MS;

-- 
Git-155)

