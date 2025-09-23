From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 23 Sep 2025 09:41:47 +0100
Subject: [PATCH 1/2] iio: dac: ltc2688: make use of devm_mutex_init()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250923-dev-ltc2688-minor-v1-1-ef92c441dc42@analog.com>
References: <20250923-dev-ltc2688-minor-v1-0-ef92c441dc42@analog.com>
In-Reply-To: <20250923-dev-ltc2688-minor-v1-0-ef92c441dc42@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758616915; l=859;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=F6YQv/dp6fldG+irAJWIirOEKqwL81H4FDi4A6vD6/I=;
 b=E0G3sBJ3E1Twic4uQJikMhi82lPs4k7FexI9NZTGakeiNxCXROAu5TiQVb+hfY19/oRvDGDe7
 WDC/pGAvbD0B8TIHExlNZKwN8bDCcRgxlYv+S88P692YRJvw/U/CgvI
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use devm_mutex_init() since it brings some benefits when
CONFIG_DEBUG_MUTEXES is enabled.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/dac/ltc2688.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/dac/ltc2688.c b/drivers/iio/dac/ltc2688.c
index 7a2ee26a7d68730fe90d9cc91ea764f05eb61791..57028d422868ec48e6900ef1cc4be6dee9cd4547 100644
--- a/drivers/iio/dac/ltc2688.c
+++ b/drivers/iio/dac/ltc2688.c
@@ -953,7 +953,9 @@ static int ltc2688_probe(struct spi_device *spi)
 
 	/* Just write this once. No need to do it in every regmap read. */
 	st->tx_data[3] = LTC2688_CMD_NOOP;
-	mutex_init(&st->lock);
+	ret = devm_mutex_init(dev, &st->lock);
+	if (ret)
+		return ret;
 
 	st->regmap = devm_regmap_init(dev, &ltc2688_regmap_bus, st,
 				      &ltc2688_regmap_config);

-- 
2.51.0

