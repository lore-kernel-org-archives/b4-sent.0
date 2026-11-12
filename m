From: Cunhao Lu <1579567540@qq.com>
Date: Thu, 12 Nov 2026 13:50:25 +0800
Subject: [PATCH net] MAINTAINERS: exclude CAN documentation from general
 networking
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-exclude-can-docs-from-netdev-v1-1-b5eb3ba4ae86@qq.com>
X-B4-Tracking: v=1; b=H4sIAKBT9WoC/yXMUQrCMBCE4auUfXbBBFrRq4gPcXeiK5pI0pZC6
 d2N+vgPw7dSRTFUOnUrFcxWLacWbteR3EO6gU1bk9/7wTnnGYs8JwVLSKxZKseSX5wwKmbuB3c
 4KrSPIVIj3gXRlh9/pvahy3+s0/UBGb8wbdsH5nMmjYUAAAA=
X-Change-ID: 20261112-exclude-can-docs-from-netdev-56179ded5faf
To: Jakub Kicinski <kuba@kernel.org>, netdev@vger.kernel.org
Cc: davem@davemloft.net, edumazet@kernel.org, pabeni@redhat.com, 
 horms@kernel.org, mkl@pengutronix.de, mailhol@kernel.org, 
 socketcan@hartkopp.net, robin@protonic.nl, o.rempel@pengutronix.de, 
 kernel@pengutronix.de, max@enpas.org, linux-can@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Cunhao Lu <1579567540@qq.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794462709; l=1751;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=EDE/G8F7AsHZZC8XTFKoaDp+CkrXlJxUORBA2UZXClg=;
 b=1DDz/uZh0nk8aI17NVbPmWi9JCFjTJQ/qWJIX9P0DEMRV0wFBnfzmYfFxSeDqYtgfSoQg8n9H
 L7iZDPtorTZCgDjFoc9QuX6mdVSyBwZeXDXJGtstOy++hpamR+plokM
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SocketCAN, ISO-TP, J1939 and ELM327 documents are already covered by
CAN maintainer entries, but also match the broad Documentation/networking/
pattern in NETWORKING [GENERAL]. This makes get_maintainer.pl select
netdev and the general networking maintainers for these CAN-specific
documentation changes.

Exclude these four documents from NETWORKING [GENERAL], as is already
done for net/can/ and the CAN selftests.

Suggested-by: Jakub Kicinski <kuba@kernel.org>
Link: https://lore.kernel.org/all/20261111161459.4879a82d@kernel.org/
Signed-off-by: Cunhao Lu <1579567540@qq.com>
---
CAN documentation changes currently match NETWORKING [GENERAL], causing
get_maintainer.pl and b4 prep --auto-to-cc to select general networking
recipients for CAN-specific changes.

This patch excludes the SocketCAN, ISO-TP, J1939 and ELM327 documents from
that entry. All four already have CAN maintainer entries.
---
 MAINTAINERS | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 222b7fc2c3aa..cb1fec8ec5f5 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -19600,6 +19600,10 @@ F:	samples/pktgen/
 F:	tools/net/
 F:	tools/testing/selftests/net/
 X:	Documentation/networking/batman-adv.rst
+X:	Documentation/networking/can.rst
+X:	Documentation/networking/device_drivers/can/can327.rst
+X:	Documentation/networking/iso15765-2.rst
+X:	Documentation/networking/j1939.rst
 X:	Documentation/networking/mac80211-injection.rst
 X:	Documentation/networking/mac80211_hwsim/
 X:	Documentation/networking/regulatory.rst

---
base-commit: 79eb6679ef6a0d5ea68da53a8321fb1dc72299b9
change-id: 20261112-exclude-can-docs-from-netdev-56179ded5faf

Best regards,
--  
Cunhao Lu <1579567540@qq.com>

