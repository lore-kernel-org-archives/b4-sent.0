From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Subject: [PATCH 0/2] pinctrl: qcom: Add the Molokai TLMM
Date: Mon, 16 Nov 2026 01:49:22 +0530
Message-Id: <20261116-molokai-tlmm-v1-0-3ba4840002cb@yahoo.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQ5EMBRG4VeRu9bEZXQxryIWxT9coyotIhHvP
 mWW3+KckwK8INA7OcljlyBujuA0oXYwcw8lXTTlWa6ZWSvrJvc1otbJWtWYDHixRskFxWTx+Mj
 x7Kr677A1I9r1ftB1/QBl/OSdcAAAAA==
X-Change-ID: 20261116-molokai-tlmm-ba0ee416e513
To: Bartosz Golaszewski <brgl@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Cc: linux-arm-msm@vger.kernel.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794773962; l=1461;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=ycrpenfnV06XhWlfcVWQ1HMmfcwzHDxYlIujTz54+LI=;
 b=OXUKtRiR3bN02LazYY80nM1rysJOYuqGc7EfCK1ErDXCW/w7ClFnBr/9vpUf9KDOu9u//uHi2
 hjoXzWW0vnpC4l6q7FKapNOkjmB25tNDI83Mn6YY3MayXH4YGDBEZKy
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Molokai (SM8845) is a Qualcomm SoC derived from Kaanapali (SM8850), found
for example in the Motorola Signature. Its TLMM has the Kaanapali register
layout, but 205 GPIOs instead of 217, different functions on every pin and
a different GPIO to PDC wakeup map. With the Kaanapali tables a
wake-capable GPIO interrupt is routed to the wrong PDC input and never
fires, so this adds a binding and a driver of its own.

The SoC and board devicetree that use it are sent separately in "Add
support for the Qualcomm Molokai (SM8845) and the Motorola Signature".

Tested on the Motorola Signature: the UFS reset, the keys and the GPIO
interrupts that go through the PDC (touchscreen, amplifiers) work.

I used an LLM (Claude) to help write these patches and their commit
messages. I reviewed all of them and tested the result on the device.

---
Venkat Yadlapati (2):
      dt-bindings: pinctrl: qcom: Add Molokai TLMM
      pinctrl: qcom: Add Molokai TLMM driver

 .../bindings/pinctrl/qcom,molokai-tlmm.yaml        |  128 ++
 drivers/pinctrl/qcom/Kconfig.msm                   |   10 +
 drivers/pinctrl/qcom/Makefile                      |    1 +
 drivers/pinctrl/qcom/pinctrl-molokai.c             | 1679 ++++++++++++++++++++
 4 files changed, 1818 insertions(+)
---
base-commit: 7bbad7337a81d1d73559b783280a76a65a9de191
change-id: 20261116-molokai-tlmm-ba0ee416e513

Best regards,
--  
Venkat Yadlapati <venkat.yadlapati@yahoo.com>

