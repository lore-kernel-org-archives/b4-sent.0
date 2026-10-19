From: Vidhu Sarwal <vidhu.linux@gmail.com>
Subject: [PATCH 0/3] iio: proximity: Add Benewake TF-Luna LiDAR driver
Date: Tue, 20 Oct 2026 00:03:40 +0530
Message-Id: <20261020-tf-luna-v1-0-53a88f93db24@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMywrCMBBFf6XM2sEkkPr4FXGRpNN2RKaSSUUo/
 XcTXZ7LOXcDpcykcO02yPRm5UUq2EMHaQ4yEfJQGZxxvTX2gmXE5yoByfVnT8afzOCh2q9MI39
 +T7f7n3WND0ql5c2IQQljDpLmNjEvx0JaWCbY9y+uCS09iQAAAA==
X-Change-ID: 20261019-tf-luna-e2685e0570d5
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Vidhu Sarwal <vidhu.linux@gmail.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-iio@vger.kernel.org, Shuah Khan <skhan@linuxfoundation.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792434836; l=2129;
 i=vidhu.linux@gmail.com; s=20260713; h=from:subject:message-id;
 bh=AqRUiR4PUtUlWpRVFT94V35Qa7422g3L1JI66lW1jU0=;
 b=xUYl31z5VBB+JqcWZAzEqY1h+b++lrUGMv2yptbu+6XiTcn6WTk10oCU6DJ8hj/ABvzH8lDUw
 v1S/yr78vnmA8OQUPtEOmHaGk0cM0KCNGeIC6O7h8Gtp1ibpyoN9xtg
X-Developer-Key: i=vidhu.linux@gmail.com; a=ed25519;
 pk=xDu3Cbesz76CQXwY8lteI74n3ELVIV7wCsuYAvcX1Q4=
X-Endpoint-Received: by B4 Relay for vidhu.linux@gmail.com/20260713 with auth_id=869
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the Benewake TF-Luna, a single point ToF
 LiDAR distance sensor with a range of 0.2 m to 8 m. The
sensor uses either UART or I2C, selected by a strap pin at power-up.
This series covers the I2C interface only.

Patch 1 adds the vendor prefix, patch 2 adds the binding and patch 3 adds the
driver, which reports distance using an IIO_DISTANCE channel.

The driver keeps the sensor in trigger mode and starts a measurement
per read. The manual warns that reads in continuous mode can race with
the sensor updating its result registers unless they are synchronised
to the data ready output, which the driver does not use yet.

Two issues I faced with the hardware that the manual does not mention:
- The sensor silently drops a register write that arrives right after
  another one, so probe reads the mode back after setting it.
- The boot time is not documented. I was able to measure 350ms after a
  reboot before the registers read back correctly, so probe waits
  500 ms after enabling the supply, keeping some buffer.

Later on I plan to add buffered caputure using data ready interrupt and 
runtime PM in a follow up series. 

This was tested on hardware using Raspberry Pi 4 and with firmware v3.6.0
built out of tree on the 6.18 RPi kernel both via new_device as well as a 
DT Overlay.

---
Vidhu Sarwal (3):
      dt-bindings: vendor-prefixes: Add Benewake
      dt-bindings: iio: proximity: Add Benewake TF-Luna
      iio: proximity: Add Benewake TF-Luna LiDAR driver

 .../bindings/iio/proximity/benewake,tf-luna.yaml   |  58 +++++
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 MAINTAINERS                                        |   7 +
 drivers/iio/proximity/Kconfig                      |  11 +
 drivers/iio/proximity/Makefile                     |   1 +
 drivers/iio/proximity/tf-luna.c                    | 254 +++++++++++++++++++++
 6 files changed, 333 insertions(+)
---
base-commit: 43ffda3c7f8456bbe641ae8249a077a361b97880
change-id: 20261019-tf-luna-e2685e0570d5

Best regards,
--  
Vidhu Sarwal <vidhu.linux@gmail.com>

