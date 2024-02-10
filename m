From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH v11 0/7] iio: add new backend framework
Date: Sat, 10 Feb 2024 21:57:12 +0100
Message-Id: <20240210-iio-backend-v11-0-f5242a5fb42a@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIACjjx2UC/2XP20rEMBCA4VdZcm0kk8M02SvfQ7yYHLob1EZaC
 crSdzddFBt6MzAD3w9zY0uac1rY+XRjc6p5yWVqC8DDiYUrTZfEc2wHJoVUIMHxnAv3FF7TFDm
 pGICQBjKWNfExpzF/3XPPL22/5uWzzN/3etXb9bcjRdepmgvunE0OtPXo5BNN9FYuj6G8sy1Uz
 R/WAkD22DTsYwoUhQby+oBxj/sPKjYM1hmFQRkS5oCHHZaqx8OG/ThKhd6iUwds/3EbPbYNj2h
 SssFKoeIBuz3GHruG44gYwbgghOjwuq4/ooAvHNkBAAA=
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Frank Rowand <frowand.list@gmail.com>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, andy.shevchenko@gmail.com, 
 Rob Herring <robh@kernel.org>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707598639; l=3748;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=q4V3T80Txq6jSUjNLG3n3P4nfNbu0tPkxZiFNMalY7s=;
 b=mj9zDaKxZirMr/a7AvN8pw/m5jXV47e/D7X7RYcG779EudkgWBg4ysdG3U5bxgi7DRbsLgmgA
 X8iHGYG78QoBmy93uweVsJCYlIA2E+8FNEKXaKtjKvN3Li+nW2ZqmSh
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

v9:
 https://lore.kernel.org/r/20240206-iio-backend-v9-0-df66d159c000@analog.com

v10:
 https://lore.kernel.org/r/20240209-iio-backend-v10-0-3ed842064318@analog.com/

Changes in v11:
 - Patch 6
   * Directly use dev in devm_iio_backend_get();
   * Move comment above the proper place.
 - Patch 7
   * Added blank line between includes (to logically separate them);
   * Move back to 10 millisecond sleep;
   * Constify expected_ver and removed unneeded cast.

Jonathan, the series is based on next-20240202 since it already includes
the io-channels fix Rob applied in his tree. I guess it should land in rc3 so
after you rebase, all patches should apply cleanly (if applying them of course
:)). Let me know if anything fails...

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
 drivers/iio/adc/ad9467.c                           | 267 ++++++++-----
 drivers/iio/adc/adi-axi-adc.c                      | 385 +++++--------------
 drivers/iio/buffer/industrialio-buffer-dmaengine.c |   8 +-
 drivers/iio/industrialio-backend.c                 | 418 +++++++++++++++++++++
 drivers/of/property.c                              |   2 +
 include/linux/iio/adc/adi-axi-adc.h                |  68 ----
 include/linux/iio/backend.h                        |  72 ++++
 include/linux/iio/buffer-dmaengine.h               |   3 +
 14 files changed, 802 insertions(+), 455 deletions(-)
---
base-commit: 076d56d74f17e625b3d63cf4743b3d7d02180379
change-id: 20231219-iio-backend-a3dc1a6a7a58
--

Thanks!
- Nuno Sá

