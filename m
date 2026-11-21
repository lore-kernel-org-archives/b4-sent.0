From: David Heidelberg <david@ixit.cz>
Date: Sat, 21 Nov 2026 23:37:56 +0100
Subject: [PATCH v3 02/12] regulator: qcom_usb_vbus: Fix the
 MODULE_LICENSE() string
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-pmi8998-vbus-v3-2-91ba2e61a877@ixit.cz>
References: <20261121-pmi8998-vbus-v3-0-91ba2e61a877@ixit.cz>
In-Reply-To: <20261121-pmi8998-vbus-v3-0-91ba2e61a877@ixit.cz>
To: Abel Vesa <abelvesa@kernel.org>, 
 Alexey Minnekhanov <alexeymin@minlexx.ru>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Markus Rathgeb <maggu2810@mailbox.org>, Rob Herring <robh@kernel.org>, 
 Robin Snyders <robin@snyders.xyz>, Sebastian Reichel <sre@kernel.org>, 
 Wesley Cheng <quic_wcheng@quicinc.com>
Cc: Richard Acayan <mailingradian@gmail.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 devicetree@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1233; i=david@ixit.cz;
 h=from:subject:message-id; bh=F79nBmxItmBKLY+5BEM13y1NDT1vp2palB3VbLLu0zM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrAh1afl3rcaq6g4wTWEwFc5CPeJ3e6HObeuEC9
 li6KnB8sT6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawIdWgAKCRBgAj/E00kg
 coMcD/oCe2oRgElpBSGKInEhx2e7IDBu390+H5o9R7XOLrWmCdtAN954iUPufOnMmFauwcxTMWo
 QSb0/MTt2JoJ9QUXqMyg0wN0BHc6tODnmAwkhDBE0Ta/ivviYGNQdWpskEFb9NAViaWQw9BF2wc
 x4oLYEDtkopMivVuwTkYuMghDiXfm6woMsBu29Ju28C0WPGdBQjLX4vTWg1HswaCnYuAVBNAQbs
 BiLEeXIqAvZtfa0tMkqtAAfV0m8eSVQJCoeTeXUfa1rEMqVsoYo/tDuFfj4eUr4VfY/VZLk/DgK
 Hp90WoHufVh4+WH0ZMISXE7XHbMCFb4Y9yiaLFn+beTVCpCnkZmDP1g2Q0ClxbnEtX0QU6aNpZn
 lc3n/ltQ5o0qvXYgNf/kIS5eKBkHrAq1EOq6sacootAZdWzPfa6mcRHOn2xGa8pyI658Jyw40lK
 Mf3+1zlWfDN8Fwe5+JbiUIStwLIDQi/CsnTLpoMqvxnl/UuqadeE3vAt4ElI66d2acfuNd7/iqS
 ovv5338YMGo8RDM3kE4aaexBCM2Ka0dGmcwmAfmCYUx7EEB4THsCIahFvJ5vGeQuUvdhec/BpR5
 bTsr+/D9II5wEzuK+rdmjSwIDb7aaWTz1rQJLO1RSExxgNuT6jnUeQGWWjLFC83NzySkdcYXZ8f
 x7va73EyaUSbc5Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace the bogus "GPL v2" with "GPL" as MODULE_LICENSE() string. The
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

