From: Sven Peter <sven@kernel.org>
Date: Sat, 06 Sep 2025 15:43:18 +0000
Subject: [PATCH v2 05/22] usb: typec: tipd: Clear interrupts first
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250906-atcphy-6-17-v2-5-52c348623ef6@kernel.org>
References: <20250906-atcphy-6-17-v2-0-52c348623ef6@kernel.org>
In-Reply-To: <20250906-atcphy-6-17-v2-0-52c348623ef6@kernel.org>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Felipe Balbi <balbi@kernel.org>, 
 Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Neal Gompa <neal@gompa.dev>, Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Frank Li <Frank.Li@nxp.com>, 
 Ran Wang <ran.wang_1@nxp.com>, Peter Chen <peter.chen@nxp.com>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-phy@lists.infradead.org, 
 Sven Peter <sven@kernel.org>, stable@kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3392; i=sven@kernel.org;
 h=from:subject:message-id; bh=15pym0980OuqLrEYjjB149fk5uGZSOarunjihhfaJPQ=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ8aesLm+enUZnyVMG4Lu6VTucDnbnVBV66Aququgf037O
 dFOmWsdpSwMYhwMsmKKLNv325s+efhGcOmmS+9h5rAygQxh4OIUgIloGDAybD0eNiHfe/opE21f
 Xbea/rvM8QvF5vR9WSq7/fp5+ZLJZxn+F816IKz8doNEY/4/9zPfz2dfKuDeo9L/8pt88vaLxxt
 /cwAA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Right now the interrupt handler first reads all updated status registers
and only then clears the interrupts. It's possible that a duplicate
interrupt for a changed register or plug state comes in after the
interrupts have been processed but before they have been cleared:

* plug is inserted, TPS_REG_INT_PLUG_EVENT is set
* TPS_REG_INT_EVENT1 is read
* tps6598x_handle_plug_event() has run and registered the plug
* plug is removed again, TPS_REG_INT_PLUG_EVENT is set (again)
* TPS_REG_INT_CLEAR1 is written, TPS_REG_INT_PLUG_EVENT is cleared

We then have no plug connected and no pending interrupt but the tipd
core still thinks there is a plug. It's possible to trigger this with
e.g. a slightly broken Type-C to USB A converter.

Fix this by first clearing the interrupts and only then reading the
updated registers.

Fixes: 45188f27b3d0 ("usb: typec: tipd: Add support for Apple CD321X")
Fixes: 0a4c005bd171 ("usb: typec: driver for TI TPS6598x USB Power Delivery controllers")
Cc: stable@kernel.org
Reviewed-by: Heikki Krogerus <heikki.krogerus@linux.intel.com>
Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/usb/typec/tipd/core.c | 24 +++++++++++-------------
 1 file changed, 11 insertions(+), 13 deletions(-)

diff --git a/drivers/usb/typec/tipd/core.c b/drivers/usb/typec/tipd/core.c
index dcf141ada07812295a6f07e41d77f95f98116010..1c80296c3b273e24ceacb3feff432c4f6e6835cc 100644
--- a/drivers/usb/typec/tipd/core.c
+++ b/drivers/usb/typec/tipd/core.c
@@ -545,24 +545,23 @@ static irqreturn_t cd321x_interrupt(int irq, void *data)
 	if (!event)
 		goto err_unlock;
 
+	tps6598x_write64(tps, TPS_REG_INT_CLEAR1, event);
+
 	if (!tps6598x_read_status(tps, &status))
-		goto err_clear_ints;
+		goto err_unlock;
 
 	if (event & APPLE_CD_REG_INT_POWER_STATUS_UPDATE)
 		if (!tps6598x_read_power_status(tps))
-			goto err_clear_ints;
+			goto err_unlock;
 
 	if (event & APPLE_CD_REG_INT_DATA_STATUS_UPDATE)
 		if (!tps6598x_read_data_status(tps))
-			goto err_clear_ints;
+			goto err_unlock;
 
 	/* Handle plug insert or removal */
 	if (event & APPLE_CD_REG_INT_PLUG_EVENT)
 		tps6598x_handle_plug_event(tps, status);
 
-err_clear_ints:
-	tps6598x_write64(tps, TPS_REG_INT_CLEAR1, event);
-
 err_unlock:
 	mutex_unlock(&tps->lock);
 
@@ -668,25 +667,24 @@ static irqreturn_t tps6598x_interrupt(int irq, void *data)
 	if (!(event1[0] | event1[1] | event2[0] | event2[1]))
 		goto err_unlock;
 
+	tps6598x_block_write(tps, TPS_REG_INT_CLEAR1, event1, intev_len);
+	tps6598x_block_write(tps, TPS_REG_INT_CLEAR2, event2, intev_len);
+
 	if (!tps6598x_read_status(tps, &status))
-		goto err_clear_ints;
+		goto err_unlock;
 
 	if ((event1[0] | event2[0]) & TPS_REG_INT_POWER_STATUS_UPDATE)
 		if (!tps6598x_read_power_status(tps))
-			goto err_clear_ints;
+			goto err_unlock;
 
 	if ((event1[0] | event2[0]) & TPS_REG_INT_DATA_STATUS_UPDATE)
 		if (!tps6598x_read_data_status(tps))
-			goto err_clear_ints;
+			goto err_unlock;
 
 	/* Handle plug insert or removal */
 	if ((event1[0] | event2[0]) & TPS_REG_INT_PLUG_EVENT)
 		tps6598x_handle_plug_event(tps, status);
 
-err_clear_ints:
-	tps6598x_block_write(tps, TPS_REG_INT_CLEAR1, event1, intev_len);
-	tps6598x_block_write(tps, TPS_REG_INT_CLEAR2, event2, intev_len);
-
 err_unlock:
 	mutex_unlock(&tps->lock);
 

-- 
2.34.1

