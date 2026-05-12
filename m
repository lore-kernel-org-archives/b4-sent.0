From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Tue, 12 May 2026 12:57:21 +0200
Subject: [PATCH v2 01/10] iio: light: opt3001: move device registration to
 end of probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260512-opt3001-cleanup-v2-1-8018cf3a8a0a@gmail.com>
References: <20260512-opt3001-cleanup-v2-0-8018cf3a8a0a@gmail.com>
In-Reply-To: <20260512-opt3001-cleanup-v2-0-8018cf3a8a0a@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Alexander Koch <mail@alexanderkoch.net>, 
 Michael Hornung <mhornung.linux@gmail.com>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>, Sashiko <sashiko-bot@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778583471; l=1566;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=nHPjQtXZ5RMpyhB4rSm3vBLNZNU5C/mIRnD5ecXS1Bc=;
 b=6/PIMfcUOxDdRs2DP/ReF8xt/OCjoTdSTgKXfqc2UBjW2HlCSmYeWie3lz4JmV8DWdY0bQi+U
 QIGFQodeiaDA3FKg4h/dkJvoOCJ0wRwW+F05WMK8lB2RhMAhO2r+VBQ
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move devm_iio_device_register() to end of the opt3001_probe() function
to prevent a race condition where userspace could interact with the
device before the hardware IRQ was set up.

Fixes: ac663db3678a ("iio: light: opt3001: enable operation w/o IRQ")
Reported-by: Jonathan Cameron <jic23@kernel.org>
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://sashiko.dev/#/patchset/20260511-opt3001-cleanup-v1-0-f7879dc3455c%40gmail.com?part=7
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/light/opt3001.c | 10 ++++------
 1 file changed, 4 insertions(+), 6 deletions(-)

diff --git a/drivers/iio/light/opt3001.c b/drivers/iio/light/opt3001.c
index 53bc455b7bad142695d9fecc6cabb934fb3ace0c..3c79e0c4ca32fedf33e318d047d6ab3f62b6c03b 100644
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
@@ -894,6 +888,10 @@ static int opt3001_probe(struct i2c_client *client)
 		dev_dbg(opt->dev, "enabling interrupt-less operation\n");
 	}
 
+	ret = devm_iio_device_register(dev, iio);
+	if (ret)
+		return dev_err(dev, "failed to register IIO device\n");
+
 	return 0;
 }
 

-- 
2.47.3

