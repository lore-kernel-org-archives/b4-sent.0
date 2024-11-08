From: Daniel Gomez <da.gomez@samsung.com>
Subject: [PATCH RFC v3 0/4] module: refactor ro_after_init failure path
Date: Fri, 08 Nov 2024 17:12:12 +0100
Message-Id: <20241108-modules-ro_after_init-v3-0-6dd041b588a5@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFw4LmcC/x2MQQqDMBAAvyJ7bkpMxUpPBaEP6LUUic2uLmhSN
 mmRin9v8DgDMytEFMYIl2IFwS9HDj7D6VDAa7R+QMUuMxhtqrLUjZqD+0wYlYTOUkLp2HNSmsq
 adF85aw3k9i1IvOzfB9xvLTyzJAmzSqOg3ZfN+UfB172OR6J4TcO0wLb9AeX15PuSAAAA
To: Luis Chamberlain <mcgrof@kernel.org>, Petr Pavlu <petr.pavlu@suse.com>, 
 Sami Tolvanen <samitolvanen@google.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Thomas Gleixner <tglx@linutronix.de>, Jinjie Ruan <ruanjinjie@huawei.com>, 
 Jens Axboe <axboe@kernel.dk>
Cc: "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, 
 linux-modules@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731082346; l=10603;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=eAoOZqiRUdO7h06xTiLAK9m+HY3qDfL1LG3XlVZB87o=;
 b=Z0N45xxFBSDuAi5a3NdI155j7ySvcJVNpW8KtU7ymnK1bS32ZwSLmv7OMl9Nm8V5ca2gPUGuB
 uAP7AYqvjFtD/KU46VuJQWr+XB5eJ/jTHiH0YmrXNixEHE7wP/GlB/0
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This refactoring aims to address the ro_after_init failure path issue
discussed in the thread [1] by Jinjie Ruan and Thomas Gleixner.

[1] https://lore.kernel.org/all/20230915082126.4187913-1-ruanjinjie@huawei.com/

The final patch incorporates Luis's suggestion to handle module unload
by stopping the module and calling its exit function before releasing
all allocated memory in the event of an ro_after_init failure. However,
it ignores the errors. Please, see more below for discussion.

Jinjie, can you test this patch and see if solves the issue?

I've tested this with a system without any module other than the tested
ones: loop and brd. For the block loop device driver I can successfully
unload the module when I force a ro_after_init failure. However, I
cannot do the same if I test this with the block ram disk (brd) driver.
Please, see below the logs before/after the changes. Jens, could this be
something in the brd driver?

Additionaly, could we prevent any module from loading if it depends
on another module that currently uses ro_after_init and is not fully
loaded? This would help guarantee the success of list_empty() and
try_stop_module() if ro_after_init fails. What do you think? The last
patch currently ignores error from these 2 calls.

* loop driver ro_after_init failure before this patch series:

Nov 06 11:36:25 debian kernel: loop: module loaded
Nov 06 11:36:25 debian kernel: BUG: unable to handle page fault for address: ffffffffa0006320
Nov 06 11:36:25 debian kernel: #PF: supervisor read access in kernel mode
Nov 06 11:36:25 debian kernel: #PF: error_code(0x0000) - not-present page
Nov 06 11:36:25 debian kernel: PGD 1e3f067 P4D 1e3f067 PUD 1e40063 PMD 10e7d4067 PTE 0
Nov 06 11:36:25 debian kernel: Oops: Oops: 0000 [#1]
Nov 06 11:36:25 debian kernel: CPU: 0 UID: 0 PID: 428 Comm: (udev-worker) Not tainted 6.12.0-rc6-g4ade030a2d1b #155
Nov 06 11:36:25 debian kernel: Hardware name: QEMU Standard PC (Q35 + ICH9, 2009), BIOS 1.16.2-debian-1.16.2-1 04/01/2014
Nov 06 11:36:25 debian kernel: RIP: 0010:bdev_open+0x83/0x290
Nov 06 11:36:25 debian kernel: Code: bb 48 01 00 00 48 89 3c 24 e8 79 24 38 00 48 8b 43 40 41 bd fa ff ff ff 48 83 b8 40 03 00 00 00 0f 84 b3 01 00 00 48 8b 43 48 <48> 8b 78 78 e8 d4 c9 c8 ff 84 c0 0f 84 9e 01 00 00 80 3d 45 ad ad
Nov 06 11:36:25 debian kernel: RSP: 0018:ffff8881054dbc58 EFLAGS: 00010286
Nov 06 11:36:25 debian kernel: RAX: ffffffffa00062a8 RBX: ffff8881054a6800 RCX: ffff8881075becc0
Nov 06 11:36:25 debian kernel: RDX: 0000000000000000 RSI: 0000000000000009 RDI: ffff8881054a6948
Nov 06 11:36:25 debian kernel: RBP: 0000000000000009 R08: ffff88810e7aa9c0 R09: 0000000000000000
Nov 06 11:36:25 debian kernel: R10: ffff88810e5ab0c0 R11: ffff88810e796190 R12: ffff88810094e980
Nov 06 11:36:25 debian kernel: R13: 00000000fffffffa R14: 0000000000000000 R15: 0000000000000000
Nov 06 11:36:25 debian kernel: FS:  00007fd2ff110900(0000) GS:ffffffff81e47000(0000) knlGS:0000000000000000
Nov 06 11:36:25 debian kernel: CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
Nov 06 11:36:25 debian kernel: CR2: ffffffffa0006320 CR3: 000000010e7ed004 CR4: 00000000003706b0
Nov 06 11:36:25 debian kernel: Call Trace:
Nov 06 11:36:25 debian kernel:  <TASK>
Nov 06 11:36:25 debian kernel:  ? __die_body+0x16/0x60
Nov 06 11:36:25 debian kernel:  ? page_fault_oops+0x22a/0x310
Nov 06 11:36:25 debian kernel:  ? exc_page_fault+0x99/0xa0
Nov 06 11:36:25 debian kernel:  ? asm_exc_page_fault+0x22/0x30
Nov 06 11:36:25 debian kernel:  ? bdev_open+0x83/0x290
Nov 06 11:36:25 debian kernel:  ? bdev_open+0x67/0x290
Nov 06 11:36:25 debian kernel:  ? iput+0x37/0x150
Nov 06 11:36:25 debian kernel:  ? blkdev_open+0xab/0xd0
Nov 06 11:36:25 debian kernel:  ? blkdev_mmap+0x60/0x60
Nov 06 11:36:25 debian kernel:  ? do_dentry_open+0x25d/0x3b0
Nov 06 11:36:25 debian kernel:  ? vfs_open+0x1e/0xc0
Nov 06 11:36:25 debian kernel:  ? path_openat+0x9cf/0xbb0
Nov 06 11:36:25 debian kernel:  ? do_filp_open+0x7f/0xd0
Nov 06 11:36:25 debian kernel:  ? do_sys_openat2+0x67/0xb0
Nov 06 11:36:25 debian kernel:  ? do_sys_open+0x4b/0x50
Nov 06 11:36:25 debian kernel:  ? do_syscall_64+0x3d/0xb0
Nov 06 11:36:25 debian kernel:  ? entry_SYSCALL_64_after_hwframe+0x4b/0x53
Nov 06 11:36:25 debian kernel:  </TASK>
Nov 06 11:36:25 debian kernel: Modules linked in:
Nov 06 11:36:25 debian kernel: CR2: ffffffffa0006320
Nov 06 11:36:25 debian kernel: ---[ end trace 0000000000000000 ]---

./scripts/faddr2line --list vmlinux bdev_open+0x83/0x290
bdev_open+0x83/0x290:

bdev_open at block/bdev.c:908
 903
 904            mutex_lock(&disk->open_mutex);
 905            ret = -ENXIO;
 906            if (!disk_live(disk))
 907                    goto abort_claiming;
>908<           if (!try_module_get(disk->fops->owner))
 909                    goto abort_claiming;
 910            ret = -EBUSY;
 911            if (!bdev_may_open(bdev, mode))
 912                    goto put_module;
 913            if (bdev_is_partition(bdev))

* loop module drive load logs after the changes, including some debug
info:

 diff --git a/kernel/module/main.c b/kernel/module/main.c
 index 9e549559af9e..7deffd73f04b 100644
 --- a/kernel/module/main.c
 +++ b/kernel/module/main.c
 @@ -2994,8 +2994,10 @@ static noinline int do_init_module(struct module *mod)
         return 0;
 
  fail_ro_after_init:
 -       list_empty(&mod->source_list);
 -       try_stop_module(mod, 0, &forced);
 +       ret = list_empty(&mod->source_list);
 +       pr_info("%s: list_empty: ret: %d\n", mod->name, ret);
 +       ret = try_stop_module(mod, 0, &forced);
 +       pr_info("%s: try_stop_module: ret: %d\n", mod->name, ret);

 # lsmod
 Module                  Size  Used by
 # modprobe loop
 modprobe: ERROR: could not insert 'loop': Resource temporarily unavailable
 # lsmod
 Module                  Size  Used by

 Kernel logs:
 [ 1376.901220] loop: module loaded
 [ 1376.901398] loop: list_empty: ret: 1
 [ 1376.901618] loop: try_stop_module: ret: -11

Note: This is -EAGAIN error.

* brd driver ro_after_init failure before/after this patch series:

Nov 06 11:40:57 debian kernel: brd: module loaded
Nov 06 11:40:57 debian kernel: BUG: unable to handle page fault for address: ffffffffa0004030
Nov 06 11:40:57 debian kernel: #PF: supervisor read access in kernel mode
Nov 06 11:40:57 debian kernel: #PF: error_code(0x0000) - not-present page
Nov 06 11:40:57 debian kernel: PGD 1e3f067 P4D 1e3f067 PUD 1e40063 PMD 10ee72067 PTE 0
Nov 06 11:40:57 debian kernel: Oops: Oops: 0000 [#1]
Nov 06 11:40:57 debian kernel: CPU: 0 UID: 0 PID: 418 Comm: modprobe Not tainted 6.12.0-rc6-g4ade030a2d1b #155
Nov 06 11:40:57 debian kernel: Hardware name: QEMU Standard PC (Q35 + ICH9, 2009), BIOS 1.16.2-debian-1.16.2-1 04/01/2014
Nov 06 11:40:57 debian kernel: RIP: 0010:blkdev_put_whole+0x19/0x30
Nov 06 11:40:57 debian kernel: Code: 70 ff ff ff 0f 0b e9 73 ff ff ff 66 0f 1f 44 00 00 53 48 89 fb ff 4f 40 75 08 48 89 df e8 2f 04 00 00 48 8b 7b 10 48 8b 47 48 <48> 8b 40 18 48 85 c0 74 03 5b ff e0 5b c3 66 0f 1f 84 00 00 00 00
Nov 06 11:40:57 debian kernel: RSP: 0018:ffff8881055afe80 EFLAGS: 00010246
Nov 06 11:40:57 debian kernel: RAX: ffffffffa0004018 RBX: ffff88810ee2d300 RCX: 0000000000000000
Nov 06 11:40:57 debian kernel: RDX: 0000000000000000 RSI: 00000003fffffffc RDI: ffff88810edc6c00
Nov 06 11:40:57 debian kernel: RBP: 00000000284a0005 R08: 0000000000000402 R09: 0000000000000d53
Nov 06 11:40:57 debian kernel: R10: 000000000000000f R11: 000000000000003f R12: ffff888103482780
Nov 06 11:40:57 debian kernel: R13: 0000000000000000 R14: ffff88810edc6c00 R15: ffff88810edc6d48
Nov 06 11:40:57 debian kernel: FS:  00007f62341f7640(0000) GS:ffffffff81e47000(0000) knlGS:0000000000000000
Nov 06 11:40:57 debian kernel: CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
Nov 06 11:40:57 debian kernel: CR2: ffffffffa0004030 CR3: 00000001066e2004 CR4: 00000000003706b0
Nov 06 11:40:57 debian kernel: Call Trace:
Nov 06 11:40:57 debian kernel:  <TASK>
Nov 06 11:40:57 debian kernel:  ? __die_body+0x16/0x60
Nov 06 11:40:57 debian kernel:  ? page_fault_oops+0x22a/0x310
Nov 06 11:40:57 debian kernel:  ? exc_page_fault+0x99/0xa0
Nov 06 11:40:57 debian kernel:  ? asm_exc_page_fault+0x22/0x30
Nov 06 11:40:57 debian kernel:  ? blkdev_put_whole+0x19/0x30
Nov 06 11:40:57 debian kernel:  ? bdev_release+0xb9/0xf0
Nov 06 11:40:57 debian kernel:  ? blkdev_release+0x8/0x10
Nov 06 11:40:57 debian kernel:  ? __fput+0x77/0x280
Nov 06 11:40:57 debian kernel:  ? task_work_run+0x58/0x70
Nov 06 11:40:57 debian kernel:  ? syscall_exit_to_user_mode+0x66/0xa0
Nov 06 11:40:57 debian kernel:  ? do_syscall_64+0x49/0xb0
Nov 06 11:40:57 debian kernel:  ? entry_SYSCALL_64_after_hwframe+0x4b/0x53
Nov 06 11:40:57 debian kernel:  </TASK>
Nov 06 11:40:57 debian kernel: Modules linked in:
Nov 06 11:40:57 debian kernel: CR2: ffffffffa0004030
Nov 06 11:40:57 debian kernel: ---[ end trace 0000000000000000 ]---

./scripts/faddr2line --list vmlinux blkdev_put_whole+0x19/0x30
blkdev_put_whole+0x19/0x30:

blkdev_put_whole at block/bdev.c:679
 674
 675    static void blkdev_put_whole(struct block_device *bdev)
 676    {
 677            if (atomic_dec_and_test(&bdev->bd_openers))
 678                    blkdev_flush_mapping(bdev);
>679<           if (bdev->bd_disk->fops->release)
 680                    bdev->bd_disk->fops->release(bdev->bd_disk);
 681    }
 682
 683    static int blkdev_get_whole(struct block_device *bdev, blk_mode_t mode)
 684    {

To: Luis Chamberlain <mcgrof@kernel.org>
To: Petr Pavlu <petr.pavlu@suse.com>
To: Sami Tolvanen <samitolvanen@google.com>
To: Christophe Leroy <christophe.leroy@csgroup.eu>
To: Thomas Gleixner <tglx@linutronix.de>
To: Jinjie Ruan <ruanjinjie@huawei.com>
To: Jens Axboe <axboe@kernel.dk>
Cc: Daniel Gomez (Samsung) <d+samsung@kruces.com>
Cc: linux-modules@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
Daniel Gomez (4):
      module: remove module_deallocate() unused param
      module: avoid double ref drop on ro_after_init failure
      module: update state and release reference under lock
      module: refactor ro_after_init failure path

 kernel/module/main.c | 22 ++++++++++++++--------
 1 file changed, 14 insertions(+), 8 deletions(-)
---
base-commit: c39901c21cda246f967a4d1dc79ae349488fc4de
change-id: 20241108-modules-ro_after_init-0f16f0b4daa2

Best regards,
-- 
Daniel Gomez <da.gomez@samsung.com>

