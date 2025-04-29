From: Levi Zim <rsworktech@outlook.com>
Date: Tue, 29 Apr 2025 22:49:37 +0800
Subject: [PATCH net v2] docs: tproxy: fix code block style
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250429-tproxy-docs-fix-v2-1-20cbe0d91827@outlook.com>
X-B4-Tracking: v=1; b=H4sIAADnEGgC/3WNwQ7CIBBEf6XZs2taQiP15H+YHoQulqjdBpC0a
 fh3CXeP8ybz5oBA3lGAa3OAp+SC46UEcWrAzI/lSeimkkG0om+luGBcPW87TmwCWrehMVprK0U
 vBwtltXoquBrvsFCEscDZhch+ry+pq9VfYeqww0EpGqSSsuhv/I1v5tfZ8AfGnPMP4NGXbbUAA
 AA=
X-Change-ID: 20250427-tproxy-docs-fix-ccbbbf42549f
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, 
 Mauro Carvalho Chehab <mchehab+huawei@kernel.org>
Cc: netdev@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Bagas Sanjaya <bagasdotme@gmail.com>, 
 Levi Zim <rsworktech@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1513;
 i=rsworktech@outlook.com; s=not_default; h=from:subject:message-id;
 bh=NKjV0mTkVlgZ5Qae4uXgQi5NGdHyS6jBKgNza+UO9ck=;
 b=owEBbQKS/ZANAwAIAW87mNQvxsnYAcsmYgBoEOcaFCexvq7uGJB1WvGKOAK/+N2YlYX7U4MvE
 Xj/h1GjLKuJAjMEAAEIAB0WIQQolnD5HDY18KF0JEVvO5jUL8bJ2AUCaBDnGgAKCRBvO5jUL8bJ
 2GzgD/9ioRWNEeQIjH1V0ALiE+1n0soTvI/Ck2yvHO7h9Byser86y8ZveLp5TV2+jvQME2HtupI
 UecwXF/GWFqM3aWN3+D3j4bzW72yxxP+9EtL90PIiZWdB48sgGae02oMFnQIH45gISVANiWwg8Q
 5E/sCCopJEObePMgvy6FHgoRk6l4Qh+nxqGMYfbgpBIHoWloWy89s/+r5OFc9jJ9y5i4qkqtvZf
 IIJH9Wm/qDX3W2gY9Q8RzIAedV2LXI44dGGEMaA5AUA8o//PvMSOjyTi1bQ9QcvIYgoS2sWVKjn
 arViX4i3ZgTNDxcXyeE2oYNrrQ4OOQjKuAlyIkMIXWuVimRTnAvpPKBaj6h8O0iJQAJupDhhZVi
 gfn1gpLrqENeq5nSqNrn853Bt1dU3ui+gH5xKa4vJrMckhl/R00YAXwUVNpzetuWHbvtkUxdMH6
 qlRZxgr05Pzsursh/JK9smWnwW18I4NFfz+kjfiWrcuHgVvdzcLE4M+PKeihWxkgGKgkZSz3QIS
 95/wypwNELvyBbP5zgyJ+h9b7ph7mAc9dzmo+W4+Y/TBk0uKyvZV5a8bW8GGciudPG4kkhjLoRa
 4qEUMZAiPyWKWMSFmoLTpyY3U2RjvxJjKbNy5+cJSZmyyPBxtTbeu7BKE7qwq5CJ3Y0ziSYB1nR
 Nt7QWQk4zLEhCtA==
X-Developer-Key: i=rsworktech@outlook.com; a=openpgp;
 fpr=17AADD6726DDC58B8EE5881757670CCFA42CCF0A
X-Endpoint-Received: by B4 Relay for rsworktech@outlook.com/not_default with auth_id=390
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The last command is not indented thus does not show as code block when
rendered. This patch fixes it.

Fixes: 4ac0b122ee63 ("docs: networking: convert tproxy.txt to ReST")
Signed-off-by: Levi Zim <rsworktech@outlook.com>
---
Changes in v2:
- Add double colons to the end of paragraph before the code block
- Link to v1: https://lore.kernel.org/r/20250427-tproxy-docs-fix-v1-1-988e94844ccb@outlook.com
---
 Documentation/networking/tproxy.rst | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/Documentation/networking/tproxy.rst b/Documentation/networking/tproxy.rst
index 7f7c1ff6f159ed98d96c63d99c98ddbaefd47124..72ba41a10bb22b1f1054af55702423fa8086d98d 100644
--- a/Documentation/networking/tproxy.rst
+++ b/Documentation/networking/tproxy.rst
@@ -69,9 +69,9 @@ add rules like this to the iptables ruleset above::
     # iptables -t mangle -A PREROUTING -p tcp --dport 80 -j TPROXY \
       --tproxy-mark 0x1/0x1 --on-port 50080
 
-Or the following rule to nft:
+Or the following rule to nft:::
 
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

