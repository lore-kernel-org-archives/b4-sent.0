From: Dmitry Safonov <0x7f454c46@gmail.com>
Subject: [PATCH net v3 0/3] tcp: TCP-AO connect() fixes
Date: Thu, 25 Jun 2026 17:54:28 +0100
Message-Id: <20260625-tcp-md5-connect-v3-0-30827ed58b6d@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAERdPWoC/yWMQQ6CMBBFr0Jm7UQsUKNXMS7a6SBjwkDaakwId
 7fV5Xt5/2+QOAonuDYbRH5LkkULdIcGaHL6YJRQGExrbGvNgJlWnMOAtKgyZQxkOnsJ57E/9VB
 Wa+RRPr/HGyhnuP9levln6etXzbxLjD46pamqEh5nJwr7/gWAJJKUkwAAAA==
X-Change-ID: 20260625-tcp-md5-connect-dc2369d7f414
To: Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>
Cc: Michael Bommarito <michael.bommarito@gmail.com>, 
 Qihang <q.h.hack.winter@gmail.com>, security@kernel.org, 
 Dmitry Safonov <0x7f454c46@gmail.com>, 
 Dmitry Safonov <0x7f454c46@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782406484; l=792;
 i=0x7f454c46@gmail.com; s=20260625; h=from:subject:message-id;
 bh=Owdh+o4cV8ucbhnwkAI/9g2pFQnXI+8vcFXDNpr8txY=;
 b=zxE6ThMYgvVkEXXke4U2Is/m9AfunRQu72acsFfMV4zedZ/d2UZxRucp3y61CzZZ4/Gfy46uO
 LJbqIMrrRQHCyTpN9WepvyFE/pr2cuMqMwq8t1Qpy05EZkTzucG3EV4
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=clHVGbfKfZMeCUp+xCL/096jI68XK5EZLytgy6lSyrc=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20260625 with auth_id=841
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Resending v3 as v2 seems to have been lost.

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

