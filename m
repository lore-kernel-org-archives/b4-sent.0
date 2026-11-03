From: "David R. Hedges" <linuxdev844@thelittleman.net>
Date: Tue, 03 Nov 2026 14:02:50 -0600
Subject: [PATCH 4/5] drm/nouveau/kms: cache the DP encoder after it has
 been attached
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-nouveau-dp-relink-v1-4-7ee88c7f1e8a@thelittleman.net>
References: <20261103-nouveau-dp-relink-v1-0-7ee88c7f1e8a@thelittleman.net>
In-Reply-To: <20261103-nouveau-dp-relink-v1-0-7ee88c7f1e8a@thelittleman.net>
To: Lyude Paul <lyude@redhat.com>, Danilo Krummrich <dakr@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Jani Nikula <jani.nikula@intel.com>, Ben Skeggs <bskeggs@nvidia.com>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, Danilo Krummrich <me@dakr.org>, 
 "David R. Hedges" <linuxdev844@thelittleman.net>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793736171; l=3184;
 i=linuxdev844@thelittleman.net; s=20261103; h=from:subject:message-id;
 bh=oxUnvWNMjr2Z6ZaQSslI9Xgy2BrHndjmNGwQkasaX3o=;
 b=Qp6JlCv2gZGBNz7xpy3nONrc81+mPG1Gr0q1jTZ8LlxSQXWfBIyaig2dPs1j6BC8ianfhaZSO
 Bq47JCpksfGBnxmUpMwf920vostAXMfJBFCBQjtFtBOkG7n7qVu8Ntk
X-Developer-Key: i=linuxdev844@thelittleman.net; a=ed25519;
 pk=Cynzuei/w0GLdh3LuNJdvH7aaszLrHSxY5UyujS7l+g=
X-Endpoint-Received: by B4 Relay for linuxdev844@thelittleman.net/20261103 with auth_id=1397
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

nouveau_connector_create() caches the connector's DP encoder in
nv_connector->dp_encoder using find_encoder().  On nv50+ it's called
from nv50_display_create() before nv50_sor_create() has created the
encoder and attached it to the connector, so possible_encoders is
still empty, find_encoder() returns NULL, and dp_encoder is never set.
Two things depend on it:

 - nouveau_dp_link_check(), which the HPD worker calls on IRQ_HPD,
   reports the link as fine without looking at it when there's no DP
   encoder.  Until commit 633716501c94 ("drm/nouveau/disp: add dp
   train method") it looked the encoder up each time; since then, a
   sink that reports link loss with IRQ_HPD hasn't been retrained.

 - nouveau_connector_atomic_check() has never called
   drm_dp_mst_root_conn_atomic_check() for MST-capable root
   connectors.

Set dp_encoder in nv50_sor_create() right after the SOR is attached to
the connector, and drop the assignment that can't succeed.  This also
covers eDP, whose SOR is a DCB_OUTPUT_DP encoder too.  On a GA102 with
GSP-RM 570.144, an IRQ_HPD now leads to a read of the sink's link
status, where before it produced no AUX traffic at all.

This depends on "drm/nouveau/kms/nv50-: reject DP modesets the link
can't carry" and "drm/nouveau/dp: restart lost links with a modeset on
GSP-RM".  Without them, enabling the link check would have nouveau
retrain active links in place on GSP-RM, or restart them with a mode
the link can no longer carry, either of which can hang the display
engine.  The MST atomic check this enables hasn't been tested.

Fixes: 11d2738940eb ("drm/nouveau/kms: Cache DP encoders in nouveau_connector")
Fixes: 633716501c94 ("drm/nouveau/disp: add dp train method")
Link: https://gitlab.freedesktop.org/drm/nouveau/-/work_items/515
Signed-off-by: David R. Hedges <linuxdev844@thelittleman.net>
---
 drivers/gpu/drm/nouveau/dispnv50/disp.c     | 1 +
 drivers/gpu/drm/nouveau/nouveau_connector.c | 2 --
 2 files changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/nouveau/dispnv50/disp.c b/drivers/gpu/drm/nouveau/dispnv50/disp.c
index 7f55c016d846..583368914bf0 100644
--- a/drivers/gpu/drm/nouveau/dispnv50/disp.c
+++ b/drivers/gpu/drm/nouveau/dispnv50/disp.c
@@ -1941,6 +1941,7 @@ nv50_sor_create(struct nouveau_encoder *nv_encoder)
 
 	if (dcbe->type == DCB_OUTPUT_DP) {
 		mutex_init(&nv_encoder->dp.hpd_irq_lock);
+		nv_connector->dp_encoder = nv_encoder;
 
 		if (disp->disp->object.oclass < GF110_DISP) {
 			/* HW has no support for address-only
diff --git a/drivers/gpu/drm/nouveau/nouveau_connector.c b/drivers/gpu/drm/nouveau/nouveau_connector.c
index cae4e35c30aa..845f284f3a20 100644
--- a/drivers/gpu/drm/nouveau/nouveau_connector.c
+++ b/drivers/gpu/drm/nouveau/nouveau_connector.c
@@ -1573,8 +1573,6 @@ nouveau_connector_create(struct drm_device *dev, int index)
 
 	switch (type) {
 	case DRM_MODE_CONNECTOR_DisplayPort:
-		nv_connector->dp_encoder = find_encoder(&nv_connector->base, DCB_OUTPUT_DP);
-		fallthrough;
 	case DRM_MODE_CONNECTOR_eDP:
 		drm_dp_cec_register_connector(&nv_connector->aux, connector);
 		break;

-- 
2.55.0

