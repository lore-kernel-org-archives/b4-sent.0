From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/3] support for amlogic rtc
Date: Fri, 23 Aug 2024 17:19:43 +0800
Message-Id: <20240823-rtc-v1-0-6f70381da283@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAC9UyGYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDCyNj3aKSZF1DI/PkFAtDS6NEQ2MloMqCotS0zAqwKdGxtbUAA60T+FU
 AAAA=
To: Yiting Deng <yiting.deng@amlogic.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-rtc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724404784; l=839;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=KhN+NQf/vdSEEkKAVXu1CtJtcHLdjhi4HZJpa/pUdy4=;
 b=HsWgzJib2xTeA8gPpNPJiGUQhNPcfsMJfbZcceA8byJwSKYLP9/PfVVJ32Xkd/3txvcwOEw6o
 2DM3LDAMKS+Dt84agCJgAMYxbroDNzqH9v7mHjfL6C3XJeTD0HiZATj
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add rtc driver and bindigns for the amlogic A113L2 and A113X2 SoCs

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Yiting Deng (3):
      dt-bindings: rtc: Add Amlogic A311L2 and A113X2 rtc
      rtc: support for the Amlogic on-chip RTC
      MAINTAINERS: Add an entry for Amlogic RTC driver

 .../bindings/rtc/amlogic,amlogic-rtc.yaml          |  66 +++
 MAINTAINERS                                        |   8 +
 drivers/rtc/Kconfig                                |  12 +
 drivers/rtc/Makefile                               |   1 +
 drivers/rtc/rtc-amlogic.c                          | 589 +++++++++++++++++++++
 5 files changed, 676 insertions(+)
---
base-commit: dff71e5c6076314f3eefe700abd6af834c57bd64
change-id: 20240823-rtc-127cd8192a13

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

