From: Carl Lee <carl.lee@amd.com>
Date: Thu, 05 Feb 2026 18:01:38 +0800
Subject: [PATCH v2 2/3] hwmon: pmbus: mpq8785: add support for MPQ8786
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260205-dt-bindings-hwmon-pmbus-mpq8785-add-mpq8786-support-v2-2-3744cd9b2850@amd.com>
References: <20260205-dt-bindings-hwmon-pmbus-mpq8785-add-mpq8786-support-v2-0-3744cd9b2850@amd.com>
In-Reply-To: <20260205-dt-bindings-hwmon-pmbus-mpq8785-add-mpq8786-support-v2-0-3744cd9b2850@amd.com>
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Charles Hsu <ythsu0511@gmail.com>
Cc: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, carl.lee@amd.com, peter.shen@amd.com, 
 colin.huang2@amd.com
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770285700; l=2876;
 i=carl.lee@amd.com; s=20260203; h=from:subject:message-id;
 bh=RJRo1UlIAD5Na+x5KlUjzgyX3K81PgptdiZZtQGDLQg=;
 b=Moi4leam1a/lz1BX25DF2RYSxY3ZhMmuotWye7pZWpalDxga6mMrmJEVZ1CwbhoaThEZ6V9ve
 VC7TINzKVbOCYYsObg46wq9Dys29d88t4e0AS7ohgsu9sNM+2piUWYa
X-Developer-Key: i=carl.lee@amd.com; a=ed25519;
 pk=pyq7QaQvoxMg806KVkRwpCbiah+7ncWr4MBpK1AEyjA=
X-Endpoint-Received: by B4 Relay for carl.lee@amd.com/20260203 with auth_id=623
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the Monolithic Power Systems MPQ8786 digital voltage
regulator.

Signed-off-by: Carl Lee <carl.lee@amd.com>
---
 Documentation/hwmon/mpq8785.rst | 7 +++++++
 drivers/hwmon/pmbus/mpq8785.c   | 6 +++++-
 2 files changed, 12 insertions(+), 1 deletion(-)

diff --git a/Documentation/hwmon/mpq8785.rst b/Documentation/hwmon/mpq8785.rst
index 198d5dfd7c30..39306033990f 100644
--- a/Documentation/hwmon/mpq8785.rst
+++ b/Documentation/hwmon/mpq8785.rst
@@ -8,6 +8,7 @@ Supported chips:
   * MPS MPM3695 family
   * MPS MPM82504
   * MPS MPQ8785
+  * MPS MPQ8786
 
     Prefix: 'mpq8785'
 
@@ -38,6 +39,12 @@ buck converter. The MPQ8785 offers a very compact solution that achieves up to
 wide input supply range. The MPQ8785 operates at high efficiency over a wide
 output current load range.
 
+The MPQ8786 is a fully integrated, PMBus-compatible, high-frequency, synchronous
+buck converter. The device shares the same PMBus interface and register behavior
+as the MPQ8785, but provides a lower output current capability of up to 25A per
+phase. It offers excellent load and line regulation over a wide input supply
+range and operates at high efficiency over a wide output current load range.
+
 The PMBus interface provides converter configurations and key parameters
 monitoring.
 
diff --git a/drivers/hwmon/pmbus/mpq8785.c b/drivers/hwmon/pmbus/mpq8785.c
index 1f56aaf4dde8..f35534836cb8 100644
--- a/drivers/hwmon/pmbus/mpq8785.c
+++ b/drivers/hwmon/pmbus/mpq8785.c
@@ -12,13 +12,14 @@
 
 #define MPM82504_READ_TEMPERATURE_1_SIGN_POS	9
 
-enum chips { mpm3695, mpm3695_25, mpm82504, mpq8785 };
+enum chips { mpm3695, mpm3695_25, mpm82504, mpq8785, mpq8786 };
 
 static u16 voltage_scale_loop_max_val[] = {
 	[mpm3695] = GENMASK(9, 0),
 	[mpm3695_25] = GENMASK(11, 0),
 	[mpm82504] = GENMASK(9, 0),
 	[mpq8785] = GENMASK(10, 0),
+	[mpq8786] = GENMASK(10, 0),
 };
 
 static int mpq8785_identify(struct i2c_client *client,
@@ -87,6 +88,7 @@ static const struct i2c_device_id mpq8785_id[] = {
 	{ "mpm3695-25", mpm3695_25 },
 	{ "mpm82504", mpm82504 },
 	{ "mpq8785", mpq8785 },
+	{ "mpq8786", mpq8786 },
 	{ },
 };
 MODULE_DEVICE_TABLE(i2c, mpq8785_id);
@@ -96,6 +98,7 @@ static const struct of_device_id __maybe_unused mpq8785_of_match[] = {
 	{ .compatible = "mps,mpm3695-25", .data = (void *)mpm3695_25 },
 	{ .compatible = "mps,mpm82504", .data = (void *)mpm82504 },
 	{ .compatible = "mps,mpq8785", .data = (void *)mpq8785 },
+	{ .compatible = "mps,mpq8786", .data = (void *)mpq8786 },
 	{}
 };
 MODULE_DEVICE_TABLE(of, mpq8785_of_match);
@@ -128,6 +131,7 @@ static int mpq8785_probe(struct i2c_client *client)
 		info->read_word_data = mpm82504_read_word_data;
 		break;
 	case mpq8785:
+	case mpq8786:
 		info->identify = mpq8785_identify;
 		break;
 	default:

-- 
2.34.1

