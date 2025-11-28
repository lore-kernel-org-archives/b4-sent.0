From: Maud Spierings <maudspierings@gocontroll.com>
Subject: [PATCH 0/3] scripts: imx: imx-usb-loader: fix mingw compilation
Date: Fri, 28 Nov 2025 15:08:51 +0100
Message-Id: <20251128-imx_usb-v1-0-bb6a5180b38e@gocontroll.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPOsKWkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDQyML3czcivjS4iRdE0ODpKQkU/NUAzMLJaDqgqLUtMwKsEnRsbW1ACn
 nNCpZAAAA
X-Change-ID: 20251128-imx_usb-410bbb57e068
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764339080; l=643;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=FOkEnvEJmefM83hRliyO6otJ/MBuDcMphB3DLrN2qCY=;
 b=wZqAQmzlJbsqEIfRfPMPMP/qFLRJPFU8VdB4WgBy+FdDL+u3QXOwoE8townA1qVNs02gDqS/W
 EGcq/WiInfpBiGGMUHdqrnWu+Li0902aCnj9Cz4P3a5D138PYFtxLxs
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Compiling imx-usb-loader for windows targets had become broken, fix it.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
Maud Spierings (3):
      scripts: common: fix pread_full() for windows
      scripts: imx: Makefile.mingw64: add _GNU_SOURCE
      gitignore: ignore *.exe

 .gitignore                   | 1 +
 scripts/common.c             | 6 +++++-
 scripts/imx/Makefile.mingw64 | 2 +-
 3 files changed, 7 insertions(+), 2 deletions(-)
---
base-commit: 3e01efb6c6527ca72a1213000006be1902db7be9
change-id: 20251128-imx_usb-410bbb57e068

Best regards,
-- 
Maud Spierings <maudspierings@gocontroll.com>

