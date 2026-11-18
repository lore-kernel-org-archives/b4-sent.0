From: =?utf-8?q?Alexandru_Andrie=C8=99?= <alex.andries.aa@gmail.com>
Date: Thu, 19 Nov 2026 00:16:50 +0100
Subject: [PATCH 1/3] power: supply: qcom_battmgr: set mAh unit for SM8350
 and SM8550
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261119-upstream-qcom-battmgr-fixes-v1-v1-1-ca83700c08c1@gmail.com>
References: <20261119-upstream-qcom-battmgr-fixes-v1-v1-0-ca83700c08c1@gmail.com>
In-Reply-To: <20261119-upstream-qcom-battmgr-fixes-v1-v1-0-ca83700c08c1@gmail.com>
To: Sebastian Reichel <sre@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>
Cc: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 linux-pm@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, stable@vger.kernel.org, 
 =?utf-8?q?Alexandru_Andrie=C8=99?= <alex.andries.aa@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795043834; l=1477;
 i=alex.andries.aa@gmail.com; s=20261118; h=from:subject:message-id;
 bh=57hCL/wfpzvCW6AYmx0LBjTyYxD1cG6DUfZHuao/KPI=;
 b=3rYahb7KNQtzhxSpXJCb5betOKRj2XiHodoeXFNeAMkJlH4PyOOnE589g+bvcd1Dtp3z25MwE
 Q+DDg/2arIpB8Q6btPmnlA8MlzCs2IDZ14RZIcQdGufHeFGfThyql6X
X-Developer-Key: i=alex.andries.aa@gmail.com; a=ed25519;
 pk=kNAqgavfB7uUd1mA8o8TszhGxzyqBwY71PGO/oK4v84=
X-Endpoint-Received: by B4 Relay for alex.andries.aa@gmail.com/20261118 with auth_id=1564
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

battmgr->unit is only populated by BATTMGR_BAT_INFO on SC8280XP and
X1E80100, remaining QCOM_BATTMGR_UNIT_mWh (0) on SM8350 and SM8550 where
firmware reports BATT_CHG_FULL and BATT_CHG_FULL_DESIGN in uAh via
BATTMGR_BAT_PROPERTY_GET. Consequently, charge_full and
charge_full_design always return -ENODATA, preventing UPower from
computing battery energy and health.

Set battmgr->unit to QCOM_BATTMGR_UNIT_mAh when probing SM8350 and
SM8550.

Tested on a Xiaomi MIX 4 (SM8350): charge_full (4256000) and
charge_full_design (4360000) are now reported. SM8550 shares the same
property path and was not tested.

Fixes: 29e8142b5623 ("power: supply: Introduce Qualcomm PMIC GLINK power supply")
Cc: stable@vger.kernel.org
Signed-off-by: Alexandru Andrieș <alex.andries.aa@gmail.com>
---
 drivers/power/supply/qcom_battmgr.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/power/supply/qcom_battmgr.c b/drivers/power/supply/qcom_battmgr.c
index 58e238e6fb2a..c07e2db8f242 100644
--- a/drivers/power/supply/qcom_battmgr.c
+++ b/drivers/power/supply/qcom_battmgr.c
@@ -1717,6 +1717,8 @@ static int qcom_battmgr_probe(struct auxiliary_device *adev,
 			return dev_err_probe(dev, PTR_ERR(battmgr->wls_psy),
 					     "failed to register wireless charing power supply\n");
 	} else {
+		battmgr->unit = QCOM_BATTMGR_UNIT_mAh;
+
 		if (battmgr->variant == QCOM_BATTMGR_SM8550)
 			psy_desc = &sm8550_bat_psy_desc;
 		else

-- 
2.56.1

