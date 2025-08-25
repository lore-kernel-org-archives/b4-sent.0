From: Nickolay Goppen <setotau@yandex.ru>
Subject: [PATCH v3 0/3] Add SDM660 LPASS LPI TLMM
Date: Mon, 25 Aug 2025 15:32:27 +0300
Message-Id: <20250825-sdm660-lpass-lpi-v3-0-65d4a4db298e@yandex.ru>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANtXrGgC/33NwQ6CMAyA4VchOzszOgbTk+9hPMxtSBMFsuoCI
 Xt3BycOxkuTv0m/Lox8QE/sXCws+IiEQ59DHgpmO9M/PEeXm4EAJTRUnNyrrgV/joYoT+RG3wU
 YkLouDctnY/AtTht5veXukN5DmLcPsVy3f7BYcsGFkE5ZCxpkdZlN7/x0DB+2YhH2gPoBQAZM2
 zTy1CoLjd8DKaUvs8ZqCvEAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756125160; l=1677;
 i=setotau@yandex.ru; s=20250815; h=from:subject:message-id;
 bh=zlQZif1/IWQ4cdmTyd6FCBlbHrEmXVxxNYu54P+m/DQ=;
 b=TxXsTAvL1VvuaQM3xl6MFmTEDgy+eVHZL6TUsnuGEO+O8HCOLAByMO8I5Ae1sch+FBnsr6fmL
 XUkbKds8X2cBHvmLmgW9DubxhriA14nMXR1ixMgvBfvzSXJ+RIQr8+y
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
Changes in v3:
- Fixed compilation of LPI drivers as modules by changing pin_offset function determination logic 
- Link to v2: https://lore.kernel.org/r/20250825-sdm660-lpass-lpi-v2-0-af7739f5c27e@yandex.ru

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
 drivers/pinctrl/qcom/pinctrl-lpass-lpi.c           |  18 +-
 drivers/pinctrl/qcom/pinctrl-lpass-lpi.h           |   7 +
 drivers/pinctrl/qcom/pinctrl-sdm660-lpass-lpi.c    | 196 +++++++++++++++++++++
 6 files changed, 304 insertions(+), 2 deletions(-)
---
base-commit: d2798d0f96755807da0222cfc9793f2b1f38a2f1
change-id: 20250824-sdm660-lpass-lpi-a8b02a23861a

Best regards,
-- 
Nickolay Goppen <setotau@yandex.ru>

