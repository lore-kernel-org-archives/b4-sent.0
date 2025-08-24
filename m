From: Nickolay Goppen <setotau@yandex.ru>
Subject: [PATCH v2 0/3] Add SDM660 LPASS LPI TLMM
Date: Mon, 25 Aug 2025 00:05:23 +0300
Message-Id: <20250825-sdm660-lpass-lpi-v2-0-af7739f5c27e@yandex.ru>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJN+q2gC/32NQQqDMBBFryKzbso4UQld9R7iYmrSOtCqZFpRJ
 Hdv6gG6+fA+/Pd30BAlKFyKHWJYRGUaM9CpgH7g8RGM+MxASDU6qoz6V9Ogec6smlMMuxsSk3V
 NyZBncwx3WQ9l22UeRN9T3I6Hpfy1f2RLadAgWl/3PTmy1XXj0Yf1HD/QpZS+Fx94bLAAAAA=
X-Change-ID: 20250824-sdm660-lpass-lpi-a8b02a23861a
To: Bjorn Andersson <andersson@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-gpio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 ~postmarketos/upstreaming@lists.sr.ht, Nickolay Goppen <setotau@yandex.ru>, 
 Richard Acayan <mailingradian@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756069524; l=2014;
 i=setotau@yandex.ru; s=20250815; h=from:subject:message-id;
 bh=JEFpMbPlFzz53yrCK4CHoEeXJJEfFNfWrdbpvZv8miQ=;
 b=gRDjTC7anqZqS3M1vzY85tJBMbPBwzFwF/lg1BVr4ruObp/hTXAxIpJyeUuI5oss2t21TOnyx
 /ST9sSU+DH1DnlI0E4NBYLUVK7Z45eA0GcN4L9LKSkpYwOL3Y6No1AZ
X-Developer-Key: i=setotau@yandex.ru; a=ed25519;
 pk=Og7YO6LfW+M2QfcJfjaUaXc8oOr5zoK8+4AtX5ICr4o=
X-Endpoint-Received: by B4 Relay for setotau@yandex.ru/20250815 with auth_id=492
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds SDM660 LPASS LPI TLMM pinctrl driver and
introduces pin_offset callback for LPI pinctrl drivers to support
SDM660's quirky pin_offset function which uses an array with 
predefined offsets [1].

[1] https://git.codelinaro.org/clo/la/kernel/msm-4.4/-/blob/LA.UM.7.2.c27-07400-sdm660.0/drivers/pinctrl/qcom/pinctrl-lpi.c#L107

Signed-off-by: Nickolay Goppen <setotau@yandex.ru>
---
Changes in v2:
- Extended description of "pinctrl: qcom: Add SDM660 LPASS LPI TLMM" patch
- Resent using b4 relay
- Link to v1: https://lore.kernel.org/r/20250824-sdm660-lpass-lpi-v1-0-003d5cc28234@yandex.ru

---
Nickolay Goppen (2):
      pinctrl: qcom: lpass-lpi: Introduce pin_offset callback
      dt-bindings: pinctrl: qcom: Add SDM660 LPI pinctrl

Richard Acayan (1):
      pinctrl: qcom: Add SDM660 LPASS LPI TLMM

 .../pinctrl/qcom,sdm660-lpass-lpi-pinctrl.yaml     |  74 ++++++++
 drivers/pinctrl/qcom/Kconfig                       |  10 ++
 drivers/pinctrl/qcom/Makefile                      |   1 +
 drivers/pinctrl/qcom/pinctrl-lpass-lpi.c           |  13 +-
 drivers/pinctrl/qcom/pinctrl-lpass-lpi.h           |   2 +
 drivers/pinctrl/qcom/pinctrl-sc7280-lpass-lpi.c    |   1 +
 drivers/pinctrl/qcom/pinctrl-sc8280xp-lpass-lpi.c  |   1 +
 drivers/pinctrl/qcom/pinctrl-sdm660-lpass-lpi.c    | 196 +++++++++++++++++++++
 drivers/pinctrl/qcom/pinctrl-sm4250-lpass-lpi.c    |   1 +
 drivers/pinctrl/qcom/pinctrl-sm6115-lpass-lpi.c    |   1 +
 drivers/pinctrl/qcom/pinctrl-sm8250-lpass-lpi.c    |   1 +
 drivers/pinctrl/qcom/pinctrl-sm8350-lpass-lpi.c    |   1 +
 drivers/pinctrl/qcom/pinctrl-sm8450-lpass-lpi.c    |   1 +
 drivers/pinctrl/qcom/pinctrl-sm8550-lpass-lpi.c    |   1 +
 drivers/pinctrl/qcom/pinctrl-sm8650-lpass-lpi.c    |   1 +
 15 files changed, 303 insertions(+), 2 deletions(-)
---
base-commit: d2798d0f96755807da0222cfc9793f2b1f38a2f1
change-id: 20250824-sdm660-lpass-lpi-a8b02a23861a

Best regards,
-- 
Nickolay Goppen <setotau@yandex.ru>

