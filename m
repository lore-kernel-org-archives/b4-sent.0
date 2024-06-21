From: George Chan <gchan9527@gmail.com>
Date: Fri, 21 Jun 2024 17:40:56 +0800
Subject: [PATCH 4/6] media: qcom: camss: Add sc7180 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240621-b4-sc7180-camss-v1-4-14937929f30e@gmail.com>
References: <20240621-b4-sc7180-camss-v1-0-14937929f30e@gmail.com>
In-Reply-To: <20240621-b4-sc7180-camss-v1-0-14937929f30e@gmail.com>
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, cros-qcom-dts-watchers@chromium.org, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>
Cc: linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Chan <gchan9527@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718962855; l=2308;
 i=gchan9527@gmail.com; s=20240621; h=from:subject:message-id;
 bh=YnPxfplUpyI7adL5KPtpIXi5NQhvsVScDtSlkhPHhXI=;
 b=6N0QHkttcoYSS5SQ1fZKQ/9yXpFF+i4jfnyxFZ/YNyQ7zNoXbFOCVAxMHQm5FCGJtRgJI6iC/
 LYsmZIaJH8pBbe6sVnNlv7yrOh1pHN56UuFSW8GTBg9UZ33wu+ZamU6
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=Ac2fkTqgUBlj2sns9hRIWJTYhWHO1BsmHbdBb5UpUUY=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20240621 with auth_id=176
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add in functional logic throughout the code to support the sc7180.

Signed-off-by: George Chan <gchan9527@gmail.com>
---
 drivers/media/platform/qcom/camss/camss-csiphy.c | 1 +
 drivers/media/platform/qcom/camss/camss-vfe.c    | 3 +++
 drivers/media/platform/qcom/camss/camss-video.c  | 1 +
 3 files changed, 5 insertions(+)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy.c b/drivers/media/platform/qcom/camss/camss-csiphy.c
index 45b3a8e5dea4..1fb08b5ee01b 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy.c
@@ -577,6 +577,7 @@ int msm_csiphy_subdev_init(struct camss *camss,
 		csiphy->nformats = ARRAY_SIZE(csiphy_formats_8x96);
 		break;
 	case CAMSS_845:
+	case CAMSS_7180:
 	case CAMSS_8250:
 	case CAMSS_8280XP:
 		csiphy->formats = csiphy_formats_sdm845;
diff --git a/drivers/media/platform/qcom/camss/camss-vfe.c b/drivers/media/platform/qcom/camss/camss-vfe.c
index d875237cf244..05fa1adc1661 100644
--- a/drivers/media/platform/qcom/camss/camss-vfe.c
+++ b/drivers/media/platform/qcom/camss/camss-vfe.c
@@ -224,6 +224,7 @@ static u32 vfe_src_pad_code(struct vfe_line *line, u32 sink_code,
 	case CAMSS_8x96:
 	case CAMSS_660:
 	case CAMSS_845:
+	case CAMSS_7180:
 	case CAMSS_8250:
 	case CAMSS_8280XP:
 		switch (sink_code) {
@@ -1518,6 +1519,7 @@ int msm_vfe_subdev_init(struct camss *camss, struct vfe_device *vfe,
 			}
 			break;
 		case CAMSS_845:
+		case CAMSS_7180:
 		case CAMSS_8250:
 		case CAMSS_8280XP:
 			l->formats = formats_rdi_845;
@@ -1603,6 +1605,7 @@ static int vfe_bpl_align(struct vfe_device *vfe)
 
 	switch (vfe->camss->res->version) {
 	case CAMSS_845:
+	case CAMSS_7180:
 	case CAMSS_8250:
 	case CAMSS_8280XP:
 		ret = 16;
diff --git a/drivers/media/platform/qcom/camss/camss-video.c b/drivers/media/platform/qcom/camss/camss-video.c
index 54cd82f74115..5b7f3fba938c 100644
--- a/drivers/media/platform/qcom/camss/camss-video.c
+++ b/drivers/media/platform/qcom/camss/camss-video.c
@@ -1027,6 +1027,7 @@ int msm_video_register(struct camss_video *video, struct v4l2_device *v4l2_dev,
 		}
 		break;
 	case CAMSS_845:
+	case CAMSS_7180:
 	case CAMSS_8250:
 	case CAMSS_8280XP:
 		video->formats = formats_rdi_845;

-- 
2.34.1

