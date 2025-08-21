From: Sven Peter <sven@kernel.org>
Date: Thu, 21 Aug 2025 15:39:08 +0000
Subject: [PATCH RFC 16/22] usb: typec: tipd: Use read_power_status function
 in probe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250821-atcphy-6-17-v1-16-172beda182b8@kernel.org>
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
 Sven Peter <sven@kernel.org>, Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1231; i=sven@kernel.org;
 h=from:subject:message-id; bh=y56aSt+8+GGBv7M4CTBesZmBIVzkBqBitGUe5JAi5T0=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ8Zy2237661DTmzwOHm3mbPDcmX2qgs3eK6999ObE5S38
 /LNpg8xHaUsDGIcDLJiiizb99ubPnn4RnDppkvvYeawMoEMYeDiFICJOGQyMlyaPP+BF4fSZaXg
 QtsbrLFT1izcynz27/T9fp5b1A49TbFi+MMz6W6tkv3fle2n4u5t9l4jtl71vu/lBo8+Ye2uw+x
 +s9kA
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
index b0fdd4dddd3a490dbc2a8ced21ea0803658f36a7..2b7c5017a347d153b50383b34123a2ecc424eb68 100644
--- a/drivers/usb/typec/tipd/core.c
+++ b/drivers/usb/typec/tipd/core.c
@@ -1552,11 +1552,8 @@ static int tps6598x_probe(struct i2c_client *client)
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

