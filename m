From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Subject: [PATCH v9 0/5] PWM and keyboard backlight driver for ARM Macs
Date: Sat, 11 Mar 2023 06:11:08 +0100
Message-Id: <20230214-fpwm-v9-0-dbe26bccabd6@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGwNDGQC/22Nyw6DIBBFf8WwLg0qCnbV/2i64DEoSREDhrYx/
 nvBVdN0ee/cc2ZDEYKFiC7VhgIkG62fcxhOFVKTmEfAVueMGtK0pKkpNsvTYc0N66XiWqsa5ak
 UEbAMYlZTGTsRVwjlsAQw9nX4b/ecJxtXH97Hu8RK+2NODBNsJBG9NFKTll1HJ+zjrLxDRZD4P
 4hnqO+6mgui6UDpN7Tv+weMR6Z/5gAAAA==
To: Thierry Reding <thierry.reding@gmail.com>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@pengutronix.de>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 - <asahi@lists.linux.dev>, Sasha Finkelstein <fnkl.kernel@gmail.com>, 
 Hector Martin <marcan@marcan.st>, Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>
Cc: linux-pwm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 Sasha Finkelstein <7d578vix8hzw@opayq.net>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1678511469; l=2133;
 i=fnkl.kernel@gmail.com; s=20230213; h=from:subject:message-id;
 bh=cb5irgm1G4DAU5Vt0m927jUYDxIYKozT423yaayaW8s=;
 b=DD418MqqObwyR9NLdrnm0IOz7ab33zBMKOvaaamKf3FL6VPmoIacpE7GnO0bCEhpYhzEhASDW
 J+2WDCdMHKCBax2yGKOHWZU2lvibFL/Y77ILM9y3z6NwFoTRr3zCo9E
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=7LFSAJtxIWAs9LzCIyX0sSvCZy2wQTyEIu1zch6o804=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20230213 with auth_id=28
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This is the v9 of the patch series to add PWM and keyboard
backlight driver for ARM macs.

Changes in v1:
Addressing the review comments.

Changes in v2:
Added the reviewed-by and acked-by tags.
Addressing a review comment.

Changes in v3 and v4:
Addressing the review comments.

Changes in v5:
Added t600x device tree changes

Changes in v8:
Changed the overflow handling to clamp instead of erroring.

Changes in v9:
Missed a spot where clamping should be applied. Fixed that.

v1: https://www.spinics.net/lists/linux-pwm/msg19500.html
v2: https://www.spinics.net/lists/linux-pwm/msg19562.html
v3: https://www.spinics.net/lists/linux-pwm/msg19901.html
v4: https://www.spinics.net/lists/linux-pwm/msg20093.html
v5: https://www.spinics.net/lists/linux-pwm/msg20150.html
v6: https://www.spinics.net/lists/linux-pwm/msg20190.html
v7: https://lore.kernel.org/r/20230214-fpwm-v7-0-fb0a6bfbd037@gmail.com
v8: https://lore.kernel.org/r/20230214-fpwm-v8-0-65518a0d4944@gmail.com

---
Sasha Finkelstein (5):
      dt-bindings: pwm: Add Apple PWM controller
      pwm: Add Apple PWM controller
      arm64: dts: apple: t8103: Add PWM controller
      arm64: dts: apple: t600x: Add PWM controller
      MAINTAINERS: Add entries for Apple PWM driver

 .../devicetree/bindings/pwm/apple,s5l-fpwm.yaml    |  51 +++++++
 MAINTAINERS                                        |   2 +
 arch/arm64/boot/dts/apple/t600x-die0.dtsi          |   9 ++
 arch/arm64/boot/dts/apple/t600x-j314-j316.dtsi     |  18 +++
 arch/arm64/boot/dts/apple/t8103-j293.dts           |  17 +++
 arch/arm64/boot/dts/apple/t8103-j313.dts           |  17 +++
 arch/arm64/boot/dts/apple/t8103.dtsi               |   9 ++
 drivers/pwm/Kconfig                                |  12 ++
 drivers/pwm/Makefile                               |   1 +
 drivers/pwm/pwm-apple.c                            | 159 +++++++++++++++++++++
 10 files changed, 295 insertions(+)
---
base-commit: fe15c26ee26efa11741a7b632e9f23b01aca4cc6
change-id: 20230214-fpwm-d8f76bc8ddc1

Best regards,
-- 
Sasha Finkelstein <fnkl.kernel@gmail.com>

