From: Simon Baatz <gmbnomis@gmail.com>
Subject: [PATCH net-next v3 0/6] tcp: RFC 7323-compliant window retraction
 handling
Date: Mon, 09 Mar 2026 09:02:25 +0100
Message-Id: <20260309-tcp_rfc7323_retract_wnd_rfc-v3-0-4c7f96b1ec69@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/43NQQ6CMBQE0KuQrq0pv1jAlfcwhpTPLzSRQkqDG
 MLdrax0Y1zOTPJmZRN5SxM7JyvzNNvJDi4GeUgYdtq1xG0TMwMBSgAIHnCsvMFcgqw8Ba8xVA/
 XvDuOhYYGak11QywKoydjl12/MkeBO1oCu8Wls1MY/HO/ndN9/+thTrngpcjKDE4qzfLy0vba3
 o849Ls7w6elflsQLa2lKUyJqOSXtW3bC63aRgkcAQAA
X-Change-ID: 20260220-tcp_rfc7323_retract_wnd_rfc-c8a2d2baebde
To: Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 David Ahern <dsahern@kernel.org>, Jon Maloy <jmaloy@redhat.com>, 
 Jason Xing <kerneljasonxing@gmail.com>, mfreemon@cloudflare.com, 
 Shuah Khan <shuah@kernel.org>, Stefano Brivio <sbrivio@redhat.com>, 
 Matthieu Baerts <matttbe@kernel.org>, Mat Martineau <martineau@kernel.org>, 
 Geliang Tang <geliang@kernel.org>
Cc: netdev@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 mptcp@lists.linux.dev, Simon Baatz <gmbnomis@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773043425; l=2738;
 i=gmbnomis@gmail.com; s=20260220; h=from:subject:message-id;
 bh=3vpHAvYSJE1/E/Zw+R+U696ggtTJgVYAry+AHza2BC0=;
 b=kjc0s3J5JCYmq3GL3c4pN+j3Sh2jXUPcSLsACTyzPCeAcEecc5kYPGGaFYIVKCviKD9I/pjtE
 SqZlBqN54oHBpEBmApZTEBi2NMxOI3WSLi8DVVvnBfjjWaJhu1fQ5fm
X-Developer-Key: i=gmbnomis@gmail.com; a=ed25519;
 pk=T/JIz/6F5bf1uQJr69lmyi7czVG+F9TVZ/8x5z9Wtqw=
X-Endpoint-Received: by B4 Relay for gmbnomis@gmail.com/20260220 with auth_id=641
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

this series implements the receiver-side requirements for TCP window
retraction as specified in RFC 7323 and adds packetdrill tests to
cover the new behavior.

Please see the first patch for background and implementation
details. Since MPTCP adjusts the TCP receive window on subflows, the
relevant MPTCP code paths are updated accordingly.

Signed-off-by: Simon Baatz <gmbnomis@gmail.com>
---
Changes in v3:

- Address MPTCP subflow-level rcv_wnd adjustments
- Removed RFC status
- Adapt tcp_rcv_wnd_shrink_nomem.pkt to reflect 026dfef287c0 ("tcp:
  give up on stronger sk_rcvbuf checks (for now)")
- Link to v2: https://lore.kernel.org/r/20260226-tcp_rfc7323_retract_wnd_rfc-v2-0-aa3f8f9cc639@gmail.com

Changes in v2:

- tcp_rcv_wnd_shrink_nomem.pkt tests more RX code paths using various
  segment types. It also uses a more drastic rcv. buffer reduction (1MB
  to 16KB).
- Setting the TCP_REPAIR_WINDOW socket option initializes rcv_mwnd_seq.
- SKB_DROP_REASON_TCP_OVERWINDOW increases LINUX_MIB_BEYOND_WINDOW now.
- Moved rcv_mwnd_seq into rcv_wnd's cacheline group.
- Small editorial changes
- Link to v1: https://lore.kernel.org/r/20260220-tcp_rfc7323_retract_wnd_rfc-v1-0-904942561479@gmail.com

---
Simon Baatz (6):
      tcp: implement RFC 7323 window retraction receiver requirements
      mptcp: keep rcv_mwnd_seq in sync with subflow rcv_wnd
      tcp: increase LINUX_MIB_BEYOND_WINDOW for SKB_DROP_REASON_TCP_OVERWINDOW
      selftests/net: packetdrill: add tcp_rcv_wnd_shrink_nomem.pkt
      selftests/net: packetdrill: add tcp_rcv_wnd_shrink_allowed.pkt
      selftests/net: packetdrill: add tcp_rcv_neg_window.pkt

 .../networking/net_cachelines/tcp_sock.rst         |   1 +
 include/linux/tcp.h                                |   3 +
 include/net/tcp.h                                  |  22 ++++
 net/ipv4/tcp.c                                     |   2 +
 net/ipv4/tcp_fastopen.c                            |   1 +
 net/ipv4/tcp_input.c                               |  11 +-
 net/ipv4/tcp_minisocks.c                           |   1 +
 net/ipv4/tcp_output.c                              |   3 +
 net/mptcp/options.c                                |   6 +-
 .../net/packetdrill/tcp_rcv_big_endseq.pkt         |   2 +-
 .../net/packetdrill/tcp_rcv_neg_window.pkt         |  26 ++++
 .../net/packetdrill/tcp_rcv_wnd_shrink_allowed.pkt |  40 +++++++
 .../net/packetdrill/tcp_rcv_wnd_shrink_nomem.pkt   | 132 +++++++++++++++++++++
 13 files changed, 242 insertions(+), 8 deletions(-)
---
base-commit: 0bcac7b11262557c990da1ac564d45777eb6b005
change-id: 20260220-tcp_rfc7323_retract_wnd_rfc-c8a2d2baebde

Best regards,
-- 
Simon Baatz <gmbnomis@gmail.com>

