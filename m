From: Maud Spierings <maudspierings@gocontroll.com>
Date: Tue, 16 Dec 2025 11:24:11 +0100
Subject: [PATCH] pmdomain: fix collision in names when registering
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251216-genpd_fix-v1-1-b4ca268d3b31@gocontroll.com>
X-B4-Tracking: v=1; b=H4sIAEozQWkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDI0Mz3fTUvIKU+LTMCl2DNMPUFPMUi+SkJCMloPqColSgMNis6NjaWgB
 HqCQ9WwAAAA==
X-Change-ID: 20251216-genpd_fix-0f1ed7d8cbb2
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1765880654; l=1145;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=tneaB0lP0sY2e7FnhYQtjMqwPpBtlkHTVuC1952xZu0=;
 b=bmwIfDYw7JrnGxba3qJ0nKLcj0IjvXzg/H0KGlSMXdlaETiNW1x1Mwpego20zPKEIQhOBx4c/
 TiePAGCJmZTC58PegjaGdL7lyiRjpncn0DhyM70CHuQHhVXO1L2cCqN
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After adding the imx8m-blk-ctrl driver errors started appearing about
the genpd device already being registered.

incorperate some extra device details in the device name so this
possible collision goes away.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
It wasn't just errors, it started crashing but that is a seperate issue.
It at least loads normally with this change
---
 drivers/base/power.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/base/power.c b/drivers/base/power.c
index c71389422a..af06f984c0 100644
--- a/drivers/base/power.c
+++ b/drivers/base/power.c
@@ -506,7 +506,7 @@ struct device *genpd_dev_pm_attach_by_id(struct device *dev,
 	if (!virt_dev)
 		return ERR_PTR(-ENOMEM);
 
-	dev_set_name(virt_dev, "genpd");
+	dev_set_name(virt_dev, "genpd:%u:%s", index, dev_name(dev));
 	virt_dev->bus = &genpd_bus_type;
 	virt_dev->parent = dev;
 	virt_dev->of_node = dev->of_node;

---
base-commit: 63898c48611dfe51409ff1f4e1c30de4b2737c48
change-id: 20251216-genpd_fix-0f1ed7d8cbb2

Best regards,
-- 
Maud Spierings <maudspierings@gocontroll.com>

