From: David Heidelberg <david@ixit.cz>
Date: Wed, 18 Nov 2026 18:25:34 +0100
Subject: [PATCH v2 01/12] regulator: qcom_usb_vbus: Fix the
 MODULE_LICENSE() string
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-pmi8998-vbus-v2-1-3c77a72b280a@ixit.cz>
References: <20261118-pmi8998-vbus-v2-0-3c77a72b280a@ixit.cz>
In-Reply-To: <20261118-pmi8998-vbus-v2-0-3c77a72b280a@ixit.cz>
To: Alexey Minnekhanov <alexeymin@minlexx.ru>, 
 Robin Snyders <robin@snyders.xyz>, Liam Girdwood <lgirdwood@gmail.com>, 
 Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Wesley Cheng <quic_wcheng@quicinc.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Sebastian Reichel <sre@kernel.org>
Cc: Richard Acayan <mailingradian@gmail.com>, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 linux-pm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1232; i=david@ixit.cz;
 h=from:subject:message-id; bh=6MCm0tUZg6K77qclXj7MxDYC5mznSlasM+gfjuaMpWY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq/d+WCvmEc49O+Y7h/zvw8H8UpZW+GqBBvKKzK
 lbCjsxOyYCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCav3flgAKCRBgAj/E00kg
 crfpD/9hYzqBBAGwbfwHsX3WZ2LNhqt+/S6RTU/pqZmHLxXub/7XKXdB4B3BxavgdSqQchMplIc
 mIBZ9/pOGqb64x957Hb6uOAuiBNzNFg3Hs8wwS40ardiAsvSxXpDwOowr6wGylJv6S3sAcoDm5/
 WhZxhd8nqdnqwI3y6ZG0deEOnggo4JbjAbVv3bwCz/5OXzsCin8uuo+UFZb/M8hNWaBpBycBvaS
 2pcYwd5r8/ViKiEljpXP/12ARctl2prH2vs2kUfhjKwj+Y/2eFDaJctvl/CgzkwtAFatP/aW93g
 1UMYvd+2H7FzrQqLObHg0Mf2iT92h3ASePHjbg4bJyQ7PWvJWRm9wYk19xvvziFvOmVcPaDucym
 evyibJ9eDrHo3cdF0cdOoCYCkA5hEmgKfTH4rLZQZAqd/H2W5FqWEq7HV63bRG4IhYBev8VCDQ4
 xjXuZUDt7dqqESbofr6mySdSbJVD3cSPQVR1pjxLyyXvT12cpND3cjeK5G64HcsB058VMlAHotN
 cpmy55WLTC2uV7tqx+WJK0QHaQajM+1ZWB8FJeiQS2RV8VgOthvJdTjtERbXQwWFHxWwUZnoyZe
 f3sxcWPvFs1q2oGxeIKyIw9RA+7UI+Ip0xDQekP3Fmcc+QXk+CxvXkPH3bGW0gw7CnDdc6uG18W
 8OLxT6zqmi1x5AA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace the bogus "GPL v2" with "GPL" as MODULE_LICNSE() string. The
value does not declare the module's exact license, but only lets the
module loader test whether the module is Free Software or not.

See commit bf7fbeeae6db ("module: Cure the MODULE_LICENSE "GPL" vs.
"GPL v2" bogosity") in the details of the issue. The fix is to use
"GPL" for all modules under any variant of the GPL.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/regulator/qcom_usb_vbus-regulator.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/regulator/qcom_usb_vbus-regulator.c b/drivers/regulator/qcom_usb_vbus-regulator.c
index d909a6f2b7f14..88f5a6ba79e6e 100644
--- a/drivers/regulator/qcom_usb_vbus-regulator.c
+++ b/drivers/regulator/qcom_usb_vbus-regulator.c
@@ -176,9 +176,9 @@ static struct platform_driver qcom_usb_vbus_regulator_driver = {
 		.probe_type = PROBE_PREFER_ASYNCHRONOUS,
 		.of_match_table = qcom_usb_vbus_regulator_match,
 	},
 	.probe		= qcom_usb_vbus_regulator_probe,
 };
 module_platform_driver(qcom_usb_vbus_regulator_driver);
 
 MODULE_DESCRIPTION("Qualcomm USB vbus regulator driver");
-MODULE_LICENSE("GPL v2");
+MODULE_LICENSE("GPL");

-- 
2.55.0

