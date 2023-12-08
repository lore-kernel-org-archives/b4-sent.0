From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH v2 0/8] iio: add new backend framework
Date: Fri, 08 Dec 2023 16:14:07 +0100
Message-Id: <20231208-dev-iio-backend-v2-0-5450951895e1@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAL8yc2UC/x3MTQqAIBBA4avIrBvwJ4i6SrRQZ6ohsFCIILx70
 vJbvPdC4SxcYFIvZL6lyJkabKcg7j5tjELNYLV1xliNxDeKnBh8PDgRkulDPzhvaFyhVVfmVZ7
 /OC+1fn38BEthAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1702048448; l=4749;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=g4mTpo8/W7eOmvSfdwVOe0jhwpQDMDQn2RXgMbfO37Y=;
 b=x8pCre21ucQ5YDJkbrDclV7CS9J96KAFLqBzMdSI6wadRVuDbXsGa3doN+cpUdje2LJvCd9Xu
 EdTt1EPx5p+CJxMM6FKzhQyalQdkTjQ0OlXw8WasBZIreaNbQcB2R1Q
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series depends on [1] and it only build on top of it. The point is
to already speed up the reviewing of the framework. That obviously means
that all those pacthes were dropped in v2.

v1:
 https://lore.kernel.org/linux-iio/20231204144925.4fe9922f@jic23-huawei/T/#m222f5175273b81dbfe40b7f0daffcdc67d6cb8ff

Changes in v2:
 - Patch 1-2 and 5
   * new patches.
 - Patch 6:
   * Fixed some docs failures;
   * Fixed a legacy 'conv' name in one of the function parameters;
   * Added .request_buffer() and .free_buffer() ops;
   * Refactored the helper macros;
   * Added Olivier as Reviewer.
 - Patch 7:
   * Use new devm_iio_backend_request_buffer().
 - Patch 8:
   * Implement new .request_buffer() and .free_buffer() ops;

Also would like to mention that in v2 I'm experimenting in having the
DMA on the backend device (as discussed with David in v1). Does not look
to bad but as I said before, I'm not seeing a big issue if we end up
having the buffer allocation in the frontend.

For the bindings folks:

I'm introducing a new io-backends property in the ad9467 bindings but I'm
not sure this is the way to do it. Ideally that new property become a
generic schema and I'm guessing I should send a PULL to?

https://github.com/devicetree-org/dt-schema/blob/main/dtschema/schemas/iio/iio-consumer.yaml

(Jonathan, if you think that's not the right place, shout now :))

I'm also deprecating 'adi,adc-dev' as it is not relevant anymore. In the
driver code, we are actually breaking ABI but I'm taking a more
conservative approach in the bindings. Ideally I would also remove it in
the bindings :).
 

As requested here we have a small diagram that illustrated on e typical
usage of the new framework:

                                           -------------------------------------------------------
 ------------------                        | -----------         ------------      -------  FPGA |
 |     ADC        |------------------------| | AXI ADC |---------| DMA CORE |------| RAM |       |
 | (Frontend/IIO) | Serial Data (eg: LVDS) | |(backend)|---------|          |------|     |       |
 |                |------------------------| -----------         ------------      -------       |
 ------------------                        -------------------------------------------------------
 
The above is highly focused on ADI usecases. But one can see the idea...
The frontend is the real converter and is the one registering and
handling all the IIO interfaces. Such a device can then connect to a
backend device for further services/configurations. In the above
example, the backend device is an high speed core capable of handling
the high sample rate of these ADCs so that it can push that data further
in the pipeline (typically a DMA core) so the user can process the
samples with minimal losses.

Jonathan, I was also tempted in including the diagram in the source
file. Would that be a good idea?

[1]: https://lore.kernel.org/linux-iio/20231207-iio-backend-prep-v2-0-a4a33bc4d70e@analog.com

---
Nuno Sa (7):
      dt-bindings: adc: ad9467: document io-backend property
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
 drivers/iio/adc/Kconfig                            |   3 +-
 drivers/iio/adc/ad9467.c                           | 242 +++++++------
 drivers/iio/adc/adi-axi-adc.c                      | 379 +++++---------------
 drivers/iio/buffer/industrialio-buffer-dmaengine.c |   6 +-
 drivers/iio/industrialio-backend.c                 | 386 +++++++++++++++++++++
 drivers/of/property.c                              |   2 +
 include/linux/iio/adc/adi-axi-adc.h                |  68 ----
 include/linux/iio/backend.h                        |  68 ++++
 include/linux/iio/buffer-dmaengine.h               |   4 +-
 15 files changed, 727 insertions(+), 468 deletions(-)
---
base-commit: 330c0f834ccbdbe6a89da475cb1c56893f3a8363
change-id: 20231120-dev-iio-backend-d14b473a1d9f
--

Thanks!
- Nuno Sá

