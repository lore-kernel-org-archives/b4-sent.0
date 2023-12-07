From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 07 Dec 2023 13:39:30 +0100
Subject: [PATCH v2 7/8] iio: adc: ad9467: use the more common !val NULL
 check
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231207-iio-backend-prep-v2-7-a4a33bc4d70e@analog.com>
References: <20231207-iio-backend-prep-v2-0-a4a33bc4d70e@analog.com>
In-Reply-To: <20231207-iio-backend-prep-v2-0-a4a33bc4d70e@analog.com>
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 David Lechner <dlechner@baylibre.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1701952767; l=759;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=zVjj1DQ8OD7RUy7uaCTyUmHiIyQXQxKb7ynVzBw9F74=;
 b=1R/KgZoTQeiPfmE3j5sFUEbpQwDnOqEdQ7NB91FhP9VtIA8S0BSK0TekLA3OhVc1mOAMebW5k
 CNY4R/Ze37YARLaTEqCvdchX04E+7K4Aq8abLnqaSPV2yxqqf7iMRTv
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Check !val instead of directing checking for NULL (val == NULL).
No functional changes intended.

Reviewed-by: David Lechner <dlechner@baylibre.com>
Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/ad9467.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/adc/ad9467.c b/drivers/iio/adc/ad9467.c
index c5ed62cc8646..6581fce4ba95 100644
--- a/drivers/iio/adc/ad9467.c
+++ b/drivers/iio/adc/ad9467.c
@@ -158,7 +158,7 @@ static int ad9467_reg_access(struct adi_axi_adc_conv *conv, unsigned int reg,
 	struct spi_device *spi = st->spi;
 	int ret;
 
-	if (readval == NULL) {
+	if (!readval) {
 		guard(mutex)(&st->lock);
 		ret = ad9467_spi_write(spi, reg, writeval);
 		if (ret)

-- 
2.43.0

