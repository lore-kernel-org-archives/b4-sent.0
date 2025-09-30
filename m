From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 30 Sep 2025 16:33:11 +0100
Subject: [PATCH 2/9] iio: adc: ad7768-1: replace sprintf() with
 sysfs_emit()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250930-dev-sprintf-cleanup-v1-2-5d65d096a952@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759246391; l=816;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=opjKFNFC21FJ8Tr+FRJKP5nMUNY1MqCJGUbkrC9mbo4=;
 b=I0vc10ghgU/I4y9IKY66Eo/578sswg1ydBiXpn2/7Q78Qn6zpJNh3d4+upWeTjCo+MFEQ7XN0
 qLGvyT+TKzZCtUsgArTLHhVrRARtj1essW4S/LsKmrHYPk3ScWu45dI
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update the ad7768_read_label() function to use sysfs_emit(() for
generating labels.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/adc/ad7768-1.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/adc/ad7768-1.c b/drivers/iio/adc/ad7768-1.c
index 872c88d0c86cab9f083e38dbc65463676c62001f..d96802b7847a6320c12fd121b0999256f3bd04a8 100644
--- a/drivers/iio/adc/ad7768-1.c
+++ b/drivers/iio/adc/ad7768-1.c
@@ -899,7 +899,7 @@ static int ad7768_read_label(struct iio_dev *indio_dev,
 {
 	struct ad7768_state *st = iio_priv(indio_dev);
 
-	return sprintf(label, "%s\n", st->labels[chan->channel]);
+	return sysfs_emit(label, "%s\n", st->labels[chan->channel]);
 }
 
 static int ad7768_get_current_scan_type(const struct iio_dev *indio_dev,

-- 
2.51.0

