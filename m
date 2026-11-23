From: Shigeaki Asai <y-asai.0816@docomonet.jp>
Date: Mon, 23 Nov 2026 23:18:23 +0900
Subject: [PATCH RFC 1/2] clk: samsung: exynos-audss: defer probe until
 pll_in is available
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-exynos5-subcmu-defer-v1-1-43aef47d4f2b@docomonet.jp>
References: <20261123-exynos5-subcmu-defer-v1-0-43aef47d4f2b@docomonet.jp>
In-Reply-To: <20261123-exynos5-subcmu-defer-v1-0-43aef47d4f2b@docomonet.jp>
To: Krzysztof Kozlowski <krzk@kernel.org>, 
 Sylwester Nawrocki <s.nawrocki@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Marek Szyprowski <m.szyprowski@samsung.com>
Cc: linux-samsung-soc@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Shigeaki Asai <y-asai.0816@docomonet.jp>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795443504; l=1456;
 i=y-asai.0816@docomonet.jp; s=20261004; h=from:subject:message-id;
 bh=0WAaBWSTBR/BaFm9s6nACS8IfkOWalo+FbjaB+ytfE0=;
 b=ojdX6lEvfEj1MUJHgjI6r7HyjtQLZpgqI5HQW1eBkBLcHCNLBocqjpoWJlXr0HFqQp4hJI2QZ
 O/BlN2Pwov+CIyNi8aS4+xZmIwXyf2TU4dDIhFaVg2uQoiU88ETYC6S
X-Developer-Key: i=y-asai.0816@docomonet.jp; a=ed25519;
 pk=jkd95ViSn8i/X3oPMHYG1A8mae8IOwOKGE64kzLqC5c=
X-Endpoint-Received: by B4 Relay for y-asai.0816@docomonet.jp/20261004 with auth_id=1110
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The "pll_in" clock is optional, so a failed devm_clk_get() is silently
ignored and mout_audss is registered with pll_ref as its only parent.

On Exynos5800 (and Exynos5422) "pll_in" is CLK_MAU_EPLL, a gate clock
of the MAU sub-CMU. If the sub-CMU registration is deferred until the
power domains are available, this clock is not registered yet when the
audss clock controller probes. Audio then runs from the 24 MHz pll_ref
and 48 kHz playback is about twice as fast as it should be
("failed to reparent mout_audss to mau_epll: -22").

Defer the probe when "pll_in" returns -EPROBE_DEFER.

This patch was written with the help of Claude (claude-opus-5-5).

Signed-off-by: Shigeaki Asai <y-asai.0816@docomonet.jp>
---
 drivers/clk/samsung/clk-exynos-audss.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/clk/samsung/clk-exynos-audss.c b/drivers/clk/samsung/clk-exynos-audss.c
index e11ac67819ef..7c06350111ed 100644
--- a/drivers/clk/samsung/clk-exynos-audss.c
+++ b/drivers/clk/samsung/clk-exynos-audss.c
@@ -153,6 +153,9 @@ static int exynos_audss_clk_probe(struct platform_device *pdev)
 
 	pll_ref = devm_clk_get(dev, "pll_ref");
 	pll_in = devm_clk_get(dev, "pll_in");
+	if (pll_in == ERR_PTR(-EPROBE_DEFER))
+		return dev_err_probe(dev, -EPROBE_DEFER,
+				     "pll_in clock not ready\n");
 	if (!IS_ERR(pll_ref))
 		mout_audss_p[0] = __clk_get_name(pll_ref);
 	if (!IS_ERR(pll_in)) {

-- 
2.43.0

