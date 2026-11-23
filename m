From: Igor Velkov <iav@iav.lv>
Subject: [PATCH v2 0/8] cmd: lwip: wget: write the download to a block
 device
Date: Mon, 23 Nov 2026 04:03:15 +0000
Message-Id: <20261123-b4-wget-blk-r4-v2-0-073d800a5aaa@iav.lv>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAO7A2sC/3XMQQ6CMBCF4auQWTtm2k4UXXkPw6LIABMJkJZUD
 eHuVvYu/5e8b4UoQSXCtVghSNKo05jDHgp49H7sBLXJDZbsyRgyWDO+OlmwHp4YGEvn2tK7xjE
 L5NMcpNX3Dt6r3L3GZQqf3U/mt/6lkkFCsWdPdBEmdjf16TgkqLZt+wIG7W3TqQAAAA==
To: Jerome Forissier <jerome.forissier@arm.com>, 
 Tom Rini <trini@konsulko.com>
Cc: Simon Glass <sjg@chromium.org>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Adriano Cordova <adrianox@gmail.com>, u-boot@lists.u-boot-project.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=5213; i=iav@iav.lv;
 h=from:subject:message-id; bh=G8GYtpb356ooV2Y3KO81na2icZvAt7lEYQv4BxKLFks=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDNnMu1kfaXD+mx5s+8zaxulMM+f6XqF83T4+x4Q7oS8C1
 lv5WSV1lLIwiHExyIopskw4pHErY8nVv/4e5g9g5rAygQxh4OIUgIl8Smb4Xx3TtoQ/VqSu36Qv
 7/yZM1K6qfGFdWq398pqfrghm75vHSPDkefOrMUF08zTj2U6sEWwX1/f+eq7jgSfROOtviCDbZx
 MAA==
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

wget can write a disk image only after the whole file is in RAM. This
series lets lwIP wget write the download to a block device while it
arrives. The target takes the usual <dev>[.<hwpart>][:<part>|#<name>]
form and an optional byte offset:

  => wget -o mmc 0 http://192.168.1.65/disk.img          # whole device
  => wget -o mmc 0 -s 8000 http://192.168.1.65/idbloader.img # 32 KiB in
  => wget -o mmc 0:1 http://192.168.1.65/boot.img        # partition 1
  => wget -o mmc 0#rootfs http://192.168.1.65/root.img   # "rootfs"
  => wget -o mmc 0#rootfs -s 400000 http://192.168.1.65/part.img
  => wget -o mmc 0.1 http://192.168.1.65/u-boot.bin      # boot0
  => wget -o mmc 0.2 -s 40000 http://192.168.1.65/env.bin

The write buffer is 1 MiB unless -b sets it.

Patches 1-5 prepare the lwIP HTTP client and wget: the Content-Length
sentinel moves to the header, the size check accepts a reply without
a length, lengths and counts go to 64 bits as images pass 4 GiB, and
Content-Length is found whatever its case. Patch 6 lets a wget client
take the data through a callback, patch 7 adds the block device
writer, and patch 8 adds the options.

Jerome, v1 is in u-boot-net for-main (8498fbf8788..f0870bb385c);
please drop it for this version.

Tested:
- QEMU arm64, eMMC with boot partitions and a GPT, and virtio-blk:
  every form above, HTTPS into a partition and into boot0; the data
  matches the files byte for byte and nothing outside the target
  changed. Refused before any write: a 404, a chunked reply, a file
  larger than the target, ':' and ':auto', a hardware partition that
  the device lacks. A server that sends less or more than its
  Content-Length fails the command, and nothing past the declared
  length reaches the device.
- ROCK Pi 4A: a 1862270976-byte image to NVMe at a 1 GiB offset in
  68 s (26 MiB/s); the bytes at that offset have the sha256 of the
  image, and the 8 MiB before and after it are still zero.
- sandbox: ut lib lib_test_sink_blk; every patch builds on sandbox and
  sandbox64_lwip. qemu_arm (32-bit) with lwIP builds without warnings.

Notes:
- checkpatch flags lwIP's own style in patches 4 and 5, and asks for
  IS_ENABLED() at "#if defined(CONFIG_WGET_STREAM)"; that #if picks
  lines of the help string, as the WGET_CACERT ones next to it do.
- Patch 2 changes what EFI HTTP gets for a HEAD without
  Content-Length; its message says how.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Changes in v2:
- New patch 1: HTTPC_CONTENT_LEN_INVALID in http_client.h (Heinrich)
- Patch 2: no Fixes: tag; the message says what it changes for EFI
- New patches 3 and 4: 64-bit content length and byte counts; a mark
  every 10 blocks when the length is unknown
- New patch 5: find Content-Length whatever its case
- Patch 6: with a sink, refuse a Transfer-Encoding reply and data past
  the Content-Length; set neither filesize, fileaddr nor the EFI boot
  device
- Patch 7: refuse targets that leave the choice of device or partition
  to U-Boot (':', ':auto', an empty device or name, numbers that the
  lookups truncate), a hardware partition that the device lacks, and
  'ubi'; read the partition table again after the write
- Patch 8: filesize is the number of bytes written and fileaddr is
  deleted; each option once; wget.rst lists every target form
- Link to v1: https://lore.kernel.org/r/20261101-b4-wget-blk-r4-v1-0-e27a009e4043@iav.lv

---
Igor Velkov (8):
      net: lwip: move HTTPC_CONTENT_LEN_INVALID to http_client.h
      net: lwip: wget: accept a reply without Content-Length in the size check
      net: lwip: wget: count the download in 64 bits
      net: lwip: count the HTTP content length in 64 bits
      net: lwip: find Content-Length whatever its case
      net: lwip: wget: hand the payload to an optional sink
      lib: add a stream sink for block devices
      cmd: lwip: wget: write the download to a block device

 cmd/Kconfig                                       |   9 +
 cmd/lwip/wget.c                                   | 130 ++++++++++-
 configs/sandbox64_lwip_defconfig                  |   1 +
 configs/sandbox_defconfig                         |   1 +
 doc/usage/cmd/wget.rst                            |  95 +++++++-
 include/net-common.h                              |  14 +-
 include/stream_sink.h                             |  84 +++++++
 lib/Kconfig                                       |   8 +
 lib/Makefile                                      |   1 +
 lib/lwip/lwip/src/apps/http/http_client.c         |  68 ++++--
 lib/lwip/lwip/src/include/lwip/apps/http_client.h |  14 +-
 lib/stream_sink.c                                 | 268 ++++++++++++++++++++++
 net/lwip/wget.c                                   | 177 +++++++++++---
 test/dm/lwip.c                                    |   2 +-
 test/lib/Makefile                                 |   3 +
 test/lib/stream_sink.c                            | 204 ++++++++++++++++
 16 files changed, 1028 insertions(+), 51 deletions(-)
---
base-commit: e578056c766d653270b14557c2a9d8daec414c17
change-id: 20261101-b4-wget-blk-r4-833f8a3d344e

Best regards,
-- 
Igor Velkov <iav@iav.lv>

