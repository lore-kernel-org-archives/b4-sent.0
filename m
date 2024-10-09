From: Nuno Sa <nuno.sa@analog.com>
Date: Wed, 09 Oct 2024 16:16:44 +0200
Subject: [PATCH 2/4] iio: frequency: adf4371: drop spi_set_drvdata()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241009-dev-adf4371-minor-improv-v1-2-97f4f22ed941@analog.com>
References: <20241009-dev-adf4371-minor-improv-v1-0-97f4f22ed941@analog.com>
In-Reply-To: <20241009-dev-adf4371-minor-improv-v1-0-97f4f22ed941@analog.com>
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728483403; l=635;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=c8IXZHd6rce/m7P5wiE54syNc8oDjduP+uF8+b2rhUc=;
 b=IB87rW+qOzKKtO7GHOve2HEtyGEcN2xSuQwTVBrazpZXrWjpYl8y8HUt0pcU1laY29yvXfN21
 2dPj1aEKxl9AAOZsOD0aBGpvUr5E0ddtZPtENsziPw7Y6B5wvPYSv6V
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

spi_set_drvdata() is not needed as there's no spi_get_drvdata() call in
the code.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/frequency/adf4371.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/drivers/iio/frequency/adf4371.c b/drivers/iio/frequency/adf4371.c
index c8bf37f1679c..eb31f442566c 100644
--- a/drivers/iio/frequency/adf4371.c
+++ b/drivers/iio/frequency/adf4371.c
@@ -561,7 +561,6 @@ static int adf4371_probe(struct spi_device *spi)
 	}
 
 	st = iio_priv(indio_dev);
-	spi_set_drvdata(spi, indio_dev);
 	st->spi = spi;
 	st->regmap = regmap;
 	mutex_init(&st->lock);

-- 
2.46.1

