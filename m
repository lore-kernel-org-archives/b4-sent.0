From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Fri, 23 Aug 2024 23:04:54 +0100
Subject: [PATCH net-next v4 4/8] selftests/net: Open /proc/thread-self in
 open_netns()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240823-tcp-ao-selftests-upd-6-12-v4-4-05623636fe8c@gmail.com>
References: <20240823-tcp-ao-selftests-upd-6-12-v4-0-05623636fe8c@gmail.com>
In-Reply-To: <20240823-tcp-ao-selftests-upd-6-12-v4-0-05623636fe8c@gmail.com>
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Shuah Khan <shuah@kernel.org>
Cc: Mohammad Nassiri <mnassiri@ciena.com>, netdev@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dmitry Safonov <0x7f454c46@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724450716; l=1617;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=/DZmg+6IbPGdTOm+TsFWm6lsqGF2a6IiuioNpa7vVmQ=;
 b=1Qg0RIkvlr4xCpN/mwDo1APAEndDw0E+47mt2AWGvXv1mwRfJodBFE9XhTw3LmlbdkxFNVMD7
 lK14JI02RjNB3+X3OR78MNrVdECc4Tw878BKlhg7ojtgt8qgIqSNQIi
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It turns to be that open_netns() is called rarely from the child-thread
and more often from parent-thread. Yet, on initialization of kconfig
checks, either of threads may reach kconfig_lock mutex first.
VRF-related checks do create a temporary ksft-check VRF in
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

