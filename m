From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 05 Jul 2024 17:12:41 +0200
Subject: [PATCH v2 3/4] spi: xcomm: remove i2c_set_clientdata()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240705-dev-spi-xcomm-gpiochip-v2-3-b10842fc9636@analog.com>
References: <20240705-dev-spi-xcomm-gpiochip-v2-0-b10842fc9636@analog.com>
In-Reply-To: <20240705-dev-spi-xcomm-gpiochip-v2-0-b10842fc9636@analog.com>
To: linux-spi@vger.kernel.org
Cc: Mark Brown <broonie@kernel.org>, 
 Michael Hennerich <Michael.Hennerich@analog.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720192365; l=719;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=vUGNltR14uZYr+gI6pbeIx/V4FQQvYngKNBjnal7db4=;
 b=QMnksO+NgeIlZJm4SjtLwHEjjIEKU9b6RYKXNQWG4OT8MIuBJoNxjOn5FsytaqiixcZY2fZlu
 7kTL7hgbCu/ArFHSp1ZDTkfb8G6ahS5wJmO6EsofmNGw1rR9PhTHTtI
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

i2c_get_clientdata() is not being called anywhere so that we do not need
to set clientdata.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/spi/spi-xcomm.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/drivers/spi/spi-xcomm.c b/drivers/spi/spi-xcomm.c
index 5bbc250bc0534..1cd7d2b9e11c9 100644
--- a/drivers/spi/spi-xcomm.c
+++ b/drivers/spi/spi-xcomm.c
@@ -261,7 +261,6 @@ static int spi_xcomm_probe(struct i2c_client *i2c)
 	host->flags = SPI_CONTROLLER_HALF_DUPLEX;
 	host->transfer_one_message = spi_xcomm_transfer_one;
 	host->dev.of_node = i2c->dev.of_node;
-	i2c_set_clientdata(i2c, host);
 
 	ret = devm_spi_register_controller(&i2c->dev, host);
 	if (ret < 0)

-- 
2.45.2

