From: Joseph Telaak <joseph@telaak.dev>
Date: Sun, 01 Nov 2026 21:12:33 -0500
Subject: [PATCH 09/10] leds: rgb: ktd202x: Fail the probe when the chip
 does not answer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-ktd202x-et6326-v1-9-eb51eddad08c@telaak.dev>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793585580; l=1553;
 i=joseph@telaak.dev; s=20261102; h=from:subject:message-id;
 bh=tN2wy7OwuZC0ZumxoxtwXiUEmKmdwIanlrzcYbKhu94=;
 b=B5/78ifNW7ry1PcQYzxETIahBk8GLO1o+ue5ywcwKav5Gtrggl4xKBOZBukvmN+R81hSB9rhc
 euOF2vgJxfnD2qhCC/hoVhjX+TIZrWLj5VbnpSWbKuLQciDJWZnx98r
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=OmwSusdK4grZpiuZVfCZAvYyqz9FBkNemsV1EnHyVr4=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261102 with auth_id=1382
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver never reads from the chip: the register cache starts from the
defaults. So with a wrong address, or no chip at all, the reset write at
probe NAKs, the error is ignored and the LEDs get registered anyway. Every
later write then fails.

Fail the probe when the reset write fails.

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 drivers/leds/rgb/leds-ktd202x.c | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/drivers/leds/rgb/leds-ktd202x.c b/drivers/leds/rgb/leds-ktd202x.c
index 48521f1e5..5f51df993 100644
--- a/drivers/leds/rgb/leds-ktd202x.c
+++ b/drivers/leds/rgb/leds-ktd202x.c
@@ -722,20 +722,23 @@ static int ktd202x_probe_fw(struct ktd202x *chip)
 {
 	struct device *dev = chip->dev;
 	int count;
+	int ret;
 	int i = 0;
 
 	count = device_get_child_node_count(dev);
 	if (!count || count > chip->num_leds)
 		return -EINVAL;
 
-	regmap_write(chip->regmap, KTD202X_REG_RESET_CONTROL, KTD202X_RSTR_RESET);
+	/* Nothing is read back, so a failed reset is the only sign of a missing chip */
+	ret = regmap_write(chip->regmap, KTD202X_REG_RESET_CONTROL, KTD202X_RSTR_RESET);
+	if (ret)
+		return dev_err_probe(dev, ret, "Failed to reset the chip\n");
 
 	/* Allow the device to execute the complete reset */
 	usleep_range(200, 300);
 
 	device_for_each_child_node_scoped(dev, child) {
-		int ret = ktd202x_add_led(chip, child, i);
-
+		ret = ktd202x_add_led(chip, child, i);
 		if (ret)
 			return ret;
 

-- 
Git-155)

