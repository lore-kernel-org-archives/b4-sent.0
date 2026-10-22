From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Thu, 22 Oct 2026 23:52:39 +0200
Subject: [PATCH 1/4] clk: meson: g12a: fix fclk_div2p5 multiplier
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-fix-g12a-clk-v1-1-e2bd8f3f1afa@aliel.fr>
References: <20261022-fix-g12a-clk-v1-0-e2bd8f3f1afa@aliel.fr>
In-Reply-To: <20261022-fix-g12a-clk-v1-0-e2bd8f3f1afa@aliel.fr>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jian Hu <jian.hu@amlogic.com>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Ronald Claveau <linux-kernel-dev@aliel.fr>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=828;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=kmf21z98rptos6YhBfPRKtB/DG5G/xeS94e38Rd7M00=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ9at1j062/vqpNvFbynuv/zmVmqp9x1xU44b11/OfiLw+
 CbTTtWzHaUsDGJcDLJiiiz9cy1PvLt89MzXPeopMHNYmUCGMHBxCsBE7qUz/M9oLN/5IiL8XZ3i
 OlWejYrcvW5rM91kn39Km6B3RHPPAT9GhsnzL94waohu3Fz6avurlIffpgUoyup8Wfkk7P5h9pU
 lE7kA
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

g12a_fclk_div2p5 should be fclk divided by 2.5.
The mult has been declared as 1 which results
as fclk/5 instead of fclk/2.5.

Set mult=2 to get the correct div 2.5 rate.

Fixes: 085a4ea93d54 ("clk: meson: g12a: add peripheral clock controller")
Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
 drivers/clk/meson/g12a.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/clk/meson/g12a.c b/drivers/clk/meson/g12a.c
index d0d4c7b6dc82..4ec5f15daf98 100644
--- a/drivers/clk/meson/g12a.c
+++ b/drivers/clk/meson/g12a.c
@@ -995,7 +995,7 @@ static struct clk_regmap g12a_fclk_div7 = {
 };
 
 static struct clk_fixed_factor g12a_fclk_div2p5_div = {
-	.mult = 1,
+	.mult = 2,
 	.div = 5,
 	.hw.init = &(struct clk_init_data){
 		.name = "fclk_div2p5_div",

-- 
2.43.0

