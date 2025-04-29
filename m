From: Sung-Chi Li <lschyi@chromium.org>
Subject: [PATCH 0/3] Export fan control and register fans as cooling
 devices
Date: Tue, 29 Apr 2025 16:14:20 +0800
Message-Id: <20250429-cros_ec_fan-v1-0-a8d9e3efbb1a@chromium.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFyKEGgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDEyNL3eSi/OL41OT4tMQ83ZRE4yQzk8Rky2RDAyWgjoKi1LTMCrBp0bG
 1tQBABFOaXQAAAA==
X-Change-ID: 20250429-cros_ec_fan-da3b64ac9c10
To: Benson Leung <bleung@chromium.org>, Guenter Roeck <groeck@chromium.org>, 
 =?utf-8?q?Thomas_Wei=C3=9Fschuh?= <linux@weissschuh.net>, 
 Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: chrome-platform@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-hwmon@vger.kernel.org, linux-doc@vger.kernel.org, 
 Sung-Chi Li <lschyi@google.com>, Sung-Chi Li <lschyi@chromium.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745914465; l=2176;
 i=lschyi@chromium.org; s=20250429; h=from:subject:message-id;
 bh=Plr+eKET24dQ8Cc4qkU4oOyv/FkIHbVvHYuJwqLayx0=;
 b=B+aPviG+tNfkDTwtlggR0zOZTRRU03+WGP9jdqEtermjB3Z2bUBztZ357bM6C4CzxoEjJuoBK
 exqeoiWY7LmAU6Nr6j7XhC29otBOCoENKGoq0Y5jQaso56VLRpwqrBw
X-Developer-Key: i=lschyi@chromium.org; a=ed25519;
 pk=9gCZPRJmYyHDt6VN9FV2UreFcUr73JFrwYvmsltW9Y8=
X-Endpoint-Received: by B4 Relay for lschyi@chromium.org/20250429 with auth_id=392
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is a continuation of the previous series "Export the target RPM fan
control by ChromeOS EC under hwmon"
(https://lore.kernel.org/lkml/20250313-extend_ec_hwmon_fan-v1-0-5c566776f2c4@chromium.org/T/#t).
There is a change from controlling the target fan RPM value to control
the PWM value.

We anticipate to involve fans connected to EC as thermal cooling
devices, so we can utilize the thermal framework to have further thermal
control strategies.

This series updates the required EC controls definitions, implements the
mechanism for controlling fan PWM values, and registers these fans under
thermal framework as cooling devices.

Adapting comments from the previous series, the driver probes the host
command capability at beginning to see whether a fan is controllable:
  - if command `EC_CMD_PWM_GET_FAN_DUTY` is supported (v0, this is a
    new command).
  - if command `EC_CMD_THERMAL_AUTO_FAN_CTRL` v2 is supported.
  - if command `EC_CMD_PWM_SET_FAN_DUTY` v1 is supported.

This combination is selected as this is the minimum requirement for a
fan to be fully controllable under hwmon framework.

The driver supports changing the fan control mode, and allows to change
the fan PWM value only if the fan is in manual control mode. The power
management hook is implemented as well for keeping the fan control
settings, as EC will automatically restore the control method to auto
when device is suspended.

Change-Id: I4e2fdc8c4bc50778c0d04cfbefeaab7088d3181e
Signed-off-by: Sung-Chi Li <lschyi@google.com>
---
Sung-Chi Li (3):
      platform/chrome: update pwm fan control host commands
      hwmon: (cros_ec) add PWM control over fans
      hwmon: (cros_ec) register fans into thermal framework cooling devices

 Documentation/hwmon/cros_ec_hwmon.rst          |   7 +-
 drivers/hwmon/cros_ec_hwmon.c                  | 309 ++++++++++++++++++++++++-
 include/linux/platform_data/cros_ec_commands.h |  29 ++-
 3 files changed, 339 insertions(+), 6 deletions(-)
---
base-commit: 33035b665157558254b3c21c3f049fd728e72368
change-id: 20250429-cros_ec_fan-da3b64ac9c10

Best regards,
-- 
Sung-Chi Li <lschyi@chromium.org>

