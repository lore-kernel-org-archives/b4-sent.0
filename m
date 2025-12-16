From: Maud Spierings <maudspierings@gocontroll.com>
Date: Tue, 16 Dec 2025 11:47:35 +0100
Subject: [PATCH v2] pmdomain: fix collision in names when registering
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251216-genpd_fix-v2-1-1dddd24a61ef@gocontroll.com>
X-B4-Tracking: v=1; b=H4sIAMY4QWkC/22MQQqDMBAAvyJ7boq7tlZ68h9FiknWGLCJJBJaJ
 H9v6rnHGYbZIXKwHOFe7RA42Wi9K0CnCtQ8OsPC6sJANV2RsBWG3aqfk32LekLWN90pKQlKvwY
 u+ng9hsKzjZsPn2Od8Gf/XRIKFPKiRmo73cgGe+OVd1vwy3JW/gVDzvkLTwW6GqcAAAA=
X-Change-ID: 20251216-genpd_fix-0f1ed7d8cbb2
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1765882075; l=1464;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=uj2xDMAh+W4db9qhkggG33PBx94qxe489pvSR6NF8S4=;
 b=UMOWCJMmRd4UMPDYTdxMIkTcfxw2La02GOaVr9K4dT6IMII7yI1zgCaIC41vVvvQV+tobXJ0x
 aoinzTLYL4hAgg32f93MYw5i5oolkpBZMcN6PRecpxSKU1+SQ4wVBK2
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
Changes in v2:
- Change virt_dev->id into DEVICE_ID_SINGLE to drop the trailing index
  number.
- Link to v1: https://lore.kernel.org/r/20251216-genpd_fix-v1-1-b4ca268d3b31@gocontroll.com
---

It wasn't just errors, it started crashing but that is a seperate issue.
It at least loads normally with this change
---
 drivers/base/power.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/base/power.c b/drivers/base/power.c
index c71389422a..cffd043627 100644
--- a/drivers/base/power.c
+++ b/drivers/base/power.c
@@ -506,11 +506,11 @@ struct device *genpd_dev_pm_attach_by_id(struct device *dev,
 	if (!virt_dev)
 		return ERR_PTR(-ENOMEM);
 
-	dev_set_name(virt_dev, "genpd");
+	dev_set_name(virt_dev, "genpd:%u:%s", index, dev_name(dev));
 	virt_dev->bus = &genpd_bus_type;
 	virt_dev->parent = dev;
 	virt_dev->of_node = dev->of_node;
-	virt_dev->id = index;
+	virt_dev->id = DEVICE_ID_SINGLE;
 
 	ret = device_register(virt_dev);
 	if (ret) {

---
base-commit: 63898c48611dfe51409ff1f4e1c30de4b2737c48
change-id: 20251216-genpd_fix-0f1ed7d8cbb2

Best regards,
-- 
Maud Spierings <maudspierings@gocontroll.com>

