From: Antony Kurniawan Soemardi <linux@smankusors.com>
Date: Tue, 14 Apr 2026 01:55:30 +0700
Subject: [PATCH 03/10] mfd: qcom_rpm: add msm8960 QDSS clock resource
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260414-msm8960-wifi-v1-3-007fda9d6134@smankusors.com>
References: <20260414-msm8960-wifi-v1-0-007fda9d6134@smankusors.com>
In-Reply-To: <20260414-msm8960-wifi-v1-0-007fda9d6134@smankusors.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Lee Jones <lee@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-arm-msm@vger.kernel.org, 
 linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Rudraksha Gupta <guptarud@gmail.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776106820; l=1052;
 i=linux@smankusors.com; s=20250609; h=from:subject:message-id;
 bh=gOwUYArrOBSpo8/sLmrIU44Yc3IP355SUpgihPGh/KM=;
 b=kP36kl0YA8uqmZfmhFF8HyF+EAX9gBlOqTW2Kkp/0EGzuIx2zyqh2yO5JzvJLie16YLA93krS
 JI65IXoepbZBM/mxpJT2E5viwd9LpGWMP7I7CF4pvCexlxdgNigegFI
X-Developer-Key: i=linux@smankusors.com; a=ed25519;
 pk=65wTy06fJl2/h/EJwjr704YG+yjHFhZObJBWzzK+N00=
X-Endpoint-Received: by B4 Relay for linux@smankusors.com/20250609 with auth_id=733
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

msm8960 uses the same clock descriptor as apq8064 but lacked the
corresponding QDSS resource definition in its resource table. Add
resource ID 209 to msm8960_rpm_resource_table to match apq8064's
implementation.

Without this entry, RPM clock initialization fails on msm8960,
preventing Bluetooth/Wi-Fi/USB from being enabled.

Tested-by: Rudraksha Gupta <guptarud@gmail.com>
Signed-off-by: Antony Kurniawan Soemardi <linux@smankusors.com>
---
 drivers/mfd/qcom_rpm.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/mfd/qcom_rpm.c b/drivers/mfd/qcom_rpm.c
index 27446f43e3f3..0defb3279af1 100644
--- a/drivers/mfd/qcom_rpm.c
+++ b/drivers/mfd/qcom_rpm.c
@@ -324,6 +324,7 @@ static const struct qcom_rpm_resource msm8960_rpm_resource_table[] = {
 	[QCOM_RPM_USB_OTG_SWITCH] =		{ 205, 119, 82, 1 },
 	[QCOM_RPM_HDMI_SWITCH] =		{ 206, 120, 83, 1 },
 	[QCOM_RPM_DDR_DMM] =			{ 207, 121, 84, 2 },
+	[QCOM_RPM_QDSS_CLK] =			{ 209, ~0, 7, 1 },
 };
 
 static const struct qcom_rpm_data msm8960_template = {

-- 
2.34.1

