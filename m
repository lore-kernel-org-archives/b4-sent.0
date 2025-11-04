From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 04 Nov 2025 15:35:08 +0000
Subject: [PATCH v4 03/12] iio: dac: ad5446: Drop duplicated spi_id entry
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251104-dev-add-ad5542-v4-3-6fe35458bf8c@analog.com>
References: <20251104-dev-add-ad5542-v4-0-6fe35458bf8c@analog.com>
In-Reply-To: <20251104-dev-add-ad5542-v4-0-6fe35458bf8c@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762270508; l=1347;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=mlIlN1vKecNlba8Yd4mqcS02tNFjhgmuz7OVQKG3b7Q=;
 b=rW/B7LL2sa4JZTr7uIeqW9F+scJRM8g+L6hoSs+Z5nBRP+OPbno9ZH8rmhoQhcWke4thp+yRU
 5HzXzM58tMTBDyeKe68o+AqYCJ2ugiIiwvQjLOzvnQ7ySMMYf7bcWXc
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

AD5600 and AD5541A are compatible so there's no need to have a dedicated
entry for ID_AD5600.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/dac/ad5446.c | 7 +------
 1 file changed, 1 insertion(+), 6 deletions(-)

diff --git a/drivers/iio/dac/ad5446.c b/drivers/iio/dac/ad5446.c
index de5e4e0e397e..c0a38f642451 100644
--- a/drivers/iio/dac/ad5446.c
+++ b/drivers/iio/dac/ad5446.c
@@ -301,7 +301,6 @@ enum ad5446_supported_spi_device_ids {
 	ID_AD5541A,
 	ID_AD5512A,
 	ID_AD5553,
-	ID_AD5600,
 	ID_AD5601,
 	ID_AD5611,
 	ID_AD5621,
@@ -356,10 +355,6 @@ static const struct ad5446_chip_info ad5446_spi_chip_info[] = {
 		.channel = AD5446_CHANNEL(14, 16, 0),
 		.write = ad5446_write,
 	},
-	[ID_AD5600] = {
-		.channel = AD5446_CHANNEL(16, 16, 0),
-		.write = ad5446_write,
-	},
 	[ID_AD5601] = {
 		.channel = AD5446_CHANNEL_POWERDOWN(8, 16, 6),
 		.write = ad5446_write,
@@ -427,7 +422,7 @@ static const struct spi_device_id ad5446_spi_ids[] = {
 	{"ad5542a", ID_AD5541A}, /* ad5541a and ad5542a are compatible */
 	{"ad5543", ID_AD5541A}, /* ad5541a and ad5543 are compatible */
 	{"ad5553", ID_AD5553},
-	{"ad5600", ID_AD5600},
+	{"ad5600", ID_AD5541A}, /* ad5541a and ad5600 are compatible  */
 	{"ad5601", ID_AD5601},
 	{"ad5611", ID_AD5611},
 	{"ad5621", ID_AD5621},

-- 
2.51.0

