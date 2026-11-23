From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Subject: [PATCH v4 0/2] pinctrl: qcom: Add the Molokai TLMM
Date: Mon, 23 Nov 2026 21:33:11 +0530
Message-Id: <20261123-molokai-tlmm-v4-0-eed6eeaacc70@yahoo.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NTQ6CMBCG4auYrq3ptOVHV97DuGjLIFVKDUUiI
 dzdghsl0eWXzPPOSAK2FgM5bEbSYm+D9U0ccrshplLNBakt4iac8RQAUup87W/K0q52jmrFECW
 kmIAgkdxbLO1zyZ3O7x0e+oqmmxvzRWVD59th+dfDfPcj3QNlVGglc8kY40YfB1V5vzPekTnd8
 3+YRyz5vsxNXuSoYY3FB+ZshUXEmJRGZCgyBl94mqYXOU5CPDQBAAA=
X-Change-ID: 20261116-molokai-tlmm-ba0ee416e513
To: Bartosz Golaszewski <brgl@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795449791; l=2623;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=YghJL2tppXpXW7QuBO70OW5/eT9OsVH5AX0MYd/LT58=;
 b=jdib9YqWUdYP9CmFeEeboeYd4KM6eVAAJj3XnGw3kUbMuhFa8nDtYZnRJMb/8MnMhgJYdrSEQ
 XIyb8UkC5EiCplPTbxqKr5rmDxxyzFPb7EvL/eayW4eTYVysviml4Rj
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Molokai (SM8845) is a Qualcomm SoC derived from Kaanapali (SM8850), found
for example in the Motorola Signature. Its TLMM has the Kaanapali register
layout, but 205 GPIOs instead of 217, the Kaanapali pin functions on only
35 pins and a GPIO to PDC wakeup map with no entry in common. With the
Kaanapali tables a wake-capable GPIO interrupt is routed to the wrong PDC
input and never fires, so this adds a binding and a driver of its own.

The SoC and board devicetree that use it are sent separately in "Add
support for the Qualcomm Molokai (SM8845) and the Motorola Signature".

Tested on the Motorola Signature: the UFS reset, the keys and the GPIO
interrupts that go through the PDC (touchscreen, amplifiers) work.

I used an LLM (Claude) to help write these patches and their commit
messages. I reviewed all of them and tested the result on the device.

---
Changes in v4:
- Rebase on next-20261120 instead of the pinctrl for-next branch, no
  code change (Bartosz).
- Driver commit message: say that 35 pins share the Kaanapali functions
  instead of "different on every pin" (Bartosz).
- Link to v3: https://patch.msgid.link/20261120-molokai-tlmm-v3-0-e5fc37e37011@yahoo.com

Changes in v3:
- Drop the Assisted-by trailers and the LLM notes from the commit
  messages, the LLM use is stated in this cover letter (Krzysztof).
- Rewrap the GPIO to PDC wakeup map so that no entry is split across
  lines, no change in content.
- Pick up the Reviewed-by of Krzysztof.
- Link to v2: https://patch.msgid.link/20261116-molokai-tlmm-v2-0-429f8c8d8eb1@yahoo.com

Changes in v2:
- Binding: indent the example state node consistently.
- Driver: mark egpio as a GPIO function (MSM_GPIO_PIN_FUNCTION) so GPIO
  requests on pins muxed to egpio are not rejected.
- Kept the default 3-bit interrupt target field: on Molokai INTR_CFG[11]
  reads 0 out of reset and the target resets to 0x7.
- Link to v1: https://patch.msgid.link/20261116-molokai-tlmm-v1-0-3ba4840002cb@yahoo.com

---
Venkat Yadlapati (2):
      dt-bindings: pinctrl: qcom: Add Molokai TLMM
      pinctrl: qcom: Add Molokai TLMM driver

 .../bindings/pinctrl/qcom,molokai-tlmm.yaml        |  128 ++
 drivers/pinctrl/qcom/Kconfig.msm                   |   10 +
 drivers/pinctrl/qcom/Makefile                      |    1 +
 drivers/pinctrl/qcom/pinctrl-molokai.c             | 1681 ++++++++++++++++++++
 4 files changed, 1820 insertions(+)
---
base-commit: 909ef7a9a30fa139e69e555e3606680f5cca7726
change-id: 20261116-molokai-tlmm-ba0ee416e513

Best regards,
--  
Venkat Yadlapati <venkat.yadlapati@yahoo.com>

