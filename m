From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v13 0/3] hwmon: Add support for the LTC4283 Hot Swap
 Controller
Date: Sat, 02 May 2026 10:56:51 +0100
Message-Id: <20260502-ltc4283-support-v13-0-1c206542e652@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XOTW7DIBAF4KtErEvFDDBAVr1H1AXlJ0FKbct2r
 VSR716cTV2RLt+T5ntzZ1MaS5rY8XBnY1rKVPquBpAvBxYuvjsnXmItGAokIYXk1zkotJJPX8P
 QjzMXJLOxPgTtFatXw5hyuT3I03vNlzLN/fj9WFhoa/+3FuKCp5wAtMDsI775zl/782voP9mGL
 XYHoGkBWwFlICbUOhq0DeB+ASWoBVwFPohCDkY5JGgAEDsBbSuA2H7ISFmRchBkS8CecE8IqAS
 aEGIicNHHlsAdIcUTAiuhY3BOQEZN5g+xrusPVc8HOvsBAAA=
X-Change-ID: 20260303-ltc4283-support-063f78acc5a4
To: linux-gpio@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777715816; l=2159;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=1qCobfoCEucgrjRGXrCQ3vKcmNt1JqyTqC3CN//BeTg=;
 b=2lD4JiD7HXmz7ICmwv1z6+5Qet99RmrVlaltpn/Focc/QXX+JPWkpzj+DaEU4TL5LGUfout9r
 vuW1Qo/ZJ8IBW+kTu4Yt997g/CISjNBTJsH9T3DiZYwHyMOVLWZm2u9
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
Changes in v13:
- Patch 2
   * Properly register debugfs fet faults to match DRAIN channel (in11).
- Link to v12: https://patch.msgid.link/20260430-ltc4283-support-v12-0-5dc9901f2567@analog.com

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

