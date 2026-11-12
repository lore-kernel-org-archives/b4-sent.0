From: Gopi Chandra Sekhar Reddy Kanala <gopi.kanala@oss.qualcomm.com>
Date: Thu, 12 Nov 2026 16:21:52 +0530
Subject: [PATCH] pinctrl: qcom: sm8650-lpass-lpi: Force runtime suspend on
 system sleep
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-lpass-lpi-system-sleep-v1-1-438cb997e0e9@oss.qualcomm.com>
X-B4-Tracking: v=1; b=H4sIAEea9WoC/x2MwQqDMBAFf0X23AWzFUV/pfQQ46suqA1ZkYr47
 w1eBuYwc5IhKYy64qSEXU2/axb3KChMfh3BOmQnKaV2zgnP0ZtlKtthGxa2GYjclKEaRJ6t70E
 5jgkf/d3j1/u6/gOt74poAAAA
To: Bjorn Andersson <andersson@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Linus Walleij <linusw@kernel.org>
Cc: Srinivas Kandagatla <srini@kernel.org>, linux-arm-msm@vger.kernel.org, 
 linux-gpio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Gopi Chandra Sekhar Reddy Kanala <gopi.kanala@oss.qualcomm.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794480716; l=2044;
 i=gopi.kanala@oss.qualcomm.com; s=default; h=from:subject:message-id;
 bh=r/tFuO/5R18QV2K9UWmjTQhhmd3Z+jAD2SllVJ2gGl0=;
 b=gsp1pUcbb9f+clFVSqhF1YyjgD91zk0Us6GKlPmhWdWpT6bQ+oi2FnrohhJXEFNs7iCtESbJI
 Bw5A2sV/IMgALvfTRs+s0IgXc9AA7UyO6cvNzgYQfI1E6Hok2hNwUPB
X-Developer-Key: i=gopi.kanala@oss.qualcomm.com; a=ed25519;
 pk=4bCmbkbT6dfZt13k29qAL6yx8zUQ6p+yOdkRBH8lzXQ=
X-Endpoint-Received: by B4 Relay for gopi.kanala@oss.qualcomm.com/default with auth_id=1499
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The LPASS LPI pin controller votes for the LPASS HW_MACRO and HW_DCODEC
clocks through pm_clk and only implements runtime PM callbacks. Its
consumers, such as the SoundWire controllers, keep it runtime active
through their device links. If a consumer is active when system suspend
starts, or is resumed during it, the runtime PM usage count the PM core
holds from the prepare phase keeps the pin controller from runtime
suspending, and both clock votes are held for the whole suspend. On
Glymur CRD this keeps CX and DDR from collapsing in s2idle.

Use pm_runtime_force_suspend() and pm_runtime_force_resume() as the
system sleep callbacks so the clocks are always released at system
suspend. Consumers are suspended before their suppliers, so the pin
controller goes down after them and comes back before them.

Signed-off-by: Gopi Chandra Sekhar Reddy Kanala <gopi.kanala@oss.qualcomm.com>
---
Tested on Glymur CRD with next-20261110. When s2idle is entered right
after playback, the LPI clock votes are now released during suspend,
after the SoundWire controllers, and restored before them on resume.
Playback works after resume.
---
 drivers/pinctrl/qcom/pinctrl-sm8650-lpass-lpi.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/pinctrl/qcom/pinctrl-sm8650-lpass-lpi.c b/drivers/pinctrl/qcom/pinctrl-sm8650-lpass-lpi.c
index bc7889c993d0..e33d4360c094 100644
--- a/drivers/pinctrl/qcom/pinctrl-sm8650-lpass-lpi.c
+++ b/drivers/pinctrl/qcom/pinctrl-sm8650-lpass-lpi.c
@@ -220,6 +220,7 @@ static const struct of_device_id lpi_pinctrl_of_match[] = {
 MODULE_DEVICE_TABLE(of, lpi_pinctrl_of_match);
 
 static const struct dev_pm_ops lpi_pinctrl_pm_ops = {
+	SYSTEM_SLEEP_PM_OPS(pm_runtime_force_suspend, pm_runtime_force_resume)
 	RUNTIME_PM_OPS(pm_clk_suspend, pm_clk_resume, NULL)
 };
 

---
base-commit: 793807ca13bf3072fc6d16ce6d90e9ab9beff2a5
change-id: 20261112-lpass-lpi-system-sleep-70c4d2239abe

Best regards,
-- 
Gopi Chandra Sekhar Reddy Kanala <gopi.kanala@oss.qualcomm.com>

