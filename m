From: DelaySystem <DelaySystem@tubot.lat>
Date: Sat, 07 Nov 2026 21:06:54 -0800
Subject: [PATCH] staging: media: tegra-video: use dev_err_probe() in CSI/VI
 probe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-batch1-s2-tegra-probe-v1-1-b4775e6437e5@tubot.lat>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQqDQAxA4atI1g1MBmqpVyldzE/UuFBJpqUg3
 r2jLr/FexsYq7BB12yg/BWTZa6gWwNpDPPAKLkavPMtkXtgDCWNhOax8KABV10iY879nenpsqM
 ItV2Ve/md39f7sn3ixKkcM9j3P5PoQpN5AAAA
X-Change-ID: 20261107-batch1-s2-tegra-probe-ddf5e190d01b
To: luca.ceresoli@bootlin.com, mchehab@kernel.org, skomatineni@nvidia.com, 
 thierry.reding@kernel.org, jonathanh@nvidia.com, gregkh@linuxfoundation.org
Cc: linux-tegra@vger.kernel.org, linux-media@vger.kernel.org, 
 linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 DelaySystem <DelaySystem@tubot.lat>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2702; i=DelaySystem@tubot.lat;
 h=from:subject:message-id; bh=HadRakgfetZKfm5cBPmgCO0PbLmnRqlErwjrkQRxrOE=;
 b=owGbwMvMwCH2SNl4+SzWXm/G02pJDFkfmPMuPLl/SnLyI83elVuCq5deXp+gs9VSV9vGtVnsL
 4/BnnCxjlIWBjEOBlkxRRYxGZ739fd14qyt5pyAmcPKBDKEgYtTACbyfSkjw+l9nf7nRc6vPrqd
 +YjtL/9w3+s3g+x+RqyTSO6x9N9R9ZLhf+bJ2cf/qnf7eF06clJtf9ulDZpRR6bd+WEUENDC+O2
 qJh8A
X-Developer-Key: i=DelaySystem@tubot.lat; a=openpgp;
 fpr=161C0CEF7FDF2C5E3B3A9CC8E22333A79A058D4B
X-Endpoint-Received: by B4 Relay for DelaySystem@tubot.lat/default with auth_id=1447
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Clock, populate and other probe-time resource lookups can return
-EPROBE_DEFER.  Convert the remaining open-coded dev_err() + return
sites in tegra_csi_probe() and tegra_vi_probe() to dev_err_probe(),
which suppresses the error message on deferral and records the deferral
reason.  This matches the existing dev_err_probe() use in vip.c and in
the regulator/MIPI paths of tegra_csi_probe() itself.

No functional change other than defer handling.

Signed-off-by: DelaySystem <DelaySystem@tubot.lat>
---
 drivers/staging/media/tegra-video/csi.c |  6 ++----
 drivers/staging/media/tegra-video/vi.c  | 16 ++++++----------
 2 files changed, 8 insertions(+), 14 deletions(-)

diff --git a/drivers/staging/media/tegra-video/csi.c b/drivers/staging/media/tegra-video/csi.c
index 5a5fca378ae6..9ec04ad3a893 100644
--- a/drivers/staging/media/tegra-video/csi.c
+++ b/drivers/staging/media/tegra-video/csi.c
@@ -810,10 +810,8 @@ static int tegra_csi_probe(struct platform_device *pdev)
 		csi->clks[i].id = csi->soc->clk_names[i];
 
 	ret = devm_clk_bulk_get(&pdev->dev, csi->soc->num_clks, csi->clks);
-	if (ret) {
-		dev_err(&pdev->dev, "failed to get the clocks: %d\n", ret);
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(&pdev->dev, ret, "failed to get the clocks\n");
 
 	csi->vdd = devm_regulator_get(&pdev->dev, "avdd-dsi-csi");
 	if (IS_ERR(csi->vdd))
diff --git a/drivers/staging/media/tegra-video/vi.c b/drivers/staging/media/tegra-video/vi.c
index d8c77d1290ef..34507a52016e 100644
--- a/drivers/staging/media/tegra-video/vi.c
+++ b/drivers/staging/media/tegra-video/vi.c
@@ -1875,11 +1875,9 @@ static int tegra_vi_probe(struct platform_device *pdev)
 	vi->soc = of_device_get_match_data(&pdev->dev);
 
 	vi->clk = devm_clk_get(&pdev->dev, NULL);
-	if (IS_ERR(vi->clk)) {
-		ret = PTR_ERR(vi->clk);
-		dev_err(&pdev->dev, "failed to get vi clock: %d\n", ret);
-		return ret;
-	}
+	if (IS_ERR(vi->clk))
+		return dev_err_probe(&pdev->dev, PTR_ERR(vi->clk),
+				     "failed to get vi clock\n");
 
 	if (!pdev->dev.pm_domain) {
 		ret = -ENOENT;
@@ -1888,11 +1886,9 @@ static int tegra_vi_probe(struct platform_device *pdev)
 	}
 
 	ret = devm_of_platform_populate(&pdev->dev);
-	if (ret < 0) {
-		dev_err(&pdev->dev,
-			"failed to populate vi child device: %d\n", ret);
-		return ret;
-	}
+	if (ret < 0)
+		return dev_err_probe(&pdev->dev, ret,
+				     "failed to populate vi child device\n");
 
 	vi->dev = &pdev->dev;
 	vi->ops = vi->soc->ops;

---
base-commit: fa4ad798f6f681031775266044ba1b0cf3c670bd
change-id: 20261107-batch1-s2-tegra-probe-ddf5e190d01b

Best regards,
--  
DelaySystem <DelaySystem@tubot.lat>

