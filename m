From: Jakub Boehm <boehm.jakub@gmail.com>
Date: Tue, 15 Oct 2024 17:16:04 +0200
Subject: [PATCH] net: plip: fix break; causing plip to never transmit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241015-net-plip-tx-fix-v1-1-32d8be1c7e0b@gmail.com>
X-B4-Tracking: v=1; b=H4sIADOHDmcC/x2MUQqAIBAFrxL73UKKRnWV6EPqVQthohJBdPekz
 xmYeSghChIN1UMRlyQ5fQFVVzTvzm9gWQqTbrRRjbLskTkcEjjfvMrNndboDWznWlCpQkTR/3G
 c3vcD+1936WEAAAA=
X-Change-ID: 20241015-net-plip-tx-fix-822e94e58a6e
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Nathan Chancellor <nathan@kernel.org>, 
 Nick Desaulniers <ndesaulniers@google.com>, 
 Bill Wendling <morbo@google.com>, Justin Stitt <justinstitt@google.com>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 llvm@lists.linux.dev, Jakub Boehm <boehm.jakub@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729005371; l=1232;
 i=boehm.jakub@gmail.com; s=20241015; h=from:subject:message-id;
 bh=GSlzcLm/qPyuhys1asxJpTawVSorVrfA4ue4kauwzWE=;
 b=By9Huyk052EGor7HPwC5HMjk+iUzXISWFW4WNpJ9QtGtZf82sMIZfhCqPBwMhkofUmn/m8xv2
 D8Ztx+eNsrOD2NGjz4Id9B/Jf7ipoDiwVyclxdm/Siw5Do8PU6FgSJm
X-Developer-Key: i=boehm.jakub@gmail.com; a=ed25519;
 pk=Ec61DIB+jRZFEPPDlta4lWaV/69t+jWiuBU6SF909iQ=
X-Endpoint-Received: by B4 Relay for boehm.jakub@gmail.com/20241015 with auth_id=249
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit
  71ae2cb30531 ("net: plip: Fix fall-through warnings for Clang")

plip was not able to send any packets, this patch replaces one
unintended break; with fallthrough; which was originally missed by
commit 9525d69a3667 ("net: plip: mark expected switch fall-throughs").

I have verified with a real hardware PLIP connection that everything
works once again after applying this patch.

Fixes: 71ae2cb30531 ("net: plip: Fix fall-through warnings for Clang")
Signed-off-by: Jakub Boehm <boehm.jakub@gmail.com>
---
 drivers/net/plip/plip.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/plip/plip.c b/drivers/net/plip/plip.c
index e39bfaefe8c50ba72238d04f08deaa46ca650c70..d81163bc910a3bcaa770a10c0e2d7d9b334a381b 100644
--- a/drivers/net/plip/plip.c
+++ b/drivers/net/plip/plip.c
@@ -815,7 +815,7 @@ plip_send_packet(struct net_device *dev, struct net_local *nl,
 				return HS_TIMEOUT;
 			}
 		}
-		break;
+		fallthrough;
 
 	case PLIP_PK_LENGTH_LSB:
 		if (plip_send(nibble_timeout, dev,

---
base-commit: 8e929cb546ee42c9a61d24fae60605e9e3192354
change-id: 20241015-net-plip-tx-fix-822e94e58a6e

Best regards,
-- 
Jakub Boehm <boehm.jakub@gmail.com>

