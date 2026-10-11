From: Linfeng Sun <linfeng.sun.dev@gmail.com>
Date: Sun, 11 Oct 2026 16:48:40 +0800
Subject: [PATCH] vhost-vdpa: initialize state before publishing cdev
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-fix-null-pointer-in-vhost_vdpa_release-v1-1-43ebc225f938@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXNQQrCMBCF4auUWTvQFJXWq4iUSTu1IyEJmTQIp
 Xc36vJbvP/toJyEFW7NDomLqARfYU4NTCv5J6PM1dC13dW0xuAib/SbcxiD+MwJxWNZg+axzJH
 GxI5JGe15uCy2H4iohxqLievyd3R//K2bffGUv3U4jg/HsmXpigAAAA==
X-Change-ID: 20261011-fix-null-pointer-in-vhost_vdpa_release-b495fb89aaa8
To: "Michael S. Tsirkin" <mst@redhat.com>, 
 Jason Wang <jasowangio@gmail.com>, 
 =?utf-8?q?Eugenio_P=C3=A9rez?= <eperezma@redhat.com>, 
 Tiwei Bie <tiwei.bie@intel.com>
Cc: kvm@vger.kernel.org, virtualization@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Linfeng Sun <linfeng.sun.dev@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791708522; l=5684;
 i=linfeng.sun.dev@gmail.com; s=20261010; h=from:subject:message-id;
 bh=lO63c612f3W01eAQKW8gQ/u7SgviABtFHcPCPVA69xg=;
 b=2SKvFGyQlpWr3kk1AhzwaEfs1Z00KYut0wXx2gI5Q4v/E6groac6bAUK3wS1EdqSxWBAoZWFH
 4Qf467hFPJgBA/wCB8rsLfMKXYh6XGHOZstGX3A09H7cs4z77LpcCIz
X-Developer-Key: i=linfeng.sun.dev@gmail.com; a=ed25519;
 pk=IPHLe8L3bTveNcYFP12okRAIWs4eqaVd4jrqSNMj7UU=
X-Endpoint-Received: by B4 Relay for linfeng.sun.dev@gmail.com/20261010 with auth_id=1150
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Initialize the completion and as hash buckets before cdev_device_add()
makes the device accessible.

Fixes: 4c8cf31885f6 ("vhost: introduce vDPA-based backend")
Assisted-by: OpenAI-Codex:GPT-5.6
Signed-off-by: Linfeng Sun <linfeng.sun.dev@gmail.com>
---
I used // because b4 ignores lines starting with #. Please uncomment those 
lines before reproducing.
---- reproduce.c ----
// #include <fcntl.h>
// #include <pthread.h>
// #include <stdatomic.h>
// #include <unistd.h>

// #define THREADS 16

static const char *device_path;
static const char *sysfs_path;
static atomic_int stop;

static void *open_close(void *unused)
{
	(void)unused;

	while (!atomic_load(&stop)) {
		int fd;

		if (access(sysfs_path, F_OK))
			continue;
		fd = open(device_path, O_RDWR);
		if (fd >= 0)
			close(fd);
	}
	return NULL;
}

int main(int argc, char **argv)
{
	pthread_t threads[THREADS];
	int i;

	if (argc != 3)
		return 1;
	device_path = argv[1];
	sysfs_path = argv[2];

	for (i = 0; i < THREADS; i++)
		if (pthread_create(&threads[i], NULL, open_close, NULL))
			return 1;

	sleep(45);
	atomic_store(&stop, 1);
	for (i = 0; i < THREADS; i++)
		pthread_join(threads[i], NULL);
	return 0;
}

---- crash ----
[   23.959139] BUG: unable to handle page fault for address: fffffffffffffff8
[   23.959859] #PF: supervisor read access in kernel mode
[   23.960291] #PF: error_code(0x0000) - not-present page
[   23.960740] PGD 4869067 P4D 4869067 PUD 486b067 PMD 0 
[   23.961718] Oops: Oops: 0000 [#1] SMP NOPTI
[   23.962395] CPU: 1 UID: 0 PID: 126 Comm: poc Not tainted 7.3.0-rc2+ #1 PREEMPT(full) 
[   23.963059] Hardware name: QEMU Ubuntu 24.04 PC v2 (i440FX + PIIX, arch_caps fix, 1996), BIOS 1.16.3-debian-1.16.3-2 04/01/2014
[   23.963890] RIP: 0010:complete+0x44/0x80
[   23.964656] Code: 41 d8 01 49 89 c4 8b 03 83 f8 ff 74 05 83 c0 01 89 03 48 8b 53 10 48 8d 43 10 48 39 c2 74 29 48 8b 5b 10 31 d2 be 03 00 00 00 <48> 8b 7b f8 e8 e3 65 fc ff 48 8b 13 48 8b 43 08 48 89 42 08 48 89
[   23.965679] RSP: 0018:ffffc9000141bc38 EFLAGS: 00000046
[   23.966109] RAX: ffff888008a678d8 RBX: 0000000000000000 RCX: 0000000000000000
[   23.966513] RDX: 0000000000000000 RSI: 0000000000000003 RDI: 0000000000000000
[   23.967005] RBP: ffffc9000141bc50 R08: 0000000000000000 R09: 0000000000000000
[   23.967483] R10: 0000000000000000 R11: 0000000000000000 R12: 0000000000000246
[   23.967896] R13: ffff888008a678d0 R14: 0000000000000000 R15: ffffffff83541780
[   23.968384] FS:  00007dcd511046c0(0000) GS:ffff8880b94b6000(0000) knlGS:0000000000000000
[   23.968933] CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
[   23.969398] CR2: fffffffffffffff8 CR3: 0000000009a41000 CR4: 00000000000006f0
[   23.970091] Call Trace:
[   23.970735]  <TASK>
[   23.971266]  vhost_vdpa_release+0x175/0x190
[   23.971862]  ? __pfx_vhost_vdpa_release+0x10/0x10
[   23.972298]  __fput+0x1c2/0x520
[   23.972692]  fput_close_sync+0x6e/0x140
[   23.973040]  __x64_sys_close+0x51/0xd0
[   23.973362]  x64_sys_call+0x2680/0x27e0
[   23.973655]  do_syscall_64+0xbf/0x550
[   23.973969]  ? restore_fpregs_from_fpstate+0xa1/0x110
[   23.974322]  ? switch_fpu_return+0xbd/0x190
[   23.974630]  ? do_syscall_64+0x299/0x550
[   23.974962]  ? putname+0x7f/0xd0
[   23.975267]  ? do_faccessat+0x3fe/0x570
[   23.975583]  ? __sanitizer_cov_trace_cmp4+0x16/0x30
[   23.975934]  ? fpregs_assert_state_consistent+0x7b/0xc0
[   23.976272]  ? do_syscall_64+0xfd/0x550
[   23.976591]  ? __sanitizer_cov_trace_cmp4+0x16/0x30
[   23.976949]  ? fpregs_assert_state_consistent+0x7b/0xc0
[   23.977304]  ? do_syscall_64+0xfd/0x550
[   23.977611]  ? prandom_u32_state+0xd/0x90
[   23.977933]  ? do_syscall_64+0x31/0x550
[   23.978248]  entry_SYSCALL_64_after_hwframe+0x76/0x7e
[   23.978644] RIP: 0033:0x41e94c
[   23.979296] Code: 0f 05 48 3d 00 f0 ff ff 77 3c c3 0f 1f 00 55 48 89 e5 48 83 ec 10 89 7d fc e8 b0 a5 02 00 8b 7d fc 89 c2 b8 03 00 00 00 0f 05 <48> 3d 00 f0 ff ff 77 2c 89 d7 89 45 fc e8 12 a6 02 00 8b 45 fc c9
[   23.980064] RSP: 002b:00007dcd51104220 EFLAGS: 00000293 ORIG_RAX: 0000000000000003
[   23.980511] RAX: ffffffffffffffda RBX: 00007dcd51104cdc RCX: 000000000041e94c
[   23.980887] RDX: 0000000000000000 RSI: 0000000000000000 RDI: 0000000000000003
[   23.981251] RBP: 00007dcd51104230 R08: 0000000000000000 R09: 00007dcd511046c0
[   23.981604] R10: 0000000000000000 R11: 0000000000000293 R12: 00007dcd511046c0
[   23.981960] R13: ffffffffffffffb8 R14: 0000000000000000 R15: 00007ffe8c98a0f0
[   23.982377]  </TASK>
[   23.982597] Modules linked in:
[   23.983036] CR2: fffffffffffffff8
[   23.983847] ---[ end trace 0000000000000000 ]---
---
 drivers/vhost/vdpa.c | 7 +++----
 1 file changed, 3 insertions(+), 4 deletions(-)

diff --git a/drivers/vhost/vdpa.c b/drivers/vhost/vdpa.c
index ff7d90719171..35e2f5b2293b 100644
--- a/drivers/vhost/vdpa.c
+++ b/drivers/vhost/vdpa.c
@@ -1678,17 +1678,16 @@ static int vhost_vdpa_probe(struct vdpa_device *vdpa)
 
 	cdev_init(&v->cdev, &vhost_vdpa_fops);
 	v->cdev.owner = THIS_MODULE;
+	init_completion(&v->completion);
+	for (i = 0; i < VHOST_VDPA_IOTLB_BUCKETS; i++)
+		INIT_HLIST_HEAD(&v->as[i]);
 
 	r = cdev_device_add(&v->cdev, &v->dev);
 	if (r)
 		goto err;
 
-	init_completion(&v->completion);
 	vdpa_set_drvdata(vdpa, v);
 
-	for (i = 0; i < VHOST_VDPA_IOTLB_BUCKETS; i++)
-		INIT_HLIST_HEAD(&v->as[i]);
-
 	return 0;
 
 err:

---
base-commit: c69023b5e16e5ffe9368603dca76d85bd544ee57
change-id: 20261011-fix-null-pointer-in-vhost_vdpa_release-b495fb89aaa8

Best regards,
--  
Linfeng Sun <linfeng.sun.dev@gmail.com>

