From: Maximilian Pezzullo <maximilianpezzullo@gmail.com>
Subject: [PATCH 0/2] Fix typos in comments in Intel Ethernet drivers (igb,
 igc)
Date: Tue, 03 Mar 2026 22:38:19 +0100
Message-Id: <20260303-master-v1-0-f180b1ad98b5@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDYwNj3dzE4pLUIl3DVEtLSwMLSwvDpGQloOKCotS0zAqwQdGxtbUAojo
 o1lgAAAA=
X-Change-ID: 20260303-master-1e99908981bc
To: Tony Nguyen <anthony.l.nguyen@intel.com>, 
 Przemek Kitszel <przemyslaw.kitszel@intel.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: intel-wired-lan@lists.osuosl.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Maximilian Pezzullo <maximilianpezzullo@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772573919; l=656;
 i=maximilianpezzullo@gmail.com; s=20260303; h=from:subject:message-id;
 bh=AjH7WLa9bAhWMALSAH3NuMvfF6ECbIBSXWNf/e4MfJg=;
 b=L/lPOvYciaiOzmbZFaB9ATg9XQKiN5iExZe8cRlu0nHygPOjY8Zq026P5Nt/nThTqABdnRJ0g
 Jt6S6R0m4IIDygn/0pWWTORonyao+CMPl5iUbD3KSErd876dkCdcEuE
X-Developer-Key: i=maximilianpezzullo@gmail.com; a=ed25519;
 pk=TRTR4c2Vb1IfluQvv5OUDPg7EE+pIzdPBND85UU559w=
X-Endpoint-Received: by B4 Relay for maximilianpezzullo@gmail.com/20260303 with auth_id=658
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Maximilian Pezzullo <maximilianpezzullo@gmail.com>
---
Maximilian Pezzullo (2):
      igb: fix typos in comments
      igc: fix typos in comments

 drivers/net/ethernet/intel/igb/e1000_mac.c | 2 +-
 drivers/net/ethernet/intel/igb/e1000_mbx.h | 2 +-
 drivers/net/ethernet/intel/igb/e1000_nvm.c | 2 +-
 drivers/net/ethernet/intel/igc/igc_diag.c  | 2 +-
 drivers/net/ethernet/intel/igc/igc_main.c  | 4 ++--
 5 files changed, 6 insertions(+), 6 deletions(-)
---
base-commit: 4258db5c0acd08e795c78c7cd59f05860b7cb769
change-id: 20260303-master-1e99908981bc

Best regards,
-- 
Maximilian Pezzullo <maximilianpezzullo@gmail.com>

