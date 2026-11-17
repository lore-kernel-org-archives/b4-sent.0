From: Roman Vivchar <rva333@protonmail.com>
Subject: [PATCH v2 0/4] iio: light: stk3310: stk3337 support + vdd supply
Date: Tue, 17 Nov 2026 20:08:34 +0200
Message-Id: <20261117-6768-stk3337-v2-0-92f4c7be3bc6@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/1WNwQ6CMBAFf4X0bE3bJRQ8+R+GQymLrEpL2ko0h
 H8XMB48TjJv3swiBsLITtnMAk4UybsV1CFjtjfuipzalZkSqpBSaF7oouQx3QFAc8g7bVTbgFE
 5WydjwI5ee+5Sfzk+mxvatDU2o6eYfHjvf5PcvF+6/E9PkgsuIBe2qhqBAOcx+OTdYOhxtH5g9
 bIsH784dBa/AAAA
X-Change-ID: 20261107-6768-stk3337-34f7a2db3a24
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794938915; l=1167;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=FAzYg1TpkGb7wV9Cp24G4J88VqcXA/Aizp5voUGpLIQ=;
 b=6DmnmMwYtz0Vf7smueOV07bHGdtjBO13koGOuoiSbrCd7WOyFnkfDRXZu0zhA4D2qncrZwm7A
 5C3y9IwNJfuDkU/nM6IkztzB5J3h2KYLANT1/hWwPiUAvjELJ73IEI3
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds support for stk3337 light sensor, found in the
Xiaomi Redmi Note 9 phone. The sensor is compatible with stk3310
registers, while having Clear channel, similar to the stk36c61.

The series also adds vdd-supply property, since on this board the sensor
is wired to the shared power supply.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
Changes in v2:
- Clarify that stk3337 is a subset of the stk36c61 in patch 4 commit message (Jonathan)
- Link to v1: https://patch.msgid.link/20261108-6768-stk3337-v1-0-0340c99b0e33@protonmail.com

---
Roman Vivchar (4):
      dt-bindings: iio: light: stk33xx: add power supply support
      dt-bindings: iio: light: stk33xx: add stk3337
      iio: light: stk3310: add vdd regulator support
      iio: light: stk3310: add stk3337 support

 .../devicetree/bindings/iio/light/stk33xx.yaml      |  3 +++
 drivers/iio/light/stk3310.c                         | 21 +++++++++++++++++++++
 2 files changed, 24 insertions(+)
---
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20261107-6768-stk3337-34f7a2db3a24

Best regards,
--  
rva3 <rva333@protonmail.com>

