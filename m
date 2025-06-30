From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Mon, 30 Jun 2025 11:23:53 -0500
Subject: [PATCH RESEND net-next v3] Fixed typo in netdevsim documentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250630-netdevsim-typo-fix-v3-1-e1eae3a5f018@linux.ibm.com>
To: Jiri Pirko <jiri@resnulli.us>, "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: netdev@vger.kernel.org, linux-doc@vger.kernel.org, 
 Breno Leitao <leitao@debian.org>, Joe Damato <joe@dama.to>, 
 Dave Marquardt <davemarq@linux.ibm.com>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751300637; l=1398;
 i=davemarq@linux.ibm.com; s=20250630; h=from:subject:message-id;
 bh=MEqm3SmnFyL3ZtTfgUhX+syORhLhO4nWf1g250ldrQk=;
 b=sKFlgQ61hUnJi37MriXk8na7tgyFykkCypzTtPzeAojpPug9LzA2wBcvywGsx7BZFOOCeNGPd
 hPcC1lX1+5zC0EbJtNACbjKigx5rypxjNDXOR0vA/bOdcZlGcm/7cz5
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=eCwwhqOykPrqNNTH1uSGAhXUfNQI0Zlz7hb8uGTjPVU=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20250630 with auth_id=447
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fixed a typographical error in "Rate objects" section

Reviewed-by: Joe Damato <joe@dama.to>
Reviewed-by: Breno Leitao <leitao@debian.org>
Signed-off-by: Dave Marquardt <davemarq@linux.ibm.com>
---
Fixed a typographical error in "Rate objects" section
---
Changes in v3:
- Retargeted from net to net-next
- Included Reviewed-by headers

Changes in v2:
- Targeted patch to net
---
 Documentation/networking/devlink/netdevsim.rst | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Documentation/networking/devlink/netdevsim.rst b/Documentation/networking/devlink/netdevsim.rst
index 88482725422c..3932004eae82 100644
--- a/Documentation/networking/devlink/netdevsim.rst
+++ b/Documentation/networking/devlink/netdevsim.rst
@@ -62,7 +62,7 @@ Rate objects
 
 The ``netdevsim`` driver supports rate objects management, which includes:
 
-- registerging/unregistering leaf rate objects per VF devlink port;
+- registering/unregistering leaf rate objects per VF devlink port;
 - creation/deletion node rate objects;
 - setting tx_share and tx_max rate values for any rate object type;
 - setting parent node for any rate object type.

---
base-commit: 8909f5f4ecd551c2299b28e05254b77424c8c7dc
change-id: 20250616-netdevsim-typo-fix-6e5e3113f49b

Best regards,
--
Dave Marquardt <davemarq@linux.ibm.com>
-- 
Dave Marquardt <davemarq@linux.ibm.com>

