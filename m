From: Joseph Telaak <joseph@telaak.dev>
Date: Mon, 09 Nov 2026 14:03:46 -0500
Subject: [PATCH v2 10/11] leds: rgb: ktd202x: Fail the probe when the chip
 does not answer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-ktd202x-et6326-v2-10-56e97c226658@telaak.dev>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794251062; l=1869;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=33Zn/F7Xphg4ctn6H/G5Lu7rMFXNNK5SWJKIHAWvAZY=;
 b=htRnK0RlYXjrx6Qh6BAVp0Ley8xZqZUnpahsbB0rAtx7YoUkKhYHdZ3R/xlqmWt4K2VmNvfZ1
 YMtTHcx/DMuA5sTI423AQwgXbYOqqfENOsu9+fxJj/1IXUbGN8QH68V
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver never reads from the chip: the register cache starts from the
defaults. So with a wrong address, or no chip at all, the LEDs get
registered anyway, and every later write fails.

The reset write can't tell: the KTD202x does not ACK the byte that
resets it, and its data sheet says to ignore that. So once the reset
is done, put the chip to sleep, as ktd202x_chip_disable() does, and
fail the probe when that write fails.

Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 drivers/leds/rgb/leds-ktd202x.c | 13 +++++++++++--
 1 file changed, 11 insertions(+), 2 deletions(-)

diff --git a/drivers/leds/rgb/leds-ktd202x.c b/drivers/leds/rgb/leds-ktd202x.c
index 2a3fda860e68..0cc2ec3f6a7f 100644
--- a/drivers/leds/rgb/leds-ktd202x.c
+++ b/drivers/leds/rgb/leds-ktd202x.c
@@ -738,20 +738,29 @@ static int ktd202x_probe_fw(struct ktd202x *chip)
 {
 	struct device *dev = chip->dev;
 	int count;
+	int ret;
 	int i = 0;
 
 	count = device_get_child_node_count(dev);
 	if (!count || count > chip->num_leds)
 		return -EINVAL;
 
+	/* The KTD202x does not ACK the byte that resets it, so ignore the result */
 	regmap_write(chip->regmap, KTD202X_REG_RESET_CONTROL, KTD202X_RSTR_RESET);
 
 	/* Allow the device to execute the complete reset */
 	usleep_range(200, 300);
 
-	device_for_each_child_node_scoped(dev, child) {
-		int ret = ktd202x_add_led(chip, child, i);
+	/*
+	 * Nothing is read back, so a failed write is the only sign of a missing
+	 * chip. Leave it asleep until a LED is turned on.
+	 */
+	ret = regmap_write(chip->regmap, KTD202X_REG_RESET_CONTROL, KTD202X_ENABLE_CTRL_SLEEP);
+	if (ret)
+		return dev_err_probe(dev, ret, "Failed to reach the chip\n");
 
+	device_for_each_child_node_scoped(dev, child) {
+		ret = ktd202x_add_led(chip, child, i);
 		if (ret)
 			return ret;
 

-- 
Git-155)

