From: Abdurrahman Hussain <abdurrahman@nexthop.ai>
Date: Fri, 08 May 2026 16:33:19 -0700
Subject: [PATCH 7/7] hwmon: (pmbus/adm1266) include adapter number in GPIO
 line label
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260508-adm1266-v1-7-ec08bf29e0ce@nexthop.ai>
References: <20260508-adm1266-v1-0-ec08bf29e0ce@nexthop.ai>
In-Reply-To: <20260508-adm1266-v1-0-ec08bf29e0ce@nexthop.ai>
To: Guenter Roeck <linux@roeck-us.net>, 
 Alexandru Tachici <alexandru.tachici@analog.com>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Abdurrahman Hussain <abdurrahman@nexthop.ai>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1311;
 i=abdurrahman@nexthop.ai; h=from:subject:message-id;
 bh=+gb9rQVuX3txw2uuwV5b1v1Re6m0IUjLCe0dbdU21mk=;
 b=owJ4nJvAy8zAJbYltPXv6rsCXxhPqyUxZP4rOpIisG5KOtceX/+PzKf3yb98/M5V7adgQ6TPH
 aloAcH9V1M6SlkYxLgYZMUUWeY88n/T1tEWsSHmkD3MHFYmkCEMXJwCMJEsM4a/cls61kWyZN3Y
 lbm7yP9YgSGDuPdsHlfdnaGrirR3PhI5w/C/8tDCCXubz3z+2Lrn+860H5+6RWdZMC/XKHqf1mp
 2eIMtAwA9C1Bp
X-Developer-Key: i=abdurrahman@nexthop.ai; a=openpgp;
 fpr=9CE24FEC86888658B05CC23FB45585FDABDD10F4
X-Endpoint-Received: by B4 Relay for abdurrahman@nexthop.ai/default with auth_id=756
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Platforms that fit more than one ADM1266 on different I2C buses at
the same 7-bit slave address (a common shelf-management pattern,
e.g. one device per power domain) end up with duplicate GPIO line
labels because the existing format only includes the slave address.
Including the adapter number disambiguates them.

The label is purely informational (visible via gpioinfo and the
gpiochip /sys/class/gpio name); no DT or ABI consumer parses it.

Signed-off-by: Abdurrahman Hussain <abdurrahman@nexthop.ai>
---
 drivers/hwmon/pmbus/adm1266.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/drivers/hwmon/pmbus/adm1266.c b/drivers/hwmon/pmbus/adm1266.c
index 07c20746f083..ec6a2c9167d8 100644
--- a/drivers/hwmon/pmbus/adm1266.c
+++ b/drivers/hwmon/pmbus/adm1266.c
@@ -293,8 +293,9 @@ static int adm1266_config_gpio(struct adm1266_data *data)
 	int i;
 
 	for (i = 0; i < ARRAY_SIZE(data->gpio_names); i++) {
-		gpio_name = devm_kasprintf(&data->client->dev, GFP_KERNEL, "adm1266-%x-%s",
-					   data->client->addr, adm1266_names[i]);
+		gpio_name = devm_kasprintf(&data->client->dev, GFP_KERNEL, "adm1266-%x-%x-%s",
+					   data->client->adapter->nr, data->client->addr,
+					   adm1266_names[i]);
 		if (!gpio_name)
 			return -ENOMEM;
 

-- 
2.53.0

