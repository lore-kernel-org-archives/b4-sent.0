From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Subject: [PATCH v3 00/10] iio: frequency: ad9910: add IIO backend support
Date: Tue, 03 Nov 2026 11:52:56 -0300
Message-Id: <20261103-ad9910-backend-support-v3-0-0e9224ddf7b7@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAEj16WoC/3WNyw6CMBQFf8V0bc29baXgyv8wLkppoT4oaYFoC
 P9uwY0xYTnJOTMTiSY4E8lpN5FgRhedbxPw/Y7oRrW1oa5KTBiwDAoOVFVFgUBLpe+mrWgcus6
 HnqJUQlYoheBA0rkLxrrXKr5cvxyH8mZ0v9iWReNi78N7LY+47NYIAh63IiNSoFwzzESuc8Oys
 2rVw9cH7Z9kqYzsx8PYpoclD1grLZTW8j/PPM8fb8ptiBcBAAA=
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
 Rodrigo Alencar <rodrigo.alencar@analog.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793717581; l=4225;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=crclX+Wh/E611EdZhkgNZ8cUrSJu3ltuiZn/FoAIESE=;
 b=xYSl+hPNrXQeTr9KYu9pXF1Jl8dhbY8tLPl7CMPS8mKYhN6yRjgJLYba1Otg8VfIJwTtGB4+R
 srhkHMPggNEDqcuyrMqDyKARQgImvIpBMR8ia5XtrMEwq0YEHMtA9R3
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
Changes in v3:
- ad9910: Get the DRCTL PWM with con_id = NULL.
- backend: Explicit F[1:0] destination mapping for the parallel port channels.
- backend: Split DRCTL waveform write error and disable paths.
- backend bindings: Reword the #pwm-cells description.
- Link to v2: https://patch.msgid.link/20261022-ad9910-backend-support-v2-0-0ff7f0bff326@analog.com

Changes in v2:
- IIO Backend: Use device_property_present() when getting optional backends.
- AD9910 Backend: Move PWM driver to waveform semantics.
- AD9910 Backend: sync PWM configs when sysclk updates.
- Misc changes addressing other feedback (including sashiko's).
- Link to v1: https://patch.msgid.link/20261015-ad9910-backend-support-v1-0-3c21648c8e26@analog.com

To: Rodrigo Alencar <rodrigo.alencar@analog.com>
To: Jonathan Cameron <jonathan.cameron@oss.qualcomm.com>
To: linux-iio@vger.kernel.org
To: linux@analog.com
To: linux-kernel@vger.kernel.org
To: devicetree@vger.kernel.org
To: linux-pwm@vger.kernel.org
To: linux-doc@vger.kernel.org
Cc: Nuno Sá <nuno.sa@analog.com>
Cc: Michael Hennerich <Michael.Hennerich@analog.com>
Cc: Jonathan Cameron <jic23@kernel.org>
Cc: David Lechner <dlechner@baylibre.com>
Cc: Andy Shevchenko <andy@kernel.org>
Cc: Olivier Moysan <olivier.moysan@foss.st.com>
Cc: Rob Herring <robh@kernel.org>
Cc: Krzysztof Kozlowski <krzk+dt@kernel.org>
Cc: Conor Dooley <conor+dt@kernel.org>
Cc: Uwe Kleine-König <ukleinek@kernel.org>
Cc: Jonathan Corbet <corbet@lwn.net>
Cc: Shuah Khan <skhan@linuxfoundation.org>
Cc: Randy Dunlap <rdunlap@infradead.org>

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
 .../iio/frequency/adi,ad9910-axi-backend.yaml      |  74 +++
 .../bindings/iio/frequency/adi,ad9910.yaml         |  38 ++
 Documentation/iio/ad9910.rst                       |  90 +++-
 MAINTAINERS                                        |   3 +
 drivers/iio/frequency/Kconfig                      |  19 +
 drivers/iio/frequency/Makefile                     |   1 +
 drivers/iio/frequency/ad9910-axi-backend.c         | 551 +++++++++++++++++++++
 drivers/iio/frequency/ad9910.c                     | 425 +++++++++++++---
 drivers/iio/frequency/ad9910.h                     |  44 ++
 drivers/iio/industrialio-backend.c                 |  38 ++
 include/linux/iio/backend.h                        |   2 +
 12 files changed, 1236 insertions(+), 66 deletions(-)
---
base-commit: 43ffda3c7f8456bbe641ae8249a077a361b97880
change-id: 20260930-ad9910-backend-support-17a47d174430

Best regards,
--  
Rodrigo Alencar <rodrigo.alencar@analog.com>

