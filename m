From: Taylor Jackson <tjackson9431@gmail.com>
Date: Wed, 17 Apr 2024 19:34:24 +0000
Subject: [PATCH] generic/645: Add hint for expected failure with old kernel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240417-generic-test-645-v1-1-7f6f496af06a@gmail.com>
X-B4-Tracking: v=1; b=H4sIAD8kIGYC/x3MQQqAIBBA0avErBvQSTO6SrQInWo2FioRRHdPW
 v7F+w9kTsIZxuaBxJdkOWIN3Tbg9yVujBJqAykyymiHG8cqPBbOBXtjUQ/OqqDIUsdQ2Zl4lft
 fTvP7fk25UwViAAAA
To: fstests@vger.kernel.org
Cc: Christian Brauner <brauner@kernel.org>, 
 Seth Forshee <sforshee@kernel.org>, Taylor Jackson <tjackson9431@gmail.com>, 
 Zorro Lang <zlang@redhat.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713382506; l=1100;
 i=tjackson9431@gmail.com; s=20240206; h=from:subject:message-id;
 bh=rNdH0c61gNgISeRXRPFYYO+c6i1S4rlqeXA+MtehszM=;
 b=aOMZYB6wtyZDA5Pkb6xeHV4orfPQemndp/bMkenvJMErmglLVYwOtRfDdlhuPNb3lFSPCbOJa
 jk/2M4JmcUuCMRCLjh1mOTqFYryxqxabBEmod/rvpoWKYTaM3FEyvgP
X-Developer-Key: i=tjackson9431@gmail.com; a=ed25519;
 pk=NO7ntQpjIG1IGTO7F8OnLJDKSHUakhrhAli+PL72OLA=
X-Endpoint-Received: by B4 Relay for tjackson9431@gmail.com/20240206 with auth_id=145
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The following hint is added to reflect that any old kernel
without kernel commit dacfd001eaf2 (“fs/mnt_idmapping.c: Return
-EINVAL when no map is written”) is expected to fail this generic
645 test since without that commit, mount_setattr won’t return
EINVAL when attempting to create an idmapped mount using a user
namespace with no mappings.

Reported-by: Zorro Lang <zlang@redhat.com>
Signed-off-by: Taylor Jackson <tjackson9431@gmail.com>
---
 tests/generic/645 | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/tests/generic/645 b/tests/generic/645
index 556d2450..bcc3e3b5 100755
--- a/tests/generic/645
+++ b/tests/generic/645
@@ -17,6 +17,8 @@ _begin_fstest auto quick idmapped mount
 _supported_fs generic
 _require_idmapped_mounts
 _require_test
+_fixed_by_kernel_commit dacfd001eaf2 \
+	"fs/mnt_idmapping.c: Return -EINVAL when no map is written"
 
 echo "Silence is golden"
 

---
base-commit: e72e052d56c3f05e533f4b67056f86931f688368
change-id: 20240417-generic-test-645-18750d02523e

Best regards,
-- 
Taylor Jackson <tjackson9431@gmail.com>

