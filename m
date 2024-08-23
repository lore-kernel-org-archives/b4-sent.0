From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Fri, 23 Aug 2024 17:19:46 +0800
Subject: [PATCH 3/3] MAINTAINERS: Add an entry for Amlogic RTC driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240823-rtc-v1-3-6f70381da283@amlogic.com>
References: <20240823-rtc-v1-0-6f70381da283@amlogic.com>
In-Reply-To: <20240823-rtc-v1-0-6f70381da283@amlogic.com>
To: Yiting Deng <yiting.deng@amlogic.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-rtc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724404784; l=878;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=kKfAM48i5NM35z09vCTUkBfuWRf4o7vOPs0ZFkbUpAc=;
 b=oEyXPyxBt9+Kn3pBRu72Bhb7+F7ejh4pwpgFy4LjcjGyHpZpH3LLZti0ow50n/x3xKQjuP1Jc
 oluZXV1U07tDHuIwUCT1eUeBl0YDZJqQrfw3ZPRm8rz1oGwHajfr66y
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Yiting Deng <yiting.deng@amlogic.com>

Add Amlogic RTC entry to MAINTAINERS to clarify the maintainers

Signed-off-by: Yiting Deng <yiting.deng@amlogic.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 MAINTAINERS | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 42decde38320..672290dddaaa 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2481,6 +2481,14 @@ F:	drivers/irqchip/irq-mvebu-*
 F:	drivers/pinctrl/mvebu/
 F:	drivers/rtc/rtc-armada38x.c
 
+ARM/Amlogic RTC Driver
+M:	Yiting Deng <yiting.deng@amlogic.com>
+M:	Xianwei Zhao <xianwei.zhao@amlogic.com>
+L:	linux-amlogic@lists.infradead.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/rtc/amlogic,amlogic-rtc.yaml
+F:	drivers/rtc/rtc-amlogic.c
+
 ARM/Mediatek RTC DRIVER
 M:	Eddie Huang <eddie.huang@mediatek.com>
 M:	Sean Wang <sean.wang@mediatek.com>

-- 
2.37.1

