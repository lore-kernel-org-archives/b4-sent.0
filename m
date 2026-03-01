From: David Heidelberg <david@ixit.cz>
Date: Sun, 01 Mar 2026 01:51:23 +0100
Subject: [PATCH WIP v4 4/9] media: qcom: camss: Initialize lanes after lane
 configuration is available
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260301-qcom-cphy-v4-4-e53316d2cc65@ixit.cz>
References: <20260301-qcom-cphy-v4-0-e53316d2cc65@ixit.cz>
In-Reply-To: <20260301-qcom-cphy-v4-0-e53316d2cc65@ixit.cz>
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, Petr Hodina <phodina@protonmail.com>, 
 Casey Connolly <casey.connolly@linaro.org>, "Dr. Git" <drgitx@gmail.com>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Joel Selvaraj <foss@joelselvaraj.com>, Kieran Bingham <kbingham@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, linux-media@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3845; i=david@ixit.cz;
 h=from:subject:message-id; bh=POblRjXDkh18ym7OpzBorCGs1kZvG0b381or0ZV6l/s=;
 b=kA0DAAgBYAI/xNNJIHIByyZiAGmjjYig5aDT7OYPjWMZPx9Az51jCHsFYOQU3Ep85A3kPuij2
 okCMwQAAQgAHRYhBNd6Cc/u3Cu9U6cEdGACP8TTSSByBQJpo42IAAoJEGACP8TTSSBylZcP/11N
 xDps7Ztfm/Cxri/RxCzyQ3rkhcHTZjnWYm5dWSztfHEHWnPcE2WjlqGr1SOrt5aDcfCwa63XEwH
 QwlC24fs7silhmNbm1rEXWZV66/89QcJi7JncZY+ZxcP1tXjWgIFvbdF62y3YGYNasZ7KQMjp3/
 G6A7M0CacaWFXEHIVWCIH7KhLxsOHzKYaRxSFk3tO1KJz0z0OuZNTzls2gOYRTN+i1pip37qgk/
 zxtq/Pv1uCLsiVa9DHuktSD6JuTM3ZItUzkJsNXszZ70Ph8epeMSoaW6qBeg2BleqYOyM/sGlQf
 CY7Ox4LVPiytahyaASG31BfmBuAiCJe6CDYvBo+7IuwoV1b0fz/HaMZui6KD7dQb1w6tZq4QYvB
 0K7lNVWhbMHLjTAKDzIUhTtX2L8oyqkUdKfwwTeY52MAk9aQv1umhrxFkVNxEbRiY635P2ATgRZ
 3IoOa2iat7OroWbT/A1CFpCa9erjHc7k8ZdIGy0HoedyrLtAEBMPj2sO5ovw1lCBUJH1owE7xy7
 vSzJzYxhXELw5pNOC2rSTX3azgnBUMlch6PcJ/TypdrBD9y/HHxAMVbcubrZR7hPkKdSlQln3Hd
 /y/zjeWeJYh9R0yR4J8ew8qYIxsn/WpFEgmngi5DuXFAtVyTrw2RYydjSvZColpluU6JYxbHxvJ
 vFC7i
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Petr Hodina <phodina@protonmail.com>

The lanes must not be initialized before the driver has access to
the lane configuration, as it depends on whether D-PHY or C-PHY mode
is in use. Move the lane initialization to a later stage where the
configuration structures are available.

Signed-off-by: Petr Hodina <phodina@protonmail.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../platform/qcom/camss/camss-csiphy-3ph-1-0.c     | 91 ++++++++++++++--------
 1 file changed, 57 insertions(+), 34 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
index cf83c9e062b81..9748208107222 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
@@ -1048,6 +1048,62 @@ static int csiphy_lanes_enable(struct csiphy_device *csiphy,
 	u8 val;
 	int i;
 
+	switch (csiphy->camss->res->version) {
+	case CAMSS_845:
+		{
+			regs->lane_regs = &lane_regs_sdm845[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sdm845);
+		}
+		break;
+	case CAMSS_2290:
+	case CAMSS_6150:
+		{
+			regs->lane_regs = &lane_regs_qcm2290[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_qcm2290);
+		}
+		break;
+	case CAMSS_7280:
+	case CAMSS_8250:
+		{
+			regs->lane_regs = &lane_regs_sm8250[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sm8250);
+		}
+		break;
+	case CAMSS_8280XP:
+		{
+			regs->lane_regs = &lane_regs_sc8280xp[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sc8280xp);
+		}
+		break;
+	case CAMSS_X1E80100:
+		{
+			regs->lane_regs = &lane_regs_x1e80100[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_x1e80100);
+		}
+		break;
+	case CAMSS_8550:
+		{
+			regs->lane_regs = &lane_regs_sm8550[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sm8550);
+		}
+		break;
+	case CAMSS_8650:
+		{
+			regs->lane_regs = &lane_regs_sm8650[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sm8650);
+		}
+		break;
+	case CAMSS_8300:
+	case CAMSS_8775P:
+		{
+			regs->lane_regs = &lane_regs_sa8775p[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sa8775p);
+		}
+		break;
+	default:
+		break;
+	}
+
 	settle_cnt = csiphy_settle_cnt_calc(link_freq, csiphy->timer_clk_rate);
 
 	val = 0;
@@ -1119,49 +1175,16 @@ static int csiphy_init(struct csiphy_device *csiphy)
 		return -ENOMEM;
 
 	csiphy->regs = regs;
-	regs->offset = 0x800;
 	regs->common_status_offset = 0xb0;
 
 	switch (csiphy->camss->res->version) {
-	case CAMSS_845:
-		regs->lane_regs = &lane_regs_sdm845[0];
-		regs->lane_array_size = ARRAY_SIZE(lane_regs_sdm845);
-		break;
-	case CAMSS_2290:
-	case CAMSS_6150:
-		regs->lane_regs = &lane_regs_qcm2290[0];
-		regs->lane_array_size = ARRAY_SIZE(lane_regs_qcm2290);
-		break;
-	case CAMSS_7280:
-	case CAMSS_8250:
-		regs->lane_regs = &lane_regs_sm8250[0];
-		regs->lane_array_size = ARRAY_SIZE(lane_regs_sm8250);
-		break;
-	case CAMSS_8280XP:
-		regs->lane_regs = &lane_regs_sc8280xp[0];
-		regs->lane_array_size = ARRAY_SIZE(lane_regs_sc8280xp);
-		break;
 	case CAMSS_X1E80100:
-		regs->lane_regs = &lane_regs_x1e80100[0];
-		regs->lane_array_size = ARRAY_SIZE(lane_regs_x1e80100);
-		regs->offset = 0x1000;
-		break;
 	case CAMSS_8550:
-		regs->lane_regs = &lane_regs_sm8550[0];
-		regs->lane_array_size = ARRAY_SIZE(lane_regs_sm8550);
-		regs->offset = 0x1000;
-		break;
 	case CAMSS_8650:
-		regs->lane_regs = &lane_regs_sm8650[0];
-		regs->lane_array_size = ARRAY_SIZE(lane_regs_sm8650);
 		regs->offset = 0x1000;
 		break;
-	case CAMSS_8300:
-	case CAMSS_8775P:
-		regs->lane_regs = &lane_regs_sa8775p[0];
-		regs->lane_array_size = ARRAY_SIZE(lane_regs_sa8775p);
-		break;
 	default:
+		regs->offset = 0x800;
 		break;
 	}
 

-- 
2.51.0

