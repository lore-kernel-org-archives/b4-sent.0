From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v7 0/3] hwmon: Add support for the LTC4283 Hot Swap
 Controller
Date: Sat, 14 Mar 2026 10:52:18 +0000
Message-Id: <20260314-ltc4283-support-v7-0-1cda48e93802@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAOM9tWkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyzHUUlJIzE
 vPSU3UzU4B8JSMDIzMDY0MT3ZySZBMjC2Pd4tKCgvyiEl0zw0QDy1RjM1MzU0sloK6CotS0zAq
 widGxtbUAsEfWcmEAAAA=
X-Change-ID: 20260314-ltc4283-support-61a09e365659
To: linux-gpio@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Bartosz Golaszewski <brgl@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773485540; l=1803;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=4Sq3DEK8G8zCXWtDdEnlAx8YFVSgsv/JQaaNI9zSiWw=;
 b=V/ukvSe4Rq3Wz5tKTRrUOYrNTvQfWH7HW68j6w5IhtJqkTDYRYBmpWMuTwdseG2bbCZ1xan0l
 cjZiUn5QlmIB7LuYlnfx8/wq7A1JhDt/lLVoen1O20MUSg0Zdd5mG9N
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is v7 for the LTC4283 how swap controller. Main change is that I'm
now using the auxiliary bus for adding the GPIO device (done depending
on FW properties).

Similar to the LTC4282 device, we're clearing some fault logs in the
reset_history attributes.

---
Changes in v7:
 - Patch 2:
    * Initialize raw energy to 0;
    * Clamp power val;
    * Handle BIT(8) edge case in ltc4283_write_in_byte();
    * Clamp ISENSE according to vsense_max;
    * Fix ltc4283_write_curr_history() by converting vsense_max to
      micro;
    * Fix default rsense value (expected to be in nano ohm);
    * Terminate table in sysfs attrs.
Link to v6: 
  - https://lore.kernel.org/linux-hwmon/20260303-ltc4283-support-v6-0-efe11502fad2@analog.com/

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
 drivers/hwmon/ltc4283.c                            | 1787 ++++++++++++++++++++
 10 files changed, 2582 insertions(+)
---
base-commit: 33f9280f8a3a1b8e1df9ab1ff4f9d2654f434f3c
change-id: 20260314-ltc4283-support-61a09e365659
--

Thanks!
- Nuno Sá

