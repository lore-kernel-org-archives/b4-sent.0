From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH v4 0/2] hwmon: add support for MC33XS2410 hardware
Date: Tue, 08 Jul 2025 18:13:02 +0200
Message-Id: <20250708-mc33xs2410-hwmon-v4-0-95b9e3ea5f5c@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAI5DbWgC/23N3wrCIBTH8VcJrzP8M3PrqveILpweU2gzNGwx9
 u65ERS1y++B3+eMKEH0kNBhM6II2Scf+hLVdoO0U/0FsDelESNMEEEk7jTnQ2IVJdg9utBjJax
 twIImRKAyu0WwfljI07m08+ke4nP5kOl8fWOU/WOZYoqVMa2SUsvaNserh9ZBjDsdOjR7mX0bY
 sVgxagNg7KXwIlZMfjH2NNmxeDF4IRKTqFqbG1/jGmaXt4upTE7AQAA
X-Change-ID: 20250507-mc33xs2410-hwmon-a5ff9efec005
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>
Cc: linux-pwm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hwmon@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751991186; l=1629;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=Cwb3nUB6lTov3BPnF0GyHtI8BZLdVWF5iDdsj0Ls56g=;
 b=HirHDqyykc7iCpQ/3mXnfNNpmURi0wQMxBQeo36GQ5Jpk1oLhUJsHKRDKsaw3e48vkOMfOQwT
 S9wdVM6STX9B1XFJKuXbdw1MUsITjMJq5ngclipRSvqZw0CLLeeL5PE
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The device is able to monitor temperature, voltage and current of each of
the four outputs. Add basic support for monitoring the temperature of the
four outputs and the die temperature.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
Changes in v4:
- Move hwmon functionality into separate driver residing in hwmon subsystem
  (auxiliary device)
- Link to v3: https://lore.kernel.org/r/20250619-mc33xs2410-hwmon-v3-1-301731e49f8f@liebherr.com

Changes in v3:
- Add changes suggested by Uwe Kleine-König.
  Remove "#if IS_ENABLED(CONFIG_HWMON)" and add
  "if (IS_REACHABLE(CONFIG_HWMON))" in mc33xs2410_hwmon_probe.
- Link to v2: https://lore.kernel.org/r/20250515-mc33xs2410-hwmon-v2-1-8d2e78f7e30d@liebherr.com

Changes in v2:
- Remove helper mc33xs2410_hwmon_read_out_status and report the last
  latched status.
- Link to v1: https://lore.kernel.org/r/20250512-mc33xs2410-hwmon-v1-1-addba77c78f9@liebherr.com

---
Dimitri Fedrau (2):
      pwm: mc33xs2410: add hwmon support
      hwmon: add support for MC33XS2410 hardware monitoring

 drivers/hwmon/Kconfig            |  10 +++
 drivers/hwmon/Makefile           |   1 +
 drivers/hwmon/mc33xs2410_hwmon.c | 179 +++++++++++++++++++++++++++++++++++++++
 drivers/pwm/Kconfig              |   1 +
 drivers/pwm/pwm-mc33xs2410.c     |  64 +++++++++++++-
 include/linux/mc33xs2410.h       |  14 +++
 6 files changed, 267 insertions(+), 2 deletions(-)
---
base-commit: 446d36aa71b56e8a926e6ff066d83b12130fda59
change-id: 20250507-mc33xs2410-hwmon-a5ff9efec005

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

