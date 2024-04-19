From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH v4 00/10] iio: dac: support IIO backends on the output
 direction
Date: Fri, 19 Apr 2024 10:25:33 +0200
Message-Id: <20240419-iio-backend-axi-dac-v4-0-5ca45b4de294@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAH0qImYC/32NQQ6CMBBFr0Jm7ZjSVhJceQ/DYmgHmKgtaQ3BE
 O5u5QAu30v++xtkTsIZrtUGiRfJEkMBe6rATRRGRvGFQSttla01ikTsyT04eKRV0JPD3jQteUe
 2IQVlOSceZD2q967wJPkd0+c4WczP/u8tBhUabr11F63qob9RoGcczy6+oNv3/QsJjeE2twAAA
 A==
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Dragos Bogdan <dragos.bogdan@analog.com>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, Nuno Sa <nuno.sa@analog.com>, 
 Paul Cercueil <paul@crapouillou.net>, 
 Alexandru Ardelean <ardeleanalex@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713515134; l=2355;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=6Jc63Ty3AclW4Qt3X4Q3sXMZP6yZwhBtynEVSVLwiZo=;
 b=btC7zoHobyKtlNXdb77uQliTZs2BXBv2Fv5mSzJu9UQBdqwV00mwAoA9STXrQQDyhU4l6mI1+
 n7xxElW+5nLCEggR1im35BrVMtY8b0aSVfu8vq4k1fChNx/MsD+PzaB
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi Jonathan,

Here it goes v4. Added default value for full scale current and
corrected the minimum value.

Full log:

v1:
 * https://lore.kernel.org/all/20240328-iio-backend-axi-dac-v1-0-afc808b3fde3@analog.com

v2:
 * https://lore.kernel.org/all/20240405-iio-backend-axi-dac-v2-0-293bab7d5552@analog.com 

v3:
 * https://lore.kernel.org/r/20240412-iio-backend-axi-dac-v3-0-3e9d4c5201fb@analog.com 

v4:
 * Patch 7:
   - Added default value for full scale current;
   - Corrected the minimum value for full scale current.
 * Patch 10:
   - Corrected the minimum value for full scale current. 

---
Nuno Sa (6):
      iio: buffer-dma: add iio_dmaengine_buffer_setup()
      dt-bindings: iio: dac: add docs for AXI DAC IP
      dt-bindings: iio: dac: add docs for AD9739A
      iio: backend: add new functionality
      iio: dac: add support for AXI DAC IP core
      iio: dac: support the ad9739a RF DAC

Paul Cercueil (4):
      iio: buffer-dma: Rename iio_dma_buffer_data_available()
      iio: buffer-dma: Enable buffer write support
      iio: buffer-dmaengine: Support specifying buffer direction
      iio: buffer-dmaengine: Enable write support

 Documentation/ABI/testing/sysfs-bus-iio-ad9739a    |  19 +
 .../devicetree/bindings/iio/dac/adi,ad9739a.yaml   |  95 +++
 .../devicetree/bindings/iio/dac/adi,axi-dac.yaml   |  62 ++
 MAINTAINERS                                        |  17 +
 drivers/iio/adc/adi-axi-adc.c                      |  16 +-
 drivers/iio/buffer/industrialio-buffer-dma.c       | 100 +++-
 drivers/iio/buffer/industrialio-buffer-dmaengine.c |  83 +--
 drivers/iio/dac/Kconfig                            |  37 ++
 drivers/iio/dac/Makefile                           |   2 +
 drivers/iio/dac/ad9739a.c                          | 463 +++++++++++++++
 drivers/iio/dac/adi-axi-dac.c                      | 635 +++++++++++++++++++++
 drivers/iio/industrialio-backend.c                 | 179 ++++++
 include/linux/iio/backend.h                        |  49 ++
 include/linux/iio/buffer-dma.h                     |   4 +-
 include/linux/iio/buffer-dmaengine.h               |  24 +-
 15 files changed, 1706 insertions(+), 79 deletions(-)
---
base-commit: aabc0aa90c927a03d509d0b592720d9897894ce4
change-id: 20240412-iio-backend-axi-dac-b369adca46a0
--

Thanks!
- Nuno Sá

