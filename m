From: Gopi Chandra Sekhar Reddy Kanala <gopi.kanala@oss.qualcomm.com>
Date: Thu, 12 Nov 2026 16:17:42 +0530
Subject: [PATCH] soundwire: qcom: force runtime suspend across system sleep
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-qcom-swr-system-sleep-v1-1-a61a83f6475d@oss.qualcomm.com>
X-B4-Tracking: v=1; b=H4sIAE2Z9WoC/x2MSwqDQBAFryK9ToM9DIJeJWRhxqc2+J0OfhDv7
 pBd1aLqIkNUGFXZRRGbms5TEnllFPp66sDaJCeXu0JEHK9hHtn2yHbaDwkHYGF4J943RYnwpdQ
 uEa0e/+/7c98Pjrm7s2cAAAA=
To: Srinivas Kandagatla <srini@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Bard Liao <yung-chuan.liao@linux.intel.com>, 
 Pierre-Louis Bossart <pierre-louis.bossart@linux.dev>
Cc: linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Gopi Chandra Sekhar Reddy Kanala <gopi.kanala@oss.qualcomm.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794480478; l=2222;
 i=gopi.kanala@oss.qualcomm.com; s=default; h=from:subject:message-id;
 bh=PuQRJiq95loOQNMnfaO3Q8ngHy49cFz9em3LNzvhvDU=;
 b=KOc2VRthYaO2bun1MamwCsbJdgIeg4y9kZf9evD3HS8vfA2KlKz14lKS9JjT8zJmkmkL/h5AG
 CTPp69Lf6QyDFnhROwDofNz8IkKZ20XkJsQscEBSqM5dowRWzaLjHEk
X-Developer-Key: i=gopi.kanala@oss.qualcomm.com; a=ed25519;
 pk=4bCmbkbT6dfZt13k29qAL6yx8zUQ6p+yOdkRBH8lzXQ=
X-Endpoint-Received: by B4 Relay for gopi.kanala@oss.qualcomm.com/default with auth_id=1499
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The controller only implements runtime PM callbacks and relies on
runtime suspend to stop the bus clock, gate hclk and arm the wake IRQ.
That is not enough across system suspend: from the prepare phase until
the complete phase the PM core holds a runtime PM usage count on every
device, so a controller that is runtime active at that point stays
active until the system resumes. This happens when suspend is entered
within the 3 second autosuspend delay after bus activity, or when a
peripheral driver resumes its device from its own system suspend
callback, as the SDCA class function driver does to quiesce its
interrupts.

The bus clock then keeps running and hclk stays enabled for the whole
suspend. On Qualcomm platforms the LPASS clock votes behind it are held
as well, which keeps CX and DDR from collapsing in s2idle.

Use pm_runtime_force_suspend() and pm_runtime_force_resume() as the
system sleep callbacks, so the runtime suspend path always runs at
system suspend and is undone on resume. Peripherals are children of the
bus, so they are suspended before the controller and resumed after it.

Signed-off-by: Gopi Chandra Sekhar Reddy Kanala <gopi.kanala@oss.qualcomm.com>
---
Tested on Glymur CRD (WSA884x speakers on two controllers) with
next-20261110. When s2idle is entered within the autosuspend delay
after playback, both controllers now stop the bus clock and gate hclk
during suspend, and playback works after resume.
---
 drivers/soundwire/qcom.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/soundwire/qcom.c b/drivers/soundwire/qcom.c
index a4cb62897192..6884ddbe69b3 100644
--- a/drivers/soundwire/qcom.c
+++ b/drivers/soundwire/qcom.c
@@ -1902,6 +1902,7 @@ static int __maybe_unused swrm_runtime_suspend(struct device *dev)
 }
 
 static const struct dev_pm_ops swrm_dev_pm_ops = {
+	SET_SYSTEM_SLEEP_PM_OPS(pm_runtime_force_suspend, pm_runtime_force_resume)
 	SET_RUNTIME_PM_OPS(swrm_runtime_suspend, swrm_runtime_resume, NULL)
 };
 

---
base-commit: 793807ca13bf3072fc6d16ce6d90e9ab9beff2a5
change-id: 20261112-qcom-swr-system-sleep-e42144d69ecb

Best regards,
-- 
Gopi Chandra Sekhar Reddy Kanala <gopi.kanala@oss.qualcomm.com>

