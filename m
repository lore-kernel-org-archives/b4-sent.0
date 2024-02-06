From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH v9 0/7] iio: add new backend framework
Date: Tue, 06 Feb 2024 11:08:23 +0100
Message-Id: <20240206-iio-backend-v9-0-df66d159c000@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIABcFwmUC/2XPzWoDIRSG4VsJrmvR489oVr2PksVRzyTSdiwzR
 VLC3Hud0NLIbITvwPOCN7bQnGlhx8ONzVTzksvUhn86sHjB6Uw8p7YZCFASpOc5Fx4wvtGUOKo
 UJVoc0DjWxOdMY77ea6+nti95+Srz9z1e9Xb97YDoOlVzwb135KV2wXp4wQnfy/k5lg+2har5w
 1pICT02DYdEEZPQEoPeYfuI+x9U27B03igblUFhdnh4wKB6PGw4jCMoG5z1aofdP25Pj13DozV
 ELjoQKnV4XdcfhACDTJsBAAA=
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Frank Rowand <frowand.list@gmail.com>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, andy.shevchenko@gmail.com, 
 Rob Herring <robh@kernel.org>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707214121; l=4040;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=OzYvq8VgwA+aNjVyozACROn98br9x+rokfdEO0b4lSQ=;
 b=5lihuj2lIqcxnVBnVjn3xsZnY8lbBZOm5Uk9H//xDaBJnjvBcKIMo6LhyWF5PJUyYEJcNdQYs
 bg3D12RgtHJAQeHf4uBJaTP1vAB4Z/4kD8Xftjv96CmyigSu+oCh00x
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

v7
 https://lore.kernel.org/r/20240123-iio-backend-v7-0-1bff236b8693@analog.com

v8:
 https://lore.kernel.org/r/20240202-iio-backend-v8-0-f65ee8c8203d@analog.com

Changes in v9:
 - Patch 2
   * io-backends-cells > io-backend-cells in both the property and example;
   * Add proper ':' termination.  
 - Patch 5
   * Adapted Copyright (2024 included);
   * Added missing headers;
   * Changed log pr_* to dev_*;
   * Allocate first struct iio_backend_buffer_pair and error out in failure
     (before we could be left with a buffer and not freeing it);
   * Fixed io-backends-names > io-backend-names;
   * Reworked getting the index when 'name' is given as suggested by Andy. 
   * Turned dev_dbg() -> dev_err() after fwnode_find_reference() as
     the optional get was dropped;
   * Used cleanup.h everywhere for consistency.

Jonathan, the series is based on next-20240202 since it already includes
the io-channels fix Rob applied in his tree. I guess it should land in rc3 so
after you rebase, all patches should apply cleanly (if applying them of course
:)). Let me know if anything fails...

(also dropped the devlink Reviewers from the Cc list as that patch was
dropped).

Keeping the block diagram  so we don't have to follow links
to check one of the typical setups.

                                           -------------------------------------------------------
 ------------------                        | -----------         ------------      -------  FPGA |
 |     ADC        |------------------------| | AXI ADC |---------| DMA CORE |------| RAM |       |
 | (Frontend/IIO) | Serial Data (eg: LVDS) | |(backend)|---------|          |------|     |       |
 |                |------------------------| -----------         ------------      -------       |
 ------------------                        -------------------------------------------------------

---
Nuno Sa (6):
      dt-bindings: adc: ad9467: add new io-backend property
      dt-bindings: adc: axi-adc: update bindings for backend framework
      iio: buffer-dmaengine: export buffer alloc and free functions
      iio: add the IIO backend framework
      iio: adc: ad9467: convert to backend framework
      iio: adc: adi-axi-adc: move to backend framework

Olivier Moysan (1):
      of: property: add device link support for io-backends

 .../devicetree/bindings/iio/adc/adi,ad9467.yaml    |   4 +
 .../devicetree/bindings/iio/adc/adi,axi-adc.yaml   |   8 +-
 MAINTAINERS                                        |   8 +
 drivers/iio/Kconfig                                |   9 +
 drivers/iio/Makefile                               |   1 +
 drivers/iio/adc/Kconfig                            |   4 +-
 drivers/iio/adc/ad9467.c                           | 268 ++++++++-----
 drivers/iio/adc/adi-axi-adc.c                      | 379 +++++--------------
 drivers/iio/buffer/industrialio-buffer-dmaengine.c |   8 +-
 drivers/iio/industrialio-backend.c                 | 414 +++++++++++++++++++++
 drivers/of/property.c                              |   2 +
 include/linux/iio/adc/adi-axi-adc.h                |  68 ----
 include/linux/iio/backend.h                        |  72 ++++
 include/linux/iio/buffer-dmaengine.h               |   3 +
 14 files changed, 795 insertions(+), 453 deletions(-)
---
base-commit: 076d56d74f17e625b3d63cf4743b3d7d02180379
change-id: 20231219-iio-backend-a3dc1a6a7a58
--

Thanks!
- Nuno Sá

