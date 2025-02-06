From: Cryolitia PukNgae <Cryolitia@gmail.com>
Date: Thu, 06 Feb 2025 15:09:42 +0800
Subject: [PATCH] iio: imu: bmi270: Match ACPI ID found on newer GPD
 firmware
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250206-bmi270-gpd-acpi-v1-1-db638cfb9a3c@gmail.com>
X-B4-Tracking: v=1; b=H4sIADVgpGcC/x3MQQqAIBBA0avErBvQoRK6SrRInWwWmShEIN09a
 fkW/1conIULzF2FzLcUuWKD7jtwxxYDo/hmIEWjIjWhPYWMwpA8bi4Jeh68Jut4nAy0KmXe5fm
 Py/q+HxuTkRdhAAAA
X-Change-ID: 20250206-bmi270-gpd-acpi-de4d12bce567
To: Alex Lanzano <lanzano.alex@gmail.com>, 
 Jonathan Cameron <jic23@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yao Zi <ziyao@disroot.org>, Cryolitia PukNgae <Cryolitia@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1657; i=Cryolitia@gmail.com;
 h=from:subject:message-id; bh=vGeYvEdVrXEykpDXoY202pSht7dfgKW3Zo+sT/kvXh0=;
 b=LS0tLS1CRUdJTiBQR1AgTUVTU0FHRS0tLS0tCgprQTBEQUFvV1k1Z21DYUprZlR3Qnl5WmlBR
 2VrWUR1Z0F6MnBiUHAzYzJlV0U4bTVTSjVWL0VRRmJIQzJFM2xOCk5VanFnUVNaUTRoMUJBQVdD
 Z0FkRmlFRXFCdzdrWDUwaW12VUg0UzhZNWdtQ2FKa2ZUd0ZBbWVrWURzQUNna1EKWTVnbUNhSmt
 mVHdwNlFFQTVZODYrTnBvV1pKQmFxYVlQS1JCa1JEU09qaVdqZHdYWDB3ZVE4dk1qMHNBL1JqRQ
 pPMm5uYjZtcjVZbFgvNWp0bUJRMXRxdTZZVU9ySERlSXo5NjZCK1lQCj0zVFB5Ci0tLS0tRU5EI
 FBHUCBNRVNTQUdFLS0tLS0K
X-Developer-Key: i=Cryolitia@gmail.com; a=openpgp;
 fpr=1C3C6547538D7152310C0EEA84DD0C0130A54DF7
X-Endpoint-Received: by B4 Relay for Cryolitia@gmail.com/default with auth_id=186
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some GPD devices ship a buggy firmware that describes on-device BMI260 with ACPI ID "BMI0160". Since this is fixed in BIOS update v0.40[1], let's match the correct ID to detect the device. The buggy ID "BMI0160" is kept as well to maintain compatibility with older firmwares.

---
Some GPD devices ship a buggy firmware that describes on-device BMI260 with ACPI ID "BMI0160". Since this is fixed in BIOS update v0.40[1], let's match the correct ID to detect the device. The buggy ID "BMI0160" is kept as well to maintain compatibility with older firmwares.

Link: http://download.softwincn.com/WIN%20Max%202024/Max2-7840-BIOS-V0.41.zip

[1]. See the update nodes in the archive file above

Signed-off-by: Cryolitia PukNgae <Cryolitia@gmail.com>
---
 drivers/iio/imu/bmi270/bmi270_i2c.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/iio/imu/bmi270/bmi270_i2c.c b/drivers/iio/imu/bmi270/bmi270_i2c.c
index 44699ab589097eaa0eec5f2172245496ed031185..f66ae01e301df24f1e563e059da8cc531fc173eb 100644
--- a/drivers/iio/imu/bmi270/bmi270_i2c.c
+++ b/drivers/iio/imu/bmi270/bmi270_i2c.c
@@ -40,6 +40,8 @@ static const struct i2c_device_id bmi270_i2c_id[] = {
 static const struct acpi_device_id bmi270_acpi_match[] = {
 	/* GPD Win Mini, Aya Neo AIR Pro, OXP Mini Pro, etc. */
 	{ "BMI0160",  (kernel_ulong_t)&bmi260_chip_info },
+	/* GPD Win Max 2 2023(sincice BIOS v0.40), etc. */
+	{ "BMI0260",  (kernel_ulong_t)&bmi260_chip_info },
 	{ }
 };
 

---
base-commit: ffd294d346d185b70e28b1a28abe367bbfe53c04
change-id: 20250206-bmi270-gpd-acpi-de4d12bce567

Best regards,
-- 
Cryolitia PukNgae <Cryolitia@gmail.com>

