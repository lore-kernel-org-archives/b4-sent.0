From: Joseph Telaak <joseph@telaak.dev>
Date: Sun, 01 Nov 2026 21:12:25 -0500
Subject: [PATCH 01/10] leds: rgb: ktd202x: Fix the flash period of short
 blinks on 32 bit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-ktd202x-et6326-v1-1-eb51eddad08c@telaak.dev>
References: <20261101-ktd202x-et6326-v1-0-eb51eddad08c@telaak.dev>
In-Reply-To: <20261101-ktd202x-et6326-v1-0-eb51eddad08c@telaak.dev>
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
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793585579; l=1672;
 i=joseph@telaak.dev; s=20261102; h=from:subject:message-id;
 bh=hrB15O/zuKtRubiFTS3YHvdWnoAX4L1NgES4v7in3Vc=;
 b=k5X9Zd7ZY2jupGWKd00Eyp/g/9gjsAZW6C68IV7jEv+S6BKf2KV4Wx+2faFWLbu3HI5jcjSGo
 XwBT66/87l+DbF7G20RKOm+IxPlgDC8RrpNbLVtTt+8/FIVgYNxeZTN
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=OmwSusdK4grZpiuZVfCZAvYyqz9FBkNemsV1EnHyVr4=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261102 with auth_id=1382
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When delay_on + delay_off is below 256 ms, the unsigned subtraction of
KTD202X_FLASH_PERIOD_MIN_MS wraps. On 64 bit the result truncates to -1
or -2 and gets clamped to the shortest period, but on 32 bit it
truncates to 33554431 or 33554430 and gets clamped to the longest one,
so asking for a fast blink gives a blink every 16 seconds.

Compare before subtracting.

Fixes: 0ebdb7210943 ("leds: Add ktd202x driver")
Cc: stable@vger.kernel.org
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 drivers/leds/rgb/leds-ktd202x.c | 10 +++++++---
 1 file changed, 7 insertions(+), 3 deletions(-)

diff --git a/drivers/leds/rgb/leds-ktd202x.c b/drivers/leds/rgb/leds-ktd202x.c
index 143020945..539cf425c 100644
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

