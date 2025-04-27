From: Levi Zim <rsworktech@outlook.com>
Date: Sun, 27 Apr 2025 22:36:59 +0800
Subject: [PATCH net] docs: tproxy: fix code block style
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250427-tproxy-docs-fix-v1-1-988e94844ccb@outlook.com>
X-B4-Tracking: v=1; b=H4sIAAtBDmgC/x2MQQqAIBAAvyJ7bqHEiPpKdEhbay8qKmGEf086z
 sDMC4kiU4JFvBDp5sTeNRg6Aeba3UnIR2OQvRx7JSfMIfry4OFNQssFjdFaWyVHNVtoVYjU9H9
 cwVGGrdYPkk9mnmYAAAA=
X-Change-ID: 20250427-tproxy-docs-fix-ccbbbf42549f
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: netdev@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Levi Zim <rsworktech@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1174;
 i=rsworktech@outlook.com; s=not_default; h=from:subject:message-id;
 bh=cby+1jVkm77u6wkNVFnwY7Zel5ns9SwCbUFjdQo23d8=;
 b=owEBbQKS/ZANAwAIAW87mNQvxsnYAcsmYgBoDkEMC9YQa4pYiRQ4m8eDAv3pFcvx3SdQvUtxA
 t5FkHu8dVyJAjMEAAEIAB0WIQQolnD5HDY18KF0JEVvO5jUL8bJ2AUCaA5BDAAKCRBvO5jUL8bJ
 2KgHEADOuGO9cGsSUh1JGInQtQK/Nj56a2IhHlhvZbMELaEFp7sz389+1psGnMqwmAtijjz311F
 ScH6yNQ01ox8XzUj/zHbhP7+5d3yXT1KMuyArrVWYwWkQ/3rPfOqtNxNNBTNCWVdqaW5RzT9Y+f
 u2BdaEPreaXeVkTsu5ze6vTout+y31EDzPihMqgKu5NZL6XsHt9QDSCSi9MeBCCFDpSZKzKGjrP
 9zwR17lLhc37Z92qsSKVl+p5LOdXwAzFM/XqTTFHji1p6HUME/ygaR2RyeAfU8D1tq0Q5bSsXfm
 av6DyFc+rLqnlFAiEYA3gmjS6yndiWJOkMLPYv91+qPYAJr0pa47DCtJeH9VpXOrZhRJXlZVpNI
 4aTZsHYqPLYPYHxecSGDJlE1v7m4jq/X2wrogJRqr/9AOES0OyRkWbtW22XPYKvW250yW+LrNB/
 Z/sY7utlfFRSLxPBVBHBMB24bxoeornVdZUwYV75RrtiSHCspMbgq/T3phsT2lj5+t8s2Ti0wRA
 2XBXggkU5sPTaJDdqeei6a9GoAYNWlykcG+9/wU6LFx/CDDKFJS7t3pbPoW2oFINQMHjucyAsIY
 A2HVmOQ5+2x/jKEpgyjIG10C28uZDKp0YWCp1McjMBHaQahP2kXS0PQE2t+Q7GxTfLR/09LvjfQ
 IchJaG0Q92+xFyQ==
X-Developer-Key: i=rsworktech@outlook.com; a=openpgp;
 fpr=17AADD6726DDC58B8EE5881757670CCFA42CCF0A
X-Endpoint-Received: by B4 Relay for rsworktech@outlook.com/not_default with auth_id=390
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The last command is not indented thus does not show as code block when
rendered. This patch fixes it.

Fixes: 4ac0b122ee63 ("docs: networking: convert tproxy.txt to ReST")
Signed-off-by: Levi Zim <rsworktech@outlook.com>
---
 Documentation/networking/tproxy.rst | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Documentation/networking/tproxy.rst b/Documentation/networking/tproxy.rst
index 7f7c1ff6f159ed98d96c63d99c98ddbaefd47124..102c030e3cf06d6e9607f7668b417b99a3a62300 100644
--- a/Documentation/networking/tproxy.rst
+++ b/Documentation/networking/tproxy.rst
@@ -71,7 +71,7 @@ add rules like this to the iptables ruleset above::
 
 Or the following rule to nft:
 
-# nft add rule filter divert tcp dport 80 tproxy to :50080 meta mark set 1 accept
+    # nft add rule filter divert tcp dport 80 tproxy to :50080 meta mark set 1 accept
 
 Note that for this to work you'll have to modify the proxy to enable (SOL_IP,
 IP_TRANSPARENT) for the listening socket.

---
base-commit: f73f05c6f711fd1628c7565441b9febc0c4d6c58
change-id: 20250427-tproxy-docs-fix-ccbbbf42549f

Best regards,
-- 
Levi Zim <rsworktech@outlook.com>

