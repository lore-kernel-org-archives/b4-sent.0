From: Cunhao Lu <1579567540@qq.com>
Date: Fri, 13 Nov 2026 10:33:06 +0800
Subject: [PATCH net v2] MAINTAINERS: exclude CAN documentation from general
 networking
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-exclude-can-docs-from-netdev-v2-1-8ae9dc553024@qq.com>
X-B4-Tracking: v=1; b=H4sIAOF29moC/42OTQ6CMBSEr0Le2mdsFVRW3sOw6M+r1EgrLTQYw
 t0teAGXM/nyzcwQKViKUBczBEo2Wu9y4LsCVCvcg9DqnIEfeMUY40iTeo2aUAmH2quIJvgOHQ2
 aEpYVO1816dIIA1nxDmTstOnvkBlofmUc5ZPUsIpXrLVx8OGznUhsg//bSwwZypLkUYqToEt16
 /u98h00y7J8AU3Z2VncAAAA
X-Change-ID: 20261112-exclude-can-docs-from-netdev-56179ded5faf
To: Jakub Kicinski <kuba@kernel.org>, netdev@vger.kernel.org
Cc: davem@davemloft.net, edumazet@kernel.org, pabeni@redhat.com, 
 horms@kernel.org, mkl@pengutronix.de, mailhol@kernel.org, 
 socketcan@hartkopp.net, robin@protonic.nl, o.rempel@pengutronix.de, 
 kernel@pengutronix.de, max@enpas.org, linux-can@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Cunhao Lu <1579567540@qq.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794537207; l=2171;
 i=1579567540@qq.com; s=20261015; h=from:subject:message-id;
 bh=6F5YqxvMaIs1hwfEFbyXKXtIGxmZw++Ht0ooa1sJl88=;
 b=2DNpMdnz/83Syn6nW0AH1yBI48kZvv0cu5uv4pbBSxBZT83lgUHpn/v33Y0qTCpn1Mcz1CPHd
 ojULR3hSGccDOvJWX+jBOA9x/rKs40M64/FX5tRwWQHC5CmFIX0Z7LZ
X-Developer-Key: i=1579567540@qq.com; a=ed25519;
 pk=sUTWrzlIwT4C7ctjNfVZAzzg0G7QUn2XxRGpYsw4RtM=
X-Endpoint-Received: by B4 Relay for 1579567540@qq.com/20261015 with auth_id=1177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SocketCAN, ISO-TP and J1939 documents and the CAN driver documentation
directory match the broad Documentation/networking/ pattern in
NETWORKING [GENERAL]. This makes get_maintainer.pl select netdev and the
general networking maintainers for these CAN-specific documentation
changes.

Exclude these paths from NETWORKING [GENERAL], as is already done for
net/can/ and the CAN selftests. Add the driver documentation directory
to CAN NETWORK DRIVERS to cover files without a dedicated CAN entry.

Suggested-by: Jakub Kicinski <kuba@kernel.org>
Link: https://lore.kernel.org/all/20261111161459.4879a82d@kernel.org/
Signed-off-by: Cunhao Lu <1579567540@qq.com>
---
Changes in v2:
- Exclude the whole CAN driver documentation directory instead of only
  can327.rst, and add it to CAN NETWORK DRIVERS.
- Link to v1: https://patch.msgid.link/20261112-exclude-can-docs-from-netdev-v1-1-b5eb3ba4ae86@qq.com
---
 MAINTAINERS | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 222b7fc2c3aa..152771314140 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -5992,6 +5992,7 @@ T:	git git://git.kernel.org/pub/scm/linux/kernel/git/mkl/linux-can.git
 T:	git git://git.kernel.org/pub/scm/linux/kernel/git/mkl/linux-can-next.git
 F:	Documentation/devicetree/bindings/net/can/
 F:	Documentation/devicetree/bindings/phy/ti,tcan104x-can.yaml
+F:	Documentation/networking/device_drivers/can/
 F:	drivers/net/can/
 F:	drivers/phy/phy-can-transceiver.c
 F:	include/linux/can/bittiming.h
@@ -19600,6 +19601,10 @@ F:	samples/pktgen/
 F:	tools/net/
 F:	tools/testing/selftests/net/
 X:	Documentation/networking/batman-adv.rst
+X:	Documentation/networking/can.rst
+X:	Documentation/networking/device_drivers/can/
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

