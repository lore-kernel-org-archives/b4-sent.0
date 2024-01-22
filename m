From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH v3 0/5] net: hifemac: a few cleanups
Date: Mon, 22 Jan 2024 22:33:19 +0800
Message-Id: <20240122-net-v3-0-f1e80564725b@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAK98rmUC/1WMwQ6CMBAFf4Xs2Rq6xVI8+R/GQymLNGprWmw0h
 H+34EWO8/JmJogULEU4FhMESjZa7zKIXQFm0O5KzHaZAUusSs4b5mhkNWqBsj4QtRXk5zNQb99
 r5XzJPNg4+vBZo4kv69ZPnJWs4z21irjURp78a7x7f9sb/4ClkPDPQvxZmK1aaSGVamQvcWvN8
 /wFLb1XZ84AAAA=
To: Joe Hershberger <joe.hershberger@ni.com>, 
 Ramon Fried <rfried.dev@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705934004; l=1219;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=t8eOdm8eaQWLmDlJrYsiVJeZtCWqqiz2sfmyGJzGwCE=;
 b=qdYz47FMgb1P5V0vE3zEmPFxFZwcUvFqNasSNFQbJHE22i9ouHT7no25DPH0eX5scloRV0RY9
 PVpN2ew7ZlYCOGvN61Ww9ZZZ6I0xQcFrT7mOR5tdeaC0PWzUFZSQFfW
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

- Fix the use of log_msg_ret() and add dev_xxx() for error reporting.
- Register mdio subnode as a mdio bus device for hifemac.
- Implement ops needed by `net stats`
- Make functions static.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Changes in v3:
- hisi-femac: add missing `static` to avoid polluting global namespace.
- Link to v2: https://lore.kernel.org/r/20240122-net-v2-0-78a368896f62@outlook.com

Changes in v2:
- hisi-femac: add statistics related operations
- Link to v1: https://lore.kernel.org/r/20240119-net-v1-0-d1feb8e16ac6@outlook.com

---
Yang Xiwen (5):
      net: hifemac_mdio: use log_msg_ret() correctly, report error by dev_err()
      net: hifemac: fix log reporting
      net: hifemac: register MDIO bus device for subnode
      net: hifemac: implement `net stats` needed ops
      net: hifemac: make some functions static

 drivers/net/hifemac.c      | 229 +++++++++++++++++++++++++++++++++++++--------
 drivers/net/hifemac_mdio.c |  11 ++-
 2 files changed, 198 insertions(+), 42 deletions(-)
---
base-commit: f7cca7ccc5117eaafcc2bde91ad1bed6fee7cfc3
change-id: 20240119-net-72a32675eeb4

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

