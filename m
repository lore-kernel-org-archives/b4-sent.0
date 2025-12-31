From: Yang Xiwen <forbidden405@outlook.com>
Date: Thu, 01 Jan 2026 03:52:48 +0800
Subject: [PATCH v2 2/5] clk: add uclass id check to clk_get_parent()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260101-clk-reparent-v2-2-3eb42b78c7f1@outlook.com>
References: <20260101-clk-reparent-v2-0-3eb42b78c7f1@outlook.com>
In-Reply-To: <20260101-clk-reparent-v2-0-3eb42b78c7f1@outlook.com>
To: Simon Glass <sjg@chromium.org>, Tom Rini <trini@konsulko.com>, 
 Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767210769; l=791;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=ekHy6JW3OFPDeKcnpOoMx+HO2QaD959tyRe/0bAViCE=;
 b=ZavlkEVSCLsdF5iRqiRFOCYbs9kXJECOWQT26/wSgxhDwISszV0g9M3QxY0BQRtnwR+5htyXH
 x+Zz9Svpyy5C5e/rBtRsSsq6ir1ZVmh1gvtNXer1nuCxQ+P8oEK32nA
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Check the uclass id in clk_get_parent() before casting dev->priv to
struct clk *.  This sanity check can be also found in some other places
and should be enforced.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/clk/clk-uclass.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/clk/clk-uclass.c b/drivers/clk/clk-uclass.c
index 2167cd5ad0fe..bd18de972bb9 100644
--- a/drivers/clk/clk-uclass.c
+++ b/drivers/clk/clk-uclass.c
@@ -502,6 +502,10 @@ struct clk *clk_get_parent(struct clk *clk)
 	pdev = dev_get_parent(clk->dev);
 	if (!pdev)
 		return ERR_PTR(-ENODEV);
+
+	if (device_get_uclass_id(pdev) != UCLASS_CLK)
+		return ERR_PTR(-ENODEV);
+
 	pclk = dev_get_clk_ptr(pdev);
 	if (!pclk)
 		return ERR_PTR(-ENODEV);

-- 
2.43.0

