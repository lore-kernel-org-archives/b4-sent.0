From: Asdlerto Korry <korryasdlerto@gmail.com>
Subject: [PATCH 0/2] power: supply: Add Silicon Mitus SM5714 fuel gauge
Date: Wed, 11 Nov 2026 17:34:58 +0200
Message-Id: <20261111-sm5714-fuel-gauge-v1-0-b9d163fff6ff@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACKL9GoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDINAtzjU1NzTRTStNzdFNTywFKkg2TjYzNDcwtzAyMVAC6isoSk3LrAC
 bGR1bWwsANTEWw2MAAAA=
X-Change-ID: 20261111-sm5714-fuel-gauge-c3c617078240
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Asdlerto Korry <korryasdlerto@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794411298; l=1685;
 i=korryasdlerto@gmail.com; s=20261104; h=from:subject:message-id;
 bh=76ei+RgM9hKvisAUftK3npdW06X58VHxTiIil5MR6B0=;
 b=TkmNnO8CvraYln5cWpyEJnk+YbdPl6bcnr+37wPdYhFCMhmxzda+T+C7zs/egAxxNprrt+JSk
 jOtDwliwEtGCKk0cu7Yf1YzqtygFkO+Qrn5nNLb7b74FJFcffRLUCo1
X-Developer-Key: i=korryasdlerto@gmail.com; a=ed25519;
 pk=RqttIGkm2XZ8NhLQBzPgpXXawOdVa1uODGsk+sagbxs=
X-Endpoint-Received: by B4 Relay for korryasdlerto@gmail.com/20261104 with auth_id=1411
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Silicon Mitus SM5714 is a power management chip for mobile phones
with a charger, a USB Type-C port controller, a MUIC and a fuel gauge,
each on its own I2C address. It is used in the Samsung Galaxy M52 5G
(SM7325).

This series adds a binding and a read-only driver for the fuel gauge
part. It reports the state of charge, the battery voltage and current
and the battery temperature. The temperature measured by the gauge
itself rises with the charge current, so an optional ADC channel can
point at the battery thermistor.

Tested on a Samsung Galaxy M52 5G with the driver backported to 7.1:
the voltage, open-circuit voltage and current match the out-of-tree
driver used before, and the status follows the cable (discharging when
unplugged, full when plugged in with a full battery).

The charger and Type-C parts of the chip, and the devicetree nodes for
the M52, will come in separate series.

Signed-off-by: Asdlerto Korry <korryasdlerto@gmail.com>
---
Asdlerto Korry (2):
      dt-bindings: power: supply: Add Silicon Mitus SM5714 fuel gauge
      power: supply: Add Silicon Mitus SM5714 fuel gauge driver

 .../supply/siliconmitus,sm5714-fuelgauge.yaml      |  53 ++++
 MAINTAINERS                                        |   7 +
 drivers/power/supply/Kconfig                       |  13 +
 drivers/power/supply/Makefile                      |   1 +
 drivers/power/supply/sm5714_fuel_gauge.c           | 315 +++++++++++++++++++++
 5 files changed, 389 insertions(+)
---
base-commit: 7649ba73f9e7e1e04d0b46213e39c79ae09dd55c
change-id: 20261111-sm5714-fuel-gauge-c3c617078240

Best regards,
-- 
Asdlerto Korry <korryasdlerto@gmail.com>

