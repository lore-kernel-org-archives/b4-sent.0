From: Roman Vivchar <rva333@protonmail.com>
Subject: [PATCH 0/4] iio: light: stk3310: stk3337 support + vdd supply
Date: Sun, 08 Nov 2026 00:15:02 +0200
Message-Id: <20261108-6768-stk3337-v1-0-0340c99b0e33@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQwNzXTNzMwvd4pJsY2Njc11jkzTzRKOUJONEIxMloJaCotS0zAqwcdG
 xEH5xaVJWanIJyAyl2loAwwIPuXAAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794089703; l=969;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=J7EpCcudKslIFmWVaj/lQjrcW5V1778FeNRCMHZxV0w=;
 b=XeBpOofutHPzMGqYAXYM0cq2/fNQbuU0FzLK8+nly2nwniSkzxA+lSGzqbSFGta1w3+onjACD
 vMo6ACJMzTXBEnmJ63XAcVVj4ruT8xL3D9amAZQpk3rZEh1we0IezUp
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
Roman Vivchar <rva333@protonmail.com>

