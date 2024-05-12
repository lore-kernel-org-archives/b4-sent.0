From: Sven Peter <sven@svenpeter.dev>
Subject: [PATCH 0/2] Bluetooth: hci_bcm4377 fixes
Date: Sun, 12 May 2024 12:12:06 +0000
Message-Id: <20240512-btfix-msgid-v1-0-ab1bd938a7f4@svenpeter.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABayQGYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDU0Mj3aSStMwK3dzi9MwU3RRzMwMjy0TzFEtDcyWgjoKiVKAk2LTo2Np
 aAC/1v5RdAAAA
To: Hector Martin <marcan@marcan.st>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sven Peter <sven@svenpeter.dev>, stable@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1715515936; l=990;
 i=sven@svenpeter.dev; s=20240512; h=from:subject:message-id;
 bh=lOIv9CYGdaM8Wpum8P1i2gOjEdfKKm5DnGLmgvog6Z4=;
 b=jo+i34A8NOxsam6xXuE0fOchQDV91L+Thb8dJuNz0ff62D+4IpNSyLKnSj5jHwq69S1kkNjWn
 LBUq4GIaVAvCemQrrixNxdXViAjDxtvuELGEqQxzUC16YPHvmWJTjQy
X-Developer-Key: i=sven@svenpeter.dev; a=ed25519;
 pk=jIiCK29HFM4fFOT2YTiA6N+4N7W+xZYQDGiO0E37bNU=
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/20240512 with auth_id=159
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

There are just two minor fixes from Hector that we've been carrying downstream
for a while now. One increases the timeout while waiting for the firmware to
boot which is optional for the controller already supported upstream but
required for a newer 4388 board for which we'll also submit support soon.
It also fixes the units for the timeouts which is why I've already included it
here. The other one fixes a call to bitmap_release_region where we only wanted
to release a single bit but are actually releasing much more.

Best,

Sven

Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
Hector Martin (2):
      Bluetooth: hci_bcm4377: Increase boot timeout
      Bluetooth: hci_bcm4377: Fix msgid release

 drivers/bluetooth/hci_bcm4377.c | 7 ++++---
 1 file changed, 4 insertions(+), 3 deletions(-)
---
base-commit: cf87f46fd34d6c19283d9625a7822f20d90b64a4
change-id: 20240512-btfix-msgid-d76029a7d917

Best regards,
-- 
Sven Peter <sven@svenpeter.dev>

