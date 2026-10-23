From: Ishu Brar <patches@brar.si>
Subject: [PATCH 0/2] clk: qcom: Add SM7250 display clock controller
Date: Fri, 23 Oct 2026 15:48:23 +0530
Message-Id: <20261023-dispcc-sm7250-v1-0-07bdefb99801@brar.si>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/y2O227CMBAFfyXyc43WGzsmUVXxHxUPvqzBbc3FG
 yokxL9jCI8jnZ3Zm2CqmVhM3U1U+s+cj4cG6qMTYe8OO5I5NhYIOCjAXsbMpxAkF4sGZKJekdL
 WaEii3ZwqpXx9+b63C/PF/1CYn5L3otL50kLzMhOFmN0rNHWfS0cNoFH3uFqjlkpyJeL2za+rM
 CrY7IrLf6twLF9Po3dMskHJ89QlM1h0fUwJcFRxcNqQh4Bm7ceI3pHXMRhrxfZ+fwCRzaYu/QA
 AAA==
X-Change-ID: 20261023-dispcc-sm7250-fe31e147540f
To: Bjorn Andersson <andersson@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ishu Brar <patches@brar.si>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792750706; l=2319;
 i=patches@brar.si; h=from:subject:message-id;
 bh=L42gwoB4IDYurR/qmI07tVWXUEgQ5w5RBtv6+zFe72U=;
 b=tYd7THEuqUZTOOWgDmSDL4eT9QMjuypIbKDrp8Jd4xyY05lmLtGf9+mWuBBOeQsRcE+/E5EqA
 r5L15OO1LfRDh5L2ECpje4kLbypWEa2FSgScoezE+K2EcjwnqduR/vh
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the display clock controller (DISPCC) of the Qualcomm SM7250 SoC
(Snapdragon 765/765G/768G): a binding patch with the header, and the
driver. It provides the MDSS clocks, the MDSS GDSC and the core reset.
Both patches are derived from the SM7150 ones, since the register layout
is the same. The differences are the Lucid PLL and the AHB, MDP and
rotator clocks, which take GPLL0 from the GCC. The PLL settings and the
frequency tables were checked against the downstream driver of the platform.

This series depends on the SM7250 GCC series from Shreeshankar [1] (the
Kconfig symbol SM_GCC_7250 and the GPLL0 parent come from it). The DPU
and MDSS series that follows will use this controller. The SoC devicetree
nodes are not part of this series.

Tested on a OnePlus Nord (a 7.3-rc7 based tree with the GCC series
applied): the controller probes and its clocks and power domain drive the
DSI panel. The DisplayPort clocks and the second DSI link are untested,
because the board has neither. I could not run dt_binding_check on the
binding; I will do that before a next version.

[1] https://lore.kernel.org/r/20261016042432.824-1-sreeshankar0910@gmail.com

Signed-off-by: Ishu Brar <patches@brar.si>
---
Ishu Brar (2):
      dt-bindings: clock: qcom: Document the SM7250 display clock controller
      clk: qcom: Add SM7250 display clock controller driver

 .../bindings/clock/qcom,sm7250-dispcc.yaml         |   73 ++
 drivers/clk/qcom/Kconfig                           |   11 +
 drivers/clk/qcom/Makefile                          |    1 +
 drivers/clk/qcom/dispcc-sm7250.c                   | 1009 ++++++++++++++++++++
 include/dt-bindings/clock/qcom,sm7250-dispcc.h     |   62 ++
 5 files changed, 1156 insertions(+)
---
base-commit: f5672a3dff0291d6a45eb0c258b9d2baeb4dc577
change-id: 20261023-dispcc-sm7250-fe31e147540f
prerequisite-message-id: <20261016042432.824-1-sreeshankar0910@gmail.com>
prerequisite-patch-id: 73b48e3c0861782784c45684336c1cb2c8b37852
prerequisite-patch-id: fb97b00b62996e3d3634185a803a33eb545522dd
prerequisite-patch-id: 8190bf61e50dbe2e09859505e8e4d8cb4ab02ddb
prerequisite-patch-id: 8c34692012f724a93c58e1df02338acec497344d
prerequisite-patch-id: 983ca91f160cca12047d9b0829c8cbbf4cc32e98

Best regards,
--  
Ishu Brar <patches@brar.si>

