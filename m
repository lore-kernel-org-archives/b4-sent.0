From: quanyeyang@proton.me
Subject: [PATCH mptcp-net v3 0/3] mptcp: fix reported data-races
Date: Mon, 07 Sep 2026 18:15:12 +0800
Message-Id: <20260907-mptcp-snd-una-race-v3-0-65ba0d5f0221@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWM0QrCMBAEf6XcswchQm39FfEhSdd6gmfIpSKU/
 rvRPg6zOysZisDo3K1U8BaTlzY4HjpK96AzWKbG5J3v3eh6fuaaMptOvGjgEhI4okmPwcfxRO2
 YC27y+UcvtO8Vla67siU+kOovStv2BRd0x6aBAAAA
X-Change-ID: 20260906-mptcp-snd-una-race-be0262e82b97
To: MPTCP Linux <mptcp@lists.linux.dev>
Cc: geliang@kernel.org, matttbe@kernel.org, pabeni@redhat.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788776116; l=1520;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=4swwXSXZMFQrVpWN3d94kjdBytf0k593JmcslLYIY6o=;
 b=OKoOjQqUnpArxC4se/rwjY/yQOiM77xfDnZ6uF0EEC3x3O+5lEVLP7llNbHEvc0ykWk3iE18p
 MPHMoIPBOL/Aw3XA39vYp42d3Bdc1EK+4cXqX1SlDa+uNYgJA+arQyG
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix three KCSAN reports involving the MPTCP receive and retransmit
paths.

Patch 1 picks up Matthieu's v2 fixing the lockless snd_una read.

Patch 2 fixes the lockless access to the TCP subflow's icsk_pending
field when calculating the MPTCP retransmission timeout.

Patch 3 fixes the lockless sk_err access in tcp_recv_should_stop(),
as sock_error() can clear the field without holding the socket lock.

Closes: https://github.com/multipath-tcp/mptcp_net-next/issues/627
Link: https://lore.kernel.org/mptcp/20260317-mptcp-data-race-snd_una-v2-1-2caac60de92a@kernel.org/
---
v3:
 - rebase on the MPTCP export branch
 - wrap the snd_una field comment to satisfy checkpatch
 - add fixes for the reported icsk_pending and sk_err races
 - exclude the unrelated workqueue and timekeeping reports

v2:
 - mention under which locks the field is updated and read
 - add a comment where snd_una is defined

To: mptcp@lists.linux.dev

---
Matthieu Baerts (NGI0) (1):
      mptcp: fix data-race in __mptcp_retrans / mptcp_incoming_options

Quanye Yang (2):
      mptcp: fix data-race in mptcp_subflow_get_send / tcp_ack
      tcp: fix data-race in do_recvmmsg / mptcp_recvmsg

 include/net/tcp.h    | 3 ++-
 net/mptcp/protocol.c | 4 +++-
 net/mptcp/protocol.h | 6 ++++--
 3 files changed, 9 insertions(+), 4 deletions(-)
---
base-commit: 45f7c939f8b155208c7447517e588c9fb133388c
change-id: 20260906-mptcp-snd-una-race-be0262e82b97

Best regards,
--  
Quanye Yang <quanyeyang@proton.me>

