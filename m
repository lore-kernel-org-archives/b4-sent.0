From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Wed, 19 Jun 2024 01:29:04 +0100
Subject: [PATCH net] net/tcp_ao: Don't leak ao_info on error-path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240619-tcp-ao-required-leak-v1-1-6408f3c94247@gmail.com>
X-B4-Tracking: v=1; b=H4sIAE8mcmYC/x2MwQrCMBAFf6Xs2YU2hkr9FfGwSZ52UdO6qSKU/
 rvR4wzMrFRgikLHZiXDW4tOuUK3ayiOkq9gTZXJtc63fTfwEmeWiQ3PlxoS3yE3di54GUKfDn5
 PNZ0NF/38tyfKWOhcZZACDiY5jr/jQ8oCo237Aq/AsvqEAAAA
To: Eric Dumazet <edumazet@google.com>, 
 "David S. Miller" <davem@davemloft.net>, David Ahern <dsahern@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Dmitry Safonov <0x7f454c46@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718756966; l=1410;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=U4ffmt+DUWeDhoiFE1PxHHKXEhF2E1etRzuFRWJAYks=;
 b=1nlpQ5rZM2edyZFchlRIuzQ9Kxs50YnffEPqyXXW0fnMWL2amUUou8Zbpd/ttsVw6enM+fHirgyV
 D/3Y/FMXBZgTP1rF8zQA46MTVXb1xaWWq1mug9ccyAvR7vO0wPfF
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It seems I introduced it together with TCP_AO_CMDF_AO_REQUIRED, on
version 5 [1] of TCP-AO patches. Quite frustrative that having all these
selftests that I've written, running kmemtest & kcov was always in todo.

[1]: https://lore.kernel.org/netdev/20230215183335.800122-5-dima@arista.com/

Reported-by: Jakub Kicinski <kuba@kernel.org>
Closes: https://lore.kernel.org/netdev/20240617072451.1403e1d2@kernel.org/
Fixes: 0aadc73995d0 ("net/tcp: Prevent TCP-MD5 with TCP-AO being set")
Cc: stable@vger.kernel.org
Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
 net/ipv4/tcp_ao.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/net/ipv4/tcp_ao.c b/net/ipv4/tcp_ao.c
index 37c42b63ff99..09c0fa6756b7 100644
--- a/net/ipv4/tcp_ao.c
+++ b/net/ipv4/tcp_ao.c
@@ -1968,8 +1968,10 @@ static int tcp_ao_info_cmd(struct sock *sk, unsigned short int family,
 		first = true;
 	}
 
-	if (cmd.ao_required && tcp_ao_required_verify(sk))
-		return -EKEYREJECTED;
+	if (cmd.ao_required && tcp_ao_required_verify(sk)) {
+		err = -EKEYREJECTED;
+		goto out;
+	}
 
 	/* For sockets in TCP_CLOSED it's possible set keys that aren't
 	 * matching the future peer (address/port/VRF/etc),

---
base-commit: 92e5605a199efbaee59fb19e15d6cc2103a04ec2
change-id: 20240619-tcp-ao-required-leak-22b4a9b6d743

Best regards,
-- 
Dmitry Safonov <0x7f454c46@gmail.com>

