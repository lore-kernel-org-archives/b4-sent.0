From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v2 00/17] mfd: adp5585: support keymap events and drop
 legacy Input driver
Date: Tue, 15 Apr 2025 15:49:16 +0100
Message-Id: <20250415-dev-adp5589-fw-v2-0-3a799c3ed812@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAOxx/mcC/13MQQ7CIBCF4as0s3YMUDCtq97DdIEwtCRaGjCoa
 bi72MSNy/8l79sgUfSU4NxsECn75MNSQxwaMLNeJkJva4NgQrGWc7SUUdtVqa5H90Ri0jjbSyW
 6E9TTGsn51w5extqzT48Q37uf+Xf9Ue0/lTkyFIw6ZuXVStKDXvQtTEcT7jCWUj6Zld7srQAAA
 A==
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
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744728559; l=3998;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=1YZSRaVDusksRM573pWwDi4SZBCKuSaeLIow9Kp3l3I=;
 b=w0G5TNF3ytrz+ne3xbnvovn3y0/E5PqAb7Y/asbnYDqtM/Z73hQZEnaSQAOWjHoZdmXfWh3V6
 Fe2KiJys+hFAiR6I8Z3ceeR9Wyvihg6p9RL3r1COFyC8eUccipAM0bQ
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The adp5585 MFD driver was introduced in 6.11 adding support for gpio
and PWM. However, the gpio part of it was already supported as part of
the keyboard driver:

https://elixir.bootlin.com/linux/v6.14-rc6/source/drivers/input/keyboard/adp5589-keys.c#L532

On top of that it also overlapped with my refactoring of the above driver [1]
to drop usage of platform data and use FW properties instead.

Now, it actually makes sense for this device to be supported under MFD
and since the "legacy" input device depends on platform data that is not
defined anywhere the plan in this series is to add support for the
keyboard and adp5589 devices as part of the MFD driver. Once the MFD
driver supports all that's supported in the Input one, we drop it...

For DT Maintainers:

The compatible for adp5589 is part of trivial devices. To me, it makes
sense to remove it in the patch where we drop the driver but doing so
would result in a warning when adding the same compatible for the MFD
bindings. Hence, I remove it in that patch. Is that ok?

Uwe:

In my eval board, I could see that reading the GPIO value (when
configured as input) does not work when OSC_EN is not set. Therefore,
commit ("pwm: adp5585: don't control OSC_EN in the pwm driver") could
very well have a Fixes tag. However I'm not 100% sure it's a real issue
or something special to my eval board.

It would be nice if Laurent or Liu could test the PWM bits or even
check that the above is also an issue for their platform.

[1]: https://lore.kernel.org/linux-input/d1395bd61ce58b3734121bca4e09605a3e997af3.camel@gmail.com/

BTW the series is based on linux-next/master

---
Changes in v2:
- Patch 5:
   * Do not nest if:then:else::if:then.
- Patch 6:
   * Make use of the adp5585 info variables and adp5589 volatile regs.
- Patch 9:
   * Use standard "poll-interval" property (and move it before vendor
     properties).
- Patch 10:
   * Make sure to include bitfield.h.

- Link to v1: https://lore.kernel.org/r/20250313-dev-adp5589-fw-v1-0-20e80d4bd4ea@analog.com

---
Nuno Sá (17):
      dt-bindings: mfd: adp5585: ease on the required properties
      mfd: adp5585: enable oscilator during probe
      pwm: adp5585: don't control OSC_EN in the pwm driver
      mfd: adp5585: make use of MFD_CELL_NAME()
      dt-bindings: mfd: adp5585: document adp5589 I/O expander
      mfd: adp5585: add support for adp5589
      gpio: adp5585: add support for the ad5589 expander
      pwm: adp5585: add support for adp5589
      dt-bindings: mfd: adp5585: add properties for input events
      mfd: adp5585: add support for key events
      gpio: adp5585: support gpi events
      Input: adp5585: Add Analog Devices ADP5585/89 support
      Input: adp5589: remove the driver
      mfd: adp5585: support getting vdd regulator
      dt-bindings: mfd: adp5585: document reset gpio
      mfd: adp5585: add support for a reset pin
      pwm: adp5585: make sure to include mod_devicetable.h

 .../devicetree/bindings/mfd/adi,adp5585.yaml       |  240 ++++-
 .../devicetree/bindings/trivial-devices.yaml       |    2 -
 MAINTAINERS                                        |    1 +
 drivers/gpio/Kconfig                               |    1 +
 drivers/gpio/gpio-adp5585.c                        |  299 +++++-
 drivers/input/keyboard/Kconfig                     |   21 +-
 drivers/input/keyboard/Makefile                    |    2 +-
 drivers/input/keyboard/adp5585-keys.c              |  221 ++++
 drivers/input/keyboard/adp5589-keys.c              | 1066 --------------------
 drivers/mfd/adp5585.c                              |  808 ++++++++++++++-
 drivers/pwm/pwm-adp5585.c                          |   57 +-
 include/linux/mfd/adp5585.h                        |  153 ++-
 12 files changed, 1709 insertions(+), 1162 deletions(-)
---
base-commit: 5b37f7bfff3b1582c34be8fb23968b226db71ebd
change-id: 20250311-dev-adp5589-fw-e04cfd945286
--

Thanks!
- Nuno Sá

