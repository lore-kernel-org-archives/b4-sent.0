From: Dmitry Safonov <0x7f454c46@gmail.com>
Subject: [PATCH net v3 0/3] tcp: TCP-AO connect() fixes
Date: Thu, 25 Jun 2026 19:21:38 +0100
Message-Id: <20260625-tcp-md5-connect-v3-0-1fd313d6c1e0@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALJxPWoC/yWMQQ6CMBBFr0Jm7UQsUKNXMS7a6SBjwkDaakwId
 7fV5Xt5/2+QOAonuDYbRH5LkkULdIcGaHL6YJRQGExrbGvNgJlWnMOAtKgyZQxkOnsJ57E/9VB
 Wa+RRPr/HGyhnuP9levln6etXzbxLjD46pamqEh5nJwr7/gWAJJKUkwAAAA==
X-Change-ID: 20260625-tcp-md5-connect-dc2369d7f414
To: David Ahern <dsahern@kernel.org>, Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Salam Noureddine <noureddine@arista.com>
Cc: Michael Bommarito <michael.bommarito@gmail.com>, 
 Qihang <q.h.hack.winter@gmail.com>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dmitry Safonov <0x7f454c46@gmail.com>, 
 stable@vger.kernel.org, Dmitry Safonov <0x7f454c46@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782411722; l=762;
 i=0x7f454c46@gmail.com; s=20260625; h=from:subject:message-id;
 bh=XQ53pe/Jq8Z+Ffdi2ZgG+P8nlFouXKNplbiEL69TedA=;
 b=Y7z8nzcRMUDzxvqM7RljOh8KweK3DMHV8ICMaFA05PjJgEO3zSkUJxtrhQHXWTzSkEoIp7UgX
 d88tq5AcaTEDzlQwBvZq1J6tg9JGtkqXSqsrxf0ShwkFRsiYIrfbX8b
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=clHVGbfKfZMeCUp+xCL/096jI68XK5EZLytgy6lSyrc=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20260625 with auth_id=841
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Resending v3.

I've addeded credits to Qihang on patch 2; and a third patch/fix
for static key decrement.

Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
Dmitry Safonov (1):
      tcp: Decrement tcp_md5_needed static branch

Michael Bommarito (2):
      tcp: restore RCU grace period in tcp_ao_destroy_sock
      tcp: defer md5sig_info kfree past RCU grace period in tcp_connect

 include/net/tcp_ao.h  | 1 +
 net/ipv4/tcp_ao.c     | 5 +++--
 net/ipv4/tcp_ipv4.c   | 4 ++--
 net/ipv4/tcp_output.c | 8 ++++++--
 4 files changed, 12 insertions(+), 6 deletions(-)
---
base-commit: 02f144fbb4c86c360495d33debe307cb46a57f95
change-id: 20260625-tcp-md5-connect-dc2369d7f414

Best regards,
--  
Dmitry Safonov <0x7f454c46@gmail.com>

