From: Demos Ra <demosthenes.ra@gmail.com>
Subject: [PATCH net 0/2] tools: ynl: generate code for rt-nexthop bucket
 notifications
Date: Sun, 25 Oct 2026 00:13:54 +0700
Message-Id: <20261025-ynl-ntf-bucket-v1-0-65aef308d62c@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqEMBAF0atIr6chBhHxKoOLqD/aKD2SZEQR7
 25w+RZVF0UEQaS2uChglyg/zSg/BQ2z0wksYzZZY+vS2IpPXVmT5/4/LEhsPBrn+6Z2qChHW4C
 X4x1+SZGou+8HeskEN2UAAAA=
X-Change-ID: 20261024-ynl-ntf-bucket-0fe8afb86ae4
To: Donald Hunter <donald.hunter@gmail.com>, 
 Jakub Kicinski <kuba@kernel.org>, "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: Simon Horman <horms@kernel.org>, David Ahern <dsahern@kernel.org>, 
 Ido Schimmel <idosch@nvidia.com>, netdev@vger.kernel.org, 
 Demos Ra <demosthenes.ra@gmail.com>, Sashiko <sashiko-bot@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792862112; l=985;
 i=demosthenes.ra@gmail.com; s=20261019; h=from:subject:message-id;
 bh=/j7E8HCFiSHo7P2rv+DOQ25KZfpsl+WGqu8Wu2cLYgM=;
 b=4HwYBLNilcCI9mMBMV7dd85SXw3g5jEa9ByJAXCL4OjKFTFC/RNpne3cVBPoYzi6zKltz3UWK
 ztXYdU1PogwDYwuy52lrNht0XeUVgBrdaBeFZSdioELcOUuqxBo9Gh3
X-Developer-Key: i=demosthenes.ra@gmail.com; a=ed25519;
 pk=sDKS9AI9zxhWgOqkhc9EOIo6cky+anqccB3VGtDvzCc=
X-Endpoint-Received: by B4 Relay for demosthenes.ra@gmail.com/20261019 with auth_id=1235
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 457dc9fefe9a ("netlink: specs: Add a spec for nexthops in
rtnetlink") left newnexthopbucket-ntf out of the C code generation,
because ynl-gen could not write a notification table entry for it.
Sashiko pointed out that the generated library then fails at runtime
when the kernel sends that notification to a subscribed socket.

Patch 1 lets ynl-gen handle a classic notification that no request
matches. Patch 2 drops the exclusion.

457dc9fefe9a was pulled in this merge window, hence net.

---
Demos Ra (2):
      tools: ynl-gen-c: handle classic notifications without a matching request
      tools: ynl: generate code for rt-nexthop bucket notifications

 tools/net/ynl/generated/Makefile | 1 -
 tools/net/ynl/pyynl/ynl_gen_c.py | 4 +++-
 2 files changed, 3 insertions(+), 2 deletions(-)
---
base-commit: 7076f684d5132e6a6145e1da2fa74771ecd052e5
change-id: 20261024-ynl-ntf-bucket-0fe8afb86ae4

Best regards,
-- 
Demos Ra <demosthenes.ra@gmail.com>

