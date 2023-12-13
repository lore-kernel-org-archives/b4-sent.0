From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH v3 0/8] iio: add new backend framework
Date: Wed, 13 Dec 2023 16:02:31 +0100
Message-Id: <20231213-dev-iio-backend-v3-0-bb9f12a5c6dc@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAIfHeWUC/2WNQQ6CMBBFr0Jm7Zi20AiuvIdhUdoBJmpLWtNoC
 He34tLle8l/f4VEkSnBuVohUubEwReoDxXY2fiJkF1hUELVUiqBjjIyBxyMvZF36GQzNKfaSNe
 NUFZLpJFfe/HaF545PUN87wdZfe2vpUT718oKBepGi07LttMkL8abe5iONjyg37btAykssoGvA
 AAA
To: devicetree@vger.kernel.org, linux-iio@vger.kernel.org
Cc: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Frank Rowand <frowand.list@gmail.com>, Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Olivier Moysan <olivier.moysan@foss.st.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1702479785; l=3859;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=2eAeAB2OSKA3kMHm2dotaI1S60CZCs+9Bu00lkPC4pg=;
 b=ZdBPKtdhFrWiX5W0MlzQLvi5FZAO29nTrtsbsIrwQyNVmksYsFYN3aNJp7tbTT/Pzydz4Kyu6
 Ro2nEf24vrgDj2mOP5fBmOfBhshsYQ05u5TeNgbAzwgpVYH7RLxq+nw
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

v1:
 https://lore.kernel.org/linux-iio/20231204144925.4fe9922f@jic23-huawei/T/#m222f5175273b81dbfe40b7f0daffcdc67d6cb8ff

v2:
 https://lore.kernel.org/r/20231208-dev-iio-backend-v2-0-5450951895e1@analog.com

Changes in v3:
- Patch 1:
 * Use proposed generic schema [1]. Also make it a required property;
 * Improved the commit message.
- Patch 2:
 * Improved commit message.
- Patch 4:
 * Namespace all IIO DMAENGINE buffer exports;
 * Removed unrelated new line removal change.
- Patch 5:
 * Namespace all IIO backend exports.
- Patch 6:
 * Set backend.h in alphabetical order;
 * Import IIO backend namespace.
- Patch 7:
 * Don't depend on OF in kbuild anymore;
 * Import IIO backend namespace.

For the bindings patches, I tried not to enter into much details about
the IIO framework as I think specifics of the implementation don't care
from the bindings perspective. Hopefully the commit messages are good
enough.

I'm also aware that patch 1 is not backward compatible but we are
anyways doing it on the driver side (and on the driver the property is
indeed required). Anyways, just let me know if making the property
required is not acceptable (I'm fairly confident no one was using the
upstream version of the driver and so validating devicetrees for it). 

Keeping the block diagram in v3's cover so we don't have to follow links
to check the one of the typicals setups. 

                                           -------------------------------------------------------
 ------------------                        | -----------         ------------      -------  FPGA |
 |     ADC        |------------------------| | AXI ADC |---------| DMA CORE |------| RAM |       |
 | (Frontend/IIO) | Serial Data (eg: LVDS) | |(backend)|---------|          |------|     |       |
 |                |------------------------| -----------         ------------      -------       |
 ------------------                        -------------------------------------------------------
 
Jonathan, I was also tempted in including the diagram in the source
file. Would that be a good idea?

[1]: https://github.com/devicetree-org/dt-schema/pull/120

---
Nuno Sa (7):
      dt-bindings: adc: ad9467: add new io-backend property
      dt-bindings: adc: axi-adc: deprecate 'adi,adc-dev'
      driver: core: allow modifying device_links flags
      iio: buffer-dmaengine: export buffer alloc and free functions
      iio: add the IIO backend framework
      iio: adc: ad9467: convert to backend framework
      iio: adc: adi-axi-adc: move to backend framework

Olivier Moysan (1):
      of: property: add device link support for io-backends

 .../devicetree/bindings/iio/adc/adi,ad9467.yaml    |   5 +
 .../devicetree/bindings/iio/adc/adi,axi-adc.yaml   |   4 +-
 MAINTAINERS                                        |   8 +
 drivers/base/core.c                                |  14 +-
 drivers/iio/Kconfig                                |   5 +
 drivers/iio/Makefile                               |   1 +
 drivers/iio/adc/Kconfig                            |   4 +-
 drivers/iio/adc/ad9467.c                           | 243 +++++++------
 drivers/iio/adc/adi-axi-adc.c                      | 381 +++++---------------
 drivers/iio/buffer/industrialio-buffer-dmaengine.c |   8 +-
 drivers/iio/industrialio-backend.c                 | 386 +++++++++++++++++++++
 drivers/of/property.c                              |   2 +
 include/linux/iio/adc/adi-axi-adc.h                |  68 ----
 include/linux/iio/backend.h                        |  68 ++++
 include/linux/iio/buffer-dmaengine.h               |   3 +
 15 files changed, 730 insertions(+), 470 deletions(-)
---
base-commit: 3cde3cdb0b23151dbaac476b17eb1868335993aa
change-id: 20231120-dev-iio-backend-d14b473a1d9f
--

Thanks!
- Nuno Sá

