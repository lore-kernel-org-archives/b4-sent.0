From: Jaegyun Lee <dreams200260@g.skku.edu>
Date: Thu, 26 Nov 2026 15:40:43 +0900
Subject: [PATCH] usb: gadget: f_fs: fix UAF read in INTERFACE_REVMAP ioctl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-ffs-revmap-v1-1-e1322f6fa290@g.skku.edu>
X-B4-Tracking: v=1; b=H4sIAGrUB2sC/y2MQQrCMBBFr1Jm7UAmYCpepXSRpJN2BGPJqAild
 2+iLt/j/7eBchFWuHYbFH6LyiNXoFMHcfF5ZpSpMlhjHZF1mJJiHd79iv3FkDk74uAM1MNaOMn
 nGxvGH+sr3Dg+W6EtglfGUHyOS1P/TrMW9v0AoERnaY0AAAA=
X-Change-ID: 20261126-ffs-revmap-78010561eb60
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Neill Kapron <nkapron@google.com>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Jaegyun Lee <dreams200260@g.skku.edu>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795675243; l=4099;
 i=dreams200260@g.skku.edu; s=20261126; h=from:subject:message-id;
 bh=lGzl9QWbGZO+/ZfDqZ6tmIIpCKGN1RaRxZQ6vywnsN8=;
 b=iR7+gtHg34TMl/noXXFkqyYklPjW6DUIXJ3MJNr8o2RdygcdSfsN34tRNkMNizYgPjQHT4CFN
 zgk0h/drSzNAf5375kXD3vaZ2/jiDjHgV8d8aia/G4Rb7avWpGQ1E8O
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

Take ffs->eps_lock around the REVMAP snapshot and walk, and move the
ffs->func = NULL write and the free of the eps chunk in
ffs_func_unbind() under the same lock.

Reproduced and tested in QEMU (dummy_hcd) only, not on real UDC
hardware.

Fixes: ddf8abd25994 ("USB: f_fs: the FunctionFS driver")
Cc: stable@vger.kernel.org
Assisted-by: ZCode:GLM-5.4
Signed-off-by: Jaegyun Lee <dreams200260@g.skku.edu>
---
 drivers/usb/gadget/function/f_fs.c | 15 ++++++++++-----
 1 file changed, 10 insertions(+), 5 deletions(-)

diff --git a/drivers/usb/gadget/function/f_fs.c b/drivers/usb/gadget/function/f_fs.c
index c64a268e98a43..c824d1d5ce571 100644
--- a/drivers/usb/gadget/function/f_fs.c
+++ b/drivers/usb/gadget/function/f_fs.c
@@ -687,8 +687,13 @@ static long ffs_ep0_ioctl(struct file *file, unsigned code, unsigned long value)
 	long ret;
 
 	if (code == FUNCTIONFS_INTERFACE_REVMAP) {
-		struct ffs_function *func = ffs->func;
+		struct ffs_function *func;
+		unsigned long iflags;
+
+		spin_lock_irqsave(&ffs->eps_lock, iflags);
+		func = ffs->func;
 		ret = func ? ffs_func_revmap_intf(func, value) : -ENODEV;
+		spin_unlock_irqrestore(&ffs->eps_lock, iflags);
 	} else if (gadget && gadget->ops->ioctl) {
 		ret = gadget->ops->ioctl(gadget, code, value);
 	} else {
@@ -4203,10 +4208,8 @@ static void ffs_func_unbind(struct usb_configuration *c,
 	unsigned count = ffs->eps_count;
 	unsigned long flags;
 
-	if (ffs->func == func) {
+	if (ffs->func == func)
 		ffs_func_eps_disable(func);
-		ffs->func = NULL;
-	}
 
 	/* Drain any pending AIO completions */
 	drain_workqueue(ffs->io_completion_wq);
@@ -4217,13 +4220,14 @@ static void ffs_func_unbind(struct usb_configuration *c,
 
 	/* cleanup after autoconfig */
 	spin_lock_irqsave(&func->ffs->eps_lock, flags);
+	if (ffs->func == func)
+		ffs->func = NULL;
 	while (count--) {
 		if (ep->ep && ep->req)
 			usb_ep_free_request(ep->ep, ep->req);
 		ep->req = NULL;
 		++ep;
 	}
-	spin_unlock_irqrestore(&func->ffs->eps_lock, flags);
 	kfree(func->eps);
 	func->eps = NULL;
 	/*
@@ -4235,6 +4239,7 @@ static void ffs_func_unbind(struct usb_configuration *c,
 	func->function.ss_descriptors = NULL;
 	func->function.ssp_descriptors = NULL;
 	func->interfaces_nums = NULL;
+	spin_unlock_irqrestore(&func->ffs->eps_lock, flags);
 
 }
 

---
base-commit: 666539eecdf4db623f5e3c3e55cf9f2dfad24aa4
change-id: 20261126-ffs-revmap-78010561eb60

Best regards,
--  
Jaegyun Lee <dreams200260@g.skku.edu>

