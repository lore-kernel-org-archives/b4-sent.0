From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Subject: [PATCH v5 0/2] pinctrl: qcom: Add the Molokai TLMM
Date: Thu, 26 Nov 2026 22:21:56 +0530
Message-Id: <20261126-molokai-tlmm-v5-0-ada44435bdd3@yahoo.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NTQ7CIBCG4asY1mJmgP7oynsYF0CnFrViSm00p
 ncXdNPU6PJL5nnnyQJ1jgLbLJ6so8EF5y9xZMsFs42+HIi7Km4mQOSImPPWn/1JO96f25YbDUQ
 Kc8pQskiuHdXu/s7t9p8dbuZItk+NdNG40Pvu8f43YLr7kR6QA5dGq1IBgLBm+9CN9yvrW5bSg
 /iHRcRKrOvSllVJBudYTrCAGZYRU1ZbWZAsAL+wmmI5wyphqnIira0tYIrHcXwB9Go7n3EBAAA
 =
X-Change-ID: 20261116-molokai-tlmm-ba0ee416e513
To: Bartosz Golaszewski <brgl@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795711916; l=3620;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=yvh6oQ30SWrOi/tTSyISUv5yU+UrT1z3j4lkCL44K4s=;
 b=TUnSqaGa5j4NPRi6MI79uQZ7pZdZMt243F7WrEDymEul+tILdlNAbxi1kI2uU7gjxEs8uJ5Hd
 AXAX3ea10smDNpwNh4e4LS+TMmp7XgWzdu0R4Q4h2R38rWqKQuLx5Fk
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Molokai (SM8845) is a Qualcomm SoC derived from Kaanapali (SM8850), found
for example in the Motorola Signature. Its TLMM has the Kaanapali register
layout, but 205 GPIOs instead of 217, the Kaanapali pin functions on only
29 pins and a GPIO to PDC wakeup map with no entry in common. With the
Kaanapali tables a wake-capable GPIO interrupt is routed to the wrong PDC
input and never fires, so this adds a binding and a driver of its own.

The SoC and board devicetree that use it are sent separately in "Add
support for the Qualcomm Molokai (SM8845) and the Motorola Signature".

Tested on the Motorola Signature: the UFS reset, the keys and the GPIO
interrupts that go through the PDC (touchscreen, amplifiers) work.

I used an LLM (Claude) to help write these patches and their commit
messages. I reviewed all of them and tested the result on the device.

---
Changes in v5:
- Binding commit message: Molokai does have SDC2, muxed on GPIOs; it
  only lacks the dedicated SDC2 pads of Kaanapali (Bartosz).
- Driver: add gp_mn on GPIO127 (Bartosz, Konrad).
- Driver: add the gp_pdm_mira, gp_pdm_mirb, rffe and grfc functions, and
  qup2_se5_l6, qup1_se5_l2_mirb and qup1_se5_l3_mirb for the second QUP
  mux setting of GPIO17, GPIO202 and GPIO203 (Konrad). The three RFFE
  buses share one rffe function, as Konrad suggested. The gp_mn,
  gp_pdm, rffe and grfc muxes are not in the downstream tables, they
  come from Konrad's review.
- Binding: add the new functions to the function enum. Krzysztof's
  Reviewed-by is kept, as the schema only gains enum entries.
- Driver: drop the comment above the pin group table (Konrad).
- Driver commit message and cover: 29 pins (not 35) now have the
  Kaanapali functions, as GPIO138-143 gained rffe and grfc.
- Link to v4: https://patch.msgid.link/20261123-molokai-tlmm-v4-0-eed6eeaacc70@yahoo.com

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

 .../bindings/pinctrl/qcom,molokai-tlmm.yaml        |  129 ++
 drivers/pinctrl/qcom/Kconfig.msm                   |   10 +
 drivers/pinctrl/qcom/Makefile                      |    1 +
 drivers/pinctrl/qcom/pinctrl-molokai.c             | 1727 ++++++++++++++++++++
 4 files changed, 1867 insertions(+)
---
base-commit: 909ef7a9a30fa139e69e555e3606680f5cca7726
change-id: 20261116-molokai-tlmm-ba0ee416e513

Best regards,
--  
Venkat Yadlapati <venkat.yadlapati@yahoo.com>

