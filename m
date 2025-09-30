From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 30 Sep 2025 16:33:16 +0100
Subject: [PATCH 7/9] iio: adc: qcom-spmi-rradc: replace snprintf() with
 sysfs_emit()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250930-dev-sprintf-cleanup-v1-7-5d65d096a952@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759246391; l=827;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=LSfxhhZe4Y9G3fVBPuRYQ9cDdJyKCoAbntGmW6cv3Eg=;
 b=ySGgncpBHt8kfBf0mbo0J/Jyy+BqieBr3dd3ewpOTQeGTAa8dz78d9UCtCINd3G9FNKrVdmxj
 sN6rBKmNi8TCyZ9S4XQuixf5d4zz0gl3YDpQkJM9TSc+V2KJccSYcIW
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update the rradc_read_label() function to use sysfs_emit() for generating
labels.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/adc/qcom-spmi-rradc.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/adc/qcom-spmi-rradc.c b/drivers/iio/adc/qcom-spmi-rradc.c
index f61ad0510f04c7760d3735020b5de854b0e31702..b245416bae12121e16033f0185d8d0d2ef28f7ee 100644
--- a/drivers/iio/adc/qcom-spmi-rradc.c
+++ b/drivers/iio/adc/qcom-spmi-rradc.c
@@ -769,7 +769,7 @@ static int rradc_read_raw(struct iio_dev *indio_dev,
 static int rradc_read_label(struct iio_dev *indio_dev,
 			    struct iio_chan_spec const *chan, char *label)
 {
-	return snprintf(label, PAGE_SIZE, "%s\n",
+	return sysfs_emit(label, "%s\n",
 			rradc_chans[chan->address].label);
 }
 

-- 
2.51.0

