From: Martin Belanger <martin.nvme.dev@gmail.com>
Subject: [PATCH RFC net-next v3 0/5] tls: perform TLS 1.3 KeyUpdate in the
 kernel
Date: Fri, 30 Oct 2026 07:18:11 -0400
Message-Id: <20261030-keyupdate-rfc-v3-0-8e1e32226e51@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WOyw6CMBBFf8V0bU0phaIrExM/wK1xQdsBqvJIW
 wiE8O+WuiEmLu/MPWdmRhaMBotOuxkZGLTVbeNDvN8hWeVNCVgrnxElNI0ITfALpr5TuQNsCom
 PTMWSQ8YI58gznYFCj8F3R7frZZ014HADo0OPb8H24gnSrdZ1XWnrWjOFD4YogH+ODREmOCWC8
 yQFKYU6l3Wu3wfZ1sE90C2d/dLU0yCSiMWCSZbxLb0sywfdF16sCwEAAA==
X-Change-ID: 20261025-keyupdate-rfc-94d3c7e84077
To: John Fastabend <john.fastabend@gmail.com>, 
 Jakub Kicinski <kuba@kernel.org>, Sabrina Dubroca <sd@queasysnail.net>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Shuah Khan <shuah@kernel.org>
Cc: linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 Hannes Reinecke <hare@kernel.org>, Chuck Lever <cel@kernel.org>, 
 kernel-tls-handshake@lists.linux.dev, linux-nvme@lists.infradead.org, 
 Alistair Francis <alistair.francis@wdc.com>, 
 Martin Belanger <martin.belanger@dell.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793359096; l=8920;
 i=martin.nvme.dev@gmail.com; s=20261014; h=from:subject:message-id;
 bh=sFbD6ZqjlXc6GPbItJ5mNDRkqXKYq9hhbUTFLPWJ/b8=;
 b=8KoB2jyv6Mc1v4yKctLGXLZPMzcW6S1OLRlDJ3JJVPlEVm70Vus6+xvv6rdsOPEJYXaqTXV4O
 3hgmpKBnjQZBEpXDjXCbdVMKRT1rH0mAEiR3/X7YwMs/DlFFtxntkPe
X-Developer-Key: i=martin.nvme.dev@gmail.com; a=ed25519;
 pk=4K+XXetGK35w2LzRRddd/bbHawZU222BN+YZRuSpN+k=
X-Endpoint-Received: by B4 Relay for martin.nvme.dev@gmail.com/20261014 with auth_id=1176
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

kTLS does not currently handle TLS 1.3 KeyUpdate. It never sends a
KeyUpdate. And when it receives one, it blocks the socket until the
application installs the next key. kTLS also does not enforce the key
usage limit on transmit.

This applies to TLS libraries in user space as well as kernel users such
as NVMe/TCP or sunrpc:

- GnuTLS sends a KeyUpdate after 2^24 records when it runs its own
  record layer. With kTLS, the record layer is handled in the kernel and
  GnuTLS therefore never runs the check. OpenSSL never sends a KeyUpdate
  on its own.
- NVMe/TCP and sunrpc don't have a mechanism to install a new key. A
  conforming peer that sends a KeyUpdate stalls their connection.

RFC 9846 (July 2026), which obsoletes RFC 8446, makes the limit
mandatory (section 5.5): "Implementations MUST either close the
connection or do a key update as described in Section 4.7.3 prior to
reaching these limits." Long-lived connections with small records reach
the limit quickly. One NVMe/TCP queue sends at least one record per
command, and more with large I/O. Depending on the load and link speed,
the 2^24 limit can be reached in less than 10 minutes in many cases.

With this series, kTLS handles KeyUpdate in both directions for a socket
that registers its traffic secrets. A socket that does not register them
behaves as before. A user can opt in by passing the secrets after the
handshake. GnuTLS and OpenSSL install the kTLS keys themselves, so they
could register the secrets at the same time. tlshd gets the secrets from
GnuTLS through a callback it uses for QUIC.

Why the record layer
====================

KeyUpdate must be handled where the records are built.

The 2^24 limit is a record count, and only the record layer can see the
count precisely as it changes. A user sitting above kTLS can only read
the count with getsockopt(TLS_TX) after each write. A kTLS user writes
bytes, and the kernel splits and merges those bytes into records. I
counted send calls in an NVMe/TCP prototype trying to guesstimate the
2^24 limit. The count was correct with 4 KB I/O, but was 21 times too
low with 1 MB I/O. Each send call translates into a different number of
records. It's simply not possible to precisely guess the number of
records based on the number of send calls.

The KeyUpdate must also go at a precise place in the record stream
(section 4.7.3). It is encrypted with the old key, and every record
after it with the new key. When the peer sets update_requested, our
KeyUpdate must go out before the next Application Data record. The key
can only change between two records. Only net/tls has control over that.
Fixing this in one driver or library would leave other drivers or
libraries to re-implement their own (imperfect) solution.

The in-kernel QUIC series under review on netdev splits the work the
same way as this proposed fix. The handshake stays in user space, the
secrets are passed in with a socket option, and the kernel derives each
key update with HKDF-Expand-Label (quic_crypto_key_update()).

What the series does
====================

- Two new socket options, TLS_TX_TRAFFIC_SECRET and
  TLS_RX_TRAFFIC_SECRET, are used to register the application traffic
  secrets. The secret is passed as raw bytes. The kernel derives the
  hash (SHA-256 or SHA-384) from the cipher installed with TLS_TX or
  TLS_RX. The TX secret must be set first because the RX secret needs
  the TX secret in case a received KeyUpdate asks for a reply.
- A third socket option, TLS_TX_KEY_UPDATE, can be used to send a
  KeyUpdate now. It can also optionally ask the peer to update too.
- Receive: kTLS consumes the KeyUpdate, installs the next key and
  continues. This works for recvmsg, splice and read_sock.
- Transmit: kTLS sends a KeyUpdate after 2^24 records, a margin below
  the 2^24.5 limit of RFC 9846 section 5.5, and in reply to
  update_requested. ChaCha20-Poly1305 has no record limit.
- kTLS aborts the connection when a peer sends more than 8 KeyUpdates in
  one second, or an invalid KeyUpdate. GnuTLS uses the same rate limit.
- Software path only. Device offload is unchanged.
- SM4-GCM and SM4-CCM are not supported: the kernel has no HMAC-SM3.

Testing
=======

- NVMe/TCP host and target over loopback, with the record limit and the
  rate limit lowered for the test: more than 1000 KeyUpdates in each
  direction under I/O, with AES-128-GCM and AES-256-GCM.
- Interoperability with OpenSSL in user space, which derives the keys on
  its own, including the reply to update_requested.
- New selftests in tools/testing/selftests/net/tls.c for every TLS 1.3
  cipher kTLS supports. The full tls selftest passes.

The matching tlshd change for ktls-utils is a small patch to be
submitted at a later time if this series is accepted.

Questions
=========

This is an RFC for feedback on the design and the new socket options, in
particular:

1. I used one socket option per direction, like TLS_TX and TLS_RX. Is
   that the right form? Would one option that sets secrets for both
   directions be better?
2. When the application installs a key itself with TLS_TX or TLS_RX
   after the secrets have already been registered, the series removes
   the registered secrets (TLS_TX removes both, TLS_RX only the RX
   secret) and gives KeyUpdate back to the application. Is that right,
   or should the key change be refused while a secret is registered?
3. TLS_TX_KEY_UPDATE (patch 4) is not needed for the record limit. I can
   move it to a separate series if you prefer a smaller first step.

Signed-off-by: Martin Belanger <martin.belanger@dell.com>
---
Changes in v3:
- Patch 2: cite RFC 9846 section 7.3 for the key and IV derivation in
  the comment of the secret check. (Hannes)
- Patch 3: count a KeyUpdate over the rate limit as TlsRxRekeyError
  and log it, rate limited. The limit stays at 8 per second, the same
  as in GnuTLS. (Hannes)
- Patch 4: rename tls_tx_key_update_if_due() to
  tls_tx_maybe_update_key(). (Hannes)
- Patch 4: check for a due KeyUpdate before each record, not once per
  sendmsg(). One call can write many records, and the reply to
  update_requested must go before the next record. (Sashiko)
- Patch 4: align the control message buffer of the KeyUpdate record.
  (Sashiko)
- Patch 5: add a test where one write crosses the record limit.
- Not changed: the lock and send error points of Sashiko on patch 4
  are the same as for v1, see the v2 changes.
- The nvme-tcp fix for the stall on a KeyUpdate, "nvme-tcp: start
  error recovery when read_sock fails", is in nvme-7.4 with Cc:
  stable. (Chuck)
- Collect Reviewed-by from Hannes on patches 1, 2 and 5.
- Link to v2: https://patch.msgid.link/20261028-keyupdate-rfc-v2-0-eb5143b4c487@gmail.com

Changes in v2:
- Patch 2: check that the installed key and IV come from the
  registered secret. (Hannes)
- Patch 3: free the KeyUpdate record when its processing fails.
  (Sashiko)
- Patch 3: after a rekey, wake pollers only if a pending KeyUpdate held
  them back. (Sashiko)
- Patch 4: keep MSG_NOSIGNAL when sending a KeyUpdate. setsockopt()
  never raises SIGPIPE. (Sashiko)
- Patch 4: clear the KeyUpdate request state when the application
  installs a key with TLS_TX or TLS_RX. (Sashiko)
- Patch 5: derive the test keys from the secrets with AF_ALG. Add tests
  for the changes above.
- Not changed: if TCP fails to send the KeyUpdate after the record was
  queued, TLS_TX_KEY_UPDATE can return 0, as sendmsg() returns the
  queued length. The next call reports the error. (Sashiko)
- Link to v1: https://patch.msgid.link/20261025-keyupdate-rfc-v1-0-60b7756eccbd@gmail.com

---
Martin Belanger (5):
      tls: add HKDF-Expand-Label for the TLS 1.3 key schedule
      tls: add socket options to register the traffic secrets
      tls: update the RX key when a KeyUpdate is received
      tls: send a KeyUpdate at the record limit and on request
      selftests/tls: add KeyUpdate tests

 Documentation/networking/tls.rst   |  43 ++++
 include/net/tls.h                  |  23 ++
 include/uapi/linux/tls.h           |   3 +
 net/tls/Kconfig                    |   2 +
 net/tls/Makefile                   |   3 +-
 net/tls/tls.h                      |   5 +
 net/tls/tls_hkdf.c                 |  82 +++++++
 net/tls/tls_keyupdate.c            | 159 +++++++++++++
 net/tls/tls_main.c                 | 181 ++++++++++++++-
 net/tls/tls_sw.c                   | 207 ++++++++++++++++-
 tools/testing/selftests/net/config |   4 +
 tools/testing/selftests/net/tls.c  | 461 +++++++++++++++++++++++++++++++++++++
 12 files changed, 1164 insertions(+), 9 deletions(-)
---
base-commit: 1a2c35c49cc7c6be860038b8442b52424a8f123c
change-id: 20261025-keyupdate-rfc-94d3c7e84077

Best regards,
--  
Martin Belanger <martin.nvme.dev@gmail.com>

