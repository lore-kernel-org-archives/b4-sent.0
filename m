From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Thu, 15 Aug 2024 22:32:29 +0100
Subject: [PATCH net-next v3 4/8] selftests/net: Open /proc/thread-self in
 open_netns()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240815-tcp-ao-selftests-upd-6-12-v3-4-7bd2e22bb81c@gmail.com>
References: <20240815-tcp-ao-selftests-upd-6-12-v3-0-7bd2e22bb81c@gmail.com>
In-Reply-To: <20240815-tcp-ao-selftests-upd-6-12-v3-0-7bd2e22bb81c@gmail.com>
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Shuah Khan <shuah@kernel.org>
Cc: Mohammad Nassiri <mnassiri@ciena.com>, netdev@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dmitry Safonov <0x7f454c46@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1723757567; l=1616;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=5VWqPUDjhIp9H1w5UjOr5S/0zah4a8/9NW+/5Oa3bag=;
 b=PNecNbQ9DKJVRb9aqAil9a/cpWXD5e9KfEajkTKHB4is0KOH7FiIlEwpipH+FvN7UCFjfc85Q
 v2PdMGbxCqMDZ3JVh5KSy9IsUWOMcaeOQcgDeuroJazZWq71jJ7ehs2
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It turns to be that open_netns() is called rarely from the child-thread
and more often from parent-thread. Yet, on initialization of kconfig
checks, either of threads may reach kconfig_lock mutex first.
VRF-related checks do create a temprary ksft-check VRF in
an unshare()'d namespace and than setns() back to the original.
As original was opened from "/proc/self/ns/net", it's valid for
thread-leader (parent), but it's invalid for the child, resulting
in the following failure on tests that check has_vrfs() support:
> # ok 54 TCP-AO required on socket + TCP-MD5 key: prefailed as expected: Key was rejected by service
> # not ok 55 # error 381[unsigned-md5.c:24] Failed to add a VRF: -17
> # not ok 56 # error 383[unsigned-md5.c:33] Failed to add a route to VRF: -22: Key was rejected by service
> not ok 1 selftests: net/tcp_ao: unsigned-md5_ipv6 # exit=1

Use "/proc/thread-self/ns/net" which is valid for any thread.

Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
 tools/testing/selftests/net/tcp_ao/lib/setup.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/tools/testing/selftests/net/tcp_ao/lib/setup.c b/tools/testing/selftests/net/tcp_ao/lib/setup.c
index e408b9243b2c..d5212ffe9489 100644
--- a/tools/testing/selftests/net/tcp_ao/lib/setup.c
+++ b/tools/testing/selftests/net/tcp_ao/lib/setup.c
@@ -111,7 +111,7 @@ static void sig_int(int signo)
 
 int open_netns(void)
 {
-	const char *netns_path = "/proc/self/ns/net";
+	const char *netns_path = "/proc/thread-self/ns/net";
 	int fd;
 
 	fd = open(netns_path, O_RDONLY);

-- 
2.42.2

