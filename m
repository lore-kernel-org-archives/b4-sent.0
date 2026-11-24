From: Mahdi Salimi <mahdisalimikingmallo@gmail.com>
Date: Wed, 25 Nov 2026 00:28:42 +0330
Subject: [PATCH] drm/nouveau/fb/ramnv50: Fixed DDR2 reclocking on NV50
 architectures
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-ramnv50-ddr2-reclock-v1-1-64f046c1c95d@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/x3MUQrCMAwG4KuE/3mBtlLBXkV8qE02g9pJCkMYu
 7vgd4Bvx1A3HSi0w3WzYWtHoTgR2qP2RdkEhZBCOseYMnt99y0HFvHEru21tiffT6HVi2QVFUy
 Ej+ts3397vR3HD1iWqldmAAAA
X-Change-ID: 20261125-ramnv50-ddr2-reclock-b30ca9d5eded
To: Lyude Paul <lyude@redhat.com>, Danilo Krummrich <dakr@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 Jonathan Fouquart <jfouquart@hotmail.fr>, Karol Herbst <kherbst@redhat.com>, 
 Mahdi Salimi <mahdisalimikingmallo@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795553923; l=1573;
 i=mahdisalimikingmallo@gmail.com; s=20261125; h=from:subject:message-id;
 bh=1K/6Wu8e0J2XN3Xm9Hku5Ij7+tN+riEcZySH53+Mfuw=;
 b=CtKj6j0bbn9Ur2HFfZapsXTVU8AiohiH+Ee8Xyg1ckdaHO1RCinKAGomZD2IWX8esLRom+QH7
 NBCX01rpnBcDVPAmsvG9KWRpsmskn1efsZ/Qvx6sjQ1afCF3OtO0WaH
X-Developer-Key: i=mahdisalimikingmallo@gmail.com; a=ed25519;
 pk=kJgQkgLnEIBLRzYOU2pUvQKBck8dX2HvJdCy3M3tDoc=
X-Endpoint-Received: by B4 Relay for mahdisalimikingmallo@gmail.com/20261125 with auth_id=1631
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Jonathan Fouquart <jfouquart@hotmail.fr>

Call nvkm_sddr2_calc when calculating the DDR2 memory clock frequency on
NV50 architectures. With this change, there are no more errors when
reclocking, the DDR2 memory frequency is correctly calculated, and there
are a performance gain of around 30% on glxgears.

Signed-off-by: Jonathan Fouquart <jfouquart@hotmail.fr>
Reviewed-by: Karol Herbst <kherbst@redhat.com>
Link: https://gitlab.freedesktop.org/drm/nouveau/-/merge_requests/23
Tested-by: Mahdi Salimi <mahdisalimikingmallo@gmail.com>
Signed-off-by: Mahdi Salimi <mahdisalimikingmallo@gmail.com>
---
Forwarding Jonathan's reviewed patch from GitLab MR !23 as Lyude
requested. Tested on an NVIDIA G96 with DDR2 memory (reclocking works
without errors).
---
 drivers/gpu/drm/nouveau/nvkm/subdev/fb/ramnv50.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/gpu/drm/nouveau/nvkm/subdev/fb/ramnv50.c b/drivers/gpu/drm/nouveau/nvkm/subdev/fb/ramnv50.c
index be15519d0..d013a2fd2 100644
--- a/drivers/gpu/drm/nouveau/nvkm/subdev/fb/ramnv50.c
+++ b/drivers/gpu/drm/nouveau/nvkm/subdev/fb/ramnv50.c
@@ -288,6 +288,9 @@ nv50_ram_calc(struct nvkm_ram *base, u32 freq)
 	ram->base.mr[2] = ram_rd32(hwsq, mr[2]);
 
 	switch (ram->base.type) {
+	case NVKM_RAM_TYPE_DDR2:
+		ret = nvkm_sddr2_calc(&ram->base);
+		break;
 	case NVKM_RAM_TYPE_GDDR3:
 		ret = nvkm_gddr3_calc(&ram->base);
 		break;

---
base-commit: 8d7fe9885c62fc9a95bf55d9db244d9672a8aadc
change-id: 20261125-ramnv50-ddr2-reclock-b30ca9d5eded

Best regards,
-- 
Mahdi Salimi <mahdisalimikingmallo@gmail.com>

