From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Fri, 27 Nov 2026 21:26:25 +0100
Subject: [PATCH 2/5] media: qcom: camss: vfe: match numbered vfe_liteN
 clock names
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-camss-titan17x-fixes-v1-2-541ab39e5889@gmail.com>
References: <20261127-camss-titan17x-fixes-v1-0-541ab39e5889@gmail.com>
In-Reply-To: <20261127-camss-titan17x-fixes-v1-0-541ab39e5889@gmail.com>
To: Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Robert Foss <rfoss@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Andrey Konovalov <andrey.konovalov@linaro.org>, 
 Atanas Filipov <atanas.filipov@oss.qualcomm.com>, 
 Milen Mitkov <quic_mmitkov@quicinc.com>, 
 Gjorgji Rosikopulos <quic_grosikop@quicinc.com>
Cc: Mauro Carvalho Chehab <mchehab+huawei@kernel.org>, 
 linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795811183; l=3348;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=IGn2MissXaSamQTI986UKKW4wZmXGmc2R/DeWGFygtc=;
 b=JHiBPBmLyW/0sWrdZMUJc4q27EwzjTnxUfMkzGF5dLp8nZigPhOm0vLYYqCk7WGj90Rj5r/Kq
 AGs0TLVgfz8AeqqKJxz3fcyvxEmMoZJf0HtUYzjZz5y0gKv2Pzfa5d9
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On SoCs where VFE-Lite entries follow full VFE entries in vfe_res[]
(such as SC8280XP), vfe->id starts after the full VFEs while the
device clocks are named "vfe_lite0", "vfe_lite1", etc. Constructing
"vfe_lite%d" from vfe->id fails to match those clocks, causing
vfe_set_clock_rates() and vfe_check_clock_rates() to skip scaling
VFE-Lite core clocks.

Match any "vfe_lite<N>" clock name when vfe_is_lite(vfe) (without
matching auxiliary clocks like "vfe_lite_ahb") in
vfe_match_core_clock_name(), and reuse it from vfe_match_clock_names().

Fixes: 546e9ba08625 ("media: qcom: camss: clamp VFE clock rates to the highest level")
Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 drivers/media/platform/qcom/camss/camss-vfe.c | 44 ++++++++++++++-------------
 1 file changed, 23 insertions(+), 21 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-vfe.c b/drivers/media/platform/qcom/camss/camss-vfe.c
index 0d80e6f12274cbbb3c8f551a573fab2d482309ee..b5a8196c9145163dfa3ee1af549a4684901e2fa7 100644
--- a/drivers/media/platform/qcom/camss/camss-vfe.c
+++ b/drivers/media/platform/qcom/camss/camss-vfe.c
@@ -886,37 +886,39 @@ int vfe_pm_domain_on(struct vfe_device *vfe)
 	return 0;
 }
 
-static int vfe_match_clock_names(struct vfe_device *vfe,
-				 struct camss_clock *clock)
+static bool vfe_match_core_clock_name(struct vfe_device *vfe,
+				      struct camss_clock *clock)
 {
 	char vfe_name[7]; /* vfeXXX\0 */
-	char vfe_lite_name[12]; /* vfe_liteXXX\0 */
-	char vfe_areg_name[12]; /* vfeXXX_areg\0 */
+	unsigned int lite_idx;
 
 	snprintf(vfe_name, sizeof(vfe_name), "vfe%d", vfe->id);
-	snprintf(vfe_lite_name, sizeof(vfe_lite_name), "vfe_lite%d", vfe->id);
-	snprintf(vfe_areg_name, sizeof(vfe_areg_name), "vfe%d_areg", vfe->id);
 
-	return (!strcmp(clock->name, vfe_name) ||
-		!strcmp(clock->name, vfe_lite_name) ||
-		!strcmp(clock->name, vfe_areg_name) ||
-		!strcmp(clock->name, "vfe_lite") ||
-		!strcmp(clock->name, "camnoc_axi") ||
-		!strcmp(clock->name, "camnoc_rt_axi"));
+	if (!strcmp(clock->name, vfe_name) || !strcmp(clock->name, "vfe_lite"))
+		return true;
+
+	/*
+	 * VFE-Lite instances follow full VFEs in vfe_res[], so vfe->id does
+	 * not necessarily match the 0-based "vfe_liteN" clock suffix.
+	 */
+	if (vfe_is_lite(vfe) && !strncmp(clock->name, "vfe_lite", 8) &&
+	    !kstrtouint(clock->name + 8, 10, &lite_idx))
+		return true;
+
+	return false;
 }
 
-static bool vfe_match_core_clock_name(struct vfe_device *vfe,
-				      struct camss_clock *clock)
+static int vfe_match_clock_names(struct vfe_device *vfe,
+				 struct camss_clock *clock)
 {
-	char vfe_name[7]; /* vfeXXX\0 */
-	char vfe_lite_name[12]; /* vfe_liteXXX\0 */
+	char vfe_areg_name[12]; /* vfeXXX_areg\0 */
 
-	snprintf(vfe_name, sizeof(vfe_name), "vfe%d", vfe->id);
-	snprintf(vfe_lite_name, sizeof(vfe_lite_name), "vfe_lite%d", vfe->id);
+	snprintf(vfe_areg_name, sizeof(vfe_areg_name), "vfe%d_areg", vfe->id);
 
-	return (!strcmp(clock->name, vfe_name) ||
-		!strcmp(clock->name, vfe_lite_name) ||
-		!strcmp(clock->name, "vfe_lite"));
+	return (vfe_match_core_clock_name(vfe, clock) ||
+		!strcmp(clock->name, vfe_areg_name) ||
+		!strcmp(clock->name, "camnoc_axi") ||
+		!strcmp(clock->name, "camnoc_rt_axi"));
 }
 
 /*

-- 
2.47.3

