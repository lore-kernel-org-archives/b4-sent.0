From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Thu, 21 Aug 2025 14:17:50 +0800
Subject: [PATCH v3] iio: imu: bmi270: Match PNP ID found on newer GPD
 firmware
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250821-bmi270-gpd-acpi-v3-1-91a873cb87c0@uniontech.com>
X-B4-Tracking: v=1; b=H4sIAA26pmgC/2XOTQ7CIBAF4Ks0rMXAVKBx5T2MiwLTdhb9CVSia
 Xp3aV2Y2MzqTfK+mYVFDISRXYuFBUwUaRxyKE8Fc109tMjJ58xAgBIgNLc9gRG8nTyv3UTc48V
 LsA6VNiy3poANvXbx/si5oziP4b0fSHLbfi1TioOVJM/TNK5SVhrQ+vYc8j8zuu7sxp5tXoKfU
 Ul1NCAbFUpvdeVL7eW/sa7rBzW6sh72AAAA
X-Change-ID: 20250206-bmi270-gpd-acpi-de4d12bce567
To: Alex Lanzano <lanzano.alex@gmail.com>, 
 Jonathan Cameron <jic23@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yao Zi <ziyao@disroot.org>, WangYuli <wangyuli@deepin.org>, 
 Jun Zhan <zhanjun@uniontech.com>, niecheng1@uniontech.com2, 
 Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755757073; l=2828;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=1BJaTH0WmgAVQTuafmvfpaUKGXqYqrjXyykU4/x5k0w=;
 b=bYCc/+pZk+QLxlxEEs/zCvLhIQzpdfMtt0qc1684By1MebgKpEKRmorce3cjCNx1ukrLfUVj5
 yd8jXNYNzsbBBlHzFyXWLzR7UWbLMvs5Hw5zD8/xK2Lb9mosUw0h111
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

GPD devices originally used BMI160 sensors with the "BMI0160" PNP ID.
When they switched to BMI260 sensors in newer hardware, they reused
the existing Windows driver which accepts both "BMI0160" and "BMI0260"
IDs. Consequently, they kept "BMI0160" in DSDT tables for new BMI260
devices, causing driver mismatches in Linux.

1. GPD updated BIOS v0.40+[1] for newer devices to report "BMI0260" for
BMI260 sensors to avoid loading bmi160 driver on Linux. While this
isn't Bosch's VID;
2. Bosch's official Windows driver uses "BMI0260" as a compatible ID
3. We're seeing real devices shipping with "BMI0260" in DSDT

The DSDT excerpt of GPD G1619-04 with BIOS v0.40:

Scope (_SB.I2CC)
{
    Device (BMA2)
    {
        Name (_ADR, Zero)  // _ADR: Address
        Name (_HID, "BMI0260")  // _HID: Hardware ID
        Name (_CID, "BMI0260")  // _CID: Compatible ID
        Name (_DDN, "Accelerometer")  // _DDN: DOS Device Name
        Name (_UID, One)  // _UID: Unique ID
        Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
        {
            Name (RBUF, ResourceTemplate ()
            {
                I2cSerialBusV2 (0x0069, ControllerInitiated, 0x00061A80,
                    AddressingMode7Bit, "\\_SB.I2CC",
                    0x00, ResourceConsumer, , Exclusive,
                    )
            })
            Return (RBUF) /* \_SB_.I2CC.BMA2._CRS.RBUF */
        }
        # omit some noise
    }
}

Link: http://download.softwincn.com/WIN%20Max%202024/Max2-7840-BIOS-V0.41.zip #1

Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
Changes in v3:
- Improve commit message
- Link to v2: https://lore.kernel.org/r/20250815-bmi270-gpd-acpi-v2-1-8e1db68d36d1@uniontech.com

Changes in v2:
- Improve commit message
- Add DSDT table
- Link to v1: https://lore.kernel.org/r/20250730-bmi270-gpd-acpi-v1-1-1ffc85b17266@uniontech.com
---
 drivers/iio/imu/bmi270/bmi270_i2c.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/iio/imu/bmi270/bmi270_i2c.c b/drivers/iio/imu/bmi270/bmi270_i2c.c
index c77839b03a969f6f149c025a0305c4b9b8ac6571..b909a421ad0176ee414f2f96ff09db2297586ded 100644
--- a/drivers/iio/imu/bmi270/bmi270_i2c.c
+++ b/drivers/iio/imu/bmi270/bmi270_i2c.c
@@ -41,6 +41,8 @@ static const struct i2c_device_id bmi270_i2c_id[] = {
 static const struct acpi_device_id bmi270_acpi_match[] = {
 	/* GPD Win Mini, Aya Neo AIR Pro, OXP Mini Pro, etc. */
 	{ "BMI0160",  (kernel_ulong_t)&bmi260_chip_info },
+	/* GPD Win Max 2 2023(sincice BIOS v0.40), etc. */
+	{ "BMI0260",  (kernel_ulong_t)&bmi260_chip_info },
 	{ }
 };
 

---
base-commit: 24ea63ea387714634813359e2c8e0e6c36952f73
change-id: 20250206-bmi270-gpd-acpi-de4d12bce567

Best regards,
-- 
Cryolitia PukNgae <cryolitia@uniontech.com>

