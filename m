From: Kelvin Zhang <kelvin.zhang@amlogic.com>
Subject: [PATCH v4 0/2] Add support for Amlogic S4 PWM
Date: Wed, 24 Apr 2024 18:28:33 +0800
Message-Id: <20240424-s4-pwm-v4-0-ee22effd40d0@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANHeKGYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyTHQUlJIzE
 vPSU3UzU4B8JSMDIxMDEyMT3WIT3YLyXF2jFHMDS0sLs+TE1FQloOKCotS0zAqwQdGxtbUAPQl
 xMVgAAAA=
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@pengutronix.de>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pwm@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Kelvin Zhang <kelvin.zhang@amlogic.com>, 
 Junyi Zhao <junyi.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713954523; l=576;
 i=kelvin.zhang@amlogic.com; s=20240329; h=from:subject:message-id;
 bh=GMt3bHr/0bLk2xq/2azl7lpbQ/7wyhQOM8zaZNjnyJ0=;
 b=TJKESOCW+E486eRlzDgVjMM/9EfdVstKhuRksh8I/7CdeV2Sshl9LaATqxJ4K0X9H8NWr9d1G
 j4Gd58lMfR6D3a73YnsRiP73TFBL96sadimEK3pE0IWTOHeowhjLA4j
X-Developer-Key: i=kelvin.zhang@amlogic.com; a=ed25519;
 pk=pgnle7HTNvnNTcOoGejvtTC7BJT30HUNXfMHRRXSylI=
X-Endpoint-Received: by B4 Relay for kelvin.zhang@amlogic.com/20240329 with auth_id=148
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for Amlogic S4 PWM and related device nodes.

Signed-off-by: Kelvin Zhang <kelvin.zhang@amlogic.com>
---
Junyi Zhao (2):
      pwm: meson: Add support for Amlogic S4 PWM
      arm64: dts: amlogic: Add Amlogic S4 PWM

 arch/arm64/boot/dts/amlogic/meson-s4.dtsi | 207 ++++++++++++++++++++++++++++++
 drivers/pwm/pwm-meson.c                   |  37 ++++++
 2 files changed, 244 insertions(+)
---
base-commit: a59668a9397e7245b26e9be85d23f242ff757ae8
change-id: 20240424-s4-pwm-2d709986caee

Best regards,
-- 
Kelvin Zhang <kelvin.zhang@amlogic.com>

