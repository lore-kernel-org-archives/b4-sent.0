From: Nizat Mikayilli <nacht@dxdmail.cc>
Subject: [PATCH 0/2] power: supply: Add Silicon Mitus SM5714 fuel gauge
Date: Sun, 08 Nov 2026 12:22:24 +0100
Message-Id: <20261108-b4-sm5714-fuel-gauge-v1-0-c659b6c0884a@dxdmail.cc>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2M2wpAQBBAf0XzbGpHWPyKPDDGmnJrN1Ly7zaPp
 845DwTxKgGa5AEvlwbdtwiUJsBzvzlBHSNDZrKSyFQ45BjWwlKO0ykLuv6MDvMglqkmNgwxPbx
 Mev/btnvfD/4vLNlmAAAA
X-Change-ID: 20261108-b4-sm5714-fuel-gauge-ccbe7c191c0c
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Nizat Mikayilli <nacht@dxdmail.cc>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794136945; l=1211;
 i=nacht@dxdmail.cc; s=20261004; h=from:subject:message-id;
 bh=G4eLbQVc7Ut3i550ga26bqAGN7kV6jqBGKLCtmfUKLc=;
 b=DLCmbW5H/qvvM7izdoeqCMWESI+C+PhwFfIouDn7sRaNwibvHzMEW6u7cfLiekx19DKpR0/gR
 J9d0opx947kC8Ha8ouYy5QjlR+HeIG24m4AGgGYHnQ0+/XhvrdcGWKc
X-Developer-Key: i=nacht@dxdmail.cc; a=ed25519;
 pk=Kay3P3pOJq5klUD+0/I8QX8JGOh0CeQXEwRVv7CMm4k=
X-Endpoint-Received: by B4 Relay for nacht@dxdmail.cc/20261004 with auth_id=1111
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Samsung Galaxy Tab S9 Wi-Fi uses the fuel gauge of the Silicon
Mitus SM5714. This series adds a binding and a small driver for it,
which reports the state of charge, voltage, current and status.

The fuel gauge node for the tablet will be sent with its board series:
https://lore.kernel.org/r/20261022-gts9wifi-dts-v4-0-a361428fe59c@dxdmail.cc

I tested it on the tablet, with the USB cable in and out, and the
power-supply selftest passes.

Signed-off-by: Nizat Mikayilli <nacht@dxdmail.cc>
---
Nizat Mikayilli (2):
      dt-bindings: power: supply: Add Silicon Mitus SM5714 fuel gauge
      power: supply: Add Silicon Mitus SM5714 fuel gauge driver

 .../supply/siliconmitus,sm5714-fuel-gauge.yaml     |  47 +++++
 MAINTAINERS                                        |   7 +
 drivers/power/supply/Kconfig                       |  10 +
 drivers/power/supply/Makefile                      |   1 +
 drivers/power/supply/sm5714-battery.c              | 221 +++++++++++++++++++++
 5 files changed, 286 insertions(+)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261108-b4-sm5714-fuel-gauge-ccbe7c191c0c

Best regards,
-- 
Nizat Mikayilli <nacht@dxdmail.cc>

