From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v4 0/3] hwmon: Add support for the LTC4283 Hot Swap
 Controller
Date: Thu, 04 Dec 2025 16:15:25 +0000
Message-Id: <20251204-ltc4283-support-v4-0-db0197fd7984@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAJ6zMWkC/23OwQ7CIAyA4VdZOIuBwjbw5HsYD4MVJZljgblol
 r27aKLGzOPfpF87k4TRYyK7YiYRJ5986HPITUHsuelPSH2bmwCDkikOtButBCVoug5DiCOF2io
 rsdK2MiRvDRGdv73EwzH32acxxPvrwMSf07clV9bEKaNKGbDo6lo42Dd904XT1oYLeWITfAHNx
 BqADFTGItO85My4FSA+AOfszwciA9JgI3Xlas3bH2BZlgd8uPueMQEAAA==
X-Change-ID: 20250812-ltc4283-support-27c8c4e69c6b
To: linux-hwmon@vger.kernel.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jean Delvare <jdelvare@suse.com>, 
 Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, "Rob Herring (Arm)" <robh@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764864927; l=2380;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=pAQTPCvFXYrGAotRnk0JwW3gTHvZ0ixKDshwUPXxrK8=;
 b=rnRdWJg2gZbjIbep6IktGTICmCL3KUTRjQh1fqixdCvEtA/d80rvVPRF8MbAvxApjC4N6vMlk
 w8DGYDag4aLD5+OHcQbdhqN/xoI6qGCeA7VvxO2foozbWObJB1KZwLG
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is v3 for the LTC4283 how swap controller. Main change is that I'm
now using the auxiliary bus for adding the GPIO device (done depending
on FW properties).

Similar to the LTC4282 device, we're clearing some fault logs in the
reset_history attributes.

Guenter, in [1] you can find some replies for some questions you had in
v2 that likely you don't remember anymore.

v4 is based in last linux-next (next-20251204) so that we get
field_prep()/get() for masks that are not compile time constants.

[1]: https://lore.kernel.org/linux-hwmon/0765a0b89779331c62a3f136ef030f7f2f40ea47.camel@gmail.com/
[2]: https://lore.kernel.org/linux-iio/cover.1761588465.git.geert+renesas@glider.be/

---
Changes in v4:
- Patch 2
  * Drop driver's own mutex (now handled by the core).
- Patch 3
  * Refrased kconfig menu to "Auxiliary Bus GPIO drivers" as suggested;
  * Add blank line before including the headers;
  * Fix includes not in alphabetical order;
  * Dropped custom fied_prep()/get().
- Link to v3: https://lore.kernel.org/r/20251104-ltc4283-support-v3-0-4bea496f791d@analog.com

Changes in v3:
- Link to v2: https://lore.kernel.org/r/20250903-ltc4283-support-v2-0-6bce091510bf@analog.com

Changes in v2:
- Link to v1: https://lore.kernel.org/r/20250814-ltc4283-support-v1-0-88b2cef773f2@analog.com

---
Nuno Sá (3):
      dt-bindings: hwmon: Document the LTC4283 Swap Controller
      hwmon: ltc4283: Add support for the LTC4283 Swap Controller
      gpio: gpio-ltc4283: Add support for the LTC4283 Swap Controller

 .../devicetree/bindings/hwmon/adi,ltc4283.yaml     |  272 ++++
 Documentation/hwmon/index.rst                      |    1 +
 Documentation/hwmon/ltc4283.rst                    |  266 +++
 MAINTAINERS                                        |    9 +
 drivers/gpio/Kconfig                               |   15 +
 drivers/gpio/Makefile                              |    1 +
 drivers/gpio/gpio-ltc4283.c                        |  215 +++
 drivers/hwmon/Kconfig                              |   12 +
 drivers/hwmon/Makefile                             |    1 +
 drivers/hwmon/ltc4283.c                            | 1719 ++++++++++++++++++++
 10 files changed, 2511 insertions(+)
---
base-commit: bc04acf4aeca588496124a6cf54bfce3db327039
change-id: 20250812-ltc4283-support-27c8c4e69c6b
--

Thanks!
- Nuno Sá

