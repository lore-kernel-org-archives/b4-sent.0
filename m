From: Louis Rannou <louis.rannou@non.se.com>
Date: Thu, 03 Jul 2025 14:14:36 +0200
Subject: [PATCH] openssh: limit read access to sshd_config
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250703-sshd_perm-v1-1-f92e5fbb18c7@non.se.com>
X-B4-Tracking: v=1; b=H4sIACt0ZmgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDcwNj3eLijJT4gtSiXF0z42QLEwPzNEszozQloPqCotS0zAqwWdGxtbU
 ATVsoOFsAAAA=
To: openembedded-core@lists.openembedded.org
Cc: pascal.eberhard@se.com, Louis Rannou <louis.rannou@non.se.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751544878; l=1954;
 i=louis.rannou@non.se.com; s=20250630; h=from:subject:message-id;
 bh=MWC55oMq0pjTiIOMWdI0f51vNbs/kU196thLmSduxzk=;
 b=moAZvwR50+72UCDA3DbXm/eCJbbdO4jxGYDNA29Ok6ql7i0mHM4a/9xvWktnwhbQWcwc6t1zO
 9kKSvR6Ls03CCCr8vwVKcLrKzKZWL9Ev167Xmkaah2FxNP8n0r9+J+0
X-Developer-Key: i=louis.rannou@non.se.com; a=ed25519;
 pk=WWYN5/DFKqyCKdv6oTYNuq0gROqwZVfNfw2OMI3tUlc=
X-Endpoint-Received: by B4 Relay for louis.rannou@non.se.com/20250630 with auth_id=446
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enhance security by limiting read access for /etc/sshd_config to user root as it
may reveal unsecure configurations.

Reading access is limited in the install append as the default value 0644 is
hardcoded in the openssh makefile and is not configurable. Therefore the
permissions are modified in the install append.

Signed-off-by: Louis Rannou <louis.rannou@non.se.com>
---
 meta/recipes-connectivity/openssh/openssh_10.0p1.bb | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/meta/recipes-connectivity/openssh/openssh_10.0p1.bb b/meta/recipes-connectivity/openssh/openssh_10.0p1.bb
index a044aec063..2f446b5540 100644
--- a/meta/recipes-connectivity/openssh/openssh_10.0p1.bb
+++ b/meta/recipes-connectivity/openssh/openssh_10.0p1.bb
@@ -102,7 +102,7 @@ CACHED_CONFIGUREVARS += "ac_cv_header_maillock_h=no"
 
 do_configure:prepend () {
 	export LD="${CC}"
-	install -m 0644 ${UNPACKDIR}/sshd_config ${B}/
+	install -m 0600 ${UNPACKDIR}/sshd_config ${B}/
 	install -m 0644 ${UNPACKDIR}/ssh_config ${B}/
 }
 
@@ -153,9 +153,12 @@ do_install:append () {
 	install -m 644 ${UNPACKDIR}/volatiles.99_sshd ${D}/${sysconfdir}/default/volatiles/99_sshd
 	install -m 0755 ${S}/contrib/ssh-copy-id ${D}${bindir}
 
+	# Limit sshd_config access to the owner (default is 0644)
+	chmod 0600 ${D}${sysconfdir}/ssh/sshd_config
+
 	# Create config files for read-only rootfs
 	install -d ${D}${sysconfdir}/ssh
-	install -m 644 ${D}${sysconfdir}/ssh/sshd_config ${D}${sysconfdir}/ssh/sshd_config_readonly
+	install -m 0600 ${D}${sysconfdir}/ssh/sshd_config ${D}${sysconfdir}/ssh/sshd_config_readonly
 
 	install -d ${D}${systemd_system_unitdir}
 	if ${@bb.utils.contains('PACKAGECONFIG','systemd-sshd-socket-mode','true','false',d)}; then

---
base-commit: 77a93e8cf1da4231341c56f64f9d4d474f9f2bb7
change-id: 20250703-sshd_perm-63c8407f962f

Best regards,
-- 
Louis Rannou <louis.rannou@non.se.com>

