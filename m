From: Cryolitia PukNgae <liziyao@uniontech.com>
Date: Wed, 30 Jul 2025 20:56:16 +0800
Subject: [PATCH] iio: imu: bmi270: Match ACPI ID found on newer GPD
 firmware
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250730-bmi270-gpd-acpi-v1-1-1ffc85b17266@uniontech.com>
X-B4-Tracking: v=1; b=H4sIAG8WimgC/x3MQQqAIBBA0avErBvQoRK6SrRInWwWmShEIN09a
 fkW/1conIULzF2FzLcUuWKD7jtwxxYDo/hmIEWjIjWhPYWMwpA8bi4Jeh68Jut4nAy0KmXe5fm
 Py/q+HxuTkRdhAAAA
X-Change-ID: 20250206-bmi270-gpd-acpi-de4d12bce567
To: Alex Lanzano <lanzano.alex@gmail.com>, 
 Jonathan Cameron <jic23@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yao Zi <ziyao@disroot.org>, WangYuli <wangyuli@uniontech.com>, 
 Jun Zhan <zhanjun@uniontech.com>, Cryolitia PukNgae <liziyao@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753880186; l=1662;
 i=liziyao@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=tfDPKjat9rlbUiCQbb3HHtNunn+iGtYvXq3O0y2Qh+g=;
 b=LLI6ML1UHHB/RjQT+LS52yxqoWtKT7VwVJIiqKv+jIcM3jHAegOP76mcKY0NMnSU9cVg8zPFb
 WtHkRien4rQCN9mPTIntTTuagB5l141KW9fbX8/e0xzL3aoHwvd+z0w
X-Developer-Key: i=liziyao@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for liziyao@uniontech.com/20250730 with auth_id=471
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some GPD devices ship a buggy firmware that describes on-device BMI260
with ACPI ID "BMI0160". Since this is fixed in BIOS update v0.40,
let's match the correct ID to detect the device. The buggy ID "BMI0160"
is kept as well to maintain compatibility with older firmwares.

Signed-off-by: Cryolitia PukNgae <liziyao@uniontech.com>
---
Some GPD devices ship a buggy firmware that describes on-device BMI260
with ACPI ID "BMI0160". Since this is fixed in BIOS update v0.40[1],
let's match the correct ID to detect the device. The buggy ID "BMI0160"
is kept as well to maintain compatibility with older firmwares.

Link: http://download.softwincn.com/WIN%20Max%202024/Max2-7840-BIOS-V0.41.zip

[1]. See the update nodes in the archive file above
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
base-commit: 0db240bc077fd16cc16bcecfd7f4645bc474aa7e
change-id: 20250206-bmi270-gpd-acpi-de4d12bce567

Best regards,
-- 
Cryolitia PukNgae <liziyao@uniontech.com>

