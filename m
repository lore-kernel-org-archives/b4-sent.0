From: Janne Grunau <j@jannau.net>
Subject: [PATCH v2 0/5] configs: apple: Switch to standard boot + small
 adjustments
Date: Thu, 18 Apr 2024 21:00:24 +0200
Message-Id: <20240418-apple_config-v2-0-7e5c6b9a9db3@jannau.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMhtIWYC/3XMQQ7CIBCF4as0sxYD2Ghx1XuYxgAd2jEGCNRG0
 3B3sXuX/0vet0HGRJjh2myQcKVMwdeQhwbsrP2EjMbaILls+UlcmI7xiXcbvKOJqU44OyouO6O
 gXmJCR++duw21Z8pLSJ9dX8Vv/QOtgnEmTHeWxoqWa9U/tPf6dfS4wFBK+QIaqNVNqQAAAA==
To: Mark Kettenis <kettenis@openbsd.org>, Tom Rini <trini@konsulko.com>
Cc: Simon Glass <sjg@chromium.org>, u-boot@lists.denx.de, 
 asahi@lists.linux.dev, Janne Grunau <j@jannau.net>, 
 Hector Martin <marcan@marcan.st>, Neal Gompa <neal@gompa.dev>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1331; i=j@jannau.net;
 h=from:subject:message-id; bh=wszhNZ4MU9ddNHRZ14s0fd0fyOXux/wMrPcWH5LuASo=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhjTF3NPdi/s+Tp3ip9P+1DI5a0PW+fa3czZtVSk49cziq
 4nwbuf4jlIWBjEuBlkxRZYk7ZcdDKtrFGNqH4TBzGFlAhnCwMUpABPR/8bIMCd0p0CaYGmD2zdJ
 HjH2N6eZrwvUZl2bNq+k7L2okbDxeYb/MReaj1b7zt54LvJ/XXcw/xem5T/ezb83fV5fu3qe5lc
 eXgA=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series contains a few misc config changes for Apple silicon
systems:
- switch from the deprecated distro boot scripts to standard boot
- allows EFI console resizing based on the video console size
- enables 16x32 bitmap fonts as Apple devices come with high DPI
  displays
- enables 64-bit LBA addressing

Signed-off-by: Janne Grunau <j@jannau.net>
---
Changes in v2:
- added Reviewed-by: tags
- switched to BOOTSTD_FULL to enable efi_bootmgr and make interactive
  use easier
- override BOOTCOMMAND to not list the bootflows
- rebased onto v2024.04
- Link to v1: https://lore.kernel.org/r/20240317-apple_config-v1-0-1b862bc140a9@jannau.net

---
Hector Martin (1):
      apple_m1_defconfig: Turn on CONFIG_SYS_64BIT_LBA

Janne Grunau (4):
      configs: apple: Use "vidconsole,serial" as stdout/stderr
      configs: apple: Enable CMD_SELECT_FONT and FONT_16X32
      arm: apple: Switch to standard boot
      arm: apple: Do not list bootflows on boot

 arch/arm/Kconfig           |  2 +-
 configs/apple_m1_defconfig |  4 ++++
 include/configs/apple.h    | 24 ++++--------------------
 3 files changed, 9 insertions(+), 21 deletions(-)
---
base-commit: 25049ad560826f7dc1c4740883b0016014a59789
change-id: 20240317-apple_config-981fcd9028b9

Best regards,
-- 
Janne Grunau <j@jannau.net>

