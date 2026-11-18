From: Suyuan Wang <shyckless@gmail.com>
Date: Wed, 18 Nov 2026 13:30:32 +0000
Subject: [PATCH] EDAC/versalnet: Fix device-name use-after-free on removal
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-edac-versalnet-v1-1-cee5b2d3cb25@gmail.com>
X-B4-Tracking: v=1; b=H4sIAHeo/WoC/yXMQQqDMBBG4avIrBswBkS9SuliTH51RNKSsVIQ7
 26sy2/x3k6KJFDqip0SNlF5xwz7KMhPHEcYCdlUlVVtrW0MAnuzISkvEasZXGh7V7rGM1OOPgm
 D/P7D5+u2fvsZfr0udBwn51M7SHIAAAA=
X-Change-ID: 20261118-edac-versalnet-f3d9b3038caa
To: tony.luck@intel.com, bp@alien8.de, shubhrajyoti.datta@amd.com
Cc: linux-edac@vger.kernel.org, linux-kernel@vger.kernel.org, 
 radhey.shyam.pandey@amd.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795008632; l=2204;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=sTtyzJiANnIvp7M1JNbpCfE+tCWHvVaQU2IfbQIiNEU=;
 b=ePMlEm6RensHEV8Xaa8mBur6V/XNR+lMpvzg4hG9hfo9o8doC3KcdGdr2YTBDqrVuq8lgPLn+
 0qH80Yqz5lRDQZOqTuyYn/PCZuidD6Ng2vR4LJCeChck3GVoEz/QmRr
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

mc_init() stores a pointer to the backing device's name in mci->dev_name
without copying the string:

	mci->dev_name = dev_name(dev);

remove_one_mc() then unregisters that device before calling
edac_mc_del_mc():

	device_unregister(mci->pdev);
	edac_mc_del_mc(mci->pdev);

device_unregister() can drop the last reference, and kobject_cleanup()
frees the device's name along with the device. edac_mc_del_mc() then
logs the controller removal through edac_dev_name(mci), i.e.
mci->dev_name, reading the freed name string.

Call edac_mc_del_mc() before device_unregister(), so the device and its
name stay alive until EDAC has logged and removed the controller.

Found with a static analysis tool and checked by hand.

Fixes: d5fe2fec6c40 ("EDAC: Add a driver for the AMD Versal NET DDR controller")
Link: https://lore.kernel.org/linux-edac/20260724171945.2812749-9-shubhrajyoti.datta@amd.com/
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
We found this independently and later found the earlier patch linked
above, which fixes the same bug as part of a larger series; this is a
standalone two-line version. The bad ordering predates the refactor in
62a9fc50e8d9 -- it was already in the original driver, in both the normal
remove path and the init-failure rollback path.

The change only reorders two cleanup calls. Checked by inspection; I
couldn't build it here (it needs an arm64 Zynq config and my arm64 cross
toolchain fails at an unrelated vdso step), and I don't have the hardware.
---
 drivers/edac/versalnet_edac.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/edac/versalnet_edac.c b/drivers/edac/versalnet_edac.c
index d59ba3904cda..075b0105c427 100644
--- a/drivers/edac/versalnet_edac.c
+++ b/drivers/edac/versalnet_edac.c
@@ -767,8 +767,8 @@ static void remove_one_mc(struct mc_priv *priv, int i)
 	struct mem_ctl_info *mci;
 
 	mci = priv->mci[i];
-	device_unregister(mci->pdev);
 	edac_mc_del_mc(mci->pdev);
+	device_unregister(mci->pdev);
 	edac_mc_free(mci);
 }
 



