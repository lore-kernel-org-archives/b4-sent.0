From: Alexis Bouzigues <BouziguesAlexis@JohnDeere.com>
Date: Wed, 07 Oct 2026 09:34:16 -0500
Subject: [PATCH] iio: accel: adxl345: select IIO_BUFFER and IIO_KFIFO_BUF
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261007-fix-adxl345-buffer-deps-review-v1-1-0c94c8d0443a@JohnDeere.com>
X-B4-Tracking: v=1; b=H4sIAGdYxmoC/x2Nyw6CMBAAf4Xs2Y1tBYz+ivGwbbewiRay9UFC+
 HeLxznMzAqFVbjAtVlB+SNFplzBHhoII+WBUWJlcMb11pgzJlmQ4vI4tR36d0qsGHkuuMv8xf5
 CzrZsuhgIamRWrsZ/cLtX9lQYvVIO456dVAbJxyeVFyts2w8mY0JckAAAAA==
To: Jonathan Cameron <jic23@kernel.org>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>
Cc: David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Lothar Rubusch <l.rubusch@gmail.com>, 
 linux@analog.com, linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Alexis Bouzigues <BouziguesAlexis@JohnDeere.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791383655; l=1713;
 i=BouziguesAlexis@JohnDeere.com; s=20260527; h=from:subject:message-id;
 bh=s/yXKM6ln4x9Rm+hNY2FnXFaP1MQgX8qNBneutc4oYU=;
 b=aKlLVve0fWP0+XrcqwgW4kxbyVmfM7iWxiONstwX/yYmAoM9Vnsb6im4zKzYpqzsY7/1IodZR
 ew04scKnQPeBoJlKi9+E3W8zZHbppfifc9IefWhq9uJNUqbYHG4ePB5
X-Developer-Key: i=BouziguesAlexis@JohnDeere.com; a=ed25519;
 pk=5KJ7ArL00x5flpPhi9zRLC2p88V1rZXDQ5SXhpRvTDk=
X-Endpoint-Received: by B4 Relay for BouziguesAlexis@JohnDeere.com/20260527 with auth_id=797
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since the addition of FIFO watermark support, adxl345_core.c calls
devm_iio_kfifo_buffer_setup() and iio_push_to_buffers(), but the
ADXL345 Kconfig entry does not select IIO_BUFFER and IIO_KFIFO_BUF.
Building with CONFIG_ADXL345_I2C=y and CONFIG_IIO_BUFFER=n fails to
link:

  ld: drivers/iio/accel/adxl345_core.o: in function `adxl345_irq_handler':
  adxl345_core.c:(.text+0x145c): undefined reference to `iio_push_to_buffers'
  ld: drivers/iio/accel/adxl345_core.o: in function `adxl345_core_probe':
  adxl345_core.c:(.text+0x1db6): undefined reference to `devm_iio_kfifo_buffer_setup_ext'

Add the missing selects on the hidden ADXL345 core symbol, as done for
ADXL367, ADXL372 and ADXL380, so both the I2C and SPI front-ends are
covered.

Fixes: cf04212d1fe7 ("iio: accel: adxl345: add FIFO with watermark events")
Assisted-by: LLM
Signed-off-by: Alexis Bouzigues <BouziguesAlexis@JohnDeere.com>
---
Add the buffer selections required by the ADXL345 FIFO support.
The shared core symbol covers both I2C and SPI frontends.
---
 drivers/iio/accel/Kconfig | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/iio/accel/Kconfig b/drivers/iio/accel/Kconfig
index 4094299e2ed8..fc130854af71 100644
--- a/drivers/iio/accel/Kconfig
+++ b/drivers/iio/accel/Kconfig
@@ -61,6 +61,8 @@ config ADXL313_SPI
 
 config ADXL345
 	tristate
+	select IIO_BUFFER
+	select IIO_KFIFO_BUF
 
 config ADXL345_I2C
 	tristate "Analog Devices ADXL345 3-Axis Digital Accelerometer I2C Driver"

---
base-commit: 7b63ef2d55f24519e7e9e5f4d15dbea03f126e40
change-id: 20261007-fix-adxl345-buffer-deps-review-69a214e05dca

Best regards,
-- 
Alexis Bouzigues <BouziguesAlexis@JohnDeere.com>

