From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 30 Sep 2025 16:33:13 +0100
Subject: [PATCH 4/9] iio: adc: meson_saradc: replace sprintf() with
 sysfs_emit()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250930-dev-sprintf-cleanup-v1-4-5d65d096a952@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759246391; l=1089;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=CO1dW13uEq5iQy8PTF8+VarBtppTsSzenQ9AxsdRKFs=;
 b=4y4uDQITwsisSt6tGbaCrHAG7F6eERYGflEv1FzUMEcWRuohGhkZ81PLpLQFSU4g0KZTs3PrO
 eTmGjJUS8BwBZ5BVXFJg3udBxU2crACim+Fj4KHs1T3EnolD+l+15q5
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update the read_label() function to use sysfs_emit() for generating
labels.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/adc/meson_saradc.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/iio/adc/meson_saradc.c b/drivers/iio/adc/meson_saradc.c
index f7e7172ef4f6c2042f9ad54583d399f477ef7f5d..47cd350498a0d42536445ab324cc9249966b37d0 100644
--- a/drivers/iio/adc/meson_saradc.c
+++ b/drivers/iio/adc/meson_saradc.c
@@ -1181,12 +1181,12 @@ static int read_label(struct iio_dev *indio_dev,
 		      char *label)
 {
 	if (chan->type == IIO_TEMP)
-		return sprintf(label, "temp-sensor\n");
+		return sysfs_emit(label, "temp-sensor\n");
 	if (chan->type == IIO_VOLTAGE && chan->channel >= NUM_MUX_0_VSS)
-		return sprintf(label, "%s\n",
+		return sysfs_emit(label, "%s\n",
 			       chan7_mux_names[chan->channel - NUM_MUX_0_VSS]);
 	if (chan->type == IIO_VOLTAGE)
-		return sprintf(label, "channel-%d\n", chan->channel);
+		return sysfs_emit(label, "channel-%d\n", chan->channel);
 	return 0;
 }
 

-- 
2.51.0

