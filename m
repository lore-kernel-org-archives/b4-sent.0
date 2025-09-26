From: Dominique Martinet <asmadeus@codewreck.org>
Date: Fri, 26 Sep 2025 18:27:31 +0900
Subject: [PATCH 3/3] 9p: sysfs_init: don't hardcode error to ENOMEM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250926-v9fs_misc-v1-3-a8b3907fc04d@codewreck.org>
References: <20250926-v9fs_misc-v1-0-a8b3907fc04d@codewreck.org>
In-Reply-To: <20250926-v9fs_misc-v1-0-a8b3907fc04d@codewreck.org>
To: "Randall P. Embry" <rpembry@gmail.com>, 
 Eric Van Hensbergen <ericvh@kernel.org>, 
 Latchesar Ionkov <lucho@ionkov.net>, 
 Christian Schoenebeck <linux_oss@crudebyte.com>
Cc: v9fs@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Dominique Martinet <asmadeus@codewreck.org>
X-Mailer: b4 0.15-dev-7be4f
X-Developer-Signature: v=1; a=openpgp-sha256; l=957; i=asmadeus@codewreck.org;
 h=from:subject:message-id; bh=gn+Wu50PLn45xmVoChT1EsToJxDhrtvpZbSqmSUmcd8=;
 b=owEBbQKS/ZANAwAKAatOm+xqmOZwAcsmYgBo1lyKQwca23NbZ83VZF2cYauPoOy1Y4BjyFq26
 TzZCllr0DmJAjMEAAEKAB0WIQT8g9txgG5a3TOhiE6rTpvsapjmcAUCaNZcigAKCRCrTpvsapjm
 cDCkD/4q0ZBLaufKQhUuJnfMggUKocITlkvpCcrgSyBv60WkuSkHGAJ0mZ1tOTfXe07pV88nS02
 8oEb5W9IcQY1MUZkWVU3qET4xr4hYR0zWI62PrcewGaJgu5AT6HffWTsZyQPG0L00wI8W+0Qy2U
 J4eM1fX25aZj4BctIH6gtT/XVqY15A81A1tpGwtUKjw2MGiElF5kscHJYl6Ig7t42Obm0Qx1qer
 yy3J3ePk+1HlWiKxhHFH+3dXFh75ozwaTD3g9b6T8FIuJ2Sv3PdOavngMDn0DpbsfOJoZWOy9R0
 XAdy8Vy7EUjc7tok1kcQCCCN3TXzNvo4Mt4XaebtcrzU4eZJa+fX1uxcfFshOJClMu5Wr02Xmid
 zyKk60N78If1UP+xbWsh0Pf9aj2hahEVSfL5KfmB5kRd52hpNvR3kHp2jzrmo/24ssLkl9vnive
 3slrOeriFa9PbCDZxkWEMXcV19K1sc7qslTbg25F/+BxYNwxHglWvPEqzlSjYZs6OyKcnOvWwqM
 0gJWgHmBsx8qXnA6f16TLHPoKFXuCuyqdhA3lMJ5hpUkBr5Jqma/OZZ6vX1Rtx3CjjrSAxfNCPP
 HhMWv52p4sZQplWLZXvkjCeucFs+w8+hJ9l2z6j6sUBVPUaD3aVdzvE0yIv5G/LoV3ovLTmDDD9
 aYl8d1MiJ8g5VEw==
X-Developer-Key: i=asmadeus@codewreck.org; a=openpgp;
 fpr=B894379F662089525B3FB1B9333F1F391BBBB00A
X-Endpoint-Received: by B4 Relay for asmadeus@codewreck.org/default with auth_id=435
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: "Randall P. Embry" <rpembry@gmail.com>

v9fs_sysfs_init() always returned -ENOMEM on failure;
return the actual sysfs_create_group() error instead.

Signed-off-by: Randall P. Embry <rpembry@gmail.com>
Signed-off-by: Dominique Martinet <asmadeus@codewreck.org>
---
 fs/9p/v9fs.c | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/fs/9p/v9fs.c b/fs/9p/v9fs.c
index 4d289c56578fb15e45d8e94a264977898973cb31..a020a8f00a1ac074e826a728c5a2b1ef09ec87fd 100644
--- a/fs/9p/v9fs.c
+++ b/fs/9p/v9fs.c
@@ -596,13 +596,16 @@ static const struct attribute_group v9fs_attr_group = {
 
 static int __init v9fs_sysfs_init(void)
 {
+	int ret;
+
 	v9fs_kobj = kobject_create_and_add("9p", fs_kobj);
 	if (!v9fs_kobj)
 		return -ENOMEM;
 
-	if (sysfs_create_group(v9fs_kobj, &v9fs_attr_group)) {
+	ret = sysfs_create_group(v9fs_kobj, &v9fs_attr_group);
+	if (ret) {
 		kobject_put(v9fs_kobj);
-		return -ENOMEM;
+		return ret;
 	}
 
 	return 0;

-- 
2.51.0

