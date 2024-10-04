From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH v2 0/3] Input: adp5588-keys: refactor adp5588_read()
Date: Fri, 04 Oct 2024 15:46:49 +0200
Message-Id: <20241004-fix-adp5588-read-refactor-v2-0-275a093758ae@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAMnx/2YC/42N0Q6CMAxFf4X02ZptMqk++R+Ghzo2aKKMbIZgC
 P/u5At8aXJ6b09XyD6Jz3CtVkh+lixxLGAOFbiBx96jdIXBKFNrpQwGWZC7yVoiTJ67MgK7d0z
 IZB0Rh1qdDZT7qSSy7O57W3iQXGqf/dWsf9t/rLNGhYZIqaAfl6Y53XjkZ+yPLr6g3bbtC7Cfo
 yzDAAAA
To: Michael Hennerich <michael.hennerich@analog.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728049615; l=767;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=oZbY7cjUlUXs+rZdZPhUrlKHoQ+v6J/LO/oK31lbn4A=;
 b=XHBzVocNO/baFkv19sn1LrVqmxrRKLvUQHt+7x0VVkAJyqYwBHVTTzYA1qtBkdoiu7QX2GkSZ
 vOz35NoCgkkDfq6avibKeeaCAfxbDuwSBpU7FtRgKxPSzXiNAKVXKP9
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi Dmitry,

Here it goes v2. I ended up squashing the patches as the patch is still fairly
simple.

---
Changes in v2:
- Link to v1: https://lore.kernel.org/r/20241002-fix-adp5588-read-refactor-v1-0-28800f1b9773@analog.com
- Squashed patch 1 and 2 so that we don't return an int into an u8.

---
Nuno Sa (3):
      Input: adp5588-keys: bail on returned error
      Input: adp5588-keys: error out if no IRQ is given
      Input: adp5588-keys: make use of dev_err_probe()

 drivers/input/keyboard/adp5588-keys.c | 151 +++++++++++++++++++---------------
 1 file changed, 86 insertions(+), 65 deletions(-)
---
base-commit: c684771630e64bc39bddffeb65dd8a6612a6b249
change-id: 20241002-fix-adp5588-read-refactor-a85c88af4062
--

Thanks!
- Nuno Sá

