From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Subject: [PATCH v2 0/9] Add support for AD411x
Date: Tue, 14 May 2024 10:22:45 +0300
Message-Id: <20240514-ad4111-v2-0-29be6a55efb5@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEURQ2YC/zXMyw7CIBCF4VdpZi2Ggam3le9huqB02pIoNGCIp
 uHdxRqX/8nJt0Li6DjBpVkhcnbJBV9D7Rqws/ETCzfUBiUVSY1KmIEQURyZe03ck2lHqOcl8uh
 eG3Tras8uPUN8b27G7/ojSOKfyCik0HTAkzlb20p1Nd7cw7S34QFdKeUD8nmS+J0AAAA=
To: Ceclan Dumitru <dumitru.ceclan@analog.com>
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dumitru Ceclan <mitrutzceclan@gmail.com>, 
 Jonathan Cameron <Jonathan.Cameron@huawei.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1715671396; l=6250;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=3bcxwx7sfw8ExkjnXW8neKCzL9NjAQifAMy4d7Pc3gk=;
 b=3pQ94uO81s0//8XuVGtezlkkET09/clzgXKTYhvLUbvh05IcCoou4f+U2Sl+bz7fqsGj5xA9l
 zw22lFP1GvDAtMw32ZUVIQ1VZQnO41qoMi5FXoaLp+mCJrC1n46C0FL
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds support for the Analog Devices AD4111, AD4112,
 AD4114, AD4115, AD4116 within the existing AD7173 driver.

  The AD411X family encompasses a series of low power, low noise, 24-bit,
sigma-delta analog-to-digital converters that offer a versatile range of
specifications. They integrate an analog front end suitable for processing
fully differential/single-ended and bipolar voltage inputs.

Particularities of the models:
- All ADCs have inputs with a precision voltage divider with a division
ratio of 10.
- AD4116 has 5 low level inputs without a voltage divider.
- AD4111 and AD4112 support current inputs (0 mA to 20 mA) using a 50ohm
shunt resistor.

Discussions from this patch series have concluded with:
-Datasheets mention single-ended and pseudo differential capabilities by
 the means of connecting the negative input of a differential pair (IN-)
 to a constant voltage supply and letting the positive input fluctuate.
 This is not a special operating mode, it is a capability of the
 differential channels to also measure such signals.

-Single-ended and pseudo differential do not need any specific
 configuration and cannot be differentiated from differential usage by
 the driver side =>
	offer adi,channel-type attribute to flag the usage of the channel

-VINCOM is described as a dedicated pin for single-ended channels but as
 seen in AD4116, it is a normal input connected to the cross-point
 multiplexer (VIN10, VINCOM (single-ended or differential pair)).
 This does not mean full functionality in any configuration:
 AD4111:"If any two voltage inputs are paired in a configuration other
 than what is described in this data sheet, the accuracy of the device
 cannot be guaranteed".

-ADCIN15 input pin from AD4116 is specified as the dedicated pin for
 pseudo-differential but from the datasheet it results that this pin is
 also able to measure single-ended and fully differential channels
 ("ADCIN11, ADCIN15. (pseudo differential or differential pair)";
  "An example is to connect the ADCIN15 pin externally to the AVSS
   pin in a single-ended configuration")

 As such, detecting the type of usage of a channel is not possible and
will be the responsability of the user to specify.
 If the user has connected a non 0V (in regards to AVSS) supply to
the negative input pin of a channel in a pseudo differential
configuration, the offset of the measurement from AVSS will not be known
from the driver and will need to be measured by other means.

Datasheets:
https://www.analog.com/media/en/technical-documentation/data-sheets/AD4111.pdf
https://www.analog.com/media/en/technical-documentation/data-sheets/AD4112.pdf
https://www.analog.com/media/en/technical-documentation/data-sheets/AD4114.pdf
https://www.analog.com/media/en/technical-documentation/data-sheets/AD4115.pdf
https://www.analog.com/media/en/technical-documentation/data-sheets/AD4116.pdf

This series depends on patch:
(iio: adc: ad7173: Use device_for_each_child_node_scoped() to simplify error paths.)
https://lore.kernel.org/all/20240330190849.1321065-6-jic23@kernel.org

Signed-off-by: Dumitru Ceclan <mitrutzceclan@gmail.com>
---
Changes in v2:

dt-bindings: adc: ad7173: add support for ad411x
- Add constraint for missing avdd2-supply on ad411x
- Change support for current channels to selecting the actual
   diff-channels input values and activating the
   adi,current-channel property
- Add constraint for adi,current-channel
- Add adi,channel-type to be able to differentiante in the driver
   between single-ended, pseudo-differential and differential channels.
- Update diff-channels description to decribe inputs beside the AINs

iio: adc: ad7173: fix buffers enablement for ad7176-2
- Specify ".has_input_buf = false" for AD7176-2
- Drop fixes tag, specify that configuration bits are read only

iio: adc: ad7173: refactor channel configuration parsing
- Add Link and Suggested-by in commit message

iio: adc: ad7173: refactor ain and vref selection
- Improve commit message to express commit purpose
- Refactor line wrappings due to reduced indent
- Change AINs check to a loop

iio: adc: ad7173: add support for special inputs
- Create patch

iio: adc: ad7173: Add ad7173_device_info names
- Create patch

iio: adc: ad7173: Remove index from temp channel
- Justify in commit message userspace breakage
- Remove index from the correct channel template

iio: adc: ad7173: Add support for AD411x devices
- Add missing validation for VCOM and inputs with voltage divider
- Add missing validation for AD4116 low level inputs
- Add missing ad7173_device_info names
- Add support for setting differential flag depending on the channel type
- Change current channel validation to use actual pin values
- Combine multiple chipID reg values in a single define
		(AD7173_AD4111_AD4112_AD4114_ID)
- Rename num_inputs and num_inputs_with_divider to include voltage
- Add comment to specify that num_voltage_inputs_with_divider does not
   include the VCOM pin.
- Change break to direct returns where possible in switch cases
- Add fix for ad411x gpio's

iio: adc: ad7173: Reduce device info struct size
- Create patch

- Link to v1: https://lore.kernel.org/r/20240401-ad4111-v1-0-34618a9cc502@analog.com

---
Dumitru Ceclan (9):
      dt-bindings: adc: ad7173: add support for ad411x
      iio: adc: ad7173: fix buffers enablement for ad7176-2
      iio: adc: ad7173: refactor channel configuration parsing
      iio: adc: ad7173: refactor ain and vref selection
      iio: adc: ad7173: add support for special inputs
      iio: adc: ad7173: Add ad7173_device_info names
      iio: adc: ad7173: Remove index from temp channel
      iio: adc: ad7173: Add support for AD411x devices
      iio: adc: ad7173: Reduce device info struct size

 .../devicetree/bindings/iio/adc/adi,ad7173.yaml    | 118 +++++-
 drivers/iio/adc/ad7173.c                           | 438 ++++++++++++++++++---
 2 files changed, 497 insertions(+), 59 deletions(-)
---
base-commit: 5ab61121a34759eb2418977f0b3589b7edc57776
change-id: 20240312-ad4111-7eeb34eb4a5f

Best regards,
-- 
Dumitru Ceclan <dumitru.ceclan@analog.com>

