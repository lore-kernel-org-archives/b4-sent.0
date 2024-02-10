From: Janne Grunau <j@jannau.net>
Subject: [PATCH v2 0/6] video: Add UTF-8 support for UEFI applications
Date: Sat, 10 Feb 2024 13:46:38 +0100
Message-Id: <20240210-vidconsole-utf8-uefi-v2-0-88c03db60de2@jannau.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAC9wx2UC/4WNTQ6CMBBGr0Jm7Rha/sSV9zAsSpnKGNOSFhoN6
 d2tXMDle8n3vh0CeaYA12IHT5EDO5tBngrQs7IPQp4ygyxlXQrRYeRJOxvci3BbzQU3MoxGyWq
 slW6bqYU8XXy27yN7HzLPHFbnP8dLFD/7JxgFlthUvek0dbUZ+9tTWau2s6UVhpTSF3EIIJO5A
 AAA
To: Anatolij Gustschin <agust@denx.de>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>
Cc: Simon Glass <sjg@chromium.org>, Andre Przywara <andre.przywara@arm.com>, 
 u-boot@lists.denx.de, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2454; i=j@jannau.net;
 h=from:subject:message-id; bh=qrrIsRuZER9w8JJwPSokL7SPOouqThiSo5O68q33i2I=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhtTjBVZflkwsYp9iNVfQ+OU81l7j04d8g29maTKuOvbD5
 OljveedHaUsDGJcDLJiiixJ2i87GFbXKMbUPgiDmcPKBDKEgYtTACbCosbI0LFrDa/LPpGJl82U
 tlrl7nGY+f+J14eXOy7L6Ymn2y02UmL4n8Lz2PhQreZhe9+UN5ZaISn7979VPrBsU+HOBerN/rv
 TWAE=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Andre submitted 2 years ago DM_VIDEO improvements for UEFI applications
using UEFI's EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL but did not follow with
suggested changes. This series takes care of the UTF-8 support which
required to draw symbol and box drawing characters used by UEFI
applications like grub2 and sd-boot correctly.

Compared to Andre's version this version has the following changes:
- use and extend existing conversion functions from lib/charset.c
- convert to Unicode code points for truetype console support
- conversion is conditional on CONFIG_CHARSET
- use escape sequences in tests as proposed by Heinrich

Link: https://lore.kernel.org/u-boot/20220110005638.21599-1-andre.przywara@arm.com/
Signed-off-by: Janne Grunau <j@jannau.net>
---
Changes in v2:
- use "CONFIG_IS_ENABLED(CHARSET)" instead of EFI_LOADER
- rewritten commit message for mapping CP437 cp 1-31
- extended utf8_to_utf32_stream() documentation as suggested by
  Heinrich
- Link to RFC: https://lore.kernel.org/r/20240117-vidconsole-utf8-uefi-v1-0-539f7ce74fb9@jannau.net

---
Andre Przywara (2):
      efi_selftest: Add international characters test
      efi_selftest: Add box drawing character selftest

Janne Grunau (4):
      lib: charset: Fix and extend utf8_to_utf32_stream() documentation
      video: console: Parse UTF-8 character sequences
      lib/charset: Map Unicode code points to CP437 code points 0-31
      efi_selftest: Add symbol character selftest

 drivers/video/console_normal.c             |  6 +++--
 drivers/video/console_rotate.c             | 16 +++++++++-----
 drivers/video/console_truetype.c           |  8 +++----
 drivers/video/vidconsole-uclass.c          | 18 ++++++++++-----
 drivers/video/vidconsole_internal.h        | 15 +++++++++++++
 include/charset.h                          | 16 +++++++++++---
 include/cp1250.h                           | 12 ++++++++--
 include/cp437.h                            | 12 ++++++++--
 include/video_console.h                    | 10 +++++----
 lib/charset.c                              |  9 +++++---
 lib/efi_loader/efi_unicode_collation.c     |  2 +-
 lib/efi_selftest/efi_selftest_textoutput.c | 35 ++++++++++++++++++++++++++++++
 12 files changed, 127 insertions(+), 32 deletions(-)
---
base-commit: 866ca972d6c3cabeaf6dbac431e8e08bb30b3c8e
change-id: 20240117-vidconsole-utf8-uefi-fa23b4ac65d6

Best regards,
-- 
Janne Grunau <j@jannau.net>

