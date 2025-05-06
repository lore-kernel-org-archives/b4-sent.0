From: George Moussalem <george.moussalem@outlook.com>
Date: Tue, 06 May 2025 09:43:34 +0400
Subject: [PATCH v2 2/6] dt-bindings: clock: qcom: ipq5018: remove bindings
 for XO clock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250506-ipq5018-cmn-pll-v2-2-c0a9fcced114@outlook.com>
References: <20250506-ipq5018-cmn-pll-v2-0-c0a9fcced114@outlook.com>
In-Reply-To: <20250506-ipq5018-cmn-pll-v2-0-c0a9fcced114@outlook.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Luo Jie <quic_luoj@quicinc.com>, 
 Lee Jones <lee@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 Arnd Bergmann <arnd@arndb.de>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746510258; l=916;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=JupKX6iwdtJMe4ecLVTA0mWjAGvKoKV28P3vMGpTlG0=;
 b=7p+yVQvKj5aQQRuj+czk6aiSi45ggNA8QFh8VJwga282xblu/OE1PGOvTXbw3Bj8u5hJmcLBj
 J5Cy+BBjW7MDWf5qvb38Bg7e8V4cI2apve30eAPFN79ZcDPH1FwxgBJ
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The XO and its source clock must be always-on and is enabled in the GCC
during probe. As such, remove the bindings for them.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 include/dt-bindings/clock/qcom,gcc-ipq5018.h | 2 --
 1 file changed, 2 deletions(-)

diff --git a/include/dt-bindings/clock/qcom,gcc-ipq5018.h b/include/dt-bindings/clock/qcom,gcc-ipq5018.h
index f3de2fdfeea11f4b8832b75a05e424ca347b3634..d4de5eaffee7b4cb81e0ff2dcbf9e6669c3da8f8 100644
--- a/include/dt-bindings/clock/qcom,gcc-ipq5018.h
+++ b/include/dt-bindings/clock/qcom,gcc-ipq5018.h
@@ -140,8 +140,6 @@
 #define GCC_WCSS_DBG_IFC_NTS_BDG_CLK			131
 #define GCC_WCSS_DBG_IFC_NTS_CLK			132
 #define GCC_WCSS_ECAHB_CLK				133
-#define GCC_XO_CLK					134
-#define GCC_XO_CLK_SRC					135
 #define GMAC0_RX_CLK_SRC				136
 #define GMAC0_TX_CLK_SRC				137
 #define GMAC1_RX_CLK_SRC				138

-- 
2.49.0

