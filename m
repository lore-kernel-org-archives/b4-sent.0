From: Sven Peter <sven@kernel.org>
Date: Sun, 14 Sep 2025 12:56:13 +0000
Subject: [PATCH 08/11] usb: typec: tipd: Update partner identity when power
 status was updated
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250914-apple-usb3-tipd-v1-8-4e99c8649024@kernel.org>
References: <20250914-apple-usb3-tipd-v1-0-4e99c8649024@kernel.org>
In-Reply-To: <20250914-apple-usb3-tipd-v1-0-4e99c8649024@kernel.org>
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Sven Peter <sven@kernel.org>, Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1354; i=sven@kernel.org;
 h=from:subject:message-id; bh=rY6V5NMDdkiVm06hCdoOp7C9X1kzTeKeAD8FlJOwjT0=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ8ax3c1eu7J+1bkbGjw67pdp3510yy7oQaDmhx9GeqvOq
 USX2E/sKGVhEONgkBVTZNm+3970ycM3gks3XXoPM4eVCWQIAxenAEzk2F1Ghkd6Jj1dRwsvHa+8
 cM1X8mDEMltubt2iTYx2LlaiV04aXWNkWNVcX3opq3zTqybJv6r/J3u92WwsqP6nlzdCxGj19l4
 1ZgA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

Whenever the power status is changed make sure to also update the
partner identity to be able to detect changes once de-bouncing and mode
changes are added for CD321x.

Signed-off-by: Hector Martin <marcan@marcan.st>
Reviewed-by: Neal Gompa <neal@gompa.dev>
Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/usb/typec/tipd/core.c | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/drivers/usb/typec/tipd/core.c b/drivers/usb/typec/tipd/core.c
index c7cf936e5a61a331271c05b68ff1b77b89c0f643..e16c6c07c72a3e285f1fc94db72bed8dc3217a1d 100644
--- a/drivers/usb/typec/tipd/core.c
+++ b/drivers/usb/typec/tipd/core.c
@@ -635,9 +635,16 @@ static irqreturn_t cd321x_interrupt(int irq, void *data)
 	if (!tps6598x_read_status(tps, &status))
 		goto err_unlock;
 
-	if (event & APPLE_CD_REG_INT_POWER_STATUS_UPDATE)
+	if (event & APPLE_CD_REG_INT_POWER_STATUS_UPDATE) {
 		if (!tps6598x_read_power_status(tps))
 			goto err_unlock;
+		if (TPS_POWER_STATUS_PWROPMODE(tps->pwr_status) == TYPEC_PWR_MODE_PD) {
+			if (tps6598x_read_partner_identity(tps)) {
+				dev_err(tps->dev, "failed to read partner identity\n");
+				tps->partner_identity = (struct usb_pd_identity) {0};
+			}
+		}
+	}
 
 	if (event & APPLE_CD_REG_INT_DATA_STATUS_UPDATE)
 		if (!tps->data->read_data_status(tps))

-- 
2.34.1

