From: Carl Lee <carl.lee@amd.com>
Date: Thu, 05 Feb 2026 18:01:39 +0800
Subject: [PATCH v2 3/3] hwmon: pmbus: mpq8785: force direct mode for VID
 VOUT on MPQ8785/MPQ8786
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260205-dt-bindings-hwmon-pmbus-mpq8785-add-mpq8786-support-v2-3-3744cd9b2850@amd.com>
References: <20260205-dt-bindings-hwmon-pmbus-mpq8785-add-mpq8786-support-v2-0-3744cd9b2850@amd.com>
In-Reply-To: <20260205-dt-bindings-hwmon-pmbus-mpq8785-add-mpq8786-support-v2-0-3744cd9b2850@amd.com>
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Charles Hsu <ythsu0511@gmail.com>
Cc: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, carl.lee@amd.com, peter.shen@amd.com, 
 colin.huang2@amd.com
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770285700; l=1342;
 i=carl.lee@amd.com; s=20260203; h=from:subject:message-id;
 bh=uUNryTHUDVRGoinkT8aURxtPAS6L7bejWtD4269H63g=;
 b=VMo06GX712048wIeOdsmJHxqW1d72ofM4/Su0TefhhhZh/xVTQ+GAhGcD0mngmW/xyROVEt0v
 aEm3zNh7TOVA700szOjV37xENr3f/GOV7qHJT9GV4Z0mIlSBF2u/XAb
X-Developer-Key: i=carl.lee@amd.com; a=ed25519;
 pk=pyq7QaQvoxMg806KVkRwpCbiah+7ncWr4MBpK1AEyjA=
X-Endpoint-Received: by B4 Relay for carl.lee@amd.com/20260203 with auth_id=623
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

According to MPQ8785/MPQ8786 datasheet, VID mode configuration is
the same as direct mode configuration. Therefore, when VOUT is
reported in VID mode, it must be forced to use direct format.

Signed-off-by: Carl Lee <carl.lee@amd.com>
---
 drivers/hwmon/pmbus/mpq8785.c | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)

diff --git a/drivers/hwmon/pmbus/mpq8785.c b/drivers/hwmon/pmbus/mpq8785.c
index f35534836cb8..d6624af076c3 100644
--- a/drivers/hwmon/pmbus/mpq8785.c
+++ b/drivers/hwmon/pmbus/mpq8785.c
@@ -48,6 +48,25 @@ static int mpq8785_identify(struct i2c_client *client,
 	return 0;
 };
 
+static int mpq8785_read_byte_data(struct i2c_client *client, int page, int reg)
+{
+	int ret;
+
+	switch (reg) {
+	case PMBUS_VOUT_MODE:
+		ret = pmbus_read_byte_data(client, page, reg);
+		if (ret < 0)
+			return ret;
+
+		if ((ret >> 5) == 1)
+			return PB_VOUT_MODE_DIRECT;
+	default:
+		return -ENODATA;
+	}
+
+	return ret;
+}
+
 static int mpm82504_read_word_data(struct i2c_client *client, int page,
 				   int phase, int reg)
 {
@@ -133,6 +152,7 @@ static int mpq8785_probe(struct i2c_client *client)
 	case mpq8785:
 	case mpq8786:
 		info->identify = mpq8785_identify;
+		info->read_byte_data = mpq8785_read_byte_data;
 		break;
 	default:
 		return -ENODEV;

-- 
2.34.1

