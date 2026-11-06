From: Andrew Gigena <mail@andrewgigena.dev>
Date: Fri, 06 Nov 2026 18:35:36 +0000
Subject: [PATCH v3 4/7] media: qcom: camss: Match VFE lite clocks by name
 prefix
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-sm8150-v7.4-rc1-camss-v3-4-0103e8a0bbcd@andrewgigena.dev>
References: <20261106-sm8150-v7.4-rc1-camss-v3-0-0103e8a0bbcd@andrewgigena.dev>
In-Reply-To: <20261106-sm8150-v7.4-rc1-camss-v3-0-0103e8a0bbcd@andrewgigena.dev>
To: Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Robert Foss <rfoss@kernel.org>, Andi Shyti <andi.shyti@linaro.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bryan O'Donoghue <bod@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Andi Shyti <andi.shyti@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-i2c@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-phy@lists.infradead.org, 
 Andrew Gigena <mail@andrewgigena.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793990195; l=2177;
 i=mail@andrewgigena.dev; s=20261104; h=from:subject:message-id;
 bh=RKXBqJzp5jx1oO13mVy3JGt1LTgj4JwjvJ23lzdf2Vg=;
 b=pYp3wGGx24nx3RQs/uM68jjw91qjhA54KzVks5zInjKDvgsrjRK40Pq5jZGxUGXkWe0RqKT4s
 kFoiJZYWW+9DN1jzG0xNruH04CTSWPOBKwBxb5v1kw7COZqtwWWOPJE
X-Developer-Key: i=mail@andrewgigena.dev; a=ed25519;
 pk=OMhlYIBaOEC8g4mJ4JCKy7kbg+lrwRxuujieZF8Ne6U=
X-Endpoint-Received: by B4 Relay for mail@andrewgigena.dev/20261104 with auth_id=1402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

vfe_match_clock_names() builds the expected lite clock name from
vfe->id, but vfe->id is the index of the VFE in the resources array.
On SoCs where the lite VFEs come after the full VFEs, the generated
name is vfe_lite2, vfe_lite3, ... and never matches the actual
vfe_lite0/vfe_lite1 clocks, so their rates are never programmed.

Restrict the new prefix match to numbered "vfe_liteN" clocks (digit
check) to avoid matching aux clocks, leaving the pre-existing
vfe_lite_name and bare "vfe_lite" matches unchanged.

This affects SM8150, SC7280 and SC8280XP. On a Pixel 4 (SM8150),
streaming through VFE-lite0 left cam_cc_ife_lite_0_clk at 19.2 MHz and
failed with "VFE reset timeout".

Signed-off-by: Andrew Gigena <mail@andrewgigena.dev>
---
 drivers/media/platform/qcom/camss/camss-vfe.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/media/platform/qcom/camss/camss-vfe.c b/drivers/media/platform/qcom/camss/camss-vfe.c
index 2680a9914765..29e04d097116 100644
--- a/drivers/media/platform/qcom/camss/camss-vfe.c
+++ b/drivers/media/platform/qcom/camss/camss-vfe.c
@@ -9,6 +9,7 @@
  */
 #include <linux/clk.h>
 #include <linux/completion.h>
+#include <linux/ctype.h>
 #include <linux/interrupt.h>
 #include <linux/iommu.h>
 #include <linux/mutex.h>
@@ -346,6 +347,7 @@ static u32 vfe_src_pad_code(struct vfe_line *line, u32 sink_code,
 	case CAMSS_6350:
 	case CAMSS_7280:
 	case CAMSS_8x96:
+	case CAMSS_8150:
 	case CAMSS_8250:
 	case CAMSS_8280XP:
 	case CAMSS_8300:
@@ -914,6 +916,9 @@ static int vfe_match_clock_names(struct vfe_device *vfe,
 	return (!strcmp(clock->name, vfe_name) ||
 		!strcmp(clock->name, vfe_lite_name) ||
 		!strcmp(clock->name, "vfe_lite") ||
+		(vfe->res->is_lite &&
+		 !strncmp(clock->name, "vfe_lite", 8) &&
+		 isdigit((unsigned char)clock->name[8])) ||
 		!strcmp(clock->name, "camnoc_axi") ||
 		!strcmp(clock->name, "camnoc_rt_axi"));
 }
@@ -2006,6 +2011,7 @@ static int vfe_bpl_align_rdi(struct vfe_device *vfe)
 	case CAMSS_6150:
 	case CAMSS_6350:
 	case CAMSS_7280:
+	case CAMSS_8150:
 	case CAMSS_8250:
 	case CAMSS_8280XP:
 	case CAMSS_8300:

-- 
2.56.0

