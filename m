From: "David R. Hedges" <linuxdev844@thelittleman.net>
Date: Tue, 03 Nov 2026 13:28:01 -0600
Subject: [PATCH 1/5] drm/nouveau/gsp: fail control calls whose reply went
 missing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-nouveau-dp-fixes-v1-1-892f4bd357cd@thelittleman.net>
References: <20261103-nouveau-dp-fixes-v1-0-892f4bd357cd@thelittleman.net>
In-Reply-To: <20261103-nouveau-dp-fixes-v1-0-892f4bd357cd@thelittleman.net>
To: Lyude Paul <lyude@redhat.com>, Danilo Krummrich <dakr@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Dave Airlie <airlied@redhat.com>, Ben Skeggs <bskeggs@redhat.com>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, 
 "David R. Hedges" <linuxdev844@thelittleman.net>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793734092; l=1563;
 i=linuxdev844@thelittleman.net; s=20261103; h=from:subject:message-id;
 bh=hRrbjbCV1yWJ+Tf4TceO0O/RoGm+JN9bs3miAwLKNC0=;
 b=6s12OYfwt2UO14gX7497JNyOhA9zhT4/8AHID6LT0VcGuyiRRNzPWfVfvBvnfpxe4/vknFRFo
 z48TbizjuXvCS3Cgmaa503BHH9hYz5crRbWHqwooqyH4QUz/6Bmj1ws
X-Developer-Key: i=linuxdev844@thelittleman.net; a=ed25519;
 pk=Cynzuei/w0GLdh3LuNJdvH7aaszLrHSxY5UyujS7l+g=
X-Endpoint-Received: by B4 Relay for linuxdev844@thelittleman.net/20261103 with auth_id=1397
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

r535_gsp_rpc_rm_ctrl_push() sets *params to NULL and returns
PTR_ERR(rpc) when nvkm_gsp_rpc_push() returns an error or NULL.  NULL
is the normal result when no reply was asked for (repc == 0), but
r535_gsp_msgq_recv() also returns NULL, after a WARN, when the message
at the head of the queue claims to be longer than a message can be.
PTR_ERR(NULL) is 0, so the caller sees success with a NULL reply:
nvkm_gsp_rm_ctrl_rd() hands the NULL back as if it were valid, and
r535_dp_aux_xfer() and r535_dp_train_target() go on to read their
reply fields.

Return -EIO when a reply was expected and none came back.

Fixes: 4ae3a20102b2 ("nouveau/gsp: don't free ctrl messages on errors")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: David R. Hedges <linuxdev844@thelittleman.net>
---
 drivers/gpu/drm/nouveau/nvkm/subdev/gsp/rm/r535/ctrl.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/rm/r535/ctrl.c b/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/rm/r535/ctrl.c
index 70b9ee911c5e..ea925a9d0531 100644
--- a/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/rm/r535/ctrl.c
+++ b/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/rm/r535/ctrl.c
@@ -44,6 +44,9 @@ r535_gsp_rpc_rm_ctrl_push(struct nvkm_gsp_object *object, void **params, u32 rep
 	rpc = nvkm_gsp_rpc_push(gsp, rpc, NVKM_GSP_RPC_REPLY_RECV, repc);
 	if (IS_ERR_OR_NULL(rpc)) {
 		*params = NULL;
+		/* NULL is only a successful reply if none was asked for. */
+		if (!rpc && repc)
+			return -EIO;
 		return PTR_ERR(rpc);
 	}
 

-- 
2.55.0

