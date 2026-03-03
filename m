From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Tue, 03 Mar 2026 16:25:18 +0100
Subject: [PATCH v2] clk: hisilicon: Improve deallocation in error path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260303-hisi-error-v2-1-7cd9b43d8fbb@posteo.net>
X-B4-Tracking: v=1; b=H4sIAF39pmkC/02MQQ7CIBBFr9LMWgwFI8WV9zBdtDBtWQhmaEhNw
 90d68bl+3n/7ZCRAma4NTsQlpBDigzq1IBbhjijCJ4ZlFQXqZUVCysCiRIJJ+XgzdR5bxTw4UU
 4he2IPXpmVtdE76Nd2u/6yxjZ/WdKK1phlBmd0daOV32fn9s54gp9rfUDCipp0qIAAAA=
X-Change-ID: 20240329-hisi-error-c00ad7f8dd72
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: Tao Lan <taolan@huawei.com>, linux-clk@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772551527; l=1298;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=W75+ROlkJ4ctU6rXqjndz3tp5n4Jy0ZaYQ7i/ITwlZU=;
 b=ZW94RwJBH7x5SH05HYGS4Nfr3uEkO4103SkA3Ao49766KC6OpDmkSAN/Q34LfIWk9OL56bjvU
 9GCViRxRSbBCtllj36E+Frki+qDa/vHLcIyUgIYd06TOrNWZ5nI7LbB
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Unmap 'base' if an error occurs after it has been mapped.

Reported-by: Tao Lan <taolan@huawei.com>
Closes: https://lore.kernel.org/lkml/ZNlSH+eWV8Sk3FYn@probook/
Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
Changes in v2:
- Rebase on v7.0-rc2
- Update my email address
- Reword the commit message somewhat
- Link to v1: https://lore.kernel.org/r/20240708-hisi-error-v1-1-727bc7399b63@gmx.net
---
 drivers/clk/hisilicon/clk.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/drivers/clk/hisilicon/clk.c b/drivers/clk/hisilicon/clk.c
index fae65127cd4aa8..08050ff1c8cf9a 100644
--- a/drivers/clk/hisilicon/clk.c
+++ b/drivers/clk/hisilicon/clk.c
@@ -70,7 +70,7 @@ struct hisi_clock_data *hisi_clk_init(struct device_node *np,
 
 	clk_data = kzalloc_obj(*clk_data);
 	if (!clk_data)
-		goto err;
+		goto err_base;
 
 	clk_data->base = base;
 	clk_table = kzalloc_objs(*clk_table, nr_clks);
@@ -83,6 +83,8 @@ struct hisi_clock_data *hisi_clk_init(struct device_node *np,
 	return clk_data;
 err_data:
 	kfree(clk_data);
+err_base:
+	iounmap(base);
 err:
 	return NULL;
 }

---
base-commit: 11439c4635edd669ae435eec308f4ab8a0804808
change-id: 20240329-hisi-error-c00ad7f8dd72

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

