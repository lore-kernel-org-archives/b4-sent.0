From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Thu, 21 May 2026 11:55:38 +0200
Subject: [PATCH v3 1/7] iio: light: opt3001: move device registration to
 end of probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260521-opt3001-cleanup-v3-1-820169dec8c3@gmail.com>
References: <20260521-opt3001-cleanup-v3-0-820169dec8c3@gmail.com>
In-Reply-To: <20260521-opt3001-cleanup-v3-0-820169dec8c3@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Alexander Koch <mail@alexanderkoch.net>, 
 Michael Hornung <mhornung.linux@gmail.com>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>, Sashiko <sashiko-bot@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779357341; l=1994;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=ZczGFIQbqXOXLVlXU5uBirkleYkJeoHuapeGlc+EZuQ=;
 b=6EuN+QHD5HXCI+/JLhT3u5i9ocSVNtKKGc+Z1MIW6vDkxxv+2sbL/6Yn2gJnk5iqAQUNw6ZPj
 V71NdptTC1hCPp8lFO7IITMQQy1aoKNfPGLB7Na2wPAUDFwjbNm4hF0
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move IIO device registration to the end of the probe() function to
prevent a potential race where userspace can interact with the device
before IRQ is configured properly. Additionally, switch
devm_iio_device_register() to its unmanaged counterpart as current
driver implementation mixes managed and unmanaged resources, causing
potential resource leaks.

Also, add iio_device_unregister() to remove() function to correctly
handle teardown.

Fixes: ac663db3678a ("iio: light: opt3001: enable operation w/o IRQ")
Reported-by: Jonathan Cameron <jic23@kernel.org>
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://sashiko.dev/#/patchset/20260511-opt3001-cleanup-v1-0-f7879dc3455c%40gmail.com?part=7
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/light/opt3001.c | 10 +++-------
 1 file changed, 3 insertions(+), 7 deletions(-)

diff --git a/drivers/iio/light/opt3001.c b/drivers/iio/light/opt3001.c
index dac3d3818d0a01b4ca53106fa38bb54b8c5373d4..fe53a072b21ddaa26a23c76e82897fdbc1e4d846 100644
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
@@ -894,7 +888,7 @@ static int opt3001_probe(struct i2c_client *client)
 		dev_dbg(opt->dev, "enabling interrupt-less operation\n");
 	}
 
-	return 0;
+	return iio_device_register(iio);
 }
 
 static void opt3001_remove(struct i2c_client *client)
@@ -904,6 +898,8 @@ static void opt3001_remove(struct i2c_client *client)
 	int ret;
 	u16 reg;
 
+	iio_device_unregister(iio);
+
 	if (opt->use_irq)
 		free_irq(client->irq, iio);
 

-- 
2.47.3

