From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH v2 0/7] iio: ad9467: support interface tuning
Date: Fri, 26 Apr 2024 17:42:09 +0200
Message-Id: <20240426-ad9467-new-features-v2-0-6361fc3ba1cc@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAFHLK2YC/32NQQ6CMBBFr0Jm7ZhSoagr72FYDHQGmmhrWkQN4
 e5WDuDyveS/v0Di6DjBuVgg8uySCz6D3hXQj+QHRmczg1a6UlV5QrKnyjTo+YXCND0jJ5ROOqK
 arSgDefmILO69Va9t5tGlKcTPdjKXP/u/N5eo8MCN0UcRY2u+kKdbGPZ9uEO7rusXFM/mSbcAA
 AA=
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Jonathan Cameron <Jonathan.Cameron@huawei.com>, 
 Alexandru Ardelean <alexandru.ardelean@analog.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, Nuno Sa <nuno.sa@analog.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1714146147; l=1945;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=YZ6VXyeY39Amd3aJX1bAsPKuxCkd4qcZJwMJ/B4JMxM=;
 b=TQICWzuVJ91VffhN/LdgZDj7U8z3Xq+4v7Yufhtr1yBwoX6V/EnxpP4ZZ9Nhv/kgfAZawurYa
 i5iNnv56ubVDSUkF60Z6YO7t235BqicbAk/AnIUmcqfniuPiJdkAaXZ
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi Jonathan,

Here it goes v2. Some points were still left open on v1 but this should
already include most of the things you asked for. 

---
Changes in v2:
- Link to v1: https://lore.kernel.org/r/20240419-ad9467-new-features-v1-0-3e7628ff6d5e@analog.com

- Patch 1:
  * New patch;
  
- Patch 2:
  * Added IIO_BACKEND_NO_TESTPATERN to stop the pattern (may be a no-op);
  * Drop struct iio_backend_chan_status and use a bool pointer;
  * Rename tap -> taps;
  * Improved commit message.
  
- Patch 3 & 4:
  * Added fixes tag;
  * Imporved commit message (so one can better decide for backporting).

- Patch 6:
  * Add comment on the sleep before checking for error;
  * Use switch case in axi_adc_data_sample_trigger();
  * Add IIO_BACKEND_NO_TEST_PATTERN.

- Patch 7:
  * Instead of caching the sample_rate, use clk_get_rate() "in place";
  * Added comment clarifying dco (data clock output);
  * Remove shadow ret;
  * Moved the tuning table dump into debugfs.

---
Nuno Sa (7):
      iio: backend: change docs padding
      iio: backend: add API for interface tuning
      dt-bindings: adc: axi-adc: add clocks property
      iio: adc: axi-adc: make sure AXI clock is enabled
      iio: adc: adi-axi-adc: remove regmap max register
      iio: adc: adi-axi-adc: support digital interface calibration
      iio: adc: ad9467: support digital interface calibration

 .../devicetree/bindings/iio/adc/adi,axi-adc.yaml   |   5 +
 drivers/iio/adc/ad9467.c                           | 374 ++++++++++++++++++---
 drivers/iio/adc/adi-axi-adc.c                      | 127 ++++++-
 drivers/iio/industrialio-backend.c                 | 162 ++++++---
 include/linux/iio/backend.h                        |  74 ++--
 5 files changed, 643 insertions(+), 99 deletions(-)
---
base-commit: cd84b21017b5f7b993341ee8b5c5bf10ddba37ab
change-id: 20240419-ad9467-new-features-fbfbaa5edf06
--

Thanks!
- Nuno Sá

