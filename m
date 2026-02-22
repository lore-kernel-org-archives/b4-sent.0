From: Simon Baatz <gmbnomis@gmail.com>
Subject: [PATCH net 0/2] tcp: re-enable acceptance of FIN packets when RWIN
 is 0
Date: Sun, 22 Feb 2026 13:35:07 +0100
Message-Id: <20260222-fix_zero_wnd_fin-v1-0-5f4034952f3c@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQqAIBAAvxJ7TnANCvpKhJRutZctNCoS/550H
 JiZBJECU4S+ShDo4si7FMC6ArdNspJiXxiMNq02BtXCj30p7PYWbxcW5XGeEJ1vZt1ByY5Axfm
 XAwidMOb8AWG+m55nAAAA
X-Change-ID: 20260221-fix_zero_wnd_fin-d1ba11cd3b07
To: Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, David Ahern <dsahern@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Simon Baatz <gmbnomis@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771763718; l=767;
 i=gmbnomis@gmail.com; s=20260220; h=from:subject:message-id;
 bh=Ad3HcaJiaO0xhdi6BjPXye6filJoTMtnWzaj36dECf4=;
 b=a4wxL2o8dJnNrLbg12N86bR+YJDyDe+zCosqzLSxm28QtxkJzW+Bo1FrcyO6/PiwAXsHp0+OL
 6gYnbe9lCz7C8nbCQSPVf/kBkJ3JZtcsvrGfYFyj1xdBx4zcmeekK1T
X-Developer-Key: i=gmbnomis@gmail.com; a=ed25519;
 pk=T/JIz/6F5bf1uQJr69lmyi7czVG+F9TVZ/8x5z9Wtqw=
X-Endpoint-Received: by B4 Relay for gmbnomis@gmail.com/20260220 with auth_id=641
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

this series restores the ability to accept in‑sequence FIN packets 
even when the advertised receive window is zero, and adds a 
packetdrill test to guard the behavior.

Signed-off-by: Simon Baatz <gmbnomis@gmail.com>
---
Simon Baatz (2):
      tcp: re-enable acceptance of FIN packets when RWIN is 0
      selftests/net: packetdrill: Verify acceptance of FIN packets when RWIN is 0

 net/ipv4/tcp_input.c                               |  7 +++++-
 .../net/packetdrill/tcp_rcv_zero_wnd_fin.pkt       | 27 ++++++++++++++++++++++
 2 files changed, 33 insertions(+), 1 deletion(-)
---
base-commit: d4f687fbbce45b5e88438e89b5e26c0c15847992
change-id: 20260221-fix_zero_wnd_fin-d1ba11cd3b07

Best regards,
-- 
Simon Baatz <gmbnomis@gmail.com>

