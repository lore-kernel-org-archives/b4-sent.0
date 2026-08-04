From: Alexandre MINETTE <contact@alex-min.fr>
Date: Tue, 04 Aug 2026 08:34:30 +0200
Subject: [PATCH v5 5/6] extcon: qcom-spmi-misc: match PM8xxx USB ID
 platform device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260804-mainline-send-v1-sending-v5-5-149dd4372ac8@alex-min.fr>
References: <20260804-mainline-send-v1-sending-v5-0-149dd4372ac8@alex-min.fr>
In-Reply-To: <20260804-mainline-send-v1-sending-v5-0-149dd4372ac8@alex-min.fr>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, MyungJoo Ham <myungjoo.ham@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, 
 Guru Das Srinagesh <linux@gurudas.dev>, Linus Walleij <linusw@kernel.org>, 
 Rob Clark <robin.clark@oss.qualcomm.com>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>, Lee Jones <lee@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-gpio@vger.kernel.org, 
 phone-devel@vger.kernel.org, Alexandre MINETTE <contact@alex-min.fr>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785825291; l=1259;
 i=contact@alex-min.fr; s=20260421; h=from:subject:message-id;
 bh=GY8HHAKQAe9p+CGliq7ltiYrSns53pS1wL6cDILgUI0=;
 b=ZLboheVqEulZk767LeMAQIhKgzjMzsE9seG0dIqxjEa/av+wcyMuf7HKKNGCow88t9DvLFo6g
 CJwRNYVEFXxB5ZKI1DlVEYny8s165aSEas87LF4guXotYkN0emTH9Gw
X-Developer-Key: i=contact@alex-min.fr; a=ed25519;
 pk=KOCaxY4v16ptaT0uk1FRkuaDF2n1JhmnYwLiqWD76M4=
X-Endpoint-Received: by B4 Relay for contact@alex-min.fr/20260421 with auth_id=743
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PM8xxx MFD registers the PM8921 USB ID detector as a platform device
named "qcom-pm8xxx-usb-id". Its reused firmware node remains compatible
with "qcom,pm8921", so it does not match the extcon driver's OF table.

Add a platform device ID so the existing extcon driver binds to this
device and consumes its named USB ID interrupt.

Signed-off-by: Alexandre MINETTE <contact@alex-min.fr>
---
 drivers/extcon/extcon-qcom-spmi-misc.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/extcon/extcon-qcom-spmi-misc.c b/drivers/extcon/extcon-qcom-spmi-misc.c
index afaba5685c3d..e16c109b553e 100644
--- a/drivers/extcon/extcon-qcom-spmi-misc.c
+++ b/drivers/extcon/extcon-qcom-spmi-misc.c
@@ -204,8 +204,15 @@ static const struct of_device_id qcom_usb_extcon_dt_match[] = {
 };
 MODULE_DEVICE_TABLE(of, qcom_usb_extcon_dt_match);
 
+static const struct platform_device_id qcom_usb_extcon_id[] = {
+	{ "qcom-pm8xxx-usb-id" },
+	{ }
+};
+MODULE_DEVICE_TABLE(platform, qcom_usb_extcon_id);
+
 static struct platform_driver qcom_usb_extcon_driver = {
 	.probe		= qcom_usb_extcon_probe,
+	.id_table	= qcom_usb_extcon_id,
 	.driver		= {
 		.name	= "extcon-pm8941-misc",
 		.pm	= &qcom_usb_extcon_pm_ops,

-- 
2.43.0

