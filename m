From: Demeter Barna <me@fromdisposition.org>
Date: Thu, 05 Nov 2026 13:30:03 +0000
Subject: [PATCH 4/5] drm/msm/adreno: Add speedbins for A660 GPU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-b4-sm8350-gpu-v1-4-a7175cdd6512@fromdisposition.org>
References: <20261105-b4-sm8350-gpu-v1-0-a7175cdd6512@fromdisposition.org>
In-Reply-To: <20261105-b4-sm8350-gpu-v1-0-a7175cdd6512@fromdisposition.org>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Srinivas Kandagatla <srini@kernel.org>, 
 Rob Clark <robin.clark@oss.qualcomm.com>, Sean Paul <sean@poorly.run>, 
 Akhil P Oommen <akhilpo@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, Demeter Barna <me@fromdisposition.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793885419; l=1126;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=oTxpg/D+jgMPGwDowW4xu7/gXp7fpT5IY/GcQ0zhKx8=;
 b=GtKovN95UpCfH5qWyBuGsZ9za1/hCqHtLIDArXBKbwZbdw5gl9dUiN/Oe/pd1G3Hp2tGiyp7a
 4AUL0ZNm6tVDmNcNu2ff4xE54HicFA9S81wb4KHBOoCJwJB8mrSFmQy
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SM8350 GPU comes in speed bins, read from QFPROM 0x17b bits 7:5.
Qualcomm's GPU tables for this SoC give:

  fuse 1, 3:     up to 900 MHz
  fuse 0, 5, 7:  up to 840 MHz
  fuse 4:        up to 738 MHz

The levels below are the same in every bin. Map these fuse values to
speed bins 1, 0 and 2. An unknown fuse value falls back to speed bin 0.

Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
 drivers/gpu/drm/msm/adreno/a6xx_catalog.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/gpu/drm/msm/adreno/a6xx_catalog.c b/drivers/gpu/drm/msm/adreno/a6xx_catalog.c
index 4ef2bd6e7..f1ae9932d 100644
--- a/drivers/gpu/drm/msm/adreno/a6xx_catalog.c
+++ b/drivers/gpu/drm/msm/adreno/a6xx_catalog.c
@@ -1096,6 +1096,14 @@ static const struct adreno_info a6xx_gpus[] = {
 			.gmu_cgc_mode = 0x00020000,
 			.prim_fifo_threshold = 0x00300200,
 		},
+		.speedbins = ADRENO_SPEEDBINS(
+			{ 0, 0 },
+			{ 1, 1 },
+			{ 3, 1 },
+			{ 4, 2 },
+			{ 5, 0 },
+			{ 7, 0 },
+		),
 	}, {
 		.chip_ids = ADRENO_CHIP_IDS(0x06060300),
 		.family = ADRENO_6XX_GEN4,

-- 
2.53.0

