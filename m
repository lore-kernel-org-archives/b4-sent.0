From: Patrick Vogelaar <patrick.vogelaar@belden.com>
Date: Wed, 12 Aug 2026 12:33:45 +0200
Subject: [PATCH wrynose] volatile-binds: order systemd-timesyncd after
 /var/lib
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260812-backport_timesyncd-v1-1-c1fa5bc8e5c9@belden.com>
X-B4-Tracking: v=1; b=H4sIAAhMfGoC/yWMXQrCMBAGr1L22UAbsESvIiJp8lVXMSm78aeU3
 t2oj8Mws5BCGEr7ZiHBk5VzqtBtGgoXn84wHCuTbW3fus6awYfblKWcCt+hcwrR+N3Wux5uRAT
 VcBKM/P5ND/SSOWUFHf9CH8MVoXyXtK4fskh15X8AAAA=
X-Change-ID: 20260812-backport_timesyncd-a95a86e8fede
To: openembedded-core@lists.openembedded.org
Cc: esa.jaaskela@suomi24.fi, 
 Richard Purdie <richard.purdie@linuxfoundation.org>, 
 Patrick Vogelaar <patrick.vogelaar@belden.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786530838; l=1917;
 i=patrick.vogelaar@belden.com; s=20240201; h=from:subject:message-id;
 bh=6FOhyJqR2CFPF1BF78T38KQBpWYothYXTgr6AIq1q70=;
 b=9SdjAIgEFuFmK44nypfC1yD8R4c1v+t5U3O6CQ9wfokB4k7NA3fVNGl4QIFiu4fS0GuQ6r/zn
 QKTd6jcNX6LBpT+P9OC3TOORY4P8vDEcvvnASYWsgvshAapbu4rAa+1
X-Developer-Key: i=patrick.vogelaar@belden.com; a=ed25519;
 pk=w0QU8RmOR3hQv1DxMcz6KmySeE8yqbvO0xC1ZSSUNqY=
X-Endpoint-Received: by B4 Relay for patrick.vogelaar@belden.com/20240201 with auth_id=125
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Esa Jaaskela <esa.jaaskela@suomi24.fi>

systemd-timesyncd stores its clock file under /var/lib/systemd/timesync,
so it can fail to save state if it starts before the volatile /var/lib
is mounted. Add it to the Before= and WantedBy= entries already used for
systemd-random-seed.service.

(cherry picked from commit 1b8d8c25e46f1df7079545f4297496426fd9d371)

Signed-off-by: Esa Jaaskela <esa.jaaskela@suomi24.fi>
Signed-off-by: Richard Purdie <richard.purdie@linuxfoundation.org>
Signed-off-by: Patrick Vogelaar <patrick.vogelaar@belden.com>
---
 meta/recipes-core/volatile-binds/volatile-binds.bb | 9 +++++----
 1 file changed, 5 insertions(+), 4 deletions(-)

diff --git a/meta/recipes-core/volatile-binds/volatile-binds.bb b/meta/recipes-core/volatile-binds/volatile-binds.bb
index 857bcc93ff..613e750c17 100644
--- a/meta/recipes-core/volatile-binds/volatile-binds.bb
+++ b/meta/recipes-core/volatile-binds/volatile-binds.bb
@@ -57,10 +57,11 @@ ${@d.getVar('VOLATILE_BINDS').replace("\\n", "\n")}
 END
 
     if [ -e "$var_lib_servicefile" ]; then
-        # As the seed is stored under /var/lib, ensure that this service runs
-        # after the volatile /var/lib is mounted.
-        sed -i -e "/^Before=/s/\$/ systemd-random-seed.service/" \
-               -e "/^WantedBy=/s/\$/ systemd-random-seed.service/" \
+        # The random seed and the timesyncd clock file are stored under
+        # /var/lib, so ensure that those services run after the volatile
+        # /var/lib is mounted.
+        sed -i -e "/^Before=/s/\$/ systemd-random-seed.service systemd-timesyncd.service/" \
+               -e "/^WantedBy=/s/\$/ systemd-random-seed.service systemd-timesyncd.service/" \
                "$var_lib_servicefile"
     fi
 }

---
base-commit: f09a0f28aeb54ddd90415dd458338e1565bb5a49
change-id: 20260812-backport_timesyncd-a95a86e8fede

Best regards,
--  
Patrick Vogelaar <patrick.vogelaar@belden.com>

