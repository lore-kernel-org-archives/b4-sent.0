From: Radu Sabau <radu.sabau@analog.com>
Date: Mon, 23 Nov 2026 15:25:29 +0200
Subject: [PATCH 5/7] iio: imu: adis: Drop the FIFO handling from the data
 ready trigger
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-adis-fifo-v1-5-f6ad9e493e19@analog.com>
References: <20261123-adis-fifo-v1-0-f6ad9e493e19@analog.com>
In-Reply-To: <20261123-adis-fifo-v1-0-f6ad9e493e19@analog.com>
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Ramona Gradinariu <ramona.bolboaca13@gmail.com>, 
 Radu Sabau <radu.sabau@analog.com>
Cc: linux-iio@vger.kernel.org, linux@analog.com, 
 linux-kernel@vger.kernel.org, Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795440327; l=1449;
 i=radu.sabau@analog.com; s=20261001; h=from:subject:message-id;
 bh=pD142zB7Wg0nJ7TAd0BHg7Du2nyR0gjUnfAC77rMuLo=;
 b=IceP6S+oYJoHgGh+eGQ1OguL2IPkrHb64sDsGvZvM9LE5MInLfTXvv+pFIcOjxbbCPpVVvbkZ
 h8iLDGubOPUD447P4rbwF267neCJe6OK6BDCTblmlXK6FGSvTlrJxxm
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=XOZSO/Ut8qfYw7khL8lUF65Pgl+VLihISyS+Iy9jY8c=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20261001 with auth_id=1094
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

No device with a FIFO uses the data ready trigger any more, they all use
devm_adis_setup_kfifo_buffer(). Remove the threaded oneshot interrupt
request meant for them from devm_adis_probe_trigger(), which now only
serves the data ready devices.

Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
 drivers/iio/imu/adis_trigger.c | 18 +++++-------------
 1 file changed, 5 insertions(+), 13 deletions(-)

diff --git a/drivers/iio/imu/adis_trigger.c b/drivers/iio/imu/adis_trigger.c
index ea8661bff901..14d29ea60273 100644
--- a/drivers/iio/imu/adis_trigger.c
+++ b/drivers/iio/imu/adis_trigger.c
@@ -84,19 +84,11 @@ int devm_adis_probe_trigger(struct adis *adis, struct iio_dev *indio_dev)
 	if (ret)
 		return ret;
 
-	if (adis->data->has_fifo)
-		ret = devm_request_threaded_irq(&adis->spi->dev, adis->spi->irq,
-						NULL,
-						&iio_trigger_generic_data_rdy_poll,
-						adis->irq_flag | IRQF_ONESHOT,
-						indio_dev->name,
-						adis->trig);
-	else
-		ret = devm_request_irq(&adis->spi->dev, adis->spi->irq,
-				       &iio_trigger_generic_data_rdy_poll,
-				       adis->irq_flag | IRQF_NO_THREAD,
-				       indio_dev->name,
-				       adis->trig);
+	ret = devm_request_irq(&adis->spi->dev, adis->spi->irq,
+			       &iio_trigger_generic_data_rdy_poll,
+			       adis->irq_flag | IRQF_NO_THREAD,
+			       indio_dev->name,
+			       adis->trig);
 	if (ret)
 		return ret;
 

-- 
2.43.0

