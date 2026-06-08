From: Radu Sabau <radu.sabau@analog.com>
Date: Mon, 08 Jun 2026 12:02:54 +0300
Subject: [PATCH] iio: adc: ad_sigma_delta: allow COMPILE_TEST in isolation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260608-ad_sigma_delta_spi-v1-1-61e37666d9b6@analog.com>
X-B4-Tracking: v=1; b=H4sIAD2FJmoC/x2M0QpAQBAAf+XaZ1frRPgV6TpuscXRraTk310ep
 2nmAaHIJNCqByJdLLyHBHmmYFxcmEmzTwwGTYUV1tp5KzxvznpaT2flYJ1EMRnEvCkHSOERaeL
 7n3b9+37rS1+aZAAAAA==
X-Change-ID: 20260608-ad_sigma_delta_spi-6063f200195b
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Radu Sabau <radu.sabau@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780909381; l=1341;
 i=radu.sabau@analog.com; s=20260220; h=from:subject:message-id;
 bh=GA54EjBngw5qAiuNb6r1BBeWyhMJfGxCv8whjAQhc6M=;
 b=UK0M5bL9QqeHBi4QSmvPvewHW+zOL4F9Uxuc/DLQAmRv27fffcJObgR/JhgQlzi0Vk/fZqLBM
 j1b2i/O8jlKDx0qbtSvGu9NMXKY2psENCTp8THEnnAYOQogwIjUOK5S
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=lDPQHgn9jTdt0vo58Na9lLxLaE2mb330if71Cn+EvFU=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20260220 with auth_id=642
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

AD_SIGMA_DELTA is a hidden tristate that can only be enabled by
selecting drivers (AD7124, AD7192, etc.), all of which require SPI.
This prevents compile-testing the library code directly with allmodconfig
or by manually enabling it with COMPILE_TEST.

Add a prompt string guarded by "if COMPILE_TEST" so the symbol becomes
directly selectable when COMPILE_TEST is set.

Also add an explicit "depends on SPI" since the ad_sigma_delta library
directly calls SPI core symbols such as spi_bus_lock(), spi_bus_unlock(),
and spi_sync_locked().

Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
 drivers/iio/adc/Kconfig | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/adc/Kconfig b/drivers/iio/adc/Kconfig
index a9dedbb8eb46..329d1f6e5106 100644
--- a/drivers/iio/adc/Kconfig
+++ b/drivers/iio/adc/Kconfig
@@ -33,7 +33,8 @@ config AB8500_GPADC
 	  and USB voltages integral to the U8500 platform.
 
 config AD_SIGMA_DELTA
-	tristate
+	tristate "Analog Devices Sigma-Delta Modulator support" if COMPILE_TEST
+	depends on SPI
 	select IIO_BUFFER
 	select IIO_BUFFER_DMAENGINE
 	select IIO_TRIGGERED_BUFFER

---
base-commit: 4549871118cf616eecdd2d939f78e3b9e1dddc48
change-id: 20260608-ad_sigma_delta_spi-6063f200195b

Best regards,
-- 
Radu Sabau <radu.sabau@analog.com>

