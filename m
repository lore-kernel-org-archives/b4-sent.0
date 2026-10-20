From: Igor Velkov <iav@iav.lv>
Date: Tue, 20 Oct 2026 20:28:37 +0300
Subject: [PATCH] watchdog: meson_gxbb_wdt: fix suspend/resume handling of
 HW_RUNNING watchdog
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-meson-gxbb-wdt-suspend-v1-1-d5abe4340008@iav.lv>
X-B4-Tracking: v=1; b=H4sIAMSk12oC/x3MPQ6AIAxA4auYzjZBBlCvYhxQqnYQDfWHxHh3i
 eM3vPeAUGQSaIsHIl0svIWMqixgXFyYCdlng1baVEorXEm2gHMaBrz9gXLKTsGj89ZOjTXKuBp
 yvEeaOP3jrn/fD3NgT0FoAAAA
To: Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Philippe Boos <pboos@baylibre.com>, linux-watchdog@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2222; i=iav@iav.lv;
 h=from:subject:message-id; bh=sRv9WsAiYhuKwPOnpeKTfGsN/HKl13MoG+1oyJNF3pA=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFnXl8oFK5/3KmUNFvRYWPXuus1sB4G68vNb+rIWO/n82
 33zHldARykLgxgXg6yYIsuEQxq3MpZc/evvYf4AZg4rE8gQBi5OAZhIjS4jw/40D7UdWeeS+W5E
 vV3I/WNR9qIzLkabjQPjXi7ZnPHtszMjw75lBx9c6Li346oIh0Gi+p2SOFUOyR4Db82VksfSHHN
 /8gAA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

meson_gxbb_wdt_suspend() and meson_gxbb_wdt_resume() only check
watchdog_active(). Since commit 6adbfbab0f03 ("watchdog: meson: keep
running if already active"), probe keeps a watchdog left running by the
bootloader and sets WDOG_HW_RUNNING. If userspace never opens the
device, WDOG_ACTIVE stays clear and the timer is not stopped for system
suspend.

On an ODROID-HC4 (S905X3) whose U-Boot starts the watchdog, with no
userspace owner, the board does not wake from deep suspend
(rtcwake -m mem -s 60) in 2 of 2 attempts and needs a power cycle.

Stop the timer on suspend and restart it on resume also when it is only
running in hardware, as sp805_wdt does. With this change the board
wakes from deep suspend in 4 of 4 attempts, and the kernel pings the
watchdog again after resume.

Fixes: 6adbfbab0f03 ("watchdog: meson: keep running if already active")
Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
The same change as commit 1c81d4a5cda2 ("watchdog: sp805_wdt: fix
suspend/resume handling of HW_RUNNING watchdog") in watchdog-next.
---
 drivers/watchdog/meson_gxbb_wdt.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/watchdog/meson_gxbb_wdt.c b/drivers/watchdog/meson_gxbb_wdt.c
index fb276060e831..fa6953d106ac 100644
--- a/drivers/watchdog/meson_gxbb_wdt.c
+++ b/drivers/watchdog/meson_gxbb_wdt.c
@@ -124,7 +124,8 @@ static int __maybe_unused meson_gxbb_wdt_resume(struct device *dev)
 {
 	struct meson_gxbb_wdt *data = dev_get_drvdata(dev);
 
-	if (watchdog_active(&data->wdt_dev))
+	if (watchdog_active(&data->wdt_dev) ||
+	    watchdog_hw_running(&data->wdt_dev))
 		meson_gxbb_wdt_start(&data->wdt_dev);
 
 	return 0;
@@ -134,7 +135,8 @@ static int __maybe_unused meson_gxbb_wdt_suspend(struct device *dev)
 {
 	struct meson_gxbb_wdt *data = dev_get_drvdata(dev);
 
-	if (watchdog_active(&data->wdt_dev))
+	if (watchdog_active(&data->wdt_dev) ||
+	    watchdog_hw_running(&data->wdt_dev))
 		meson_gxbb_wdt_stop(&data->wdt_dev);
 
 	return 0;

---
base-commit: 6276c8195e598361942082423114877265c17692
change-id: 20261020-meson-gxbb-wdt-suspend-ad77f97606a8

Best regards,
-- 
Igor Velkov <iav@iav.lv>

