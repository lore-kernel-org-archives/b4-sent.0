From: Xiubo Li <xiubo.li@clyso.com>
Date: Fri, 09 Oct 2026 04:04:00 +0200
Subject: [PATCH] MAINTAINERS: update ceph and libceph maintainers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261009-ceph-maintainers-v1-1-298e8158087f@clyso.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqAIBCF4avErBNUKKSrRAuzqSbIxKkIwrtnt
 XiLb/H+GxgjIUNT3BDxJKbNZ6iyADdbP6GgIRu01LWS0giHYRarJb/nYWQhK9OPSptB6RryLUQ
 c6fqSbfebj35Bt78dSOkBI2QHznQAAAA=
X-Change-ID: 20261008-ceph-maintainers-058bf128d126
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791511445; l=1286;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=UNHZxFLoDthSpbH7ZtQYJv77/Hv0b2jZ2TirzHOPBc4=;
 b=QItQR9Lu3CFJWk2CGX4actviVoxo5VQjgYAWKc5drEJez8n+/QyNlhEDzn3mcqaHhIo4uVkQ3
 VcPm/enaM/6DKguDSCpO+HWo0rugOq393x5dbVNdmFs4BO/7+fAhKT1
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add myself as a maintainer for the CephFS kernel client and the
libceph common code, and move Viacheslav Dubeyko from maintainer to
reviewer for both.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 MAINTAINERS | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index c8d4b913f26c..d197c6928b08 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -5892,7 +5892,8 @@ F:	drivers/power/supply/cw2015_battery.c
 CEPH COMMON CODE (LIBCEPH)
 M:	Ilya Dryomov <idryomov@gmail.com>
 M:	Alex Markuze <amarkuze@redhat.com>
-M:	Viacheslav Dubeyko <slava@dubeyko.com>
+M:	Xiubo Li <xiubo.li@clyso.com>
+R:	Viacheslav Dubeyko <slava@dubeyko.com>
 L:	ceph-devel@vger.kernel.org
 S:	Supported
 W:	http://ceph.com/
@@ -5905,7 +5906,8 @@ F:	net/ceph/
 CEPH DISTRIBUTED FILE SYSTEM CLIENT (CEPH)
 M:	Ilya Dryomov <idryomov@gmail.com>
 M:	Alex Markuze <amarkuze@redhat.com>
-M:	Viacheslav Dubeyko <slava@dubeyko.com>
+M:	Xiubo Li <xiubo.li@clyso.com>
+R:	Viacheslav Dubeyko <slava@dubeyko.com>
 L:	ceph-devel@vger.kernel.org
 S:	Supported
 W:	http://ceph.com/

---
base-commit: b5650e70565c380d52c36f6bd0e1a4b1bdb385cd
change-id: 20261008-ceph-maintainers-058bf128d126

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

