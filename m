From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v10 0/3] hwmon: Add support for the LTC4283 Hot Swap
 Controller
Date: Tue, 28 Apr 2026 17:07:25 +0100
Message-Id: <20260428-ltc4283-support-v10-0-4f26f46491c3@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XN0Q6CIBgF4FdxXEeDXwTsqvdoXRCCspk4MFZzv
 nvoTTXX5Tnb+c6MognORHQqZhRMctH5IQdKDgXSnRpag12TCwQEOClJiftJM5Aljo9x9GHChJd
 WSKV1pRjKqzEY654bebnm3Lk4+fDaHhJf2/9W4phgYw2lFQGrGjirQfW+PWp/RyuW5BcAYg/ID
 DBBGwNV1QiQO6D+AIzwPVBn4Ma5tlqwGjj9AZZleQOU2LccMgEAAA==
X-Change-ID: 20260303-ltc4283-support-063f78acc5a4
To: linux-gpio@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777392450; l=2621;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=wJpZOr7WpcpInKgvVGac/trrFN9ZpHJHZEoCiuPdrYs=;
 b=JKTAEyv8cj4/a5R73is9A5no+jJH+LIDC8oOOPpDWV5LA7qj9M6fnD7uU0fVpMp8GjS21gyUf
 75zEL7JTuzwDsHKjW2OhuDP0gP+IHitPpIWLldEjAKerHCrfhk668N/
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
Changes in v10:
- Patch 2:
 * Replace regmap_clear_bits() with direct regmap_write() in
   ltc4283_read_alarm();
 * Simplify ltc4283_read_energy() overflow handling using
   mul_u64_u64_div_u64() for 128-bit intermediate precision;
 * Simplify ltc4283_write_power_word() overflow handling using
   mul_u64_u64_div_u64();
 * Fix clamp-before-multiply overflow in ltc4283_write_minmax() by
   clamping against LONG_MAX/MILLI first;
 * Drop broken %*ph format from ltc4283_parse_array_prop() error
   message;
 * Remove unused #include <linux/overflow.h>.
- Link to v9: https://patch.msgid.link/20260406-ltc4283-support-v9-0-b66cfc749261@analog.com

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
 drivers/hwmon/ltc4283.c                            | 1795 ++++++++++++++++++++
 10 files changed, 2590 insertions(+)
---
base-commit: 30a90fa04af6937493fbba20e3e923b5b5a162b4
change-id: 20260303-ltc4283-support-063f78acc5a4
--

Thanks!
- Nuno Sá

