From: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
Date: Sun, 18 Oct 2026 22:41:51 +0100
Subject: [PATCH 2/2] staging: iio: addac: adt7316: drop informational
 message in probe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261018-adt7316-error-codes-v1-2-1970b7e242ac@gmail.com>
References: <20261018-adt7316-error-codes-v1-0-1970b7e242ac@gmail.com>
In-Reply-To: <20261018-adt7316-error-codes-v1-0-1970b7e242ac@gmail.com>
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux@analog.com, linux-iio@vger.kernel.org, 
 linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792359739; l=1014;
 i=raffaele.tranfaglia@gmail.com; s=20261011; h=from:subject:message-id;
 bh=yKADDDdmBBCSlIewg1RBic2YWBgdqUnAFXf9g80Iw9I=;
 b=4bGHkl86lqoxO05oSI3aEhN7pTSr3znRkYLdnGHa5tl+v8u/1hhgxkY53SqCTXNQvRjAG97/T
 SIIxK1ggLhkBYiRG3n2F56kbRHssFz7YzWDmUg3etjbvsaPKvgf8a0J
X-Developer-Key: i=raffaele.tranfaglia@gmail.com; a=ed25519;
 pk=mweuSGNM6vguCTdqa+aiHwMXdgk70suj2wolzCp6XGM=
X-Endpoint-Received: by B4 Relay for raffaele.tranfaglia@gmail.com/20261011 with auth_id=1160
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A successful probe does not need to be announced in the kernel log;
the device can be found in sysfs. Remove the dev_info() and return the
result of devm_iio_device_register() directly.

Assisted-by: LLM
Signed-off-by: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
---
 drivers/staging/iio/addac/adt7316.c | 9 +--------
 1 file changed, 1 insertion(+), 8 deletions(-)

diff --git a/drivers/staging/iio/addac/adt7316.c b/drivers/staging/iio/addac/adt7316.c
index d495032786db..9fcbb640b7a5 100644
--- a/drivers/staging/iio/addac/adt7316.c
+++ b/drivers/staging/iio/addac/adt7316.c
@@ -2178,14 +2178,7 @@ int adt7316_probe(struct device *dev, struct adt7316_bus *bus,
 	if (ret)
 		return ret;
 
-	ret = devm_iio_device_register(dev, indio_dev);
-	if (ret)
-		return ret;
-
-	dev_info(dev, "%s temperature sensor, ADC and DAC registered.\n",
-		 indio_dev->name);
-
-	return 0;
+	return devm_iio_device_register(dev, indio_dev);
 }
 EXPORT_SYMBOL(adt7316_probe);
 

-- 
2.56.0

