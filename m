From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH 0/3] net: hifemac: a few cleanups
Date: Fri, 19 Jan 2024 19:44:27 +0800
Message-Id: <20240119-net-v1-0-d1feb8e16ac6@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJtgqmUC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDQ0NL3bzUEl1zo0RjIzNz09TUJBMloMqCotS0zAqwKdGxtbUAGnCncVU
 AAAA=
To: Joe Hershberger <joe.hershberger@ni.com>, 
 Ramon Fried <rfried.dev@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705664668; l=720;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=GosKtxU73aFIPQGFRc6FM8kcXFBSXm3PgdAcWrgvLFU=;
 b=wo6PsqxSUcI1euxuKNl5x/g0jSkAAKzxOESz/lhi+e4xrYRZcZswBImIMxllHLBoIbLi+0DET
 BnB7BCk/ikJAaXGIL2/dcF+Ixl9yAvChB//S5E+Dk5iCm0wl9uZrDPW
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the use of log_msg_ret() and add dev_xxx() for error reporting.

Register mdio subnode as a mdio bus device for hifemac.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Yang Xiwen (3):
      net: hifemac_mdio: use log_msg_ret() correctly, report error by dev_err()
      net: hifemac: fix log reporting
      net: hifemac: register MDIO bus device for subnode

 drivers/net/hifemac.c      | 138 +++++++++++++++++++++++++++++++++------------
 drivers/net/hifemac_mdio.c |  11 +++-
 2 files changed, 109 insertions(+), 40 deletions(-)
---
base-commit: f7cca7ccc5117eaafcc2bde91ad1bed6fee7cfc3
change-id: 20240119-net-72a32675eeb4

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

