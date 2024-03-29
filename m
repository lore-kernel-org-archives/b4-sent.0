From: Kelvin Zhang <kelvin.zhang@amlogic.com>
Subject: [PATCH 0/3] Add support for Amlogic T7 Reset
Date: Fri, 29 Mar 2024 17:17:12 +0800
Message-Id: <20240329-t7-reset-v1-0-4c6e2e68359e@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABiHBmYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDYyNL3RJz3aLU4tQS3TQL81QLYxOztMSUJCWg8oKi1LTMCrBR0bG1tQB
 080UQWgAAAA==
To: Philipp Zabel <p.zabel@pengutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Zelong Dong <zelong.dong@amlogic.com>, 
 Kelvin Zhang <kelvin.zhang@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711703853; l=866;
 i=kelvin.zhang@amlogic.com; s=20240329; h=from:subject:message-id;
 bh=n/GJizp9nm7qN6fx85RRF4G4vfz5pWZJJrrOuOIEosg=;
 b=2HDdcu8bHK28/Vw6Upe0zpsGUXqXEi9POhJTjRSNSmOBU3TqML/IbpwEUaPrQTa6cUJL5+rk5
 +Z9Y3JC24v2CfMsbzDGndOgSjtVeZCAMsQG6uX4CC8Pxmf6XUIMMBaA
X-Developer-Key: i=kelvin.zhang@amlogic.com; a=ed25519;
 pk=pgnle7HTNvnNTcOoGejvtTC7BJT30HUNXfMHRRXSylI=
X-Endpoint-Received: by B4 Relay for kelvin.zhang@amlogic.com/20240329 with auth_id=148
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a new compatible and device node for Amlogic T7 Reset.

Signed-off-by: Zelong Dong <zelong.dong@amlogic.com>
Signed-off-by: Kelvin Zhang <kelvin.zhang@amlogic.com>
---
Zelong Dong (3):
      dt-bindings: reset: Add Amlogic T7 Reset Controller
      reset: reset-meson: add support for Amlogic T7 SoC Reset Controller
      arm64: dts: amlogic: add reset controller for Amlogic T7 SoC

 .../bindings/reset/amlogic,meson-reset.yaml        |   1 +
 arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi        |   7 +
 drivers/reset/reset-meson.c                        |   6 +
 include/dt-bindings/reset/amlogic,t7-reset.h       | 197 +++++++++++++++++++++
 4 files changed, 211 insertions(+)
---
base-commit: a6bd6c9333397f5a0e2667d4d82fef8c970108f2
change-id: 20240329-t7-reset-f87e8346fadb

Best regards,
-- 
Kelvin Zhang <kelvin.zhang@amlogic.com>

