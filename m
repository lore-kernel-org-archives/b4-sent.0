From: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
Subject: [PATCH v3 0/2] leds: rgb: lpg: Don't enable TRILED when
 configuring PWM
Date: Wed, 19 Nov 2025 14:06:41 +0800
Message-Id: <20251119-lpg_triled_fix-v3-0-84b6dbdc774a@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHFeHWkC/3XM0QqCMBTG8VeJXTfx7MxwXfUeEaJz6kCdbTYK8
 d07ehVUNwf+H5zfwoLx1gR2PizMm2iDdSMFHg9Md+XYGm5raiZSkQGA5P3UFrO3vamLxj65lFJ
 BJVWFMmX0NHlD8w5eb9SdDbPzr92PsK1/qQgcuKoEqhyFzlBfXAjJ/VH22g1DQodtYhSfSv6lC
 FJONZgsR0DE5oeyrusbpI8rSfkAAAA=
X-Change-ID: 20251114-lpg_triled_fix-44491b49b340
To: kernel@oss.qualcomm.com, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Bjorn Andersson <andersson@kernel.org>, linux-arm-msm@vger.kernel.org, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Subbaraman Narayanamurthy <subbaraman.narayanamurthy@oss.qualcomm.com>, 
 Pavel Machek <pavel@ucw.cz>, linux-leds@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Fenglin Wu <fenglin.wu@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763532404; l=1449;
 i=fenglin.wu@oss.qualcomm.com; s=20240327; h=from:subject:message-id;
 bh=ZEK+wJs21KjpieXILjX9OQNrW4hvNI90ksPgQCgH+Os=;
 b=KSR6kKZ3j50ymX3dSQIla49xrLoVfc93fppvTUnwiShO5j/tMcix8DTvKFAIql9ViOFaDoPhs
 2mtfgsXh5XbAj/2xFRjrL9eIFfzu/0unuUJ6fLuIqjjZdGWroZeTWzh
X-Developer-Key: i=fenglin.wu@oss.qualcomm.com; a=ed25519;
 pk=BF8SA4IVDk8/EBCwlBehKtn2hp6kipuuAuDAHh9s+K4=
X-Endpoint-Received: by B4 Relay for fenglin.wu@oss.qualcomm.com/20240327 with auth_id=406
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The LPG channel can be used for only outputting PWM signal without the
need to enable TRILED. Update the DT binding document to explain that
usage and remove the TRILED enabling register write in the driver for
that use case.

Signed-off-by: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
---
Changes in v3:
- Add a DT binding change to clarify the standalone PWM usage according
  to the suggestion from Bjorn.
- Link to v2: https://lore.kernel.org/r/20251118-lpg_triled_fix-v2-1-6d1e5831333f@oss.qualcomm.com

Changes in v2:
- Check "chan->in_use" flag in lpg_pwm_apply() is not correct, as it
  indicates the channel is being used as a LED and this PWM API would
  never get called. Instead, remove the code line which enables TRILED
  in lpg_pwm_apply() and update the commit text to explain it clearly.

- Link to v1: https://lore.kernel.org/r/20251114-lpg_triled_fix-v1-1-9b239832c53c@oss.qualcomm.com

---
Fenglin Wu (2):
      dt-bindings: leds: qcom-lpg: Explain standalone PWM usage
      leds: rgb: leds-qcom-lpg: Don't enable TRILED when configuring PWM

 Documentation/devicetree/bindings/leds/leds-qcom-lpg.yaml | 5 +++++
 drivers/leds/rgb/leds-qcom-lpg.c                          | 4 +---
 2 files changed, 6 insertions(+), 3 deletions(-)
---
base-commit: ea1c4c7e648d1ca91577071fc42fdc219521098c
change-id: 20251114-lpg_triled_fix-44491b49b340

Best regards,
-- 
Fenglin Wu <fenglin.wu@oss.qualcomm.com>

