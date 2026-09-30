From: Bernd Schubert <bernd@bsbernd.com>
Date: Wed, 30 Sep 2026 15:10:59 +0200
Subject: [PATCH v3 05/15] util: give fuservicemount3 an absolute build-tree
 runpath
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-mount-service-bound-open-v3-5-e26c5e4eca4c@bsbernd.com>
References: <20260930-mount-service-bound-open-v3-0-e26c5e4eca4c@bsbernd.com>
In-Reply-To: <20260930-mount-service-bound-open-v3-0-e26c5e4eca4c@bsbernd.com>
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, neal@gompa.dev, 
 Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=1124; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=cHv54HitSu2anlu/930tbqWeXtXeZVKdqR+lf4lHv5k=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLL2cmXfreZeeTbuHm9QY20J+xvJIBcvY5F25fofJTppy
 078eba2o5SFQYyDQVZMkaVLYo/tlH98smpf11+HmcPKBDKEgYtTACbSNZXhf1o6Q9Oc9Xsjtz9s
 kd4swDxNcPEp0zXx/j7mFVH9VhW7FRn+x8xces6r+IZPxG6uZ+vzw7qC783RXadmP29xzBJzrZe
 +fAA=
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The dynamic loader ignores $ORIGIN runpaths and LD_LIBRARY_PATH for a
setuid program. A build-tree fuservicemount3 made setuid, for example by
"run-tests.py --setuid-helpers", then failed with "libfuse3.so.4: cannot
open shared object file", or loaded the libfuse3.so.4 of the system.
meson removes build_rpath on install, so installed binaries do not change.

Assisted-by: LLM
Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
Reviewed-by: "Darrick J. Wong" <djwong@kernel.org>
---
 util/meson.build | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/util/meson.build b/util/meson.build
index 28052a65536f..bc266776e153 100644
--- a/util/meson.build
+++ b/util/meson.build
@@ -22,6 +22,8 @@ if private_cfg.get('HAVE_SERVICEMOUNT', false)
              link_with: [ libfuse ],
              install: true,
              install_dir: get_option('sbindir'),
+             # A setuid run ignores the $ORIGIN runpath meson sets
+             build_rpath: join_paths(meson.project_build_root(), 'lib'),
              c_args: ['-DFUSE_USE_VERSION=319'] + mount_service_cflags)
 endif
 

-- 
2.53.0

