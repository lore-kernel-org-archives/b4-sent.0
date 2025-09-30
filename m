From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 30 Sep 2025 16:33:10 +0100
Subject: [PATCH 1/9] iio: adc: ad4030: replace sprintf() with sysfs_emit()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250930-dev-sprintf-cleanup-v1-1-5d65d096a952@analog.com>
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
 Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sal@analog.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759246391; l=936;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=8oSpf8r5jwGofADc7uyuWm6zvYPITgJxkrmhRQeFNVw=;
 b=YvsETcKc0FyfwIW9q42+ruD7MI2LXA8AQsvBfAfIKPHq0U5ERtdYkzgKTFO97ieoaonc2C9mT
 rv6RbuR/aOuDK+pxAyySV9lQNy4dV9Evd/WfWrV8PGhEVjB6GqOCCM6
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update the ad4030_read_label() function to use sysfs_emit() for generating
labels.

Signed-off-by: Nuno Sá <nuno.sal@analog.com>
---
 drivers/iio/adc/ad4030.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/adc/ad4030.c b/drivers/iio/adc/ad4030.c
index 1bc2f9a2247081e166680232aa6d4aebc5f41b89..4393160c7c77981729d8e43bbf1aa573616e4d40 100644
--- a/drivers/iio/adc/ad4030.c
+++ b/drivers/iio/adc/ad4030.c
@@ -852,8 +852,8 @@ static int ad4030_read_label(struct iio_dev *indio_dev,
 			     char *label)
 {
 	if (chan->differential)
-		return sprintf(label, "differential%lu\n", chan->address);
-	return sprintf(label, "common-mode%lu\n", chan->address);
+		return sysfs_emit(label, "differential%lu\n", chan->address);
+	return sysfs_emit(label, "common-mode%lu\n", chan->address);
 }
 
 static int ad4030_get_current_scan_type(const struct iio_dev *indio_dev,

-- 
2.51.0

