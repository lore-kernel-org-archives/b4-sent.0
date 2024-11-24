From: =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
Date: Sun, 24 Nov 2024 17:21:35 +0100
Subject: [PATCH v3 1/3] w1: ds2482: Add regulator support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241124-ds2482-add-reg-v3-1-806df39c9454@gmail.com>
References: <20241124-ds2482-add-reg-v3-0-806df39c9454@gmail.com>
In-Reply-To: <20241124-ds2482-add-reg-v3-0-806df39c9454@gmail.com>
To: Krzysztof Kozlowski <krzk@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Stefan Wahren <stefan.wahren@chargebyte.com>
Cc: Ben Gardner <bgardner@wabtec.com>, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732465298; l=1158;
 i=cleverline1mc@gmail.com; s=20241112; h=from:subject:message-id;
 bh=H8N8tauiBMgbKBmqSSTyyRx/4y+QoyyhsjWOzpjAqZ0=;
 b=edK6aOOPZL4NDaAJIKVytq8Qt2/TbTj4o8lvGOE6bIG/3BrM1zzFc2py3zp/wuHSWnDKVNetQ
 9U69XAbyQf4BJFzcLr5RyZHDcRyeGIIiTOvYHc0D8zBKFamPrZFpg2h
X-Developer-Key: i=cleverline1mc@gmail.com; a=ed25519;
 pk=EJoEbw03UiRORQuCiEyNA8gH1Q6fIpEWnn/MyaWOWX0=
X-Endpoint-Received: by B4 Relay for cleverline1mc@gmail.com/20241112 with auth_id=275
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds a support for attaching a supply regulator.

Signed-off-by: Kryštof Černý <cleverline1mc@gmail.com>
---
 drivers/w1/masters/ds2482.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/w1/masters/ds2482.c b/drivers/w1/masters/ds2482.c
index a2ecbb863c57f38bffc8e3cd463db1940e603179..4cb05d00cb6743abc5699583f591ef9b5339b44e 100644
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
@@ -457,6 +459,12 @@ static int ds2482_probe(struct i2c_client *client)
 		goto exit;
 	}
 
+	ret = devm_regulator_get_enable(&client->dev, "vcc");
+	if (ret) {
+		dev_err(&client->dev, "Fail to enable regulator\n");
+		return ret;
+	}
+
 	data->client = client;
 	i2c_set_clientdata(client, data);
 

-- 
2.39.5

