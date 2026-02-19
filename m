From: Simon Baatz <gmbnomis@gmail.com>
Subject: [PATCH RFC net-next 0/4] tcp: RFC 7323-compliant window retraction
 handling
Date: Fri, 20 Feb 2026 00:55:13 +0100
Message-Id: <20260220-tcp_rfc7323_retract_wnd_rfc-v1-0-904942561479@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MwQrCMAyA4VcpOVuoGUzxKvgAXoeULs00lzrSo
 IOxd7fz+P2Hf4XKKlzh4lZQ/kiVd2k4HhzQK5Une8nNgAH7gBi80Rx1olOHXVQ2TWTxW/LePJ0
 TZhwTj5mhHWblSZb/fYD77eoKmy+8GDy27QfkRiVoewAAAA==
X-Change-ID: 20260220-tcp_rfc7323_retract_wnd_rfc-c8a2d2baebde
To: Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 David Ahern <dsahern@kernel.org>, Stefano Brivio <sbrivio@redhat.com>, 
 Jon Maloy <jmaloy@redhat.com>, Jason Xing <kerneljasonxing@gmail.com>, 
 mfreemon@cloudflare.com, Shuah Khan <shuah@kernel.org>
Cc: Christian Ebner <c.ebner@proxmox.com>, netdev@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Simon Baatz <gmbnomis@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771545363; l=3411;
 i=gmbnomis@gmail.com; s=20260220; h=from:subject:message-id;
 bh=A4B+KQUKfkALABSV4ypfoM7JWCIo0oQ5oJiT+QXtlgM=;
 b=oNGmNjCqW5WuUBHxUhDcDVp1H6go11aygE11D7Wp0WGZ4sPYxX0QAVXGO6QFSqO1gf443g7kk
 EhnarpSRwfrCr7CdlrCXJ9zQP3PXVeF/8Y8odmcZ1PtJ9Di/MO7qMDy
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
  tcp_select_window. However, rcv_wup is documented as RX read_write
  only (even though it is updated in tcp_select_window), and rcv_wnd
  is TX read_write / RX read_mostly.

  rcv_mwnd_seq is only updated in tcp_select_window and, as far as I
  can tell, is not used on the RX fast path.

  If I understand the placement rules correctly, this means that
  rcv_mwnd_seq, rcv_wup, and rcv_wnd end up in different cacheline
  groups, which feels odd. Guidance on where rcv_mwnd_seq should live
  would be appreciated.

- In tcp_minisocks.c, it is not clear to me whether we should change
  "tcptw->tw_rcv_wnd = tcp_receive_window(tp)" to
  "tcptw->tw_rcv_wnd = tcp_max_receive_window(tp)". I could not find a
  case where this makes a practical difference and have left the
  existing behavior unchanged.

- Packetdrill tests: Some of these seem rather brittle to me; I
  included them mostly to document what I have tested. Suggestions
  for making them more robust are welcome.

- MPTCP seems to modify tp->rcv_wnd of subflows. I haven't looked at
  this, since I wanted to get feedback on the overall approach first.

- Although this series addresses a regression triggered by commit
  d2fbaad7cd8 ("tcp: stronger sk_rcvbuf checks") the underlying
  problem is shrinking the window. Thus I added "Fixes" headers for
  the commits that introduced window shrinking.

I would appreciate feedback on the overall approach and on these
questions.

Signed-off-by: Simon Baatz <gmbnomis@gmail.com>
---
Simon Baatz (4):
      tcp: implement RFC 7323 window retraction receiver requirements
      selftests/net: packetdrill: add tcp_rcv_wnd_shrink_nomem.pkt
      selftests/net: packetdrill: add tcp_rcv_wnd_shrink_allowed.pkt
      selftests/net: packetdrill: add tcp_rcv_toobig_back_to_back.pkt

 .../networking/net_cachelines/tcp_sock.rst         |   1 +
 include/linux/tcp.h                                |   1 +
 include/net/tcp.h                                  |  14 +++
 net/ipv4/tcp_fastopen.c                            |   1 +
 net/ipv4/tcp_input.c                               |   6 +-
 net/ipv4/tcp_minisocks.c                           |   1 +
 net/ipv4/tcp_output.c                              |  12 +++
 .../net/packetdrill/tcp_rcv_big_endseq.pkt         |   2 +-
 .../packetdrill/tcp_rcv_toobig_back_to_back.pkt    |  27 +++++
 .../net/packetdrill/tcp_rcv_wnd_shrink_allowed.pkt |  35 +++++++
 .../net/packetdrill/tcp_rcv_wnd_shrink_nomem.pkt   | 109 +++++++++++++++++++++
 11 files changed, 206 insertions(+), 3 deletions(-)
---
base-commit: 8bf22c33e7a172fbc72464f4cc484d23a6b412ba
change-id: 20260220-tcp_rfc7323_retract_wnd_rfc-c8a2d2baebde

Best regards,
-- 
Simon Baatz <gmbnomis@gmail.com>

