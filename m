From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v6 0/3] hwmon: Add support for the LTC4283 Hot Swap
 Controller
Date: Tue, 03 Mar 2026 17:00:39 +0000
Message-Id: <20260303-ltc4283-support-v6-0-efe11502fad2@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqAIBBA0avErBNEzaSrRAuxqQbCZKwIwrsnL
 d/i/xcyMmGGoXmB8aZMR6ywbQNh83FFQXM1KKms1FKL/QxGOS3yldLBp5BWL73zIXTeQK0S40L
 PfxynUj660kVMYQAAAA==
X-Change-ID: 20260303-ltc4283-support-063f78acc5a4
To: linux-gpio@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772557240; l=1962;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=mgwUhCncYhDl61XAwXlMI23b+H6nVEk5nE7YqMPl7/4=;
 b=5QEy1itU4Qq/SbblS24Kt7rPX/4f94eo9Z8Iwj5JbfsH6EGvRk7Shvd0OCxCOFe/D3IM3xtXg
 jyAOnii5XYlD114Ja5BrgGvlFYESNG2je0ZO2v0RyNDX/Qu+WS3rWbG
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is v6 for the LTC4283 how swap controller. Main change is that I'm
now using the auxiliary bus for adding the GPIO device (done depending
on FW properties).

Similar to the LTC4282 device, we're clearing some fault logs in the
reset_history attributes.

---
Changes in v6:
- Patch 2:
  * Rework regmap to use single regmap with custom regmap_bus
    (lm75-style);
  * Add explicit i2c func checks;
  * Make sure page support is enabled for energy reads;
  * Fix MODULE_DESCRIPTION: "How Swap" -> "Hot Swap";
  * Remove #include <linux/hwmon-sysfs.h> (unused);
  * Fix commit message: "How Swap Controller" -> "Hot Swap Controller";
  * Fix "Addresses scanned" section in docs (no .detect() supported).

- Patch 3:
  * Fix typo: LTC42823_ADIO_CONFIG -> LTC4283_ADIO_CONFIG.
 
- Link to v5: https://lore.kernel.org/linux-hwmon/20251223-ltc4283-support-v5-0-1152bff59a61@analog.com/

---

---
Nuno Sá (3):
      dt-bindings: hwmon: Document the LTC4283 Swap Controller
      hwmon: ltc4283: Add support for the LTC4283 Swap Controller
      gpio: gpio-ltc4283: Add support for the LTC4283 Swap Controller

 .../devicetree/bindings/hwmon/adi,ltc4283.yaml     |  272 +++
 Documentation/hwmon/index.rst                      |    1 +
 Documentation/hwmon/ltc4283.rst                    |  265 +++
 MAINTAINERS                                        |    9 +
 drivers/gpio/Kconfig                               |   15 +
 drivers/gpio/Makefile                              |    1 +
 drivers/gpio/gpio-ltc4283.c                        |  218 +++
 drivers/hwmon/Kconfig                              |   12 +
 drivers/hwmon/Makefile                             |    1 +
 drivers/hwmon/ltc4283.c                            | 1780 ++++++++++++++++++++
 10 files changed, 2574 insertions(+)
---
base-commit: 78558965440b27814592ec82d8f3668395953b1b
change-id: 20260303-ltc4283-support-063f78acc5a4
--

Thanks!
- Nuno Sá

