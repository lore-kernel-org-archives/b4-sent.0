From: Yang Xiwen <forbidden405@outlook.com>
Date: Fri, 18 Aug 2023 01:04:01 +0800
Subject: [PATCH RESEND 2/5] clk: call log_debug() instead to avoid console
 log printing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230818-clk-fix-v1-2-49ec18f820bf@outlook.com>
References: <20230818-clk-fix-v1-0-49ec18f820bf@outlook.com>
In-Reply-To: <20230818-clk-fix-v1-0-49ec18f820bf@outlook.com>
To: Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1692291852; l=944;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=rF0dwZvgeJOMiuqcxICJYTlilfkM8yDDIOepIOXVwHY=;
 b=rSvWzZEYw1wZeS/cixeh4ZFcbGRiAF40fm9cqVlCBXKweMo9QX/eS8eJmOn+bXXvdbjyYpoIY
 ZExhG7evb7jAMW7FbRqcmsOZEj125Puht4Dusis0PamlH+rXemItOQi
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

it's a very common case to register a clock without a parent, such as
clk_register_fixed_rate(). Replace log_error() with log_debug() to avoid
useless console log if not debugging.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/clk/clk.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/clk/clk.c b/drivers/clk/clk.c
index a5a3461b66..a38daaac0c 100644
--- a/drivers/clk/clk.c
+++ b/drivers/clk/clk.c
@@ -24,8 +24,8 @@ int clk_register(struct clk *clk, const char *drv_name,
 
 	ret = uclass_get_device_by_name(UCLASS_CLK, parent_name, &parent);
 	if (ret) {
-		log_err("%s: failed to get %s device (parent of %s)\n",
-			__func__, parent_name, name);
+		log_debug("%s: failed to get %s device (parent of %s)\n",
+			  __func__, parent_name, name);
 	} else {
 		log_debug("%s: name: %s parent: %s [0x%p]\n", __func__, name,
 			  parent->name, parent);

-- 
2.34.1

