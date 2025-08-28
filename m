From: Nickolay Goppen <setotau@yandex.ru>
Subject: [PATCH v4 0/3] Add SDM660 LPASS LPI TLMM
Date: Thu, 28 Aug 2025 22:23:36 +0300
Message-Id: <20250828-sdm660-lpass-lpi-v4-0-af4afdd52965@yandex.ru>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALissGgC/4XNwQ6CMAyA4VchOzszug2GJ9/DeCjbkCUKZNMFQ
 nh3Byc1Ri9N/ib9OpNgvbOBHLKZeBtdcH2XQuwyolvsLpY6k5oAA8kUCBrMrSgYvQ4YQpqOoqo
 ZIHBV5EjS2eBt48aNPJ1Tty7cez9tH2K+bn9gMaeMMsaN1BoUcHGcsDN23PsHWbEIr4D8AkACs
 ClLXjVSQ2k/Af4P4AkopBEoTA2VegOWZXkCxYl36zIBAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756409018; l=2199;
 i=setotau@yandex.ru; s=20250815; h=from:subject:message-id;
 bh=FZwL7XBHhgoAckbWlwEtMct61pGudjOnR3GfzuWKi34=;
 b=a1gGoYgpK4ZQPNnQPogN3Kj0i8goX1ZnwWD6Rmv0VGgTs1Meo08YF4SbuOLptdWi58nc7KIVN
 sABjBervZT0AQc1TZO0K10+nxUtrCOyG558kRTVY9ESg6GA2nunxBih
X-Developer-Key: i=setotau@yandex.ru; a=ed25519;
 pk=Og7YO6LfW+M2QfcJfjaUaXc8oOr5zoK8+4AtX5ICr4o=
X-Endpoint-Received: by B4 Relay for setotau@yandex.ru/20250815 with auth_id=492
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds SDM660 LPASS LPI TLMM pinctrl driver and
introduces pin_offset field for LPI pinctrl drivers to support
SDM660's quirky pin_offsets taken from an array with 
predefined offsets from downstream [1].

[1] https://git.codelinaro.org/clo/la/kernel/msm-4.4/-/blob/LA.UM.7.2.c27-07400-sdm660.0/drivers/pinctrl/qcom/pinctrl-lpi.c#L107

Signed-off-by: Nickolay Goppen <setotau@yandex.ru>
---
Changes in v4:
- Replaced pin_offset callback with a pin_offset field in lpi_pingroup struct
- Introduced LPI_PINGROUP_OFFSET macro with additional pin_offset field handling
- Introduced LPI_FLAG_USE_PREDEFINED_PIN_OFFSET flag for indicating use of predefined pin_offsets
- Replaced an array with offsets in SDM660 LPASS LPI TLMM driver with pin_offset defined for each pin in the new pin_offset field
- Link to v3: https://lore.kernel.org/r/20250825-sdm660-lpass-lpi-v3-0-65d4a4db298e@yandex.ru

Changes in v3:
- Fixed compilation of LPI drivers as modules by changing pin_offset function determination logic 
- Link to v2: https://lore.kernel.org/r/20250825-sdm660-lpass-lpi-v2-0-af7739f5c27e@yandex.ru

Changes in v2:
- Extended description of "pinctrl: qcom: Add SDM660 LPASS LPI TLMM" patch
- Resent using b4 relay
- Link to v1: https://lore.kernel.org/r/20250824-sdm660-lpass-lpi-v1-0-003d5cc28234@yandex.ru

---
Nickolay Goppen (2):
      pinctrl: qcom: lpass-lpi: Add ability to use custom pin offsets
      dt-bindings: pinctrl: qcom: Add SDM660 LPI pinctrl

Richard Acayan (1):
      pinctrl: qcom: Add SDM660 LPASS LPI TLMM

 .../pinctrl/qcom,sdm660-lpass-lpi-pinctrl.yaml     |  74 ++++++++++
 drivers/pinctrl/qcom/Kconfig                       |  10 ++
 drivers/pinctrl/qcom/Makefile                      |   1 +
 drivers/pinctrl/qcom/pinctrl-lpass-lpi.c           |  18 ++-
 drivers/pinctrl/qcom/pinctrl-lpass-lpi.h           |  18 +++
 drivers/pinctrl/qcom/pinctrl-sdm660-lpass-lpi.c    | 155 +++++++++++++++++++++
 6 files changed, 274 insertions(+), 2 deletions(-)
---
base-commit: d2798d0f96755807da0222cfc9793f2b1f38a2f1
change-id: 20250824-sdm660-lpass-lpi-a8b02a23861a

Best regards,
-- 
Nickolay Goppen <setotau@yandex.ru>

