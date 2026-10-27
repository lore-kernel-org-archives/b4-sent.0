From: Ishu Brar <patches@brar.si>
Date: Tue, 27 Oct 2026 12:44:36 +0530
Subject: [PATCH v4 3/5] drm/msm/a6xx: Factor out the common BCM list
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-adreno-a620-v4-3-b0095e028c76@brar.si>
References: <20261027-adreno-a620-v4-0-b0095e028c76@brar.si>
In-Reply-To: <20261027-adreno-a620-v4-0-b0095e028c76@brar.si>
To: Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 Akhil P Oommen <akhilpo@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Ishu Brar <patches@brar.si>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793085280; l=1585;
 i=patches@brar.si; h=from:subject:message-id;
 bh=XKW/3wqWkpV9U6TbTOCzER6M6DepQLoeu6Dsp0lQK/c=;
 b=UATGICwhaM+VynziqpGJXd7w/6gymuJoI6jp2/3+UMP9DFSIfAiz80ay6Wy1Qlgpb/S5LeJOc
 sgWf6JVakHeD6+ctr/tIPPG2fAZgpb7QaCrsG90mBchin3J3sgsJmnV
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The A690 entry carries a list of the Bus Clock Managers it votes for
(SH0, MC0 and ACV) which is the same for other A6xx GPUs. Move it to a
shared array so that more entries can refer to it instead of repeating
it.

No functional change.

Signed-off-by: Ishu Brar <patches@brar.si>
---
 drivers/gpu/drm/msm/adreno/a6xx_catalog.c | 22 ++++++++++++----------
 1 file changed, 12 insertions(+), 10 deletions(-)

diff --git a/drivers/gpu/drm/msm/adreno/a6xx_catalog.c b/drivers/gpu/drm/msm/adreno/a6xx_catalog.c
index 4ef2bd6e7ad2..c4d332f48f6f 100644
--- a/drivers/gpu/drm/msm/adreno/a6xx_catalog.c
+++ b/drivers/gpu/drm/msm/adreno/a6xx_catalog.c
@@ -736,6 +736,17 @@ static const struct adreno_reglist a702_hwcg[] = {
 	{}
 };
 
+static const struct a6xx_bcm a6xx_bcms[] = {
+	{ .name = "SH0", .buswidth = 16 },
+	{ .name = "MC0", .buswidth = 4 },
+	{
+		.name = "ACV",
+		.fixed = true,
+		.perfmode = BIT(3),
+	},
+	{ /* sentinel */ },
+};
+
 static const struct adreno_info a6xx_gpus[] = {
 	{
 		.chip_ids = ADRENO_CHIP_IDS(0x06010000),
@@ -985,16 +996,7 @@ static const struct adreno_info a6xx_gpus[] = {
 			.gbif_cx = a640_gbif,
 			.gmu_cgc_mode = 0x00020200,
 			.prim_fifo_threshold = 0x00010000,
-			.bcms = (const struct a6xx_bcm[]) {
-				{ .name = "SH0", .buswidth = 16 },
-				{ .name = "MC0", .buswidth = 4 },
-				{
-					.name = "ACV",
-					.fixed = true,
-					.perfmode = BIT(3),
-				},
-				{ /* sentinel */ },
-			},
+			.bcms = a6xx_bcms,
 		},
 		.speedbins = ADRENO_SPEEDBINS(
 			{ 0,   0 },

-- 
2.56.0

