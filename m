From: Aiden Isik <aidenisik@member.fsf.org>
Date: Tue, 18 Aug 2026 22:58:36 +0100
Subject: [PATCH v2 2/3] clk: samsung: clk-pll: Add support for pll_309
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260818-for-next-lucky7-clock-v2-2-cda0cc80f158@member.fsf.org>
References: <20260818-for-next-lucky7-clock-v2-0-cda0cc80f158@member.fsf.org>
In-Reply-To: <20260818-for-next-lucky7-clock-v2-0-cda0cc80f158@member.fsf.org>
To: Krzysztof Kozlowski <krzk@kernel.org>, 
 Sylwester Nawrocki <s.nawrocki@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Rob Herring <robh@kernel.org>, Conor Dooley <conor+dt@kernel.org>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Aiden Isik <aidenisik+git@member.fsf.org>
Cc: linux-samsung-soc@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-hardening@vger.kernel.org, 
 Aiden Isik <aidenisik@member.fsf.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1487;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=SNzpKyzyVzqFs6rOSQCcEFpC4iw9RoBw0UMuhIAXVh0=;
 b=owEBbQKS/ZANAwAIAUknAbLEetfrAcsmYgBqhNWStfOQgiLZQOyJJ6wRF50DStw5mBJeTHKnp
 +7c5NSpeCaJAjMEAAEIAB0WIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCaoTVkgAKCRBJJwGyxHrX
 69e+EADIBPeCCqmCFyg3DfzQStsorxafe8K9/BxDXS4EDg6wwFzbJPq4Xva8MeTapq7bmyPyGPV
 A7DqygWN3KzgG/VQUkTJt/CrWwp6zmKT8jzslL6jnjYg1xAzfHNg8TdxdXo8LkjUPtjf0wL6IRY
 bS7E6hpuWOl3oucTteKZRH1P3vljDTpaEABJ0VF3m31Y38jQTATB6so4g1upFHYSXHMiseZIYQf
 Uoxz9EDM+UbMZcW4Q5pkCJdpUG2Ehuoh5+PJhA3FWg0xqFWpVfaoRkPoqg8cPRY+SWZRhYofZTP
 CeHtRgmIQCbjqon2Lzlm2AOYX00qj/sIhLc0S8RM1xS2T83tgYLZz+ii6GUBJjYESFzqDJ0/CsY
 BIBrv28d4G9gw26BlF6F4rC6k39WV5ED9XcSMW82sxLhRDX4cSmczmNScQfnvXgEV7YDDnX8Jqy
 2OwYDrG0u6H4/lLAgyh5pV2cBtOQ9EiuntnfbDbgmofkvGmGQo8SHKfZWtgj7J3yeKMcQaHJSNr
 reJ7ZjXXPEOVtpn6PGnQ7BAqFzsZKYRrtDc4dZQMb+pGe8UYFxu3a63q4khjIBREn0yAFjCXA8D
 0vVSQn30LiGpW8IeExpKFJFfQhrfj8KNUgu4SNApAKFYDxIzE5UtdnNXchFM/c8zbOEQQcdJYBm
 eikX0ucIQta1fKA==
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pll_309 (referred to in the downstream kernel sources as frd_309_rpll) is
one of two PLLs used in the Exynos5515 SoC. It is an integer/fractional
PLL with an FVCO of 600-2400MHz.

It has the same locktime (500), and kdiv/mdiv/pdiv/sdiv masks and shifts
as pll_531x, so it can be handled in exactly the same way.

When defining a PLL, the "con" parameter should be set to the CON3
register, like this:

PLL(pll_309, CLK_FOUT_AUD_PLL, "fout_aud_pll", "oscclk",
    PLL_LOCKTIME_PLL_AUD, PLL_CON3_PLL_AUD, NULL),

Signed-off-by: Aiden Isik <aidenisik@member.fsf.org>
---
 drivers/clk/samsung/clk-pll.c | 1 +
 drivers/clk/samsung/clk-pll.h | 1 +
 2 files changed, 2 insertions(+)

diff --git a/drivers/clk/samsung/clk-pll.c b/drivers/clk/samsung/clk-pll.c
index e74552846ba3..73584fd1da5a 100644
--- a/drivers/clk/samsung/clk-pll.c
+++ b/drivers/clk/samsung/clk-pll.c
@@ -1728,6 +1728,7 @@ static void __init _samsung_clk_register_pll(struct samsung_clk_provider *ctx,
 		break;
 	case pll_531x:
 	case pll_4311:
+	case pll_309:
 		init.ops = &samsung_pll531x_clk_ops;
 		break;
 	case pll_1031x:
diff --git a/drivers/clk/samsung/clk-pll.h b/drivers/clk/samsung/clk-pll.h
index d6eb3246611b..2457cf47c109 100644
--- a/drivers/clk/samsung/clk-pll.h
+++ b/drivers/clk/samsung/clk-pll.h
@@ -53,6 +53,7 @@ enum samsung_pll_type {
 	pll_1031x,
 	pll_a9fracm,
 	pll_a9fraco,
+	pll_309,
 };
 
 #define PLL_RATE(_fin, _m, _p, _s, _k, _ks) \

-- 
2.54.0

