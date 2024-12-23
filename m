From: PavithraUdayakumar-adi <pavithra.u@analog.com>
Subject: [PATCH 0/2] Subject: [PATCH v1 0/2] Add support for MAX31331 RTC
Date: Mon, 23 Dec 2024 11:57:43 +0530
Message-Id: <20241223-max31331-driver-support-v1-0-f9499bd598f5@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAN8CaWcC/x2MQQ5AMBAAvyJ7toluCfEVcShd7AHNFpGIv2scZ
 5KZByKrcIQ2e0D5kij7lsDkGYyL22ZG8YmBCioNkcXV3dZYa9CrXKwYzxB2PdANVdJNPXrykOq
 gPMn9n7v+fT8pEnRMaQAAAA==
X-Change-ID: 20241223-max31331-driver-support-ab513387cd2d
To: Antoniu Miclaus <antoniu.miclaus@analog.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jean Delvare <jdelvare@suse.com>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: linux-rtc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 PavithraUdayakumar-adi <pavithra.u@analog.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734935277; l=874;
 i=pavithra.u@analog.com; s=20241220; h=from:subject:message-id;
 bh=BUoyR5rCkmanl4wSU8ZX2PoK3BmpB+33e48XNgyU860=;
 b=Q2IaHBVCkh3VTYh/vVW7NIUlHEQyv1IjmAXaVrVlGqZ5jBpSxjtx/3NBD6wta5UuRSC+8ViOq
 cAdkpDH9WS2A6Gw3/yn7/eigZWRcfcp+LgYoRS0V1ELepyWLuzarRgA
X-Developer-Key: i=pavithra.u@analog.com; a=ed25519;
 pk=RIhZrdpg71GEnmwm1eNn95TYUMDJOKVsFd37Fv8xf1U=
X-Endpoint-Received: by B4 Relay for pavithra.u@analog.com/20241220 with auth_id=303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series introduces support for the Maxim MAX31331 RTC.
It includes:

1. Device Tree bindings documentation for the MAX31331 chip.
2. The driver implementation for the MAX31331 RTC.

The changes have been tested with hardware and verified against the
YAML schema.

Signed-off-by: PavithraUdayakumar-adi <pavithra.u@analog.com>
---
PavithraUdayakumar-adi (2):
      dtbindings:rtc:max31335:Add max31331 support
      rtc:max31335: Add driver support for max31331

 .../devicetree/bindings/rtc/adi,max31335.yaml      |  32 +++-
 drivers/rtc/rtc-max31335.c                         | 184 +++++++++++++++------
 2 files changed, 158 insertions(+), 58 deletions(-)
---
base-commit: 4bbf9020becbfd8fc2c3da790855b7042fad455b
change-id: 20241223-max31331-driver-support-ab513387cd2d

Best regards,
-- 
PavithraUdayakumar-adi <pavithra.u@analog.com>

