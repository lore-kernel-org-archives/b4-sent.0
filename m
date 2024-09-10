From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v3 0/3] support for amlogic rtc
Date: Tue, 10 Sep 2024 18:14:17 +0800
Message-Id: <20240910-rtc-v3-0-1fa077a69a20@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPkb4GYC/1WMwQrCMBAFf6Xs2UiyMTb15H+Ih5ik7YJtJClBK
 f130yJIj/N4MzMkH8knuFQzRJ8pURgLyEMFtjdj5xm5woAcT1yjZHGyTGBtnRYNGiGhPF/Rt/T
 eKrd74Z7SFOJni2axrns/C8bZua251MIZ1PJqhmfoyB5tGGAtZPxbDf9ZWCyunFG1Ug/tmr21L
 MsXGCJDoc4AAAA=
To: Yiting Deng <yiting.deng@amlogic.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-rtc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725963258; l=1443;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=Sobyjbsg00DCrwSWH1kDJBeyO+Pp/IjZIWpKWS5D8QU=;
 b=ILLG7jZLh8LNWnmrhMqwMAvdN+HP2yahKKY/veJHkXQAAOKdiZJlBOS5SJMlyxBL9twv2+Ndj
 dqTItQ3WhvgBrs2gKuB/VQnMdNCVPBiNXVGkEJrqfJ3bd65biYS47hh
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add rtc driver and bindigns for the amlogic A4(A113L2) and A5(A113X2) SoCs.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v3:
- Perfect the binding description and rename binding.
- Using dev_err_probe function correctly, and modify commit message.
- Change placement about MAINTAINERS.
- Link to v2: https://lore.kernel.org/r/20240903-rtc-v2-0-05da5755b8d9@amlogic.com

Changes in v2:
- Modify bindings clock name and perfect the example.
- Fix some bug in driver, and use dev_err_probe instead of dev_err in probe process.
- Use RTC API to handle calibration.
- Remove unused func and rename driver file name.
- Link to v1: https://lore.kernel.org/r/20240823-rtc-v1-0-6f70381da283@amlogic.com

---
Yiting Deng (3):
      dt-bindings: rtc: Add Amlogic A4 and A5 RTC
      rtc: support for the Amlogic on-chip RTC
      MAINTAINERS: Add an entry for Amlogic RTC driver

 .../devicetree/bindings/rtc/amlogic,a4-rtc.yaml    |  63 +++
 MAINTAINERS                                        |   8 +
 drivers/rtc/Kconfig                                |  12 +
 drivers/rtc/Makefile                               |   1 +
 drivers/rtc/rtc-amlogic-a4.c                       | 473 +++++++++++++++++++++
 5 files changed, 557 insertions(+)
---
base-commit: 658b3fec5fc0ef3c016c4a7eedac1a5f3b8c0151
change-id: 20240823-rtc-127cd8192a13

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

