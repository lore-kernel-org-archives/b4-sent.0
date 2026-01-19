From: Petr Hodina <petr.hodina@protonmail.com>
Subject: [PATCH 0/3] iio: light: add AMS TCS3400 driver
Date: Mon, 19 Jan 2026 18:19:05 +0100
Message-Id: <20260119-tsc3400-v1-0-82a65c5417aa@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIlnbmkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDQ0NL3ZLiZGMTAwNdM4tES8MUi2RDY1NTJaDqgqLUtMwKsEnRsbW1ANA
 32vFZAAAA
X-Change-ID: 20260119-tsc3400-68a91d8c1355
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, David Heidelberg <david@ixit.cz>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768843157; l=1197;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=VeK13ypBHOfjYHA6gWEHJp+oDUN8gaTIycXBoszv1bQ=;
 b=WK3hd2ENhnZO6FOBcTgdGO+GUM2e8gxz72WPSWqDbwW9wEmdU1p9Tv/xjNVCh0YHBM1iFSU3j
 PGDMetvtTJ2BZ/ljOfBRccGMsXYYYq7c61jxkt+dPJxN9Qk1yY6+nvC
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This patch adds an IIO driver for the AMS TCS3400 color light-to-digital
converter.

The TCS3400 is an I2C-connected RGB color sensor supporting RGBC and
RGB-IR measurement modes, programmable integration time, selectable
gain, optional interrupt-driven sampling, and regulator-based power
control.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
Petr Hodina (3):
      doc: add Device Tree binding for AMS TCS3400 light sensor
      iio: light: add AMS TCS3400 RGB and RGB-IR color sensor driver
      sdm845: tama: Add AMS TCS3400 ambient light sensor

 .../devicetree/bindings/iio/light/ams,tcs3400.yaml |  54 +++
 MAINTAINERS                                        |   7 +
 .../boot/dts/qcom/sdm845-sony-xperia-tama.dtsi     |  36 +-
 drivers/iio/light/Kconfig                          |  11 +
 drivers/iio/light/Makefile                         |   1 +
 drivers/iio/light/tcs3400.c                        | 505 +++++++++++++++++++++
 6 files changed, 613 insertions(+), 1 deletion(-)
---
base-commit: 46fe65a2c28ecf5df1a7475aba1f08ccf4c0ac1b
change-id: 20260119-tsc3400-68a91d8c1355

Best regards,
-- 
Petr Hodina <petr.hodina@protonmail.com>

