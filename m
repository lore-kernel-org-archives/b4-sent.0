From: Nathan Lynch <nathan.lynch@amd.com>
Date: Tue, 08 Apr 2025 08:37:49 -0500
Subject: [PATCH] dmaengine: dmatest: Don't forcibly terminate channel in
 polled mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250408-dmaengine-dmatest-poll-mode-fix-v1-1-754a446a5363@amd.com>
X-B4-Tracking: v=1; b=H4sIAKwm9WcC/x2NQQqDMBBFryKzdmBMrbZepXSh5qsDmkgiRRDvb
 uzuvbf4/6CIoIjUZAcF/DSqd0mKPKN+at0IVpucjJinlPJgu7RwozrctCFuvPp55sVb8KA7V3X
 RibH9W14lpZU1IOX/w+d7nhdJi4UBcQAAAA==
X-Change-ID: 20250403-dmaengine-dmatest-poll-mode-fix-671b02dc9084
To: Vinod Koul <vkoul@kernel.org>
Cc: =?utf-8?q?P=C3=A9ter_Ujfalusi?= <peter.ujfalusi@gmail.com>, 
 Vinicius Costa Gomes <vinicius.gomes@intel.com>, 
 Dave Jiang <dave.jiang@intel.com>, dmaengine@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Nathan Lynch <nathan.lynch@amd.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744119476; l=1736;
 i=nathan.lynch@amd.com; s=20241010; h=from:subject:message-id;
 bh=dERQxgU+2fAzNEP2+EuhPk8lfIVEWf/LdcDgr/XAkxk=;
 b=fgHl1Z3V5ne92fMnkK6WX/NUlvhrY7ftyp1iGj55T2Rey1pSPm6P7YYnXu/z/lCXzmywZO2Q/
 Za25lHutFt2BfoJWCHb5RC+THaLBzNM4f4ygDpL7fmAfPa5EliGOvRP
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=ZR637UTGg5YLDj56cxFeHdYoUjPMMFbcijfOkAmAnbc=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20241010 with auth_id=241
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
index d891dfca358e209c9a5c2d8b49e3e539130e53e8..4e109c45fe0c5a7e8f337efe6e00e0616977f770 100644
--- a/drivers/dma/dmatest.c
+++ b/drivers/dma/dmatest.c
@@ -835,7 +835,6 @@ static int dmatest_func(void *data)
 
 		if (params->polled) {
 			status = dma_sync_wait(chan, cookie);
-			dmaengine_terminate_sync(chan);
 			if (status == DMA_COMPLETE)
 				done->done = true;
 		} else {

---
base-commit: 0af2f6be1b4281385b618cb86ad946eded089ac8
change-id: 20250403-dmaengine-dmatest-poll-mode-fix-671b02dc9084

Best regards,
-- 
Nathan Lynch <nathan.lynch@amd.com>

