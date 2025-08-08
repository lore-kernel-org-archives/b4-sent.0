From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Fri, 08 Aug 2025 17:12:33 +0100
Subject: [PATCH] iio: imu: adis16475: remove extra line
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250808-adis15475-extraline-v1-1-e3259a466e95@analog.com>
X-B4-Tracking: v=1; b=H4sIAPAhlmgC/x3MQQqAIBBA0avIrBswa8q6SrSQmmogLDRCiO6et
 HyL/x+IHIQj9OqBwLdEOXxGWSiYNudXRpmzwWhD2mqLbpZYUt0ScrqC28UzUlUzNZ1dKtdCLs/
 Ai6T/Oozv+wGh5rU3ZQAAAA==
X-Change-ID: 20250808-adis15475-extraline-534e5698f3a7
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754669566; l=741;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=npUHJTmNVT2sPd9SnTgs4zrg1w76PUt3kTdlnAH1txE=;
 b=aGLHxdtRM+AYQt22tLWAfpXa4q/wiaOMtOjW0rDVpMVJ1RNJNsukV2VJweOFZTTPTQ8jDjXul
 +12ypwOeitsDdEKxVCkQFkpkEByPvAtxDXYko52+TtQagUz4WifmFfq
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove extra line before adis16475_probe().

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/imu/adis16475.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/drivers/iio/imu/adis16475.c b/drivers/iio/imu/adis16475.c
index 924395b7e3b45dd3a6459d6eb788fa2ec86c4a29..ab39bea1e729ea8abb56dbbca3d5305dc1973083 100644
--- a/drivers/iio/imu/adis16475.c
+++ b/drivers/iio/imu/adis16475.c
@@ -1930,7 +1930,6 @@ static int adis16475_config_irq_pin(struct adis16475 *st)
 	return 0;
 }
 
-
 static int adis16475_probe(struct spi_device *spi)
 {
 	struct iio_dev *indio_dev;

---
base-commit: 6408dba154079656d069a6a25fb3a8954959474c
change-id: 20250808-adis15475-extraline-534e5698f3a7
--

Thanks!
- Nuno Sá

