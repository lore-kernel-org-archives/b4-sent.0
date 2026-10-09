From: Andrei Stancovici <andrei.stancovici@analog.com>
Subject: [PATCH 0/6] iio: adc: ltc2497: add LTC2493 support and
 line-frequency rejection
Date: Fri, 09 Oct 2026 11:43:33 +0300
Message-Id: <20261009-submission-ltc2493-support-v1-v1-0-3dad1d4b152a@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADWpyGoC/yXMywrCMBCF4Vcps3YgN4rxVcRFTUYd0TZk0iKUv
 rtTXf6Hw7eCUGUSOHUrVFpYeBo17KGD9BjGOyFnbXDG9daYiDJf3yz7DV8tuRC9TqVMteFi8di
 HEClT8C6DGqXSjT8//3z5twJPSm1HYdu+K87nIYEAAAA=
X-Change-ID: 20261009-submission-ltc2493-support-v1-86449ede432d
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Liam Beguin <liambeguin@gmail.com>
Cc: linux@analog.com, linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Andrei Stancovici <andrei.stancovici@analog.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791535413; l=2561;
 i=andrei.stancovici@analog.com; s=20261009; h=from:subject:message-id;
 bh=qPw/W4uGpNR8YtgkZjRtlirnT4ziZSl3ZtAV1Ca3h1Y=;
 b=d4Cpeh3cVJHo3gedk3mF1UmNKUS4/0bt9xBrR89d1/04EauA5cuIUyKmZQYnXfXchl6LnoofF
 YGwc3s04sYFCT+Eqd3JMmojGSUQdnaAlezA/QbrNzm9OkKAj3Hv5RhG
X-Developer-Key: i=andrei.stancovici@analog.com; a=ed25519;
 pk=wgT+au+blAhVYxhwNgdx0woNl/1p+OCG484rnTRFrsE=
X-Endpoint-Received: by B4 Relay for andrei.stancovici@analog.com/20261009 with auth_id=1140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds LTC2493 support to the ltc2497 driver, and adds FA/FB
line-frequency rejection for the LTC2499 and the LTC2493.

It includes:
- the LTC2493 device-tree binding,
- LTC2493 support in the driver: 4 single-ended inputs or 2 differential
  pairs, 24-bit result, same command format as the LTC2499,
- the LTC2493 internal PTAT temperature channel,
- the LTC2493 2x conversion speed mode, exposed via sampling_frequency,
- FA/FB line-frequency rejection (50Hz, 60Hz, or both) exposed via
  filter_mode, implemented in the core and enabled for the LTC2499,
- the same rejection selection enabled for the LTC2493.

The FA/FB patch also widens the conversion-time budget, because 50Hz-only
rejection takes 163.5 ms at 1x and the previous budget was 150 ms; see
that patch for the details.

Validated on a Raspberry Pi 4 running 7.3.0-rc4, over an IIO network
backend, with a DC1010A-A board (LTC2493) and a DC1012A-A board
(LTC2499):
- LTC2493 voltage channels, single-ended and differential,
- LTC2493 temperature raw/scale/offset, with voltage and temperature
  reads interleaved to confirm no sticky PTAT,
- sampling_frequency 1x/2x switching on the LTC2493,
- filter_mode 50Hz/60Hz/both on both parts, with the conversion time
  honoured in each mode,
- pyadi-iio hardware test suites: 41/41 on the LTC2493, 36/36 on the
  LTC2499.

The series was rebased onto the base commit below after those runs. The
rebase left all four touched files byte-identical, so the code posted
here is the code that was tested.

Signed-off-by: Andrei Stancovici <andrei.stancovici@analog.com>
---
Andrei Stancovici (6):
      dt-bindings: iio: adc: lltc,ltc2497: add LTC2493 support
      iio: adc: ltc2497: add LTC2493 support
      iio: adc: ltc2497: add LTC2493 internal temperature channel
      iio: adc: ltc2497: add 2x speed mode support for the LTC2493
      iio: adc: ltc2497: add FA/FB line-frequency rejection selection
      iio: adc: ltc2497: enable line-frequency rejection on LTC2493

 .../devicetree/bindings/iio/adc/lltc,ltc2497.yaml  |   7 +
 drivers/iio/adc/ltc2497-core.c                     | 199 +++++++++++++++++----
 drivers/iio/adc/ltc2497.c                          |  61 +++++--
 drivers/iio/adc/ltc2497.h                          |  45 ++++-
 4 files changed, 251 insertions(+), 61 deletions(-)
---
base-commit: a3b3580713f3ac5a32dc2874ee546828977a1d68
change-id: 20261009-submission-ltc2493-support-v1-86449ede432d

Best regards,
--  
Andrei Stancovici <andrei.stancovici@analog.com>

