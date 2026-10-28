From: =?utf-8?q?Krzysztof_Soko=C5=82owski?= <krzysiek.sokolowski@gmail.com>
Date: Wed, 28 Oct 2026 12:28:11 +0100
Subject: [PATCH] dmaengine: pl330: drop only the runtime PM reference a
 channel holds
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261028-pl330-runtime-pm-v1-1-f0fb5c34a7c4@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/y2Nyw7CIBQFf6VhLcnl3forpgugF8XYh0CNSdN/F
 63LSebM2UjGFDGTc7ORhK+Y4zxVYKeG+JudrkjjUJlw4JoBb+nyEAJoWqcSR6TLSJ2yAkCB40G
 ROlsShvj+JS/9wXl1d/Tl2/kbCZ9r/SqHRpzNSP08jrGcGxuCQm2NCV531njZAZdaatVJGFgrO
 R+M14KRft8/xOgpXMAAAAA=
X-Change-ID: 20261028-pl330-runtime-pm-b5a30050b2f5
To: Vinod Koul <vkoul@kernel.org>
Cc: Frank Li <Frank.Li@kernel.org>, dmaengine@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 =?utf-8?q?Krzysztof_Soko=C5=82owski?= <krzysiek.sokolowski@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793186892; l=2072;
 i=krzysiek.sokolowski@gmail.com; s=20261028; h=from:subject:message-id;
 bh=N0Dj51bhXIkS3BDw3/lGRjrwPEjdmvZxsqfqjpdUcCU=;
 b=ehlD/UbuZSYLlj0k3N8mtTulGuMalewB+pRQnS63Q3pr8M5a7lbCppFfroC6Kq/aGDjJJK1ee
 1uDkG+C2TppBmzIO7uFxRQQuHlqX9L2yt4eiW5LwDi6NBGvo/2IN8LI
X-Developer-Key: i=krzysiek.sokolowski@gmail.com; a=ed25519;
 pk=qeeCHf+lXP5Q+6LakjbiVVxxcDVYb7Op1WMfhoaK2T0=
X-Endpoint-Received: by B4 Relay for krzysiek.sokolowski@gmail.com/20261028 with auth_id=1343
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pl330_tasklet() drops a runtime PM reference when the channel's work
list is empty, without checking that the channel still holds one.
pl330_terminate_all() drops that reference too (power_down =
pch->active) and clears pch->active. If a completion schedules the
tasklet and a client terminates the channel before the tasklet runs, the
tasklet finds an empty work list and drops the reference a second time:

  Runtime PM usage count underflow!

after which the controller can be runtime suspended while still in use.

Seen on an RK3128 board (dw_mmc using the PL330 for SD transfers) under
combined SD and USB load, where the dw_mmc error path terminates the
channel; the underflow was followed by "pl330_update:1678 Unexpected!"
and a failure to request the DMA channel again.

Take power_down from pch->active in the tasklet, as pl330_terminate_all()
does, so the reference taken in pl330_issue_pending() is dropped once.

Fixes: 5c9e6c2b2ba3 ("dmaengine: pl330: Fix runtime PM support for terminated transfers")
Cc: stable@vger.kernel.org
Signed-off-by: Krzysztof Sokołowski <krzysiek.sokolowski@gmail.com>
---
 drivers/dma/pl330.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/dma/pl330.c b/drivers/dma/pl330.c
index c2d0b47..b0eced8 100644
--- a/drivers/dma/pl330.c
+++ b/drivers/dma/pl330.c
@@ -2090,7 +2090,12 @@ static void pl330_tasklet(struct tasklet_struct *t)
 		spin_lock(&pch->thread->dmac->lock);
 		_stop(pch->thread);
 		spin_unlock(&pch->thread->dmac->lock);
-		power_down = true;
+		/*
+		 * Drop the runtime PM reference only if this channel still
+		 * holds it: pl330_terminate_all() may already have dropped it
+		 * while this tasklet was scheduled.
+		 */
+		power_down = pch->active;
 		pch->active = false;
 	} else {
 		/* Make sure the PL330 Channel thread is active */

---
base-commit: aff5e6a77fc69a7c490246465940d18422d7c631
change-id: 20261028-pl330-runtime-pm-b5a30050b2f5

Best regards,
--  
Krzysztof Sokołowski <krzysiek.sokolowski@gmail.com>

