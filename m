From: Janne Grunau <j@jannau.net>
Date: Sat, 30 Sep 2023 10:19:26 +0200
Subject: [PATCH] watchdog: apple: Deactivate on suspend
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230930-apple-watchdog-suspend-v1-1-1998c0be9fd7@jannau.net>
X-B4-Tracking: v=1; b=H4sIAA3aF2UC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI2MDS2MD3cSCgpxU3fLEkuSMlPx03eLS4oLUvBRd8zRzYwtjQ0Njg7QkJaD
 mgqLUtMwKsMHRsbW1AAVOok1oAAAA
To: Hector Martin <marcan@marcan.st>, Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-watchdog@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Janne Grunau <j@jannau.net>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2007; i=j@jannau.net;
 h=from:subject:message-id; bh=+tQiILihRq5o4N62Yd4BUwts5HYkI5tfzlOjXU3MCSQ=;
 b=owGbwMvMwCG2UNrmdq9+ahrjabUkhlTxW4KTvB7z2UddmJ6rPD/L5aGfgFxyUCR/5qFClbwo+
 YLZpqs7SlkYxDgYZMUUWZK0X3YwrK5RjKl9EAYzh5UJZAgDF6cATOSVPMP/iL75jLdTnDPNFrpY
 iG5aWeomdapyIjufzK5Fr/ZXdZgFMTK89XdY5lUubBX3a7fkvQOJl6cKsiydf2zdvNr8X7cCY1o
 ZAA==
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The watchdog remains active after putting the system into suspend. Add
PM callbacks to deactivate the watchdog on suspend an re-activate it on
resume.

Signed-off-by: Janne Grunau <j@jannau.net>
---
 drivers/watchdog/apple_wdt.c | 25 +++++++++++++++++++++++++
 1 file changed, 25 insertions(+)

diff --git a/drivers/watchdog/apple_wdt.c b/drivers/watchdog/apple_wdt.c
index eddeb0fede89..2167e0ba705e 100644
--- a/drivers/watchdog/apple_wdt.c
+++ b/drivers/watchdog/apple_wdt.c
@@ -173,6 +173,8 @@ static int apple_wdt_probe(struct platform_device *pdev)
 	if (!wdt->clk_rate)
 		return -EINVAL;
 
+	platform_set_drvdata(pdev, wdt);
+
 	wdt->wdd.ops = &apple_wdt_ops;
 	wdt->wdd.info = &apple_wdt_info;
 	wdt->wdd.max_timeout = U32_MAX / wdt->clk_rate;
@@ -190,6 +192,28 @@ static int apple_wdt_probe(struct platform_device *pdev)
 	return devm_watchdog_register_device(dev, &wdt->wdd);
 }
 
+static int __maybe_unused apple_wdt_resume(struct device *dev)
+{
+	struct apple_wdt *wdt = dev_get_drvdata(dev);
+
+	if (watchdog_active(&wdt->wdd) || watchdog_hw_running(&wdt->wdd))
+		apple_wdt_start(&wdt->wdd);
+
+	return 0;
+}
+
+static int __maybe_unused apple_wdt_suspend(struct device *dev)
+{
+	struct apple_wdt *wdt = dev_get_drvdata(dev);
+
+	if (watchdog_active(&wdt->wdd) || watchdog_hw_running(&wdt->wdd))
+		apple_wdt_stop(&wdt->wdd);
+
+	return 0;
+}
+
+static SIMPLE_DEV_PM_OPS(apple_wdt_pm_ops, apple_wdt_suspend, apple_wdt_resume);
+
 static const struct of_device_id apple_wdt_of_match[] = {
 	{ .compatible = "apple,wdt" },
 	{},
@@ -200,6 +224,7 @@ static struct platform_driver apple_wdt_driver = {
 	.driver = {
 		.name = "apple-watchdog",
 		.of_match_table = apple_wdt_of_match,
+		.pm = pm_sleep_ptr(&apple_wdt_pm_ops),
 	},
 	.probe = apple_wdt_probe,
 };

---
base-commit: 0bb80ecc33a8fb5a682236443c1e740d5c917d1d
change-id: 20230930-apple-watchdog-suspend-7f73831130fb

Best regards,
-- 
Janne Grunau <j@jannau.net>

