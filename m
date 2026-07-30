From: Vincent Jardin <vjardin@free.fr>
Date: Thu, 30 Jul 2026 17:43:59 +0200
Subject: [PATCH v7 1/4] hwmon: (pmbus/core) export
 pmbus_check_and_notify_faults()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260730-mpq8646_v0-v7-1-e7c7ad768d5d@free.fr>
References: <20260730-mpq8646_v0-v7-0-e7c7ad768d5d@free.fr>
In-Reply-To: <20260730-mpq8646_v0-v7-0-e7c7ad768d5d@free.fr>
To: Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, Charles Hsu <ythsu0511@gmail.com>
Cc: Markus Elfring <Markus.Elfring@web.de>, linux-hwmon@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-doc@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785426244; l=2454;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=5jcbiv8ttuTHSkeFOtZkPoUuH9LONtMGA1eeXSbtKBk=;
 b=FknOLK/iRcBLgKw6ypheqsPLong0cwc/KQt+oSjOqEN3gma9IQhJdbZ4hHr7Crbp/jNhVzTq5
 Gr871dCFnKXABXKopOs7F4q1ZHJnKoqRc4SKRorzOcqj/aTiqD+qkGW
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Factor of pmbus_fault_handler() into an exported helper so
drivers can notify sequence from a polling work item on boards
for which the chip's SMBALERT# pin is not wired to the
CPU. The interrupt handler becomes a thin wrapper.

Like the SMBALERT# path, the helper notifies and then clears the
latched faults unconditionally, so a polling caller inherits exactly
the interrupt semantics.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 drivers/hwmon/pmbus/pmbus.h      |  1 +
 drivers/hwmon/pmbus/pmbus_core.c | 14 +++++++++++---
 2 files changed, 12 insertions(+), 3 deletions(-)

diff --git a/drivers/hwmon/pmbus/pmbus.h b/drivers/hwmon/pmbus/pmbus.h
index 23e3eda58870..1504d8b9e34c 100644
--- a/drivers/hwmon/pmbus/pmbus.h
+++ b/drivers/hwmon/pmbus/pmbus.h
@@ -560,6 +560,7 @@ int pmbus_write_byte_data(struct i2c_client *client, int page, u8 reg,
 int pmbus_update_byte_data(struct i2c_client *client, int page, u8 reg,
 			   u8 mask, u8 value);
 void pmbus_clear_faults(struct i2c_client *client);
+void pmbus_check_and_notify_faults(struct i2c_client *client);
 bool pmbus_check_byte_register(struct i2c_client *client, int page, int reg);
 bool pmbus_check_word_register(struct i2c_client *client, int page, int reg);
 int pmbus_do_probe(struct i2c_client *client, struct pmbus_driver_info *info);
diff --git a/drivers/hwmon/pmbus/pmbus_core.c b/drivers/hwmon/pmbus/pmbus_core.c
index 3143b9e0316c..c52052b30bc8 100644
--- a/drivers/hwmon/pmbus/pmbus_core.c
+++ b/drivers/hwmon/pmbus/pmbus_core.c
@@ -3437,10 +3437,9 @@ static int pmbus_write_smbalert_mask(struct i2c_client *client, u8 page, u8 reg,
 	return ret;
 }
 
-static irqreturn_t pmbus_fault_handler(int irq, void *pdata)
+void pmbus_check_and_notify_faults(struct i2c_client *client)
 {
-	struct pmbus_data *data = pdata;
-	struct i2c_client *client = to_i2c_client(data->dev);
+	struct pmbus_data *data = i2c_get_clientdata(client);
 	int i, status, event;
 
 	guard(pmbus_lock)(client);
@@ -3453,6 +3452,15 @@ static irqreturn_t pmbus_fault_handler(int irq, void *pdata)
 	}
 
 	pmbus_clear_faults(client);
+}
+EXPORT_SYMBOL_NS_GPL(pmbus_check_and_notify_faults, "PMBUS");
+
+static irqreturn_t pmbus_fault_handler(int irq, void *pdata)
+{
+	struct pmbus_data *data = pdata;
+	struct i2c_client *client = to_i2c_client(data->dev);
+
+	pmbus_check_and_notify_faults(client);
 
 	return IRQ_HANDLED;
 }

-- 
2.43.0

