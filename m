From: Joel Granados <joel.granados@kernel.org>
Date: Wed, 18 Dec 2024 11:30:05 +0100
Subject: [PATCH 11/12] scripts: Return the full default path of the pool
 path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241218-jag-bringup_fixes-v1-11-0bf2e07c640c@kernel.org>
References: <20241218-jag-bringup_fixes-v1-0-0bf2e07c640c@kernel.org>
In-Reply-To: <20241218-jag-bringup_fixes-v1-0-0bf2e07c640c@kernel.org>
To: kdevops@lists.linux.dev
Cc: Joel Granados <joel.granados@kernel.org>, da.gomez@samsung.com
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=618;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=Kv/ycEEjWStHBxJuRHp2jefllpU4iYXDCmq1ZbHsqLs=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGdipDF8wr0zfKRwI7Ai6EumFq+tcl5KmaZEm
 rSG4u2tOE11hokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnYqQxAAoJELqXzVK3
 lkFP/xEL/j3qisqcUPCiG3GE6uRl38N7m4ZzmhW4DPZec+m+tzvqW5fluncQeC1mPJ3k7PlDgGD
 R/UrtnIqJRxu8lUMqt9QXD/x3wLv9Bpar4ATzGm9kVO/i4hawIKfKVRRCAfM9EwJ8e0mVzobOH3
 G9VUe/Tw47LbZIgWTKvFsugZ8KGhUeezj1aWVcs3er1F/YHkCPLM13+zDQeM9Wh+b+XSPQHB1y4
 tzzVYvtqgwD2jl66b8N8Md7XdZT23Dub7rcXMpvb5FUM7DlEHaEXPOXtfCpekbB06pIv1fU9L8Z
 OyTQDYg931Vs3Hcka+KTvwRvoF7yDS/9XXVGDkaKgxT8MEyvrivdvv8tMrGrxotnKgX19dS9mgj
 PjZ1Ft4422C9Oj4ivWe9JAVzFVRbOfxk3eQZ8J8Q3ucuGdkivm56dJj69dSMxRiGwY2VUqaXA3k
 oF6phCu3vP4JDDt2aIyPgcSb7lg97YTvayMlqjoeruZlWiD16aijXQ3REl84nUJipuvt/Jrvg+8
 f0=
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

