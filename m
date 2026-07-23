From: Vincent Jardin <vjardin@free.fr>
Date: Fri, 24 Jul 2026 00:56:33 +0200
Subject: [PATCH] bus: fsl-mc: set dma_mask for the root DPRC device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260724-for-upstream-fsl-mc-dprc-dma-mask-v1-1-6f08af883195@free.fr>
X-B4-Tracking: v=1; b=H4sIACCcYmoC/x2NQQqDMBAAvyJ77oIJaqVfKT0scaNLjYZdLQXx7
 wYvA3OZOcBYhQ1e1QHKPzFZlyLuUUGYaBkZZSgOvvZd/fQNxlVxz7YpU8JoM6aAQ9aCRJjIvkj
 OcRNa6tvQQelk5Sj/+/H+nOcFc1VD13MAAAA=
To: Ioana Ciornei <ioana.ciornei@nxp.com>, 
 Laurentiu Tudor <laurentiu.tudor@nxp.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Bogdan Purcareata <bogdan.purcareata@nxp.com>, 
 Stuart Yoder <stuyoder@gmail.com>
Cc: linuxppc-dev@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784847396; l=1926;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=50GoUATjGzTOE04DbAm6nufTMWrQbESmgDWMsefMpuA=;
 b=G/rIzE9Z00+txF2HsSaVork5JjXa/HUmU6sdGAwS5CqDVJ6ty4/eAcaTlKHYt1XIHo88cbx2+
 Nuyh+327K58ARkUaktB2yx8+DxrMdXge7fCpWfQhMqc+N9kvE0hHKP+
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On Layerscape platforms, when SMMU is disabled,
fsl_mc_device_add() leads to the DPRC device with a NULL dma_mask.

It has been tested on LX2160A, no SMMU on the MC
domain: the root DPRC can probe cleanly and fsl_mc children
enumerate.

Fixes: a259ed1618d2 ("bus/fsl-mc: support dma configure for devices on fsl-mc bus")
Cc: stable@vger.kernel.org
Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
fsl_mc_device_add() already seeds a default dma_mask for non-DPRC
objects, but never for the DPRC devices themselves. When the MC I/O
domain is not behind an SMMU, the root DPRC reaches
fsl_mc_dma_configure() -> of_dma_configure_id() with a NULL dma_mask
and the probe warns "DMA mask not set". This mirrors the existing
non-DPRC seeding into the DPRC branch.

Tested on LX2160A with no SMMU on the MC domain: the root DPRC probes
cleanly and its fsl_mc children enumerate.
---
 drivers/bus/fsl-mc/fsl-mc-bus.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/bus/fsl-mc/fsl-mc-bus.c b/drivers/bus/fsl-mc/fsl-mc-bus.c
index 64d75eed0d34..585345ac0179 100644
--- a/drivers/bus/fsl-mc/fsl-mc-bus.c
+++ b/drivers/bus/fsl-mc/fsl-mc-bus.c
@@ -832,6 +832,14 @@ int fsl_mc_device_add(struct fsl_mc_obj_desc *obj_desc,
 		error = get_dprc_icid(mc_io2, obj_desc->id, &mc_dev->icid);
 		if (error < 0)
 			goto error_cleanup_dev;
+
+		/*
+		 * Seed dma_mask so platforms without an SMMU don't complain
+		 * with "DMA mask not set" in of_dma_configure_id().
+		 */
+		mc_dev->dma_mask = FSL_MC_DEFAULT_DMA_MASK;
+		mc_dev->dev.dma_mask = &mc_dev->dma_mask;
+		mc_dev->dev.coherent_dma_mask = mc_dev->dma_mask;
 	} else {
 		/*
 		 * A non-DPRC object has to be a child of a DPRC, use the

---
base-commit: 248951ddc14de84de3910f9b13f51491a8cd91df
change-id: 20260724-for-upstream-fsl-mc-dprc-dma-mask-a11e4c5a85c6

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

