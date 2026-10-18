From: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
Subject: [PATCH 0/2] staging: iio: addac: adt7316: error code and probe
 cleanups
Date: Sun, 18 Oct 2026 22:41:49 +0100
Message-Id: <20261018-adt7316-error-codes-v1-0-1970b7e242ac@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CQAxA0auQrm3SoiDxKsYFnalaF4xp0ZgQ7
 u4oy7f4f4FQNw04NQu4vi2sTBW8ayDdx+mmaLkaWmp7Jh5wzPNxzz2qe3FMJWvgYeiIREg4CdT
 y6Xq1z/96vmyOlzw0zb8VrOsX1lpCBHcAAAA=
X-Change-ID: 20261018-adt7316-error-codes-48500bb0b1cb
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux@analog.com, linux-iio@vger.kernel.org, 
 linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792359739; l=1590;
 i=raffaele.tranfaglia@gmail.com; s=20261011; h=from:subject:message-id;
 bh=6nfRQdeF7YPs+cvmTHFcNKp9NpREBzOxIrnig+osLr8=;
 b=8XdQsDFcKXECYP0TbCWHKIFERLwFeJRpzhbVsy0z3N1g1MzaCUztOyTKs0N6rLIofHBk635aP
 Hu319KJj3XrCUyhMjZqeh49SPKpHVZrA9+xOOlBNHEea2fylCGV0SQ9
X-Developer-Key: i=raffaele.tranfaglia@gmail.com; a=ed25519;
 pk=mweuSGNM6vguCTdqa+aiHwMXdgk70suj2wolzCp6XGM=
X-Endpoint-Received: by B4 Relay for raffaele.tranfaglia@gmail.com/20261011 with auth_id=1160
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two small cleanups for the adt7316 driver.

Patch 1 makes the driver return the error codes reported by the bus
helpers instead of replacing them with -EIO, so callers see the
actual cause of a failure.

Patch 2 removes the dev_info() printed on successful probe, as
drivers that are working properly should be quiet (see
Documentation/process/coding-style.rst).

Tested on arm64 QEMU, with i2c-stub providing the device:

  insmod i2c-stub.ko chip_addr=0x48
  i2cset -y 0 0x48 0x4d 0x01
  echo adt7316 0x48 > /sys/bus/i2c/devices/i2c-0/new_device

- probe succeeds and no longer prints a message
- device_id reads back the stub register value
- writing 0/1 to "enabled" updates CONFIG1 (0x18)

Error path, instantiating the device where no stub chip exists:

  echo adt7316 0x49 > /sys/bus/i2c/devices/i2c-0/new_device

  before: probe with driver adt7316 failed with error -5
  after:  probe with driver adt7316 rejects match -19

Signed-off-by: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>

Signed-off-by: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
---
Raffaele Tranfaglia (2):
      staging: iio: addac: adt7316: propagate bus error codes
      staging: iio: addac: adt7316: drop informational message in probe

 drivers/staging/iio/addac/adt7316.c | 91 ++++++++++++++++++-------------------
 1 file changed, 43 insertions(+), 48 deletions(-)
---
base-commit: 6a27f3a7d1063aec5aa3d9370161e850fc3a85dd
change-id: 20261018-adt7316-error-codes-48500bb0b1cb

Best regards,
--  
Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>

