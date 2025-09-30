From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 30 Sep 2025 16:33:14 +0100
Subject: [PATCH 5/9] iio: adc: mt6360-adc: replace snprintf() with
 sysfs_emit()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250930-dev-sprintf-cleanup-v1-5-5d65d096a952@analog.com>
References: <20250930-dev-sprintf-cleanup-v1-0-5d65d096a952@analog.com>
In-Reply-To: <20250930-dev-sprintf-cleanup-v1-0-5d65d096a952@analog.com>
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Esteban Blanc <eblanc@baylibre.com>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Marius Cristea <marius.cristea@microchip.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Matteo Martelli <matteomartelli3@gmail.com>, Jiri Kosina <jikos@kernel.org>, 
 Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759246391; l=910;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=3f+W95hXwHL+jJYIyyCbGXqeeocZadZ1pyBxrDdqaHo=;
 b=8aP4W/p5srujnnNMnnPeKKFdtx8Tg/Gk/cxjEf0uazyj+bbAs5UmxKbFFfZk4rRfpY6eWLdrT
 bmfWmx7C/kBDiNSBA04XAST79B4jYbQzprH4UoB4Sp+0iH1a47lrOsH
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update the mt6360_adc_read_label() function to use sysfs_emit() for
generating labels.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/adc/mt6360-adc.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/adc/mt6360-adc.c b/drivers/iio/adc/mt6360-adc.c
index 69b3569c90e5b665e1d2c59621df00d6142fbe9c..e0e4df418612469bb11a88bdbeb77aeb7cb833eb 100644
--- a/drivers/iio/adc/mt6360-adc.c
+++ b/drivers/iio/adc/mt6360-adc.c
@@ -216,7 +216,7 @@ static const char *mt6360_channel_labels[MT6360_CHAN_MAX] = {
 static int mt6360_adc_read_label(struct iio_dev *iio_dev, const struct iio_chan_spec *chan,
 				 char *label)
 {
-	return snprintf(label, PAGE_SIZE, "%s\n", mt6360_channel_labels[chan->channel]);
+	return sysfs_emit(label, "%s\n", mt6360_channel_labels[chan->channel]);
 }
 
 static const struct iio_info mt6360_adc_iio_info = {

-- 
2.51.0

