From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH v5 0/2] hwmon: add support for MC33XS2410 hardware
Date: Wed, 23 Jul 2025 19:34:55 +0200
Message-Id: <20250723-mc33xs2410-hwmon-v5-0-f62aab71cd59@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAD8dgWgC/23Q0QrCIBQG4FcJrzOOOnN21XtEF5sem9C20FiLs
 XfPjaAoL/8D//fDmUjE4DGSw2YiAQcffd+lILcbYpqquyD1NmXCgUuQoGhrhBgjLxjQ5tH2Ha2
 kcxodGgBJUu0W0PlxJU/nlBsf7314rgsDW65vjPF/bGCU0craulLKqNLp49Vj3WAIO9O3ZPEG/
 m3IjMGTUVqOqa9QgM0Y4mPsmc4YIhkCmBIMC+1KlzGKj6GgzBgFBaplrVFgepI0P8Y8zy99T6x
 EfwEAAA==
X-Change-ID: 20250507-mc33xs2410-hwmon-a5ff9efec005
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: linux-pwm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hwmon@vger.kernel.org, linux-doc@vger.kernel.org, 
 Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753292105; l=2083;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=DxP/8U/gv179+30ubQutejfBAUlzcxofPDI//uz2+R4=;
 b=w2jsYEX3F4tizmo5c8iQbF8fCJeuHjAOI2yQlfmaW1ngd4BN8okSmhyujLKXgFy+3yMnJifrF
 AsQ/iBYkl/QC5eDneSi+Vzq27UhkWc3o1+06/u5pAfbmjZ84VIjJedp
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The device is able to monitor temperature, voltage and current of each of
the four outputs. Add basic support for monitoring the temperature of the
four outputs and the die temperature.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
Changes in v5:
- Define DEFAULT_SYMBOL_NAMESPACE
- Replace mc33xs2410_hwmon_register with devm_auxiliary_device_create
- Add MODULE_IMPORT_NS("PWM_MC33XS2410") to mc33xs2410.h
- Add documentation for HWMON driver
- Link to v4: https://lore.kernel.org/r/20250708-mc33xs2410-hwmon-v4-0-95b9e3ea5f5c@liebherr.com

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

 Documentation/hwmon/index.rst            |   1 +
 Documentation/hwmon/mc33xs2410_hwmon.rst |  34 ++++++
 drivers/hwmon/Kconfig                    |  10 ++
 drivers/hwmon/Makefile                   |   1 +
 drivers/hwmon/mc33xs2410_hwmon.c         | 178 +++++++++++++++++++++++++++++++
 drivers/pwm/Kconfig                      |   1 +
 drivers/pwm/pwm-mc33xs2410.c             |  20 +++-
 include/linux/mc33xs2410.h               |  16 +++
 8 files changed, 259 insertions(+), 2 deletions(-)
---
base-commit: 3b85883a9a7751ab198696f33f94afa428b43722
change-id: 20250507-mc33xs2410-hwmon-a5ff9efec005

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

