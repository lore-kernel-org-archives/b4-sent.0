From: Nikita Shubin <n.shubin@yadro.com>
Date: Tue, 14 May 2024 13:52:31 +0300
Subject: [PATCH] dmaengine: ioatdma: Fix missing kmem_cache_destroy()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240514-ioatdma_fixes-v1-1-2776a0913254@yadro.com>
X-B4-Tracking: v=1; b=H4sIAG5CQ2YC/x3LQQqFMAxF0a1Ixr/QSlVwKyKfaFPNwCqJiCDu3
 erwvse5QEmYFNriAqGDldeUw/0KGGdMExkOuaG0pbeV84ZX3MOC/8gnqWl8baOPoQmVg2wGVDK
 DYBrnVy2oO8l7bEKfyGvX3/cDq+M74HgAAAA=
To: Vinod Koul <vkoul@kernel.org>, Dave Jiang <dave.jiang@intel.com>, 
 Dan Williams <dan.j.williams@intel.com>
Cc: dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nikita Shubin <nikita.shubin@maquefel.me>, 
 Nikita Shubin <n.shubin@yadro.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1715683955; l=1016;
 i=n.shubin@yadro.com; s=20230718; h=from:subject:message-id;
 bh=TaDiVeYpCG0Gog6sHS4e83pIRXeaMHb4I90wYknNlpQ=;
 b=2r0fesdFAuB2thndx9sfMJ/dbUYz2qmIAG5YWpn7va1Sqt0J9PosnpdcOcSnHUcazw8ZCkLneKSV
 snq0jwzMA6Mfwz5uixHXRX80bber7nP+aQ7AEIMOT+zsQrPpAqfB
X-Developer-Key: i=n.shubin@yadro.com; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for n.shubin@yadro.com/20230718 with auth_id=161
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix missing kmem_cache_destroy() for ioat_sed_cache in
ioat_exit_module().

Noticed via:

```
modprobe ioatdma
rmmod ioatdma
modprobe ioatdma
debugfs: Directory 'ioat_sed_ent' with parent 'slab' already present!
```

Fixes: c0f28ce66ecf ("dmaengine: ioatdma: move all the init routines")
Signed-off-by: Nikita Shubin <n.shubin@yadro.com>
---
 drivers/dma/ioat/init.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/dma/ioat/init.c b/drivers/dma/ioat/init.c
index 9c364e92cb82..61329c279040 100644
--- a/drivers/dma/ioat/init.c
+++ b/drivers/dma/ioat/init.c
@@ -1445,6 +1445,7 @@ module_init(ioat_init_module);
 static void __exit ioat_exit_module(void)
 {
 	pci_unregister_driver(&ioat_pci_driver);
+	kmem_cache_destroy(ioat_sed_cache);
 	kmem_cache_destroy(ioat_cache);
 }
 module_exit(ioat_exit_module);

---
base-commit: a38297e3fb012ddfa7ce0321a7e5a8daeb1872b6
change-id: 20240514-ioatdma_fixes-7460f4fd7d51

Best regards,
-- 
Nikita Shubin <n.shubin@yadro.com>

