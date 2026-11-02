From: Joseph Telaak <joseph@telaak.dev>
Date: Sun, 01 Nov 2026 21:12:32 -0500
Subject: [PATCH 08/10] leds: rgb: ktd202x: Limit the LED current to
 led-max-microamp
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-ktd202x-et6326-v1-8-eb51eddad08c@telaak.dev>
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
 linux-doc@vger.kernel.org, Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793585580; l=3297;
 i=joseph@telaak.dev; s=20261102; h=from:subject:message-id;
 bh=bJVCBymLVZomp3//HashN1Tl2FKEJXGEWkQVbD7FcHw=;
 b=Ug8b6aLw0kyjUK7y0zyWl1VcaJ12U6+WG3NrndldaoVN86LAdHH/6/ZN16W7uRe1kZrdHyIVX
 Q+XKBv/fTmMCsjvPlrcWKMEhhXLAxES1O1OD2E1e41JJj5TndnFthKp
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=OmwSusdK4grZpiuZVfCZAvYyqz9FBkNemsV1EnHyVr4=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261102 with auth_id=1382
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The full brightness of 192 is 24 mA, which is more than many indicator
LEDs are made for, and a channel may drive several LEDs in parallel. The
GL.iNet GL-SFT1200 firmware, for example, runs each of its two channels,
three LEDs each, at 1.375 mA.

Honor the common led-max-microamp property for single color LEDs by
lowering max_brightness, since each brightness step adds 0.125 mA. Set
max_brightness before the LED is registered, and blink at max_brightness
rather than at the chip maximum.

Multicolor LEDs are left as they are: the LED core already bounds each
color intensity, and the hardware this was tested on has none.

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 drivers/leds/rgb/leds-ktd202x.c | 20 +++++++++++++++++---
 1 file changed, 17 insertions(+), 3 deletions(-)

diff --git a/drivers/leds/rgb/leds-ktd202x.c b/drivers/leds/rgb/leds-ktd202x.c
index ed0e8e74c..48521f1e5 100644
--- a/drivers/leds/rgb/leds-ktd202x.c
+++ b/drivers/leds/rgb/leds-ktd202x.c
@@ -78,6 +78,7 @@
 #define KTD202X_PATTERN_MAX_MS 16384
 
 #define KTD202X_MAX_BRIGHTNESS 192
+#define KTD202X_LED_CURRENT_STEP_uA 125
 
 static const struct reg_default ktd202x_reg_defaults[] = {
 	{ KTD202X_REG_RESET_CONTROL, KTD202X_TIMER_SLOT_CONTROL_TSLOT1 |
@@ -398,7 +399,7 @@ static int ktd202x_blink_single_set(struct led_classdev *cdev,
 	int ret;
 
 	if (!cdev->brightness) {
-		ret = ktd202x_brightness_single_set(cdev, KTD202X_MAX_BRIGHTNESS);
+		ret = ktd202x_brightness_single_set(cdev, cdev->max_brightness);
 		if (ret)
 			return ret;
 	}
@@ -588,6 +589,18 @@ static int ktd202x_pattern_mc_clear(struct led_classdev *cdev)
 	return ktd202x_brightness_mc_set(cdev, LED_OFF);
 }
 
+/* The current limit of a LED in brightness steps, each of which adds 0.125 mA */
+static unsigned int ktd202x_max_brightness(struct fwnode_handle *fwnode)
+{
+	u32 max_microamp;
+
+	if (fwnode_property_read_u32(fwnode, "led-max-microamp", &max_microamp))
+		return KTD202X_MAX_BRIGHTNESS;
+
+	return clamp_t(u32, max_microamp / KTD202X_LED_CURRENT_STEP_uA, 1,
+		       KTD202X_MAX_BRIGHTNESS);
+}
+
 static int ktd202x_setup_led_rgb(struct ktd202x *chip, struct fwnode_handle *fwnode,
 				 struct ktd202x_led *led, struct led_init_data *init_data)
 {
@@ -637,6 +650,7 @@ static int ktd202x_setup_led_rgb(struct ktd202x *chip, struct fwnode_handle *fwn
 	led->mcdev.num_colors = num_channels;
 
 	cdev = &led->mcdev.led_cdev;
+	cdev->max_brightness = KTD202X_MAX_BRIGHTNESS;
 	cdev->brightness_set_blocking = ktd202x_brightness_mc_set;
 	cdev->blink_set = ktd202x_blink_mc_set;
 	cdev->pattern_set = ktd202x_pattern_mc_set;
@@ -660,6 +674,8 @@ static int ktd202x_setup_led_single(struct ktd202x *chip, struct fwnode_handle *
 	led->index = reg;
 
 	cdev = &led->cdev;
+	cdev->max_brightness = ktd202x_max_brightness(fwnode);
+
 	cdev->brightness_set_blocking = ktd202x_brightness_single_set;
 	cdev->blink_set = ktd202x_blink_single_set;
 	cdev->pattern_set = ktd202x_pattern_single_set;
@@ -699,8 +715,6 @@ static int ktd202x_add_led(struct ktd202x *chip, struct fwnode_handle *fwnode, u
 		return ret;
 	}
 
-	cdev->max_brightness = KTD202X_MAX_BRIGHTNESS;
-
 	return 0;
 }
 

-- 
Git-155)

