From: Linfeng Sun <linfeng.sun.dev@gmail.com>
Date: Sat, 10 Oct 2026 20:22:58 +0800
Subject: [PATCH v3] vhost-scsi: reject delayed virtqueue setup
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-fix-warning-in-sbitmap_get-v3-1-33de562d1359@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/43NQQ6CMBCF4auQrq1pR1PAlfcwxrR1gDFSSIuoI
 dzdFjesjMuXvHz/xAJ6wsAO2cQ8jhSoc3HsNhmzjXY1crrGzUCAEqUoeEUv/tTekas5OR4MDa3
 uLzUO3CiAUmNlhRIsAr3H+F7w0/m7w8Pc0A5JTI+GwtD591IfZfr9FRollzxXuQULUmowx7rVd
 N/armUpNMKKkuonBZFCJXVs7nNRlGtqnucPZQoLhCEBAAA=
X-Change-ID: 20260908-fix-warning-in-sbitmap_get-b6229aefc060
To: "Michael S. Tsirkin" <mst@redhat.com>, 
 Jason Wang <jasowangio@gmail.com>, 
 Mike Christie <michael.christie@oracle.com>, 
 =?utf-8?q?Eugenio_P=C3=A9rez?= <eperezma@redhat.com>
Cc: virtualization@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Linfeng Sun <linfeng.sun.dev@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791634978; l=5354;
 i=linfeng.sun.dev@gmail.com; s=20261010; h=from:subject:message-id;
 bh=tSXH3z3FUfG59x/oF0TAiwVbAv/p4oxB4J5rJGqlY2Y=;
 b=R9/F95DB5IZDhvYSXThGx9td/upl0Ol2tRW2/50nKqagWnDoBfHyBsWBHFDC2RPqj6RhSInkI
 5Im3y0H5nVXDA4uV/bEGhNaPtutCZujlLfE9LoDZP1Heo85C5Ipd/NZ
X-Developer-Key: i=linfeng.sun.dev@gmail.com; a=ed25519;
 pk=IPHLe8L3bTveNcYFP12okRAIWs4eqaVd4jrqSNMj7UU=
X-Endpoint-Received: by B4 Relay for linfeng.sun.dev@gmail.com/20261010 with auth_id=1150
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

vhost_scsi_set_endpoint() allocates command pools only for I/O
virtqueues that are already set up, but publishes the backend for every
virtqueue. Userspace can complete a skipped queue after attaching the
endpoint, then kick it with scsi_tags uninitialized and trigger the
alloc_hint warning in sbitmap_get().

Delayed virtqueue setup is not supported. Leave skipped I/O virtqueues
inactive and reject changes to the vring size or addresses while an
endpoint is attached. Userspace must clear the endpoint before changing
the vring configuration.

I found this bug myself, though the patch was written with AI assistance.

Fixes: 25b98b64e284 ("vhost scsi: alloc cmds per vq instead of session")
Assisted-by: OpenAI-Codex:GPT-5.6
Signed-off-by: Linfeng Sun <linfeng.sun.dev@gmail.com>
---
I checked QEMU and found no evidence it's affected. I haven't checked 
VirtualBox because I am not familiar with it. However, the virtio spec 
doesn't require a specific operation order, so a new VMM could still 
trigger this issue. 

Crash log:
[   34.698961] ------------[ cut here ]------------
[   34.699385] WARNING: lib/sbitmap.c:286 at sbitmap_get+0x227/0x270, CPU#0: vhost-82/88
[   34.700542] Modules linked in:
[   34.701309] CPU: 0 UID: 0 PID: 88 Comm: vhost-82 Not tainted 7.3.0-rc2+ #14 PREEMPT(full)
[   34.701958] Hardware name: QEMU Ubuntu 24.04 PC v2 (i440FX + PIIX, arch_caps fix, 1996), BIOS 1.16.3-debian-1.16.3-2 04/01/2014
[   34.702717] RIP: 0010:sbitmap_get+0x227/0x270
[   34.703247] Code: 41 8d 5d 01 89 df 44 89 fe e8 f5 3a 46 ff 31 c0 44 39 fb 0f 43 d8 e8 38 46 46 ff 65 41 89 1c 24 e9 25 ff ff ff e8 29 46 46 ff <0f> 0b eb ba e8 20 46 46 ff 44 89 fe 31 ff 45 31 e4 e8 c3 3b 46 ff
[   34.704234] RSP: 0018:ffffc90000ec3bb0 EFLAGS: 00000246
[   34.704677] RAX: 0000000000000000 RBX: ffff88800500dee8 RCX: 0000000000000000
[   34.705166] RDX: 0000000000000000 RSI: 0000000000000000 RDI: ffff88800500dee8
[   34.705584] RBP: ffffc90000ec3be0 R08: 0000000000000000 R09: 0000000000000000
[   34.705988] R10: 0000000000000000 R11: 0000000000000000 R12: 0000000000000006
[   34.706477] R13: 0000000000000000 R14: 0000000000000000 R15: ffff8880050094d0
[   34.706955] FS:  0000000014d05380(0000) GS:ffff888099c36000(0000) knlGS:0000000000000000
[   34.707463] CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
[   34.707854] CR2: 00007c0c3c20e000 CR3: 0000000008e47000 CR4: 00000000000006f0
[   34.708592] Call Trace:
[   34.709259]  <TASK>
[   34.709822]  vhost_scsi_handle_vq+0x4a9/0x1b20
[   34.710437]  ? update_cfs_rq_load_avg+0x2e/0x230
[   34.710874]  vhost_scsi_handle_kick+0x2c/0x40
[   34.711292]  vhost_run_work_list+0xa6/0xf0
[   34.711673]  vhost_task_fn+0x76/0x1b0
[   34.712003]  ? __sanitizer_cov_trace_const_cmp1+0x1a/0x30
[   34.712506]  ? recalc_sigpending+0xe1/0x130
[   34.712890]  ? __pfx_vhost_task_fn+0x10/0x10
[   34.713325]  ret_from_fork+0x37a/0x630
[   34.713673]  ? __pfx_vhost_task_fn+0x10/0x10
[   34.714031]  ret_from_fork_asm+0x1a/0x30
[   34.714535] RIP: 0033:0x0
[   34.715201] Code: Unable to access opcode bytes at 0xffffffffffffffd6.
[   34.715587] RSP: 002b:0000000000000000 EFLAGS: 00000246 ORIG_RAX: 0000000000000010
[   34.716158] RAX: 0000000000000000 RBX: 000000000048bb20 RCX: 000000000041ca3d
[   34.716571] RDX: 0000000000000000 RSI: 0000000000000000 RDI: 0000000000000003
[   34.716957] RBP: 00007ffcac47c4e0 R08: 00000000ffffffff R09: 0000000000000000
[   34.717418] R10: 0000000000000000 R11: 0000000000000246 R12: 0000000000000004
[   34.717826] R13: 00007ffcac47c778 R14: 00000000004af868 R15: 0000000000000001
[   34.718363]  </TASK>
---
Changes in v3:
- Reject delayed virtqueue setup instead of activating it.
- Link to v2: https://patch.msgid.link/20260916-fix-warning-in-sbitmap_get-v2-1-e61a09047089@gmail.com

Changes in v2:
- Activate only the virtqueue specified by VHOST_SET_VRING_ADDR.
- Mask the userspace provided index before accessing the virtqueue array.
- Link to v1: https://patch.msgid.link/20260908-fix-warning-in-sbitmap_get-v1-1-767c2c211a2b@gmail.com
---
 drivers/vhost/scsi.c | 15 ++++++++++++---
 1 file changed, 12 insertions(+), 3 deletions(-)

diff --git a/drivers/vhost/scsi.c b/drivers/vhost/scsi.c
index 885fac5ed042..1710bc8e4381 100644
--- a/drivers/vhost/scsi.c
+++ b/drivers/vhost/scsi.c
@@ -2105,6 +2105,9 @@ vhost_scsi_set_endpoint(struct vhost_scsi *vs,
 
 		for (i = 0; i < vs->dev.nvqs; i++) {
 			vq = &vs->vqs[i].vq;
+			if (i >= VHOST_SCSI_VQ_IO && !vs->vqs[i].scsi_cmds)
+				continue;
+
 			mutex_lock(&vq->mutex);
 			vhost_vq_set_backend(vq, vs_tpg);
 			vhost_vq_init_access(vq);
@@ -2466,10 +2469,16 @@ vhost_scsi_ioctl(struct file *f,
 	default:
 		mutex_lock(&vs->dev.mutex);
 		r = vhost_dev_ioctl(&vs->dev, ioctl, argp);
-		if (r == -ENOIOCTLCMD)
-			r = vhost_vring_ioctl(&vs->dev, ioctl, argp);
-		else
+		if (r == -ENOIOCTLCMD) {
+			if (vs->vs_tpg &&
+			    (ioctl == VHOST_SET_VRING_NUM ||
+			     ioctl == VHOST_SET_VRING_ADDR))
+				r = -EBUSY;
+			else
+				r = vhost_vring_ioctl(&vs->dev, ioctl, argp);
+		} else {
 			vhost_scsi_flush(vs);
+		}
 		mutex_unlock(&vs->dev.mutex);
 		return r;
 	}

---
base-commit: c69023b5e16e5ffe9368603dca76d85bd544ee57

Best regards,
-- 
Linfeng Sun <linfeng.sun.dev@gmail.com>

