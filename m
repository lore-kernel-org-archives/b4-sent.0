From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH 0/6] mfd: Add support for the LTC4283 Hot Swap Controller
Date: Thu, 14 Aug 2025 11:52:22 +0100
Message-Id: <20250814-ltc4283-support-v1-0-88b2cef773f2@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAOe/nWgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDC0Mj3ZySZBMjC2Pd4tKCgvyiEl0j82SLZJNUM8tksyQloK6CotS0zAq
 widGxtbUAb10EdGEAAAA=
X-Change-ID: 20250812-ltc4283-support-27c8c4e69c6b
To: linux-hwmon@vger.kernel.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-doc@vger.kernel.org
Cc: Lee Jones <lee@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jean Delvare <jdelvare@suse.com>, 
 Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755168752; l=2545;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=LS7UVXZq5BcWKHTjEz4xF0C5gnYu/PomYCrf0wF8d4E=;
 b=MYo3wIvH+i4xncYor+OvLaAiEb1eJDXKd170JjyFYsTrHb/1XGEBmjy7wA+RsfpOVF9yBBaDf
 xLciOBqry6+CDhImzd4dU9U25eN8kmw/N78xJAXiS+eJWxTHiAId65b
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The LTC4283 device features programmable current limit with foldback and
independently adjustable inrush current to optimize the MOSFET safe
operating area (SOA). The SOA timer limits MOSFET temperature rise for
reliable protection against overstresses.

An I2C interface and onboard ADC allow monitoring of board current, voltage,
power, energy, and fault status.

It also features 8 pins that can be configured as GPIO devices. But since
the main usage for this device is monitoring, the GPIO part is optional
while the HWMON is being made as required.

Also to note that the device has some similarities with the already
supported ltc4282 hwmon driver but it is different enough to be in it's own
driver (apart from being added as MFD). The register map is also fairly
different.

Last time (for the ltc4282) I tried to add the gpio bits directly in the
hwmon driver but Guenter did not really liked it and so this time I'm doing
it as MFD.
 

---
Nuno Sá (6):
      dt-binbings: mfd: Add bindings for the LTC4283 Swap Controller
      mfd: ltc4283: Add support for the LTC4283 Swap Controller
      dt-binbings: hwmon: Add bindings for the LTC4283 Swap Controller
      hwmon: ltc4283-hwmon: Add support for the LTC4283 Swap Controller
      dt-binbings: gpio: Add bindings for the LTC4283 Swap Controller
      gpio: gpio-ltc4283: Add support for the LTC4283 Swap Controller

 .../devicetree/bindings/gpio/adi,ltc4283.yaml      |   33 +
 .../devicetree/bindings/hwmon/adi,ltc4283.yaml     |  159 ++
 .../devicetree/bindings/mfd/adi,ltc4283.yaml       |   85 +
 Documentation/hwmon/ltc4283.rst                    |  266 ++++
 MAINTAINERS                                        |   13 +
 drivers/gpio/Kconfig                               |   10 +
 drivers/gpio/Makefile                              |    1 +
 drivers/gpio/gpio-ltc4283.c                        |  233 +++
 drivers/hwmon/Kconfig                              |   10 +
 drivers/hwmon/Makefile                             |    1 +
 drivers/hwmon/ltc4283-hwmon.c                      | 1658 ++++++++++++++++++++
 drivers/mfd/Kconfig                                |   11 +
 drivers/mfd/Makefile                               |    1 +
 drivers/mfd/ltc4283.c                              |  140 ++
 include/linux/mfd/ltc4283.h                        |   33 +
 15 files changed, 2654 insertions(+)
---
base-commit: 9703c672af8dd3573c76ce509dfff26bf6c4768d
change-id: 20250812-ltc4283-support-27c8c4e69c6b
--

Thanks!
- Nuno Sá

