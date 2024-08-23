From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Fri, 23 Aug 2024 23:04:55 +0100
Subject: [PATCH net-next v4 5/8] selftests/net: Don't forget to close nsfd
 after switch_save_ns()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240823-tcp-ao-selftests-upd-6-12-v4-5-05623636fe8c@gmail.com>
References: <20240823-tcp-ao-selftests-upd-6-12-v4-0-05623636fe8c@gmail.com>
In-Reply-To: <20240823-tcp-ao-selftests-upd-6-12-v4-0-05623636fe8c@gmail.com>
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Shuah Khan <shuah@kernel.org>
Cc: Mohammad Nassiri <mnassiri@ciena.com>, netdev@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dmitry Safonov <0x7f454c46@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724450716; l=1650;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=RZZIhByrLVMtPYu4stmuI1j7mLzypnmNTN4/LUHGhUo=;
 b=U+/ETigXsEiFz8RzDyvc84aF6CU8gl01I8dOANx1OCpIcqj5PdHtpKlXzRtzCcn8bxskrGBJ/
 y824EmiKG2VBUtm4o6WjLmLOZdYBF/CSbDbMBHFalxjnPP3yxHSeK8F
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The switch_save_ns() helper suppose to help switching to another
namespace for some action and to return back to original namespace.

The fd should be closed.

Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
 tools/testing/selftests/net/tcp_ao/lib/setup.c | 13 ++++++++++---
 1 file changed, 10 insertions(+), 3 deletions(-)

diff --git a/tools/testing/selftests/net/tcp_ao/lib/setup.c b/tools/testing/selftests/net/tcp_ao/lib/setup.c
index d5212ffe9489..86a4f6e20450 100644
--- a/tools/testing/selftests/net/tcp_ao/lib/setup.c
+++ b/tools/testing/selftests/net/tcp_ao/lib/setup.c
@@ -142,6 +142,13 @@ int switch_save_ns(int new_ns)
 	return ret;
 }
 
+void switch_close_ns(int fd)
+{
+	if (setns(fd, CLONE_NEWNET))
+		test_error("setns()");
+	close(fd);
+}
+
 static int nsfd_outside	= -1;
 static int nsfd_parent	= -1;
 static int nsfd_child	= -1;
@@ -296,7 +303,7 @@ static bool is_optmem_namespaced(void)
 		int old_ns = switch_save_ns(nsfd_child);
 
 		optmem_ns = !access(optmem_file, F_OK);
-		switch_ns(old_ns);
+		switch_close_ns(old_ns);
 	}
 	return !!optmem_ns;
 }
@@ -317,7 +324,7 @@ size_t test_get_optmem(void)
 		test_error("can't read from %s", optmem_file);
 	fclose(foptmem);
 	if (!is_optmem_namespaced())
-		switch_ns(old_ns);
+		switch_close_ns(old_ns);
 	return ret;
 }
 
@@ -339,7 +346,7 @@ static void __test_set_optmem(size_t new, size_t *old)
 		test_error("can't write %zu to %s", new, optmem_file);
 	fclose(foptmem);
 	if (!is_optmem_namespaced())
-		switch_ns(old_ns);
+		switch_close_ns(old_ns);
 }
 
 static void test_revert_optmem(void)

-- 
2.42.2

