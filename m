From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 30 Sep 2025 16:33:18 +0100
Subject: [PATCH 9/9] iio: resolver: ad2s1210: replace sprintf() with
 sysfs_emit()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250930-dev-sprintf-cleanup-v1-9-5d65d096a952@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759246391; l=2894;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=2v/UBDacfyGj6xhZdzqGsD4ShuKgbrosFVu6hBr3/TU=;
 b=SZ1ccuEHWy8PJkPf4uWbeG9O41n7NqU7iKIMliFfwXerRoEiXkiadZJbn7Dd20EupxdVrQLUz
 ElO5j8g8wDJCBRD/2mjoa1ZY5GzXBKUkcTJz5qkFL7DC2+pUv31JPTv
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update the ad2s1210_read_label() and ad2s1210_read_event_label() functions
to use sysfs_emit() for generating labels.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/resolver/ad2s1210.c | 30 +++++++++++++++---------------
 1 file changed, 15 insertions(+), 15 deletions(-)

diff --git a/drivers/iio/resolver/ad2s1210.c b/drivers/iio/resolver/ad2s1210.c
index 9b028c8bb1db142e2afd743aa3ace1d6d3230ae5..06d9c784f93e01288b42a1b9aee36b9f84e4b7f4 100644
--- a/drivers/iio/resolver/ad2s1210.c
+++ b/drivers/iio/resolver/ad2s1210.c
@@ -1132,23 +1132,23 @@ static int ad2s1210_read_label(struct iio_dev *indio_dev,
 {
 	if (chan->type == IIO_ANGL) {
 		if (chan->channel == 0)
-			return sprintf(label, "position\n");
+			return sysfs_emit(label, "position\n");
 		if (chan->channel == 1)
-			return sprintf(label, "tracking error\n");
+			return sysfs_emit(label, "tracking error\n");
 	}
 	if (chan->type == IIO_ANGL_VEL)
-		return sprintf(label, "velocity\n");
+		return sysfs_emit(label, "velocity\n");
 	if (chan->type == IIO_PHASE)
-		return sprintf(label, "synthetic reference\n");
+		return sysfs_emit(label, "synthetic reference\n");
 	if (chan->type == IIO_ALTVOLTAGE) {
 		if (chan->output)
-			return sprintf(label, "excitation\n");
+			return sysfs_emit(label, "excitation\n");
 		if (chan->channel == 0)
-			return sprintf(label, "monitor signal\n");
+			return sysfs_emit(label, "monitor signal\n");
 		if (chan->channel == 1)
-			return sprintf(label, "cosine\n");
+			return sysfs_emit(label, "cosine\n");
 		if (chan->channel == 2)
-			return sprintf(label, "sine\n");
+			return sysfs_emit(label, "sine\n");
 	}
 
 	return -EINVAL;
@@ -1239,24 +1239,24 @@ static int ad2s1210_read_event_label(struct iio_dev *indio_dev,
 				     char *label)
 {
 	if (chan->type == IIO_ANGL)
-		return sprintf(label, "LOT\n");
+		return sysfs_emit(label, "LOT\n");
 	if (chan->type == IIO_ANGL_VEL)
-		return sprintf(label, "max tracking rate\n");
+		return sysfs_emit(label, "max tracking rate\n");
 	if (chan->type == IIO_PHASE)
-		return sprintf(label, "phase lock\n");
+		return sysfs_emit(label, "phase lock\n");
 	if (chan->type == IIO_ALTVOLTAGE) {
 		if (chan->channel == 0) {
 			if (type == IIO_EV_TYPE_THRESH &&
 			    dir == IIO_EV_DIR_FALLING)
-				return sprintf(label, "LOS\n");
+				return sysfs_emit(label, "LOS\n");
 			if (type == IIO_EV_TYPE_THRESH &&
 			    dir == IIO_EV_DIR_RISING)
-				return sprintf(label, "DOS overrange\n");
+				return sysfs_emit(label, "DOS overrange\n");
 			if (type == IIO_EV_TYPE_MAG)
-				return sprintf(label, "DOS mismatch\n");
+				return sysfs_emit(label, "DOS mismatch\n");
 		}
 		if (chan->channel == 1 || chan->channel == 2)
-			return sprintf(label, "clipped\n");
+			return sysfs_emit(label, "clipped\n");
 	}
 
 	return -EINVAL;

-- 
2.51.0

