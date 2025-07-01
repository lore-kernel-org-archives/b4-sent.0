From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v7 00/20] mfd: adp5585: support keymap events and drop
 legacy Input driver
Date: Tue, 01 Jul 2025 15:31:55 +0100
Message-Id: <20250701-dev-adp5589-fw-v7-0-b1fcfe9e9826@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAFzxY2gC/2XQ3UoDMRCG4VspOTYymfyOR96HeDCbZNuA7pZdi
 UrZezctyFZz+AWedyAXseal5FU8HS5iybWsZZ7a8A8HEU88HbMsqW2BgBa0UjLlKjmdrQ0kx0+
 ZwcQxkbEYnGjovOSxfN2CL69tn8r6MS/ft35V19fflP6fqkqCRMgBkhmSyfzME7/Nx8c4v4trq
 +LujbKdx+Y1e6KocwoKO693bxV2XjcPhIMygycOofPmzmP3FdU0P2KkEJJnz9B5u3unTOdt8z5
 TCobAoevvuzuvofOueYZREzIMTOqP37btB2Uk0RztAQAA
X-Change-ID: 20250311-dev-adp5589-fw-e04cfd945286
To: linux-gpio@vger.kernel.org, linux-pwm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-input@vger.kernel.org
Cc: Lee Jones <lee@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Liu Ying <victor.liu@nxp.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@linaro.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751380320; l=2789;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=rqJXkoluTBUb8/TC3f6BkLvnwz9KDd39/fIEKWYuoQ8=;
 b=kdpaPC6QvTEVwYqCdDRCXSZVZxESkOXpnXuXJRkJ980kTIWXdAyFO/WBXgXMk05xtioAStEU1
 3z00gUZ7yi3AVcgA1+03fBy17Ya+OwUo4MQen3OvYLAtHAckqxsqJAF
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi all,

Here it goes v7 with proper changelogs. Also took opportunity to fix
some spelling issues brought by Uwe.

Thanks!
- Nuno Sá

---
- Link to v5: https://lore.kernel.org/r/20250614-dev-adp5589-fw-v5-0-7e9d84906268@analog.com
- Link to v4: https://lore.kernel.org/r/20250521-dev-adp5589-fw-v4-0-f2c988d7a7a0@analog.com
- Link to v3: https://lore.kernel.org/r/20250512-dev-adp5589-fw-v3-0-092b14b79a88@analog.com
- Link to v2: https://lore.kernel.org/r/20250415-dev-adp5589-fw-v2-0-3a799c3ed812@analog.com
- Link to v1: https://lore.kernel.org/r/20250313-dev-adp5589-fw-v1-0-20e80d4bd4ea@analog.com
- Link to v6: https://lore.kernel.org/r/20250630-dev-adp5589-fw-v6-0-a0f392a0ba91@analog.com

---
Nuno Sá (20):
      dt-bindings: mfd: adp5585: ease on the required properties
      mfd: adp5585: Only add devices given in FW
      mfd: adp5585: Enable oscillator during probe
      mfd: adp5585: Make use of MFD_CELL_NAME()
      dt-bindings: mfd: adp5585: document adp5589 I/O expander
      mfd: adp5585: Refactor how regmap defaults are handled
      mfd: adp5585: Add support for adp5589
      mfd: adp5585: Add a per chip reg struture
      gpio: adp5585: add support for the adp5589 expander
      pwm: adp5585: add support for adp5589
      dt-bindings: mfd: adp5585: add properties for input events
      mfd: adp5585: Add support for event handling
      mfd: adp5585: Support reset and unlock events
      mfd: adp5585: Add support for input devices
      gpio: adp5585: support gpi events
      Input: adp5585: Add Analog Devices ADP5585/89 support
      Input: adp5589: remove the driver
      mfd: adp5585: Support getting vdd regulator
      dt-bindings: mfd: adp5585: document reset gpio
      mfd: adp5585: Add support for a reset pin

 .../devicetree/bindings/mfd/adi,adp5585.yaml       |  240 ++++-
 .../devicetree/bindings/trivial-devices.yaml       |    2 -
 MAINTAINERS                                        |    1 +
 drivers/gpio/Kconfig                               |    1 +
 drivers/gpio/gpio-adp5585.c                        |  364 ++++++-
 drivers/input/keyboard/Kconfig                     |   21 +-
 drivers/input/keyboard/Makefile                    |    2 +-
 drivers/input/keyboard/adp5585-keys.c              |  371 +++++++
 drivers/input/keyboard/adp5589-keys.c              | 1066 --------------------
 drivers/mfd/adp5585.c                              |  741 +++++++++++++-
 drivers/pwm/pwm-adp5585.c                          |   78 +-
 include/linux/mfd/adp5585.h                        |  118 ++-
 12 files changed, 1797 insertions(+), 1208 deletions(-)
---
base-commit: 407f60a151df3c44397e5afc0111eb9b026c38d3
change-id: 20250311-dev-adp5589-fw-e04cfd945286
--

Thanks!
- Nuno Sá

