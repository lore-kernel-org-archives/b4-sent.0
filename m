From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v8 0/3] hwmon: Add support for the LTC4283 Hot Swap
 Controller
Date: Fri, 27 Mar 2026 17:26:13 +0000
Message-Id: <20260327-ltc4283-support-v8-0-471de255d728@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNQQrDIBQFrxL+uhajiZWuco+ShZhvIqQqaqUle
 Pfa7LucgTfvgITRYoJ7d0DEYpP1roG8dKA35VYkdmkMjDJBOeVkz3pgkpP0CsHHTKjg5iaV1qM
 aoK1CRGPfZ/ExN95syj5+zoMifvZ/qwhCCRrs+5EyoxY2Kad2v161f8Jca/0Cl+nMMK8AAAA=
X-Change-ID: 20260303-ltc4283-support-063f78acc5a4
To: linux-gpio@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774632374; l=1827;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=wP07MCoE5Leq1WsPpP2sxNPCLJfyGnjf5lGaQDv3kmA=;
 b=Q1nzDECbjvmzhD8F/jUVZDSHmwCeuMks6JUDapVMLTH1OJdSFYj0xw0RWt7NjcddbfLZLYTLC
 z3ckPOWC3R5Dx2e+2VcYWI5rpJsi1TA5mN2Zxo8QZT6bzRi/ViLZnBL
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is v8 for the LTC4283 how swap controller. 

Similar to the LTC4282 device, we're clearing some fault logs in the
reset_history attributes.

---
Changes in v8:
- Patch 1:
   * Improved descriptin in adi,fet-turn-off-disable so it's more clear;
   * Same for adi,dvdt-inrush-control-disable;
   * Fixed typo in adi,external-fault-retry-enable description.
- Patch 2:
   * Use return value from clamp_val();
   * Add missing 'ret < 0' for device_property_match_property_string()
     calls;
   * Fixed logic in when adi,vpower-drns-enable is enabled;
   * Check default state of the pgio4 pin. So that we can, accordingly
     flag st->ext_fault.
- Link to v7: https://lore.kernel.org/linux-hwmon/20260314-ltc4283-support-v7-0-1cda48e93802@analog.com/ 
---

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
 drivers/hwmon/ltc4283.c                            | 1796 ++++++++++++++++++++
 10 files changed, 2591 insertions(+)
---
base-commit: cd041796c380961f0e3c04d9627af80131608adc
change-id: 20260303-ltc4283-support-063f78acc5a4
--

Thanks!
- Nuno Sá

