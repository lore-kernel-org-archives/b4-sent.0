From: Roman Vivchar <rva333@protonmail.com>
Subject: [PATCH v3 0/7] iio: light: stk3310: refactoring and new chip
 support
Date: Sun, 22 Nov 2026 19:15:41 +0200
Message-Id: <20261122-6768-stk3337-v3-0-b0d0a924e843@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2XOTQ7CIBAF4Ks0rMUAQ6B15T2MC6DUorY0UImm6
 d0tNSb+LF/y5nszoWiDsxHtigkFm1x0vl8CbApkWtWfLHb1khEjTFBKJBZSlDiOFwCQGHgjFas
 1KMbRcjIE27j7yh2Orxxv+mzNmI3caF0cfXise4nm3psuv+lEMcEEODFVpYkF2A/Bj77vlLtuj
 e9Q9hP7EOjPc4ktQsUabqS2oI34E+Z5fgI5GlYIAQEAAA==
X-Change-ID: 20261107-6768-stk3337-34f7a2db3a24
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Joshua Crofts <crofts@kernel.org>, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Roman Vivchar <rva333@protonmail.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795367795; l=1636;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=2HH/HfdtFY3GEA+ss6XCFk9efzMGE8PhUZ5o2ui45Ac=;
 b=mSlQoXrvmtI+m2p+Qk1db41/fr0QqUtgUyMI8Mb3aUa2sLNnylKR/bxAaxqdHhaYjTb7Z/iAJ
 +20v4gc80YOCXMWqPlf9VdEcW4lCfidKKyCsEW9EYbSFbCk40lNhY1u
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds support for stk3337 light sensor, found in the
Xiaomi Redmi Note 9 phone. The sensor is compatible with stk3310
registers, while having Clear channel, similar to the stk36c61.

It also adds support for stk3331-a sensor in Realme C3 phone.
It's stk3337 but in a different package.

Additionally, there's patch for vdd-supply property, since sensor can be
wired to the shared power supply.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
Changes in v3:
- Add patch to migrate to devm_* helpers (Joshua)
- Add stk3331 patches
- Link to v2: https://patch.msgid.link/20261117-6768-stk3337-v2-0-92f4c7be3bc6@protonmail.com

Changes in v2:
- Clarify that stk3337 is a subset of the stk36c61 in patch 4 commit message (Jonathan)
- Link to v1: https://patch.msgid.link/20261108-6768-stk3337-v1-0-0340c99b0e33@protonmail.com

---
Roman Vivchar (7):
      iio: light: stk3310: migrate to devm_* API
      dt-bindings: iio: light: stk33xx: add power supply support
      iio: light: stk3310: add vdd regulator support
      dt-bindings: iio: light: stk33xx: add stk3337
      iio: light: stk3310: add stk3337 support
      dt-bindings: iio: light: stk33xx: add stk3331
      iio: light: stk3310: add STK3331-A support

 .../devicetree/bindings/iio/light/stk33xx.yaml     |  7 +++
 drivers/iio/light/stk3310.c                        | 60 ++++++++++++++--------
 2 files changed, 47 insertions(+), 20 deletions(-)
---
base-commit: ddfe51b0a0f5dc9e415cc2c8ad8db17532dd426b
change-id: 20261107-6768-stk3337-34f7a2db3a24

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

