From: Igor Velkov <iav@iav.lv>
Date: Tue, 17 Nov 2026 20:13:03 +0000
Subject: [PATCH] rtc: meson-vrtc: keep the alarm across the hibernation
 snapshot
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-meson-vrtc-thaw-v1-1-b58a2c3919d3@iav.lv>
X-B4-Tracking: v=1; b=H4sIAE61/GoC/x3MQQqAIBBA0avIrBtwggq7SrQQm2oWaahUEN49a
 fkW/7+QOAonGNULkS9JEnwFNQrcbv3GKEs1tLrtiWjAg1PweMXsMO/2Rm2sJmecsR1Drc7Iqzz
 /cZpL+QDTRidsYQAAAA==
To: Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-rtc@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2531; i=iav@iav.lv;
 h=from:subject:message-id; bh=SA/YHiFrtpyx141R9I9mj/voNyRERhsuFPxCUy/+Hlc=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFl/tgYcyVxedunn3MdR+1ew5Nh862Dv8X7Ju+ZICfexS
 VzicnzXOkpZGMS4GGTFFFkmHNK4lbHk6l9/D/MHMHNYmUCGMHBxCsBE8v8zMhzPfWsf7n1ry6d1
 ezY5iXmqHVh4vPzG7tIdus/2Lr1Ue1qOkeHZR7Vi5yjlZvUzcnXHOtvCf0fedb+mPf3kttJivUX
 np7ECAA==
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SIMPLE_DEV_PM_OPS also installs meson_vrtc_resume() as the .thaw
callback, so the alarm is cleared as soon as the hibernation image has
been created. An alarm set through the RTC (rtcwake, wakealarm) is then
lost: with hybrid-sleep the system suspends with a zero wakeup time in
the SCP and does not wake on it. The alarmtimer is not affected, as it
sets the alarm again from its own suspend callback.

Set only the suspend/resume and poweroff/restore callbacks, so freeze
and thaw leave the alarm alone.

Tested on ODROID-HC4 with v7.4-rc3, rtcwake -m no before hybrid-sleep:
BL301 printed alarm=0S before this change and the remaining time with
it, and woke the board on the alarm 3 of 3 times. Waking needs a BL301
that acts on this alarm; the stock one for HC4 does not. Deep suspend
still wakes on the alarm.

Fixes: 6ef35398e827 ("rtc: Add Amlogic Virtual Wake RTC")
Signed-off-by: Igor Velkov <iav@iav.lv>
---
 drivers/rtc/rtc-meson-vrtc.c | 12 ++++++++----
 1 file changed, 8 insertions(+), 4 deletions(-)

diff --git a/drivers/rtc/rtc-meson-vrtc.c b/drivers/rtc/rtc-meson-vrtc.c
index e5f9f05ffee0..f34a98defee6 100644
--- a/drivers/rtc/rtc-meson-vrtc.c
+++ b/drivers/rtc/rtc-meson-vrtc.c
@@ -86,7 +86,7 @@ static int meson_vrtc_probe(struct platform_device *pdev)
 	return devm_rtc_register_device(rtc);
 }
 
-static int __maybe_unused meson_vrtc_suspend(struct device *dev)
+static int meson_vrtc_suspend(struct device *dev)
 {
 	struct meson_vrtc_data *vrtc = dev_get_drvdata(dev);
 
@@ -115,7 +115,7 @@ static int __maybe_unused meson_vrtc_suspend(struct device *dev)
 	return 0;
 }
 
-static int __maybe_unused meson_vrtc_resume(struct device *dev)
+static int meson_vrtc_resume(struct device *dev)
 {
 	struct meson_vrtc_data *vrtc = dev_get_drvdata(dev);
 
@@ -126,8 +126,12 @@ static int __maybe_unused meson_vrtc_resume(struct device *dev)
 	return 0;
 }
 
-static SIMPLE_DEV_PM_OPS(meson_vrtc_pm_ops,
-			 meson_vrtc_suspend, meson_vrtc_resume);
+static const struct dev_pm_ops meson_vrtc_pm_ops = {
+	.suspend = pm_sleep_ptr(meson_vrtc_suspend),
+	.resume = pm_sleep_ptr(meson_vrtc_resume),
+	.poweroff = pm_sleep_ptr(meson_vrtc_suspend),
+	.restore = pm_sleep_ptr(meson_vrtc_resume),
+};
 
 static const struct of_device_id meson_vrtc_dt_match[] = {
 	{ .compatible = "amlogic,meson-vrtc"},

---
base-commit: aebb7274476403040d582c61478df8f4a7bf9cd3
change-id: 20261117-meson-vrtc-thaw-09a01c9c9a5e

Best regards,
-- 
Igor Velkov <iav@iav.lv>

