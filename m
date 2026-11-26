From: Jaegyun Lee <dreams200260@g.skku.edu>
Date: Thu, 26 Nov 2026 16:43:40 +0900
Subject: [PATCH v2] usb: gadget: f_fs: fix UAF read in INTERFACE_REVMAP
 ioctl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-ffs-revmap-v2-1-445e86b561dc@g.skku.edu>
X-B4-Tracking: v=1; b=H4sIACvjB2sC/22OSw6DMAwFr4KyblDsqulnxT0qFgk4kKICigG1Q
 ty9Ce2yy3l+HnsVTMETi1u2ikCLZz/0EfCQiao1fUPS15EFKtQAqKVzLGPxaUZ5vihQJw1ktRJ
 xYQzk/GuX3csv82wfVE3JkBrWMEkbTF+1Kfp5Uopp3HqehvDen1kgaf7eXUCCJDgiOu0MXlXR5
 Nx1c071LMpt2z6zA4bZ1gAAAA==
X-Change-ID: 20261126-ffs-revmap-78010561eb60
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Neill Kapron <nkapron@google.com>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Jaegyun Lee <dreams200260@g.skku.edu>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795679021; l=3771;
 i=dreams200260@g.skku.edu; s=20261126; h=from:subject:message-id;
 bh=mGP4dJRI5dVKVVI3t6CcFy7i3MLxyMc37ZVLWnt4iuA=;
 b=krablm811VIvfZOl5mHT85JdNyqt3jcsZjyaxRN09r7gstCHL10qMqILnDC1PoStAdByJfRZ9
 itXQ8tvCthuAbfxtf/I/E6QEB00w6jPss/zOnsSI9+ySr3+u3Ku/GH6
X-Developer-Key: i=dreams200260@g.skku.edu; a=ed25519;
 pk=vQE4ltNw5Q74mXWk3rPpCfclWKMKcHJ7J9YJ+gqaLUs=
X-Endpoint-Received: by B4 Relay for dreams200260@g.skku.edu/20261126 with auth_id=1649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ffs_ep0_ioctl() snapshots ffs->func without any lock or reference:

	struct ffs_function *func = ffs->func;
	ret = func ? ffs_func_revmap_intf(func, value) : -ENODEV;

ffs_func_revmap_intf() then walks func->interfaces_nums for
interfaces_count iterations. ffs_func_unbind() first sets
ffs->func = NULL, then after drain_workqueue() kfrees func->eps --
the allocation chunk that also holds interfaces_nums -- and later
still writes func->interfaces_nums = NULL.

An ioctl that read ffs->func before the NULL write can therefore be
inside the revmap walk while the chunk is freed.
John Keeping noted this in 2021:
https://lkml.rescloud.iu.edu/2112.0/00724.html

The following is the KASAN log:

  BUG: KASAN: slab-use-after-free in ffs_ep0_ioctl+0x29b/0x300
  Read of size 2 at addr ffff888051b4925a by task park/9666
  CPU: 1 UID: 0 PID: 9666 Comm: park Not tainted 7.4.0-rc3-g666539eecdf4 #1 PREEMPT(full)
  Call Trace:
   ffs_ep0_ioctl+0x29b/0x300
   __x64_sys_ioctl+0x18f/0x210
   do_syscall_64+0x132/0x7c0
  Allocated by task 9675:
   __kmalloc_noprof+0x357/0x810
   ffs_func_bind+0xbd1/0x1b00
   usb_add_function+0x219/0x8a0
   configfs_composite_bind+0xcd5/0x17f0
   gadget_bind_driver+0x288/0xc80
  Freed by task 9675:
   kfree+0x2ca/0x6e0
   ffs_func_unbind+0x2f2/0x570
   purge_configs_funcs+0x283/0x520
   configfs_composite_unbind+0xae/0x210
   gadget_unbind_driver+0x211/0x520
   ...
   gadget_dev_desc_UDC_store+0x18a/0x2f0
  The buggy address is located 602 bytes inside of
   freed 2048-byte region (kmalloc-2k)

Take ffs->eps_lock around the REVMAP snapshot and walk, and do the
ffs->func = NULL store in ffs_func_unbind() under the same lock. A walk
that started before the store finishes before it, and every later
ioctl sees NULL, so the walk can no longer overlap the free of the eps
chunk.

Reproduced and tested in QEMU (dummy_hcd) only, not on real UDC
hardware.

Fixes: ddf8abd25994 ("USB: f_fs: the FunctionFS driver")
Cc: stable@vger.kernel.org
Assisted-by: ZCode:GLM-5.4
Signed-off-by: Jaegyun Lee <dreams200260@g.skku.edu>
---
Changes in v2:
- Keep clearing ffs->func in its original place in ffs_func_unbind(),
  before functionfs_unbind(), and only do that store under eps_lock;
  leave the eps free path unchanged (Sashiko review).
- Link to v1: https://patch.msgid.link/20261126-ffs-revmap-v1-1-e1322f6fa290@g.skku.edu
---
 drivers/usb/gadget/function/f_fs.c | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/drivers/usb/gadget/function/f_fs.c b/drivers/usb/gadget/function/f_fs.c
index c64a268e98a43..df55c2cba6101 100644
--- a/drivers/usb/gadget/function/f_fs.c
+++ b/drivers/usb/gadget/function/f_fs.c
@@ -687,8 +687,13 @@ static long ffs_ep0_ioctl(struct file *file, unsigned code, unsigned long value)
 	long ret;
 
 	if (code == FUNCTIONFS_INTERFACE_REVMAP) {
-		struct ffs_function *func = ffs->func;
+		struct ffs_function *func;
+		unsigned long flags;
+
+		spin_lock_irqsave(&ffs->eps_lock, flags);
+		func = ffs->func;
 		ret = func ? ffs_func_revmap_intf(func, value) : -ENODEV;
+		spin_unlock_irqrestore(&ffs->eps_lock, flags);
 	} else if (gadget && gadget->ops->ioctl) {
 		ret = gadget->ops->ioctl(gadget, code, value);
 	} else {
@@ -4205,7 +4210,9 @@ static void ffs_func_unbind(struct usb_configuration *c,
 
 	if (ffs->func == func) {
 		ffs_func_eps_disable(func);
+		spin_lock_irqsave(&ffs->eps_lock, flags);
 		ffs->func = NULL;
+		spin_unlock_irqrestore(&ffs->eps_lock, flags);
 	}
 
 	/* Drain any pending AIO completions */

---
base-commit: 666539eecdf4db623f5e3c3e55cf9f2dfad24aa4
change-id: 20261126-ffs-revmap-78010561eb60

Best regards,
--  
Jaegyun Lee <dreams200260@g.skku.edu>

