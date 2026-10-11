From: Linfeng Sun <linfeng.sun.dev@gmail.com>
Date: Sun, 11 Oct 2026 15:33:30 +0800
Subject: [PATCH] vhost: reject backend enable without a kick file
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-fix-null-pointer-in-vhost_test_set_backend-v1-1-60b2f12d64c6@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWNQQrCMBBFr1Jm7UBSo1KvIqWk6WhHy6Rk0iKU3
 t2omw9v8d/bQCkxKVyrDRKtrBylgD1UEEYvD0IeCkNt6rM11uKd3yjLNOEcWTIlZMF1jJq7TGW
 Uctf78CIZ0DTu2JA7Be8uUIRzovL+xW7tn3XpnxTytwD7/gHIgGoYjgAAAA==
X-Change-ID: 20261011-fix-null-pointer-in-vhost_test_set_backend-09439e45ca47
To: "Michael S. Tsirkin" <mst@redhat.com>, 
 Jason Wang <jasowangio@gmail.com>, 
 =?utf-8?q?Eugenio_P=C3=A9rez?= <eperezma@redhat.com>
Cc: kvm@vger.kernel.org, virtualization@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Linfeng Sun <linfeng.sun.dev@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791704011; l=5233;
 i=linfeng.sun.dev@gmail.com; s=20261010; h=from:subject:message-id;
 bh=eZ1DZ28a+86fOznwSiX0c0JcYbu2CGeoKTJCHCyhpfo=;
 b=1llHowXxVWEg+42F2EhlCrPKV4cn91bxeVpvDzNIRuoH/4LV+e9ZI9Rhb3yDjYylp1SLiCl91
 GEdpgkEWKiOAE/2SD9hi0VfgumH/5iH+/1fq68IuWqcLchET5977aEh
X-Developer-Key: i=linfeng.sun.dev@gmail.com; a=ed25519;
 pk=IPHLe8L3bTveNcYFP12okRAIWs4eqaVd4jrqSNMj7UU=
X-Endpoint-Received: by B4 Relay for linfeng.sun.dev@gmail.com/20261010 with auth_id=1150
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enabling a backend without VHOST_SET_VRING_KICK dereferences a NULL
vq->kick in vhost_poll_start(). Reject the request with -EINVAL.

Fixes: 264ee5aa81ec ("tools/virtio: Add --reset")
Assisted-by: OpenAI-Codex:GPT-5.6
Signed-off-by: Linfeng Sun <linfeng.sun.dev@gmail.com>
---
I used // because b4 ignores lines starting with #. Please uncomment those 
lines before reproducing.
---- reproduce.c ----
// #include <fcntl.h>
// #include <linux/vhost.h>
// #include <stdint.h>
// #include <stdlib.h>
// #include <sys/ioctl.h>
// #include <unistd.h>

// #define VHOST_TEST_SET_BACKEND _IOW(VHOST_VIRTIO, 0x32, int)

static char ring[4096];

int main(void)
{
	struct vhost_memory *memory;
	struct vhost_vring_state state = { .num = 1 };
	struct vhost_vring_addr addr = { 0 };
	struct vhost_vring_file backend = { 0 };
	int fd;

	memory = calloc(1, sizeof(*memory) + sizeof(memory->regions[0]));
	memory->nregions = 1;
	memory->regions[0].memory_size = sizeof(ring);
	memory->regions[0].userspace_addr = (uintptr_t)ring;

	addr.desc_user_addr = (uintptr_t)ring;
	addr.avail_user_addr = (uintptr_t)ring + 64;
	addr.used_user_addr = (uintptr_t)ring + 128;

	fd = open("/dev/vhost-test", O_RDWR);
	ioctl(fd, VHOST_SET_OWNER, NULL);
	ioctl(fd, VHOST_SET_MEM_TABLE, memory);
	ioctl(fd, VHOST_SET_VRING_NUM, &state);
	ioctl(fd, VHOST_SET_VRING_ADDR, &addr);
	return ioctl(fd, VHOST_TEST_SET_BACKEND, &backend);
}

---- crash log ----
[   12.537464] BUG: kernel NULL pointer dereference, address: 0000000000000008
[   12.538119] #PF: supervisor read access in kernel mode
[   12.538452] #PF: error_code(0x0000) - not-present page
[   12.538855] PGD 8ddb067 P4D 8ddb067 PUD 8d3b067 PMD 0 
[   12.539665] Oops: Oops: 0000 [#1] SMP NOPTI
[   12.540406] CPU: 0 UID: 0 PID: 88 Comm: poc Tainted: G           OE       7.3.0-rc2+ #1 PREEMPT(full) 
[   12.541088] Tainted: [O]=OOT_MODULE, [E]=UNSIGNED_MODULE
[   12.541411] Hardware name: QEMU Standard PC (Q35 + ICH9, 2009), BIOS 1.16.3-debian-1.16.3-2 04/01/2014
[   12.542015] RIP: 0010:vhost_poll_start+0x41/0xf0
[   12.542802] Code: 8f fe 48 83 7b 10 00 74 1c 31 db e8 d9 d1 8f fe 89 d8 5b 41 5c 41 5d 5d 31 d2 31 c9 31 f6 31 ff c3 cc cc cc cc e8 bf d1 8f fe <49> 8b 44 24 08 4c 8b 68 48 4d 85 ed 74 7b e8 ac d1 8f fe 4c 89 e7
[   12.543670] RSP: 0018:ffffc90000ebfdc0 EFLAGS: 00000246
[   12.544081] RAX: 0000000000000000 RBX: ffff888008d88170 RCX: 0000000000000000
[   12.544476] RDX: 0000000000000000 RSI: 0000000000000000 RDI: ffff888008d88170
[   12.544873] RBP: ffffc90000ebfdd8 R08: 0000000000000000 R09: 0000000000000000
[   12.545266] R10: 0000000000000000 R11: 0000000000000000 R12: 0000000000000000
[   12.545654] R13: ffff888008d88008 R14: 0000000000000000 R15: 0000000000000000
[   12.546110] FS:  000000003a5c4380(0000) GS:ffff8880a9836000(0000) knlGS:0000000000000000
[   12.546550] CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
[   12.546901] CR2: 0000000000000008 CR3: 0000000008ce1000 CR4: 00000000000006f0
[   12.547496] Call Trace:
[   12.548068]  <TASK>
[   12.548605]  vhost_test_ioctl+0x6cd/0x730 [vhost_test]
[   12.549194]  ? __pfx_vhost_test_ioctl+0x10/0x10 [vhost_test]
[   12.549597]  __x64_sys_ioctl+0x10e/0x160
[   12.549941]  x64_sys_call+0x2b5/0x27e0
[   12.550243]  do_syscall_64+0xbf/0x550
[   12.550565]  ? fpregs_assert_state_consistent+0x7b/0xc0
[   12.550933]  ? irqentry_exit+0x44/0x790
[   12.551270]  ? prandom_u32_state+0xd/0x90
[   12.551612]  ? do_syscall_64+0x31/0x550
[   12.551948]  entry_SYSCALL_64_after_hwframe+0x76/0x7e
[   12.552361] RIP: 0033:0x41c19d
[   12.552914] Code: 04 25 28 00 00 00 48 89 45 c8 31 c0 48 8d 45 10 c7 45 b0 10 00 00 00 48 89 45 b8 48 8d 45 d0 48 89 45 c0 b8 10 00 00 00 0f 05 <89> c2 3d 00 f0 ff ff 77 1a 48 8b 45 c8 64 48 2b 04 25 28 00 00 00
[   12.553749] RSP: 002b:00007ffd30f78940 EFLAGS: 00000246 ORIG_RAX: 0000000000000010
[   12.554234] RAX: ffffffffffffffda RBX: 00000000004860a4 RCX: 000000000041c19d
[   12.554620] RDX: 00007ffd30f789b8 RSI: 000000004004af32 RDI: 0000000000000003
[   12.555010] RBP: 00007ffd30f78990 R08: 00000000004b2820 R09: 0000000000000000
[   12.555400] R10: 0000000000000001 R11: 0000000000000246 R12: 0000000000001000
[   12.555788] R13: 00007ffd30f78b28 R14: 00000000004ad868 R15: 0000000000000001
[   12.556239]  </TASK>
[   12.556478] Modules linked in: vhost_test(OE)
[   12.557136] CR2: 0000000000000008
[   12.557983] ---[ end trace 0000000000000000 ]---
---
 drivers/vhost/test.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/vhost/test.c b/drivers/vhost/test.c
index 84ed9ea81219..65dc8c71336d 100644
--- a/drivers/vhost/test.c
+++ b/drivers/vhost/test.c
@@ -287,6 +287,10 @@ static long vhost_test_set_backend(struct vhost_test *n, unsigned index, int fd)
 		r = -EFAULT;
 		goto err_vq;
 	}
+	if (enable && !vq->kick) {
+		r = -EINVAL;
+		goto err_vq;
+	}
 	if (!enable) {
 		vhost_poll_stop(&vq->poll);
 		backend = vhost_vq_get_backend(vq);

---
base-commit: c69023b5e16e5ffe9368603dca76d85bd544ee57
change-id: 20261011-fix-null-pointer-in-vhost_test_set_backend-09439e45ca47

Best regards,
--  
Linfeng Sun <linfeng.sun.dev@gmail.com>

