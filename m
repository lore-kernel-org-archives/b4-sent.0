From: "David R. Hedges" <linuxdev844@thelittleman.net>
Date: Tue, 03 Nov 2026 13:28:03 -0600
Subject: [PATCH 3/5] drm/nouveau/gsp: don't dereference a failed DP_CTRL
 reply
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-nouveau-dp-fixes-v1-3-892f4bd357cd@thelittleman.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793734092; l=2139;
 i=linuxdev844@thelittleman.net; s=20261103; h=from:subject:message-id;
 bh=Em2OoM13M26pHcKpGhv1LYrtl6SYDlTdhnsjJdx/IvI=;
 b=SbNR04R3SMfP+QN1UMFdmAjrsP/bJpahSlrmBPEiholWFF0MG14BK5ZjKZRTnQSMaOK9sjjOC
 2YG7CX4kHn6BN5hvVQCke4v4O6nJOyumj6eFFm+r36izrVnQkjlVZp/
X-Developer-Key: i=linuxdev844@thelittleman.net; a=ed25519;
 pk=Cynzuei/w0GLdh3LuNJdvH7aaszLrHSxY5UyujS7l+g=
X-Endpoint-Received: by B4 Relay for linuxdev844@thelittleman.net/20261103 with auth_id=1397
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit eb284f4b3781 ("drm/nouveau/dp: Honor GSP link training retry
timeouts") put the NV0073_CTRL_CMD_DP_CTRL call in
r535_dp_train_target() in a retry loop and dropped the check for the
call failing.  The reply's err field is now read whatever
nvkm_gsp_rm_ctrl_push() returned, but when the GSP RPC itself fails,
a timeout for instance, the reply is NULL.

On a GA102 with GSP-RM 570.144 this turned a display hang into an
oops.  A modeset hit "core notifier timeout", and releasing the output
afterwards timed out waiting for GSP:

  WARNING: nvkm/subdev/gsp/rm/r535/rpc.c:164 at r535_gsp_msgq_wait+0xb1/0xc0 [nouveau]
  ...
  BUG: kernel NULL pointer dereference, address: 0000000000000010
  RIP: 0010:r535_dp_train_target+0x1db/0x220 [nouveau]
  Call Trace:
   r535_dp_release+0x73/0xe0 [nouveau]
   nvkm_uoutp_mthd+0xaf0/0xc70 [nouveau]
   ...
   nvif_outp_release+0x1b/0xb0 [nouveau]
   nv50_disp_atomic_commit_core+0x5ba/0x6b0 [nouveau]

0x10 is the offset of err in NV0073_CTRL_DP_CTRL_PARAMS.  Only look at
err if the control call succeeded.

Fixes: eb284f4b3781 ("drm/nouveau/dp: Honor GSP link training retry timeouts")
Cc: stable@vger.kernel.org
Link: https://gitlab.freedesktop.org/drm/nouveau/-/work_items/515
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: David R. Hedges <linuxdev844@thelittleman.net>
---
 drivers/gpu/drm/nouveau/nvkm/subdev/gsp/rm/r535/disp.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/rm/r535/disp.c b/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/rm/r535/disp.c
index 953392504413..028f342e020b 100644
--- a/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/rm/r535/disp.c
+++ b/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/rm/r535/disp.c
@@ -1006,7 +1006,7 @@ r535_dp_train_target(struct nvkm_outp *outp, u8 target, bool mst, u8 link_nr, u8
 			nvkm_gsp_rm_ctrl_done(&disp->rm.objcom, ctrl);
 		} else {
 			/* GSP didn't say to retry, or we were successful */
-			if (ctrl->err)
+			if (ret == 0 && ctrl->err)
 				ret = -EIO;
 			nvkm_gsp_rm_ctrl_done(&disp->rm.objcom, ctrl);
 			break;

-- 
2.55.0

