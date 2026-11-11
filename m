From: Dave Airlie <airlied@redhat.com>
Date: Wed, 11 Nov 2026 16:00:05 +1000
Subject: [PATCH] drm/nouveau/disp: Set
 drm_mode_config_funcs.atomic_(check|commit) (attempt 2)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-nouveau-atomic-fix-v1-1-118e65d3a2f5@redhat.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQqAIBBFrxKzbsAkNLpKtBCbahZpaEUg3r2ht
 3sP/i+QKTFlGJsCiR7OHINI1zbgdxc2Ql7EQSttOgFDvB9yN7orHuxx5RdtbwdtlCfjLMjwTCT
 5P53mWj9Sw/bMZAAAAA==
X-Change-ID: 20261111-nouveau-atomic-fix-7478260ce6a7
To: Lyude Paul <lyude@redhat.com>, Danilo Krummrich <dakr@kernel.org>, 
 David Airlie <airlied@gmail.com>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 Ruben Wauters <rubenru09@aol.com>, stable@vger.kernel.org, 
 Dave Airlie <airlied@redhat.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2247; i=airlied@redhat.com;
 h=from:subject:message-id; bh=3p4OPHHZOJWgpQuQJ5QnAg5qMkCUtFo/f/weNmlXOSk=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq9ARmdY8O0EEkMXRDfLn3actnKw4etDeyAV8x8
 HKJOrksjxmJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCavQEZgAKCRAMdPNZecSG
 vpwKD/4l9INlZa9aSAR5SckcwizWiw5H6zLQzoeImLwaKy+8n2gedhzzkX+PUHnmYZhnHVhK58D
 4TXaCaaLKqNSbG49F2EzNHi8S6kFnodZZVt1KNgCj9kyJEALImwsPYlJDDfcim92L1NTpg9J27L
 y9aUreEWmlfxoEBaf69hYwZRzgkx2GQK9qRduFvbXfD2O/TmU9yo0XtvMfOchvkmFqvhmrsEXzm
 7YQf8ogM5+5JK8CH/zBkXG6sikkjA0loZdNeOiFbtLu3pPwtX5wSIyhqGxSjTF9G9sEtDxPq99z
 R9wOuRuKqLl7zqRwwOnBcrUIk+mQVoihUPW9lPG+pOnfDR7i695sm4Ms8VmsNTpPGrbhqLd4wuK
 t148TuirypH6FSuP6hIPClTZQSlyVxFhS9wckmj7Jz96Xv3Vi/GGAfdqG0CYm1/0pg8y0Falhs6
 Hu01FdcGxNt2KKyejLEiUodh2Y5Vyw0CV55VRNAKgmT+5prKfexroeF0uVD9pe4XR1JuysFJ26Y
 BdYsOHE1nhrITGiNDbR0tBDJWwji/OxLrgokm1Eg6+9bUHzI+391vxC3ulv9cnAGdPy4vpHGiH6
 9VNBlcHeO93HhNi5tl3fpwONq+WFAbx85wvM45KC4Ql7C4S3y1Hgw8EBZrOv6xbVrQLxDgn/Mrp
 U3v3tPwh6US6jAQ==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

commit 604826acb3f5 attempted to add these flags but
commit 6c65db809796 reverted it due to it
failing on hw from pre-atomic times.

So use a second set of functions.

original commit msg from Lyude:
"Apparently we never actually filled these in, despite the fact that we do
in fact technically support atomic modesetting.

Since not having these filled in causes us to potentially forget to disable
fbdev and friends during suspend/resume, let's fix it."

Reported-by: Ruben Wauters <rubenru09@aol.com>
Closes: https://gitlab.freedesktop.org/drm/nouveau/-/work_items/517
Fixes: 6c65db809796 ("Revert "drm/nouveau/disp: Set drm_mode_config_funcs.atomic_(check|commit)")
Cc: stable@vger.kernel.org
Signed-off-by: Dave Airlie <airlied@redhat.com>
---
 drivers/gpu/drm/nouveau/nouveau_display.c | 11 ++++++++++-
 1 file changed, 10 insertions(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/nouveau/nouveau_display.c b/drivers/gpu/drm/nouveau/nouveau_display.c
index d71dcfc6ee66..07882624a7f6 100644
--- a/drivers/gpu/drm/nouveau/nouveau_display.c
+++ b/drivers/gpu/drm/nouveau/nouveau_display.c
@@ -354,6 +354,11 @@ static const struct drm_mode_config_funcs nouveau_mode_config_funcs = {
 	.fb_create = nouveau_user_framebuffer_create,
 };
 
+static const struct drm_mode_config_funcs nouveau_mode_config_funcs_atomic = {
+	.fb_create = nouveau_user_framebuffer_create,
+	.atomic_commit = drm_atomic_helper_commit,
+	.atomic_check = drm_atomic_helper_check,
+};
 
 struct nouveau_drm_prop_enum_list {
 	u8 gen_mask;
@@ -654,7 +659,11 @@ nouveau_display_create(struct drm_device *dev)
 	drm_mode_create_scaling_mode_property(dev);
 	drm_mode_create_dvi_i_properties(dev);
 
-	dev->mode_config.funcs = &nouveau_mode_config_funcs;
+	/* this only gets set if the driver has the ATOMIC flag */
+	if (drm_drv_uses_atomic_modeset(dev))
+		dev->mode_config.funcs = &nouveau_mode_config_funcs_atomic;
+	else
+		dev->mode_config.funcs = &nouveau_mode_config_funcs;
 
 	dev->mode_config.min_width = 0;
 	dev->mode_config.min_height = 0;

---
base-commit: 067c5c24cef23d913b67eaaf71ae67e7169a6620
change-id: 20261111-nouveau-atomic-fix-7478260ce6a7

Best regards,
-- 
Dave Airlie <airlied@redhat.com>

