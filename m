From: George Moussalem <george.moussalem@outlook.com>
Date: Sun, 25 May 2025 21:56:05 +0400
Subject: [PATCH 2/5] clk: qcom: gcc-ipq5018: fix GE PHY reset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250525-ipq5018-ge-phy-v1-2-ddab8854e253@outlook.com>
References: <20250525-ipq5018-ge-phy-v1-0-ddab8854e253@outlook.com>
In-Reply-To: <20250525-ipq5018-ge-phy-v1-0-ddab8854e253@outlook.com>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-clk@vger.kernel.org, George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748195765; l=1149;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=oIkUIGsEO4IxSACM3i9ZzN1oSf3eDEKLwbaKL+SIoYs=;
 b=02XFO8KJUlDf/GQd0oZSxvLXGTZYrGzhEljPdbdnmF3LQkWU+O1zbHOfU5UYGN6hY3jyv7wMk
 IdbCEfGcfhPBaDz4Y5AKdRWodS3NgeHf5YGFoZkJgwCqcH0fCYGK81c
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MISC reset is supposed to trigger a resets across the MDC, DSP, and
RX & TX clocks of the IPQ5018 internal GE PHY. So let's set the bitmask
of the reset definition accordingly in the GCC as per the downstream
driver.

Link: https://git.codelinaro.org/clo/qsdk/oss/kernel/linux-ipq-5.4/-/commit/00743c3e82fa87cba4460e7a2ba32f473a9ce932

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 drivers/clk/qcom/gcc-ipq5018.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/clk/qcom/gcc-ipq5018.c b/drivers/clk/qcom/gcc-ipq5018.c
index 70f5dcb96700f55da1fb19fc893d22350a7e63bf..02d6f08f389f24eccc961b9a4271288c6b635bbc 100644
--- a/drivers/clk/qcom/gcc-ipq5018.c
+++ b/drivers/clk/qcom/gcc-ipq5018.c
@@ -3660,7 +3660,7 @@ static const struct qcom_reset_map gcc_ipq5018_resets[] = {
 	[GCC_WCSS_AXI_S_ARES] = { 0x59008, 6 },
 	[GCC_WCSS_Q6_BCR] = { 0x18004, 0 },
 	[GCC_WCSSAON_RESET] = { 0x59010, 0},
-	[GCC_GEPHY_MISC_ARES] = { 0x56004, 0 },
+	[GCC_GEPHY_MISC_ARES] = { 0x56004, .bitmask = 0xf },
 };
 
 static const struct of_device_id gcc_ipq5018_match_table[] = {

-- 
2.49.0

