From: =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
Date: Mon, 25 Nov 2024 23:47:19 +0100
Subject: [PATCH v4 2/3] w1: ds2482: Add regulator support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241125-ds2482-add-reg-v4-2-475a7a08df96@gmail.com>
References: <20241125-ds2482-add-reg-v4-0-475a7a08df96@gmail.com>
In-Reply-To: <20241125-ds2482-add-reg-v4-0-475a7a08df96@gmail.com>
To: Krzysztof Kozlowski <krzk@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Stefan Wahren <stefan.wahren@chargebyte.com>, 
 Stefan Wahren <wahrenst@gmx.net>
Cc: Ben Gardner <bgardner@wabtec.com>, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732574911; l=1153;
 i=cleverline1mc@gmail.com; s=20241112; h=from:subject:message-id;
 bh=ZVLH9FCOXjNMCzUhrLMcjGrb/+QHtd7lqHIOEQnbQ0A=;
 b=NGjcReCZm694x2vbivM2YHW7Pxb0cSlRh98mzsM6xWcMWK+YhwEtRGg7u78/K2fImYvl5cIkT
 1AP025PTO7dC35XJ2fcIu7/SrdTy7z49S/TYgPRVPNUd37pV3HxzkW8
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
index a2ecbb863c57f38bffc8e3cd463db1940e603179..2e5bbe11d8a0cdabd12e89e22537423749e7f9ff 100644
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
@@ -457,6 +459,10 @@ static int ds2482_probe(struct i2c_client *client)
 		goto exit;
 	}
 
+	ret = devm_regulator_get_enable(&client->dev, "vcc");
+	if (ret)
+		return dev_err_probe(&client->dev, ret, "Failed to enable regulator\n");
+
 	data->client = client;
 	i2c_set_clientdata(client, data);
 

-- 
2.39.5

