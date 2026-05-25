From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Mon, 25 May 2026 10:20:15 +0200
Subject: [PATCH v4 1/8] iio: light: opt3001: move device registration to
 end of probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260525-opt3001-cleanup-v4-1-65b36a174f78@gmail.com>
References: <20260525-opt3001-cleanup-v4-0-65b36a174f78@gmail.com>
In-Reply-To: <20260525-opt3001-cleanup-v4-0-65b36a174f78@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779697227; l=1858;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=oA51opJseD6tk2nABX482iviMQyyuKM5oZpLk6ZwbiU=;
 b=0mU+Q7a50F8VB2hs3UsYYa3wU9govCa5ia2cmCecoGcXjumHMCiiTnKUaT1hQrB/rlrlMZ4MZ
 Z60aEkhTLcABpaQuiKUq/dqrRicFPnU5uWCPcn7YirVrRw8c+Unr4Rb
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move IIO device registration to the end of the probe() function to
follow standard driver teardown/setup ordering and improve driver
logic. Additionally, switch devm_iio_device_register() to its
unmanaged counterpart as current driver implementation mixes managed
and unmanaged resources, causing potential resource leaks.

Also, add iio_device_unregister() to remove() function to correctly
handle teardown.

Suggested-by: Jonathan Cameron <jic23@kernel.org>
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/light/opt3001.c | 18 ++++++++++++------
 1 file changed, 12 insertions(+), 6 deletions(-)

diff --git a/drivers/iio/light/opt3001.c b/drivers/iio/light/opt3001.c
index 03c7a87b4a8eef13bbdcf48dcaf969781aa76bd1..6a39f116f9312b6933e86d72aefbaaaf1769aca5 100644
--- a/drivers/iio/light/opt3001.c
+++ b/drivers/iio/light/opt3001.c
@@ -874,12 +874,6 @@ static int opt3001_probe(struct i2c_client *client)
 	iio->modes = INDIO_DIRECT_MODE;
 	iio->info = &opt3001_info;
 
-	ret = devm_iio_device_register(dev, iio);
-	if (ret) {
-		dev_err(dev, "failed to register IIO device\n");
-		return ret;
-	}
-
 	/* Make use of INT pin only if valid IRQ no. is given */
 	if (irq > 0) {
 		ret = request_threaded_irq(irq, NULL, opt3001_irq,
@@ -894,7 +888,17 @@ static int opt3001_probe(struct i2c_client *client)
 		dev_dbg(opt->dev, "enabling interrupt-less operation\n");
 	}
 
+	ret = iio_device_register(iio);
+	if (ret)
+		goto free_irq;
+
 	return 0;
+
+free_irq:
+	if (irq > 0)
+		free_irq(irq, iio);
+
+	return ret;
 }
 
 static void opt3001_remove(struct i2c_client *client)
@@ -904,6 +908,8 @@ static void opt3001_remove(struct i2c_client *client)
 	int ret;
 	u16 reg;
 
+	iio_device_unregister(iio);
+
 	if (opt->use_irq)
 		free_irq(client->irq, iio);
 

-- 
2.47.3

