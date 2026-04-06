From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v9 0/3] hwmon: Add support for the LTC4283 Hot Swap
 Controller
Date: Mon, 06 Apr 2026 15:31:10 +0100
Message-Id: <20260406-ltc4283-support-v9-0-b66cfc749261@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XNTQ7CIBCG4as0rMXQofzoynsYFwSGlqSWBmqja
 Xp3aVca4/L9knlmIRlTwEzO1UISziGHOJQ4HSpiOzO0SIMrTYCBZJxx2k+2Ac1pfoxjTBNlknu
 ljbXCNKRcjQl9eO7i9Va6C3mK6bU/mOW2/rdmSRlFj3UtGHjj4GIG08f2aOOdbNisPwBQv4AuQ
 KNqhyCEU6C/gHVd3zA26k/wAAAA
X-Change-ID: 20260303-ltc4283-support-063f78acc5a4
To: linux-gpio@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775486610; l=2471;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=1qvPs6Dx3KIJATyl7qc5LXmaMLyGjDLwYwapxU8QMaE=;
 b=zg96LAc7vzvzRRoSu1RjQO+IgFC5QplIyIy4bIA0KkDl5TOHSHDev44amb671aQeopTnpEBzt
 GT/mOhV7LQeAeXHLXPIUCFNCOaZALWgv7YauYVhHJ7gjiR39dQM5ubp
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
Changes in v9:
- Patch 2:
  * Add max and min rsense values to avoid 32bit overflows in power and
    rsense * 256;
  * Fix typo in ltc4283_read_in_alarm() s/LTC4283_CHAN_ADIN34/LTC4283_CHAN_ADIO34;
  * Clamp 'val * MILLI' for LTC4283_ADC1_FS_uV in ltc4283_read_in_alarm();
  * Adapt rsense default and property reading for the new range values.
  * Properly construct an auxdev id from the i2c client.
- Link to v8: https://patch.msgid.link/20260327-ltc4283-support-v8-0-471de255d728@analog.com
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
 drivers/hwmon/ltc4283.c                            | 1808 ++++++++++++++++++++
 10 files changed, 2603 insertions(+)
---
base-commit: 30a90fa04af6937493fbba20e3e923b5b5a162b4
change-id: 20260303-ltc4283-support-063f78acc5a4
--

Thanks!
- Nuno Sá

