From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 30 Sep 2025 16:33:15 +0100
Subject: [PATCH 6/9] iio: adc: pac1921: replace sprintf() with sysfs_emit()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250930-dev-sprintf-cleanup-v1-6-5d65d096a952@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759246391; l=1061;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=466V0/0B47csEqruRL0ob9WL3H9t/OmaPrXaNfsTut4=;
 b=aC8PK+hT8/opOKbqTScLPZGn7FfUBiDJH5hEDNdfTS0WHI3CsiB0NI8Gfe++DZySSebxuKkkf
 hal60izx0NtBw+F1QY3qptKS1pc2sm97DaoNVAix7GtMp8PR4jizhE0
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update the pac1921_read_label() function to use sysfs_emit() for
generating labels.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/adc/pac1921.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/adc/pac1921.c b/drivers/iio/adc/pac1921.c
index 35433250b00872edfc9214c632917a8b8ae6e281..a0227b57f23883034f84ac2ada3d4f9319e5047d 100644
--- a/drivers/iio/adc/pac1921.c
+++ b/drivers/iio/adc/pac1921.c
@@ -672,13 +672,13 @@ static int pac1921_read_label(struct iio_dev *indio_dev,
 {
 	switch (chan->channel) {
 	case PAC1921_CHAN_VBUS:
-		return sprintf(label, "vbus\n");
+		return sysfs_emit(label, "vbus\n");
 	case PAC1921_CHAN_VSENSE:
-		return sprintf(label, "vsense\n");
+		return sysfs_emit(label, "vsense\n");
 	case PAC1921_CHAN_CURRENT:
-		return sprintf(label, "current\n");
+		return sysfs_emit(label, "current\n");
 	case PAC1921_CHAN_POWER:
-		return sprintf(label, "power\n");
+		return sysfs_emit(label, "power\n");
 	default:
 		return -EINVAL;
 	}

-- 
2.51.0

