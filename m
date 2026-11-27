From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 13:09:38 +0000
Subject: [PATCH 5.10.y-cip] usb: gadget: f_fs: copy only received bytes on
 short ep0 read
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-cip-ffs-510b-v1-1-740c3a4fb9b3@certik.com>
X-B4-Tracking: v=1; b=H4sIABGBCWsC/02Nyw6CMBBFf4XM2kFaoCb+CnHRx1RqTEs6aDSEf
 7fVjct77msDphyI4dxskOkZOKRYhDg0YGcdr4TBFQ2yk0oIeUIbFvSecRSdQekGJVU/9Ep4KJU
 lkw+v79wEYyu69l0LcPl5/DA3smvdq2mjmdBkHe1cEVN0a0p3rPz4/wP7/gGP86ZQqQAAAA==
X-Change-ID: 20261127-cip-ffs-510b-2d462634361f
To: cip-dev@lists.cip-project.org
Cc: Pavel Machek <pavel@nabladev.com>, 
 Nobuhiro Iwamatsu <nobuhiro.iwamatsu.x90@mail.toshiba>, 
 Ulrich Hecht <uli@fpond.eu>, 
 Michael Bommarito <michael.bommarito@gmail.com>, linux-usb@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795784977; l=4141;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=DJqW2fanrrMBxibpJCrploJciD5vVQ8YJRECDs4tOi0=;
 b=i8Hl5WVTQgwvcj1ou3S2krOCa26XAw5gHG95oKNPxSQLFQPGHMExQ9CzUPfFVArwqZOP0Rp9c
 4TC87YgFKZSCaZ6PpjuQeQ/xPCDvwdxrKOjQ3khP+FuVpLpKYTLA5vU
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Michael Bommarito <michael.bommarito@gmail.com>

commit 4e036c10e7f4df5d951c69cc3697bc8e209c6d02 upstream.

ffs_ep0_read() allocates its control-OUT data buffer with
kmalloc() (not kzalloc) at the Length value from the Setup
packet, then copies that full len to userspace regardless of
how many bytes were actually received:

    data = kmalloc(len, GFP_KERNEL);
    ...
    ret = __ffs_ep0_queue_wait(ffs, data, len);
    if ((ret > 0) && (copy_to_user(buf, data, len)))
            ret = -EFAULT;

__ffs_ep0_queue_wait() returns req->actual, which on a short
control OUT transfer is strictly less than len.  The
copy_to_user() call still copies len bytes, so on a short OUT
the last (len - ret) bytes of the kmalloc() buffer --
uninitialised slab residue -- are delivered to the FunctionFS
daemon.

Short ep0 OUT completions are specified USB control-transfer
behavior and are produced by in-tree UDCs:

  * dwc2 continues on req->actual < req->length for ep0 DATA OUT
    (short-not-ok is the only ep0-OUT stall path).
  * aspeed_udc ends ep0 OUT on rx_len < ep->ep.maxpacket.
  * renesas_usbf logs "ep0 short packet" and completes the
    request.
  * dwc3 stalls on short IN but not on short OUT.

A short ep0 OUT is therefore not evidence of a broken UDC; it is
a normal condition f_fs has to cope with.  The sibling gadgetfs
implementation in drivers/usb/gadget/legacy/inode.c already does
this correctly via min(len, dev->req->actual) before
copy_to_user().  This patch brings f_fs.c to the same safe
pattern rather than trimming at a defensive layer.

The bug is reached from the FunctionFS device node, which in
real deployments is owned by the privileged gadget daemon
(adbd, UMS, composite gadget services, etc.); it is not
reachable from unprivileged userspace.  Linux host stacks
normally reject short-wLength control OUTs before they reach
the gadget, so reproducing this required a build that
bypasses that host-side check.  With the bypass in place, a
1-byte payload on a 64-byte Setup produces 63 bytes of
non-canary slab residue in the daemon's read buffer.

Fix by copying only ret (actually received) bytes to
userspace.

Fixes: ddf8abd25994 ("USB: f_fs: the FunctionFS driver")
Cc: stable <stable@kernel.org>
Assisted-by: Claude:claude-opus-4-7
Signed-off-by: Michael Bommarito <michael.bommarito@gmail.com>
Link: https://patch.msgid.link/20260419160359.1577270-1-michael.bommarito@gmail.com
Signed-off-by: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
[ adapted to 5.10.y-cip: keep the branch's likely/unlikely wrappers around the EP0 copy ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
5.10 wraps the EP0 read condition in likely() and unlikely(). The
backport keeps those wrappers and uses the completed length for the copy.

Tested on 5.10.272-cip79: drivers/usb/gadget/function/f_fs.o built
with W=1 before and after the patch, with no new diagnostics. The same
paired build passed on the 5.10.275-cip80 tip. On v5.10.275, the
patched kernel booted in QEMU and passed the FunctionFS dummy-HCD
endpoint creation smoke test. That test covered endpoint setup. The
runtime test was not rerun on the CIP tip.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.
---
 drivers/usb/gadget/function/f_fs.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/usb/gadget/function/f_fs.c b/drivers/usb/gadget/function/f_fs.c
index bb0b7c1e050b..5ad3ce302650 100644
--- a/drivers/usb/gadget/function/f_fs.c
+++ b/drivers/usb/gadget/function/f_fs.c
@@ -598,7 +598,7 @@ static ssize_t ffs_ep0_read(struct file *file, char __user *buf,
 
 		/* unlocks spinlock */
 		ret = __ffs_ep0_queue_wait(ffs, data, len);
-		if (likely(ret > 0) && unlikely(copy_to_user(buf, data, len)))
+		if (likely(ret > 0) && unlikely(copy_to_user(buf, data, ret)))
 			ret = -EFAULT;
 		goto done_mutex;
 

---
base-commit: bd8b111cdf1d9897bf4d826b7305a9c16bfe5f71
change-id: 20261127-cip-ffs-510b-2d462634361f

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

