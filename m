From: Sam Day <me@samcday.com>
Date: Mon, 01 Jun 2026 18:12:55 +1000
Subject: [PATCH RESEND 14/16] clk: qcom: arch-agnostic pointer fmtstrings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260601-qcom-armv7-v1-14-05a08d87e476@samcday.com>
References: <20260601-qcom-armv7-v1-0-05a08d87e476@samcday.com>
In-Reply-To: <20260601-qcom-armv7-v1-0-05a08d87e476@samcday.com>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Michal Simek <michal.simek@amd.com>, 
 Angelo Dureghello <angelo@kernel-space.org>, 
 Eugen Hristev <ehristev@kernel.org>, Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Yao Zi <me@ziyao.cc>, Simon Glass <sjg@chromium.org>, 
 Sughosh Ganu <sughosh.ganu@arm.com>, George Chan <gchan9527@gmail.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>, 
 Tien Fong Chee <tien.fong.chee@altera.com>, Peng Fan <peng.fan@nxp.com>, 
 Alif Zakuan Yuslaimi <alif.zakuan.yuslaimi@altera.com>, 
 Anshul Dalal <anshuld@ti.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Tingting Meng <tingting.meng@altera.com>, Alice Guo <alice.guo@nxp.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 David Wronek <david.wronek@mainlining.org>, 
 Danila Tikhonov <danila@jiaxyga.com>, 
 Varadarajan Narayanan <quic_varada@quicinc.com>, 
 Lukasz Majewski <lukma@denx.de>, 
 Balaji Selvanathan <balaji.selvanathan@oss.qualcomm.com>, 
 Jens Reidel <adrian@mainlining.org>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780301569; l=1199;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=arEZXUejhz2XTT4qW5woBRmseXPtJT361FuxHNEfPWE=;
 b=YGl6s7PYpglxC0Ra9nY75aSB2l0cLhQD/4/Kc9HWWB+sV/W/HW0rrPnuafrWqPXb1VLm3uUyd
 1eq5pHfUWP4AHV1aZRfQKoKCZgVaJLQgkePvT+SpqIvlyPOkpfPz0pk
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Cleans up some warnings when building on arm32.

Signed-off-by: Sam Day <me@samcday.com>
---
 drivers/clk/qcom/clock-qcom.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/clk/qcom/clock-qcom.c b/drivers/clk/qcom/clock-qcom.c
index 6b46d9db744..0f8c7155784 100644
--- a/drivers/clk/qcom/clock-qcom.c
+++ b/drivers/clk/qcom/clock-qcom.c
@@ -77,8 +77,8 @@ void clk_enable_vote_clk(phys_addr_t base, const struct vote_clk *vclk)
 int qcom_gate_clk_en(const struct msm_clk_priv *priv, unsigned long id)
 {
 	if (id >= priv->data->num_clks || priv->data->clks[id].reg == 0) {
-		log_err("gcc@%#08llx: unknown clock ID %lu!\n",
-			priv->base, id);
+		log_err("gcc@%p: unknown clock ID %lu!\n",
+			(void *)priv->base, id);
 		return -ENOENT;
 	}
 
@@ -115,8 +115,8 @@ void clk_bcr_update(phys_addr_t apps_cmd_rcgr)
 			break;
 		udelay(1);
 	}
-	WARN(count == 50000, "WARNING: RCG @ %#llx [%#010x] stuck at off\n",
-	     apps_cmd_rcgr, readl(apps_cmd_rcgr));
+	WARN(count == 50000, "WARNING: RCG @ %p [%#010x] stuck at off\n",
+	     (void *)apps_cmd_rcgr, readl(apps_cmd_rcgr));
 }
 
 #define CFG_SRC_DIV_MASK	0b11111

-- 
2.54.0

