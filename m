From: Rudraksha Gupta <guptarud@gmail.com>
Subject: [PATCH v3 0/3] Samsung Expressatt: Camera Flash
Date: Thu, 26 Mar 2026 00:57:30 -0700
Message-Id: <20260326-expressatt_camera_flash-v3-0-e75e5d58990f@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAOrmxGkC/4WPy2rDMBBFf8VoXQU9bLkypeQ/Sgmjh2PRKG4kR
 SQE/3tlZVFvSpnVHWbO4T5QtMHZiIbmgYLNLrr5XAJ/aZCe4Hy02JmSESNMEE4EtrfvYGOElA4
 avA1wGE8QJ0y5ph30LesBUPkuV6O7VfLH5zMHe7kWQXoukV8xVTA0b4XfUUa6DR+n+aqnL3vHm
 eIybdsqyXotR74/enCnnZ79++pSEC0uwbs0NFnsqESrcnIxzeFeu2Vanf/WKCqCFZVSjL02ozG
 /qsrMbMOhr39zWOF0mikJgnGj1ZazLMsPaB6EDXkBAAA=
X-Change-ID: 20260306-expressatt_camera_flash-13c15a7427aa
To: Lee Jones <lee@kernel.org>, Pavel Machek <pavel@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Liam Girdwood <lgirdwood@gmail.com>, 
 Mark Brown <broonie@kernel.org>
Cc: linux-leds@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>, 
 Conor Dooley <conor.dooley@microchip.com>, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774511852; l=3372;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=RlIM0MUSwd5wz+8XPIpqDDZrKwpihhE+hECNmip7gPI=;
 b=zbdwGQMdwTftPx42S7rTi4MPfe2+CYew1vD4HdwzXJiO6y16XrYpftcKvYRpJEiv2dkXaxRO/
 rmGccPAbWtyBFvtr0rcTlEfdCkM1b1pNLzUAfaFIqGyJmtq2wNaznid
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This small series adds camera flash to an existing similar mainline
driver and adds it to the Samsung Expressatt's DTS

// Tests

// # Navigate to LED
sudo su
cd /sys/class/leds/white:flash

// # Should stay at dim brightness
echo 1 > brightness
echo 1 > brightness
echo 1 > brightness
echo 1 > brightness
echo 0 > brightness           # LED_OFF

// # Max Brightness
echo 50 > brightness
echo 0 > brightness           # LED_OFF
echo 99 > brightness
echo 0 > brightness           # LED_OFF
echo 1000 > brightness
echo 0 > brightness           # LED_OFF
echo 100 > brightness
echo 0 > brightness           # LED_OFF

// # Should increase in brightness
for i in $(seq 1 16); do echo $i > brightness; sleep 1; done
echo 0 > brightness           # LED_OFF

// # Test flash strobe (rt8515_led_flash_strobe_set)
cat max_flash_timeout          # check max
echo 200000 > flash_timeout    # 200ms
echo 1 > flash_strobe          # strobe ON → brightness_commit + timer
cat flash_strobe               # should read 1, then 0 after timeout
sleep 1
cat flash_strobe               # should be 0 (timer fired)

// # Test manual strobe cancel
echo 1 > flash_strobe ; echo 0 > flash_strobe          # immediate off

// # Check regulator error handling
dmesg | tail -20                     # look for any "failed to turn off LED" msgs

Downstream reference:
Link: https://github.com/LineageOS/android_kernel_samsung_d2/blob/stable/cm-12.0-YNG4N/drivers/leds/Makefile#L51
Link: https://github.com/LineageOS/android_kernel_samsung_d2/blob/stable/cm-12.0-YNG4N/arch/arm/mach-msm/board-apexq-camera.c#L591

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
Changes in v3:
- DTS:
    - Renamed and reordered nodes
- Driver:
    - Use regulator_is_enabled() instead of reg_enabled
    - remove ent xor vin check
    - remove rt->reg == -ENODEV check
    - rename functions to reflect what they do and added ret's
    - Fixed: LED was increasing in brightness when setting the same
        brightness multiple times
- Link to v2: https://lore.kernel.org/r/20260318-expressatt_camera_flash-v2-0-5c2b9a623dcb@gmail.com

Changes in v2:
- dt-bindings: Explain the hardware and not the driver
- **/*: Use vin-supply instead of unlock-gpio
- expressatt DTS: Reorder pinctrl-*
- expressatt DTS: Define rfs-ohms to a default (couldn't find
                  information about this)
- Link to v1: https://lore.kernel.org/r/20260306-expressatt_camera_flash-v1-0-b1996f7cdfdd@gmail.com

---
Rudraksha Gupta (3):
      dt-bindings: leds: rt8515: Support single-GPIO flash ICs with vin supply
      leds: flash: rt8515: Support single-GPIO flash ICs with vin supply
      ARM: dts: qcom: msm8960: expressatt: Add camera flash

 .../devicetree/bindings/leds/richtek,rt8515.yaml   | 34 +++++++-
 .../dts/qcom/qcom-msm8960-samsung-expressatt.dts   | 43 +++++++++++
 drivers/leds/flash/leds-rt8515.c                   | 90 +++++++++++++++++-----
 3 files changed, 148 insertions(+), 19 deletions(-)
---
base-commit: e9ec05addd1a067fc7cb218f20ecdc1b1b0898c0
change-id: 20260306-expressatt_camera_flash-13c15a7427aa
prerequisite-message-id: <20251205-expressatt-touchkey-v1-1-1444b927c9f3@gmail.com>
prerequisite-patch-id: 8de4de7909722ccaf385c4224f25a623eaa72c28

Best regards,
-- 
Rudraksha Gupta <guptarud@gmail.com>

