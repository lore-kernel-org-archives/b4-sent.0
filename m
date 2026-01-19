From: Yang Xiwen <forbidden405@outlook.com>
Date: Tue, 20 Jan 2026 03:07:20 +0800
Subject: [PATCH v3 3/6] clk: add uclass id check to clk_get_parent()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260120-clk-reparent-v3-3-0d43d4b362ac@outlook.com>
References: <20260120-clk-reparent-v3-0-0d43d4b362ac@outlook.com>
In-Reply-To: <20260120-clk-reparent-v3-0-0d43d4b362ac@outlook.com>
To: Simon Glass <sjg@chromium.org>, Tom Rini <trini@konsulko.com>, 
 Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>, 
 Simon Glass <simon.glass@canonical.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768849639; l=845;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=z8RAmI39MslmxtsJNWHoIU88HjZWrYeA9Sj3Gni2MDQ=;
 b=eA3SH0a3h3MAHezL7mbybBTXNKIrnN+gdOIPjNxGUpLzNnS1J8191zYh09ZARzisqpQdlfg+q
 MP5UUucWlweBmMdEpr+USFYFP0Kh9tBFC331Fd5TYaFOl8r864eqQeV
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Check the uclass id in clk_get_parent() before casting dev->priv to
struct clk *.  This sanity check can be also found in some other places
and should be enforced.

Reviewed-by: Simon Glass <simon.glass@canonical.com>
Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/clk/clk-uclass.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/clk/clk-uclass.c b/drivers/clk/clk-uclass.c
index 0584429bed65..559420c85056 100644
--- a/drivers/clk/clk-uclass.c
+++ b/drivers/clk/clk-uclass.c
@@ -507,6 +507,10 @@ struct clk *clk_get_parent(struct clk *clk)
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

