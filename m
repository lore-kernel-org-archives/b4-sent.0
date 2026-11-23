From: David Heidelberg <david@ixit.cz>
Date: Mon, 23 Nov 2026 13:02:39 +0100
Subject: [PATCH 1/4] media: ccs: Use dev_dbg() instead of dev_err() in
 ccs_enum_mbus_code()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-ccs-clanked-fixes-v1-1-fb2bcc87a517@ixit.cz>
References: <20261123-ccs-clanked-fixes-v1-0-fb2bcc87a517@ixit.cz>
In-Reply-To: <20261123-ccs-clanked-fixes-v1-0-fb2bcc87a517@ixit.cz>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Cc: linux-media@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1866; i=david@ixit.cz;
 h=from:subject:message-id; bh=GfKr+K5WGWXwwETAeSQOVutcMvwdnlaUEXm6+5Ib7/8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrBCtfQDSpYx+xIeb6yn6+r9P/tpHAqG3wdobEO
 bcCHHWPI4yJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawQrXwAKCRBgAj/E00kg
 ciXHD/9tPEb1mYDS7IGmsCwheeD4oSigaV4cLtu67HgAXkIPAg7yib8qSr4aCHa4S2MPaauDdsr
 3i1gXCxMZ8sKMNd30nXKzEfR0bHgNi82s/tQJJZN1hdPx7G4Ee0mk/47SGI9oS72gsXGGPwktiF
 pnDusV/tYoet32puz9W6n7VUy5Szow08VNpw7SiQQiikMMOlcLeyTeTNjWUJtqdkhdAd5+EN/wu
 /+fp/9adCwlHoYAykrWhOXNJa3DDyNAyWFnAFivVaIxjJ2RCJyH1/xGSs9y8k6x0vrkvrKaekGd
 jCxd5nNW5GutzkKihifuNmJ/2D0G3ke4EavHJVTDZYtl8YT1TZRacCGdeU1Ra2gcyo97NY0FBHk
 ddwry87yCmcE/Dvaz6Sp/VYaMIU9A9cecGPbPVDBfFulY1UTuTbeUP9uffT1mZk7y6Enldi/alv
 hvpatHvMVHJZMj5/nhbLnWn+duwhk+Zbl6LqK+gcevBeeS91FGP6BNsRQFN4JSvNZ0xPkECthoh
 qYb3L2hO3Uv6FkYOST/Uw/Kg7fr+C8uZrT/nI8MujePaqAK+4ysIIc2Ob7l/LaPFjSI56DCUg98
 F2UGavHcv7jzCNqrL+7spNShA0/zNbAISFsvILTXAh1uljHoS+HHlpLEYK9DBcW+RK1RQxrTHMy
 /WfDWMb2YyOg6BQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 63bd19442f08 accidentally converted two dev_dbg() calls in
ccs_enum_mbus_code() to dev_err(), flooding the kernel log with error
messages whenever userspace enumerates media bus codes.

Restore them to dev_dbg().

Fixes: 63bd19442f08 ("media: ccs: Use %u for printing unsigned values, remove extra debug print")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/media/i2c/ccs/ccs-core.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/media/i2c/ccs/ccs-core.c b/drivers/media/i2c/ccs/ccs-core.c
index c3592317ee575..284cfbd89349c 100644
--- a/drivers/media/i2c/ccs/ccs-core.c
+++ b/drivers/media/i2c/ccs/ccs-core.c
@@ -2104,17 +2104,17 @@ static int ccs_enum_mbus_code(struct v4l2_subdev *subdev,
 			      struct v4l2_subdev_state *sd_state,
 			      struct v4l2_subdev_mbus_code_enum *code)
 {
 	struct i2c_client *client = v4l2_get_subdevdata(subdev);
 	struct ccs_sensor *sensor = to_ccs_sensor(subdev);
 	unsigned int i;
 	int idx = -1;
 
-	dev_err(&client->dev, "subdev %s, pad %u, index %u\n",
+	dev_dbg(&client->dev, "subdev %s, pad %u, index %u\n",
 		subdev->name, code->pad, code->index);
 
 	if (subdev != &sensor->src->sd || code->pad != CCS_PAD_SRC) {
 		if (code->index)
 			return -EINVAL;
 
 		code->code = sensor->internal_csi_format->code;
 
@@ -2122,17 +2122,17 @@ static int ccs_enum_mbus_code(struct v4l2_subdev *subdev,
 	}
 
 	for (i = 0; i < ARRAY_SIZE(ccs_csi_data_formats); i++) {
 		if (sensor->mbus_frame_fmts & BIT_U64(i))
 			idx++;
 
 		if (idx == code->index) {
 			code->code = ccs_csi_data_formats[i].code;
-			dev_err(&client->dev, "found index %u, i %u, code %x\n",
+			dev_dbg(&client->dev, "found index %u, i %u, code %x\n",
 				code->index, i, code->code);
 			return 0;
 		}
 	}
 
 	return -EINVAL;
 }
 

-- 
2.55.0

