From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 06 Aug 2024 15:35:07 +0200
Subject: [PATCH 2/2] iio: dac: ad9739a: add backend debugfs interface
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240806-dev-backend-dac-direct-reg-access-v1-2-b84a6e8ee8a0@analog.com>
References: <20240806-dev-backend-dac-direct-reg-access-v1-0-b84a6e8ee8a0@analog.com>
In-Reply-To: <20240806-dev-backend-dac-direct-reg-access-v1-0-b84a6e8ee8a0@analog.com>
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, 
 Dragos Bogdan <dragos.bogdan@analog.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722951306; l=880;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=2tJLx9S3feK5aLP/bucGasBHK5sb0LjFdbnPk10uUfM=;
 b=1Xt2FwsLAKMhNBmQTfuH8OBmjzDVq/oNfTzyD24A55S4nHKWDODYFKG7A/MgG4gka7vBU+FRs
 aQ4BJbvw+LiC9clKHAlhieSFb3Ng4iZt2z6TXuiSF5+2F+a2obwGnJA
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Call iio_backend_debugfs_add() to add (if available) the backend debug
interface.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/dac/ad9739a.c | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/dac/ad9739a.c b/drivers/iio/dac/ad9739a.c
index 799387f21b9f..615d1a196db3 100644
--- a/drivers/iio/dac/ad9739a.c
+++ b/drivers/iio/dac/ad9739a.c
@@ -431,7 +431,13 @@ static int ad9739a_probe(struct spi_device *spi)
 	indio_dev->num_channels = ARRAY_SIZE(ad9739a_channels);
 	indio_dev->setup_ops = &ad9739a_buffer_setup_ops;
 
-	return devm_iio_device_register(&spi->dev, indio_dev);
+	ret = devm_iio_device_register(&spi->dev, indio_dev);
+	if (ret)
+		return ret;
+
+	iio_backend_debugfs_add(st->back, indio_dev);
+
+	return 0;
 }
 
 static const struct of_device_id ad9739a_of_match[] = {

-- 
2.45.2

