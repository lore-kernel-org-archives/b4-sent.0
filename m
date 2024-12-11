From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH v2 0/3] cmd: ufetch improvements
Date: Wed, 11 Dec 2024 23:25:24 +0100
Message-Id: <20241211-ufetch-v2-0-2b5432ffaeb1@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAFQRWmcC/zXMQQ6DIBCF4auYWZcGRovWVe/RuFAZChswQEkbw
 91LTVz+Ly/fDpGCpQhjs0OgbKP1rgZeGljN7F7ErKoNyLETyFv21pRWw1qU1PdiQTkrqOctkLa
 fA3pOtY2NyYfv4WbxX0/idhJZMM6UHqRoxbCo7v7YfEzkr44STKWUH9ZnNpudAAAA
X-Change-ID: 20241203-ufetch-326e771b26ad
To: Caleb Connolly <caleb.connolly@linaro.org>, 
 Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733955947; l=758;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=IfwXNrjStpdZHnvc7viDk+ybbinFcvPASWXbh4NRW/Q=;
 b=PeO/m15lNwKB+vXxaPSAVnPoDbKplLmdFhSV6sXSECDDwNnPXxo3fu3V9uzBCkVLo9TBzdKfH
 j29thTTuWNKC+PPw2ZtDlApINg41E/GPjprjICQTApC6pX8dxxs4p2E
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Following the recent addition of the "ufetch" command, this patchset
improves it in a few ways.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
Changes in v2:
- Address comments and add R-b tags from Caleb
- Link to v1: https://lore.kernel.org/r/20241205-ufetch-v1-0-df861318bd49@posteo.net

---
J. Neuschäfer (3):
      cmd: ufetch: Fix type mismatch on 32-bit
      cmd: Allow building ufetch without CONFIG_BLK
      cmd: ufetch: Show CPU architecture under "CPU"

 cmd/Kconfig  |  1 -
 cmd/ufetch.c | 17 +++++++++++------
 2 files changed, 11 insertions(+), 7 deletions(-)
---
base-commit: a7efabf75cc7a31bc0c9dc8a1509a788ade238bc
change-id: 20241203-ufetch-326e771b26ad

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

