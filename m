From: PavithraUdayakumar-adi <pavithra.u@analog.com>
Subject: [PATCH RESEND v5 0/2] Add support for MAX31331 RTC
Date: Mon, 17 Feb 2025 18:17:15 +0530
Message-Id: <20250217-add_support_max31331_fix_8-v1-0-16ebcfc02336@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANMvs2cC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDI0Nz3cSUlPji0oKC/KKS+NzECmNDY2PD+LTMingL3UTLxDQTc4MU0+R
 EYyWgAQVFqUAJsOHRSkGuwa5+LgplpkqxtbUAZvihj3cAAAA=
X-Change-ID: 20250217-add_support_max31331_fix_8-a9af470d5ca3
To: Antoniu Miclaus <antoniu.miclaus@analog.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jean Delvare <jdelvare@suse.com>, 
 Guenter Roeck <linux@roeck-us.net>, 
 =?utf-8?q?Nuno_S=C3=A1?= <noname.nuno@gmail.com>
Cc: linux-rtc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 Christophe JAILLET <christophe.jaillet@wanadoo.fr>, 
 PavithraUdayakumar-adi <pavithra.u@analog.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739796453; l=1888;
 i=pavithra.u@analog.com; s=20241220; h=from:subject:message-id;
 bh=PTSy1ip0l95HNNQQE+rcttEDB0KFrDuEV+630qcL2IM=;
 b=GEPLWHzuMBYTO6EresIlfpo7HAopxkDf6L5smseqo1eSfTDrJKoO9S/ltULxyNfxkr6IJzyks
 x2FXYLOP0zYDemNc9ckp+qoqoj65TD4aTngiFvOU/ZoI1tVIusTxSaY
X-Developer-Key: i=pavithra.u@analog.com; a=ed25519;
 pk=RIhZrdpg71GEnmwm1eNn95TYUMDJOKVsFd37Fv8xf1U=
X-Endpoint-Received: by B4 Relay for pavithra.u@analog.com/20241220 with auth_id=303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series introduces support for the Maxim MAX31331 RTC.
It includes:

1. Device Tree bindings documentation for MAX31331.
2. The driver implementation for the MAX31331 RTC.

---
Resend v5:
- [PATCH RESEND v5 2/2]: Added id as a member of struct chip_desc in v4 [Nuno Sa], the patch requires a review. 
- Rebase v6.14-rc3                                    
- Link to v5: https://lore.kernel.org/r/20250131-add_support_max31331_fix_7-v1-0-d29d5de3d562@analog.com

Changes in v5:
- Removed the commit description stating max31331 and max31335 are compatible.
- Rebase v6.13
- Link to v4: https://lore.kernel.org/all/20250119-add_support_max31331_fix_5-v1-0-73f7be59f022@analog.com/
---
Changes in v4:
- Reverted the I2C address change for MAX31335 RTC (0x69) and removed it from the property register;
  will include it in a separate fix.
- Added id as a member of struct chip_desc [Nuno Sa]
- Rebase on v6.13-rc7
- Link to v3: https://lore.kernel.org/all/20250109-add_support_max31331_fix_3-v1-0-a74fac29bf49@analog.com/
---
Changes in v3:
- Added missing spaces in driver code
- Removed binding for checking address
- Rebase on v6.13-rc6
- Link to v2: https://lore.kernel.org/all/20250103-add_support_max31331_fix-v1-0-8ff3c7a81734@analog.com/
---

Signed-off-by: PavithraUdayakumar-adi <pavithra.u@analog.com>

---
PavithraUdayakumar-adi (2):
      dt-bindings: rtc: max31335: Add max31331 support
      rtc: max31335: Add driver support for max31331

 .../devicetree/bindings/rtc/adi,max31335.yaml      |   4 +-
 drivers/rtc/rtc-max31335.c                         | 165 +++++++++++++++------
 2 files changed, 125 insertions(+), 44 deletions(-)
---
base-commit: 0ad2507d5d93f39619fc42372c347d6006b64319
change-id: 20250217-add_support_max31331_fix_8-a9af470d5ca3

Best regards,
-- 
PavithraUdayakumar-adi <pavithra.u@analog.com>

