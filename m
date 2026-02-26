From: Simon Baatz <gmbnomis@gmail.com>
Subject: [PATCH RFC net-next v2 0/5] tcp: RFC 7323-compliant window
 retraction handling
Date: Thu, 26 Feb 2026 01:49:06 +0100
Message-Id: <20260226-tcp_rfc7323_retract_wnd_rfc-v2-0-aa3f8f9cc639@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42N3wqCMBSHX0XOdYt5NM2ugqAH6DZE5nbUQU7Zh
 hmyd2/5BF3+/vB9Gziymhxckg0sLdrpycSAhwTkIExPTKuYATkWHJEzL+fGdrLMMGsseSukb95
 G/TomzwIVtoJaRRAJs6VOrzv9CY/7LTHkmaHVQx3XQTs/2c+uXtL985dlSRlnFc+rHE9FmpfVt
 R+Ffh3lNEIdQvgCiPkMpdQAAAA=
X-Change-ID: 20260220-tcp_rfc7323_retract_wnd_rfc-c8a2d2baebde
To: Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 David Ahern <dsahern@kernel.org>, Stefano Brivio <sbrivio@redhat.com>, 
 Jon Maloy <jmaloy@redhat.com>, Jason Xing <kerneljasonxing@gmail.com>, 
 mfreemon@cloudflare.com, Shuah Khan <shuah@kernel.org>, 
 Stefano Brivio <sbrivio@redhat.com>
Cc: Christian Ebner <c.ebner@proxmox.com>, netdev@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Simon Baatz <gmbnomis@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772066964; l=3983;
 i=gmbnomis@gmail.com; s=20260220; h=from:subject:message-id;
 bh=YHtDERu+dGZKwokXML/KbGIAJKjFs9XTNnGWe5MyxQY=;
 b=N0mn084EpHoTzzizetrZ3FJM/LK2M7Xhs7TrG0vLQs7Vld6CoyM/xKEdyG4BKmEp4cPfefUoI
 lgc8R4hpclvDUoFb7xF0KiCNm/S+71rDNMv+Ka7mjP+yqO2gyxzl0RA
X-Developer-Key: i=gmbnomis@gmail.com; a=ed25519;
 pk=T/JIz/6F5bf1uQJr69lmyi7czVG+F9TVZ/8x5z9Wtqw=
X-Endpoint-Received: by B4 Relay for gmbnomis@gmail.com/20260220 with auth_id=641
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

this series implements the receiver-side requirements for TCP window
retraction as specified in RFC 7323 and adds packetdrill tests to
cover the new behavior.

It addresses a regression with somewhat complex causes; see my message
"Re: [regression] [PATCH net-next 7/8] tcp: stronger sk_rcvbuf checks"
(https://lkml.kernel.org/netdev/aXaHEk_eRJyhYfyM@gandalf.schnuecks.de/).

Please see the first patch for background and implementation details.

This is an RFC because a few open questions remain:

- Placement of the new rcv_mwnd_seq field in tcp_sock:

  rcv_mwnd_seq is updated together with rcv_wup and rcv_wnd in
  tcp_select_window(). However, rcv_wup is documented as RX read_write
  only (even though it is updated in tcp_select_window()), and rcv_wnd
  is TX read_write / RX read_mostly.

  rcv_mwnd_seq is only updated in tcp_select_window(). If we
  count tcp_sequence() as fast path, it is read in the fast path.

  Therefore, the proposal is to put rcv_mwnd_seq in rcv_wnd's
  cacheline group.

- In tcp_minisocks.c, it is not clear to me whether we should change
  "tcptw->tw_rcv_wnd = tcp_receive_window(tp)" to
  "tcptw->tw_rcv_wnd = tcp_max_receive_window(tp)". I could not find a
  case where this makes a practical difference and have left the
  existing behavior unchanged.

- MPTCP seems to modify tp->rcv_wnd of subflows. And the modifications
  look odd:

  1. It is updated in the RX path. Since we never advertised that
     value, we shouldn't need to update rcv_mwnd_seq.
  2. In the TX path, there is:
  
     tp->rcv_wnd = min_t(u64, win, U32_MAX);

     To me, that looks very wrong and that code might need to be fixed
     first.

- Although this series addresses a regression triggered by commit
  d2fbaad7cd8 ("tcp: stronger sk_rcvbuf checks") the underlying
  problem is shrinking the window. Thus, I added "Fixes" headers for
  the commits that introduced window shrinking.

I would appreciate feedback on the overall approach and on these
questions.

Signed-off-by: Simon Baatz <gmbnomis@gmail.com>
---
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
Simon Baatz (5):
      tcp: implement RFC 7323 window retraction receiver requirements
      tcp: increase LINUX_MIB_BEYOND_WINDOW for SKB_DROP_REASON_TCP_OVERWINDOW
      selftests/net: packetdrill: add tcp_rcv_wnd_shrink_nomem.pkt
      selftests/net: packetdrill: add tcp_rcv_wnd_shrink_allowed.pkt
      selftests/net: packetdrill: add tcp_rcv_neg_window.pkt

 .../networking/net_cachelines/tcp_sock.rst         |   1 +
 include/linux/tcp.h                                |   3 +
 include/net/tcp.h                                  |  13 ++
 net/ipv4/tcp.c                                     |   1 +
 net/ipv4/tcp_fastopen.c                            |   1 +
 net/ipv4/tcp_input.c                               |   7 +-
 net/ipv4/tcp_minisocks.c                           |   1 +
 net/ipv4/tcp_output.c                              |  12 ++
 .../net/packetdrill/tcp_rcv_big_endseq.pkt         |   2 +-
 .../net/packetdrill/tcp_rcv_neg_window.pkt         |  26 ++++
 .../net/packetdrill/tcp_rcv_wnd_shrink_allowed.pkt |  40 ++++++
 .../net/packetdrill/tcp_rcv_wnd_shrink_nomem.pkt   | 141 +++++++++++++++++++++
 12 files changed, 245 insertions(+), 3 deletions(-)
---
base-commit: 2f61f38a217462411fed950e843b82bc119884cf
change-id: 20260220-tcp_rfc7323_retract_wnd_rfc-c8a2d2baebde

Best regards,
-- 
Simon Baatz <gmbnomis@gmail.com>

