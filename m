From: Andrei Stancovici <andrei.stancovici@analog.com>
Subject: [PATCH v2 0/3] iio: adc: ltc2497: add LTC2493 support and
 line-frequency rejection
Date: Thu, 22 Oct 2026 12:58:17 +0300
Message-Id: <20261022-submission-ltc2493-support-v1-v2-0-391d908d2877@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIADne2WoC/42OQQ6CMBAAv0L2bE1bKhFP/MNwKO0Ka4CSthIN4
 e+2+AGTvcxmMrsbBPSEAW7FBh5XCuTmBPJUgBn03CMjmxgkl5XgvGbh1U0UssbGaKSqy7RaFuc
 jWwW7VkrVaFGV0kJqLB4f9D769/bHKfBEE3M0GwOF6PzneGAV2fv3VhrOSqutsKoTF6kbPevR9
 WfjJmj3ff8CQQpv7N0AAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792663098; l=3104;
 i=andrei.stancovici@analog.com; s=20261009; h=from:subject:message-id;
 bh=yPsqOFeX5OG71XtkfM53Dkyy130nnE6U9LTTm4qQtUM=;
 b=Bv5SokQryLzD6Jp1AUfflpESvj8Lt7SDZjuElK2RHsTuO7NcK33myjeO79yvfCabfHwsi1AGJ
 tVtlI2P+PpXDeUnfu6//cPQ0XAjG/9MEgMaZ/YT5Rr2GchpNakCBOLA
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
Changes in v2:
- Restructured from six patches to three, following review from Nuno Sá
  and Jonathan Cameron: the FA/FB rejection infrastructure comes first,
  and the LTC2493 is then introduced complete in a single patch instead
  of growing a chip_info entry over four of them.
- The input count is modelled as a number rather than a bool, so further
  family members do not each add a branch (Jonathan Cameron).
- FA/FB is modelled as a 2-bit field rather than two independent flags,
  with the mapping helper removed (Jonathan Cameron).
- Addressed the locking, comment and churn review on the FA/FB patch.
- Behaviour is unchanged, re-verified by hardware regression on all
  three parts; see the validation summary above.
- Per-patch changelogs are under the --- of each patch.
- Link to v1: https://lore.kernel.org/r/20261009-submission-ltc2493-support-v1-v1-0-3dad1d4b152a@analog.com

---
Andrei Stancovici (3):
      dt-bindings: iio: adc: lltc,ltc2497: add LTC2493 support
      iio: adc: ltc2497: add FA/FB line-frequency rejection selection
      iio: adc: ltc2497: add LTC2493 support

 .../devicetree/bindings/iio/adc/lltc,ltc2497.yaml  |   7 +
 drivers/iio/adc/ltc2496.c                          |   1 +
 drivers/iio/adc/ltc2497-core.c                     | 227 +++++++++++++++++----
 drivers/iio/adc/ltc2497.c                          |  47 +++--
 drivers/iio/adc/ltc2497.h                          |  31 ++-
 5 files changed, 251 insertions(+), 62 deletions(-)
---
base-commit: a3b3580713f3ac5a32dc2874ee546828977a1d68
change-id: 20261009-submission-ltc2493-support-v1-86449ede432d

Best regards,
--  
Andrei Stancovici <andrei.stancovici@analog.com>

