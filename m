From: Igor Velkov <iav@iav.lv>
Subject: [PATCH 0/4] cmd: lwip: wget: write the download to a block device
Date: Sun, 01 Nov 2026 07:53:22 +0200
Message-Id: <20261101-b4-wget-blk-r4-v1-0-e27a009e4043@iav.lv>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANLT5moC/x3MQQqAIBBA0avIrBvIlJCuEi00RxuKCo0KorsnL
 d/i/wcyJaYMnXgg0cmZt7VAVgLGya6RkH0xNHXTSllLdBqvSAe6Zcak0SgVjFVeaU1Qoj1R4Ps
 f9sP7fh0vZSpgAAAA
To: Jerome Forissier <jerome.forissier@arm.com>, 
 Tom Rini <trini@konsulko.com>
Cc: Simon Glass <sjg@chromium.org>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Adriano Cordova <adrianox@gmail.com>, u-boot@lists.u-boot-project.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3141; i=iav@iav.lv;
 h=from:subject:message-id; bh=T1UUImtRC3lpa4FcpFhwynJT5smSm8vUcSpCUZ1Vj7Q=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFnPLl+WySy6XRfAvtT9HNvJxAmKbw261Ly2yFpeeiIQs
 e/V+c9SHaUsDGJcDLJiiiwTDmncylhy9a+/h/kDmDmsTCBDGLg4BWAi2nmMDLemsmuszp3A98ts
 Zt6pwodMiZ3Npxi/8LapPD7+6ynLOXVGhufV0XN+fDfdLeK9YeqziJ8xh75w9nrd71KN2NbOH/G
 ohQ8A
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

wget can write a disk image only after the whole file is in RAM. This
series lets lwIP wget write the download to a block device while it
arrives:

  => wget -o mmc 1 -b 400000 http://192.168.1.65/armbian.img

The target is a whole device, a hardware partition, a partition by
number or name, and an optional byte offset into it.

Patch 1 fixes the buffer size check for a reply without Content-Length;
patch 4 sets that check to the target size, and without the fix such a
reply would be refused. Patch 2 lets a wget client take the data
through a callback, patch 3 adds the block device writer, and patch 4
adds the options to the command.

Tested:
- ROCK Pi 4A: a 1862270976-byte image to the SD card in 3 min 16 s to
  3 min 35 s with a 4 MiB buffer; the first 1862270976 bytes of the
  card have the sha256 of the image, and the card boots. A
  2936012800-byte image, past the Content-Length limit below, took
  4 min 18 s and checks and boots the same way.
- QEMU arm64, virtio-blk: a 404 writes nothing; a file larger than the
  target is refused before any write with Content-Length, and at the
  end of the target without it.
- sandbox: ut lib lib_test_sink_blk; every patch builds on sandbox and
  sandbox64_lwip.

Notes:
- lwIP's http_client.c reads Content-Length through an int, so from
  2 GiB on the length is unknown and a file that does not fit fails
  only at the end of the target.
- EFI HTTP, the other user of check_buffer_size, retries with the
  reported length when it exceeds the buffer (efi_net.c:1715), so a
  reply without Content-Length still ends in a 4 GiB allocation there;
  patch 1 does not change that.
- checkpatch asks for IS_ENABLED() at "#if defined(CONFIG_WGET_STREAM)"
  in cmd/lwip/wget.c; that #if picks lines of the help string, as the
  WGET_CACERT ones next to it do.

gzip and zstd input follow in a separate series on top of this one.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Igor Velkov (4):
      net: lwip: wget: accept a reply without Content-Length in the size check
      net: lwip: wget: hand the payload to an optional sink
      lib: add a stream sink for block devices
      cmd: lwip: wget: write the download to a block device

 cmd/Kconfig                      |   9 ++
 cmd/lwip/wget.c                  | 107 +++++++++++++++++++++-
 configs/sandbox64_lwip_defconfig |   1 +
 configs/sandbox_defconfig        |   1 +
 doc/usage/cmd/wget.rst           |  43 ++++++++-
 include/net-common.h             |   6 ++
 include/stream_sink.h            |  75 ++++++++++++++++
 lib/Kconfig                      |   8 ++
 lib/Makefile                     |   1 +
 lib/stream_sink.c                | 189 +++++++++++++++++++++++++++++++++++++++
 net/lwip/wget.c                  |  89 +++++++++++++++---
 test/lib/Makefile                |   3 +
 test/lib/stream_sink.c           | 137 ++++++++++++++++++++++++++++
 13 files changed, 655 insertions(+), 14 deletions(-)
---
base-commit: 3401e006432abcbf7d73d7210f10df157f990ed3
change-id: 20261101-b4-wget-blk-r4-833f8a3d344e

Best regards,
-- 
Igor Velkov <iav@iav.lv>

