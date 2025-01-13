From: Joel Granados <joel.granados@kernel.org>
Date: Mon, 13 Jan 2025 12:53:09 +0100
Subject: [PATCH RESEND 11/12] scripts: Return the full default path of the
 pool path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250113-jag-bringup_fixes-v1-11-fb28030b1f26@kernel.org>
References: <20250113-jag-bringup_fixes-v1-0-fb28030b1f26@kernel.org>
In-Reply-To: <20250113-jag-bringup_fixes-v1-0-fb28030b1f26@kernel.org>
To: kdevops@lists.linux.dev
Cc: Joel Granados <joel.granados@kernel.org>, mcgrof@kernel.org, 
 da.gomez@samsung.com
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=618;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=Kv/ycEEjWStHBxJuRHp2jefllpU4iYXDCmq1ZbHsqLs=;
 b=kA0DAAoBupfNUreWQU8ByyZiAGeE/qihjTAk+t4sfpUIDKRspIW+2P/vcvk64I4+wMMVgMihs
 YkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnhP6oAAoJELqXzVK3lkFPBkUL/iQ7
 29G+y0NWZtSazP+onjmYbre4TAvOP7k8H3SthkNre8mq32inh72bk3d49yBF2q2CPmF26RgG6yU
 zAKW1ygddXSYcUTPzYtIMyo5aNYRt5DK6x4iOFffMXzbqSCpLmJ8J5arSjHcLUrh1aujtvVVXvC
 tSVYmMj/4PrHZIH0LNPmb3ytSQ8FnV0GCg9ZdSh1ODp5ijO9IidZxktczRH8s0RGbGUBi9Siq1h
 Y8ozvxbrgaLWHZePxDpRbMKk5gEVuI+EEFgGZhOXORgvD9Xiuzd1a3Gaag2wRnnCgfycL/seYY9
 yvKDk9vt1P5zhtnOtiUXYtNMQXYZhla7VjRgi6hhSyQiSolzk0KqrBlCOiGjRsRj81JrOyC3E0O
 0G900liW9dn6UR5LhoM86nCgoKslPxz0og/WkTTg+DKRNefxTDgdK/urh6KJh1lE/w0BZouqjCG
 NSX/NXRxHi4Mh5ket712I74IwWzEUKAhYMx3/8Z/kD6YZrZH3/YuBXweGKvQ==
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Avoid "file not found" failures related to relative paths in pool paths.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 scripts/get_libvirsh_pool_path.sh | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/scripts/get_libvirsh_pool_path.sh b/scripts/get_libvirsh_pool_path.sh
index 92901a8..c036777 100755
--- a/scripts/get_libvirsh_pool_path.sh
+++ b/scripts/get_libvirsh_pool_path.sh
@@ -17,7 +17,7 @@ POOL_LIST=""
 get_pool_vars
 VIRSH_WORKS=$(virsh_works)
 if [[ "$VIRSH_WORKS" == "n" ]]; then
-	echo "default"
+	echo "$(pwd)/default"
 	exit
 fi
 

-- 
2.44.2

