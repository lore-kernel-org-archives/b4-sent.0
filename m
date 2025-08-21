From: Sven Peter <sven@kernel.org>
Date: Thu, 21 Aug 2025 15:39:01 +0000
Subject: [PATCH RFC 09/22] usb: typec: tipd: Move initial irq mask to
 tipd_data
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250821-atcphy-6-17-v1-9-172beda182b8@kernel.org>
References: <20250821-atcphy-6-17-v1-0-172beda182b8@kernel.org>
In-Reply-To: <20250821-atcphy-6-17-v1-0-172beda182b8@kernel.org>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Felipe Balbi <balbi@kernel.org>, 
 Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Neal Gompa <neal@gompa.dev>, Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-phy@lists.infradead.org, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3168; i=sven@kernel.org;
 h=from:subject:message-id; bh=eKL7OgN/DvasHSMHY1JVLFsa5OJf2n5Y1v/SsiTf9mc=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ8Zy29X37j8tXW0dVX/4fuKD1QwXrzTmbLzzSqfre/7cg
 ANRd7KLOkpZGMQ4GGTFFFm277c3ffLwjeDSTZfew8xhZQIZwsDFKQAT+WXMyPDlg+aeFWmbFnVG
 VHzKC/6to/fT4O6yrr6O3/yLxauu3w1j+CvEr+Aj/2KZ2tLtriqpZ9n6f6mfi3gnvSNV+u7/tPO
 +CewA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since the irq mask was originally added more tipd variants have been
introduced and there's now struct tipd_data. Move the initial mask in
there.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/usb/typec/tipd/core.c | 23 +++++++++++------------
 1 file changed, 11 insertions(+), 12 deletions(-)

diff --git a/drivers/usb/typec/tipd/core.c b/drivers/usb/typec/tipd/core.c
index 1c80296c3b273e24ceacb3feff432c4f6e6835cc..6d8bcbc9cad8a1394e066504d4c5ca570edd4e4f 100644
--- a/drivers/usb/typec/tipd/core.c
+++ b/drivers/usb/typec/tipd/core.c
@@ -112,6 +112,7 @@ struct tps6598x;
 
 struct tipd_data {
 	irq_handler_t irq_handler;
+	u64 irq_mask1;
 	int (*register_port)(struct tps6598x *tps, struct fwnode_handle *node);
 	void (*trace_power_status)(u16 status);
 	void (*trace_status)(u32 status);
@@ -1298,7 +1299,6 @@ static int tps6598x_probe(struct i2c_client *client)
 	u32 status;
 	u32 vid;
 	int ret;
-	u64 mask1;
 
 	tps = devm_kzalloc(&client->dev, sizeof(*tps), GFP_KERNEL);
 	if (!tps)
@@ -1337,16 +1337,6 @@ static int tps6598x_probe(struct i2c_client *client)
 		if (ret)
 			return ret;
 
-		/* CD321X chips have all interrupts masked initially */
-		mask1 = APPLE_CD_REG_INT_POWER_STATUS_UPDATE |
-			APPLE_CD_REG_INT_DATA_STATUS_UPDATE |
-			APPLE_CD_REG_INT_PLUG_EVENT;
-
-	} else {
-		/* Enable power status, data status and plug event interrupts */
-		mask1 = TPS_REG_INT_POWER_STATUS_UPDATE |
-			TPS_REG_INT_DATA_STATUS_UPDATE |
-			TPS_REG_INT_PLUG_EVENT;
 	}
 
 	tps->data = i2c_get_match_data(client);
@@ -1364,7 +1354,7 @@ static int tps6598x_probe(struct i2c_client *client)
 			return ret;
 	}
 
-	ret = tps6598x_write64(tps, TPS_REG_INT_MASK1, mask1);
+	ret = tps6598x_write64(tps, TPS_REG_INT_MASK1, tps->data->irq_mask1);
 	if (ret)
 		goto err_reset_controller;
 
@@ -1527,6 +1517,9 @@ static const struct dev_pm_ops tps6598x_pm_ops = {
 
 static const struct tipd_data cd321x_data = {
 	.irq_handler = cd321x_interrupt,
+	.irq_mask1 = APPLE_CD_REG_INT_POWER_STATUS_UPDATE |
+		     APPLE_CD_REG_INT_DATA_STATUS_UPDATE |
+		     APPLE_CD_REG_INT_PLUG_EVENT,
 	.register_port = tps6598x_register_port,
 	.trace_power_status = trace_tps6598x_power_status,
 	.trace_status = trace_tps6598x_status,
@@ -1536,6 +1529,9 @@ static const struct tipd_data cd321x_data = {
 
 static const struct tipd_data tps6598x_data = {
 	.irq_handler = tps6598x_interrupt,
+	.irq_mask1 = TPS_REG_INT_POWER_STATUS_UPDATE |
+		     TPS_REG_INT_DATA_STATUS_UPDATE |
+		     TPS_REG_INT_PLUG_EVENT,
 	.register_port = tps6598x_register_port,
 	.trace_power_status = trace_tps6598x_power_status,
 	.trace_status = trace_tps6598x_status,
@@ -1546,6 +1542,9 @@ static const struct tipd_data tps6598x_data = {
 
 static const struct tipd_data tps25750_data = {
 	.irq_handler = tps25750_interrupt,
+	.irq_mask1 = TPS_REG_INT_POWER_STATUS_UPDATE |
+		     TPS_REG_INT_DATA_STATUS_UPDATE |
+		     TPS_REG_INT_PLUG_EVENT,
 	.register_port = tps25750_register_port,
 	.trace_power_status = trace_tps25750_power_status,
 	.trace_status = trace_tps25750_status,

-- 
2.34.1

