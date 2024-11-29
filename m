From: =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
Date: Fri, 29 Nov 2024 10:53:17 +0100
Subject: [PATCH v5 2/4] w1: ds2482: switch to devm_kzalloc() from kzalloc()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241129-ds2482-add-reg-v5-2-af8e83d41344@gmail.com>
References: <20241129-ds2482-add-reg-v5-0-af8e83d41344@gmail.com>
In-Reply-To: <20241129-ds2482-add-reg-v5-0-af8e83d41344@gmail.com>
To: Krzysztof Kozlowski <krzk@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Stefan Wahren <stefan.wahren@chargebyte.com>, 
 Stefan Wahren <wahrenst@gmx.net>
Cc: Ben Gardner <bgardner@wabtec.com>, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732874180; l=2540;
 i=cleverline1mc@gmail.com; s=20241112; h=from:subject:message-id;
 bh=85jsX+YFwJTBnGA69duIqiPwKPoBcjMjdnBr1eB0RA0=;
 b=W1Q+FumymcH5SQxo82c1E+HTh5Wsh5iywz+Op1fle7O7B9Xd4f4g+fEJ98G1yTac3HZXZ+Ld1
 8qGOjJ2MHzoCWO6ZOM+eOIJwCc+4uTN/qLZ/afnVZT8pkoQz2hhA5zu
X-Developer-Key: i=cleverline1mc@gmail.com; a=ed25519;
 pk=EJoEbw03UiRORQuCiEyNA8gH1Q6fIpEWnn/MyaWOWX0=
X-Endpoint-Received: by B4 Relay for cleverline1mc@gmail.com/20241112 with auth_id=275
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Refactored the driver to devm_kzalloc() from kzalloc(), so the future
driver edits are easier and less error-prone.

Signed-off-by: Kryštof Černý <cleverline1mc@gmail.com>
---
 drivers/w1/masters/ds2482.c | 31 ++++++++++---------------------
 1 file changed, 10 insertions(+), 21 deletions(-)

diff --git a/drivers/w1/masters/ds2482.c b/drivers/w1/masters/ds2482.c
index a2ecbb863c57f38bffc8e3cd463db1940e603179..b2157869067d52f79d618e163b6cd96dbc7bee60 100644
--- a/drivers/w1/masters/ds2482.c
+++ b/drivers/w1/masters/ds2482.c
@@ -451,11 +451,9 @@ static int ds2482_probe(struct i2c_client *client)
 				     I2C_FUNC_SMBUS_BYTE))
 		return -ENODEV;
 
-	data = kzalloc(sizeof(struct ds2482_data), GFP_KERNEL);
-	if (!data) {
-		err = -ENOMEM;
-		goto exit;
-	}
+	data = devm_kzalloc(&client->dev, sizeof(struct ds2482_data), GFP_KERNEL);
+	if (!data)
+		return -ENOMEM;
 
 	data->client = client;
 	i2c_set_clientdata(client, data);
@@ -463,7 +461,7 @@ static int ds2482_probe(struct i2c_client *client)
 	/* Reset the device (sets the read_ptr to status) */
 	if (ds2482_send_cmd(data, DS2482_CMD_RESET) < 0) {
 		dev_warn(&client->dev, "DS2482 reset failed.\n");
-		goto exit_free;
+		return err;
 	}
 
 	/* Sleep at least 525ns to allow the reset to complete */
@@ -474,7 +472,7 @@ static int ds2482_probe(struct i2c_client *client)
 	if (temp1 != (DS2482_REG_STS_LL | DS2482_REG_STS_RST)) {
 		dev_warn(&client->dev, "DS2482 reset status "
 			 "0x%02X - not a DS2482\n", temp1);
-		goto exit_free;
+		return err;
 	}
 
 	/* Detect the 8-port version */
@@ -505,21 +503,15 @@ static int ds2482_probe(struct i2c_client *client)
 		err = w1_add_master_device(&data->w1_ch[idx].w1_bm);
 		if (err) {
 			data->w1_ch[idx].pdev = NULL;
-			goto exit_w1_remove;
+			for (idx = 0; idx < data->w1_count; idx++) {
+				if (data->w1_ch[idx].pdev != NULL)
+					w1_remove_master_device(&data->w1_ch[idx].w1_bm);
+			}
+			return err;
 		}
 	}
 
 	return 0;
-
-exit_w1_remove:
-	for (idx = 0; idx < data->w1_count; idx++) {
-		if (data->w1_ch[idx].pdev != NULL)
-			w1_remove_master_device(&data->w1_ch[idx].w1_bm);
-	}
-exit_free:
-	kfree(data);
-exit:
-	return err;
 }
 
 static void ds2482_remove(struct i2c_client *client)
@@ -532,9 +524,6 @@ static void ds2482_remove(struct i2c_client *client)
 		if (data->w1_ch[idx].pdev != NULL)
 			w1_remove_master_device(&data->w1_ch[idx].w1_bm);
 	}
-
-	/* Free the memory */
-	kfree(data);
 }
 
 /*

-- 
2.39.5

