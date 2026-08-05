From: Junrui Luo <moonafterrain@outlook.com>
Subject: [PATCH net 0/2] ovpn: fix peer float use-after-free and key slot
 NULL deref
Date: Wed, 05 Aug 2026 21:29:35 +0800
Message-Id: <20260805-ovpn-fixes-v1-0-763f8c237fb9@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAL86c2oC/x2LQQqAIBAAvxJ7TlDJsL4SHcS22ouKhgTi31s6D
 jPToGAmLLAODTJWKhQDgxoH8LcLFwo6mEFLPUsrjYg1BXHSi0UY7dViJ2OddsBDyvgL7jcI+MD
 e+wcqScLJYQAAAA==
X-Change-ID: 20260805-ovpn-fixes-52c198458a2a
To: Antonio Quartulli <antonio@openvpn.net>, 
 Sabrina Dubroca <sd@queasysnail.net>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Junrui Luo <moonafterrain@outlook.com>, Yuhao Jiang <danisjiang@gmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1819;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=3ONLOkCCikXZjvVxIR5WZoHWXthWoxkThJGRkJtifWc=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrGKrqz3nznC0rb8yq8Hla3LLstxLLFknOe+VBMmqK
 q84xubC39lRysIgxsUgK6bIcrzg0jcL3y26W3y2JMPMYWUCGcLAxSkAE3ktzvA/ZJta7NWEVzyf
 c9atK73w2HvLnaDZ5caapxjLI/gU/MNMGRn2Xdl+dNf0C1vyUxJm7HU4tOzsoe/sHiUXgw9393F
 4ZnxjBAC5t0xf
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two independent fixes for the ovpn driver, both in lifetime handling:
one for a crypto key slot that can legitimately be empty, one for a peer
that can be re-linked into a hash table after it has been removed.

Patch 1 fixes a NULL dereference in ovpn_crypto_kill_key(). It locates
the slot holding a given key ID by reading both cs->slots[] entries and
comparing ->key_id, without checking either pointer first. An empty slot
is a normal state: the ordinary rekey sequence - install into the
secondary slot, swap, delete the retired one - leaves primary_idx at 1
with slots[0] empty, and key_id sits at offset 0, so the first
comparison faults on a read of address 0.

Patch 2 fixes a use-after-free in the peer float path.
ovpn_peer_endpoints_update() releases peer->lock to send the float
notification, then re-acquires ovpn->lock and re-links the peer into
by_transp_addr unconditionally - even if ovpn_peer_remove() unlinked it
while the lock was not held. The teardown path never unlinks hash nodes
again, so the peer ends up freed while still on the chain, and every
later datagram walks it in ovpn_peer_get_by_transp_addr(). Reproduced
under KASAN on 7.0-rc3; the splat is included in the patch.

The two patches are independent and touch different files; they can be
applied in either order.

Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
Junrui Luo (2):
      ovpn: don't deref NULL key slot in ovpn_crypto_kill_key()
      ovpn: don't re-hash a removed peer on float

 drivers/net/ovpn/crypto.c | 6 ++++--
 drivers/net/ovpn/peer.c   | 7 ++++++-
 2 files changed, 10 insertions(+), 3 deletions(-)
---
base-commit: 075b74841bd0065a3bda3440873c747938e69b68
change-id: 20260805-ovpn-fixes-52c198458a2a

Best regards,
-- 
Junrui Luo <moonafterrain@outlook.com>

