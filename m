From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v12 0/3] hwmon: Add support for the LTC4283 Hot Swap
 Controller
Date: Thu, 30 Apr 2026 09:52:02 +0100
Message-Id: <20260430-ltc4283-support-v12-0-5dc9901f2567@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XO3U7EIBAF4FfZcC2GGegAXvkexgvkZ5dkbRuoj
 WbTd5fujTXo5TnJfGdurMaSY2VPpxsrcc01T2MLgA8n5i9uPEeeQysYCiQhheTXxSs0ktePeZ7
 KwgXJpI3zfnCKtau5xJQ/7+TLa8uXXJepfN0XVtrb/62VuOAxRYBBYHIBn93ortP50U/vbMdWc
 wBQ94BpgNIQIg5D0Gg6wP4ASlAP2Aa8EfnktbJI0AEgDgKaXgCx/5CQkiJlwcuegCNh/yCgEai
 9D5HABhd+Edu2fQNhQFX8uAEAAA==
X-Change-ID: 20260303-ltc4283-support-063f78acc5a4
To: linux-gpio@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777539125; l=2204;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=X1hORcvEfGXH+JxOkAabXjsJ0RPQOd7wDQ4R+LR8WXM=;
 b=meKXRoX3OHpHON0TjTUrShcmctKrv2zBkfnhG2M4tPMLJusAzu/d3JQgqf73dHS1QCyvYDaBC
 CMq/LgDUCzeAXLc3A//ILHI1RW7PwgokdZ3lZsTCZ5IvAIgbzWiDTdw
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is v8 for the LTC4283 how swap controller. 

Similar to the LTC4282 device, we're clearing some fault logs in the
reset_history attributes.

Guenter, for my last email worrying about rsense low values, this is
what I got internally:

"10uOhm at the smallest sense voltage of 15mV would be 1500A and 72kW, which
seems a tad excessive. The highest currents I’ve seen are around 200A, and
the -48V market 4283 serves is generally a lot lower than that. Normal values
are around 200uOhm.  I’d say the resolution should be around 1uohm and if a
minimum is needed, 50uOhm is probably safe."

For the resolution, I'm pretty sure I got the tenths of micro
resolution for ltc4282 so I just kept it in here. So, if you don't mind
I would prefer to keep it this way to be safer and changing that now would
require me to change some formulas and I would prefer not to do that at
this stage.

---
Changes in v12:
- Patch 2:
  * Add missing in0_reset_history in docs;
  * Make sure to pass st->gpio_mask in __devm_auxiliary_device_create().
- Link to v11: https://patch.msgid.link/20260429-ltc4283-support-v11-0-27ccde619dad@analog.com

---
Nuno Sá (3):
      dt-bindings: hwmon: Document the LTC4283 Swap Controller
      hwmon: ltc4283: Add support for the LTC4283 Swap Controller
      gpio: gpio-ltc4283: Add support for the LTC4283 Swap Controller

 .../devicetree/bindings/hwmon/adi,ltc4283.yaml     |  272 +++
 Documentation/hwmon/index.rst                      |    1 +
 Documentation/hwmon/ltc4283.rst                    |  267 +++
 MAINTAINERS                                        |    9 +
 drivers/gpio/Kconfig                               |   15 +
 drivers/gpio/Makefile                              |    1 +
 drivers/gpio/gpio-ltc4283.c                        |  218 +++
 drivers/hwmon/Kconfig                              |   12 +
 drivers/hwmon/Makefile                             |    1 +
 drivers/hwmon/ltc4283.c                            | 1795 ++++++++++++++++++++
 10 files changed, 2591 insertions(+)
---
base-commit: 992920ad25f27f41521c1bb905d0e1062ecb9e93
change-id: 20260303-ltc4283-support-063f78acc5a4
--

Thanks!
- Nuno Sá

