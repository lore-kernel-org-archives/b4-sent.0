From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 05 Dec 2023 18:06:45 +0100
Subject: [PATCH 5/8] iio: adc: ad9467: use spi_get_device_match_data()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231205-iio-backend-prep-v1-5-7c9bc18d612b@analog.com>
References: <20231205-iio-backend-prep-v1-0-7c9bc18d612b@analog.com>
In-Reply-To: <20231205-iio-backend-prep-v1-0-7c9bc18d612b@analog.com>
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1701796004; l=686;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=KwOoDJbfeKxv+O783O7duvsC7KCPDrH8MqqvCh2j2jc=;
 b=ACyqsphlXIDuXvqbAJcHv8gAMEISv6L/6J5c3+Urd4EdPSovL+SwSa9MknGlfJAdB8AN+7Xaf
 Zqvq3Q5WI5/Ah3xg5/nR3TdYz9RHKMFPLGMic3kZFe3DDmPI+N0p39E
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
index 3c8bd6c821a4..6bdbd0ea8d6c 100644
--- a/drivers/iio/adc/ad9467.c
+++ b/drivers/iio/adc/ad9467.c
@@ -456,9 +456,7 @@ static int ad9467_probe(struct spi_device *spi)
 	unsigned int id;
 	int ret;
 
-	info = of_device_get_match_data(&spi->dev);
-	if (!info)
-		info = (void *)spi_get_device_id(spi)->driver_data;
+	info = spi_get_device_match_data(spi);
 	if (!info)
 		return -ENODEV;
 

-- 
2.43.0

