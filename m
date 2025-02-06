From: Tobias Sperling <tobias.sperling@softing.com>
Subject: [PATCH v3 0/2] Support for TI ADS7128 and ADS7138 ADCs
Date: Thu, 06 Feb 2025 16:41:47 +0100
Message-Id: <20250206-adc_ml-v3-0-1d0bd3483aa2@softing.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADvYpGcC/2WM0QqCMBSGXyXOdYvt2KZ21XtEhM6jHkgXm4xCf
 PemUBBdfj//980QyDMFOO1m8BQ5sBsTZPsd2L4aOxLcJAaUeFQKUVSNvQ130ShLhaFC12ghnR+
 eWn5uocs1cc9hcv61daNa179EVEIKmZuyRVJ1bdU5uHbisTtYN8AaifgRtUSZfUVMYlHpMjdG2
 qzUv+KyLG+d9ek51wAAAA==
X-Change-ID: 20241122-adc_ml-d1ce86e85b2c
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Tobias Sperling <tobias.sperling@softing.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.15-dev-355e8
X-Developer-Signature: v=1; a=ed25519-sha256; t=1738856545; l=2986;
 i=tobias.sperling@softing.com; s=20241122; h=from:subject:message-id;
 bh=1fOQzDV6HZJ2nN25yLU7hZ1P3TPmArQ54K7qLHm0wt0=;
 b=EDhZjivm2O9mwyFHeORx+WauW1U4nzeS00mqk6I26KR0A+OjgJ+GiRdQyBsQO8xhOha5mygZE
 sXkn1loYnQtA73o2cnWWJCiCFgFHqyWz0OKd+GDYQrgOFyj6jlu8g4P
X-Developer-Key: i=tobias.sperling@softing.com; a=ed25519;
 pk=v7hgaMHsrA9ul4UXkBVUuwusS9PF3uHW/CC+gABI65E=
X-Endpoint-Received: by B4 Relay for tobias.sperling@softing.com/20241122 with auth_id=281
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds support for Texas Instruments ADS7128 and
ADS7138, which are 12-bit, 8 channel analog-to-digital converters (ADCs)
with build-in digital window comparator (DWC), using the I2C interface.

The driver exposes the interfaces to read the raw values, as well as the
minimum and maximum value for each channel. In addition several settings
can be configured, like the DWC, sampling frequency or an averaging
filter/oversampling. Interrupts triggered by the DWC, if configured, are
then exposed as IIO events.

ADS7128 differs in the addition of further hardware features, like a
root-mean-square (RMS) and a zero-crossing-detect (ZCD) module, which
are not yet supported by the driver.

Regarding the I2C interface the chips using opcodes to define the way
how the registeres are accessed, like single or multiple register(s)
read/write or setting/clearing only bits.

---
Changes in v3:
- Make interrupt optional.
- Replace SET_RUNTIME_PM_OPS() with RUNTIME_PM_OPS() to prevent warning.
- Rework read_avail for sampling frequency to show each frequency only
  once.
- Use IIO_CHAN_INFO_PEAK and IIO_CHAN_INFO_TROUGH instead of ext_info.
- Link to v2: https://lore.kernel.org/r/20250203-adc_ml-v2-0-8a597660c395@softing.com

Changes in v2:
- Improved commit messages.
- dt-bindings: drop info about what driver supports, make 'avdd-supply'
  optional.
- General rework of driver regarding indentation and code style.
- General code improvements to make code shorter and improve
  readability, like remove 'goto's, order of declarations, ...
- Use kernel macros and functions, like FIELD_*, guard(), ...
- Rework i2c functions to return 0 in case of success and use
  i2c_master_send() if possible.
- Use struct for chip data instead of enum.
- Add comment to what the lock is used for and make sure it's used in
  these cases.
- Use read_avail of iio_info and extend to return also the available
  values for OSR.
- Rework to only accept values of the availability list.
- Use devm_* if possible and therefore drop 'remove' callback.
- Rebase to kernel 6.13 and adjust to API changes.
- Link to v1:
  https://lore.kernel.org/r/20241122-adc_ml-v1-0-0769f2e1bbc1@softing.com

Changes in v1 (to patch series without b4):
- dt-bindings: Extended description

Signed-off-by: Tobias Sperling <tobias.sperling@softing.com>

---
Tobias Sperling (2):
      dt-bindings: iio: adc: Introduce ADS7138
      iio: adc: Add driver for ADS7128 / ADS7138

 .../devicetree/bindings/iio/adc/ti,ads7138.yaml    |  62 ++
 drivers/iio/adc/Kconfig                            |  10 +
 drivers/iio/adc/Makefile                           |   1 +
 drivers/iio/adc/ti-ads7138.c                       | 746 +++++++++++++++++++++
 4 files changed, 819 insertions(+)
---
base-commit: 05dbaf8dd8bf537d4b4eb3115ab42a5fb40ff1f5
change-id: 20241122-adc_ml-d1ce86e85b2c

Best regards,
-- 
Tobias Sperling <tobias.sperling@softing.com>

