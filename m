From: PavithraUdayakumar-adi <pavithra.u@analog.com>
Subject: [PATCH v4 0/2] Add support for MAX31331 RTC
Date: Sun, 19 Jan 2025 13:17:37 +0530
Message-Id: <20250119-add_support_max31331_fix_5-v1-0-73f7be59f022@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIABmujGcC/x3MTQqDMBBA4avIrA1k8qPEq0gJqRl1FmpIWhHEu
 zd0+fHg3VAoMxUYmhsynVz42CuwbWBaw76Q4FgNSiorEZ0IMfryTenIH7+FS6PW6Ge+vBWuM+b
 dW9krN0EdpEw1/OcjnAZez/MDaJ0/uHAAAAA=
X-Change-ID: 20250119-add_support_max31331_fix_5-9644b750729c
To: Antoniu Miclaus <antoniu.miclaus@analog.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jean Delvare <jdelvare@suse.com>, 
 Guenter Roeck <linux@roeck-us.net>, 
 =?utf-8?q?Nuno_S=C3=A1?= <noname.nuno@gmail.com>
Cc: linux-rtc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 PavithraUdayakumar-adi <pavithra.u@analog.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1737272867; l=1840;
 i=pavithra.u@analog.com; s=20241220; h=from:subject:message-id;
 bh=CIKaCZcT16a6tJEODh7bzMFplHmaUEsUgpKbCILga5I=;
 b=3O14u94m49fkw3rv39FXa5CDj0/G6POCiCUDTazBHUBouSv8Wxmt42lv959ikYDoCzjdkdX8Z
 0LzBej+o747CgW9Twe3hc8r+KQ0+3d9X4CtQu5Jz0QZhh+10GD/2GaD
X-Developer-Key: i=pavithra.u@analog.com; a=ed25519;
 pk=RIhZrdpg71GEnmwm1eNn95TYUMDJOKVsFd37Fv8xf1U=
X-Endpoint-Received: by B4 Relay for pavithra.u@analog.com/20241220 with auth_id=303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series introduces support for the Maxim MAX31331 RTC.
It includes:

1. Device Tree bindings documentation for the MAX31331 chip.
2. The driver implementation for the MAX31331 RTC

---
Changes in v4:
- Reverted the I2C address change for MAX31335 RTC (0x69) and removed it from the property register;
  will include it in a separate fix.
- Added id as a member of struct chip_desc
- Rebase on v6.13-rc7
- Link to v3: https://lore.kernel.org/all/20250109-add_support_max31331_fix_3-v1-0-a74fac29bf49@analog.com/
---
Changes in v3:
- Added missing spaces in driver code
- Removed binding for checking address
- Rebase on v6.13-rc6
- Link to v2: https://lore.kernel.org/all/20250103-add_support_max31331_fix-v1-0-8ff3c7a81734@analog.com/
---
To: Antoniu Miclaus <antoniu.miclaus@analog.com>
To: Alexandre Belloni <alexandre.belloni@bootlin.com>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Jean Delvare <jdelvare@suse.com>
To: Guenter Roeck <linux@roeck-us.net>
To: Nuno Sá <noname.nuno@gmail.com>
Cc: linux-rtc@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-hwmon@vger.kernel.org
Signed-off-by: PavithraUdayakumar-adi <pavithra.u@analog.com>

---
PavithraUdayakumar-adi (2):
      dt-bindings: rtc: max31335: Add max31331 support
      rtc: max31335: Add driver support for max31331

 .../devicetree/bindings/rtc/adi,max31335.yaml      |   4 +-
 drivers/rtc/rtc-max31335.c                         | 165 +++++++++++++++------
 2 files changed, 125 insertions(+), 44 deletions(-)
---
base-commit: 5bc55a333a2f7316b58edc7573e8e893f7acb532
change-id: 20250119-add_support_max31331_fix_5-9644b750729c

Best regards,
-- 
PavithraUdayakumar-adi <pavithra.u@analog.com>

