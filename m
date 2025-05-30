From: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
Date: Fri, 30 May 2025 15:35:12 +0800
Subject: [PATCH v2 7/8] usb: typec: ucsi_glink: Add UCSI quirk for X1E80100
 platform
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250530-qcom_battmgr_update-v2-7-9e377193a656@oss.qualcomm.com>
References: <20250530-qcom_battmgr_update-v2-0-9e377193a656@oss.qualcomm.com>
In-Reply-To: <20250530-qcom_battmgr_update-v2-0-9e377193a656@oss.qualcomm.com>
To: Sebastian Reichel <sre@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Subbaraman Narayanamurthy <subbaraman.narayanamurthy@oss.qualcomm.com>, 
 David Collins <david.collins@oss.qualcomm.com>, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 kernel@oss.qualcomm.com, devicetree@vger.kernel.org, 
 linux-usb@vger.kernel.org, Fenglin Wu <fenglin.wu@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748590538; l=1276;
 i=fenglin.wu@oss.qualcomm.com; s=20240327; h=from:subject:message-id;
 bh=dQg6k1rH9JeZXOd77cdrsXXp+gDn3BfTbsH0eA2Fx0g=;
 b=+o52O9eawEr1KHvmULpL518x3uwspPR7DvcCFxkditKBT9yEqBpOgmpddijryjSaQaI42Y3LB
 BiUARQyzPpoCa+Z+QChCpTW9IFtdCmlW/ZUJQj/vHkn1c2MFMb7ccWy
X-Developer-Key: i=fenglin.wu@oss.qualcomm.com; a=ed25519;
 pk=BF8SA4IVDk8/EBCwlBehKtn2hp6kipuuAuDAHh9s+K4=
X-Endpoint-Received: by B4 Relay for fenglin.wu@oss.qualcomm.com/20240327 with auth_id=406
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, the Qualcomm X1E80100 is treated as a fallback of SM8550
in pmic-glink support. However, the battmgr driver, which uses the
same pmic-glink compatible strings, has implemented charge control
functionality differently between SM8550 and X1E80100. As a result,
X1E80100 is no longer a fallback of SM8550 in pmic-glink support.

Therefore, add match data for X1E80100 separately in ucsi_glink driver
but keep the UCSI quirk the same as SM8550.

Signed-off-by: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
---
 drivers/usb/typec/ucsi/ucsi_glink.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/usb/typec/ucsi/ucsi_glink.c b/drivers/usb/typec/ucsi/ucsi_glink.c
index 8af79101a2fc75ae17be1d119b25a9c862e010b3..b10c3161fd577f672d15602023c1aa71a1ab4fe6 100644
--- a/drivers/usb/typec/ucsi/ucsi_glink.c
+++ b/drivers/usb/typec/ucsi/ucsi_glink.c
@@ -319,6 +319,7 @@ static const struct of_device_id pmic_glink_ucsi_of_quirks[] = {
 	{ .compatible = "qcom,sm8350-pmic-glink", .data = &quirk_sc8180x, },
 	{ .compatible = "qcom,sm8450-pmic-glink", .data = &quirk_sm8450, },
 	{ .compatible = "qcom,sm8550-pmic-glink", .data = &quirk_sm8450, },
+	{ .compatible = "qcom,x1e80100-pmic-glink", .data = &quirk_sm8450, },
 	{}
 };
 

-- 
2.34.1

