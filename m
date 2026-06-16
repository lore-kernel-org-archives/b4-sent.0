From: Keguang Zhang <keguang.zhang@gmail.com>
Subject: [PATCH 0/2] pwm: loongson: Fix PWM configuration handling
Date: Tue, 16 Jun 2026 19:13:16 +0800
Message-Id: <20260616-pwm-loongson-fix-v1-0-491dbf260a7f@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMwvMWoC/x2MWwqAIBAAryL73UJq2eMq0UfUVgulolCBdPekz
 xmYSRApMEXoRYJAF0d2NoMsBMz7ZDdCXjKDKpUpjVTo7xMP5+wWncWVH5Stboyuakmdhpz5QFn
 /y2F83w+ABRyVYgAAAA==
To: Binbin Zhou <zhoubinbin@loongson.cn>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>
Cc: linux-pwm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Keguang Zhang <keguang.zhang@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781608406; l=874;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=wuQLvZe5ZnxbCDNi2S87UD72UC7CkBtYW73zX/3xjkE=;
 b=P6nXzVQ3Rr4Vmsu2R58w0DdbZMAGG2y6jgHUrxA1leF0wRppAiH4ABDw8SXWfn36qrjn4QkPm
 M3+zOvHdtJCCK1/PCWgf6b0sLJZDuxrEEZ0BfE/3sGu6QSBE9MnkfJr
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes two issues in the Loongson PWM driver:

- Fix the handling of the Low Pulse Buffer Register, which was
  incorrectly treated as a duty-cycle register.

- Ensure that PWM configuration updates take effect immediately by
  resetting the PWM counter to reload the updated settings.

The fixes were verified on LS1B, LS1C, and LS2K0300 boards.

Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
Keguang Zhang (2):
      pwm: loongson: Fix low pulse buffer register handling
      pwm: loongson: Reload PWM configuration through counter reset

 drivers/pwm/pwm-loongson.c | 31 ++++++++++++++++---------------
 1 file changed, 16 insertions(+), 15 deletions(-)
---
base-commit: 8d6dbbbe3ba62de0a63e962ee004afb848c8e3ac
change-id: 20260612-pwm-loongson-fix-183763451e93

Best regards,
-- 
Keguang Zhang <keguang.zhang@gmail.com>

