From: =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
Date: Fri, 29 Nov 2024 14:25:55 +0100
Subject: [PATCH v6 3/4] w1: ds2482: Add regulator support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241129-ds2482-add-reg-v6-3-bd95ad171e19@gmail.com>
References: <20241129-ds2482-add-reg-v6-0-bd95ad171e19@gmail.com>
In-Reply-To: <20241129-ds2482-add-reg-v6-0-bd95ad171e19@gmail.com>
To: Krzysztof Kozlowski <krzk@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Stefan Wahren <stefan.wahren@chargebyte.com>, 
 Stefan Wahren <wahrenst@gmx.net>
Cc: Ben Gardner <bgardner@wabtec.com>, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732886921; l=1167;
 i=cleverline1mc@gmail.com; s=20241112; h=from:subject:message-id;
 bh=ZNdNnRwO64lpwOVc2mLzGiHi0iiUtX2t971DmgjvJRM=;
 b=QtI1fYsd0HQcfegVRNzgWKFIH/6GVtdnErLdTiqOytFf6QWo86DwmMMwqkL1/7syzCM3E4Cru
 LMqydw+d7+SBI4KF4R5RXDjWEHhGYWFr8th4Ux2Ev6k/l+clsPuywgT
X-Developer-Key: i=cleverline1mc@gmail.com; a=ed25519;
 pk=EJoEbw03UiRORQuCiEyNA8gH1Q6fIpEWnn/MyaWOWX0=
X-Endpoint-Received: by B4 Relay for cleverline1mc@gmail.com/20241112 with auth_id=275
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds a support for attaching a supply regulator.

Signed-off-by: Kryštof Černý <cleverline1mc@gmail.com>
---
 drivers/w1/masters/ds2482.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/w1/masters/ds2482.c b/drivers/w1/masters/ds2482.c
index ea09d2ee21ccac27783a19547e988694ca171b91..f8095264d82f0e0135492ed65e71df74c71bcd65 100644
--- a/drivers/w1/masters/ds2482.c
+++ b/drivers/w1/masters/ds2482.c
@@ -15,6 +15,7 @@
 #include <linux/slab.h>
 #include <linux/i2c.h>
 #include <linux/delay.h>
+#include <linux/regulator/consumer.h>
 
 #include <linux/w1.h>
 
@@ -445,6 +446,7 @@ static int ds2482_probe(struct i2c_client *client)
 	int err = -ENODEV;
 	int temp1;
 	int idx;
+	int ret;
 
 	if (!i2c_check_functionality(client->adapter,
 				     I2C_FUNC_SMBUS_WRITE_BYTE_DATA |
@@ -455,6 +457,10 @@ static int ds2482_probe(struct i2c_client *client)
 	if (!data)
 		return -ENOMEM;
 
+	ret = devm_regulator_get_enable(&client->dev, "vcc");
+	if (ret)
+		return dev_err_probe(&client->dev, ret, "Failed to enable regulator\n");
+
 	data->client = client;
 	i2c_set_clientdata(client, data);
 

-- 
2.39.5

