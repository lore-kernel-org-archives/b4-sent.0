From: Maud Spierings <maudspierings@gocontroll.com>
Date: Tue, 04 Mar 2025 09:14:52 +0100
Subject: [PATCH] rtc: pcf85063: replace dev_err+return with return
 dev_err_probe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250304-rtc_dev_err_probe-v1-1-9dcc042ad17e@gocontroll.com>
X-B4-Tracking: v=1; b=H4sIAHu2xmcC/x3MSwqAIBRG4a3EHSeYPYi2EiGlv3UnFdeQINp70
 vAbnPNQhDAiDcVDgsSRjz2jKgty27yvUOyzyWjT6lo3Si5nPZKFiD3lWKBm1KbrA1y7eMrdKQh
 8/89xet8PyJCEwmMAAAA=
X-Change-ID: 20250304-rtc_dev_err_probe-ae3268fec5bd
To: Alexandre Belloni <alexandre.belloni@bootlin.com>
Cc: linux-rtc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741076095; l=1241;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=VnpZm7Q0qNGaZ2rAzKlEVmeZ1zL2qmrrgkz2dPyjYtA=;
 b=kEkN5DubV0hXbc/Rb/Q37RueM0FYdCJQ8T58k6QCvyl91+Y26ofOmzP6jihfUGdZPCynKoLGE
 U7IfwmPpvCLC7XNXX2rMnDJMSVB6cUebOplJ9J1WigVeQc2OqSF+6jq
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace the dev_err plus return combo with return dev_err_probe() this
actually communicates the error type when it occurs and helps debugging
hardware issues.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
I had some issues with a pcf85063a this change helped debugging it,
hopefully it can help someone else in the future as well.
---
 drivers/rtc/rtc-pcf85063.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/rtc/rtc-pcf85063.c b/drivers/rtc/rtc-pcf85063.c
index 905986c616559b87826d1102dbc25614f7dcbcbb..650e45876be5e88d96b0ffabaab204168c8d355c 100644
--- a/drivers/rtc/rtc-pcf85063.c
+++ b/drivers/rtc/rtc-pcf85063.c
@@ -591,8 +591,7 @@ static int pcf85063_probe(struct i2c_client *client)
 
 	err = regmap_read(pcf85063->regmap, PCF85063_REG_CTRL1, &tmp);
 	if (err) {
-		dev_err(&client->dev, "RTC chip is not present\n");
-		return err;
+		return dev_err_probe(&client->dev, err, "RTC chip is not present\n");
 	}
 
 	pcf85063->rtc = devm_rtc_allocate_device(&client->dev);

---
base-commit: cd3215bbcb9d4321def93fea6cfad4d5b42b9d1d
change-id: 20250304-rtc_dev_err_probe-ae3268fec5bd

Best regards,
-- 
Maud Spierings <maudspierings@gocontroll.com>

