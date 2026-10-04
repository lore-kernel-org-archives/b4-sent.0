From: Igor Velkov <iav@iav.lv>
Date: Sun, 04 Oct 2026 23:56:53 +0000
Subject: [PATCH] rtc: pcf8563: pass the driver data to the alarm interrupt
 handler
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261004-pcf8563-irq-data-v1-1-f176763ddf2f@iav.lv>
X-B4-Tracking: v=1; b=H4sIAMTnwmoC/x3MQQ5AMBBA0avIrE0ySktdRSyKwWyoVkQi7q6xf
 Iv/H4gchCO02QOBL4mybwlFnsG4um1hlCkZFClTEGn049xoU6KEAyd3OjRDRVZZVdeaIGU+8Cz
 3v+z69/0AWucVj2IAAAA=
To: Alexandre Belloni <alexandre.belloni@bootlin.com>
Cc: Nobuhiro Iwamatsu <iwamatsu@nigauri.org>, linux-rtc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1490; i=iav@iav.lv;
 h=from:subject:message-id; bh=pgQ6LIQ51UNGiuJ/Vyx/S0XE1D1zzqJGLztwxvNwcnA=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFmHnp9Q82D8NGOhXbNL47YzUbkzL6xRXPa8bqPbFwXVl
 muHhIQ9OkpZGMS4GGTFFFkmHNK4lbHk6l9/D/MHMHNYmUCGMHBxCsBEIhkY/nBtOrSgZPPPQqWz
 n2KCuu57XNJvm/O7878D296UH5WiAX0M/0P3fN/7zG1D/c/FDvEyuXfivW/x3uI75/tKPcK1VbP
 0HA8A
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pcf8563_irq() takes its dev_id as struct pcf8563, but probe still
registers the interrupt with the i2c client. The handler then takes the
regmap pointer from the wrong structure: the first alarm oopses, the
level-low INT is never acknowledged, and the interrupt gets disabled as
spurious.

Only an RTC that has an interrupt (client->irq > 0) reaches this path.

Fixes: 00f1bb9b8486 ("rtc: pcf8563: Switch to regmap")
Cc: stable@vger.kernel.org
Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested on ODROID-HC4, 7.3-rc5, with the INT line wired to GPIOX_5 in the
device tree: the alarm interrupt fires once, the alarm flag is cleared,
no oops.
---
 drivers/rtc/rtc-pcf8563.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/rtc/rtc-pcf8563.c b/drivers/rtc/rtc-pcf8563.c
index 7eebdb058067..0767331a2cc7 100644
--- a/drivers/rtc/rtc-pcf8563.c
+++ b/drivers/rtc/rtc-pcf8563.c
@@ -531,7 +531,7 @@ static int pcf8563_probe(struct i2c_client *client)
 		err = devm_request_threaded_irq(&client->dev, client->irq,
 				NULL, pcf8563_irq,
 				IRQF_SHARED | IRQF_ONESHOT | irqflags,
-				pcf8563_driver.driver.name, client);
+				pcf8563_driver.driver.name, pcf8563);
 		if (err) {
 			dev_err(&client->dev, "unable to request IRQ %d\n",
 								client->irq);

---
base-commit: 8ef8e9839a23ca7f5dda6a69b670633de5a23716
change-id: 20261005-pcf8563-irq-data-6b4092927750

Best regards,
-- 
Igor Velkov <iav@iav.lv>

