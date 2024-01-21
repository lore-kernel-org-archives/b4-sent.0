From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH v2 0/4] net: hifemac: a few cleanups
Date: Mon, 22 Jan 2024 05:02:03 +0800
Message-Id: <20240122-net-v2-0-78a368896f62@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEyGrWUC/1WMQQ7CIBBFr9LMWgyDlaor72G6oHRqJyoYQKJpu
 LvYncv3899bIFJginBqFgiUObJ3FdSmATsbdyXBY2VQUrUS8SgcJdEps1O62xMNLdTnM9DE77V
 y6SvPHJMPnzWa8bf++xmFFCNONBwItbH67F/p7v1ta/0D+lLKF2ommeSYAAAA
To: Joe Hershberger <joe.hershberger@ni.com>, 
 Ramon Fried <rfried.dev@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705870930; l=968;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=rfTkZjUuZSdNKh1rlWNItJX6G5H9yB1K6D6UzoYxBC8=;
 b=vfjcjhsui3wt8ON0YId3zYCv34pQo2QkrQUdJoRs8Zwy6OmIc+opgqpVpvUAM+XDTT79eVBrk
 n16W9sldqSZDjBHVPwP05rKek4qPUDeEB9Lfv4ga1ElojqOxyGL1MVU
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the use of log_msg_ret() and add dev_xxx() for error reporting.

Register mdio subnode as a mdio bus device for hifemac.

Implement ops needed by `net stats`

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Changes in v2:
- hisi-femac: add statistics related operations
- Link to v1: https://lore.kernel.org/r/20240119-net-v1-0-d1feb8e16ac6@outlook.com

---
Yang Xiwen (4):
      net: hifemac_mdio: use log_msg_ret() correctly, report error by dev_err()
      net: hifemac: fix log reporting
      net: hifemac: register MDIO bus device for subnode
      net: hifemac: implement `net stats` needed ops

 drivers/net/hifemac.c      | 225 +++++++++++++++++++++++++++++++++++++--------
 drivers/net/hifemac_mdio.c |  11 ++-
 2 files changed, 196 insertions(+), 40 deletions(-)
---
base-commit: f7cca7ccc5117eaafcc2bde91ad1bed6fee7cfc3
change-id: 20240119-net-72a32675eeb4

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

