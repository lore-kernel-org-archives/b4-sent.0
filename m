From: Chuan Liu <chuan.liu@amlogic.com>
Date: Fri, 07 Feb 2025 17:36:10 +0800
Subject: [PATCH] clk: Correct the data types of the variables in
 clk_calc_new_rates
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250207-correct_data_types-v1-1-f22bc7ea220d@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAAnUpWcC/x3MTQqAIBBA4avErBNM+oGuEhGTTjUbi1GiEO+et
 PwW7yUIJEwBxiqB0M2BT1/Q1BXYA/1Oil0xGG06bfSg7ClCNi4OIy7xvSioDR0SYtuveoASXkI
 bP/90mnP+AOo8U/tkAAAA
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1738921022; l=877;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=kAjBoWOCJ4Ktd9GA2YrUkGuLwEKid48PkvX+9Mpiwa0=;
 b=bOGjHFE86GTkOgfuiMiFJ2HgIDxYB+nL6hQ5zLfsBT3io0i9+CYMt0vF2wV3Q9XTRoJola1oj
 HpJMjHnIE+UA0Xg1yf8L4IHfXfd+Lh0V4FU+6TNriHw4gihEglu4w+i
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In clk_calc_new_rates, the "ret" is only used to store the return value
of clk_core_determine_round_nolock, and the data type of the return
value of clk_core_determine_round_nolock is int.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/clk.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/clk/clk.c b/drivers/clk/clk.c
index 9b45fa005030..e153d1901a60 100644
--- a/drivers/clk/clk.c
+++ b/drivers/clk/clk.c
@@ -2283,7 +2283,7 @@ static struct clk_core *clk_calc_new_rates(struct clk_core *core,
 	unsigned long min_rate;
 	unsigned long max_rate;
 	int p_index = 0;
-	long ret;
+	int ret;
 
 	/* sanity */
 	if (IS_ERR_OR_NULL(core))

---
base-commit: 1e1fd26ed4ca05cc1f0e5857918da4dd54967f7d
change-id: 20250207-correct_data_types-fadaeaa46b07

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

