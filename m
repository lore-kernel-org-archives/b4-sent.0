From: George Neacsu <geocausa@gmail.com>
Date: Fri, 16 Oct 2026 15:55:52 +0100
Subject: [PATCH] media: qcom: camss: tpg: Skip the unnamed test pattern
 menu entries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-camss-tpg-menu-skip-v1-1-0a0a24e36316@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDA0Mz3eTE3OJi3ZKCdN3c1LxS3eLszAJd88S0JDMjI0NLU0MjJaDOgqL
 UtMwKsKnRsbW1AGyHUMFlAAAA
X-Change-ID: 20261016-camss-tpg-menu-skip-7afb62219512
To: Bryan O'Donoghue <bod@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: Wenmeng Liu <wenmeng.liu@oss.qualcomm.com>, linux-media@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, George Neacsu <geocausa@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792162551; l=2642;
 i=geocausa@gmail.com; s=20261015; h=from:subject:message-id;
 bh=EhYu2Sf5sRq8nG4xWwgv19XdQhle1nzxQog9NV/jvME=;
 b=tt6dLw6XGpWAdQXXI+3d+vqV/+tbdo586S1BIMNGL6Zsa2RBHRM2IIigDOaKGR94k1uJCC75Q
 yGavmGxUco2DjWRc9KH797OaEmv7sJCAwxQsdtqb6n9y/Hvo2//WFdz
X-Developer-Key: i=geocausa@gmail.com; a=ed25519;
 pk=KyQk/iWbxsikewDBh0SwlHI51RvAqahD3loqmRp9DVI=
X-Endpoint-Received: by B4 Relay for geocausa@gmail.com/20261015 with auth_id=1199
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The gen1 TPG names its test patterns in testgen_payload_modes[], which
is indexed by the hardware payload mode, so entries 3, 4, 7 and 8 are
NULL. The V4L2_CID_TEST_PATTERN menu is created with that array, a
maximum of TPG_PAYLOAD_MODE_NUM_SUPPORTED_GEN1 and no skip mask, so
setting the control to one of the gaps makes
v4l2_ctrl_type_op_validate() dereference a NULL name. The oops leaves
the control handler lock held, and a later rmmod of qcom-camss then
hangs in v4l2_ctrl_handler_free(). v4l2-compliance -m /dev/media0 does
both on X1E80100.

Skip the menu entries that have no name, so the core rejects those
values with -EINVAL and VIDIOC_QUERYMENU leaves them out.

Tested on the Surface Pro 11 (X1E80100) with next-20261015: the menu
lists 0, 1, 2, 5, 6 and 9, setting 3, 4, 7 or 8 returns -EINVAL,
v4l2-compliance -m /dev/media0 completes without an oops, and qcom-camss
unloads and loads again.

Fixes: 51fe835c485b ("media: qcom: camss: tpg: Add TPG support for multiple targets")
Cc: stable@vger.kernel.org
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: George Neacsu <geocausa@gmail.com>
---
Fix for a NULL dereference in the TPG test pattern control.
---
 drivers/media/platform/qcom/camss/camss-tpg.c | 10 ++++++++--
 1 file changed, 8 insertions(+), 2 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-tpg.c b/drivers/media/platform/qcom/camss/camss-tpg.c
index 5764a60fa3..2e80834225 100644
--- a/drivers/media/platform/qcom/camss/camss-tpg.c
+++ b/drivers/media/platform/qcom/camss/camss-tpg.c
@@ -453,7 +453,8 @@ int msm_tpg_register_entity(struct tpg_device *tpg,
 {
 	struct v4l2_subdev *sd = &tpg->subdev;
 	struct device *dev = tpg->camss->dev;
-	int ret;
+	u64 skip_mask = 0;
+	int ret, i;
 
 	v4l2_subdev_init(sd, &tpg_v4l2_ops);
 	sd->internal_ops = &tpg_v4l2_internal_ops;
@@ -470,9 +471,14 @@ int msm_tpg_register_entity(struct tpg_device *tpg,
 		return ret;
 	}
 
+	/* The mode names are indexed by hardware payload mode, skip the gaps */
+	for (i = 0; i <= tpg->testgen.nmodes; i++)
+		if (!tpg->testgen.modes[i])
+			skip_mask |= BIT_ULL(i);
+
 	tpg->testgen_mode = v4l2_ctrl_new_std_menu_items(&tpg->ctrls,
 							 &tpg_ctrl_ops, V4L2_CID_TEST_PATTERN,
-							 tpg->testgen.nmodes, 0, 0,
+							 tpg->testgen.nmodes, skip_mask, 0,
 							 tpg->testgen.modes);
 	if (tpg->ctrls.error) {
 		dev_err(dev, "Failed to init ctrl: %d\n", tpg->ctrls.error);

---
base-commit: b810335a0699d1810683796b0e3ffe8827ddfe6c
change-id: 20261016-camss-tpg-menu-skip-7afb62219512

Best regards,
-- 
George Neacsu <geocausa@gmail.com>

