From: =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
Date: Fri, 29 Nov 2024 14:25:54 +0100
Subject: [PATCH v6 2/4] w1: ds2482: switch to devm_kzalloc() from kzalloc()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241129-ds2482-add-reg-v6-2-bd95ad171e19@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732886921; l=2068;
 i=cleverline1mc@gmail.com; s=20241112; h=from:subject:message-id;
 bh=r4HVfq3WAwi6F3AX46+WcwKM8Ii59ByUGgCfyK+yu30=;
 b=BO1ISe0hqX21/wwhWEHRks4IMQalS2BfDfDT/m1Zlt9LHImsYLiXjP9vyEmEaC07XSGyEJ4Tl
 SJYLxUx7CLDDP1obJX0ROf9SjF96MfxWiSImfoFvqHCmh5lvBcUak+Y
X-Developer-Key: i=cleverline1mc@gmail.com; a=ed25519;
 pk=EJoEbw03UiRORQuCiEyNA8gH1Q6fIpEWnn/MyaWOWX0=
X-Endpoint-Received: by B4 Relay for cleverline1mc@gmail.com/20241112 with auth_id=275
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Refactored the driver to devm_kzalloc() from kzalloc(), so the future
driver edits are easier and less error-prone.

Signed-off-by: Kryštof Černý <cleverline1mc@gmail.com>
---
 drivers/w1/masters/ds2482.c | 18 +++++-------------
 1 file changed, 5 insertions(+), 13 deletions(-)

diff --git a/drivers/w1/masters/ds2482.c b/drivers/w1/masters/ds2482.c
index a2ecbb863c57f38bffc8e3cd463db1940e603179..ea09d2ee21ccac27783a19547e988694ca171b91 100644
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
@@ -516,9 +514,6 @@ static int ds2482_probe(struct i2c_client *client)
 		if (data->w1_ch[idx].pdev != NULL)
 			w1_remove_master_device(&data->w1_ch[idx].w1_bm);
 	}
-exit_free:
-	kfree(data);
-exit:
 	return err;
 }
 
@@ -532,9 +527,6 @@ static void ds2482_remove(struct i2c_client *client)
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

