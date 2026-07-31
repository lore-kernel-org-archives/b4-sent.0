From: Vincent Jardin <vjardin@free.fr>
Date: Fri, 31 Jul 2026 22:13:49 +0200
Subject: [PATCH v2] bus: fsl-mc: set dma_mask for the DPRC devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-for-upstream-fsl-mc-dprc-dma-mask-v2-1-ea7058b90f06@free.fr>
X-B4-Tracking: v=1; b=H4sIAPwBbWoC/5WNQQ6CMBBFr0K6dgytgNWV9zAsJmVGGq2QGSQaw
 t2t3MDNT95fvLcYJYmk5lwsRmiOGodnBrcrTOjxeSOIXWbjSteUR1cBDwKvUSchTMD6gBSgGyV
 PQkiod0BrqQo1+jo0JntGIY7vrXFtM/dRp0E+W3K2v/cf+2zBQsOlR/b+YE/1hYVoz2LadV2/T
 aCMfdAAAAA=
To: Ioana Ciornei <ioana.ciornei@nxp.com>, 
 Laurentiu Tudor <laurentiu.tudor@nxp.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Bogdan Purcareata <bogdan.purcareata@nxp.com>, 
 Stuart Yoder <stuyoder@gmail.com>
Cc: linuxppc-dev@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785528840; l=2029;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=/JgIuzk3o1PHWS1podI6fxXs27SOl31EINS/+13QNvo=;
 b=zRdg1GZ1k6eyCaLcZYjSK3rD0C+hdoDwi4Gzv+yyomtGy2KFjWOYAfnZ6R0vpkdgMMm5mEoGR
 1Rruc7+riHYDjqQ0xFNt1dwPRdvCD7vablyWHVgNu2i4NxNeqA2sI1C
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On Layerscape platforms when SMMU is disabled by ATF, the root DPRC probes
with its dma_mask pointer unset which leads to a notification:
  "DMA mask not set"
so the device is left with a zero DMA mask instead of a sane default.

Let's seed the masks for all cases.

It was tested on LX2160A with no SMMU on the MC domain: the warning is gone
and the DPAA2 children probe unchanged.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
fsl_mc_device_add() already seeds a default dma_mask for non-DPRC
objects, but never for the DPRC devices themselves.

It was tested on LX2160A, SMMU disabled.
---
Changes in v2:
- seed the masks in the common path (Thanks Ioana)
- rewrite the commit log, drop Fixes: and Cc: stable
- Link to v1: https://lore.kernel.org/r/20260724-for-upstream-fsl-mc-dprc-dma-mask-v1-1-6f08af883195@free.fr
---
 drivers/bus/fsl-mc/fsl-mc-bus.c | 7 ++++---
 1 file changed, 4 insertions(+), 3 deletions(-)

diff --git a/drivers/bus/fsl-mc/fsl-mc-bus.c b/drivers/bus/fsl-mc/fsl-mc-bus.c
index 64d75eed0d34..35f480aa317b 100644
--- a/drivers/bus/fsl-mc/fsl-mc-bus.c
+++ b/drivers/bus/fsl-mc/fsl-mc-bus.c
@@ -797,6 +797,10 @@ int fsl_mc_device_add(struct fsl_mc_obj_desc *obj_desc,
 	}
 	dev_set_name(&mc_dev->dev, "%s.%d", obj_desc->type, obj_desc->id);
 
+	mc_dev->dma_mask = FSL_MC_DEFAULT_DMA_MASK;
+	mc_dev->dev.dma_mask = &mc_dev->dma_mask;
+	mc_dev->dev.coherent_dma_mask = mc_dev->dma_mask;
+
 	if (strcmp(obj_desc->type, "dprc") == 0) {
 		struct fsl_mc_io *mc_io2;
 
@@ -838,9 +842,6 @@ int fsl_mc_device_add(struct fsl_mc_obj_desc *obj_desc,
 		 * parent's ICID.
 		 */
 		mc_dev->icid = parent_mc_dev->icid;
-		mc_dev->dma_mask = FSL_MC_DEFAULT_DMA_MASK;
-		mc_dev->dev.dma_mask = &mc_dev->dma_mask;
-		mc_dev->dev.coherent_dma_mask = mc_dev->dma_mask;
 	}
 
 	/*

---
base-commit: 248951ddc14de84de3910f9b13f51491a8cd91df
change-id: 20260724-for-upstream-fsl-mc-dprc-dma-mask-a11e4c5a85c6

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

