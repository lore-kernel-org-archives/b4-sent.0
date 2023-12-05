From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 05 Dec 2023 18:06:47 +0100
Subject: [PATCH 7/8] iio: adc: ad9467: use the more common !val NULL check
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231205-iio-backend-prep-v1-7-7c9bc18d612b@analog.com>
References: <20231205-iio-backend-prep-v1-0-7c9bc18d612b@analog.com>
In-Reply-To: <20231205-iio-backend-prep-v1-0-7c9bc18d612b@analog.com>
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1701796004; l=707;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=3jM1tUSsUENHFVqpXxzR/Yo8ri6HTO5FowZWdC38P+c=;
 b=puuU1b0SdAO4L8t9ZAspVLPBtIUt4FOZedOvK6dpK0P7rCQwwtLtNKdQu+4P/hQ4K8yvkT1GY
 Ez+SKlkCjXqA4JyGY43Xoc/SDvd2DR8yWhZ8ghLHkOKavaOPMm/X0lB
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Check !val instead of directing checking for NULL (val == NULL).
No functional changes intended.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/ad9467.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/adc/ad9467.c b/drivers/iio/adc/ad9467.c
index 0d075e6b6248..637823de712f 100644
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

