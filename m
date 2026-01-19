From: Petr Hodina <petr.hodina@protonmail.com>
Date: Mon, 19 Jan 2026 18:19:57 +0100
Subject: [PATCH 3/4] iio: proximity: vl53l0x-i2c: Fix reset sequence
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260119-vl53l0x-v1-3-cf71715a1353@protonmail.com>
References: <20260119-vl53l0x-v1-0-cf71715a1353@protonmail.com>
In-Reply-To: <20260119-vl53l0x-v1-0-cf71715a1353@protonmail.com>
To: Song Qiang <songqiang1304521@gmail.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Liam Girdwood <lgirdwood@gmail.com>, 
 Mark Brown <broonie@kernel.org>, David Heidelberg <david@ixit.cz>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768843207; l=1425;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=gSEF9OiTVlziFUY+j6AnvS9EbsjgiEBrPmz9odaovLo=;
 b=tRYucSdFhwTxfqOarD4F45oBWBG3pFwZnKUv7ccyqlEqk3wJpxHk3ou5uHoOzkdxscsLl7C7/
 NH+jR4TUbziBbJLmB2DsOJ4Ca+GSu4/XoKLh4MJ/WlB+xdszuZRB1WT
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the reset GPIO handling and power-up timing to better match the
VL53L0X reset requirements.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 drivers/iio/proximity/vl53l0x-i2c.c | 12 ++++++++----
 1 file changed, 8 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/proximity/vl53l0x-i2c.c b/drivers/iio/proximity/vl53l0x-i2c.c
index 7bfab396377a..6901ce7dd835 100644
--- a/drivers/iio/proximity/vl53l0x-i2c.c
+++ b/drivers/iio/proximity/vl53l0x-i2c.c
@@ -275,9 +275,13 @@ static int vl53l0x_power_on(struct vl53l0x_data *data)
 			return ret;
 	}
 
-	gpiod_set_value_cansleep(data->reset_gpio, 0);
-
-	usleep_range(3200, 5000);
+	usleep_range(5000, 6000);
+	if (data->reset_gpio) {
+		gpiod_set_value_cansleep(data->reset_gpio, 1);
+		usleep_range(5000, 6000);
+		gpiod_set_value_cansleep(data->reset_gpio, 0);
+		usleep_range(5000, 6000);
+	}
 
 	return 0;
 }
@@ -354,7 +358,7 @@ static int vl53l0x_probe(struct i2c_client *client)
 		return dev_err_probe(&client->dev, PTR_ERR(data->vio_supply),
 				     "Unable to get VDDIO regulator\n");
 
-	data->reset_gpio = devm_gpiod_get_optional(&client->dev, "reset", GPIOD_OUT_HIGH);
+	data->reset_gpio = devm_gpiod_get_optional(&client->dev, "reset", GPIOD_OUT_LOW);
 	if (IS_ERR(data->reset_gpio))
 		return dev_err_probe(&client->dev, PTR_ERR(data->reset_gpio),
 				     "Cannot get reset GPIO\n");

-- 
2.52.0

