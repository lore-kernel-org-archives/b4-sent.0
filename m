From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v4 00/20] mfd: adp5585: support keymap events and drop
 legacy Input driver
Date: Wed, 21 May 2025 14:02:50 +0100
Message-Id: <20250521-dev-adp5589-fw-v4-0-f2c988d7a7a0@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAPrOLWgC/2XM0Q6CIBiG4VtpHEeDH0joqPtoHaD8Klupg0Y15
 72Hbs2Vh9+3Pe9IIgaPkZx2IwmYfPR9l4fc70jV2q5B6l3eBBgoJjinDhO1blBKG1o/KTJZ1c5
 IBfpIMhoC1v61BC/XvFsfH314L/3E5/ebEv+pxCmjwFAzJ0sn0Z5tZ299c6j6O5lbCVYvudp4y
 F7YwphKoNMcNl6sXnHYeJE9M1ByWRbGav3jp2n6AH4lFx8tAQAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747832588; l=4569;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=MuE0RHNWG9vbd8b45RwY4Vuvxd+09YzMmGVNTv4P07g=;
 b=6Cp0nCnry8wBZdQuP/oFpah/vi4bitiIHDp8Irfks3jkxL7x8fPXGu0qbbhFviKCdlp3KsP3x
 ZJlfSU4dLR6AGm1hx2VQvF7p6B/0rW0Bf6cr63FQo/Tt9sCz/OxkCMO
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
Changes in v4:
 - Patch 2:
   * Directly use mfd_add_devices() to individually add devices

 - Patch 3:
   * Don't break lines at 80;
   * Add comment suggested by Laurent;
   * PWM change squashed in this patch.

 - Patch 5:
   * Pass an enum to the of_id data pointer;
   * Reference the regmap defaults directly from the variant enum;
   * Drop chip_info struct and place data directly in struct adp5585_dev.

 - Patch 6:
   * Adapt to the new way of passing per variant data;
   * Rename adp5585_fill_regmap_config() to adp5585_fill_variant_config();
   * Add struct device now to struct adp5585_dev;
   * Pass adp5585_dev to adp5585_add_devices().

 - Patch 7:
   * Add regs directly in struct adp5585_dev.

 - Patch 9:
   * Moved the per variant gpio register into the gpio driver;
   * Moved ADP558[59]_GPIO_{BANK_BIT} into the gpio driver;
   * Moved ADP5589_GPIO_MAX and dropped the max_{col|row}.

 - Patch 10:
   * Adapt to the lack of a chip_info pointer when getting ext_cfg.

 - Patch 12:
   * Refactor parsing of poll-interval;
   * Make use of the notifier API instead of "own" dispatcher mechanism;
   * Improve comments in the code.

 - Patch 13:
   * Add more comments;
   * Drop the function callback for validating events;
   * Renamed has_pin5 to has_pin6;
 
 - Patch 14:
   * Adapt to the new way of adding MFD cells;
   * Improve comments.

 - Patch 15:
   * Use the notifier API and adapt to that.

 - Patch 16:
   * Use the notifier API and adapt to that;
   * Move devm_add_action_or_reset() before the for() loop setting the
     bits in kpad->keypad;
   * Address Dmitry comment about checking for error instead of
     directly returning when calling adp5585_keys_check_special_events().

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
 drivers/mfd/adp5585.c                              |  751 +++++++++++++-
 drivers/pwm/pwm-adp5585.c                          |   78 +-
 include/linux/mfd/adp5585.h                        |  116 ++-
 12 files changed, 1804 insertions(+), 1209 deletions(-)
---
base-commit: 407f60a151df3c44397e5afc0111eb9b026c38d3
change-id: 20250311-dev-adp5589-fw-e04cfd945286
--

Thanks!
- Nuno Sá

