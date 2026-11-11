From: Asdlerto Korry <korryasdlerto@gmail.com>
Date: Wed, 11 Nov 2026 17:07:47 +0200
Subject: [PATCH v2 3/4] nfc: s3fwrn5: i2c: Enable the pvdd supply
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-m52xq-dts-v2-3-063289405882@gmail.com>
References: <20261111-m52xq-dts-v2-0-063289405882@gmail.com>
In-Reply-To: <20261111-m52xq-dts-v2-0-063289405882@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>, 
 Krzysztof Kozlowski <krzk@kernel.org>, David Heidelberg <david@ixit.cz>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, oe-linux-nfc@lists.linux.dev, 
 netdev@vger.kernel.org, Asdlerto Korry <korryasdlerto@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794409665; l=1224;
 i=korryasdlerto@gmail.com; s=20261104; h=from:subject:message-id;
 bh=rV79nydgybBLFbM4Kvj9gL9d07PN0WdedvOZm2JSmiw=;
 b=BtLsRrLyFOgwC/N79sWeh9BuLkBoz+XPUKrY/A84mTRALJNVKCA1k+Y808SvBBHt5J9eoROa3
 hOUcCvsw2EmCuGZIVJ+rHgKm4rXq6qO5Q5LKH4Qf18OwXWd0IzXhPNl
X-Developer-Key: i=korryasdlerto@gmail.com; a=ed25519;
 pk=RqttIGkm2XZ8NhLQBzPgpXXawOdVa1uODGsk+sagbxs=
X-Endpoint-Received: by B4 Relay for korryasdlerto@gmail.com/20261104 with auth_id=1411
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Get and enable the optional PVDD supply before the enable GPIO is
driven. Boards that switch this supply from the SoC no longer have to
mark the regulator always-on.

Signed-off-by: Asdlerto Korry <korryasdlerto@gmail.com>
---
 drivers/nfc/s3fwrn5/i2c.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/nfc/s3fwrn5/i2c.c b/drivers/nfc/s3fwrn5/i2c.c
index 4ba762611711..eaa9a1f75533 100644
--- a/drivers/nfc/s3fwrn5/i2c.c
+++ b/drivers/nfc/s3fwrn5/i2c.c
@@ -11,6 +11,7 @@
 #include <linux/gpio/consumer.h>
 #include <linux/delay.h>
 #include <linux/module.h>
+#include <linux/regulator/consumer.h>
 
 #include <net/nfc/nfc.h>
 
@@ -160,6 +161,12 @@ static int s3fwrn5_i2c_probe(struct i2c_client *client)
 	phy->i2c_dev = client;
 	i2c_set_clientdata(client, phy);
 
+	/* The chip has to be powered before EN is driven */
+	ret = devm_regulator_get_enable_optional(&client->dev, "pvdd");
+	if (ret && ret != -ENODEV)
+		return dev_err_probe(&client->dev, ret,
+				     "failed to enable pvdd supply\n");
+
 	phy->common.gpio_en = devm_gpiod_get(&client->dev, "en", GPIOD_OUT_HIGH);
 	if (IS_ERR(phy->common.gpio_en))
 		return PTR_ERR(phy->common.gpio_en);

-- 
2.25.1

