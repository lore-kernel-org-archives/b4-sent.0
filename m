From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v3 0/3] reset: support reset for Amlogic A9 SoC
Date: Thu, 26 Nov 2026 09:53:37 +0000
Message-Id: <20261126-a9-reset-v3-0-fb9bb01f33d1@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKEBCGsC/1WMwQ6CMBAFf4Xs2ZqlRaCe/A/jAdotNBFKWtJoC
 P9uITHicV7ezAKBvKUA12wBT9EG68YE4pSB6puxI2Z1YuDIS6ywZI1kngLNTCohqTa6xVJDuk+
 ejH3tqfsjcW/D7Px7L8d8W78R+YvEnCEzulIGhWzri7g1w9N1Vp2VG2DLRH5Q8+Kg8qTW2qBsu
 SlEpf7VdV0/PdiiEt0AAAA=
X-Change-ID: 20260706-a9-reset-9c39e8fdb06d
To: Philipp Zabel <p.zabel@pengutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795686819; l=1303;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=L96yI3Yx/j1d5Y6jYRCC8qNnGbrQ6QxdVZQl+y4ySbs=;
 b=WMm59vQS484rXbcEcS4wquK1SzMIxM+At+yBWURtC90oFy1BzU7wucfOBfl3VRHdXvT1ICQoB
 P6l6pxsUsTSAf1vR1tF7V7HtpxD7gOpiR05J67x6YVg14qSBKDWXRD/
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the reset controller compatibles used by the Amlogic A9 SoC, and
add the reset configuration and compatible entry for the Amlogic A9 AO
reset controller, and add reset node for Amlogic A9.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v3:
- Update the header guard to use a consistent naming convention.
- Add Neil Armstrong's Reviewed-by tag.
- Link to v2: https://lore.kernel.org/r/20260714-a9-reset-v2-0-8df09b2f437c@amlogic.com

Changes in v2:
- Use standard node name reset-controller.
- Link to v1: https://lore.kernel.org/r/20260709-a9-reset-v1-0-fd7cf039b853@amlogic.com

---
Xianwei Zhao (3):
      dt-bindings: reset: amlogic: Add A9 reset compatibles
      reset: amlogic: Add A9 AO reset controller support
      arm64: dts: amlogic: a9: Add reset controller support

 .../bindings/reset/amlogic,meson-reset.yaml        |   5 +
 arch/arm64/boot/dts/amlogic/amlogic-a9-reset.h     | 247 +++++++++++++++++++++
 arch/arm64/boot/dts/amlogic/amlogic-a9.dtsi        |  14 ++
 drivers/reset/amlogic/reset-meson.c                |   9 +
 4 files changed, 275 insertions(+)
---
base-commit: 807a34cf91c1d91f2beb3cacef9eaa98bd56d172
change-id: 20260706-a9-reset-9c39e8fdb06d

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

