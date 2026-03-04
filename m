From: Maximilian Pezzullo <maximilianpezzullo@gmail.com>
Subject: [PATCH v2 0/2] Fix typos in comments in Intel Ethernet drivers
 (igb, igc)
Date: Wed, 04 Mar 2026 08:21:18 +0100
Message-Id: <20260304-fix-typos-in-comments-in-intel-ethernet-drivers-igb-igc-v2-0-b6a9f1d336ff@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2NwQqDMBBEf0X23IUQQ6X9ldJDk6y6UDeyCWIR/
 72Lh4F5DLw5oJIyVXh2ByhtXLmIgb91kOaPTIScjcE7f3e9Czjyju23loosmMqykLSrszT6IrW
 ZVKhhVt5IbZmiJWEfw2OILo9hyGD2VclU1/PrfZ5/iTsfY4kAAAA=
X-Change-ID: 20260304-fix-typos-in-comments-in-intel-ethernet-drivers-igb-igc-3b497b0df47d
To: Tony Nguyen <anthony.l.nguyen@intel.com>, 
 Przemek Kitszel <przemyslaw.kitszel@intel.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: intel-wired-lan@lists.osuosl.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Joe Damato <joe@dama.to>, 
 Maximilian Pezzullo <maximilianpezzullo@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772608916; l=1013;
 i=maximilianpezzullo@gmail.com; s=20260303; h=from:subject:message-id;
 bh=rqm1hIKFXnYB5F1diGKPD+DC9avHWqfyIaJZ3phGQak=;
 b=jGLaa1WXEILpn8rGbNZrfHas9wq6FwGnb0CbwLp9lSUNsPN3/058qUyC7++bGPw7K1sgWQRmm
 5uUvoYTwCdADv8y8Mi2qy30t1bf7xB0s9WLxX1ycQNn88z8rC5f/MhL
X-Developer-Key: i=maximilianpezzullo@gmail.com; a=ed25519;
 pk=TRTR4c2Vb1IfluQvv5OUDPg7EE+pIzdPBND85UU559w=
X-Endpoint-Received: by B4 Relay for maximilianpezzullo@gmail.com/20260303 with auth_id=658
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is v2, adding a typo fix noticed by Joe Damato in e1000_defines.h
("Device Reset Aserted" -> "Device Reset Asserted").

Changes in v2:
- igb: also fix 'Aserted' -> 'Asserted' in e1000_defines.h (suggested by Joe Damato)

Signed-off-by: Maximilian Pezzullo <maximilianpezzullo@gmail.com>
---
Maximilian Pezzullo (2):
      igb: fix typos in comments
      igc: fix typos in comments

 drivers/net/ethernet/intel/igb/e1000_defines.h | 2 +-
 drivers/net/ethernet/intel/igb/e1000_mac.c     | 2 +-
 drivers/net/ethernet/intel/igb/e1000_mbx.h     | 2 +-
 drivers/net/ethernet/intel/igb/e1000_nvm.c     | 2 +-
 drivers/net/ethernet/intel/igc/igc_diag.c      | 2 +-
 drivers/net/ethernet/intel/igc/igc_main.c      | 4 ++--
 6 files changed, 7 insertions(+), 7 deletions(-)
---
base-commit: af4e9ef3d78420feb8fe58cd9a1ab80c501b3c08
change-id: 20260304-fix-typos-in-comments-in-intel-ethernet-drivers-igb-igc-3b497b0df47d

Best regards,
-- 
Maximilian Pezzullo <maximilianpezzullo@gmail.com>

