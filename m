From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Subject: [PATCH 0/6] Add support for AD411x
Date: Mon, 01 Apr 2024 18:32:18 +0300
Message-Id: <20240401-ad4111-v1-0-34618a9cc502@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIPTCmYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDY0Mj3cQUE0NDQ13z1NQkY5PUJJNE0zQloOKCotS0zAqwQdGxtbUApX1
 /H1gAAAA=
To: Ceclan Dumitru <dumitru.ceclan@analog.com>
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dumitru Ceclan <mitrutzceclan@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711985550; l=2067;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=10B9kij4RJ8Moszjff2kF8cKqehkeXTDRYV4vE4emTg=;
 b=XLN9Nt8v7bv1mWjyDAWDeyL+7eBHCtShfmeS9aiFjAAWhNLQnF8WvA3P84LoqGXId7oimiFXZ
 njaVyz3tn1JC8NxVW9DB6cuu1ZuAS2yhvJA9QrY4mondxwUlXGQn1ip
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

- All ADCs have inputs with a precision voltage divider with a division
ratio of 10.
- AD4116 has 5 low level inputs without a voltage divider.
- AD4111 and AD4112 support current inputs (0 mA to 20 mA) using a 50ohm
shunt resistor.

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
Dumitru Ceclan (6):
      dt-bindings: adc: ad7173: add support for ad411x
      iio: adc: ad7173: fix buffers enablement for ad7176-2
      iio: adc: ad7173: refactor channel configuration parsing
      iio: adc: ad7173: refactor ain and vref selection
      iio: adc: ad7173: Remove index from temp channel
      iio: adc: ad7173: Add support for AD411x devices

 .../devicetree/bindings/iio/adc/adi,ad7173.yaml    |  59 +++-
 drivers/iio/adc/ad7173.c                           | 318 ++++++++++++++++++---
 2 files changed, 331 insertions(+), 46 deletions(-)
---
base-commit: 5ab61121a34759eb2418977f0b3589b7edc57776
change-id: 20240312-ad4111-7eeb34eb4a5f

Best regards,
-- 
Dumitru Ceclan <dumitru.ceclan@analog.com>

