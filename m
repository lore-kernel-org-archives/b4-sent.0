From: Joseph Telaak <joseph@telaak.dev>
Date: Sun, 01 Nov 2026 21:12:26 -0500
Subject: [PATCH 02/10] leds: rgb: ktd202x: Fix an out-of-bounds read with
 unused channels
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-ktd202x-et6326-v1-2-eb51eddad08c@telaak.dev>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793585579; l=2008;
 i=joseph@telaak.dev; s=20261102; h=from:subject:message-id;
 bh=mwFEfqp4SCRu2h+8wzzdp0VhrsnxZe7qyijkGUaRI90=;
 b=l2AjyqU6OQtUEPl6CCNYUZS8H6tz5BGQR9687gz5U9QitYptaESTT9n2ws3fXrg+EbVjWsFRh
 6x/dhyLgQbVA5NpdFz4s+aGnt3AEwsPCX2AfGdIZe3wD/opZB/EpH6N
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=OmwSusdK4grZpiuZVfCZAvYyqz9FBkNemsV1EnHyVr4=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261102 with auth_id=1382
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The LED array is allocated for the number of child nodes, but
ktd202x_chip_in_use() walks it up to num_leds, the number of channels of
the chip. With fewer LEDs in the device tree than channels, for example
two LEDs on a KTD2026, it reads past the end of the allocation and the
__counted_by() annotation hides that from the bounds checkers.

Allocate one entry per channel.

Fixes: 0ebdb7210943 ("leds: Add ktd202x driver")
Cc: stable@vger.kernel.org
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 drivers/leds/rgb/leds-ktd202x.c | 8 +++++---
 1 file changed, 5 insertions(+), 3 deletions(-)

diff --git a/drivers/leds/rgb/leds-ktd202x.c b/drivers/leds/rgb/leds-ktd202x.c
index 539cf425c..482af28e8 100644
--- a/drivers/leds/rgb/leds-ktd202x.c
+++ b/drivers/leds/rgb/leds-ktd202x.c
@@ -537,6 +537,7 @@ static int ktd202x_probe(struct i2c_client *client)
 {
 	struct device *dev = &client->dev;
 	struct ktd202x *chip;
+	unsigned long num_leds;
 	int count;
 	int ret;
 
@@ -544,10 +545,13 @@ static int ktd202x_probe(struct i2c_client *client)
 	if (!count || count > KTD202X_MAX_LEDS)
 		return dev_err_probe(dev, -EINVAL, "Incorrect number of leds (%d)", count);
 
-	chip = devm_kzalloc(dev, struct_size(chip, leds, count), GFP_KERNEL);
+	/* Loops over the LEDs go up to the number of channels, not of child nodes */
+	num_leds = (unsigned long)i2c_get_match_data(client);
+	chip = devm_kzalloc(dev, struct_size(chip, leds, num_leds), GFP_KERNEL);
 	if (!chip)
 		return -ENOMEM;
 
+	chip->num_leds = num_leds;
 	chip->dev = dev;
 	i2c_set_clientdata(client, chip);
 
@@ -562,8 +566,6 @@ static int ktd202x_probe(struct i2c_client *client)
 	if (ret)
 		return ret;
 
-	chip->num_leds = (unsigned long)i2c_get_match_data(client);
-
 	chip->regulators[0].supply = "vin";
 	chip->regulators[1].supply = "vio";
 	ret = devm_regulator_bulk_get(dev, ARRAY_SIZE(chip->regulators), chip->regulators);

-- 
Git-155)

