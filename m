From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v5 00/20] mfd: adp5585: support keymap events and drop
 legacy Input driver
Date: Sat, 14 Jun 2025 15:35:51 +0100
Message-Id: <20250614-dev-adp5589-fw-v5-0-7e9d84906268@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAMeITWgC/2XQTQ7CIBCG4asY1mJgAAuuvIdxMYWpkmhrWoMa0
 7tLmxh/WH6TPO9inmygPtLANosn6ynFIXZtHma5YP6I7YF4DHkzEGCEkpIHShzDxRjreHPjJLR
 vgtMG7JpldOmpifc5uNvnfYzDtesfcz/J6fpOqf9UklxwEGRF0HXQhFts8dQdVr47s6mV4OO1N
 IWH7BVWznlFwUoovPp4I6HwKnvhoJa6rhxaW3j95aF4RdLZN+CdtaHCCsWPH8fxBVDAMBZtAQA
 A
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749911835; l=3573;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=HpQ+IOBHeSPQkLLUSRUG0Nf5j2qaZir3u+Hl3A3IsNw=;
 b=ArtXRoO+FuNVNZqfpl2+TCQ9EL+05vwIiPyFP6UolfWbeck0+iU9jRWBvSQUWBcWMGsimkCX1
 vRJRENsYoM/C/HCJ62K6frCjaP1puvEpKAleEPCVZDFycxYkWHQs9oe
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi all,

Here it goes v4. Main changes is to drop chip info based struct and
directly use an enum in the FW .data pointer, use the notifier API for
dispatching events and multiple calls to mfd_add_devices().

Regarding the last point, I think I could have used multiple calls to
devm_mfd_add_devices() and avoid those gotos in adp5585_add_devices()
but I do not feel that would have been "correct".

Thanks!
- Nuno Sá

---
Changes in v5:
- Patch 2:
  * Use the existing devm_mfd_add_devices().
- Patch 3:
  * Remove TODO comment.
- Patch 4:
  * Mention in the commit message the Copyright update.
- Patch 6:
  * Return a struct regmap_config pointer in
    adp5585_fill_regmap_config();
  * Just leave a blank entry in the adp5585_regmap_defaults array.
- Patch 13:
  * Improve comments for pin6 (row5) validation;
  * Don't use magic numbers;
  * Drop some odd line breaks;
  * Initialize vartiable when declaring.
- Patch 14:
  * Drop double spaces;
  * Don't use magic numbers;
  * Improve some comments.
- Patch 16:
  * Fix missing semicolon.
- Patch 20:
  * DS -> datasheet. 

- Link to v4: https://lore.kernel.org/r/20250521-dev-adp5589-fw-v4-0-f2c988d7a7a0@analog.com
- Link to v3: https://lore.kernel.org/r/20250512-dev-adp5589-fw-v3-0-092b14b79a88@analog.com
- Link to v2: https://lore.kernel.org/r/20250415-dev-adp5589-fw-v2-0-3a799c3ed812@analog.com
- Link to v1: https://lore.kernel.org/r/20250313-dev-adp5589-fw-v1-0-20e80d4bd4ea@analog.com

---
Nuno Sá (20):
      dt-bindings: mfd: adp5585: ease on the required properties
      mfd: adp5585: only add devices given in FW
      mfd: adp5585: enable oscilator during probe
      mfd: adp5585: make use of MFD_CELL_NAME()
      dt-bindings: mfd: adp5585: document adp5589 I/O expander
      mfd: adp5585: refactor how regmap defaults are handled
      mfd: adp5585: add support for adp5589
      mfd: adp5585: add a per chip reg struture
      gpio: adp5585: add support for the adp5589 expander
      pwm: adp5585: add support for adp5589
      dt-bindings: mfd: adp5585: add properties for input events
      mfd: adp5585: add support for event handling
      mfd: adp5585: support reset and unlock events
      mfd: adp5585: add support for input devices
      gpio: adp5585: support gpi events
      Input: adp5585: Add Analog Devices ADP5585/89 support
      Input: adp5589: remove the driver
      mfd: adp5585: support getting vdd regulator
      dt-bindings: mfd: adp5585: document reset gpio
      mfd: adp5585: add support for a reset pin

 .../devicetree/bindings/mfd/adi,adp5585.yaml       |  240 ++++-
 .../devicetree/bindings/trivial-devices.yaml       |    2 -
 MAINTAINERS                                        |    1 +
 drivers/gpio/Kconfig                               |    1 +
 drivers/gpio/gpio-adp5585.c                        |  364 ++++++-
 drivers/input/keyboard/Kconfig                     |   21 +-
 drivers/input/keyboard/Makefile                    |    2 +-
 drivers/input/keyboard/adp5585-keys.c              |  371 +++++++
 drivers/input/keyboard/adp5589-keys.c              | 1066 --------------------
 drivers/mfd/adp5585.c                              |  743 +++++++++++++-
 drivers/pwm/pwm-adp5585.c                          |   78 +-
 include/linux/mfd/adp5585.h                        |  118 ++-
 12 files changed, 1799 insertions(+), 1208 deletions(-)
---
base-commit: 407f60a151df3c44397e5afc0111eb9b026c38d3
change-id: 20250311-dev-adp5589-fw-e04cfd945286
--

Thanks!
- Nuno Sá

