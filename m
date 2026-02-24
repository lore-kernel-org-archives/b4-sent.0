From: Simon Baatz <gmbnomis@gmail.com>
Subject: [PATCH net v2 0/2] tcp: re-enable acceptance of FIN packets when
 RWIN is 0
Date: Tue, 24 Feb 2026 09:20:11 +0100
Message-Id: <20260224-fix_zero_wnd_fin-v2-0-a16677ea7cea@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2WNyw6CMBBFf4XM2pp2AI2u/A9DCLRTmERa0hJ8k
 P67DXHn8r7O3SBSYIpwLTYItHJk77LAQwF67NxAgk3WgBJPElEJy6/2Q8G3T2day04Y1XdKaVP
 28gx5NgfKnR15B0cLNNkcOS4+vPebVe3Rj4j/xFUJKWpbybK61GhLfRumjh9H7SdoUkpfUlVIX
 rUAAAA=
X-Change-ID: 20260221-fix_zero_wnd_fin-d1ba11cd3b07
To: Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, David Ahern <dsahern@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Simon Baatz <gmbnomis@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771921224; l=983;
 i=gmbnomis@gmail.com; s=20260220; h=from:subject:message-id;
 bh=iQjPg2LXKrMXc3WCOF+ndy+MkCA4NlMl9SonN6terl0=;
 b=d2tKmYZIkxzmfzTEaX20IA/Rl77jjUafMxejHMQM6gR1Cu7IFRtm4uyA+V5hpawd/43oiOUzg
 ZpYRClF6pTqC/734SUwhOJg+HzaIhMepKGrD+7M4LKP5ypxCmFY/ctB
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
Changes in v2:
- Move the FIN handling out of the default execution path as suggested by Eric Dumazet
- Link to v1: https://lore.kernel.org/r/20260222-fix_zero_wnd_fin-v1-0-5f4034952f3c@gmail.com

---
Simon Baatz (2):
      tcp: re-enable acceptance of FIN packets when RWIN is 0
      selftests/net: packetdrill: Verify acceptance of FIN packets when RWIN is 0

 net/ipv4/tcp_input.c                               | 18 +++++++++++----
 .../net/packetdrill/tcp_rcv_zero_wnd_fin.pkt       | 27 ++++++++++++++++++++++
 2 files changed, 41 insertions(+), 4 deletions(-)
---
base-commit: d4f687fbbce45b5e88438e89b5e26c0c15847992
change-id: 20260221-fix_zero_wnd_fin-d1ba11cd3b07

Best regards,
-- 
Simon Baatz <gmbnomis@gmail.com>

