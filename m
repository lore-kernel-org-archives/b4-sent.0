From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Tue, 03 Sep 2024 15:00:47 +0800
Subject: [PATCH v2 3/3] MAINTAINERS: Add an entry for Amlogic RTC driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240903-rtc-v2-3-05da5755b8d9@amlogic.com>
References: <20240903-rtc-v2-0-05da5755b8d9@amlogic.com>
In-Reply-To: <20240903-rtc-v2-0-05da5755b8d9@amlogic.com>
To: Yiting Deng <yiting.deng@amlogic.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-rtc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725346845; l=877;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=XIFaH+nJVOwTXlOGddbE310DKNtSVCRPwv4K0uAQLf0=;
 b=Gk/bz/WWEsRaeP+6/mmQ6yyounrKWRHq8LqmEPUr4dcIrifmX1etdoSsvYG9Gq6D3WQqh0vCC
 ta2k/+9Tu2YB02E6FUUGfHxjjb/rDPlGFXzEc1lqvo5BSzqPjoRDWyk
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
index 42decde38320..cdcd23456567 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2481,6 +2481,14 @@ F:	drivers/irqchip/irq-mvebu-*
 F:	drivers/pinctrl/mvebu/
 F:	drivers/rtc/rtc-armada38x.c
 
+AMLOGIC RTC DRIVER
+M:	Yiting Deng <yiting.deng@amlogic.com>
+M:	Xianwei Zhao <xianwei.zhao@amlogic.com>
+L:	linux-amlogic@lists.infradead.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/rtc/amlogic,amlogic-rtc.yaml
+F:	drivers/rtc/rtc-amlogic-a4.c
+
 ARM/Mediatek RTC DRIVER
 M:	Eddie Huang <eddie.huang@mediatek.com>
 M:	Sean Wang <sean.wang@mediatek.com>

-- 
2.37.1

