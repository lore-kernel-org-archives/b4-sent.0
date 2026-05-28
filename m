From: Rudraksha Gupta <guptarud@gmail.com>
Subject: [PATCH v6 0/3] Samsung Expressatt: Camera Flash
Date: Wed, 27 May 2026 19:34:29 -0700
Message-Id: <20260527-expressatt_camera_flash-v6-0-de0f150024e4@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4XPS2rDMBCA4asYraug11iRKaX3KCWM9YhF47i1H
 JMQfPfKziImkHY5Qvp+zZUk30efSFVcSe/HmGJ3zEP5UhDb4HHvaXR5JoKJkklWUn/+7n1KOAw
 7i63vcRcOmBrKpeWAWgmNSPLrfCvE8yJ/fN7m3v+ccmC4HZJ2ZpZAVbwuPgi98unQnWzz5S90F
 JRTpoyzqHiwEt/3LcbDxnbt29yqMXmahzYOVTHqDSNzsYlp6PrLstrIl+S/W4y5Q2tuTBm0dcG
 5e2kxR7Fy+Pa5I7IDVtQGSyGdrR8duXLEH/+R2fEaPDjYGsPCo6NWjuTPHZWdwL0xQWkFXD46c
 HeAyecOZMcACAWsRG3M2pmm6Rd4b9JaUAIAAA==
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
 Conor Dooley <conor.dooley@microchip.com>, David Heidelberg <david@ixit.cz>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779935671; l=4870;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=J+2nkkgXcCLD+tG5tT12zCWjVq1fGvc4r680m2gpWrs=;
 b=1WdZlTXwS4Jb+lCGhynv0ZnTjkNbvCzqZkvvOq6qZkvTcarK89IvoSxZ/FsKsnMuvgI3n+S9m
 WURMm5o0CMrDaRoexTis8p8xfa996cE6NWh0pDfqGm0bTv3o2Jz7mjh
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

// # Multiple strobes shouldn't cause errors
echo 200000 > flash_timeout
echo 1 > flash_strobe
echo 1 > flash_strobe
sleep 1
cat flash_strobe
dmesg | tail -20

// # Multiple strobes shouldn't cause errors (extreme test)
for i in $(seq 1 500); do echo 1 > flash_strobe; echo 0 > flash_strobe; done
dmesg | tail -20

// # Test minimal timeout (turns on briefly)
echo 1 > flash_timeout
echo 1 > flash_strobe
sleep 0.1
cat flash_strobe
dmesg | tail -20

// # Flash strobe overrides brightness and flashes at full brightness
echo 200000 > flash_timeout
echo 1 > brightness
echo 1 > flash_strobe
sleep 1
cat flash_strobe
cat brightness
dmesg | tail -20

Downstream reference:
Link: https://github.com/LineageOS/android_kernel_samsung_d2/blob/stable/cm-12.0-YNG4N/drivers/leds/Makefile#L51
Link: https://github.com/LineageOS/android_kernel_samsung_d2/blob/stable/cm-12.0-YNG4N/arch/arm/mach-msm/board-apexq-camera.c#L591

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
Changes in v6:
- Address Lee Jones's comments:
    - formatting
    - use cancel_delayed_work_sync()
- Link to v5: https://lore.kernel.org/r/20260503-expressatt_camera_flash-v5-0-95524506a799@gmail.com

Changes in v5:
- Address Lee Jones's comments:
    - formatting
    - use devm_regulator_get_optional()
    - use a workqueue instead of a timer
    - previously we were validating ent-gpios xor vin-supply at probe,
        but was removed. update the commit msg to reflect this
- Link to v4: https://lore.kernel.org/r/20260331-expressatt_camera_flash-v4-0-f1e99f474513@gmail.com

Changes in v4:
- Driver:
    - revert function renames
    - add comment to use flash instead if torch pin not available
- Link to v3: https://lore.kernel.org/r/20260326-expressatt_camera_flash-v3-0-e75e5d58990f@gmail.com

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

 .../devicetree/bindings/leds/richtek,rt8515.yaml   |  34 ++++-
 .../dts/qcom/qcom-msm8960-samsung-expressatt.dts   |  43 ++++++
 drivers/leds/flash/leds-rt8515.c                   | 148 ++++++++++++++++-----
 3 files changed, 188 insertions(+), 37 deletions(-)
---
base-commit: 3131ff5a117498bb4b9db3a238bb311cbf8383ce
change-id: 20260306-expressatt_camera_flash-13c15a7427aa
prerequisite-message-id: <20260527-expressatt-touchkey-v2-1-049dca41fc3a@gmail.com>
prerequisite-patch-id: 2b24e9ba47500ef05d38e37b40d8ca2dceb4716a

Best regards,
-- 
Rudraksha Gupta <guptarud@gmail.com>

