From: Bernd Schubert <bernd@bsbernd.com>
Date: Mon, 28 Sep 2026 13:02:15 +0200
Subject: [PATCH v2 13/14] build: move the default service socket directory
 to /run/fuse
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260928-mount-service-bound-open-v2-13-0f9f501d05ce@bsbernd.com>
References: <20260928-mount-service-bound-open-v2-0-0f9f501d05ce@bsbernd.com>
In-Reply-To: <20260928-mount-service-bound-open-v2-0-0f9f501d05ce@bsbernd.com>
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, neal@gompa.dev, 
 Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=1585; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=tQryJefQwU31BGF36lLS3Yeu+12nkeqk6UvLI4AI88I=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLJ2eTofFN1TICztH76X3X4P063EHMPLVl/mWilNY3afk
 hSw09ino5SFQYyDQVZMkaVLYo/tlH98smpf11+HmcPKBDKEgYtTACYy/SAjw0EProKnKjp6dcz3
 5LeJi31wKedZc0/q7AMjrRbj3+06RxgZbsp8cDl4Mb206l/MUvlbr5fe7NuhuJFT9nGfVNBn37p
 lDAA=
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

/run/fuse sounds better for fuse and then it is also shorter
a few bytes and might reduce 108-byte AF_UNIX path issues, compared
to /run/filesystems.

Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 meson.build       | 2 +-
 meson_options.txt | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)

diff --git a/meson.build b/meson.build
index 06e6056ecf21..5e9628b521e7 100644
--- a/meson.build
+++ b/meson.build
@@ -72,7 +72,7 @@ private_cfg.set_quoted('PACKAGE_VERSION', meson.project_version())
 service_socket_dir = get_option('service-socket-dir')
 service_socket_perms = get_option('service-socket-perms')
 if service_socket_dir == ''
-  service_socket_dir = '/run/filesystems'
+  service_socket_dir = '/run/fuse'
 endif
 if service_socket_perms == ''
   service_socket_perms = '0220'
diff --git a/meson_options.txt b/meson_options.txt
index 43104290f8b5..e12177fcea30 100644
--- a/meson_options.txt
+++ b/meson_options.txt
@@ -35,7 +35,7 @@ option('sync-init', type: 'combo', choices: ['auto', 'always', 'never'], value:
        description: 'Synchronous FUSE_INIT: auto follows fuse_daemonize_early_start(), always and never override it')
 
 option('service-socket-dir', type : 'string', value : '',
-       description: 'Where to install fuse server sockets (if empty, /run/filesystems)')
+       description: 'Where to install fuse server sockets (if empty, /run/fuse)')
 
 option('service-socket-perms', type : 'string', value : '',
        description: 'Default fuse server socket permissions (if empty, 0220)')

-- 
2.53.0

