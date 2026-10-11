From: Igor Velkov <iav@iav.lv>
Date: Mon, 12 Oct 2026 02:16:58 +0300
Subject: [PATCH] watchdog: orion_wdt: stop the watchdog during system
 suspend
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261012-orion-wdt-suspend-v1-1-1676cb79e29e@iav.lv>
X-B4-Tracking: v=1; b=H4sIAOkYzGoC/x2MywqAIBAAfyX23IJKWPQr0UFyrb1ouL1A+vek4
 8DMFBDKTAJjUyDTxcIpVtBtA8vm4krIvjIYZaxW2mDK1cDbHyin7BQ9qiGY3joXnO6gdnumwM/
 /nOb3/QCPfJWFYwAAAA==
To: Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: linux-watchdog@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2486; i=iav@iav.lv;
 h=from:subject:message-id; bh=I01cscMCOu6Tzd50ZUw7bETh0PaV7/fPLgkbt1myUGw=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFlnJF4Vzjj28OQGnVD39D1Pf32OOOJmI5fKxyfsYBG35
 Y3RP4UvHaUsDGJcDLJiiiwTDmncylhy9a+/h/kDmDmsTCBDGLg4BWAiJhMYGZZM0OLjy4vK8PrK
 qrZqiljWxKkHbk9deX7/BFn+jA/Xo+8zMtxPvbFU1YYnN7pPjOHm2wnh06P60wr2357rLynGc2v
 KFTYA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The watchdog timer keeps counting across system suspend while the
userspace that pings it is frozen, so it expires and resets the system.
On a Kobol Helios4 (Armada 388) with a 60 s timeout the board resets
47-61 s into s2idle, whether the watchdog daemon or systemd's
RuntimeWatchdogSec holds the device.

Stop the timer on suspend and restart it on resume when it is active or
running in hardware, as sp805_wdt does. orion_wdt_start() reloads the
counter, so userspace gets a full timeout after resume.

Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested on a Kobol Helios4 (Armada 388, v7.2.9). Unpatched, the board
resets 60 s into s2idle. With this patch:
- watchdog daemon: three 120 s s2idle cycles, no reset;
- systemd RuntimeWatchdogSec=60s: one 120 s s2idle and one 120 s
  standby cycle, no reset;
- the watchdog still fires after resume: freezing the daemon (SIGSTOP)
  after the s2idle cycles reset the board in 61 s, a panic after
  standby in 54 s.
---
 drivers/watchdog/orion_wdt.c | 24 ++++++++++++++++++++++++
 1 file changed, 24 insertions(+)

diff --git a/drivers/watchdog/orion_wdt.c b/drivers/watchdog/orion_wdt.c
index 5d56e93f0406..0e3d896fe930 100644
--- a/drivers/watchdog/orion_wdt.c
+++ b/drivers/watchdog/orion_wdt.c
@@ -668,6 +668,29 @@ static void orion_wdt_shutdown(struct platform_device *pdev)
 	orion_wdt_stop(wdt_dev);
 }
 
+static int orion_wdt_suspend(struct device *dev)
+{
+	struct watchdog_device *wdt_dev = dev_get_drvdata(dev);
+
+	if (watchdog_active(wdt_dev) || watchdog_hw_running(wdt_dev))
+		return orion_wdt_stop(wdt_dev);
+
+	return 0;
+}
+
+static int orion_wdt_resume(struct device *dev)
+{
+	struct watchdog_device *wdt_dev = dev_get_drvdata(dev);
+
+	if (watchdog_active(wdt_dev) || watchdog_hw_running(wdt_dev))
+		return orion_wdt_start(wdt_dev);
+
+	return 0;
+}
+
+static DEFINE_SIMPLE_DEV_PM_OPS(orion_wdt_pm_ops, orion_wdt_suspend,
+				orion_wdt_resume);
+
 static struct platform_driver orion_wdt_driver = {
 	.probe		= orion_wdt_probe,
 	.remove		= orion_wdt_remove,
@@ -675,6 +698,7 @@ static struct platform_driver orion_wdt_driver = {
 	.driver		= {
 		.name	= "orion_wdt",
 		.of_match_table = orion_wdt_of_match_table,
+		.pm	= pm_sleep_ptr(&orion_wdt_pm_ops),
 	},
 };
 

---
base-commit: 8b5a9f09037e3c372c4e9f2fbda85fcfbf5ea5f0
change-id: 20261012-orion-wdt-suspend-08f276aafa14

Best regards,
-- 
Igor Velkov <iav@iav.lv>

