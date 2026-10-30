From: Igor Velkov <iav@iav.lv>
Date: Fri, 30 Oct 2026 03:33:00 +0200
Subject: [PATCH] media: rkvdec: Do not keep the clocks enabled from probe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261030-rkvdec-runtime-pm-clocks-v1-1-fb2c5b629e79@iav.lv>
X-B4-Tracking: v=1; b=H4sIAMvz42oC/x3MQQqEMAxA0atI1gaaKgpzFXEhaZwJjlVSFUG8u
 8XlW/x/QRJTSfApLjA5NOkSM6gsgH9D/ApqyAbvfEOucmjTEYTR9rjpLLjOyP+Fp4Q1DYFHqsm
 3BDlfTUY933XX3/cDQbjLdmoAAAA=
To: Detlev Casanova <detlev.casanova@collabora.com>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>
Cc: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, 
 Diederik de Haas <diederik@cknow-tech.com>, Jonas Karlman <jonas@kwiboo.se>, 
 Francesco Saverio Pavone <pavone.lawyer@gmail.com>, 
 linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2611; i=iav@iav.lv;
 h=from:subject:message-id; bh=DV65nOamq4qFrrJK3VgervQr4mJ0twxpufgrJGR55R4=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFmPP595z7Fsxraet1UnT9VN2CkpP+/ejXN1c/lOOGS6e
 1oszNFn6yhlYRDjYpAVU2SZcEjjVsaSq3/9PcwfwMxhZQIZwsDFKQAT+fqN4X+FvN+VuAaNQ3de
 TlwXYhIUHaP5PFys8zOXXHmeGqfe69uMDC//vf3eVbf27uke7xN1N7ScLuo/aNBf2lA3w8Xmh/l
 FWz4A
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit 6a846f7d72c7 ("media: rkvdec: Enable all clocks without
naming them") the clocks are fetched with devm_clk_bulk_get_all_enabled(),
which keeps them enabled from probe until unbind. rkvdec_runtime_suspend()
disables them on top of that, so their enable count never drops to zero
and the clock gates stay open while the decoder is idle.

On RK3399 this also breaks restore from hibernation when the boot kernel
has not enabled these clocks, for example with rkvdec built as a module:
the gates are closed when the restored kernel takes over, while it still
counts the clocks as enabled. Powering on the vdu power domain then finds
the count at 1 and leaves the gates closed, and the first QoS register
write of the domain never returns.

Get the clocks without enabling them and let runtime PM enable them while
the decoder is in use, as before that commit.

Fixes: 6a846f7d72c7 ("media: rkvdec: Enable all clocks without naming them")
Cc: stable@vger.kernel.org # v7.0+
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested on ROCK Pi 4A (RK3399) with v7.3, rkvdec and panfrost built as
modules, panfrost not loaded:
- idle decoder: the vdu clocks have enable_count 0 (1 without the patch);
- hibernate, power cycle, restore: 3 of 3 (0 of 3 without the patch, the
  restored kernel stops after bringing the secondary CPUs up);
- H.264 decode with GStreamer v4l2slh264dec, 300 frames of 720p High
  profile: output identical to avdec_h264 (md5 of all frames).
The QoS hang was traced with debug prints in rockchip_pd_power() on a
7.3-based kernel.

This is separate from the unbind leak in Jonas's patch that Francesco
posted [1]: here the extra enable comes from probe.

[1] https://lore.kernel.org/all/20260717154505.83935-1-pavone.lawyer@gmail.com/
---
 drivers/media/platform/rockchip/rkvdec/rkvdec.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/media/platform/rockchip/rkvdec/rkvdec.c b/drivers/media/platform/rockchip/rkvdec/rkvdec.c
index 061281f903f3..45c541ae3029 100644
--- a/drivers/media/platform/rockchip/rkvdec/rkvdec.c
+++ b/drivers/media/platform/rockchip/rkvdec/rkvdec.c
@@ -1788,7 +1788,7 @@ static int rkvdec_probe(struct platform_device *pdev)
 	if (ret)
 		return ret;
 
-	ret = devm_clk_bulk_get_all_enabled(&pdev->dev, &rkvdec->clocks);
+	ret = devm_clk_bulk_get_all(&pdev->dev, &rkvdec->clocks);
 	if (ret < 0)
 		return ret;
 

---
base-commit: c03c1a14507dfaf8b856c2608f9ac216021fc222
change-id: 20261030-rkvdec-runtime-pm-clocks-41adcf141271

Best regards,
-- 
Igor Velkov <iav@iav.lv>

