From: Sven Peter <sven@kernel.org>
Date: Thu, 21 Aug 2025 15:39:07 +0000
Subject: [PATCH RFC 15/22] usb: typec: tipd: Update partner identity when
 power status was updated
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250821-atcphy-6-17-v1-15-172beda182b8@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1322; i=sven@kernel.org;
 h=from:subject:message-id; bh=SCOtQQKEz98UryM3qGwaYKjximp44wDd7gohi1eJ+XI=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ8Zy2y1nI2M8brztf9gRnfXv6vJgse5PZRwtubOYgw41h
 oScnfOlo5SFQYyDQVZMkWX7fnvTJw/fCC7ddOk9zBxWJpAhDFycAjCRc86MDPP2tJ9zlfv9ybJS
 vKlCUTHQxbaVqX5mHIe82ttXgfMXWTD8r9i2tXa3s2bd4rW+WeHaYVc/X5kvvTi6q9yHU/70pKe
 mPAA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

Whenever the power status is changed make sure to also update the
partner identity to be able to detect changes once de-bouncing and mode
changes arre added for CD321x.

Signed-off-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/usb/typec/tipd/core.c | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/drivers/usb/typec/tipd/core.c b/drivers/usb/typec/tipd/core.c
index e369897bfa017ca96e559a8bd70da11207d4513a..b0fdd4dddd3a490dbc2a8ced21ea0803658f36a7 100644
--- a/drivers/usb/typec/tipd/core.c
+++ b/drivers/usb/typec/tipd/core.c
@@ -636,9 +636,16 @@ static irqreturn_t cd321x_interrupt(int irq, void *data)
 	if (!tps6598x_read_status(tps, &status))
 		goto err_unlock;
 
-	if (event & APPLE_CD_REG_INT_POWER_STATUS_UPDATE)
+	if (event & APPLE_CD_REG_INT_POWER_STATUS_UPDATE) {
 		if (!tps6598x_read_power_status(tps))
 			goto err_unlock;
+		if (TPS_POWER_STATUS_PWROPMODE(tps->pwr_status) == TYPEC_PWR_MODE_PD) {
+			if (tps6598x_read_partner_identity(tps)) {
+				dev_err(tps->dev, "%s: failed to partner identity\n", __func__);
+				tps->partner_identity = (struct usb_pd_identity) {0};
+			}
+		}
+	}
 
 	if (event & APPLE_CD_REG_INT_DATA_STATUS_UPDATE)
 		if (!tps->data->read_data_status(tps))

-- 
2.34.1

