From: Nathan Lynch <nathan.lynch@amd.com>
Date: Thu, 03 Apr 2025 11:24:19 -0500
Subject: [PATCH] Revert "dmaengine: dmatest: Fix dmatest waiting less when
 interrupted"
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250403-dmaengine-dmatest-revert-waiting-less-v1-1-8227c5a3d7c8@amd.com>
X-B4-Tracking: v=1; b=H4sIADK27mcC/x2NQQrCMBBFr1Jm7cC0qQW9irgIzTcO6CiZUIXSu
 xu7e2/x/l/JURRO526lgkVdX9akP3Q036NlsKbmNMhwlFECp2eEZTX8qcIrtwyl8idqVcv8gDt
 HmaZwSpL6OVDbehfc9Lv/XK7b9gNUZ22YdwAAAA==
X-Change-ID: 20250403-dmaengine-dmatest-revert-waiting-less-a06639d0d1c3
To: Vinod Koul <vkoul@kernel.org>, Dave Jiang <dave.jiang@intel.com>, 
 Vinicius Costa Gomes <vinicius.gomes@intel.com>
Cc: dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nathan Lynch <nathan.lynch@amd.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1743697473; l=1742;
 i=nathan.lynch@amd.com; s=20241010; h=from:subject:message-id;
 bh=Rc7Qs86ICgVAk71Y+cZz9vWqynj5i2cRse2Xp/Ofc2A=;
 b=P/YaHgve0A48XRJovDouoH5dpci4+Zxe86GQH8kuKzUDVnHgw8+8THPwPx/NkTI33Vhkw7ULV
 lsd9JmmHN/vBthrO0kvGH/pTK65GUuNyfIVxqAyLmDTyZxddgO/ydDA
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=ZR637UTGg5YLDj56cxFeHdYoUjPMMFbcijfOkAmAnbc=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20241010 with auth_id=241
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Several issues with this change:

* The analysis is flawed and it's unclear what problem is being
  fixed. There is no difference between wait_event_freezable_timeout()
  and wait_event_timeout() with respect to device interrupts. And of
  course "the interrupt notifying the finish of an operation happens
  during wait_event_freezable_timeout()" -- that's how it's supposed
  to work.

* The link at the "Closes:" tag appears to be an unrelated
  use-after-free in idxd.

* It introduces a regression: dmatest threads are meant to be
  freezable and this change breaks that.

See discussion here:
https://lore.kernel.org/dmaengine/878qpa13fe.fsf@AUSNATLYNCH.amd.com/

Fixes: e87ca16e9911 ("dmaengine: dmatest: Fix dmatest waiting less when interrupted")
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/dmatest.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/dma/dmatest.c b/drivers/dma/dmatest.c
index d891dfca358e209c9a5c2d8b49e3e539130e53e8..91b2fbc0b8647127c7753669fa21c84d300764b9 100644
--- a/drivers/dma/dmatest.c
+++ b/drivers/dma/dmatest.c
@@ -841,9 +841,9 @@ static int dmatest_func(void *data)
 		} else {
 			dma_async_issue_pending(chan);
 
-			wait_event_timeout(thread->done_wait,
-					   done->done,
-					   msecs_to_jiffies(params->timeout));
+			wait_event_freezable_timeout(thread->done_wait,
+					done->done,
+					msecs_to_jiffies(params->timeout));
 
 			status = dma_async_is_tx_complete(chan, cookie, NULL,
 							  NULL);

---
base-commit: 6565439894570a07b00dba0b739729fe6b56fba4
change-id: 20250403-dmaengine-dmatest-revert-waiting-less-a06639d0d1c3

Best regards,
-- 
Nathan Lynch <nathan.lynch@amd.com>

