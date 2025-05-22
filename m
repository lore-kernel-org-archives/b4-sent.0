From: George Moussalem <george.moussalem@outlook.com>
Date: Thu, 22 May 2025 09:48:51 +0400
Subject: [PATCH] thermal: qcom: ipq5018: make ops_ipq5018 struct static
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250522-ipq5018-tsens-sparse-v1-1-97edaaaef27c@outlook.com>
X-B4-Tracking: v=1; b=H4sIAMK6LmgC/y3MywqDMBCF4VeRWXcgCY23VykuTDPqbNI4o1IQ3
 72h7fI7cP4TlIRJoa9OEDpY+ZUK7K2C5zKmmZBjMTjjvPHOIufVG9vippQUNY+ihPfQ1rFrYgi
 2gXLNQhO/v9nH8LPQupf69h+v6wMO8VuHewAAAA==
X-Change-ID: 20250521-ipq5018-tsens-sparse-4b86d97dbb17
To: Amit Kucheria <amitk@kernel.org>, 
 Thara Gopinath <thara.gopinath@gmail.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@linaro.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>
Cc: linux-pm@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, kernel test robot <lkp@intel.com>, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747892937; l=1603;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=AQVbg0exLroJo2VR6NwKRBYnMgg5MIEpgmctdGB8598=;
 b=tpAJawEZhOFGF5BWQgBdrS2gQMZ2F7XTxy01rJUUbdTRqdR+Ohng0RJNl1KX+coo2+FtH90L8
 1/07OjPaxg5BM/HleCtxKQ0u3x0v+afA//+C80QZ8jZBxJYAmSVL7R5
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix a sparse warning by making the ops_ipq5018 struct static.

Reported-by: kernel test robot <lkp@intel.com>
Closes: https://lore.kernel.org/oe-kbuild-all/202505202356.S21Sc7bk-lkp@intel.com/
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
Fix below sparse warning by making the ops_ipq5018 struct static.

sparse warnings: (new ones prefixed by >>)
>> drivers/thermal/qcom/tsens-v1.c:246:24: sparse: sparse: symbol 'ops_ipq5018' was not declared. Should it be static?

vim +/ops_ipq5018 +246 drivers/thermal/qcom/tsens-v1.c

   245	
 > 246	const struct tsens_ops ops_ipq5018 = {
   247		.init		= init_tsens_v1_no_rpm,
   248		.calibrate	= tsens_calibrate_common,
   249		.get_temp	= get_temp_tsens_valid,
   250	};
   251	
---
 drivers/thermal/qcom/tsens-v1.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/thermal/qcom/tsens-v1.c b/drivers/thermal/qcom/tsens-v1.c
index 27360e70d62a94e52e67f5aaa45457be165bfeb3..faa5d00788ca6fb29b367857d27596578218358e 100644
--- a/drivers/thermal/qcom/tsens-v1.c
+++ b/drivers/thermal/qcom/tsens-v1.c
@@ -243,7 +243,7 @@ struct tsens_plat_data data_8976 = {
 	.fields		= tsens_v1_regfields,
 };
 
-const struct tsens_ops ops_ipq5018 = {
+static const struct tsens_ops ops_ipq5018 = {
 	.init		= init_tsens_v1_no_rpm,
 	.calibrate	= tsens_calibrate_common,
 	.get_temp	= get_temp_tsens_valid,

---
base-commit: 54b982e44c486d604583efe8742557ab56c944e0
change-id: 20250521-ipq5018-tsens-sparse-4b86d97dbb17

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

