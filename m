From: David Heidelberg <david@ixit.cz>
Date: Mon, 23 Nov 2026 13:02:42 +0100
Subject: [PATCH 4/4] media: ccs: Set V4L2_CTRL_FLAG_MODIFY_LAYOUT on flip
 controls
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-ccs-clanked-fixes-v1-4-fb2bcc87a517@ixit.cz>
References: <20261123-ccs-clanked-fixes-v1-0-fb2bcc87a517@ixit.cz>
In-Reply-To: <20261123-ccs-clanked-fixes-v1-0-fb2bcc87a517@ixit.cz>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Cc: linux-media@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1713; i=david@ixit.cz;
 h=from:subject:message-id; bh=Jg+pYJt/4wg/fRRWkTLmCSQTZCnFKvaMIIyx5/S5q2M=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrBCtg6qFsZ6tF0hPcb6XkAiTKO+f0YLRVgPSSy
 4PzMS/9c8qJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawQrYAAKCRBgAj/E00kg
 cvpWEAClfY1fOUUJpLgmeBUtZpRAGitUn+X83v+sk61fqol1Gd1ytQRVsJW5poY6OpDOqD7tD+Q
 1WhL3TZjpdxrbmSkXEQJZw4d5Cgx56/Gzp+bKZjIcGMwHtMZ2Cv7Rizndx8i6LJi5MVHZ0cwK/I
 JWeY1iLZZvSTP8uLN1G/0jnwvcsvZmbsUlq83Eai6pIF4pUwC+BM47I2TA5QXCYYmmXV+eb3F8U
 HCrpVr+cKH9m/N/QEFUEkZF3OQiLlPB4iamG0j1C7FZfvsturf+RtGxG7bSlWCc+7O8N3k1laz5
 e+xdkAd1GwWUEs/c5jPXblHrwfFDiTy+zGxVTAXSNEiOXtPTn7k9kzEN3nQi77gQsKyguSH/zoW
 3D0tkzIezeG5k4kiDb2zQQoR9XWMy034q1Y6DeHWSts7Cm7CrV2LkOtwyBEBqNHoS671SalU+WM
 pRleCkB9nP8x4yXR3zOw/42CJPr5qUgWh3yj3ybD2V7wULhsDS3XmBOavZzfC1+l7DkzE/9VeDo
 wvs7jcfHJSG6Y9n50FZUSa1ib8jLHuIDdhEfRo8fhEaozGfmuX2DbnwN1JYTWqJ/ftV99NQJuZ+
 EN5Xzb/LBZ2btKbkWKAhQSe3vcOV+mLr5uIJITvfI+kDY5Nl0EL5v1DVzX3sNvOynsqGnBnxqNb
 jV3/wuKrDH6EP5w==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Changing V4L2_CID_HFLIP or V4L2_CID_VFLIP calls ccs_update_mbus_formats(),
which XORs the default pixel order and changes the Bayer media bus format
code exposed on the sub-device pads.

Per the V4L2 specification, controls that modify the pixel order / layout
must advertise V4L2_CTRL_FLAG_MODIFY_LAYOUT so userspace (such as
libcamera) knows that flips alter the Bayer pattern order.

Fixes: ccfc97bdb5ae ("[media] smiapp: Add driver")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/media/i2c/ccs/ccs-core.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/media/i2c/ccs/ccs-core.c b/drivers/media/i2c/ccs/ccs-core.c
index 85748c6110ecc..756b5ee11f52e 100644
--- a/drivers/media/i2c/ccs/ccs-core.c
+++ b/drivers/media/i2c/ccs/ccs-core.c
@@ -1047,19 +1047,23 @@ static int ccs_init_controls(struct ccs_sensor *sensor)
 	/* Exposure limits will be updated soon, use just something here. */
 	sensor->exposure = v4l2_ctrl_new_std(
 		&sensor->pixel_array->ctrl_handler, &ccs_ctrl_ops,
 		V4L2_CID_EXPOSURE, 0, 0, 1, 0);
 
 	sensor->hflip = v4l2_ctrl_new_std(
 		&sensor->pixel_array->ctrl_handler, &ccs_ctrl_ops,
 		V4L2_CID_HFLIP, 0, 1, 1, 0);
+	if (sensor->hflip)
+		sensor->hflip->flags |= V4L2_CTRL_FLAG_MODIFY_LAYOUT;
 	sensor->vflip = v4l2_ctrl_new_std(
 		&sensor->pixel_array->ctrl_handler, &ccs_ctrl_ops,
 		V4L2_CID_VFLIP, 0, 1, 1, 0);
+	if (sensor->vflip)
+		sensor->vflip->flags |= V4L2_CTRL_FLAG_MODIFY_LAYOUT;
 
 	sensor->vblank = v4l2_ctrl_new_std(
 		&sensor->pixel_array->ctrl_handler, &ccs_ctrl_ops,
 		V4L2_CID_VBLANK, 0, 1, 1, 0);
 
 	if (sensor->vblank)
 		sensor->vblank->flags |= V4L2_CTRL_FLAG_UPDATE;
 

-- 
2.55.0

