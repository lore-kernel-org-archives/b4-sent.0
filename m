From: Keguang Zhang <keguang.zhang@gmail.com>
Subject: [PATCH v2 0/2] pwm: loongson: Fix PWM configuration handling
Date: Fri, 26 Jun 2026 20:24:21 +0800
Message-Id: <20260626-pwm-loongson-fix-v2-0-5492db953879@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHVvPmoC/2WNQQ7CIBREr9L8td8UqNS68h6mC2yh/UmBBgxqG
 u4uNnHl8k1m3mwQdSAd4VJtEHSiSN4V4IcKhlm5SSONhYHXXNaScVyfFhfv3RS9Q0MvZGfRStG
 cmO4ElNkadIl35a0vPFN8+PDeHxL7pj+Z/JclhjU2HRvvplRUa66TVbQcB2+hzzl/AP62C6SwA
 AAA
To: Binbin Zhou <zhoubinbin@loongson.cn>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>
Cc: linux-pwm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Keguang Zhang <keguang.zhang@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782476683; l=1224;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=oo2KlzchszEKmeSlzGlrVuSsrAVnItDyZhmcgHfi0oY=;
 b=qNJb8qLIPXV6XX5uBmcZnye20QRHXS9ZDd35ewgEa3iqZ7zJfw7kKAODKUF6uiwsRbBweZ2aI
 GmqMfdm1jzBBDoWSj1RFEv2orvOlUGBI6o4sggv8QwxSgv5wG5krdJM
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
Changes in v2:
- Drop the -ERANGE return change and restore the original behavior.
- Use mul_u64_u64_div_u64_roundup() to calculate the low pulse width.
- Update the commit message accordingly.
- Link to v1: https://lore.kernel.org/r/20260616-pwm-loongson-fix-v1-0-491dbf260a7f@gmail.com

---
Keguang Zhang (2):
      pwm: loongson: Fix low pulse buffer register handling
      pwm: loongson: Reload PWM configuration through counter reset

 drivers/pwm/pwm-loongson.c | 32 +++++++++++++++++++-------------
 1 file changed, 19 insertions(+), 13 deletions(-)
---
base-commit: 8d6dbbbe3ba62de0a63e962ee004afb848c8e3ac
change-id: 20260612-pwm-loongson-fix-183763451e93

Best regards,
-- 
Keguang Zhang <keguang.zhang@gmail.com>

