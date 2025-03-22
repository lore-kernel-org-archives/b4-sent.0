From: Julian Stecklina <julian.stecklina@cyberus-technology.de>
Subject: [PATCH v2 0/9] initrd: cleanup and erofs support
Date: Sat, 22 Mar 2025 21:34:12 +0100
Message-Id: <20250322-initrd-erofs-v2-0-d66ee4a2c756@cyberus-technology.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMQe32cC/3XMQQ6CMBCF4auQWTsGiiC48h6GBW2nMIlpzRSJh
 PTuVvYu/5e8b4dIwhThVuwgtHLk4HOoUwFmHv1EyDY3qFI1Za1KZM+LWCQJLuK1pV41zrq2M5A
 vLyHHn4N7DLlnjkuQ7dDX6rf+gdYKK6wbrbXq60vbjXezaZJ3xIXM7MMzTNvZEgwppS8JgT30t
 AAAAA==
X-Change-ID: 20250320-initrd-erofs-76e925fdf68c
To: Christoph Hellwig <hch@lst.de>, Al Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>
Cc: Linus Torvalds <torvalds@linux-foundation.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Gao Xiang <xiang@kernel.org>, 
 linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-erofs@lists.ozlabs.org, 
 Julian Stecklina <julian.stecklina@cyberus-technology.de>, 
 Niklas Sturm <niklas.sturm@secunet.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742675712; l=3257;
 i=julian.stecklina@cyberus-technology.de; s=20250320;
 h=from:subject:message-id; bh=BqYZpH0UiavMMal11keGKaBoUo5bpmMxlDCKzw1Ly2A=;
 b=/HaQH4dsGXfsHwAm/6oa8WAEYcLbW08CzgyyRCZ+LZG0q+uisaMe5G6LQ3QXxCEgqyOGnYwUU
 nkvDSuyxtGkAdFImX7HqJ4sntWriaHu7HcpiTN7J586G3+Di7DiIDBv
X-Developer-Key: i=julian.stecklina@cyberus-technology.de; a=ed25519;
 pk=m051/8gQfs5AmkACfykwRcD6CUr2T7DQ9OA5eBgyy7c=
X-Endpoint-Received: by B4 Relay for julian.stecklina@cyberus-technology.de/20250320 with auth_id=363
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On my journey towards adding erofs support for initrd, Al Viro
suggested to move the filesystem detection code into the respective
filesystem modules. This patch series implements this, while also
adding erofs support.

To achieve this, I added a macro initrd_fs_detect() that allows
filesystem modules to add a filesystem detection hooks. I then moved
all existing filesystem detection code to this new API. While I was
there I also tried to clean up some of the code.

I've tested these changes with the following kinds of initrd
images:

- ext2
- Minix v1
- cramfs (padded/unpadded)
- romfs
- squashfs
- erofs

initrds are still relevant, because they have some advantages over
initramfs. They don't require unpacking all files before starting the
init process and allows them to stay compressed in memory. They also
allow using advanced file system features, such as extended
attributes. In the NixOS community, we are heavy users of erofs, due
to its sweet spot of compression, speed and features.

That being said, I'm totally in favor of cutting down the supported
filesystems for initrd and further simplify the code. I would be
surprised, if anyone is using ext2 or Minix v1 filesystems (64 MiB
filesystem size limit!) or cramfs (16 MiB file size limit!) as an
initrd these days! Squashfs and erofs seem genuinely useful, though.

Signed-off-by: Julian Stecklina <julian.stecklina@cyberus-technology.de>
---
Changes in v2:
- Remove more legacy code
- Introduce initrd_fs_detect
- Move all other initrd filesystems to the new API
- Link to v1: https://lore.kernel.org/r/20250320-initrd-erofs-v1-1-35bbb293468a@cyberus-technology.de

---
Julian Stecklina (9):
      initrd: remove ASCII spinner
      initrd: fix double fput for truncated ramdisks
      initrd: add a generic mechanism to add fs detectors
      fs: minix: register an initrd fs detector
      fs: cramfs: register an initrd fs detector
      fs: romfs: register an initrd fs detector
      fs: squashfs: register an initrd fs detector
      fs: ext2, ext4: register an initrd fs detector
      fs: erofs: register an initrd fs detector

 fs/cramfs/Makefile                |   5 ++
 fs/cramfs/initrd.c                |  41 +++++++++++++
 fs/erofs/Makefile                 |   5 ++
 fs/erofs/initrd.c                 |  19 ++++++
 fs/ext2/Makefile                  |   5 ++
 fs/ext2/initrd.c                  |  27 +++++++++
 fs/ext4/Makefile                  |   4 ++
 fs/minix/Makefile                 |   5 ++
 fs/minix/initrd.c                 |  23 +++++++
 fs/romfs/Makefile                 |   4 ++
 fs/romfs/initrd.c                 |  22 +++++++
 fs/squashfs/Makefile              |   5 ++
 fs/squashfs/initrd.c              |  23 +++++++
 include/asm-generic/vmlinux.lds.h |   6 ++
 include/linux/ext2_fs.h           |   9 ---
 include/linux/initrd.h            |  37 ++++++++++++
 init/do_mounts_rd.c               | 122 ++++++++------------------------------
 17 files changed, 257 insertions(+), 105 deletions(-)
---
base-commit: 88d324e69ea9f3ae1c1905ea75d717c08bdb8e15
change-id: 20250320-initrd-erofs-76e925fdf68c

Best regards,
-- 
Julian Stecklina <julian.stecklina@cyberus-technology.de>

