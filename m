From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Subject: [PATCH 00/10] iio: frequency: ad9910: add IIO backend support
Date: Thu, 15 Oct 2026 13:49:40 -0300
Message-Id: <20261015-ad9910-backend-support-v1-0-3c21648c8e26@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACQE0WoC/yXMQQrCMBBA0auUWTswaYMhXkVcpMmoo5CGTCtC6
 d0b6/It/l9BuQorXLoVKn9EZcoN5tRBfIb8YJTUDD31Z/IDYUjeG8IxxDfnhLqUMtUZjQvWJeO
 sHQhaXCrf5XuMr7e/dRlfHOffDbZtByM6BTB6AAAA
X-Change-ID: 20260930-ad9910-backend-support-17a47d174430
To: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux@analog.com, devicetree@vger.kernel.org, linux-pwm@vger.kernel.org, 
 linux-doc@vger.kernel.org, 
 Jonathan Cameron <jonathan.cameron@oss.qualcomm.com>
Cc: Olivier Moysan <olivier.moysan@foss.st.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792082993; l=2640;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=0+HWhSkCpghkOfm79SliF6p8qXrll7DuCOm1mvzp4Gs=;
 b=ymNJ8Ey19sr74mQ8L7kQqU2ubD3ozWIDgnC/+dBWV+57liYowKul7/gFlZbvMUrMXQ2QsRMGg
 h7G4N+upt/VAZ9nV8P1TafnbbkyVfKnoFfVkNAaM+UDSyDtwO4l3pAx
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series extends the AD9910 DDS driver with support for an IIO backend,
enabling data streaming through the parallel data port, and with control of
the DRCTL pin, which defines the slope direction of the digital ramp
generator (DRG).

The parallel data port allows modulation of the DDS core parameters
(amplitude, phase, frequency or polar) at up to the PDCLK rate, which is
SYSCLK / 4. Such data rates require an FPGA IP core as the data source, so
an AXI backend driver is added for the AD9910 HDL reference design. Besides
streaming data from memory via DMA, the IP core also drives the PROFILE[2:0]
and DRCTL pins. The latter is exposed as a PWM output, so that the frontend
driver can consume it through the PWM framework without depending on the
backend being present.

The backend is optional: the AD9910 remains functional through the SPI
control interface alone, hence the new devm_iio_backend_get_optional()
helper.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
Rodrigo Alencar (10):
      iio: frequency: ad9910: powerdown fix
      iio: backend: add devm_iio_backend_get_optional()
      dt-bindings: iio: frequency: add adi,ad9910-axi-backend
      dt-bindings: iio: frequency: ad9910: add io-backends property
      iio: frequency: ad9910: move channel indexes into a shared header
      iio: frequency: ad9910: add axi backend driver
      iio: frequency: ad9910: support drctl control
      iio: frequency: ad9910: support iio backend
      iio: ABI: add integration_time for output channels
      docs: iio: ad9910: document DRCTL pin control

 Documentation/ABI/testing/sysfs-bus-iio            |  17 +
 .../iio/frequency/adi,ad9910-axi-backend.yaml      |  74 ++++
 .../bindings/iio/frequency/adi,ad9910.yaml         |  38 ++
 Documentation/iio/ad9910.rst                       |  90 ++++-
 MAINTAINERS                                        |   3 +
 drivers/iio/frequency/Kconfig                      |  18 +
 drivers/iio/frequency/Makefile                     |   1 +
 drivers/iio/frequency/ad9910-axi-backend.c         | 396 ++++++++++++++++++++
 drivers/iio/frequency/ad9910.c                     | 402 ++++++++++++++++++---
 drivers/iio/frequency/ad9910.h                     |  44 +++
 drivers/iio/industrialio-backend.c                 |  34 +-
 include/linux/iio/backend.h                        |   2 +
 12 files changed, 1052 insertions(+), 67 deletions(-)
---
base-commit: a22dc7ebb21a6bd4c8b63bc2c1dd46a24945aae7
change-id: 20260930-ad9910-backend-support-17a47d174430

Best regards,
--  
Rodrigo Alencar <rodrigo.alencar@analog.com>

