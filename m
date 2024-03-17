From: Janne Grunau <j@jannau.net>
Subject: [PATCH 0/4] configs: apple: Switch to standard boot + small
 adjustments
Date: Sun, 17 Mar 2024 15:54:46 +0100
Message-Id: <20240317-apple_config-v1-0-1b862bc140a9@jannau.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADYE92UC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDY0Nz3cSCgpzU+OT8vLTMdF1LC8O05BRLAyOLJEsloJaCotS0zAqwcdG
 xtbUAFJllBl4AAAA=
To: Mark Kettenis <kettenis@openbsd.org>, Tom Rini <trini@konsulko.com>
Cc: Simon Glass <sjg@chromium.org>, u-boot@lists.denx.de, 
 asahi@lists.linux.dev, Janne Grunau <j@jannau.net>, 
 Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1019; i=j@jannau.net;
 h=from:subject:message-id; bh=GHsx6X1WIlFwSlzUjkLM+TSgi9zdmDPgNrNQSgJxM0Y=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhtTvLOZX0ycU5D7YXNAWGLI8uXtyh8dxuW2bts758+hx6
 Z8N3yZ5dJSyMIhxMciKKbIkab/sYFhdoxhT+yAMZg4rE8gQBi5OAZiIziFGhtUlu45+4EmNTfr3
 f6/qC6/iZXaSu5bW8C6d/ZZz3xrhJ+sZfjFf223xqXYSU4//vey4xnuPHffK9iyKXFlpwbf+jLf
 AJQ4A
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
- enables 64-bit LBA addressing for USB storage devices larger than 2TB

Signed-off-by: Janne Grunau <j@jannau.net>
---
Hector Martin (1):
      apple_m1_defconfig: Turn on CONFIG_SYS_64BIT_LBA

Janne Grunau (3):
      configs: apple: Use "vidconsole,serial" as stdout/stderr
      configs: apple: Enable CMD_SELECT_FONT and FONT_16X32
      arm: apple: Switch to standard boot

 arch/arm/Kconfig           |  2 +-
 configs/apple_m1_defconfig |  3 +++
 include/configs/apple.h    | 24 ++++--------------------
 3 files changed, 8 insertions(+), 21 deletions(-)
---
base-commit: f3c979dd0053c082d2df170446923e7ce5edbc2d
change-id: 20240317-apple_config-981fcd9028b9

Best regards,
-- 
Janne Grunau <j@jannau.net>

