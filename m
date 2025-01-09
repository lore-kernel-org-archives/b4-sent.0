From: PavithraUdayakumar-adi <pavithra.u@analog.com>
Subject: [PATCH v3 0/2] Add support for MAX31331 RTC
Date: Thu, 09 Jan 2025 15:59:56 +0530
Message-Id: <20250109-add_support_max31331_fix_3-v1-0-a74fac29bf49@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACSlf2cC/x3M0QqEIBBA0V+ReV7BcSqwX1kWEZ1qHirR3Qiif
 1/p8XDhXlC5CFcY1QWFD6mybw34UhCXsM2sJTWDNbY3aJwOKfn6y3kvX7+Gk5AI/SSnJx2Hzg4
 uWIdsoA1y4Rae+RsOgs99/wHD5wokcAAAAA==
X-Change-ID: 20250109-add_support_max31331_fix_3-c64269a291e0
To: Antoniu Miclaus <antoniu.miclaus@analog.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jean Delvare <jdelvare@suse.com>, 
 Guenter Roeck <linux@roeck-us.net>, 
 Christophe JAILLET <christophe.jaillet@wanadoo.fr>
Cc: linux-rtc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 PavithraUdayakumar-adi <pavithra.u@analog.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736418610; l=972;
 i=pavithra.u@analog.com; s=20241220; h=from:subject:message-id;
 bh=xRRlLnDdNPgPN0sW40gnB6StZmB2oxUH4YZ4q2xE94g=;
 b=4GCBlT93CXnIsbRyC0BuHL+gbpS66b3TFeG9oR8Fm+DX2rrDJtXvI0Kqi/m7pw1VFUU/VR+mp
 cC8CaW+9uSvCUdiXv4wsIL0egnWIWg28MgxEjuQHzPPqUmZLzLSG4I3
X-Developer-Key: i=pavithra.u@analog.com; a=ed25519;
 pk=RIhZrdpg71GEnmwm1eNn95TYUMDJOKVsFd37Fv8xf1U=
X-Endpoint-Received: by B4 Relay for pavithra.u@analog.com/20241220 with auth_id=303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series introduces support for the Maxim MAX31331 RTC.
It includes:

1. Device Tree bindings documentation for the MAX31331 chip.
2. The driver implementation for the MAX31331 RTC

Signed-off-by: PavithraUdayakumar-adi <pavithra.u@analog.com>

Changes in v3:
- Address review comments
- Rebase on v6.13-rc6
- Link to v2: https://lore.kernel.org/all/20250103-add_support_max31331_fix-v1-0-8ff3c7a81734@analog.com/

---
PavithraUdayakumar-adi (2):
      dt-bindings: rtc: max31335: Add max31331 support
      rtc: max31335: Add driver support for max31331

 .../devicetree/bindings/rtc/adi,max31335.yaml      |  22 ++-
 drivers/rtc/rtc-max31335.c                         | 163 +++++++++++++++------
 2 files changed, 138 insertions(+), 47 deletions(-)
---
base-commit: eea6e4b4dfb8859446177c32961c96726d0117be
change-id: 20250109-add_support_max31331_fix_3-c64269a291e0

Best regards,
-- 
PavithraUdayakumar-adi <pavithra.u@analog.com>

