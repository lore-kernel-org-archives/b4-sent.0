From: Petri Karhula <petri.karhula@novatron.fi>
Subject: [PATCH v2 0/2] Backlight driver to control backlight behind
 Congatec Board Controller.
Date: Wed, 19 Nov 2025 08:25:45 +0000
Message-Id: <20251119-cgbc-backlight-v2-0-4d4edd7ca662@novatron.fi>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAl/HWkC/3XMQQ7CIBCF4as0sxbDtNZUV97DdAFTChMNGCBE0
 3B3sXuX/0vet0EykU2Ca7dBNIUTB9+iP3RATnlrBC+toZf9iIiTIKtJaEWPJ1uXxTASorwsWuo
 J2ukVzcrvHbzPrR2nHOJn9wv+1r9UQYGC6KxoHCTK4XTzoagcgz+uDHOt9QtIFpQwrgAAAA==
X-Change-ID: 20251118-cgbc-backlight-35c1109db0b8
To: Thomas Richard <thomas.richard@bootlin.com>, Lee Jones <lee@kernel.org>, 
 Daniel Thompson <danielt@kernel.org>, Jingoo Han <jingoohan1@gmail.com>, 
 Helge Deller <deller@gmx.de>
Cc: linux-kernel@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 linux-fbdev@vger.kernel.org, Petri Karhula <petri.karhula@novatron.fi>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763540778; l=1068;
 i=petri.karhula@novatron.fi; s=20251118; h=from:subject:message-id;
 bh=QHwp4lY2HPcPahRZXK4LaMFm9Mk6v/c6AOOPuydO0fQ=;
 b=9AC+En9IdiAecmW78tFIvc8DEAPUbK4EcxwsMxWLlAHkyp8BR55ywXRluE6Le3nArv5o2KFH8
 MmL/x2bWw96B8p+bpE4kNLQHot5Ap5+sTkR3z0nXz7slK4d6uuzMZfX
X-Developer-Key: i=petri.karhula@novatron.fi; a=ed25519;
 pk=LRYJ99jPPsHJwdJEPkqlmzAMqo6oyw7I421aHEfDp7o=
X-Endpoint-Received: by B4 Relay for petri.karhula@novatron.fi/20251118 with auth_id=567
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This driver provides backlight brightness control through the Linux
backlight subsystem. It communicates with the board controller to
adjust LCD backlight using PWM signals. Communication is done
through Congatec Board Controller core driver.
    

Signed-off-by: Petri Karhula <petri.karhula@novatron.fi>
---
Changes in v2:
- Separated Board Controller core driver change into its own patch
- Link to v1: https://lore.kernel.org/r/20251118-cgbc-backlight-v1-1-cc6ac5301034@novatron.fi

---
Petri Karhula (2):
      backlight: Add Congatec Board Controller (CGBC) backlight support
      mfd: cgbc: Add support for backlight

 drivers/mfd/cgbc-core.c           |   1 +
 drivers/video/backlight/Kconfig   |  11 ++
 drivers/video/backlight/Makefile  |   1 +
 drivers/video/backlight/cgbc_bl.c | 281 ++++++++++++++++++++++++++++++++++++++
 4 files changed, 294 insertions(+)
---
base-commit: e7c375b181600caf135cfd03eadbc45eb530f2cb
change-id: 20251118-cgbc-backlight-35c1109db0b8

Best regards,
-- 
Petri Karhula <petri.karhula@novatron.fi>

