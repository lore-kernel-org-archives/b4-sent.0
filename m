From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Wed, 24 Jun 2026 07:24:34 +0000
Subject: [PATCH] rtc: amlogic-a4: clear unsupported update interrupt
 feature
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260624-rtc-feature-v1-1-42dccd22c0ee@amlogic.com>
X-B4-Tracking: v=1; b=H4sIADKGO2oC/x3MQQqAIBBA0avIrBNMRaqrRAuxsWZjMVoE4d2Tl
 m/x/wsZmTDDJF5gvCnTkRr6TkDYfdpQ0toMWmmnnLaSS5ARfbkYpTIBTTSDNX6EVpyMkZ7/Ni+
 1fiM27XxdAAAA
X-Change-ID: 20260624-rtc-feature-03ce3f3843a9
To: Yiting Deng <yiting.deng@amlogic.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>
Cc: linux-amlogic@lists.infradead.org, linux-rtc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782285876; l=1071;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=pJ5eX/skfag9z0pkWfC/zXmkphBv9K7+CU5zNogQX00=;
 b=K8SW8U312kCtLZRTKBb2MmA6n7lo6AJUWoPjwyFhymEluNvfnNr7RierO1ahP2OjvK8nQydOZ
 6+CcbiIlZ2AAj4mU+kcubK5ai8aeDsJBtdjFjvMwX5V1IViaFKEHLN5
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Amlogic A4 RTC does not support update interrupt. Clear
RTC_FEATURE_UPDATE_INTERRUPT before registering the RTC device to
prevent userspace from enabling an unsupported RTC UIE function.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Clear RTC_FEATURE_UPDATE_INTERRUPT before registering the RTC device.
---
 drivers/rtc/rtc-amlogic-a4.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/rtc/rtc-amlogic-a4.c b/drivers/rtc/rtc-amlogic-a4.c
index 50938c35af36..116cf095a9e9 100644
--- a/drivers/rtc/rtc-amlogic-a4.c
+++ b/drivers/rtc/rtc-amlogic-a4.c
@@ -379,6 +379,7 @@ static int aml_rtc_probe(struct platform_device *pdev)
 	rtc->rtc_dev->ops = &aml_rtc_ops;
 	rtc->rtc_dev->range_min = 0;
 	rtc->rtc_dev->range_max = U32_MAX;
+	clear_bit(RTC_FEATURE_UPDATE_INTERRUPT, rtc->rtc_dev->features);
 
 	return devm_rtc_register_device(rtc->rtc_dev);
 }

---
base-commit: 851d961ff248218f681c53cf0f7f08cf8201a117
change-id: 20260624-rtc-feature-03ce3f3843a9

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

