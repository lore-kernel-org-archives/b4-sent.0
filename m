From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Subject: [PATCH v2 0/2] clk: qcom: Add the Molokai GPU clock controller
Date: Fri, 20 Nov 2026 21:22:31 +0530
Message-Id: <20261120-molokai-gpucc-v2-0-e84a0869693f@yahoo.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNQQ6CMBBFr0JmbQ0tgRJX3sOwaKcDVIUhLRAJ4
 e4Crl2+5P33V4gUPEW4JSsEmn303O+gLglga/qGhHc7g0pVIaUsRMdvfhkvmmFCFM6QdUrnpc0
 d7JshUO0/Z+9R/ThO9kk4HpHDaH0cOSzn4SwP7197liIVqUab2TrTqMv7YlrmK3IH1bZtXxM6x
 kG8AAAA
X-Change-ID: 20261116-molokai-gpucc-daebd2758b5d
To: Bjorn Andersson <andersson@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 Taniya Das <taniya.das@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Venkat Yadlapati <venkat.yadlapati@yahoo.com>, 
 Abel Vesa <abel.vesa@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795189951; l=2096;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=IbD6OD7HPieTPh5DKfBJNtgPhbtkZR1mkHtbNkKgxGQ=;
 b=3iCV7kO9rnXh95d47GWcwzRcPpPPcHmNwx3kDaguPIlP2fJPegHrmgXFiL13WrZbV9vN23N3f
 nh00OkXHp27AC6D2ToBjFbQs/KxipWIVugfCEWL335XdOW0eLdJLfsf
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The graphics clock controller of the Qualcomm Molokai (SM8845) SoC is the
Kaanapali one, except for the PLL0 CONFIG_CTL_HI value and three branch
clocks that sit one register further. This documents a compatible for it
and handles it in the Kaanapali driver.

The SoC devicetree that uses it is sent separately in "Add support for
the Qualcomm Molokai (SM8845) and the Motorola Signature".

Tested on the Motorola Signature: the GPU clocks come up and the Adreno
829 runs.

I used an LLM (Claude) to help write these patches and their commit
messages. I reviewed all of them and tested the result on the device.

---
Changes in v2:
- Drop the Assisted-by trailers and the LLM notes from the commit
  messages, the LLM use is stated in this cover letter (Krzysztof).
- Pick up the Acked-by of Krzysztof and the Reviewed-by of Abel.
- Link to v1: https://patch.msgid.link/20261116-molokai-gpucc-v1-0-07cb3bf37c78@yahoo.com

To: Bjorn Andersson <andersson@kernel.org>
To: Abel Vesa <abelvesa@kernel.org>
To: Stephen Boyd <sboyd@kernel.org>
To: Brian Masney <bmasney+clk@redhat.com>
To: Jerome Brunet <jbrunet+clk@baylibre.com>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Konrad Dybcio <konradybcio@kernel.org>
To: Taniya Das <taniya.das@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org
Cc: linux-clk@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Venkat Yadlapati (2):
      dt-bindings: clock: qcom: sm8450-gpucc: Add Molokai GPU clock controller
      clk: qcom: gpucc-kaanapali: Add support for Molokai

 .../bindings/clock/qcom,sm8450-gpucc.yaml          |  1 +
 drivers/clk/qcom/Kconfig                           |  3 ++-
 drivers/clk/qcom/gpucc-kaanapali.c                 | 25 ++++++++++++++++++++++
 3 files changed, 28 insertions(+), 1 deletion(-)
---
base-commit: 6a876df4686788cd39128b62d7fcbff62f39278f
change-id: 20261116-molokai-gpucc-daebd2758b5d

Best regards,
--  
Venkat Yadlapati <venkat.yadlapati@yahoo.com>

