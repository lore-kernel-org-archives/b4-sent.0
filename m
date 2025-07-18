From: Sung-Chi Li <lschyi@chromium.org>
Subject: [PATCH v6 0/2] Export fan control and register fans as cooling
 devices
Date: Fri, 18 Jul 2025 15:08:28 +0800
Message-Id: <20250718-cros_ec_fan-v6-0-8df018396b56@chromium.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOzyeWgC/23OTW7DIBCG4atErEPF8OOYrHKPqooGGGIWMRG0V
 qvIdy/OJonl5Yf0vMOdVSqJKjvu7qzQlGrKYxvdfsf8gOOFeAptMymkEVpa7kuuZ/LniCMPqFy
 n0VsPgjVxKxTT76P2+dX2kOp3Ln+P+ATL63ZnAi449sGSougc4MkPJV/Tz/UjlwtbUpN8ciPkO
 5eN62D6vqVRQNzg6oXDiqvluo3SSWOi8GGD6yfvYPV53bhHAKN7T1rbDW5euBTv3DRu7MESAjq
 nYMXnef4HfgesnaUBAAA=
X-Change-ID: 20250429-cros_ec_fan-da3b64ac9c10
To: Benson Leung <bleung@chromium.org>, Guenter Roeck <groeck@chromium.org>, 
 =?utf-8?q?Thomas_Wei=C3=9Fschuh?= <linux@weissschuh.net>, 
 Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>, 
 Jonathan Corbet <corbet@lwn.net>, 
 =?utf-8?q?Thomas_Wei=C3=9Fschuh?= <thomas@weissschuh.net>
Cc: chrome-platform@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-hwmon@vger.kernel.org, linux-doc@vger.kernel.org, 
 Sung-Chi Li <lschyi@google.com>, Sung-Chi Li <lschyi@chromium.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752822520; l=4414;
 i=lschyi@chromium.org; s=20250429; h=from:subject:message-id;
 bh=fUvHQZqTl24PCF89+WJfWZK205oQzlOcq+fyKB4X7l4=;
 b=ja3jexFOHyCaNVploN4rGApv+Exlr5UOcylDy5nMbClEN871PDR1+ygfdIO/AoQ0s2vtkk5+d
 gY6mUlGbMQRCzjQnbXS5RVRJkB2Xvi07/5ZxeMxnVHV7IdUGQu5JCyr
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
Changes in v6:
- Fix lines over 100 characters.
- Remove unnecessary out of memory message.
- Link to v5: https://lore.kernel.org/r/20250620-cros_ec_fan-v5-0-5979ea1abb31@chromium.org

Changes in v5:
- Fix line breaks.
- Directly return 0 when there is no error (rather than return ret
  variable).
- Rename CROS to CrOS.
- Preserve Acked-by and Reviewed-by tags.
- Link to v4: https://lore.kernel.org/r/20250619-cros_ec_fan-v4-0-ca11548ce449@chromium.org

Changes in v4:
- Treat fan control is supported without `CONFIG_PM` is enabled.
- Change logic of registering cooling devices for fan from abandom
  immediately to log warning logs, then continue with the next fan.
- Fix error checking logic to use IS_ERR for
  devm_thermal_of_cooling_device_register.
- Revise variable declaration ordering with reverse christmas tree.
- Rename member variable `manual_fan_pwm_values` to `manual_fan_pwm`.
- Use %pe for printing error pointers, and add newline for logs.
- Revise comments in suspend and resume hook.
- Link to v3: https://lore.kernel.org/r/20250512-cros_ec_fan-v3-0-a9f2b255f0cd@chromium.org

Changes in v3:
- Make required EC command versions macros.
- Add `CONFIG_THERMAL` guarding for registering as thermal fan cooling
  devices.
- Add error handling during registering thermal cooling devices, and
  immediately abort the registration if any error occurred to align with
  the thermal sensor registration in hwmon core.
- Add error handling for EC fan communication during suspend and resume.
- Add `CONFIG_PM` guarding for checking whether the EC supports a
  complete fan control in hwmon driver.
- Sort variables order in declaration.
- Separate declaration and logic to different sections.
- Move `cros_ec_thermal_cooling_ops` next right after the operation
  functions declaration.
- Improve describing the resume behavior in documentation.

Changes in v2:
- Change column from 80 to 100 and fix styles.
- Directly store driver data into platform dev with
  platform_set_drvdata.
- Unify the PWM unit (from 0 ~ 255) between hwmon and thermal cooling
  devices.
- Only fetch the fan control mode and PWM value when suspending rather
  than caching values when writing. The suspend hook is thus added.
- Link to v1: https://lore.kernel.org/r/20250429-cros_ec_fan-v1-0-a8d9e3efbb1a@chromium.org

---
Sung-Chi Li (2):
      hwmon: (cros_ec) add PWM control over fans
      hwmon: (cros_ec) register fans into thermal framework cooling devices

 Documentation/hwmon/cros_ec_hwmon.rst |   7 +-
 drivers/hwmon/cros_ec_hwmon.c         | 313 ++++++++++++++++++++++++++++++++++
 2 files changed, 319 insertions(+), 1 deletion(-)
---
base-commit: 024e09e444bd2b06aee9d1f3fe7b313c7a2df1bb
change-id: 20250429-cros_ec_fan-da3b64ac9c10

Best regards,
-- 
Sung-Chi Li <lschyi@chromium.org>

