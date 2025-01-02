From: Thomas Antoine <t.antoine@uclouvain.be>
Subject: [PATCH v2 0/4] Google Pixel 6 (oriole): max77759 fuel gauge
 enablement and driver support
Date: Thu, 02 Jan 2025 12:15:02 +0100
Message-Id: <20250102-b4-gs101_max77759_fg-v2-0-87959abeb7ff@uclouvain.be>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIADZ1dmcC/4WNWwqDMBREtyL3uyl5ldR+dR9FJNEbvdAaSWqwi
 Htv6gb6M3AG5swGCSNhglu1QcRMicJUQJ4q6EY7DcioLwySSy1KMKfZkAQX7cuuxphL3fqBaS5
 RKmG1UwrKdI7oaT20j6bwSOkd4ud4yeLX/hFmwTirr7301jiPit+X7hmWbGk6O4Rm3/cvUWaGq
 bsAAAA=
X-Change-ID: 20241202-b4-gs101_max77759_fg-402e231a4b33
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dimitri Fedrau <dima.fedrau@gmail.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-samsung-soc@vger.kernel.org, Thomas Antoine <t.antoine@uclouvain.be>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735816515; l=1708;
 i=t.antoine@uclouvain.be; s=20241202; h=from:subject:message-id;
 bh=BCKCRIacyWKgqo6gAegHeTB5UJABaGjYit2k0RzaGXo=;
 b=nNwiaZEpXaE/xmq13KUaZhCVGXxQKaEr/PxDVQPiVg9kT2kvTD0OYSbdMx2Gh/O1M5enu4LZj
 vL6grHmE2QpAp6Z94gjM2/KM23we6cqO7iHL2goR6lHLpCb0jy0IE1L
X-Developer-Key: i=t.antoine@uclouvain.be; a=ed25519;
 pk=sw7UYl31W1LTpgWRiX4xIF5x6ok7YWZ6XZnHqy/d3dY=
X-Endpoint-Received: by B4 Relay for t.antoine@uclouvain.be/20241202 with auth_id=289
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Google Pixel 6 has a Maxim max77759 which provides a fuel gauge with
an interface with a lot in common with the Maxim max1720x.

Modify the Maxim max1720x driver to be compatible with the Maxim max77759 and
enable it for the gs101-oriole board.

Signed-off-by: Thomas Antoine <t.antoine@uclouvain.be>
---
Changes in v2:
- Add fallback for voltage measurement (André Draszik)
- Add regmap for the max77759 (André Draszik)
- Add chip identification for the max77759 (André Draszik, Peter Griffin)
- Move RSense value to a devicetree property shunt-resistor-micro-ohms
  (Dimitri Fedrau, André Draszik)
- Use allOf:if to narrow binding per variant (Krzysztof Kozlowski)
- Remove binding example (Krzysztof Kozlowski)
- Change defconfig order to follow savedefconfig (Krzysztof Kozlowski)
- Fix style errors
- Link to v1: https://lore.kernel.org/r/20241202-b4-gs101_max77759_fg-v1-0-98d2fa7bfe30@uclouvain.be

---
Thomas Antoine (4):
      power: supply: add support for max77759 fuel gauge
      dt-bindings: power: supply: add max77759-fg flavor
      arm64: defconfig: enable Maxim max1720x driver
      arm64: dts: exynos: gs101-oriole: enable Maxim max77759 fuel gauge

 .../bindings/power/supply/maxim,max17201.yaml      |  56 ++++--
 arch/arm64/boot/dts/exynos/google/gs101-oriole.dts |  10 ++
 arch/arm64/configs/defconfig                       |   1 +
 drivers/power/supply/max1720x_battery.c            | 189 ++++++++++++++++++---
 4 files changed, 218 insertions(+), 38 deletions(-)
---
base-commit: 12e0a4072e8edc49c99418a4303bd7b96916de95
change-id: 20241202-b4-gs101_max77759_fg-402e231a4b33

Best regards,
-- 
Thomas Antoine <t.antoine@uclouvain.be>

