From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v3 0/3] hwmon: Add support for the LTC4283 Hot Swap
 Controller
Date: Tue, 04 Nov 2025 10:32:27 +0000
Message-Id: <20251104-ltc4283-support-v3-0-4bea496f791d@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIADvWCWkC/2XNTQrCMBCG4atI1kaSSX9SV95DXLTjpA3UpiQ1K
 KV3Ny2ISJfvB/PMzAJ5S4GdDzPzFG2wbkihjgeGXT20xO09NQMBudASeD9hBlrx8BxH5ycOJWr
 MqKiwaFi6Gj0Z+9rE6y11Z8Pk/Ht7EOW6fq1sZ0XJBde6ASRTlsrApR7q3rUndA+2YhF+QCXUH
 oAEFA2SqGQuRWP+gGVZPpcyOkfwAAAA
X-Change-ID: 20250812-ltc4283-support-27c8c4e69c6b
To: linux-hwmon@vger.kernel.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jean Delvare <jdelvare@suse.com>, 
 Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, "Rob Herring (Arm)" <robh@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762252353; l=2772;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=lqrX3VJKmck4F8Oum/ghWQkXbfNnSJQYqQa2Z2DOAIo=;
 b=ShNcElYKzU+ApENVMNTC4KT4zE/bT4YDejGBzaFtFiH7nu18fGZ5syvmOBHN0BdZUkcA7jV1c
 smsJ2KU86ZXCTJgNNIkygRTmt23vRQSU3tlFZeHj7XbawvmRzB0d0Mo
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

Linus, I did looked into gpio-regmap and even add support for
init_valid_mask but the register layout is just so different that using
the gpio-regmap is not feasible. We could maybe use it for ADIO (if we
used to different gpiochips in the driver) but the drivers is fairly
small anyways so IMO not worth it.

Also note the driver uses some non constant field_prep/get() that should
go away as soon as [2] get's merged (hopefully before this).

[1]: https://lore.kernel.org/linux-hwmon/0765a0b89779331c62a3f136ef030f7f2f40ea47.camel@gmail.com/
[2]: https://lore.kernel.org/linux-iio/cover.1761588465.git.geert+renesas@glider.be/

---
Changes in v3:
- Patch 1:
  * Changed -if conditionals as suggested by Rob;
  * Fixed typo in commit subject.
- Patch 2:
  * Add ltc4283 entry to index.rst;
  * Remove lock under energy_enable read;
  * Make use of the new energy64 standard attribute;
  * Fix always false comparison in __ltc4283_write_in_history();
  * Add missing reset_history for VIN;
  * Remove energy label. Not useful.
- Patch 3:
  * Add AUXBUS menu entry in gpiolib kconfig as suggested by Linus.
- Link to v2: https://lore.kernel.org/r/20250903-ltc4283-support-v2-0-6bce091510bf@analog.com

Changes in v2:
- Link to v1: https://lore.kernel.org/r/20250814-ltc4283-support-v1-0-88b2cef773f2@analog.com

---
Nuno Sá (3):
      dt-bindings: hwmon: Document the LTC4283 Swap Controller
      hwmon: ltc4283: Add support for the LTC4283 Swap Controller
      gpio: gpio-ltc4283: Add support for the LTC4283 Swap Controller

 .../devicetree/bindings/hwmon/adi,ltc4283.yaml     |  272 +++
 Documentation/hwmon/index.rst                      |    1 +
 Documentation/hwmon/ltc4283.rst                    |  266 +++
 MAINTAINERS                                        |    9 +
 drivers/gpio/Kconfig                               |   15 +
 drivers/gpio/Makefile                              |    1 +
 drivers/gpio/gpio-ltc4283.c                        |  217 +++
 drivers/hwmon/Kconfig                              |   12 +
 drivers/hwmon/Makefile                             |    1 +
 drivers/hwmon/ltc4283.c                            | 1749 ++++++++++++++++++++
 10 files changed, 2543 insertions(+)
---
base-commit: 65bc97a5e49ea4174ba7e89afdada3e30e6e39c0
change-id: 20250812-ltc4283-support-27c8c4e69c6b
--

Thanks!
- Nuno Sá

