From: Markuss Broks <markuss.broks@gmail.com>
Date: Mon, 03 Aug 2026 12:35:20 +0300
Subject: [PATCH] drm/panfrost: add Mali-G68 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260803-staging-mainline-v1-1-5071dc782149@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBG4auQWduktkDQqxgWLf7WMTqaDhASw
 t2tsvwW762kyAylc7VSxszKbyk4Hioa7kESDF+LyVnX2s56o2NILMm8AsuTBQYR3ampfWy9o5J
 9Mm68/JeXfrdO8YFh/H1o276AUGJddAAAAA==
X-Change-ID: 20260803-staging-mainline-ebe89543b632
To: Boris Brezillon <boris.brezillon@collabora.com>, 
 Rob Herring <robh@kernel.org>, Steven Price <steven.price@arm.com>, 
 =?utf-8?q?Adri=C3=A1n_Larumbe?= <adrian.larumbe@collabora.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 Markuss Broks <markuss.broks@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785749721; l=2284;
 i=markuss.broks@gmail.com; s=20260803; h=from:subject:message-id;
 bh=zQVxjMJtITy41A+IcC52/FUWFw7jC+G0clbf2HLVuYM=;
 b=fvHu/gkWgO0W0WtruK/CG5K4YBiMRZZckWUWdyak5vKrg0BS2uBKssba19WFr1IG1XczflJjL
 uILvCc8Wf4aA/3q6+8GLRgj5IgqTY6hg4qoSMtqGanz9XaM4OhXSMRo
X-Developer-Key: i=markuss.broks@gmail.com; a=ed25519;
 pk=oKzGUTm30BCDqinRMpiHQqByOx1mp2mwmhg80Mv7Zg4=
X-Endpoint-Received: by B4 Relay for markuss.broks@gmail.com/20260803 with auth_id=911
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the features, issues, and ID for Mali-G68, a first-generation
(v9) Valhall GPU.
Tested on Exynos8835: the GPU reports GPU_ID 0x9204 (G68 r1p1).

Signed-off-by: Markuss Broks <markuss.broks@gmail.com>
---
 drivers/gpu/drm/panfrost/panfrost_features.h | 2 ++
 drivers/gpu/drm/panfrost/panfrost_gpu.c      | 3 +++
 drivers/gpu/drm/panfrost/panfrost_issues.h   | 8 ++++++++
 3 files changed, 13 insertions(+)

diff --git a/drivers/gpu/drm/panfrost/panfrost_features.h b/drivers/gpu/drm/panfrost/panfrost_features.h
index 52f9d69f6db9..34c65847192f 100644
--- a/drivers/gpu/drm/panfrost/panfrost_features.h
+++ b/drivers/gpu/drm/panfrost/panfrost_features.h
@@ -121,6 +121,8 @@ enum panfrost_hw_feature {
 	BIT_ULL(HW_FEATURE_IDVS_GROUP_SIZE) | \
 	BIT_ULL(HW_FEATURE_CLEAN_ONLY_SAFE))
 
+#define hw_features_g68 hw_features_g57
+
 static inline bool panfrost_has_hw_feature(struct panfrost_device *pfdev,
 					   enum panfrost_hw_feature feat)
 {
diff --git a/drivers/gpu/drm/panfrost/panfrost_gpu.c b/drivers/gpu/drm/panfrost/panfrost_gpu.c
index 7d555e63e21a..83223192a544 100644
--- a/drivers/gpu/drm/panfrost/panfrost_gpu.c
+++ b/drivers/gpu/drm/panfrost/panfrost_gpu.c
@@ -242,6 +242,9 @@ static const struct panfrost_model gpu_models[] = {
 	/* MediaTek MT8188 Mali-G57 MC3 */
 	GPU_MODEL(g57, 0x9093,
 		GPU_REV(g57, 0, 0)),
+
+	GPU_MODEL(g68, 0x9004,
+		GPU_REV(g68, 1, 0), GPU_REV(g68, 1, 1)),
 	{0},
 };
 
diff --git a/drivers/gpu/drm/panfrost/panfrost_issues.h b/drivers/gpu/drm/panfrost/panfrost_issues.h
index eb60cb83667a..dd39946bb572 100644
--- a/drivers/gpu/drm/panfrost/panfrost_issues.h
+++ b/drivers/gpu/drm/panfrost/panfrost_issues.h
@@ -265,6 +265,14 @@ enum panfrost_hw_issue {
 #define hw_issues_g57_r0p0 (\
 	BIT_ULL(HW_ISSUE_TTRX_3485))
 
+#define hw_issues_g68 (\
+	BIT_ULL(HW_ISSUE_TTRX_2968_TTRX_3162))
+
+#define hw_issues_g68_r1p0 (\
+	BIT_ULL(HW_ISSUE_TTRX_3485))
+
+#define hw_issues_g68_r1p1 0
+
 static inline bool panfrost_has_hw_issue(const struct panfrost_device *pfdev,
 					 enum panfrost_hw_issue issue)
 {

---
base-commit: 415606a7be939835db9b0d6b711887586646346d
change-id: 20260803-staging-mainline-ebe89543b632

Best regards,
--  
Markuss Broks <markuss.broks@gmail.com>

