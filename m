From: Bernd Schubert <bernd@bsbernd.com>
Date: Wed, 30 Sep 2026 15:11:07 +0200
Subject: [PATCH v3 13/15] build: move the default service socket directory
 to /run/fuse
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-mount-service-bound-open-v3-13-e26c5e4eca4c@bsbernd.com>
References: <20260930-mount-service-bound-open-v3-0-e26c5e4eca4c@bsbernd.com>
In-Reply-To: <20260930-mount-service-bound-open-v3-0-e26c5e4eca4c@bsbernd.com>
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, neal@gompa.dev, 
 Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=1585; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=/fLLZKFK2/8mQY9ouzzqLpP8wdTcB+LhDagp3DmmdeQ=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLL2cuVpbdrtH3bZl4c//f0N3lDvYr7IU6x864KWfrxdw
 F1ZePF4RykLgxgHg6yYIkuXxB7bKf/4ZNW+rr8OM4eVCWQIAxenAExEX43hn7H+/zUBuXOnn4q4
 t6hE5ulrgXe+L/i3fJf8wnXrt0M10wtGhh93mi/3SZdcES8o/3Mw+KR1WNNOpeYIgbu5mx+/OJA
 izgoA
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
index c22cc2c1dbf4..eb365ff66552 100644
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

