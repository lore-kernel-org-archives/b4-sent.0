From: Keguang Zhang <keguang.zhang@gmail.com>
Subject: [PATCH RESEND v4 0/3] pwm: loongson: Fix PWM configuration
 handling
Date: Fri, 27 Nov 2026 21:32:22 +0800
Message-Id: <20261127-pwm-loongson-fix-v4-0-607f325b74d4@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/23NPQ+CMBAG4L9COltDP6DUyUFWBx2NQ4ECTaAlr
 UEN4b97ISYSdXzfu3tuQkF7owPaRRPyejTBOAuBbyJUtso2GpsKMqIxTeOUUDzce9w5Z5vgLK7
 NA5OMiZTxhGjJEJwNXkO9kBd0ys/58YCu0Lcm3Jx/Lp9GskzfaPqLjgTHmEtSFTWsKFHvm16Zb
 lu6fsFGugLoP4ACkHBJq0ImLBPyG2AfQJDkD8AAiJUqaMaFVkqsgXmeXzSWr3k6AQAA
X-Change-ID: 20260612-pwm-loongson-fix-183763451e93
To: Binbin Zhou <zhoubinbin@loongson.cn>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>
Cc: linux-pwm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 "Imported from f20260920-pwm-loongson-fix-v4-0-41b36b3c6497"@gmail.com, 
 Keguang Zhang <keguang.zhang@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795786349; l=2157;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=CwIaW+A6x20ljgJSm9xW+J/vK0MOBDMKCU+FB1gyLv0=;
 b=6NAcs2SJLHuE760NzMBux45kv+OAp8njajZQqiESe4fV2avAdlB8WfGDHpkMTYoGeUQyl/7oz
 mCjOxkC69CEBs9LIattQo9rEIApBLPBv0UMTROPpKqXLwIPlAK2mdCL
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

EDITME: Imported from f20260920-pwm-loongson-fix-v4-0-41b36b3c6497@gmail.com
        Please review before sending.

This series fixes two issues in the Loongson PWM driver:

- Fix the handling of the Low Pulse Buffer Register, which was
  incorrectly treated as a duty-cycle register.

- Reset the PWM counters before enabling to ensure that
  the PWM starts from a known state.

It also includes a follow-up rework:

- Use field helpers for period validation.

The whole patchset was verified on LS1B, LS1C, and LS2K0300 boards.

Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
Changes in v4:
- Split the period validation rework into a separate patch from the
  functional fixes.
- Limit the duty cycle to the period before calculating the low pulse.
- Add a fix to reset the PWM counters before enabling, as suggested by
  Uwe Kleine-König.
- Drop v3 patch 2/3 (0de9b836a3bc), which has already been applied to
  pwm/for-next.
- Link to v3: https://lore.kernel.org/r/20260715-pwm-loongson-fix-v3-0-0aab2847eaa7@gmail.com

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
Keguang Zhang (3):
      pwm: loongson: Fix low pulse buffer register handling
      pwm: loongson: Reset the counters before enabling PWM
      pwm: loongson: Use field helpers for period validation

 drivers/pwm/pwm-loongson.c | 44 ++++++++++++++++++++++++++++++--------------
 1 file changed, 30 insertions(+), 14 deletions(-)
---
base-commit: 1ded7cf43312109206d02ef6150c9450818c239c
change-id: 20260612-pwm-loongson-fix-183763451e93

Best regards,
-- 
Keguang Zhang <keguang.zhang@gmail.com>

