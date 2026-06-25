From: Torben Hohn <torben.hohn@bruker.com>
Date: Thu, 25 Jun 2026 17:59:35 +0200
Subject: [PATCH] systemd-systemctl: Add support for UpheldBy fields in
 [Install] section
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260625-systemctl-upheldby-v1-1-b66839cab56b@bruker.com>
X-B4-Tracking: v=1; b=H4sIAGZQPWoC/x3MTQ5AMBBA4avIrDWpkZa4iljQDibxlw5CxN01l
 t/ivQeEApNAlTwQ6GThdYnI0gTc2C4DKfbRgBqttmiU3LLT7PZJHdtIk+9uVeYGrdWFMx4hhlu
 gnq9/Wjfv+wEYVohFZAAAAA==
X-Change-ID: 20260625-systemctl-upheldby-83526607c5d2
To: openembedded-core@lists.openembedded.org
Cc: Torben Hohn <torben.hohn@bruker.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782403180; l=1384;
 i=torben.hohn@bruker.com; s=20260625; h=from:subject:message-id;
 bh=R/nG2OjNBzK8ShZkAJStRPF6gEyt5fnMN84RqMWP2Ds=;
 b=8pxrFeDS5KefhApTleR0xJEZossjha9uGBY/5QfzMJoTSOQ/kWCAFMTxeJBnx5LOZsZqbflVR
 d36MEVaL4XNCPjHy8LoREDISJFBoyMSa4jpNzISNkZYLMIgDi75HEE3
X-Developer-Key: i=torben.hohn@bruker.com; a=ed25519;
 pk=xwQUIFyS0KMR/PWxOIZJmY0wxZLSQusEDFjPRjZWdhE=
X-Endpoint-Received: by B4 Relay for torben.hohn@bruker.com/20260625 with auth_id=842
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

UpheldBy generates *.upholds links in the same way WantedBy generates
*.wants links, when systemctl enable is executed. This feature is needed
to have a service restart, when a dependency restarts, and
the service is stopped via BindsTo= for example.

Call self._process_deps() with appropriate parameters to support UpheldBy.

Signed-off-by: Torben Hohn <torben.hohn@bruker.com>
---
 meta/recipes-core/systemd/systemd-systemctl/systemctl | 1 +
 1 file changed, 1 insertion(+)

diff --git a/meta/recipes-core/systemd/systemd-systemctl/systemctl b/meta/recipes-core/systemd/systemd-systemctl/systemctl
index 2229bc7b6d26c757414715341ff79d8a76034c8d..0171d2fca639ed452af9295c6a3cfd3c7102f67c 100755
--- a/meta/recipes-core/systemd/systemd-systemctl/systemctl
+++ b/meta/recipes-core/systemd/systemd-systemctl/systemctl
@@ -244,6 +244,7 @@ class SystemdUnit():
 
         self._process_deps(config, service, path, 'WantedBy', 'wants', instance)
         self._process_deps(config, service, path, 'RequiredBy', 'requires', instance)
+        self._process_deps(config, service, path, 'UpheldBy', 'upholds', instance)
 
         try:
             for also in config.get('Install', 'Also'):

---
base-commit: 78626a6f1861361bbd78a411cb27b093e34b466b
change-id: 20260625-systemctl-upheldby-83526607c5d2

Best regards,
-- 
Torben Hohn <torben.hohn@bruker.com>

