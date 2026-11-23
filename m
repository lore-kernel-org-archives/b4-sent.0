From: Dave Airlie <airlied@redhat.com>
Date: Mon, 23 Nov 2026 10:25:26 +1000
Subject: [PATCH] drm/nouveau/devinit/gf100-: fix double vbios init checks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-nouveau-fix-disp-v1-1-ebdc525287ce@redhat.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQqAIBAAvyJ7biGNBPtKdJBcay8qihGIf086D
 sNMg0KZqcAmGmR6uHAMA+Qk4LxtuAjZDQY1Ky2lWjDE+pCt6PlFxyWhVn413hntiWBkKdNw/3I
 /ev8Aaxn27mIAAAA=
X-Change-ID: 20261123-nouveau-fix-disp-62f59fd96fee
To: Lyude Paul <lyude@redhat.com>, Danilo Krummrich <dakr@kernel.org>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 Dave Airlie <airlied@redhat.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1444; i=airlied@redhat.com;
 h=from:subject:message-id; bh=fLgUkfu8VDBsHKAcmadqaVH0gSOhunpVuhNXOsf7LQ0=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBrA4f4Li9p2SfqLVkMRYpuSKzNDxRgsYBBuKP6r
 yBJoSLEYqqJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCawOH+AAKCRAMdPNZecSG
 vtJUEACnc96+K4mI4B03aLzxP3BEnCThCmG7zw4qa85DUJtAyA0go0Tklhwt4lkU7b6UQMTt4Vh
 g2AFJzUNF2h8874mF91QgkbVP601i4jXjboTZX6l0FcGYj479/LIwaWgkah1CEGC/VOLv7ZwLyN
 GT315QlkK97hwrc8K2YmKLj9fqO8Fk4fNg+EQZJSg5ipS2akDolnKW+267Yugu9M4n2Jwhol6IF
 7U23DJyqNq7XvLww2quVo1Jd6/La0NZbaihOeo9Z476Y7o3Ns43ZEEnxPAFhC2KgI2g0qM8ge/k
 1puseARHoo/x0hg86LahzQCI8brwk9NOwXufCISXCvU9gizPY4WP/XewKFDw2w/BYMqKNfMJgLm
 gK/CffNVkrl3g13YFWZp+6LaLBrT2C7YKc9o6uUcTs3cmILZ/JvGVC9fne+TDtQDFP5l0qEtfsw
 O00LVRmsU7utMy5/R2f7XkuTo/bQ3bKpW9GDOuShsq8LsCPLUth8xorDn7UH60J3Vt1Pnm3yqJx
 sBycnRlMO9HpJPDARAKEf0IQIzWRDcOWfId7FX0TNgcvdD+K+qqixjw5aoZADi+xpFj4z5VKqi5
 GMb90cCLJyRNS8Tm0Z9cmxzIl70mA4RLAeau+1N7rmuCQAdt60OWeO6dRsiF8sIecKL+UkXbGaY
 TUUJE1ZfqkRcjbQ==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The initial fix from 2017 wasn't updated for modern nouveau devinit
disable paths.

Fix that and just check if display exists instead.

Fixes: 2139cb633d48 ("drm/nouveau/devinit/gf100-: try to avoid double-running vbios scripts")
Signed-off-by: Dave Airlie <airlied@redhat.com>
---
 drivers/gpu/drm/nouveau/nvkm/subdev/devinit/gf100.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/nouveau/nvkm/subdev/devinit/gf100.c b/drivers/gpu/drm/nouveau/nvkm/subdev/devinit/gf100.c
index 186e09ea0cb1..b256404c2454 100644
--- a/drivers/gpu/drm/nouveau/nvkm/subdev/devinit/gf100.c
+++ b/drivers/gpu/drm/nouveau/nvkm/subdev/devinit/gf100.c
@@ -107,12 +107,12 @@ gf100_devinit_preinit(struct nvkm_devinit *base)
 	 * VBIOS multiple times may have detrimental effects.
 	 */
 	if (base->post) {
-		u64 disable = nvkm_devinit_disable(base);
+		nvkm_devinit_disable(base);
 		/* magic to detect whether or not x86 vbios code has
 		 * executed the devinit scripts to initialise the
 		 * board. only works if there's a display engine.
 		 */
-		if (!(disable & (1ULL << NVKM_ENGINE_DISP))) {
+		if (device->disp) {
 			if (nvkm_rdvgac(device, 0, 0x00) ||
 			    nvkm_rdvgac(device, 0, 0x1a)) {
 				base->post = false;

---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261123-nouveau-fix-disp-62f59fd96fee

Best regards,
-- 
Dave Airlie <airlied@redhat.com>

