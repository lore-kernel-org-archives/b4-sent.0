From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 30 Sep 2025 16:33:12 +0100
Subject: [PATCH 3/9] iio: adc: mcp3564: replace sprintf() with sysfs_emit()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250930-dev-sprintf-cleanup-v1-3-5d65d096a952@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759246391; l=813;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=Rp9zqAHR7um92cdrmdYf87T1TPcS5eCjH+Y/yw2ogfs=;
 b=TSEbpHN0Ta7K7iH/bVI6lgGBHEHfP7HzGhBHW8wDELffXwzKA7ksrSA22uIRbkL1qThkdU8qF
 XdYqd1+kxJwDCALJ5U4Q4IOyTqykx9mQ4TJ4SpJToB5/b7AGfpDZsLf
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update the mcp3564_read_label() function to use sysfs_emit() for
generating labels.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/adc/mcp3564.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/adc/mcp3564.c b/drivers/iio/adc/mcp3564.c
index cd679ff10a97c4be19ca461126bdfae2fa8431f2..fcdf13f49c48f31ba3a0a9079686d2b81a792744 100644
--- a/drivers/iio/adc/mcp3564.c
+++ b/drivers/iio/adc/mcp3564.c
@@ -987,7 +987,7 @@ static int mcp3564_read_label(struct iio_dev *indio_dev,
 {
 	struct mcp3564_state *adc = iio_priv(indio_dev);
 
-	return sprintf(label, "%s\n", adc->labels[chan->scan_index]);
+	return sysfs_emit(label, "%s\n", adc->labels[chan->scan_index]);
 }
 
 static int mcp3564_parse_fw_children(struct iio_dev *indio_dev)

-- 
2.51.0

