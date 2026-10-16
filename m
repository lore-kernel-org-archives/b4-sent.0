From: Bruce Tsao <bruce.tsao@analog.com>
Subject: [PATCH 0/2] iio: dac: add support for AD5413
Date: Sat, 17 Oct 2026 03:23:52 +0800
Message-Id: <20261017-ad5413-upstream-v1-0-61f40c8fef25@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQ5AMBBA0avIrDVpqRJXEYvSGWahpEUkjbtrL
 N/i/wQRA2OEvkgQ8ObIu89QZQHzav2Cgl02VLIySqpWWNdoVYvriGdAuwnqjNFEpMlNkKsjIPH
 zH4fxfT+j/ii+YQAAAA==
X-Change-ID: 20261017-ad5413-upstream-f8664fff4fdb
To: Jonathan Cameron <jic23@kernel.org>
Cc: linux-iio@vger.kernel.org, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Bruce Tsao <bruce.tsao@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792178669; l=1183;
 i=bruce.tsao@analog.com; s=20261017; h=from:subject:message-id;
 bh=BGiuguw2nDrUMZhZt/fC2z/TQeWYzLVwuYjJIurNctM=;
 b=67wYDI8ghJZc/4BM1JHb87+Z0LrADI+BD0Z4dwLGt5zWYA8BRkm3upxR1HCfkIytOhgFzZ6KB
 l+gvS4+KK8RC9cYsyFbp8QvtKPHGI3AGgPXjWVqcIyAHK8iUaZko7zH
X-Developer-Key: i=bruce.tsao@analog.com; a=ed25519;
 pk=dT7qI1i91oYvnYmY2ljmdZ0ZQoCZIzrQ8hnsyjuBedg=
X-Endpoint-Received: by B4 Relay for bruce.tsao@analog.com/20261017 with auth_id=1215
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the Analog Devices AD5413: a single-channel,
14-bit, serial-input DAC with software-selectable voltage (+/-10.5 V) and
current (0-24 mA) outputs. The SPI interface runs in mode 1 and carries a
CRC-8 on every frame, which the device has enabled out of reset.

Patch 1 documents the device-tree binding; patch 2 adds the IIO driver.

Tested on an EVAL-AD5413SDZ with a Raspberry Pi 5 and an NXP i.MX93 FRDM
board (probe, voltage- and current-output, scale/offset, powerdown/resume).

Signed-off-by: Bruce Tsao <bruce.tsao@analog.com>
---
Bruce Tsao (2):
      dt-bindings: iio: dac: Document Analog Devices AD5413 single-channel DAC
      iio: dac: add AD5413 driver

 .../devicetree/bindings/iio/dac/adi,ad5413.yaml    | 101 ++++
 drivers/iio/dac/Kconfig                            |  11 +
 drivers/iio/dac/Makefile                           |   1 +
 drivers/iio/dac/ad5413.c                           | 666 +++++++++++++++++++++
 4 files changed, 779 insertions(+)
---
base-commit: a3b3580713f3ac5a32dc2874ee546828977a1d68
change-id: 20261017-ad5413-upstream-f8664fff4fdb

Best regards,
-- 
Bruce Tsao <bruce.tsao@analog.com>

