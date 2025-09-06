From: Sven Peter <sven@kernel.org>
Date: Sat, 06 Sep 2025 15:43:26 +0000
Subject: [PATCH v2 13/22] usb: typec: tipd: Use read_power_status function
 in probe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250906-atcphy-6-17-v2-13-52c348623ef6@kernel.org>
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
 Sven Peter <sven@kernel.org>, Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1231; i=sven@kernel.org;
 h=from:subject:message-id; bh=a8r41F+GXMooCUu+KjgVBdiu8UWVrFpb7Loq9EHEDqI=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ8aesIV/d0vKnJ/dnraFIay9qvF9XIIp29ULZyyCEpu2G
 5X6hhR3lLIwiHEwyIopsmzfb2/65OEbwaWbLr2HmcPKBDKEgYtTACayOZrhv9NakSfS94v+J8+5
 ErajgbnGc2f2u9PfX8a9/K6t/GXHSmWGv9IPOr6nP56efXPBXW/RpVsfSBtPOXuwN/ffv375ivc
 T5fkB
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

We need the initial power status to be able to reliably detect connector
changes once we introduce de-bouncing for CD321x next. read_power_status
takes care of this and also forwards the status to the trace subsystem
so let's use that instead of open-coding it inside probe.

Signed-off-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/usb/typec/tipd/core.c | 5 +----
 1 file changed, 1 insertion(+), 4 deletions(-)

diff --git a/drivers/usb/typec/tipd/core.c b/drivers/usb/typec/tipd/core.c
index cd427eecd8a594b7e609a20de27a9722055307d8..e6e9730ee6dacd8c1271b1d52a02da49ff248d3e 100644
--- a/drivers/usb/typec/tipd/core.c
+++ b/drivers/usb/typec/tipd/core.c
@@ -1549,11 +1549,8 @@ static int tps6598x_probe(struct i2c_client *client)
 		goto err_role_put;
 
 	if (status & TPS_STATUS_PLUG_PRESENT) {
-		ret = tps6598x_read16(tps, TPS_REG_POWER_STATUS, &tps->pwr_status);
-		if (ret < 0) {
-			dev_err(tps->dev, "failed to read power status: %d\n", ret);
+		if (!tps6598x_read_power_status(tps))
 			goto err_unregister_port;
-		}
 		ret = tps6598x_connect(tps, status);
 		if (ret)
 			dev_err(&client->dev, "failed to register partner\n");

-- 
2.34.1

