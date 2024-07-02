From: Petar Stoykov <pd.pstoykov@gmail.com>
Subject: [PATCH v3 0/3] Add support for Sensirion SDP500
Date: Tue, 02 Jul 2024 16:59:07 +0200
Message-Id: <20240702-mainline_sdp500-v3-0-0902047b3eee@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALwVhGYC/x3MQQqAIBBA0avIrBOGySi7SkRITjVQJgoRRHdPW
 r7F/w9kTsIZevVA4kuynKGgrhTMmwsra/HFQEgGWyR9OAm7BJ6yjw2iRm+XbjbWEnVQqph4kfs
 /DuP7ft/FUwBhAAAA
To: linux-iio@vger.kernel.org, Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Cc: Petar Stoykov <pd.pstoykov@gmail.com>, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719932376; l=3344;
 i=pd.pstoykov@gmail.com; s=20240702; h=from:subject:message-id;
 bh=jcgekClSNbMNhKgcEzrXZ/EyPCCRQaAQrnvaG+E2eag=;
 b=ZxisyshPUperM+epBVMZbYObLWmXodKbAg8igdiIODh2+68BB98ztg8wAdI98sXgoitHtKy1G
 L1+EDT0GUclC7dUQkOri7ZXcN9LjpVsVOLqjOn9v7jMI80NCs/SxRRc
X-Developer-Key: i=pd.pstoykov@gmail.com; a=ed25519;
 pk=oxcGqcVV5O6wqlTh+39SbOwfbpD763i5x4TavUAHiCg=
X-Endpoint-Received: by B4 Relay for pd.pstoykov@gmail.com/20240702 with auth_id=179
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series introduces support for Sensirion SDP500 in the IIO
subsystem. The series is split into three patches:

1. The first patch adds the device tree bindings.
2. The second patch implements the device driver.
3. The third patch updates the MAINTAINERS file.

The driver is relatively simple. It provides a way to read the measured
differential pressure directly in Pa, as the device has a fixed scale
factor of 1/60. When an applications wants to read the pressure value,
3 bytes are read from the device, 2 are data and 1 is CRC8. If the crc
check passes, the raw value is made available.

The initialization of the device just starts the measurement process.

We have been using this device and driver in a product development for
almost a year now. There the pressure is read every 25ms and is used in a
control loop. We have not even seen crc errors. We are using the
"linux-imx" repository and not the mainline one but I see no risky kernel
functions in use so it should be fine here too.

All feedback is appreciated! Thank you for taking the time to review this.

Changelog
v1->v2:
	driver code:
* Removed the use of wrapper functions for logging
* Using built-in crc function instead of a custom one
* Removed the use of a wrapper function for i2c send and receive data
* Use get_unaligned_be16 instead of custom calculation
* Removed error log if devm_iio_device_alloc fails
* indio_dev->name set directly to "sdp500"
* Updated error logging to use "dev_err_probe" in probe function
* Added a sensor readout in the probe function (first one is always bad)
* Used devm_iio_device_register instead of iio_device_register
* Removed trailing comma in "sdp500_id" data
* Deleted sdp500_remove after using devm_iio_device_register in probe
	dt-bindings:
* Fixed dt-bindings example wording
* Added vdd-supply in dt-bindings example

v2->v3:
	driver code:
* Added link to datasheet at the start of the driver code
* Removed some unnecessary defines
* Removed an unused argument of sdp500_start_measurement function
* Renamed variable that holds the received CRC to "received_crc"
* Switched to returning RAW and SCALE values instead of PROCESSED
* Change logging to use data->dev instead of indio_dev->dev.parent
* Removed unnecessary debug log of the read value from the sensor
* Added vdd regulator handling
* Added "sensirion,sdp510" as compatible
* Removed the aligning of '=' in the sdp500_driver struct
	dt-bindings:
* Added "sensirion,sdp510" as possible compatible value in dt-bindings example

Signed-off-by: Petar Stoykov <pd.pstoykov@gmail.com>
---
Petar Stoykov (3):
      dt-bindings: iio: pressure: Add Sensirion SDP500
      iio: pressure: Add driver for Sensirion SDP500
      MAINTAINERS: Add Sensirion SDP500

 .../bindings/iio/pressure/sensirion,sdp500.yaml    |  41 ++++++
 MAINTAINERS                                        |   6 +
 drivers/iio/pressure/Kconfig                       |   9 ++
 drivers/iio/pressure/Makefile                      |   1 +
 drivers/iio/pressure/sdp500.c                      | 153 +++++++++++++++++++++
 5 files changed, 210 insertions(+)
---
base-commit: ab27740f76654ed58dd32ac0ba0031c18a6dea3b
change-id: 20240702-mainline_sdp500-0d9f8c499228

Best regards,
-- 
Petar Stoykov <pd.pstoykov@gmail.com>

