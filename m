From: David Heidelberg <david@ixit.cz>
Date: Mon, 23 Nov 2026 13:02:40 +0100
Subject: [PATCH 2/4] media: ccs: Fix sub-device index in ccs_cleanup()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-ccs-clanked-fixes-v1-2-fb2bcc87a517@ixit.cz>
References: <20261123-ccs-clanked-fixes-v1-0-fb2bcc87a517@ixit.cz>
In-Reply-To: <20261123-ccs-clanked-fixes-v1-0-fb2bcc87a517@ixit.cz>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Cc: linux-media@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1332; i=david@ixit.cz;
 h=from:subject:message-id; bh=pC2UfNfNMyg9YWe2H2VHn7jSLy//n125s+CsRlecDeI=;
 b=owEBbAKT/ZANAwAIAWACP8TTSSByAcsmYgBrBCtfl3ucccsr41EtQsY1tPLhfvv8RdIboiCFY
 ZmD4/8AKcSJAjIEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawQrXwAKCRBgAj/E00kg
 cmTkD/dLnQWqaCqykHC9phyfzLJiCMhlcjV9KdN+aczegXLSFT/Yh8qgmakLz+2ehuAdxG5+OMN
 pwj667xTtwFIQeB+wHVCAKWuSimVzRvJbXHMG/kF8sQMVRPuiplo6YwED8K/NXHcaQ+/ig94iPY
 VnvPqHEQE2AgOKmcdY/vtbu2qYfTos4KHqOvEOiy9/8Nhl5vAhhtsy3ZTGYDOLVLwqjBb7a4ahc
 fYH59yoaZr+0fQxJA4SvqqS2pVjPmOdaHC1HUwo16TEOK4LdhxOIPgjRRXQjMT+rdi60sl7AOfo
 PPlYvZxoxS2XPIQqs8wyXb+3qiVI0vQTsACxGmT+wHjwHPGvv2La2YJzMoE6Ln+5bCJf5buRKDt
 5HlQpDVeP5AizHO8gDW39zSc9AJqAxYZHL45KMezigYcfG2p/fDr55319WRhyCGbenneo1sK5SF
 3VC5nqwPAkZEarZVaICzAOpNDVm3L/HKDtqgSWhQQ9txWB8FLpyXkI7ymkl51AAnrCgIemejwWz
 LzgJ4QBhZaoFvP+s5H7senkeHX5njpO20KY4G9Dv3xR2BA90Vd95cyvrVEByWUoJZqEk2PJ4TKp
 Kme0kIU9oa9RTLfn67XKGRnODJ98xFyZCWsfuRAMq5FdhPdl+yRobSxdpayqgFlIRLzEkOOTDoD
 Xiu6HkUzjPY2t
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The cleanup loop in ccs_cleanup() calls v4l2_subdev_cleanup() on the
hardcoded element ssds[2] instead of ssds[i]. On two-subdev sensors
(without a scaler) ssds[2] is uninitialized, and on three-subdev sensors
ssds[0] and ssds[1] are never cleaned up while ssds[2] is cleaned up
three times.

Use the loop index i.

Fixes: d8bca3ed1d70 ("media: ccs: Use sub-device active state")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/media/i2c/ccs/ccs-core.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/media/i2c/ccs/ccs-core.c b/drivers/media/i2c/ccs/ccs-core.c
index 284cfbd89349c..df636b8df0b51 100644
--- a/drivers/media/i2c/ccs/ccs-core.c
+++ b/drivers/media/i2c/ccs/ccs-core.c
@@ -3002,17 +3002,17 @@ static int ccs_registered(struct v4l2_subdev *subdev)
 }
 
 static void ccs_cleanup(struct ccs_sensor *sensor)
 {
 	struct i2c_client *client = v4l2_get_subdevdata(&sensor->src->sd);
 	unsigned int i;
 
 	for (i = 0; i < sensor->ssds_used; i++) {
-		v4l2_subdev_cleanup(&sensor->ssds[2].sd);
+		v4l2_subdev_cleanup(&sensor->ssds[i].sd);
 		media_entity_cleanup(&sensor->ssds[i].sd.entity);
 	}
 
 	device_remove_file(&client->dev, &dev_attr_nvm);
 	device_remove_file(&client->dev, &dev_attr_ident);
 
 	ccs_free_controls(sensor);
 }

-- 
2.55.0

