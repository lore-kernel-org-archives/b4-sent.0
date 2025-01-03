From: PavithraUdayakumar-adi <pavithra.u@analog.com>
Subject: [PATCH v2 0/2] Add support for MAX31331 RTC
Date: Fri, 03 Jan 2025 12:34:18 +0530
Message-Id: <20250103-add_support_max31331_fix-v1-0-8ff3c7a81734@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPKLd2cC/x2MQQrDIBAAvxL2XEFdbCBfKUVW3TZ7SCLaSCDk7
 5EeZ2DmhMpFuMI0nFC4SZVt7WAeA8SZ1i8rSZ3Bauu00agoJV/3nLfy8wsdaBCN/8ih+OlCCBR
 HTAQ9z4W7/q9f0Cy8r+sGrcpK424AAAA=
X-Change-ID: 20250103-add_support_max31331_fix-e65bbbac73da
To: Antoniu Miclaus <antoniu.miclaus@analog.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jean Delvare <jdelvare@suse.com>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: linux-rtc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 PavithraUdayakumar-adi <pavithra.u@analog.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735887863; l=1003;
 i=pavithra.u@analog.com; s=20241220; h=from:subject:message-id;
 bh=jdxHvjuFL3Z1KgXxrlmqLozw/Gwy+74Oep59dG14Ue4=;
 b=DdvvlnW5b4ktUmdeApxFEkJNF+ur0ukx8T6FdeKhDpjDHLllsq6Iuz9xoy0h9V2yCnWikhL8C
 esbXOIZt0DhAmD9OFbUVesS5b71sDlXl/tK7nCvrCW6e8H7kOcIcogX
X-Developer-Key: i=pavithra.u@analog.com; a=ed25519;
 pk=RIhZrdpg71GEnmwm1eNn95TYUMDJOKVsFd37Fv8xf1U=
X-Endpoint-Received: by B4 Relay for pavithra.u@analog.com/20241220 with auth_id=303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series introduces support for the Maxim MAX31331 RTC.
It includes:

1. Device Tree bindings documentation for the MAX31331 chip.
2. The driver implementation for the MAX31331 RTC.

Signed-off-by: PavithraUdayakumar-adi <pavithra.u@analog.com>
---
Changes in v2:
- Fix issue with device tree binding in v1
- Revert a header change in driver code
- Link to v1: https://lore.kernel.org/all/20241223-max31331-driver-support-v1-0-f9499bd598f5@analog.com

---
PavithraUdayakumar-adi (2):
      dtbindings:rtc:max31335:Add max31331 support
      rtc:max31335: Add driver support for max31331

 .../devicetree/bindings/rtc/adi,max31335.yaml      |  32 +++-
 drivers/rtc/rtc-max31335.c                         | 182 +++++++++++++++------
 2 files changed, 157 insertions(+), 57 deletions(-)
---
base-commit: fc033cf25e612e840e545f8d5ad2edd6ba613ed5
change-id: 20250103-add_support_max31331_fix-e65bbbac73da

Best regards,
-- 
PavithraUdayakumar-adi <pavithra.u@analog.com>

