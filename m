From: Yang Li <yang.li@amlogic.com>
Subject: [PATCH BlueZ bluez 0/2] Optimize the PA sync flow
Date: Wed, 07 Jan 2026 16:51:35 +0800
Message-Id: <20260107-mgmt_ext_adv_sid-v1-0-6832b40813fd@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJceXmkC/x2MywqAIBAAfyX2nGAe7PErEWK51UIv1CSK/r2lw
 xzmMPNAQE8YoMke8Jgo0L6xFHkGw2y3CQU5dlBSaVnIUqzTGg1e0ViXTCAntLajsrJmKuDs8Dj
 S9S9b6JcTb+je9wMZ+sigaQAAAA==
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767775901; l=665;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=BB6Zo9Ch6b6qrvLJcbZ84/9go69rlEbnAxDnI8Luqhw=;
 b=/yyOb0GJXmRIAuYi5KOedfouW/u2aWtGWSXZ6YUA7mFX87U46dVMeLnENWR8PZ2D2TMBgPaZL
 9PmvEWftCioB+l8rPqLzVFV5yu20zM/k5221DOq7FITT0MYzuODCcfK
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
Yang Li (2):
      adapter: add MGMT_EV_EXT_ADV_SID_CHANGED mgmt event
      bap: add timer to wait for SID update before PA sync

 lib/bluetooth/mgmt.h |  7 +++++++
 profiles/audio/bap.c | 47 ++++++++++++++++++++++++++++++++++++++++++++++-
 src/adapter.c        | 39 +++++++++++++++++++++++++++++++++++++--
 src/device.c         | 22 ++++++++++++++++++++++
 src/device.h         |  2 ++
 5 files changed, 114 insertions(+), 3 deletions(-)
---
base-commit: b35b6befb12c91c1802d09208ea5a00f0b0bc614
change-id: 20260107-mgmt_ext_adv_sid-66af2a092a08

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

