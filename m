From: Radu Sabau <radu.sabau@analog.com>
Subject: [PATCH 0/4] iio: adc: ad4691: add driver for AD4691 multichannel
 SAR ADC family
Date: Thu, 05 Mar 2026 14:23:26 +0200
Message-Id: <20260305-ad4692-multichannel-sar-adc-driver-v1-0-336229a8dcc7@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAL51qWkC/x2NQQ6CQAxFr0K6pslQGxSuQlyMtGoTGEhHiQnh7
 o4u38/LfztkddMMfbWD62bZllSgqSsYnzE9FE0KAwVqwykQRuG2I5zf08t+RtIJc/Syjyhumzq
 eL8rCLMQ3gnK0ut7t848M1+P4Atc0p7h0AAAA
X-Change-ID: 20260302-ad4692-multichannel-sar-adc-driver-78e4d44d24b2
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pwm@vger.kernel.org, 
 linux-gpio@vger.kernel.org, Radu Sabau <radu.sabau@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772713413; l=2732;
 i=radu.sabau@analog.com; s=20260220; h=from:subject:message-id;
 bh=GU7IYmfFkVf9LKnTBKrEhEIX0CYJNEH8lftpyqFdpwc=;
 b=cQc9Kvw+BUYKQkx0T+kNtJWVcKc/VF/EXt4HxpoWTyDR1r2FotoX8J8Hd6hyYwOS8F5iP0tdN
 bJ/0spzUY+5CRaDPgwA1D5pWF6s2wkkVnZX6yzo3q5fb7lZSvuDr7Wz
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=lDPQHgn9jTdt0vo58Na9lLxLaE2mb330if71Cn+EvFU=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20260220 with auth_id=642
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the Analog Devices AD4691 family of
high-speed, low-power multichannel successive approximation register
(SAR) ADCs with an SPI-compatible serial interface.

The family includes:
  - AD4691: 16-channel, 500 kSPS
  - AD4692: 16-channel, 1 MSPS
  - AD4693: 8-channel, 500 kSPS
  - AD4694: 8-channel, 1 MSPS

The devices support five operating modes:
  - CNV Clock Mode:    external PWM drives CNV, samples at PWM rate
  - CNV Burst Mode:    PWM triggers bursts, internal oscillator drives
                       conversions within each burst
  - Autonomous Mode:   internal oscillator drives conversions,
                       software starts/stops via register write
  - SPI Burst Mode:    similar to Autonomous Mode but optimised for
                       SPI burst reads
  - Manual Mode:       CNV tied to SPI CS; each SPI transfer triggers
                       a conversion and returns the previous result
                       (pipelined);

The series is structured as follows:

  1/4 - DT bindings (YAML schema + dt-bindings header) and
        MAINTAINERS entry
  2/4 - Initial driver: register map via custom regmap callbacks,
        IIO read_raw/write_raw, all five operating modes, direct
        single-channel reads
  3/4 - Triggered buffer support: IRQ-driven (DATA_READY / BUSY on
        GP0) for non-Manual modes; hrtimer-based trigger for Manual
        Mode to handle the pipelined SPI protocol
  4/4 - SPI Engine offload support: DMA-backed high-throughput
        capture path using the SPI offload subsystem

Datasheets:
  https://www.analog.com/en/products/ad4691.html
  https://www.analog.com/en/products/ad4692.html
  https://www.analog.com/en/products/ad4693.html
  https://www.analog.com/en/products/ad4694.html

Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
Radu Sabau (4):
      dt-bindings: iio: adc: add bindings for AD4691 family
      iio: adc: ad4691: add initial driver for AD4691 family
      iio: adc: ad4691: add triggered buffer support
      iio: adc: ad4691: add SPI offload support

 .../devicetree/bindings/iio/adc/adi,ad4691.yaml    |  278 +++
 MAINTAINERS                                        |    9 +
 drivers/iio/adc/Kconfig                            |   14 +
 drivers/iio/adc/Makefile                           |    1 +
 drivers/iio/adc/ad4691.c                           | 2031 ++++++++++++++++++++
 include/dt-bindings/iio/adc/adi,ad4691.h           |   13 +
 6 files changed, 2346 insertions(+)
---
base-commit: 11439c4635edd669ae435eec308f4ab8a0804808
change-id: 20260302-ad4692-multichannel-sar-adc-driver-78e4d44d24b2

Best regards,
-- 
Radu Sabau <radu.sabau@analog.com>

