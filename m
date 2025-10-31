From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v3 00/10] iio: dac: ad5446: Refactor and add support for
 AD5542
Date: Fri, 31 Oct 2025 12:31:21 +0000
Message-Id: <20251031-dev-add-ad5542-v3-0-d3541036c0e6@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIABmsBGkC/3WMvQ7CIBRGX6Vh9hr+2oKT72EcKNy2JAoGDNE0f
 XdpJx0cvuF8yTkLyZg8ZnJqFpKw+OxjqCAODbGzCROCd5UJp7xllElwWMA4V9e2koOySgvpUFF
 EUqVHwtG/9uDlWnn2+RnTe+8Xtr1/U4UBAzs6pns3UGHo2QRzi9PRxjvZWoV/+VxsnpQdDD44H
 6YMhQMF3o9m0EozVN1PYF3XD1d62QvuAAAA
X-Change-ID: 20251014-dev-add-ad5542-8c8934de80ee
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761913895; l=2096;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=jWiOqwF7DWrzPKoJfUyuoXIXrfNLEtkDJ9x6KviWuyA=;
 b=HdkM0cxlCm7NuBbo9wGO1HJgCRkwWc5wkUaHkJt+OFwAO9XQM9LcDX4iQ7IQ/v36fkuElw8aS
 Ot1UkRIHWfjAFYDMrhM9iDZ1Y0Gt4xM1v5yfiWjzYKmV5ZPLOMqDEzs
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Alright, what was suposed to be a simple one liner patch ended up being
a full refactor (modernization) of the whole thing :). I think the
changes are anyways fairly simple so hopefully nothing was broken.

I'm also aware of the checkpatch failure in Patch 6 ("iio: dac: ad5446:
Separate I2C/SPI into different drivers") but I'm really not seeing the
added value of adding the kconfig help text to the core symbol. 

---
Changes in v3:
- Patch 1:
   * Changed commit message as suggested by Conor;
   * Dropped formatting on the binding description;
   * Used typical Analog title in MAINTAINERS entry.
- Patch 2-4, 6-9
   * New patches.
- Link to v2: https://lore.kernel.org/r/20251023-ad5446-bindings-v2-0-27fab9891e86@analog.com

---
Michael Hennerich (1):
      iio: dac: ad5446: Add AD5542 to the spi id table

Nuno Sá (9):
      dt-bindings: iio: dac: Document AD5446 and similar devices
      iio: dac: ad5446: Use DMA safe buffer for transfers
      iio: dac: ad5446: Don't ignore missing regulator
      iio: dac: ad5446: Move to single chip_info structures
      iio: dac: ad5456: Add missing DT compatibles
      iio: dac: ad5446: Separate I2C/SPI into different drivers
      iio: dac: ad5446: Make use of devm_mutex_init()
      iio: dac: ad5446: Make use of the cleanup helpers
      iio: dac: ad5446: Fix coding style issues

 .../devicetree/bindings/iio/dac/adi,ad5446.yaml    | 138 ++++++
 MAINTAINERS                                        |  12 +
 drivers/iio/dac/Kconfig                            |  31 +-
 drivers/iio/dac/Makefile                           |   2 +
 drivers/iio/dac/ad5446-i2c.c                       |  99 ++++
 drivers/iio/dac/ad5446-spi.c                       | 254 +++++++++++
 drivers/iio/dac/ad5446.c                           | 498 +++------------------
 drivers/iio/dac/ad5446.h                           |  76 ++++
 8 files changed, 663 insertions(+), 447 deletions(-)
---
base-commit: 4b17a60d1e1c2d9d2ccbd58642f6f4ac2fa364ba
change-id: 20251014-dev-add-ad5542-8c8934de80ee
--

Thanks!
- Nuno Sá

