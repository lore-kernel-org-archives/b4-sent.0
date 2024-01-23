From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH v7 0/9] iio: add new backend framework
Date: Tue, 23 Jan 2024 16:14:21 +0100
Message-Id: <20240123-iio-backend-v7-0-1bff236b8693@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAM3Xr2UC/2XP0QrCIBTG8VcJrzPUqZtd9R7RxZmeNqk0XEgx9
 u65UdDo8jvw+8MZyYDJ40D2m5EkzH7wMZRRbzfE9hA6pN6VTQQTFRfcUO8jbcFeMDgKlbMcNNS
 gGlLEPeHZP5fa8VR274dHTK8lnuV8/XQEW3WypIwa06Dhsmm1EQcIcI3dzsYbmUNZfbFknIs1V
 gW3Di04Jjm08g/rX7z+IOuCeWNUpW2lgKkVnqbpDQwhMgwhAQAA
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Frank Rowand <frowand.list@gmail.com>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, 
 Saravana Kannan <saravanak@google.com>, Rob Herring <robh@kernel.org>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706022871; l=3552;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=FMVHyscAeXfhsQ1KbZF91wY5MqXz7Hag/KmnGhBwgxU=;
 b=yWliTBrimixhlKPKBZV5iNsTKliciXYIpPTYS9UJPPCo4C8F2GN9ycME/f5B9Usx5AufGz2Yi
 6SHUBoJ8hIFBSm61mcqf5H5YYNxnBso3HijVmNsKn2TFraFoB4gEp6B
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

v1:
 https://lore.kernel.org/linux-iio/20231204144925.4fe9922f@jic23-huawei/T/#m222f5175273b81dbfe40b7f0daffcdc67d6cb8ff

v2:
 https://lore.kernel.org/r/20231208-dev-iio-backend-v2-0-5450951895e1@analog.com

v3:
 https://lore.kernel.org/linux-iio/20231213-dev-iio-backend-v3-0-bb9f12a5c6dc@analog.com/

v4:
 https://lore.kernel.org/r/20231220-iio-backend-v4-0-998e9148b692@analog.com

v5:
 https://lore.kernel.org/r/20240112-iio-backend-v5-0-bdecad041ab4@analog.com

v6:
 https://lore.kernel.org/r/20240119-iio-backend-v6-0-189536c35a05@analog.com

Changes in v7:
 - Patch 1
  * New patch.
 - Patch 3
  * Added Rob's tag.
 - Patch 5
  * Renamed '#io-backends-cells' -> '#io-backend-cells'.
 - Patch 8
  * Added a statement in the commit message about the ABI breakage;
  * Used local info variables in a couple of forgotten places.

Rob, I was thinking in sending a different patch for the io-channels fix
but then I changed my mind and included it in this series as it is then easier
to apply the io-backends patch on top of it. If you prefer for me to
send that patch alone, I'll do so.

Keeping the block diagram  so we don't have to follow links
to check one of the typical setups.

                                           -------------------------------------------------------
 ------------------                        | -----------         ------------      -------  FPGA |
 |     ADC        |------------------------| | AXI ADC |---------| DMA CORE |------| RAM |       |
 | (Frontend/IIO) | Serial Data (eg: LVDS) | |(backend)|---------|          |------|     |       |
 |                |------------------------| -----------         ------------      -------       |
 ------------------                        -------------------------------------------------------

---
Nuno Sa (8):
      of: property: fix typo in io-channels
      dt-bindings: adc: ad9467: add new io-backend property
      dt-bindings: adc: axi-adc: update bindings for backend framework
      driver: core: allow modifying device_links flags
      iio: buffer-dmaengine: export buffer alloc and free functions
      iio: add the IIO backend framework
      iio: adc: ad9467: convert to backend framework
      iio: adc: adi-axi-adc: move to backend framework

Olivier Moysan (1):
      of: property: add device link support for io-backends

 .../devicetree/bindings/iio/adc/adi,ad9467.yaml    |   4 +
 .../devicetree/bindings/iio/adc/adi,axi-adc.yaml   |   8 +-
 MAINTAINERS                                        |   8 +
 drivers/base/core.c                                |  14 +-
 drivers/iio/Kconfig                                |   9 +
 drivers/iio/Makefile                               |   1 +
 drivers/iio/adc/Kconfig                            |   4 +-
 drivers/iio/adc/ad9467.c                           | 268 +++++++++-----
 drivers/iio/adc/adi-axi-adc.c                      | 383 +++++--------------
 drivers/iio/buffer/industrialio-buffer-dmaengine.c |   8 +-
 drivers/iio/industrialio-backend.c                 | 412 +++++++++++++++++++++
 drivers/of/property.c                              |   4 +-
 include/linux/iio/adc/adi-axi-adc.h                |  68 ----
 include/linux/iio/backend.h                        |  72 ++++
 include/linux/iio/buffer-dmaengine.h               |   3 +
 15 files changed, 805 insertions(+), 461 deletions(-)
---
base-commit: 824adc9cc314be065db726e30fae876c87660775
change-id: 20231219-iio-backend-a3dc1a6a7a58
--

Thanks!
- Nuno Sá

