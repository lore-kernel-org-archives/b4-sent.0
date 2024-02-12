From: Emil Velikov <emil.l.velikov@gmail.com>
Subject: [PATCH kmod 00/13] Load compressed modules with compression-less
 kmod
Date: Mon, 12 Feb 2024 17:23:01 +0000
Message-Id: <20240212-decompression-fixes-v1-0-06f92ad07985@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPVTymUC/x2LSwqAMBDFriKzttDWT8GriAu1T52FHzoggnh3R
 5chyU2CxBBqspsSThbeNwWXZzQu/TbDcFQmb31pvfMmYtzXI0G+0kx8QUxVF8EBQ7Ahkp6qf6F
 j2z3PC8My6f5lAAAA
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707758583; l=1821;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=SCzVm2UUC1IMA/HHo4CTYKroQfXLl7GJr3AiqyJR6Pk=;
 b=FdjIW3gR+exoID4TE8nLHlI/4/FlBTPqGOZZboJbCmKbLbkP/+/v2Dd2Xl1CwtFiaScX99Myk
 KsMVHYbGlJKAdec3gHAqiRPUyOPJSl5PMjvZk2FGZyv1fgwoRn1vrt1
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

While I was digging into a dkms bug, I've noticed that kmod does not
fallback to the normal init_module() code path when the in-kernel
decompression fails.

As I looked closer, I realised that the current module compression
detection relies on kmod being build with zstd, xz, zlib ... Even in the
case where we rely on the kernel module itself to decompress - aka we
don't use the external libraries all together.

By building kmod without zstd and friends, we shave some space off the
initrd which helps with boot time.

Majority of this series handles the latter and fixes a few related bugs
along the way. The last commits is somewhat questionable commit and
addresses the former issue.

Happy to hear your feedback,
Emil

---
Emil Velikov (13):
      libkmod: use a dup()'d fd for zlib
      libkmod: keep gzFile gzf local to load_zlib()
      libkmod: remove kmod_file::{zstd,xz}_used flags
      libkmod: clear file->memory if map fails
      libkmod: nuke struct file_ops
      libkmod: propagate {zstd,xz,zlib}_load errors
      libkmod: move kmod_file_load_contents as applicable
      libkmod: always detect the module compression
      libkmod: swap alloca usage for a few assert_cc
      libkmod: tidy-up kmod_file_open()
      libkmod: move load_reg() further up
      libkmod: keep KMOD_FILE_COMPRESSION_NONE/load_reg in comp_types
      libkmod: always fallback to do_init_module()

 libkmod/libkmod-file.c     | 206 ++++++++++++++++++---------------------------
 libkmod/libkmod-internal.h |   2 +-
 libkmod/libkmod-module.c   |   8 +-
 3 files changed, 90 insertions(+), 126 deletions(-)
---
base-commit: b29704cd448aaa455dba4e656fc0f0d3c686df3f
change-id: 20240212-decompression-fixes-56371eeb707d

Best regards,
-- 
Emil Velikov <emil.l.velikov@gmail.com>

