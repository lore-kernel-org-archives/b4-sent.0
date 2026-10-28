From: Andrei Stancovici <andrei.stancovici@analog.com>
Subject: [PATCH v3 0/4] iio: adc: ltc2497: add LTC2493 support and
 line-frequency rejection
Date: Thu, 29 Oct 2026 00:24:25 +0200
Message-Id: <20261029-submission-ltc2493-support-v1-v3-0-c7dd5f877c3b@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIABl24moC/43OQQ7CIBAF0Ks0rMXAFNviynsYFxSwxbSlASSap
 ncX6kZXmszmT37ezIK8dkZ7dCwW5HQ03tgphXJXINmLqdPYqJQREKgoIRz7ezsan2t4CBIYL9N
 qnq0LOFLcVIxxrTQrQaFkzE5fzWPzz5d3TsBNy5DR3OiND9Y9twcizb1/b6UhuFRCUcVaegBxE
 pMYbLeXdkT5WIQPDuAXB5njVHHSKGjq+otb1/UFngVSSiwBAAA=
X-Change-ID: 20261009-submission-ltc2493-support-v1-86449ede432d
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Liam Beguin <liambeguin@gmail.com>, 
 Joshua Crofts <joshua.crofts1@gmail.com>
Cc: linux@analog.com, linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Andrei Stancovici <andrei.stancovici@analog.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793226265; l=3174;
 i=andrei.stancovici@analog.com; s=20261009; h=from:subject:message-id;
 bh=1eElcDBdYH6U/ku61R6dLZL+jxyUrre0O5/3HdquLhs=;
 b=yEFSNN9D24qKQqM56ZbWt8NYT5yfncSvbb2L3PTHannAmja4yUc/CCeEHsPfk1ItZwoHa6w5p
 YHzLTQxydd9AhzvDp858mrV5p4ZXE+Y+Uoxvvva8EJa6tn5/RZDGcfZ
X-Developer-Key: i=andrei.stancovici@analog.com; a=ed25519;
 pk=wgT+au+blAhVYxhwNgdx0woNl/1p+OCG484rnTRFrsE=
X-Endpoint-Received: by B4 Relay for andrei.stancovici@analog.com/20261009 with auth_id=1140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds LTC2493 support to the ltc2497 driver, and adds FA/FB
line-frequency rejection for the LTC2499 and the LTC2493.

It includes:
- the LTC2493 device-tree binding,
- FA/FB line-frequency rejection (50Hz, 60Hz, or both) exposed via
  filter_mode, implemented in the core and enabled for the LTC2499,
- a preparatory refactor giving each supported channel layout a channel
  set in the core, referenced directly from chip_info,
- LTC2493 support in the driver: 4 single-ended inputs or 2 differential
  pairs, 24-bit result, same command format as the LTC2499, the internal
  PTAT temperature channel, the 2x conversion speed mode exposed via
  sampling_frequency, and the same rejection selection.

The rejection patch also adjusts the conversion wait time for each
rejection mode. The 50Hz-only mode takes up to 163.5 ms at 1x, while the
previous fixed 150 ms delay only covered the default 50/60Hz mode.

Validated on a Raspberry Pi 4 running 7.3.0-rc4, over an IIO network
backend, with a DC1010A-A board (LTC2493), a DC1012A-A board (LTC2499)
and an LTC2497:
- LTC2493: 41/41 hardware tests passed,
- LTC2499: 36/36 hardware tests passed,
- LTC2497: 24/24 hardware tests passed,
- all LTC2493 rejection x speed combinations were exercised without
  conversion or I2C errors.

LTC2496 was build-tested only because no LTC2496 hardware was available.

The source in this series matches the hardware-tested tree.

Signed-off-by: Andrei Stancovici <andrei.stancovici@analog.com>
---
Changes in v3:
- The channel-set selection moved into a preparatory patch, so the patch
  adding the LTC2493 no longer touches the chip_info of the parts
  already supported (Nuno Sá).
- chip_info now references a per-device channel set directly. The
  num_inputs field and the keyed lookup it was matched against in probe
  are both gone (Nuno Sá).
- The LTC2493 patch is reduced to the device-specific additions.
- The binding and FA/FB patches are unchanged. Nuno Sá's Reviewed-by is
  added to the FA/FB patch.
- Behaviour revalidated on hardware on all three parts; see the
  validation summary above.
- Per-patch changelogs are under the --- of each patch.
- Link to v2: https://patch.msgid.link/20261022-submission-ltc2493-support-v1-v2-0-391d908d2877@analog.com

---
Andrei Stancovici (4):
      dt-bindings: iio: adc: lltc,ltc2497: add LTC2493 support
      iio: adc: ltc2497: add FA/FB line-frequency rejection selection
      iio: adc: ltc2497: select the channel set per device
      iio: adc: ltc2497: add LTC2493 support

 .../devicetree/bindings/iio/adc/lltc,ltc2497.yaml  |   7 +
 drivers/iio/adc/ltc2496.c                          |   1 +
 drivers/iio/adc/ltc2497-core.c                     | 208 ++++++++++++++++-----
 drivers/iio/adc/ltc2497.c                          |  47 +++--
 drivers/iio/adc/ltc2497.h                          |  44 ++++-
 5 files changed, 243 insertions(+), 64 deletions(-)
---
base-commit: a3b3580713f3ac5a32dc2874ee546828977a1d68
change-id: 20261009-submission-ltc2493-support-v1-86449ede432d

Best regards,
--  
Andrei Stancovici <andrei.stancovici@analog.com>

