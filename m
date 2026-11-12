From: Suyuan Wang <shyckless@gmail.com>
Date: Thu, 12 Nov 2026 10:04:18 +0000
Subject: [PATCH] mshv_vtl: Release mem_dev through put_device()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-hyperv-v1-1-67144d71878c@gmail.com>
X-B4-Tracking: v=1; b=H4sIACGP9WoC/yXMQQ5AMBCF4avIrDXRVi1cRSwYg7GopqUh4u6K5
 Zf8710QyDMFqLMLPEUOvNoEmWeAc2cnEjwkgypUJaVUYj4d+SiMQaO1RqpMCSl2nkY+vqOm/R3
 2fiHc3jXc9wMq+w0pagAAAA==
X-Change-ID: 20261112-hyperv-55c5333ce654
To: haiyangz@microsoft.com, decui@microsoft.com, wei.liu@kernel.org
Cc: romank@linux.microsoft.com, ssengar@linux.microsoft.com, 
 namjain@linux.microsoft.com, linux-kernel@vger.kernel.org, 
 linux-hyperv@vger.kernel.org, mhklinux@outlook.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794477862; l=2707;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=BjfU+Rbjqy4Z7JxZoJTtVEHtxruhAGS1/m1B8KB8IlY=;
 b=WvAWhy9NDI3g+BAZA+frvhYpMFqdzLiDMXxRQ7QKq5MhBchStdcOIhAKz72CkCOwFTwVwG9vm
 c62ncDw5JjvClk1l1pIw1oC5EIn73N+AJmoAfCP4m4UFfhQyhPiSZtW
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

mem_dev is set up with device_initialize() and device_add(), but it is
freed with a plain kfree(), both on the device_add() error path and on
module exit:

    device_del(mem_dev);
    kfree(mem_dev);

It has no release() callback either. Freeing an initialized device with
kfree() skips the final put_device() and device_release(). On module
unload this leaks the device name and the device_private allocated by
device_add(), and on the device_add() error path at least the name is
leaked. The leak is small, and the fix is to free the device the way
the driver core expects.

Give mem_dev a release() callback that frees it, and use put_device()
on the error path and device_unregister() in mshv_vtl_exit(). Nothing
else changes: the devm_memremap_pages() mapping is still torn down by
device_del() as before.

Found with a static analysis tool and checked by hand.

Fixes: 7bfe3b8ea6e3 ("Drivers: hv: Introduce mshv_vtl driver")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Compile tested with CONFIG_MSHV_VTL=y only, I don't have an OpenHCL
setup to run it.
---
 drivers/hv/mshv_vtl_main.c | 15 ++++++++++-----
 1 file changed, 10 insertions(+), 5 deletions(-)

diff --git a/drivers/hv/mshv_vtl_main.c b/drivers/hv/mshv_vtl_main.c
index 2d4fe24cecbf..bbf43330e129 100644
--- a/drivers/hv/mshv_vtl_main.c
+++ b/drivers/hv/mshv_vtl_main.c
@@ -1346,6 +1346,11 @@ static struct miscdevice mshv_vtl_low = {
 	.minor = MISC_DYNAMIC_MINOR,
 };
 
+static void mshv_vtl_mem_dev_release(struct device *dev)
+{
+	kfree(dev);
+}
+
 static int __init mshv_vtl_init(void)
 {
 	int ret;
@@ -1412,17 +1417,18 @@ static int __init mshv_vtl_init(void)
 	}
 
 	device_initialize(mem_dev);
+	mem_dev->release = mshv_vtl_mem_dev_release;
 	dev_set_name(mem_dev, "mshv vtl mem dev");
 	ret = device_add(mem_dev);
 	if (ret) {
 		dev_err(dev, "mshv vtl mem dev add: %d\n", ret);
-		goto free_mem;
+		goto put_mem;
 	}
 
 	return 0;
 
-free_mem:
-	kfree(mem_dev);
+put_mem:
+	put_device(mem_dev);
 free_low:
 	misc_deregister(&mshv_vtl_low);
 free_hvcall:
@@ -1439,8 +1445,7 @@ static int __init mshv_vtl_init(void)
 
 static void __exit mshv_vtl_exit(void)
 {
-	device_del(mem_dev);
-	kfree(mem_dev);
+	device_unregister(mem_dev);
 	misc_deregister(&mshv_vtl_low);
 	misc_deregister(&mshv_vtl_hvcall_dev);
 	misc_deregister(&mshv_vtl_sint_dev);

---
base-commit: 630059a5a632377b9b7b487baccde92b7ae1dd47
change-id: 20261112-hyperv-55c5333ce654

Best regards,
--  
Suyuan Wang <shyckless@gmail.com>

