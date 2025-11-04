From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v4 00/12] iio: dac: ad5446: Refactor and add support for
 AD5542
Date: Tue, 04 Nov 2025 15:35:05 +0000
Message-Id: <20251104-dev-add-ad5542-v4-0-6fe35458bf8c@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIACkdCmkC/3WOSw6CMBBAr2K6dkx/QHHlPYyL0hmgiRZDTaMh3
 N3CCkNczOLN5L3MxCKNniI7HyY2UvLRDyGDPh6Y623oCDxmZpLLQnChASmBRcxTFFqCcaZWGsl
 wIpal50itf6/B6y1z7+NrGD9rP4ll+zeVBAhwLYq6woYryy822PvQndzwYEsryY0v1eJpXULjA
 /rQRUgSOMiqtU1takGm3AXUJqDE7gGVfVSFzsfScfr153n+Ao2aH1UuAQAA
X-Change-ID: 20251014-dev-add-ad5542-8c8934de80ee
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762270508; l=2152;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=7iEpKsNY9UcWlnJ7pT3KJl2nLgV7qbqXVE2QPMDs5mw=;
 b=5L7Odu9gQy7Jw8c3ekOOT4+mL/wwB7bK3LUouy2Cb05NXb/eFdlo4hzzZbU6bl4EE/Tisv6Z6
 DcUNI/8HWNXDzsY3EeoY/o0+UTmVq4d+HliIoZF4+WU3AKDGpbDomA8
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Alright, what was suposed to be a simple one liner patch ended up being
a full refactor (modernization) of the whole thing :). I think the
changes are anyways fairly simple so hopefully nothing was broken.

I'm also aware of the checkpatch failure in Patch 7 ("iio: dac: ad5446:
Separate I2C/SPI into different drivers") but I'm really not seeing the
added value of adding the kconfig help text to the core symbol. 

---
Changes in v4:
- Patch 3
  * New patch
- Patch 6
  * Include err.h and asm/byteorder;
  * Changed Module description as suggested by Jonathan;
- Patch 8
  * New patch
- Link to v3: https://lore.kernel.org/r/20251031-dev-add-ad5542-v3-0-d3541036c0e6@analog.com

---
Michael Hennerich (1):
      iio: dac: ad5446: Add AD5542 to the spi id table

Nuno Sá (11):
      dt-bindings: iio: dac: Document AD5446 and similar devices
      iio: dac: ad5446: Use DMA safe buffer for transfers
      iio: dac: ad5446: Drop duplicated spi_id entry
      iio: dac: ad5446: Don't ignore missing regulator
      iio: dac: ad5446: Move to single chip_info structures
      iio: dac: ad5456: Add missing DT compatibles
      iio: dac: ad5446: Separate I2C/SPI into different drivers
      iio: dac: ad5446: Make use of devm_mutex_init()
      iio: dac: ad5446: Make use of the cleanup helpers
      iio: dac: ad5446: Refactor header inclusion
      iio: dac: ad5446: Fix coding style issues

 .../devicetree/bindings/iio/dac/adi,ad5446.yaml    | 138 ++++++
 MAINTAINERS                                        |  12 +
 drivers/iio/dac/Kconfig                            |  31 +-
 drivers/iio/dac/Makefile                           |   2 +
 drivers/iio/dac/ad5446-i2c.c                       | 102 +++++
 drivers/iio/dac/ad5446-spi.c                       | 252 ++++++++++
 drivers/iio/dac/ad5446.c                           | 506 +++------------------
 drivers/iio/dac/ad5446.h                           |  76 ++++
 8 files changed, 664 insertions(+), 455 deletions(-)
---
base-commit: 4b17a60d1e1c2d9d2ccbd58642f6f4ac2fa364ba
change-id: 20251014-dev-add-ad5542-8c8934de80ee
--

Thanks!
- Nuno Sá

