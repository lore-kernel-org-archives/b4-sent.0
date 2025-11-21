From: Rudraksha Gupta <guptarud@gmail.com>
Subject: [PATCH v2 0/5] ARM: dts: qcom: msm8960: expressatt: Add more
 peripherals
Date: Fri, 21 Nov 2025 03:44:43 -0800
Message-Id: <20251121-expressatt_nfc_accel_magn_light-v2-0-54ce493cc6cf@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKtQIGkC/42PUW7DIAxArxLxPRCGhEA1Tb3HVEWMmQQtIRuwq
 FWVu4+mF9jns6z37DvJmAJmcmruJOEWclhjBfHSEDfZOCINn5WJ4KIDAEPx+p0wZ1vKEL0brHM
 4D4sd4zCHcSrU9xq50KYHrUi11G0frkfh/fLkhD+/NVSeQ7I8dEfo1LxCrwRwZbSShhnZa5BMt
 bLTneAGQGtpwBj20dJyO39hijizNY1v5OGeQi5ruh3PbHDI/333BpRTJZUH5XnnfHseFxtm5ta
 FXPZ9/wNW18L8KgEAAA==
X-Change-ID: 20251119-expressatt_nfc_accel_magn_light-f78e02897186
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763725484; l=3612;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=Yi/oXfy9j6fRDTfKxTvKwXsP2XvE8pwQxQuLxQPvpMc=;
 b=hLfsrD5gEKvsBouEZ8uueZRE9XQ2YD5veq8OcCbTneNMiejLa1IcrZF53GjnU7a5tyULi6GGn
 9EPnkelO1GJCf+RGk8/zB9jkCP1OAF0dys4GZaYIoepXpI+urVY8Jwp
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Intro:
=================
The following is now working on the Samsung Galaxy Express SGH-I437, an
old 2012 Android phone:
- Light Sensor
    - Proximity is currently giving bogus values
- NFC
- Magnetometer
    - Maybe need to update the mount matrix?
- Accelerometer
    - Maybe need to update the mount matrix?

Tests:
=================
Light Sensor
=================
/sys/bus/iio/devices/iio:device2 # cat in_intensity0_raw && cat in_intensity1_raw
0
0
/sys/bus/iio/devices/iio:device2 # cat in_intensity0_raw && cat in_intensity1_raw
163
28

=================
NFC
=================
nfc0:
          Tags: [ ]
          Devices: [ ]
          Protocols: [ Felica MIFARE Jewel ISO-DEP NFC-DEP ]
          Powered: Yes
          RF Mode: None
          lto: 150
          rw: 15
          miux: 2047

Start polling on nfc0 as initiator

Targets found for nfc0
  Tags: [ tag4 ]
  Devices: [ ]

=================
Magnetometer
=================
/sys/bus/iio/devices/iio:device1 # cat in_magn_x_raw && cat in_magn_y_raw && cat in_magn_z_raw
-441672
1223706
3275580
/sys/bus/iio/devices/iio:device1 # cat in_magn_x_raw && cat in_magn_y_raw && cat in_magn_z_raw
-364650
1206172
3248674
/sys/bus/iio/devices/iio:device1 # cat in_magn_x_raw && cat in_magn_y_raw && cat in_magn_z_raw
-439362
1214092
3180892

=================
Accelerometer
=================
/sys/bus/iio/devices/iio:device0 # cat in_accel_x_raw && cat in_accel_y_raw && cat in_accel_z_raw
16
484
-48
/sys/bus/iio/devices/iio:device0 # cat in_accel_x_raw && cat in_accel_y_raw && cat in_accel_z_raw
13
489
469
/sys/bus/iio/devices/iio:device0 # cat in_accel_x_raw && cat in_accel_y_raw && cat in_accel_z_raw
433
106
48

More Information:
=================
- Device page:
https://wiki.postmarketos.org/wiki/Samsung_Galaxy_Express_SGH-I437_(samsung-expressatt)
- Downstream kernel (uses board files):
https://github.com/LineageOS/android_kernel_samsung_d2/blob/stable/cm-12.0-YNG4N/arch/arm/mach-msm/board-express.c

Note: These patches were assisted with AI (specifically Claude) as it
was easily able to translate the old board file into a DTS format that
mainline understands.

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
Changes in v2:
- Fixed formatting issues
- Use GSBI instead of i2c-gpio
- Remove regulator-always-on
- Link to v1: https://lore.kernel.org/r/20251119-expressatt_nfc_accel_magn_light-v1-0-636f16f05cf4@gmail.com

---
Rudraksha Gupta (5):
      ARM: dts: qcom: msm8960: Add GSBI2 & GSBI7
      ARM: dts: qcom: msm8960: expressatt: Add Light/Proximity Sensor
      ARM: dts: qcom: msm8960: expressatt: Add NFC
      ARM: dts: qcom: msm8960: expressatt: Add Magnetometer
      ARM: dts: qcom: msm8960: expressatt: Add Accelerometer

 .../dts/qcom/qcom-msm8960-samsung-expressatt.dts   | 110 +++++++++++++++++++++
 arch/arm/boot/dts/qcom/qcom-msm8960.dtsi           |  96 ++++++++++++++++++
 2 files changed, 206 insertions(+)
---
base-commit: a771210bab42017434c91411e16694ac4fd7afc2
change-id: 20251119-expressatt_nfc_accel_magn_light-f78e02897186
prerequisite-message-id: <176210698639.937813.643585209118839199.b4-ty@kernel.org>
prerequisite-patch-id: befdfe1948c2fbfb867597a6de917c8067fd57be
prerequisite-patch-id: 70a2b0837b9846d8a775f464295da73ca8ff26b4
prerequisite-patch-id: 20e005aa4312c3525e1b90f33a398189b9e2b3b7
prerequisite-patch-id: 970e0eb8af1736e4565fc37830576a67bf7b3227
prerequisite-patch-id: babd3b55d9ff28f19dbc3f7978742c58ef436aee

Best regards,
-- 
Rudraksha Gupta <guptarud@gmail.com>

