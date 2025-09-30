From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 30 Sep 2025 16:33:17 +0100
Subject: [PATCH 8/9] iio: position: hid-sensor-custom-intel-hinge: replace
 sprintf() with sysfs_emit()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250930-dev-sprintf-cleanup-v1-8-5d65d096a952@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759246391; l=913;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=uBtD7rHGY3JgmTsmJdv+GuLLNqnv03EVwKBOigNns3k=;
 b=n3RoQwDKC0s7FIS6Kjp9M1VCu+DSp/1GKeuNZC7e3Gb1aZpx30Sl6UWBiJdjo3JWAWFBZQK1r
 QMhlaWYj35pDGfXEQ2hV/M7ic/pJoAJOewYfyueZ11cZvjjdJoYvi1u
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update the hinge_read_label() function to use sysfs_emit() for generating
labels.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/position/hid-sensor-custom-intel-hinge.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/position/hid-sensor-custom-intel-hinge.c b/drivers/iio/position/hid-sensor-custom-intel-hinge.c
index bff7039690ac33bcc9747add8055023dd5a1f3ab..a26d391661fdb64cc34c8c0e163333c01c1f069b 100644
--- a/drivers/iio/position/hid-sensor-custom-intel-hinge.c
+++ b/drivers/iio/position/hid-sensor-custom-intel-hinge.c
@@ -176,7 +176,7 @@ static int hinge_read_label(struct iio_dev *indio_dev,
 {
 	struct hinge_state *st = iio_priv(indio_dev);
 
-	return sprintf(label, "%s\n", st->labels[chan->channel]);
+	return sysfs_emit(label, "%s\n", st->labels[chan->channel]);
 }
 
 static const struct iio_info hinge_info = {

-- 
2.51.0

