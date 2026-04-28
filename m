From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/2] pinctrl: add support amlogic a9
Date: Tue, 28 Apr 2026 08:22:47 +0000
Message-Id: <20260428-a9-pinctrl-v1-0-cd611bb5f52d@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFhu8GkC/x2NQQqDQAxFryJZN+AEW9CrlC4yY6YGJEpGiiDe3
 bG7//g83gFFXKXA0Bzg8tOii1UIjwbSxPYV1LEyUEuvNlCP3OOqljaf63yGwEzUxQxViFwEo7O
 l6Vby4miyb/e1umTd/5335zwvrtRp4XcAAAA=
X-Change-ID: 20260129-a9-pinctrl-a9511aa224bf
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777364572; l=623;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=PCmmP7rOGoVbafpRKiOOAPfPVCbMnwaOJ+ZUHtPfBlM=;
 b=e1FzcU/DdusnZod18ZyvkoyVW7rZNPse69uMZZc413BNyHmbbnJrbiwJ1VkPw9aQaSbXm8ifR
 wQV9Qv7WVVXAztSi4LRYKW0F4GH3ocNk3lCQV3uZqDvKoFUq937AHqX
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add pinctrl bindings and driver about for amlogic a9.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Xianwei Zhao (2):
      dt-bindings: pinctl: amlogic,pinctrl-a4: Add compatible string for A9
      pinctrl: meson: support amlogic A9 SoC

 .../bindings/pinctrl/amlogic,pinctrl-a4.yaml       |  1 +
 drivers/pinctrl/meson/pinctrl-amlogic-a4.c         | 61 ++++++++++++++++++++--
 2 files changed, 57 insertions(+), 5 deletions(-)
---
base-commit: bd7fd288490c64835a74c05e631c102ce056d5e1
change-id: 20260129-a9-pinctrl-a9511aa224bf

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

