From: Simon Baatz <gmbnomis@gmail.com>
Subject: [PATCH net-next 0/7] tcp: restrict rcv_wnd and window_clamp to
 representable window
Date: Wed, 08 Apr 2026 23:50:01 +0200
Message-Id: <20260408-tcp_rcv_exact_clamp_and_wnd-v1-0-76a6f212e153@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MUQrCMAwA0KuMfFvoanXqVURCSaMGNJa2zMLY3
 Vf2+X7eAoWzcIHbsEDmWYr8tGM8DEDvoC82ErvBWXe23jpTKWGmGbkFqkif8E0YNOJfo/Fuipf
 TkSd/HaEPKfNT2r7fQbka5Vbhsa4bOVUUjncAAAA=
X-Change-ID: 20260402-tcp_rcv_exact_clamp_and_wnd-427d853e7491
To: Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, David Ahern <dsahern@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Simon Baatz <gmbnomis@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775685040; l=3225;
 i=gmbnomis@gmail.com; s=20260220; h=from:subject:message-id;
 bh=bfuY5pXT/09Tmj0/Sfi1Tla4mOzK5VYAftWHOpXhLbo=;
 b=X/L7cDWkWfstOARedCaNVrM3czxQSs2EBZ8+lQc5h3mMA/OC1YzQ6XJn5iGm4oU4XHQsWqAKK
 8lLUtgCiwCbAAxU3dBg6LND9Ta+95/17SBoIH3Mw6FbOu7aT3g5JGGV
X-Developer-Key: i=gmbnomis@gmail.com; a=ed25519;
 pk=T/JIz/6F5bf1uQJr69lmyi7czVG+F9TVZ/8x5z9Wtqw=
X-Endpoint-Received: by B4 Relay for gmbnomis@gmail.com/20260220 with auth_id=641
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

this series ensures that rcv_wnd and window_clamp do not exceed the
maximum window size representable for the connection's window scale
factor.

This is most visible when TCP window scaling is not used for a
connection. In that case, the advertised window is limited to 65535
bytes, but rcv_wnd or window_clamp can still grow beyond 65535 when
large receive buffers are used. The resulting mismatch breaks
calculations that depend on the advertised window, such as the ACK
decision in __tcp_ack_snd_check(), and can prevent immediate ACKs.

Similar effects may also occur when window scaling is in use, e.g. if
the application dynamically adjusts SO_RCVBUF in unusual ways or when
the rmem sysctl parameters change during a connection’s lifetime.

Summary:

- Patch 1 keeps rcv_wnd capped by the (window scale-limited)
  window_clamp at connection start.
- Patch 3 and 6 ensure that window_clamp is limited to the
  representable window when it is updated.
- The other patches add packetdrill tests to verify the new behavior.

A simple iperf test on a virtme-ng VM (Intel i5-7500, 4 cores,
loopback) shows a noticeable improvement with window scaling disabled:

Fixed receive buffer:

- sysctl net.ipv4.tcp_window_scaling=0
- Server: iperf -l 256K -w 256K -s
- Client: iperf -l 256K -w 256K -c 127.0.0.1 -t 30
- net-next: ~47 Gbit/sec
- with this series: ~62 Gbit/sec

Receive buffer autotuning (net.ipv4.tcp_rmem = 4096 131072 7813888):

- sysctl net.ipv4.tcp_window_scaling=0
- Server: iperf -s
- Client: iperf -c 127.0.0.1 -t 30
- net-next: ~48 Gbit/sec
- with this series: ~60 Gbit/sec

Signed-off-by: Simon Baatz <gmbnomis@gmail.com>
---
Simon Baatz (7):
      tcp: keep rcv_wnd/rcv_ssthresh clamped by window_clamp if no scaling in use
      selftests/net: packetdrill: verify non-scaled rcv_wnd initialization
      tcp: Ensure window_clamp is limited to representable window
      selftests/net: packetdrill: add tcp_rcv_wnd_snd_ack_no_scaling.pkt
      selftests/net: packetdrill: add TCP_WINDOW_CLAMP test
      tcp: use tcp_set_window_clamp() for SO_RCVLOWAT
      selftests/net: packetdrill: add test for SO_RCVLOWAT window clamp

 net/ipv4/tcp.c                                     |  6 +++-
 net/ipv4/tcp_input.c                               | 13 ++++++--
 net/ipv4/tcp_minisocks.c                           |  8 +++--
 net/ipv4/tcp_output.c                              |  5 +--
 .../net/packetdrill/tcp_rcv_sockopt_lowat.pkt      | 24 ++++++++++++++
 .../net/packetdrill/tcp_rcv_sockopt_wnd_clamp.pkt  | 28 ++++++++++++++++
 .../packetdrill/tcp_rcv_wnd_active_no_scaling.pkt  | 27 ++++++++++++++++
 .../tcp_rcv_wnd_active_peer_no_scaling.pkt         | 26 +++++++++++++++
 .../packetdrill/tcp_rcv_wnd_passive_no_scaling.pkt | 30 ++++++++++++++++++
 .../tcp_rcv_wnd_passive_peer_no_scaling.pkt        | 29 +++++++++++++++++
 .../packetdrill/tcp_rcv_wnd_snd_ack_no_scaling.pkt | 37 ++++++++++++++++++++++
 11 files changed, 225 insertions(+), 8 deletions(-)
---
base-commit: b3e69fc3196fc421e26196e7792f17b0463edc6f
change-id: 20260402-tcp_rcv_exact_clamp_and_wnd-427d853e7491

Best regards,
-- 
Simon Baatz <gmbnomis@gmail.com>

