From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Tue, 24 Nov 2026 00:43:55 +0100
Subject: [PATCH v2 3/5] media: qcom: camss: csid: release parent device on
 power-on failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-camss-fixes-v2-3-231a5523cd59@gmail.com>
References: <20261124-camss-fixes-v2-0-231a5523cd59@gmail.com>
In-Reply-To: <20261124-camss-fixes-v2-0-231a5523cd59@gmail.com>
To: Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795477434; l=3176;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=l8BJgwb8YH+21l9KNFz5RZ28SzemG6MQfy5k8gd73tQ=;
 b=s7oghpaIu2xADB1QXAeTWIK48qDUUMnAwrsIuSoJGUjccBmhoiFTZrzzjGcZ85sfaGsrNypU3
 Ou9MMu7oISjC4RWhMzzAvA5alf0KeOc7BiGP5YsXaSIm9V5vnpMWtuy
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

csid_set_power() acquires a reference on the parent device via
parent_dev_ops->get() before resuming runtime PM, enabling regulators
and clocks, and resetting the CSID hardware. If any of these subsequent
steps fail, the function returns without calling parent_dev_ops->put(),
leaking the parent VFE power reference.

Consolidate the power-on error paths using goto labels and release the
parent device reference on all failure paths.

Fixes: c5af8db84c01 ("media: camss: Do vfe_get/vfe_put for csid on sm8250")
Reviewed-by: Loic Poulain <loic.poulain@oss.qualcomm.com>
Reviewed-by: Bryan O'Donoghue <bryan.odonoghue@linaro.org>
Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 drivers/media/platform/qcom/camss/camss-csid.c | 48 ++++++++++++--------------
 1 file changed, 22 insertions(+), 26 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csid.c b/drivers/media/platform/qcom/camss/camss-csid.c
index 51f2090..e67edc3 100644
--- a/drivers/media/platform/qcom/camss/camss-csid.c
+++ b/drivers/media/platform/qcom/camss/camss-csid.c
@@ -682,7 +682,7 @@ static int csid_set_power(struct v4l2_subdev *sd, int on)
 	struct csid_device *csid = v4l2_get_subdevdata(sd);
 	struct camss *camss = csid->camss;
 	struct device *dev = camss->dev;
-	int ret = 0;
+	int ret;
 
 	if (on) {
 		/*
@@ -696,44 +696,28 @@ static int csid_set_power(struct v4l2_subdev *sd, int on)
 
 		ret = pm_runtime_resume_and_get(dev);
 		if (ret < 0)
-			return ret;
+			goto err_parent_put;
 
 		ret = regulator_bulk_enable(csid->num_supplies,
 					    csid->supplies);
-		if (ret < 0) {
-			pm_runtime_put_sync(dev);
-			return ret;
-		}
+		if (ret < 0)
+			goto err_pm_put;
 
 		ret = csid_set_clock_rates(csid);
-		if (ret < 0) {
-			regulator_bulk_disable(csid->num_supplies,
-					       csid->supplies);
-			pm_runtime_put_sync(dev);
-			return ret;
-		}
+		if (ret < 0)
+			goto err_regulators_disable;
 
 		ret = camss_enable_clocks(csid->nclocks, csid->clock, dev);
-		if (ret < 0) {
-			regulator_bulk_disable(csid->num_supplies,
-					       csid->supplies);
-			pm_runtime_put_sync(dev);
-			return ret;
-		}
+		if (ret < 0)
+			goto err_regulators_disable;
 
 		csid->phy.need_vc_update = true;
 
 		enable_irq(csid->irq);
 
 		ret = csid->res->hw_ops->reset(csid);
-		if (ret < 0) {
-			disable_irq(csid->irq);
-			camss_disable_clocks(csid->nclocks, csid->clock);
-			regulator_bulk_disable(csid->num_supplies,
-					       csid->supplies);
-			pm_runtime_put_sync(dev);
-			return ret;
-		}
+		if (ret < 0)
+			goto err_reset;
 
 		csid->res->hw_ops->hw_version(csid);
 	} else {
@@ -745,6 +729,18 @@ static int csid_set_power(struct v4l2_subdev *sd, int on)
 		csid->res->parent_dev_ops->put(camss, csid->id);
 	}
 
+	return 0;
+
+err_reset:
+	disable_irq(csid->irq);
+	camss_disable_clocks(csid->nclocks, csid->clock);
+err_regulators_disable:
+	regulator_bulk_disable(csid->num_supplies, csid->supplies);
+err_pm_put:
+	pm_runtime_put_sync(dev);
+err_parent_put:
+	csid->res->parent_dev_ops->put(camss, csid->id);
+
 	return ret;
 }
 

-- 
2.56.0

