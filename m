From: Joseph Telaak <joseph@telaak.dev>
Date: Mon, 09 Nov 2026 14:03:41 -0500
Subject: [PATCH v2 05/11] leds: rgb: ktd202x: Keep the unlit colors of a
 blinking LED off
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-ktd202x-et6326-v2-5-56e97c226658@telaak.dev>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794251062; l=1610;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=nXXhn11l+uuavgmJzzQ3n82zfpI6KSghh/2iqqmNfXQ=;
 b=Llboo1xxSNU9uZEpfPmWt2eG0Ga2Nu3GmXYd7b0/15NN8tVeaqf4/G+RHKOTi6x6mZl34mxwq
 xiuJneJlifqB3lQl604n88ArUJsNM+MREsB6V4a5NNqI6UjUTbhylyV
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

blink_set() switches every channel of a multicolor LED to the flash
timer, or to always on when delay_off is 0, including the colors whose
brightness is 0. Their current register still holds the last brightness
they had, or the 10 mA default, so for example a red blink set with a
multi_intensity of "255 0 0" also blinks green and blue.

Leave the channels of the colors with no brightness off, as
brightness_set() does. A single color LED now passes its brightness too.

Fixes: 0ebdb7210943 ("leds: Add ktd202x driver")
Cc: stable@vger.kernel.org
Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 drivers/leds/rgb/leds-ktd202x.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/leds/rgb/leds-ktd202x.c b/drivers/leds/rgb/leds-ktd202x.c
index feea33b7e885..042de16c28bc 100644
--- a/drivers/leds/rgb/leds-ktd202x.c
+++ b/drivers/leds/rgb/leds-ktd202x.c
@@ -284,6 +284,10 @@ static int ktd202x_blink_set(struct ktd202x_led *led, unsigned long *delay_on,
 		int channel = subleds[i].channel;
 
 		ctrl_mask |= KTD202X_CHANNEL_CTRL_MASK(channel);
+		/* A color with no brightness stays off */
+		if (!subleds[i].brightness)
+			continue;
+
 		ctrl_on |= KTD202X_CHANNEL_CTRL_ON(channel);
 		ctrl_pwm1 |= KTD202X_CHANNEL_CTRL_PWM1(channel);
 	}
@@ -359,6 +363,7 @@ static int ktd202x_blink_single_set(struct led_classdev *cdev,
 	if (!*delay_on)
 		return ktd202x_brightness_single_set(cdev, LED_OFF);
 
+	info.brightness = cdev->brightness;
 	info.channel = led->index;
 
 	return ktd202x_blink_set(led, delay_on, delay_off, &info, 1);

-- 
Git-155)

