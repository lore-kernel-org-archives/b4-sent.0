From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 21 Nov 2023 11:20:21 +0100
Subject: [PATCH 08/12] iio: adc: ad9467: use spi_get_device_match_data()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231121-dev-iio-backend-v1-8-6a3d542eba35@analog.com>
References: <20231121-dev-iio-backend-v1-0-6a3d542eba35@analog.com>
In-Reply-To: <20231121-dev-iio-backend-v1-0-6a3d542eba35@analog.com>
To: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-iio@vger.kernel.org
Cc: Olivier MOYSAN <olivier.moysan@foss.st.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Frank Rowand <frowand.list@gmail.com>, Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1700562016; l=686;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=zYitHUb6TMLk+FkB4cL0ig740y1mLs+DvRMVWPrSNF0=;
 b=bXWJ7iE5iGJrgtGP5xd739Rr7ggBJOq8O9gdmWl6WbsvAQnU0yaRoF4iISJY3EzpfGMuAUAIN
 4AltcqL8Q1WDNvkTtIpIqq0oGoY4BjwJS5R5b8uMYVJRnq0B/qzJQbm
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make use of spi_get_device_match_data() to simplify things.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/ad9467.c | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)

diff --git a/drivers/iio/adc/ad9467.c b/drivers/iio/adc/ad9467.c
index df4c21248226..f0342c8942ee 100644
--- a/drivers/iio/adc/ad9467.c
+++ b/drivers/iio/adc/ad9467.c
@@ -455,9 +455,7 @@ static int ad9467_probe(struct spi_device *spi)
 	unsigned int id;
 	int ret;
 
-	info = of_device_get_match_data(&spi->dev);
-	if (!info)
-		info = (void *)spi_get_device_id(spi)->driver_data;
+	info = spi_get_device_match_data(spi);
 	if (!info)
 		return -ENODEV;
 

-- 
2.42.1

