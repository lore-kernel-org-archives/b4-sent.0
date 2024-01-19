From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH v6 0/8] iio: add new backend framework
Date: Fri, 19 Jan 2024 17:00:46 +0100
Message-Id: <20240119-iio-backend-v6-0-189536c35a05@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAK6cqmUC/1XMQQ7CIBCF4as0rMUApbW48h7GxQBjO1HBUEM0T
 e8ubXTR5XvJ/01sxEQ4smM1sYSZRoqhjHZXMTdA6JGTL5spoWqppOFEkVtwNwyeQ+2dhBYO0HS
 sFM+EV3qv2vlS9kDjK6bPime9vD9HiY2TNRfcmA6N1J1tjTpBgHvs9y4+2ALl5h9rIaXaxk2Jr
 UcHXmgJVm/ieZ6/8WKVAOQAAAA=
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Frank Rowand <frowand.list@gmail.com>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, Rob Herring <robh@kernel.org>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705680065; l=3841;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=uIFqdrZKiQUadDSjlozNQF7wYQuFBvh1vrmvuN8UHqA=;
 b=t6xc0+HapkXPl5DUb9pMlOlge9UeuFpW5fpe+MIVPenTyJbsDuUzPlcQbMBQGatBiztkLpBVN
 WUfgt7WPiEWAo3vgB0r4asA9N8th8BspIYrXvdbyyjbp10/797MQ2ML
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

Changes in v6:
 - Patch 2
  * Add '#io-backends-cells' property to the example dts.
 - Patch 6
  * Improve comment on struct iio_backend_buffer_pair;
  * Be consistent with dots in kernel-docs. So dots only exist now in
    description and return. Also be consistent on device managed APIs
    subject and @dev description;
  * Added devm_iio_backend_enable() and hence (and for now)
    iio_backend_disable is static;
  * Fixed __devm_iio_backend_get_from_fwnode_lookup() kernel-doc;
  * Improved english in devm_iio_backend_register() comment;
  * Don't make private data mandatory;
 - Patch 7
  * Use local ad9467_chip_info *info variable;
  * Improve error handling for optional devm_iio_backend_get();
  * Make use of devm_iio_backend_enable().
 - Patch 8
  * Also change string format in version error path.

Not that big of change in this version (more small things). The most
noticeable is perhaps the introduction of devm_iio_backend_enable().

Keeping the block diagram  so we don't have to follow links
to check one of the typical setups.

                                           -------------------------------------------------------
 ------------------                        | -----------         ------------      -------  FPGA |
 |     ADC        |------------------------| | AXI ADC |---------| DMA CORE |------| RAM |       |
 | (Frontend/IIO) | Serial Data (eg: LVDS) | |(backend)|---------|          |------|     |       |
 |                |------------------------| -----------         ------------      -------       |
 ------------------                        -------------------------------------------------------

---
Nuno Sa (7):
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
 drivers/iio/adc/ad9467.c                           | 272 +++++++++-----
 drivers/iio/adc/adi-axi-adc.c                      | 383 +++++--------------
 drivers/iio/buffer/industrialio-buffer-dmaengine.c |   8 +-
 drivers/iio/industrialio-backend.c                 | 412 +++++++++++++++++++++
 drivers/of/property.c                              |   2 +
 include/linux/iio/adc/adi-axi-adc.h                |  68 ----
 include/linux/iio/backend.h                        |  72 ++++
 include/linux/iio/buffer-dmaengine.h               |   3 +
 15 files changed, 806 insertions(+), 462 deletions(-)
---
base-commit: 801590b27bfbdb6721f85e2c3af70e627e52c8d5
change-id: 20231219-iio-backend-a3dc1a6a7a58
--

Thanks!
- Nuno Sá

