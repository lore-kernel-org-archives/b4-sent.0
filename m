From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v5 0/3] hwmon: Add support for the LTC4283 Hot Swap
 Controller
Date: Tue, 23 Dec 2025 12:21:41 +0000
Message-Id: <20251223-ltc4283-support-v5-0-1152bff59a61@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAFaJSmkC/23OwY7CIBCA4VcxnMUwAy2wp30Ps4dCByXR0kBtd
 mP67osmakw9/pPMN3NlhXKkwr42V5ZpjiWmoUaz3TB/7IYD8djXZiiwEQaQnyav0EheLuOY8sR
 Re+MVtda3jtWtMVOIv3dx/1P7GMuU8t/9wAy36cNSK2sGLrgxDj0FrWXA727oTumw8+nMbtiML
 8AKuQawAq3zJCw0IFxYAfIJAIgPH8gKKEedsm3QFvoVoF4AfgJUBXonwOrQa2vUG7Asyz/syFO
 GcgEAAA==
X-Change-ID: 20250812-ltc4283-support-27c8c4e69c6b
To: linux-hwmon@vger.kernel.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jean Delvare <jdelvare@suse.com>, 
 Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, "Rob Herring (Arm)" <robh@kernel.org>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766492512; l=2262;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=jhAnj+Jtme12Nuo50V+EmKFGUW7KvEnmq6OcpQAxmfo=;
 b=zPZqYrKNriSltqV6XCFcc4IVOsfWr3FRco8uAuGRhzOTcsL2dHP7em+w2vcxSObft6G786oVJ
 25q+BgYyhV4ADNU5WL+NyG2r3rGS33ctPB5Jjt7zvSgCNrwjh/v9SIa
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
v2 that likely you don't remember anymore. Regarding the regmap story I
ended up adding a secong regmap for the 16 bit wide registers which
seems like a clean solution (if I'm not missing nothing).

[1]: https://lore.kernel.org/linux-hwmon/0765a0b89779331c62a3f136ef030f7f2f40ea47.camel@gmail.com/
[2]: https://lore.kernel.org/linux-iio/cover.1761588465.git.geert+renesas@glider.be/

---
Changes in v5:
- Patch 2:
  * Added a secong regmap for the 16bit wide registers;
  * Add default value for rsense so that we can probe without FW
    properties;
  * Make sure to give the right file permissions to the reset_history
    attrs.
- Patch 3:
  * Make sure to get the right regmap (given that the device now has 2);
  * Add error handling for getting the regmap.
- Link to v4: https://lore.kernel.org/r/20251204-ltc4283-support-v4-0-db0197fd7984@analog.com

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
 drivers/gpio/gpio-ltc4283.c                        |  218 +++
 drivers/hwmon/Kconfig                              |   12 +
 drivers/hwmon/Makefile                             |    1 +
 drivers/hwmon/ltc4283.c                            | 1766 ++++++++++++++++++++
 10 files changed, 2561 insertions(+)
---
base-commit: bc04acf4aeca588496124a6cf54bfce3db327039
change-id: 20250812-ltc4283-support-27c8c4e69c6b
--

Thanks!
- Nuno Sá

