From: Haseeb Malik <haseebulhaq55@gmail.com>
Date: Thu, 01 Oct 2026 22:33:57 -0400
Subject: [PATCH net v3 1/2] macsec: check the resolved SCI for duplicates
MIME-Version: 1.0
Message-Id: <20261001-fix-macsec-duplicate-sci-v3-1-0f179fbe1f2d@gmail.com>
To: Sabrina Dubroca <sd@queasysnail.net>, netdev@vger.kernel.org
Cc: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Shuah Khan <shuah@kernel.org>, 
 Hannes Frederic Sowa <hannes@stressinduktion.org>, 
 linux-kselftest@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Haseeb Malik <haseebulhaq55@gmail.com>
X-B4-Tracking: v=1; b=H4sIABQYv2oC/32OzQ6CMBCEX4X07Gp/BMST72E8lGWFTaSQFomG8
 O4WYowXPc5k5puZRCDPFMQxmYSnkQN3LgqzSQQ21tUEXEUttNSZLHQGV35AazEQQnXvb4x2IAj
 IQFWemdSiQpOKWO89xeyKPgtHg7hEs7SBoPTWYbNQo71rLbsl33AYOv9cn4xqbb1H89+jowIF8
 pCWVb7XeKDiVEfebYtdu+6N+gNSUqo/IB1BxkijlC0pJfwGzfP8AolHw7UpAQAA
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790909457; l=3065;
 i=haseebulhaq55@gmail.com; s=default; h=from:subject:message-id;
 bh=c6QwTcnpUox928USSR3h8dDrqJk1wvgqABJGc0txQwM=;
 b=grqWsEPnoUJNbfIXd1V8nyHxG30ssY1yiYAabKUoXY4zuUE6biTAGpDDfKn211MJ0qxS2rSL3
 ie8OgC2a0VCBFn/Zrj1I23MHThAT0nkhLJTfhayseXygpwDqToiofKE
X-Developer-Key: i=haseebulhaq55@gmail.com; a=ed25519;
 pk=U/yCVc6cTsqDqxWLzvoONZ7DUA3EfRU+rfO9Xxo4p2w=
X-Endpoint-Received: by B4 Relay for haseebulhaq55@gmail.com/default with auth_id=1026
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

An all-ones IFLA_MACSEC_SCI selects the default SCI derived from the
MACsec device's MAC address and port 1. macsec_init_secy() resolves this
value and stores the result in secy.sci, but macsec_newlink() checks for
duplicates using the unchanged local sci argument.

Consequently, an all-ones request can create a second MACsec device with
the same transmit SCI on the same lower device, while requesting that
SCI explicitly returns -EBUSY.

Resolve an undefined SCI in macsec_newlink() before initializing the
SecY, so initialization and duplicate detection use the same value.
Preserve the all-ones fallback when the resulting SCI is available.

The duplicate acceptance was flagged by Sashiko, an LLM review bot,
during review of an earlier MACsec initialization fix. Source and history
inspection, followed by raw-netlink checks and selftests on the unfixed
kernel, confirmed the issue.

Fixes: c09440f7dcb3 ("macsec: introduce IEEE 802.1AE driver")
Link: https://lists.openwall.net/netdev/2026/09/16/11
Assisted-by: LLM
Signed-off-by: Haseeb Malik <haseebulhaq55@gmail.com>
---
Changes in v3:
- Split the driver fix and selftests into separate patches, as Jakub requested.
- Explain how the issue was discovered, as the submission-info bot requested.
- No code changes from v2.

Changes in v2:
- Resolve undefined SCI in macsec_newlink(), as suggested by Sabrina.

Link to v2: https://lore.kernel.org/netdev/20261001-fix-macsec-duplicate-sci-v2-1-330311abe5ec@gmail.com/

Tested on arm64/virtme with KASAN and lockdep: the regression tests
in patch 2 go from 5 pass/2 fail to 7 pass/0 fail. The full MACsec
selftest passes all 15 cases without skips.

 drivers/net/macsec.c | 8 +++-----
 1 file changed, 3 insertions(+), 5 deletions(-)

diff --git a/drivers/net/macsec.c b/drivers/net/macsec.c
index 78a19b134632..69686f22eda8 100644
--- a/drivers/net/macsec.c
+++ b/drivers/net/macsec.c
@@ -4143,9 +4143,6 @@ static void macsec_init_secy(struct net_device *dev, sci_t sci, u8 icv_len)
 	struct macsec_dev *macsec = macsec_priv(dev);
 	struct macsec_secy *secy = &macsec->secy;
 
-	if (sci == MACSEC_UNDEF_SCI)
-		sci = dev_to_sci(dev, MACSEC_PORT_ES);
-
 	secy->netdev = dev;
 	secy->operational = true;
 	secy->key_len = DEFAULT_SAK_LEN;
@@ -4178,7 +4175,7 @@ static int macsec_newlink(struct net_device *dev,
 	u8 icv_len = MACSEC_DEFAULT_ICV_LEN;
 	struct net_device *real_dev;
 	int err, mtu;
-	sci_t sci;
+	sci_t sci = MACSEC_UNDEF_SCI;
 
 	if (!tb[IFLA_LINK])
 		return -EINVAL;
@@ -4231,7 +4228,8 @@ static int macsec_newlink(struct net_device *dev,
 		sci = nla_get_sci(data[IFLA_MACSEC_SCI]);
 	else if (data && data[IFLA_MACSEC_PORT])
 		sci = dev_to_sci(dev, nla_get_be16(data[IFLA_MACSEC_PORT]));
-	else
+
+	if (sci == MACSEC_UNDEF_SCI)
 		sci = dev_to_sci(dev, MACSEC_PORT_ES);
 
 	/* Registration can notify listeners before returning. */


base-commit: 11536ee3d3e0b1bd35b6f3f8df55a6053eb0c71d
change-id: 20260926-fix-macsec-duplicate-sci-ed7635ac1c35

-- 
2.43.0

