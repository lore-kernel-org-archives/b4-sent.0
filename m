From: David Heidelberg <david@ixit.cz>
Date: Tue, 06 Jan 2026 16:14:05 +0100
Subject: [PATCH] media: ccs: Accommodate C-PHY into the calculation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260106-ccs-account-for-cphy-v1-1-c3639d606271@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAL0mXWkC/x3MPQ6AIAxA4auYzjZBBvy5inHAWrQLGFCjMdxd4
 vgN772QOAonGKoXIl+SJPiCpq6ANutXRlmKQSttVKMMEiW0ROH0B7oQkfbtQev6tutmo3TvoKR
 7ZCf3vx2nnD+WKD+HZgAAAA==
X-Change-ID: 20260106-ccs-account-for-cphy-af9788b6029f
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1385; i=david@ixit.cz;
 h=from:subject:message-id; bh=dwwD/3ToQdy2999UX5LH+C6Kbfqw7B2Pld4wPUvRozw=;
 b=kA0DAAgBYAI/xNNJIHIByyZiAGldJr6hRSnxRX3ddHeuWIjaZJfpEk1Fl0K7+qldAS/LzpOOn
 IkCMwQAAQgAHRYhBNd6Cc/u3Cu9U6cEdGACP8TTSSByBQJpXSa+AAoJEGACP8TTSSBy24QQAJ3P
 oYDcg7bkEuwDJ2VLTHZQSv/OBL+4D2EvFmFv2UBZUlW/HfRyL6rdSz4txsqGN7ofmf+tk/mS15w
 G9jHsTTTT0fhmDm8zzELQXot34oFCN1ISkjqAXX6k7bPRi9bsHYKI0yfWWsJgoqBVZ/G85rfuE0
 Ipdt39Vi3K+GnBma4R5RJxKIiIjooxBmY1xH6zouGZfb/mr5/SnL0MBL/DACIH3hPVCy0ZpBvAA
 TGzCZWysAwcsDDOw/Mfs1ec+9gcvg6q+BpFAiq1I6S+qthavLtIxiF9QFxyWwB4SWu9duPsnzFT
 3Gp31oc+xDQbjE4kTzdHAkeje8TkeEsVZGUeHytdGUlyk/eyncHnY32w3KVMZTzeXfO6UWfh0Ca
 OmrqLNY3F/7Phv5zMjKDEARCFChP/IK1zbD6HU/7aAjlVvbDuylC0/o67eNrnYbs0Jc2G5lIcvy
 9kfM5/4c7Zh92JeB1XmYZY7UvDAL0eopgacKBuN/7+1hH7U42LQDuFV6AYhu4ZBZqdEA6lHV3lj
 okrfALhrFhVpw6cQHCLhJ4jYgMLeCJVLBBei8tPp8VkoOzMBYVQIuUOjAj3ta4/orB2oQL4yAda
 ygm7h/GJmU2dhzxK0qfdNqjZkpcCFtMS9LCde3mSymlwc+XUWXMd98VW7TIKSlRlQDYVW+VAbnS
 R1Nj1
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We need to set correct mode for PLL to calculate correct frequency.
Signalling mode is known at this point, so use it for that.

Fixes: 47b6eaf36eba ("media: ccs-pll: Differentiate between CSI-2 D-PHY and C-PHY")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/media/i2c/ccs/ccs-core.c | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/drivers/media/i2c/ccs/ccs-core.c b/drivers/media/i2c/ccs/ccs-core.c
index f8523140784c7..2d689e47ed094 100644
--- a/drivers/media/i2c/ccs/ccs-core.c
+++ b/drivers/media/i2c/ccs/ccs-core.c
@@ -3425,7 +3425,14 @@ static int ccs_probe(struct i2c_client *client)
 	sensor->scale_m = CCS_LIM(sensor, SCALER_N_MIN);
 
 	/* prepare PLL configuration input values */
-	sensor->pll.bus_type = CCS_PLL_BUS_TYPE_CSI2_DPHY;
+	switch (sensor->hwcfg.csi_signalling_mode) {
+	case CCS_CSI_SIGNALING_MODE_CSI_2_CPHY:
+		sensor->pll.bus_type = CCS_PLL_BUS_TYPE_CSI2_CPHY;
+		break;
+	case CCS_CSI_SIGNALING_MODE_CSI_2_DPHY:
+		sensor->pll.bus_type = CCS_PLL_BUS_TYPE_CSI2_DPHY;
+		break;
+	}
 	sensor->pll.csi2.lanes = sensor->hwcfg.lanes;
 	if (CCS_LIM(sensor, CLOCK_CALCULATION) &
 	    CCS_CLOCK_CALCULATION_LANE_SPEED) {

---
base-commit: 6cd6c12031130a349a098dbeb19d8c3070d2dfbe
change-id: 20260106-ccs-account-for-cphy-af9788b6029f

Best regards,
-- 
David Heidelberg <david@ixit.cz>

