From: Nathan Lynch <nathan.lynch@amd.com>
Date: Wed, 22 Jul 2026 10:47:46 -0500
Subject: [PATCH 1/4] dmaengine: dmatest: Don't forcibly terminate channel
 in polled mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260722-dmatest-fixes-and-fatal-errors-v1-1-8287709987ea@amd.com>
References: <20260722-dmatest-fixes-and-fatal-errors-v1-0-8287709987ea@amd.com>
In-Reply-To: <20260722-dmatest-fixes-and-fatal-errors-v1-0-8287709987ea@amd.com>
To: Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>
Cc: Tycho Andersen <tycho@kernel.org>, Wei Huang <wei.huang2@amd.com>, 
 dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nathan Lynch <nathan.lynch@amd.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784735280; l=1508;
 i=nathan.lynch@amd.com; s=20260722; h=from:subject:message-id;
 bh=bgtcSNqMScacYr65kuIB7nzRdUTetKq2Oy8oDO2rtQI=;
 b=Uk5WS/4WEiqYz81XjlyzumJ4PJwdv1BZQ3iYnda/sghVKSOMhLxhyxMqDYaFT7bWwxRC5D8s2
 aZVnIkcjovMB6d4nu9+R4IpJ7W1SQFmf/akwyDI3EYRJIgNVu5X1rNk
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=pO5+BCw/TENGLvwX5NYZOZmZihcxjkxeFSMuk47erps=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260722 with auth_id=891
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Invoking dmaengine_terminate_sync() against the channel after each
submitted descriptor is strange. It's benign when the test is
single-threaded, but disruptive when multiple threads are submitting
descriptors to the channel concurrently:

  # cd /sys/module/dmatest/parameters/
  # echo 1 > polled
  # echo 2 > threads_per_chan
  # echo dma0chan0 > channel
  # echo 1 > run
...
  dmatest: Added 2 threads using dma0chan0
  dmatest: Started 2 threads using dma0chan0
  xilinx-zynqmp-dma ffa80000.dma: dma_sync_wait: timeout!
  xilinx-zynqmp-dma ffa80000.dma: dma_sync_wait: timeout!
  dmatest: dma0chan0-copy0: result #3: 'test timed out' with
    src_off=0x487 dst_off=0xf8 len=0x171b (0)
  dmatest: dma0chan0-copy1: result #6: 'test timed out' with
    src_off=0x227d dst_off=0xf99 len=0xf7a (0)

Remove the call to dmaengine_terminate_sync() from the main thread
loop.

Fixes: fb9816f9d05f ("dmaengine: dmatest: Add support for completion polling")
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 drivers/dma/dmatest.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/drivers/dma/dmatest.c b/drivers/dma/dmatest.c
index 2ae3469397f3..60bc448f42ee 100644
--- a/drivers/dma/dmatest.c
+++ b/drivers/dma/dmatest.c
@@ -837,7 +837,6 @@ static int dmatest_func(void *data)
 
 		if (params->polled) {
 			status = dma_sync_wait(chan, cookie);
-			dmaengine_terminate_sync(chan);
 			if (status == DMA_COMPLETE)
 				done->done = true;
 		} else {

-- 
2.54.0

