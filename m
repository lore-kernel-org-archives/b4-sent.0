From: Joe Finzel <joe@sudmix.de>
Date: Fri, 23 Oct 2026 11:38:05 +0200
Subject: [PATCH] drm/nouveau/gsp: only handle GSP interrupts routed to the
 host
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-nouveau-gsp-irqdest-v1-1-5dd6131faa14@sudmix.de>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqAIBBA0avErBtQA8muEi0kp5qNllMRSHdPW
 r7F/wWEMpPA0BTIdLNwihW6bWDefFwJOVSDUcZqZTqM6brJX7jKjpyPQHKiV712QVPwzkIt90w
 LP/91nN73A0eequxlAAAA
X-Change-ID: 20261023-nouveau-gsp-irqdest-a0819d1eda96
To: Lyude Paul <lyude@redhat.com>, Danilo Krummrich <dakr@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Ben Skeggs <bskeggs@nvidia.com>, Dave Airlie <airlied@redhat.com>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Joe Finzel <joe@sudmix.de>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792748316; l=4484;
 i=joe@sudmix.de; s=default; h=from:subject:message-id;
 bh=b17+26F2qy81a+KL88BTwZnr9eyzHZo5HKZat40hBY0=;
 b=MbIuyuHc8Or6oZda9Wk1YBS5NKVR+tSNgUAdhPdBE3ZtOClgBMW1X93E8PHSnTQpSFYVhTLo0
 mcivfq9ZJCuAIrUbRqoyhiYIYpa/MDhEK0WuDFxf8AcprRTcqtduk3G
X-Developer-Key: i=joe@sudmix.de; a=ed25519;
 pk=vaX11uVm57me/1N8otNmzMMnsE+f0U3/Hi9TCPbnvZM=
X-Endpoint-Received: by B4 Relay for joe@sudmix.de/default with auth_id=1151
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The GSP's interrupt handler takes every pending interrupt the RISC-V
IRQMASK enables as its own, without looking at IRQDEST, which says
whether an interrupt goes to the host or to the GSP itself. One that
belongs to GSP-RM, pending when the host's handler runs for the message
queue, is reported as unknown, cleared and masked off with IRQMCLR,
taking it away from the firmware:

  nouveau 0000:01:00.0: gsp: intr 00040000

NVIDIA's driver reads the interrupts routed to the host as
IRQSTAT & IRQMASK & IRQDEST (kflcnRiscvReadIntrStatus_TU102() and
_GA102()). Do the same, with IRQDEST from NVIDIA's register headers
next to IRQMASK on each falcon.

Seen once in a few boots on an RTX 3070 Ti (GA104, GSP-RM 570.144),
before the login prompt. There IRQMASK reads 0x01049042 and IRQDEST
0x01000040: 0x00040000 is enabled but routed to the GSP.

Fixes: 830531e94712 ("drm/nouveau/gsp/r535: add interrupt handling")
Cc: stable@vger.kernel.org
Signed-off-by: Joe Finzel <joe@sudmix.de>
---
 drivers/gpu/drm/nouveau/include/nvkm/engine/falcon.h  | 1 +
 drivers/gpu/drm/nouveau/nvkm/subdev/gsp/ga100.c       | 1 +
 drivers/gpu/drm/nouveau/nvkm/subdev/gsp/ga102.c       | 1 +
 drivers/gpu/drm/nouveau/nvkm/subdev/gsp/rm/r535/gsp.c | 4 +++-
 drivers/gpu/drm/nouveau/nvkm/subdev/gsp/tu102.c       | 1 +
 5 files changed, 7 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/nouveau/include/nvkm/engine/falcon.h b/drivers/gpu/drm/nouveau/include/nvkm/engine/falcon.h
index 341f133dc38..eb8adaf07fe 100644
--- a/drivers/gpu/drm/nouveau/include/nvkm/engine/falcon.h
+++ b/drivers/gpu/drm/nouveau/include/nvkm/engine/falcon.h
@@ -63,6 +63,7 @@ struct nvkm_falcon_func {
 	int (*select)(struct nvkm_falcon *);
 	u32 addr2;
 	u32 riscv_irqmask;
+	u32 riscv_irqdest;
 	bool reset_pmc;
 	int (*reset_eng)(struct nvkm_falcon *);
 	int (*reset_prep)(struct nvkm_falcon *);
diff --git a/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/ga100.c b/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/ga100.c
index d5126fe39d2..10e2813a016 100644
--- a/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/ga100.c
+++ b/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/ga100.c
@@ -27,6 +27,7 @@ ga100_gsp_flcn = {
 	.enable = gm200_flcn_enable,
 	.addr2 = 0x1000,
 	.riscv_irqmask = 0x2b4,
+	.riscv_irqdest = 0x2b8,
 	.reset_eng = gp102_flcn_reset_eng,
 	.reset_wait_mem_scrubbing = gm200_flcn_reset_wait_mem_scrubbing,
 	.bind_inst = gm200_flcn_bind_inst,
diff --git a/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/ga102.c b/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/ga102.c
index b6b3eb6f4c0..96fa26fa612 100644
--- a/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/ga102.c
+++ b/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/ga102.c
@@ -140,6 +140,7 @@ ga102_gsp_flcn = {
 	.select = ga102_flcn_select,
 	.addr2 = 0x1000,
 	.riscv_irqmask = 0x528,
+	.riscv_irqdest = 0x52c,
 	.reset_eng = gp102_flcn_reset_eng,
 	.reset_prep = ga102_flcn_reset_prep,
 	.reset_wait_mem_scrubbing = ga102_flcn_reset_wait_mem_scrubbing,
diff --git a/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/rm/r535/gsp.c b/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/rm/r535/gsp.c
index 94925f1590e..463e463db24 100644
--- a/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/rm/r535/gsp.c
+++ b/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/rm/r535/gsp.c
@@ -64,7 +64,9 @@ r535_gsp_intr(struct nvkm_inth *inth)
 	u32 intr = nvkm_falcon_rd32(&gsp->falcon, 0x0008);
 	u32 inte = nvkm_falcon_rd32(&gsp->falcon, gsp->falcon.func->addr2 +
 						  gsp->falcon.func->riscv_irqmask);
-	u32 stat = intr & inte;
+	u32 dest = nvkm_falcon_rd32(&gsp->falcon, gsp->falcon.func->addr2 +
+						  gsp->falcon.func->riscv_irqdest);
+	u32 stat = intr & inte & dest;
 
 	if (!stat) {
 		nvkm_debug(subdev, "inte %08x %08x\n", intr, inte);
diff --git a/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/tu102.c b/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/tu102.c
index 11a37963bd4..823532758af 100644
--- a/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/tu102.c
+++ b/drivers/gpu/drm/nouveau/nvkm/subdev/gsp/tu102.c
@@ -420,6 +420,7 @@ tu102_gsp_flcn = {
 	.enable = gm200_flcn_enable,
 	.addr2 = 0x1000,
 	.riscv_irqmask = 0x2b4,
+	.riscv_irqdest = 0x2b8,
 	.reset_eng = gp102_flcn_reset_eng,
 	.reset_wait_mem_scrubbing = gm200_flcn_reset_wait_mem_scrubbing,
 	.bind_inst = gm200_flcn_bind_inst,

---
base-commit: fb26cf4f1df40a462ea65552a3fbcc8cfafab523
change-id: 20261023-nouveau-gsp-irqdest-a0819d1eda96

Best regards,
-- 
Joe Finzel <joe@sudmix.de>

