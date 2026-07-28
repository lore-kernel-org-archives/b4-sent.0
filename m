From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 28 Jul 2026 17:03:48 +0100
Subject: [PATCH 1/5] hwmon: (pmbus/core) fix regulator enable/disable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260728-hwmon-max20826-support-v1-1-224766e0acd1@analog.com>
References: <20260728-hwmon-max20826-support-v1-0-224766e0acd1@analog.com>
In-Reply-To: <20260728-hwmon-max20826-support-v1-0-224766e0acd1@analog.com>
To: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-doc@vger.kernel.org
Cc: Mark Brown <broonie@kernel.org>, 
 Alan Tull <atull@opensource.altera.com>, Guenter Roeck <linux@roeck-us.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785254629; l=1553;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=ZcrZpyTu1G+a3XqNBtj7GJFqxWjd2g2ZSlsiPnCwNoM=;
 b=lxEFSoj5ni7Nfcm6Xf7eH/GKlGXNXmcKWhvXvQ57Mx/c8RnCgf3X6/aHdxnaQo34ircovujFo
 FPmR+Fy1aboCh6zcJkBwJ1vXsF3teG3owOJv79bgL4EDg0vDDlyJZ1W
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pmbus_update_byte_data() can return the value of PMBUS_OPERATION which
can be different than 0 and that can mess with the regulator core
given _regulator_disable() explicitly checks for ret == 0 in order to
call _regulator_handle_consumer_disable().

Fixes: ddbb4db4ced1 ("hwmon: (pmbus) Add regulator support")
Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/hwmon/pmbus/pmbus_core.c | 15 ++++++++++++---
 1 file changed, 12 insertions(+), 3 deletions(-)

diff --git a/drivers/hwmon/pmbus/pmbus_core.c b/drivers/hwmon/pmbus/pmbus_core.c
index 0081f16c3a95..7b58f7198574 100644
--- a/drivers/hwmon/pmbus/pmbus_core.c
+++ b/drivers/hwmon/pmbus/pmbus_core.c
@@ -3100,12 +3100,21 @@ static int _pmbus_regulator_on_off(struct regulator_dev *rdev, bool enable)
 	struct device *dev = rdev_get_dev(rdev);
 	struct i2c_client *client = to_i2c_client(dev->parent);
 	u8 page = rdev_get_id(rdev);
+	int rv;
 
 	guard(pmbus_lock)(client);
+	/*
+	 * pmbus_update_byte_data() can just return the value of
+	 * PMBUS_OPERATION and that's not what we want to return to the
+	 * regulator core.
+	 */
+	rv = pmbus_update_byte_data(client, page, PMBUS_OPERATION,
+				    PB_OPERATION_CONTROL_ON,
+				    enable ? PB_OPERATION_CONTROL_ON : 0);
+	if (rv < 0)
+		return rv;
 
-	return pmbus_update_byte_data(client, page, PMBUS_OPERATION,
-				      PB_OPERATION_CONTROL_ON,
-				      enable ? PB_OPERATION_CONTROL_ON : 0);
+	return 0;
 }
 
 static int pmbus_regulator_enable(struct regulator_dev *rdev)

-- 
2.55.0

