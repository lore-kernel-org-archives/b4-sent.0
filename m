From: David Heidelberg <david@ixit.cz>
Date: Mon, 21 Sep 2026 12:46:22 +0200
Subject: [PATCH v4 1/4] backlight: qcom-wled: Fix NULL pointer dereference
 in wled_remove()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-qcom-wled-backlight-v4-1-bab8c7ef73cb@ixit.cz>
References: <20260921-qcom-wled-backlight-v4-0-bab8c7ef73cb@ixit.cz>
In-Reply-To: <20260921-qcom-wled-backlight-v4-0-bab8c7ef73cb@ixit.cz>
To: Lee Jones <lee@kernel.org>, Daniel Thompson <danielt@kernel.org>, 
 Jingoo Han <jingoohan1@gmail.com>, Helge Deller <deller@gmx.de>, 
 Kiran Gunda <quic_kgunda@quicinc.com>, 
 Marco Mattiolo <marco.mattiolo@hotmail.it>, 
 =?utf-8?q?Barnab=C3=A1s_Cz=C3=A9m=C3=A1n?= <barnabas.czeman@mainlining.org>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 linux-fbdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Joel Selvaraj <foss@joelselvaraj.com>, David Heidelberg <david@ixit.cz>, 
 stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1208; i=david@ixit.cz;
 h=from:subject:message-id; bh=+dZaRJRtQ4v3SzBsEJavUDVtILbeFcbE2ljB22hvcJI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqsQr/4lkhyZPqySJGz8AbmEdnqgIJmewQv2Vg8
 UJPRD7QvBSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCarEK/wAKCRBgAj/E00kg
 cqdgEACW4JkRf6Isv9QBPQ23EC6GzduH57OWTfvtjLxLPCjceEaSPsrzUHJT9Oy2U5NYJwlZ8Ih
 LbTJS2rNlynQzdPCbqcJEIIwu5KUKLVPJykGUsxclL6gdFXEhcdec7YLRrKMyY6TqxkW6v/cHXQ
 R4EMHQ9SMCh49+sJE7LdtcZ+y+Z0hqL0XXZuaaXYbj2crc39hI4uxtbuf4gNzIAZm6UW/uDEWma
 2fojatxwgf+iXwVUxRyisb70+zwk/L4yR0JHZIUb3+F0+HqwAHbRA2aqMq5stkwWFH1STmscsua
 /h0FdqK2MtuoFJYpc/sAtq5Okn09o5lqBqqvJQSoHpgjt61KKsBGXMPrUm9LSjmNooroaTeurDB
 UvJCK3mElpGpDxK5tzkRofhdYjBvfONap1EEYAE3M1Ww3HVqiFECjLj0XtwPR9BGuykdezorZ84
 JzCiFjK85ZPU/SduLIumAcsodjnP7py6jwoKN6o4lYfZM3i6z7NIzckd7s1mNyV2y7N1jg3BLru
 oJKifmcvVRtdOYwAuigCfxdAeetAvoV4rZL1EuvQyhac1cgkDjwyDKMBbdKf/M8SIxdv+c56Js0
 b4gfr9vDcu10RMj0wGw0D42DlblpaR9lF0KEIj9fhuZK2m7DSW1D7okZK2DlmJA6eCF+soNV54o
 w9bufxI8ObtEL4A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

wled_probe() doesn't set the driver data for the platform device.
As a result, platform_get_drvdata() in wled_remove() will return NULL,
and the first dereference of it crashes on unbind.

Set the platform device driver data in wled_probe().

Cc: stable@vger.kernel.org
Fixes: feeab87b3072 ("backlight: qcom-wled: Add support for short circuit handling")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/video/backlight/qcom-wled.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/video/backlight/qcom-wled.c b/drivers/video/backlight/qcom-wled.c
index 650dd95f06ef5..2281007bdd459 100644
--- a/drivers/video/backlight/qcom-wled.c
+++ b/drivers/video/backlight/qcom-wled.c
@@ -1675,16 +1675,17 @@ static int wled_probe(struct platform_device *pdev)
 	}
 
 	wled = devm_kzalloc(&pdev->dev, sizeof(*wled), GFP_KERNEL);
 	if (!wled)
 		return -ENOMEM;
 
 	wled->regmap = regmap;
 	wled->dev = &pdev->dev;
+	platform_set_drvdata(pdev, wled);
 
 	wled->version = (uintptr_t)of_device_get_match_data(&pdev->dev);
 	if (!wled->version) {
 		dev_err(&pdev->dev, "Unknown device version\n");
 		return -ENODEV;
 	}
 
 	mutex_init(&wled->lock);

-- 
2.55.0

