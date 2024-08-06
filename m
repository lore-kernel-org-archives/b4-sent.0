From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 06 Aug 2024 17:40:49 +0200
Subject: [PATCH] iio: adc: ad_sigma_delta: fix irq_flags on irq request
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240806-dev-fix-ad-sigma-delta-v1-1-aa25b173c063@analog.com>
X-B4-Tracking: v=1; b=H4sIAABEsmYC/x2MSwqAMAwFryJZG2irFPEq4iKYqAF/tCKCeHeDy
 3nMmweyJJUMbfFAkkuz7puBLwsYZtomQWVjCC7UrnERWS4c9UZizDqtZMNyElbsna8jh0AR7Hw
 kMesPd/37fp9KzF1oAAAA
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, 
 Dumitru Ceclan <mitrutzceclan@gmail.com>, 
 Andy Shevchenko <andy.shevchenko@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722958849; l=1377;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=+YEFvjCJxa2eedif6Vm6NGhVp6V9JbA4Q0ngV/mhSWg=;
 b=loeKN2ll6nkGoGDQAxiCypLdyXh92uhegPcl1Xlz7C15OIkmgDXGz/5Vf2SpgG3/E/ks3gGNY
 A2wNz8lhKy0AYqWbS8AwnTooV97Bge4iwXySJsFdOlcJ9aJevRpYdx1
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With commit 7b0c9f8fa3d2 ("iio: adc: ad_sigma_delta: Add optional irq
selection"), we can get the irq line from struct ad_sigma_delta_info
instead of the spi device. However, in devm_ad_sd_probe_trigger(), when
getting the irq_flags with irq_get_trigger_type() we are still using
the spi device irq instead of the one used for devm_request_irq().

Fixes: 7b0c9f8fa3d2 ("iio: adc: ad_sigma_delta: Add optional irq selection")
Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/ad_sigma_delta.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/adc/ad_sigma_delta.c b/drivers/iio/adc/ad_sigma_delta.c
index 389930186bb6..e2bed2d648f2 100644
--- a/drivers/iio/adc/ad_sigma_delta.c
+++ b/drivers/iio/adc/ad_sigma_delta.c
@@ -569,7 +569,7 @@ EXPORT_SYMBOL_NS_GPL(ad_sd_validate_trigger, IIO_AD_SIGMA_DELTA);
 static int devm_ad_sd_probe_trigger(struct device *dev, struct iio_dev *indio_dev)
 {
 	struct ad_sigma_delta *sigma_delta = iio_device_get_drvdata(indio_dev);
-	unsigned long irq_flags = irq_get_trigger_type(sigma_delta->spi->irq);
+	unsigned long irq_flags = irq_get_trigger_type(sigma_delta->irq_line);
 	int ret;
 
 	if (dev != &sigma_delta->spi->dev) {

---
base-commit: 593737c18ae789dc6e4b493510a0c00977972e2e
change-id: 20240806-dev-fix-ad-sigma-delta-3d10146d22a6
--

Thanks!
- Nuno Sá

