From: Dominique Martinet <asmadeus@codewreck.org>
Date: Fri, 26 Sep 2025 18:27:30 +0900
Subject: [PATCH 2/3] 9p: fix /sys/fs/9p/caches overwriting itself
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250926-v9fs_misc-v1-2-a8b3907fc04d@codewreck.org>
References: <20250926-v9fs_misc-v1-0-a8b3907fc04d@codewreck.org>
In-Reply-To: <20250926-v9fs_misc-v1-0-a8b3907fc04d@codewreck.org>
To: "Randall P. Embry" <rpembry@gmail.com>, 
 Eric Van Hensbergen <ericvh@kernel.org>, 
 Latchesar Ionkov <lucho@ionkov.net>, 
 Christian Schoenebeck <linux_oss@crudebyte.com>
Cc: v9fs@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Dominique Martinet <asmadeus@codewreck.org>
X-Mailer: b4 0.15-dev-7be4f
X-Developer-Signature: v=1; a=openpgp-sha256; l=911; i=asmadeus@codewreck.org;
 h=from:subject:message-id; bh=sblDE7el9v90HXEfOfwFbTsacdQEvKtucuy7CFjReRU=;
 b=owEBbQKS/ZANAwAKAatOm+xqmOZwAcsmYgBo1lyJ06819UxMXPHdVaEM7RHAphy86FM+fibHn
 WmW1B0P+cCJAjMEAAEKAB0WIQT8g9txgG5a3TOhiE6rTpvsapjmcAUCaNZciQAKCRCrTpvsapjm
 cJxmD/0ZYZEPA8otf0o8CjXDON/3oJm+5fldLBC9ZoOpLVZVgcjTnY4dYbBGWN4rT3qHNZNGIw1
 QozJvZPjFfk5FkVQLMBk5rkpNUcITFRM1nyHmj+iz+lzbEoDYuRwo0orzc3bPjW7JhZNALm4Z7g
 fri6mnRrJtC43hH6ejE+wvi+T/gC+mtHTYfIcIl1FAOSaVapI50zzv/jvjdIy2AhhWc02g+fWJ7
 FNt6RysLKlryCgBW13Z5q6FmRaXhVTBsg3NuUtBKwmn2D1eOeVQgjXVuKvalpcH6//Up20ZodlQ
 Qq7l3+UYJXPTmwlUTbhTxKZmer+bF92lSp2V/nu1WWqDNz0VghWFGYWy7TQfh+s29QblER4dvZZ
 +8D05pNzOioTs8xoreljgBACHd7hk6GlOhpsASEIgkyFVRr+c2F3pvRjg8O8qW5kKEg4DIOM6Dg
 BBLTbUKmud+Wqb7+b4BEV+JEbhCJIp+A6mbCda/zaCmVPfTZ80iXwvLfPs/knDoNTZzveov0ly8
 yqVKV/NFc79jcoBn6K6236pQT0OsGlAw6o6psarrCiBWFJ/uinlwsfjfM71VQ76M5mvZsdbxNl6
 nBuZmht1HHM7g5yoHhbOFI7gQOGY7CBVaHzrywNXOOkycKKWOj/2GunNrqe8lh++eig1jVMgI3t
 fGoqf4mQ5SWT0cA==
X-Developer-Key: i=asmadeus@codewreck.org; a=openpgp;
 fpr=B894379F662089525B3FB1B9333F1F391BBBB00A
X-Endpoint-Received: by B4 Relay for asmadeus@codewreck.org/default with auth_id=435
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: "Randall P. Embry" <rpembry@gmail.com>

caches_show() overwrote its buffer on each iteration,
so only the last cache tag was visible in sysfs output.

Properly append with snprintf(buf + count, …).

Signed-off-by: Randall P. Embry <rpembry@gmail.com>
Signed-off-by: Dominique Martinet <asmadeus@codewreck.org>
---
 fs/9p/v9fs.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/fs/9p/v9fs.c b/fs/9p/v9fs.c
index 01e70a464b6039231df272e43b4ebdd3b5afb967..4d289c56578fb15e45d8e94a264977898973cb31 100644
--- a/fs/9p/v9fs.c
+++ b/fs/9p/v9fs.c
@@ -560,7 +560,7 @@ static ssize_t caches_show(struct kobject *kobj,
 	spin_lock(&v9fs_sessionlist_lock);
 	list_for_each_entry(v9ses, &v9fs_sessionlist, slist) {
 		if (v9ses->cachetag) {
-			n = snprintf(buf, limit, "%s\n", v9ses->cachetag);
+			n = snprintf(buf + count, limit, "%s\n", v9ses->cachetag);
 			if (n < 0) {
 				count = n;
 				break;

-- 
2.51.0

