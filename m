From: =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
Date: Fri, 15 Nov 2024 15:58:04 +0100
Subject: [PATCH 1/3] w1: ds2482: Add regulator support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241115-ds2482-add-reg-v1-1-cc84b9aba126@gmail.com>
References: <20241115-ds2482-add-reg-v1-0-cc84b9aba126@gmail.com>
In-Reply-To: <20241115-ds2482-add-reg-v1-0-cc84b9aba126@gmail.com>
To: Krzysztof Kozlowski <krzk@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Stefan Wahren <stefan.wahren@chargebyte.com>
Cc: Ben Gardner <bgardner@wabtec.com>, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731682735; l=2045;
 i=cleverline1mc@gmail.com; s=20241112; h=from:subject:message-id;
 bh=/MV/A5HBPIZ49zvbrwPtUxocg+GMGOHnltCMlTjv4CY=;
 b=4ujHrq56di8Z9ZW59yDJ2UvrZ4lzPNxqnEbXmS895tkdASU9WCcP1n0n3U/QdKMRGhqqUTcsz
 Gg/XxT94p41Bf82rGnCO70ssTogKAsM3Puf0QnfLB3mznqItpO7t8VS
X-Developer-Key: i=cleverline1mc@gmail.com; a=ed25519;
 pk=EJoEbw03UiRORQuCiEyNA8gH1Q6fIpEWnn/MyaWOWX0=
X-Endpoint-Received: by B4 Relay for cleverline1mc@gmail.com/20241112 with auth_id=275
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds a support for attaching a supply regulator.

Signed-off-by: Kryštof Černý <cleverline1mc@gmail.com>
---
 drivers/w1/masters/ds2482.c | 21 +++++++++++++++++++++
 1 file changed, 21 insertions(+)

diff --git a/drivers/w1/masters/ds2482.c b/drivers/w1/masters/ds2482.c
index a2ecbb863c57f38bffc8e3cd463db1940e603179..3fb35e92fc1587dc4e609c0061fa5057e0027a80 100644
--- a/drivers/w1/masters/ds2482.c
+++ b/drivers/w1/masters/ds2482.c
@@ -15,6 +15,7 @@
 #include <linux/slab.h>
 #include <linux/i2c.h>
 #include <linux/delay.h>
+#include <linux/regulator/consumer.h>
 
 #include <linux/w1.h>
 
@@ -117,6 +118,9 @@ struct ds2482_data {
 	u8			channel;
 	u8			read_prt;	/* see DS2482_PTR_CODE_xxx */
 	u8			reg_config;
+
+	/* reference to the optional regulator */
+	struct regulator *vcc_reg;
 };
 
 
@@ -445,6 +449,7 @@ static int ds2482_probe(struct i2c_client *client)
 	int err = -ENODEV;
 	int temp1;
 	int idx;
+	int ret;
 
 	if (!i2c_check_functionality(client->adapter,
 				     I2C_FUNC_SMBUS_WRITE_BYTE_DATA |
@@ -457,6 +462,18 @@ static int ds2482_probe(struct i2c_client *client)
 		goto exit;
 	}
 
+	/* Get the vcc regulator */
+	data->vcc_reg = devm_regulator_get(&client->dev, "vcc");
+	if (IS_ERR(data->vcc_reg))
+		return PTR_ERR(data->vcc_reg);
+
+	/* Enable the vcc regulator */
+	ret = regulator_enable(data->vcc_reg);
+	if (ret) {
+		dev_err(&client->dev, "Fail to enable regulator\n");
+		return ret;
+	}
+
 	data->client = client;
 	i2c_set_clientdata(client, data);
 
@@ -517,6 +534,7 @@ static int ds2482_probe(struct i2c_client *client)
 			w1_remove_master_device(&data->w1_ch[idx].w1_bm);
 	}
 exit_free:
+	regulator_disable(data->vcc_reg);
 	kfree(data);
 exit:
 	return err;
@@ -533,6 +551,9 @@ static void ds2482_remove(struct i2c_client *client)
 			w1_remove_master_device(&data->w1_ch[idx].w1_bm);
 	}
 
+	/* Disable the vcc regulator */
+	regulator_disable(data->vcc_reg);
+
 	/* Free the memory */
 	kfree(data);
 }

-- 
2.39.5

