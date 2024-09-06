From: Kelvin Zhang <kelvin.zhang@amlogic.com>
Subject: [PATCH 0/2] Add support for Amlogic C3 PWM
Date: Fri, 06 Sep 2024 20:46:11 +0800
Message-Id: <20240906-c3-pwm-v1-0-acaf17fad247@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJP52mYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDSwMz3WRj3YLyXN0UQ3MDcyNTQ3MLIzMloOKCotS0zAqwQdGxtbUAHXP
 JPFgAAAA=
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-pwm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, Kelvin Zhang <kelvin.zhang@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725626786; l=600;
 i=kelvin.zhang@amlogic.com; s=20240329; h=from:subject:message-id;
 bh=Af4hVO2lEqJLghX243SGdJHNChv8mD1EBsYO0E+v2XY=;
 b=8dq3owc63Flh3oSrwiJ6ZbPd7n2PLeqykBE4++TGv2VCDPWshqQnmin/SpZG7z2QVX5yEfHtP
 IzzrWBjOQ0uARrFv2gIh3PY+imduyZF5JwpKVMDj22KLSq1Sx4uls6O
X-Developer-Key: i=kelvin.zhang@amlogic.com; a=ed25519;
 pk=pgnle7HTNvnNTcOoGejvtTC7BJT30HUNXfMHRRXSylI=
X-Endpoint-Received: by B4 Relay for kelvin.zhang@amlogic.com/20240329 with auth_id=148
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for Amlogic C3 PWM, including the DT binding document and DTS.

Signed-off-by: Kelvin Zhang <kelvin.zhang@amlogic.com>
---
Kelvin Zhang (2):
      dt-bindings: pwm: amlogic: Document C3 PWM
      arm64: dts: amlogic: Add Amlogic C3 PWM

 .../devicetree/bindings/pwm/pwm-amlogic.yaml       |   4 +
 arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi        | 364 +++++++++++++++++++++
 2 files changed, 368 insertions(+)
---
base-commit: ad40aff1edffeccc412cde93894196dca7bc739e
change-id: 20240906-c3-pwm-d17072517826

Best regards,
-- 
Kelvin Zhang <kelvin.zhang@amlogic.com>

