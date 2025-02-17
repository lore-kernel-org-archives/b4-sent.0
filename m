From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 17 Feb 2025 17:43:18 -0600
Subject: [PATCH] drm/nouveau/pmu: Fix gp10b firmware guard
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250217-nouveau-gm10b-guard-v1-1-0d96f0068570@gmail.com>
X-B4-Tracking: v=1; b=H4sIAJXJs2cC/x2MQQqAIBAAvxJ7bkG3ougr0cFqsz2koRiB9Pek4
 8DMZIgchCOMVYbAt0TxroCuK1gP4yyjbIWBFHWKdI/Op5tNQntqtaBNJmxo2mZoFS3FICjlFXi
 X579O8/t+8YEsT2UAAAA=
X-Change-ID: 20250217-nouveau-gm10b-guard-a438402b5022
To: Karol Herbst <kherbst@redhat.com>, Lyude Paul <lyude@redhat.com>, 
 Danilo Krummrich <dakr@kernel.org>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, Ben Skeggs <bskeggs@redhat.com>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739835804; l=1102;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=f8lb6sJV/0LlAIwBP7HgEJtH0QjoGFU98w+WZTb7n3A=;
 b=zrOqogMmtS+s+z9c0ZTFVovU04FHtGu75y4ymeQgMVFlFom3ckutTmS40FWLi5r9k/jjJ/PqW
 4EB3YkQumtdAcdfBGN24IIENroYNuD0HoEuQDww+AyIotTJtZzd7JP0
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fixes: 989863d7cbe5 ("drm/nouveau/pmu: select implementation based on available firmware")
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/gpu/drm/nouveau/nvkm/subdev/pmu/gp10b.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/nouveau/nvkm/subdev/pmu/gp10b.c b/drivers/gpu/drm/nouveau/nvkm/subdev/pmu/gp10b.c
index a6f410ba60bc94ec9d52fc78868acddfc6770e19..d393bc540f8628812990dffe4c2f7e9014be07c5 100644
--- a/drivers/gpu/drm/nouveau/nvkm/subdev/pmu/gp10b.c
+++ b/drivers/gpu/drm/nouveau/nvkm/subdev/pmu/gp10b.c
@@ -75,7 +75,7 @@ gp10b_pmu_acr = {
 	.bootstrap_multiple_falcons = gp10b_pmu_acr_bootstrap_multiple_falcons,
 };
 
-#if IS_ENABLED(CONFIG_ARCH_TEGRA_210_SOC)
+#if IS_ENABLED(CONFIG_ARCH_TEGRA_186_SOC)
 MODULE_FIRMWARE("nvidia/gp10b/pmu/desc.bin");
 MODULE_FIRMWARE("nvidia/gp10b/pmu/image.bin");
 MODULE_FIRMWARE("nvidia/gp10b/pmu/sig.bin");

---
base-commit: 2408a807bfc3f738850ef5ad5e3fd59d66168996
change-id: 20250217-nouveau-gm10b-guard-a438402b5022

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

