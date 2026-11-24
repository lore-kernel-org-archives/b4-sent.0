From: Suyuan Wang <shyckless@gmail.com>
Date: Tue, 24 Nov 2026 04:31:33 +0000
Subject: [PATCH] mmc: sdhci-msm: Disable clocks when runtime resume fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-sdhci-msm-v1-1-75c70ed6569f@gmail.com>
X-B4-Tracking: v=1; b=H4sIACQTBWsC/yXMywqAIBBA0V+JWSeoiD1+JVqUTjVBD5yKIPr3r
 JYHLvcCxkDIUCYXBDyIaZkjVJqAG5q5R0E+GrTUViltBPvBkZh4EqYwymTS+txnEPs1YEfn96r
 q37y3I7rtHcB9P5jxzABtAAAA
X-Change-ID: 20261124-sdhci-msm-49414706d8d7
To: ulfh@kernel.org, adrian.hunter@intel.com
Cc: linux-arm-msm@vger.kernel.org, linux-mmc@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795494693; l=2096;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=HhFjClmYElnD2cFzd7zNNwY54YGQOkXaSr+aFnOcHKc=;
 b=zQ6Ixg/O3d6/6EBenIwna/syzB/rptUS20olIOt4SZIX7tXf+a1VQZT5aipjVTOBY2eeYy/hC
 xE3DTWawSwjDQEzg2Q7a5pmI9AKPwhO+Y3xCveevI/3ihOkv+EvKlrn
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

sdhci_msm_runtime_resume() enables the bulk clocks first. If restoring
the SDR DLL config or resuming the ICE fails after the clocks have been
enabled, the callback returns the error without undoing the clock
enable. On the ICE error path the OPP performance vote also stays in
place.

The PM core then keeps the device in the suspended state, so
sdhci_msm_runtime_suspend() does not run and nothing drops the vote or
disables the clocks.

Undo these steps on the error paths, in the same order that
sdhci_msm_runtime_suspend() uses.

Found with a static analysis tool and checked by hand.

Fixes: 21f1e2d457ce ("mmc: sdhci-msm: Re-initialize DLL if MCLK is gated dynamically")
Fixes: c93767cf64eb ("mmc: sdhci-msm: add Inline Crypto Engine support")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Compile tested on arm64 (W=1). I don't have the hardware.
---
 drivers/mmc/host/sdhci-msm.c | 11 +++++++++--
 1 file changed, 9 insertions(+), 2 deletions(-)

diff --git a/drivers/mmc/host/sdhci-msm.c b/drivers/mmc/host/sdhci-msm.c
index 32b1bcba47d6..39db20ce5bb7 100644
--- a/drivers/mmc/host/sdhci-msm.c
+++ b/drivers/mmc/host/sdhci-msm.c
@@ -2978,20 +2978,27 @@ static int sdhci_msm_runtime_resume(struct device *dev)
 	if (msm_host->restore_dll_config && msm_host->clk_rate) {
 		ret = sdhci_msm_restore_sdr_dll_config(host);
 		if (ret)
-			return ret;
+			goto err_disable_clks;
 	}
 
 	dev_pm_opp_set_rate(dev, msm_host->clk_rate);
 
 	ret = sdhci_msm_ice_resume(msm_host);
 	if (ret)
-		return ret;
+		goto err_drop_vote;
 
 	spin_lock_irqsave(&host->lock, flags);
 	host->runtime_suspended = false;
 	spin_unlock_irqrestore(&host->lock, flags);
 
 	return ret;
+
+err_drop_vote:
+	dev_pm_opp_set_rate(dev, 0);
+err_disable_clks:
+	clk_bulk_disable_unprepare(ARRAY_SIZE(msm_host->bulk_clks),
+				   msm_host->bulk_clks);
+	return ret;
 }
 
 static int sdhci_msm_restore(struct device *dev)



