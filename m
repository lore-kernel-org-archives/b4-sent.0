From: David Heidelberg <david@ixit.cz>
Date: Sat, 31 Oct 2026 16:04:58 +0100
Subject: [PATCH 01/11] regulator: qcom_usb_vbus: Fix the MODULE_LICENSE()
 string
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261031-pmi8998-vbus-v1-1-4d805e5a0f27@ixit.cz>
References: <20261031-pmi8998-vbus-v1-0-4d805e5a0f27@ixit.cz>
In-Reply-To: <20261031-pmi8998-vbus-v1-0-4d805e5a0f27@ixit.cz>
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
 h=from:subject:message-id; bh=0vIIV4exeWwbtrGHfz1u0SZa5CA6vOAyO+STZ9EWoY0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq5gOvB4xWLh9WrazYpdCCBZa+F16420W1sGD8c
 8qX8EaxbdmJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCauYDrwAKCRBgAj/E00kg
 cno8D/93p3H8YLRZBhTAzf01g1NXN2ySjYQNUKD+tKCdydBNSPaJqG05KoIoPU8UkBEKFgc1r1N
 +AA/ePDT+TLBrbfpAxnSn/WV16q/jp8TQEH137C/sgiXiybYiQMpPz3ZzHuqg+ZAhMza18DTuN6
 +y/dSZNNbohbLBXCimwkwxXpo2AnJbFHP5Pqey8vyN5ASWWPTOFQeFJ2KEA/AR32vZB1RzwJvRb
 BoUYxkg9OsMCCxwwP2vMMU69p5LZ9AZRZv8pQ5sT+zNXuWAUe9koEu9TZY2bjzFASrV/ItyCTNf
 D8eut1lureYu88R0dBc5tIpQeNh61xzWX2PJ6swT1eHIqnQ+5zMNJyVnCkeJQ03A9s9LML0S7wi
 6Stmgowp96gizeGqGWVy06DPhanm0tnXPNE3BGd3086V5xPz45YTEcBsZ9bYw8Bj55nrTEsfqAG
 g0ccc1FbGEHLV4SNLWr2WRKtweSM4hW9yF/uU6j1TNqWyxIBnGEjVYWRRn6lgSZZnnKDVclpMxc
 hJYaum7uxrq5TWVhAue19IgeiLjdNUutjoeklKxUZQV3vg/U5K+eWKxqfcARd1r9VpeTSDyLky8
 zile/LXQlH9Dlv0DXb7JvJaNoE84FsnOW25KeZcZ3mEM7lTu5kGCxEdCFX31zI8BtmQkjwBSNbV
 sY5oJ5Vz6vkOnDw==
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
index 9aea68876284e..f189e1ed4f3f9 100644
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

