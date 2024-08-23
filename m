From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Fri, 23 Aug 2024 23:04:51 +0100
Subject: [PATCH net-next v4 1/8] selftests/net: Clean-up double assignment
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240823-tcp-ao-selftests-upd-6-12-v4-1-05623636fe8c@gmail.com>
References: <20240823-tcp-ao-selftests-upd-6-12-v4-0-05623636fe8c@gmail.com>
In-Reply-To: <20240823-tcp-ao-selftests-upd-6-12-v4-0-05623636fe8c@gmail.com>
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Shuah Khan <shuah@kernel.org>
Cc: Mohammad Nassiri <mnassiri@ciena.com>, netdev@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dmitry Safonov <0x7f454c46@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724450716; l=947;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=CTRIdhA/fNrbMRjaJSddnxfQDObvWmFHJBusF1leQ7c=;
 b=qiTQgBS+fVc2fssLpqStyjQOkOOrKu4E8mujH9Mda4q8LlfGqDUwg0i4Zp0facIFK2xao04GY
 GYmR7fMy5HvCOSHSOsbDGLx8GExYSQpp0Z2Asoc9U3BEnl47ACEXo/M
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Correct copy'n'paste typo: the previous line already initialises get_all
to 1.

Reported-by: Nassiri, Mohammad <mnassiri@ciena.com>
Closes: https://lore.kernel.org/all/DM6PR04MB4202BC58A9FD5BDD24A16E8EC56F2@DM6PR04MB4202.namprd04.prod.outlook.com/
Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
 tools/testing/selftests/net/tcp_ao/lib/sock.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/tools/testing/selftests/net/tcp_ao/lib/sock.c b/tools/testing/selftests/net/tcp_ao/lib/sock.c
index 15aeb0963058..0ffda966c677 100644
--- a/tools/testing/selftests/net/tcp_ao/lib/sock.c
+++ b/tools/testing/selftests/net/tcp_ao/lib/sock.c
@@ -379,7 +379,6 @@ int test_get_tcp_ao_counters(int sk, struct tcp_ao_counters *out)
 
 	key_dump[0].nkeys = nr_keys;
 	key_dump[0].get_all = 1;
-	key_dump[0].get_all = 1;
 	err = getsockopt(sk, IPPROTO_TCP, TCP_AO_GET_KEYS,
 			 key_dump, &key_dump_sz);
 	if (err) {

-- 
2.42.2

