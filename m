From: Keguang Zhang <keguang.zhang@gmail.com>
Subject: [PATCH v3 0/2] pwm: loongson: Fix PWM configuration handling
Date: Wed, 15 Jul 2026 19:05:22 +0800
Message-Id: <20260715-pwm-loongson-fix-v3-0-0aab2847eaa7@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHJpV2oC/23NTQqDMBAF4KtI1p1iEo2mq96jdOFP1AFNJClpi
 3j3jkJBaJfvMe+bhQXj0QR2SRbmTcSAzlKQp4Q1Q2V7A9hSZiIVKlVcwPycYHTO9sFZ6PAFvJS
 FklnOjZaMZrM3VO/k7U55wPBw/r1/iHxrv5j6xSKHFDLN27qjk6rorv1U4Xhu3MQ2LIoDIP4Bg
 oA806KtdS7LQh+BdV0/yGReUvEAAAA=
To: Binbin Zhou <zhoubinbin@loongson.cn>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>
Cc: linux-pwm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Keguang Zhang <keguang.zhang@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784113526; l=1512;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=l/qhZrympsE5KEgXEO5QvluKCO3+AiZ430txFKLvYOc=;
 b=pEOLPflSQeame2lfhTLdd//re8Wcx7yxsM+TMcZKaoDxNz7+eSNUqCh0bT7uJrqJD+gl30ZAc
 +zEP1fpAQQjAITDpavMJ6mBUX+z8dpF9mBZGuTZ2vGJW4Bx4hmOdUbf
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes two issues in the Loongson PWM driver:

- Fix the handling of the Low Pulse Buffer Register, which was
  incorrectly treated as a duty-cycle register.

- Reset the PWM counter when disabling the PWM and release it when
  enabling the PWM so that updated LOW and PERIOD values are latched
  before the PWM starts running again.

The fixes were verified on LS1B, LS1C, and LS2K0300 boards.

Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
Changes in v3:
- Calculate the low pulse as period - duty after rounding the duty cycle.
- Handle LOW > PERIOD in pwm_loongson_get_state().
- Add a Fixes tag to the second patch.
- Link to v2: https://lore.kernel.org/r/20260626-pwm-loongson-fix-v2-0-5492db953879@gmail.com

Changes in v2:
- Drop the -ERANGE return change and restore the original behavior.
- Use mul_u64_u64_div_u64_roundup() to calculate the low pulse width.
- Update the commit message accordingly.
- Link to v1: https://lore.kernel.org/r/20260616-pwm-loongson-fix-v1-0-491dbf260a7f@gmail.com

---
Keguang Zhang (2):
      pwm: loongson: Fix low pulse buffer register handling
      pwm: loongson: Reload PWM configuration through counter reset

 drivers/pwm/pwm-loongson.c | 40 ++++++++++++++++++++++++++--------------
 1 file changed, 26 insertions(+), 14 deletions(-)
---
base-commit: cc2b5f627e8ccbae1188ef2d8be3e451d7f933a5
change-id: 20260612-pwm-loongson-fix-183763451e93

Best regards,
-- 
Keguang Zhang <keguang.zhang@gmail.com>

