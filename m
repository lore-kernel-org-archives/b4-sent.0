From: "David R. Hedges" <linuxdev844@thelittleman.net>
Date: Tue, 03 Nov 2026 13:28:02 -0600
Subject: [PATCH 2/5] drm/nouveau/gsp: don't report failed DP AUX transfers
 as completed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-nouveau-dp-fixes-v1-2-892f4bd357cd@thelittleman.net>
References: <20261103-nouveau-dp-fixes-v1-0-892f4bd357cd@thelittleman.net>
In-Reply-To: <20261103-nouveau-dp-fixes-v1-0-892f4bd357cd@thelittleman.net>
To: Lyude Paul <lyude@redhat.com>, Danilo Krummrich <dakr@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Dave Airlie <airlied@redhat.com>, Ben Skeggs <bskeggs@redhat.com>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, 
 "David R. Hedges" <linuxdev844@thelittleman.net>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793734092; l=2363;
 i=linuxdev844@thelittleman.net; s=20261103; h=from:subject:message-id;
 bh=VnhFFCJgwU5i55xG5SnKSfbRyrndYBR8/9ZzNzwvcvc=;
 b=FvGKLCExeTq/wzKIWyYwo1rYcl1ZNPwjfmlGJ9iRJBjjjUCu0eUeEa1Bfv5QXetBKXpDgnJXF
 yayxYdUuTsrDUdBzi3pocWEpW6KG++byU15FYqnfgrHstlChLrGGO5h
X-Developer-Key: i=linuxdev844@thelittleman.net; a=ed25519;
 pk=Cynzuei/w0GLdh3LuNJdvH7aaszLrHSxY5UyujS7l+g=
X-Endpoint-Received: by B4 Relay for linuxdev844@thelittleman.net/20261103 with auth_id=1397
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 9776c0a75a1a ("nouveau/dp: handle retries for AUX CH transfers
with GSP.") put the NV0073_CTRL_CMD_DP_AUXCH_CTRL call in a retry loop
and dropped the check for the call failing.  When RM fails it with
anything other than a retry request, r535_dp_aux_xfer() ignores the
error and returns the reply fields as if a transaction had completed:
replyType becomes the AUX reply, and size and data are copied out.
NVIDIA's own DisplayPort library (EvoAuxBus::transaction() in
open-gpu-kernel-modules) treats a failed AUXCH_CTRL call as a NACK and
ignores the reply.

RM does fail these calls.  On a GA102 with GSP-RM 570.144, replugging
a DP monitor that hasn't come back from DPMS off produces bursts of

  gsp: cli:0xc1d00001 obj:0x00730000 ctrl cmd:0x00731341 failed: 0x0000ffff

(NV_ERR_GENERIC, occasionally NV_ERR_INVALID_DATA), one per AUX
transaction, and the DPCD and EDID reads made during a burst are
judged on whatever the reply fields happen to contain.

Return the error from the control call again, as r535_dp_aux_xfer()
did before the retry loop was added.

Fixes: 9776c0a75a1a ("nouveau/dp: handle retries for AUX CH transfers with GSP.")
Cc: stable@vger.kernel.org
Link: https://gitlab.freedesktop.org/drm/nouveau/-/work_items/515
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: David R. Hedges <linuxdev844@thelittleman.net>
---
 drivers/gpu/drm/nouveau/nvkm/subdev/gsp/rm/r535/disp.c | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/rm/r535/disp.c b/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/rm/r535/disp.c
index f5f22173fc2c..953392504413 100644
--- a/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/rm/r535/disp.c
+++ b/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/rm/r535/disp.c
@@ -1101,9 +1101,12 @@ r535_dp_aux_xfer(struct nvkm_outp *outp, u8 type, u32 addr, u8 *data, u8 *psize)
 			msleep(ctrl->retryTimeMs);
 			nvkm_gsp_rm_ctrl_done(&disp->rm.objcom, ctrl);
 		} else {
-			memcpy(data, ctrl->data, size);
-			*psize = ctrl->size;
-			ret = ctrl->replyType;
+			/* The reply only describes a transaction if RM completed one. */
+			if (ret == 0) {
+				memcpy(data, ctrl->data, size);
+				*psize = ctrl->size;
+				ret = ctrl->replyType;
+			}
 			nvkm_gsp_rm_ctrl_done(&disp->rm.objcom, ctrl);
 			break;
 		}

-- 
2.55.0

