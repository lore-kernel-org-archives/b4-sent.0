From: Demos Ra <demosthenes.ra@gmail.com>
Date: Sun, 25 Oct 2026 00:13:55 +0700
Subject: [PATCH net 1/2] tools: ynl-gen-c: handle classic notifications
 without a matching request
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261025-ynl-ntf-bucket-v1-1-65aef308d62c@gmail.com>
References: <20261025-ynl-ntf-bucket-v1-0-65aef308d62c@gmail.com>
In-Reply-To: <20261025-ynl-ntf-bucket-v1-0-65aef308d62c@gmail.com>
To: Donald Hunter <donald.hunter@gmail.com>, 
 Jakub Kicinski <kuba@kernel.org>, "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: Simon Horman <horms@kernel.org>, David Ahern <dsahern@kernel.org>, 
 Ido Schimmel <idosch@nvidia.com>, netdev@vger.kernel.org, 
 Demos Ra <demosthenes.ra@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792862112; l=1950;
 i=demosthenes.ra@gmail.com; s=20261019; h=from:subject:message-id;
 bh=QMYy/9g8848X9S1LCXRZkDwcKaSb1n2GG17LJZDrReg=;
 b=B7MGblZ4U2cEctXru7+Jc/y/mlJ+At6eZMUYUFfmht+6h6XQes+WI8ac3Wv3uE8boO7co+RfR
 Gy9d4TONzdmBNDKtNX377gQNXpbVNaodnxVkfP8/36ERFAU4h8qXaZ+
X-Developer-Key: i=demosthenes.ra@gmail.com; a=ed25519;
 pk=sDKS9AI9zxhWgOqkhc9EOIo6cky+anqccB3VGtDvzCc=
X-Endpoint-Received: by B4 Relay for demosthenes.ra@gmail.com/20261019 with auth_id=1235
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For classic Netlink families the notification table in the generated
user code is indexed by the message type the kernel sends. Since
commit 49398830a4aa ("tools: ynl-gen: support CRUD-like notifications
for classic Netlink") ynl-gen writes each index as the name of the
request that has the same message type, and fails if no request has
it:

  $ ./tools/net/ynl/pyynl/ynl_gen_c.py --mode user --source \
        --spec Documentation/netlink/specs/rt-nexthop.yaml
  ...
      crud_op = ri.family.req_by_value[op.rsp_value]
  KeyError: 116

rt-nexthop's newnexthopbucket-ntf is the only such notification: the
kernel sends it as RTM_NEWNEXTHOPBUCKET (116), and no request uses
that message type.

When no request matches, write the message type as a number, as
put_op_name() already does for messages whose request and reply types
differ. The generated code for every spec in the tree is unchanged.

Signed-off-by: Demos Ra <demosthenes.ra@gmail.com>
---
 tools/net/ynl/pyynl/ynl_gen_c.py | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/tools/net/ynl/pyynl/ynl_gen_c.py b/tools/net/ynl/pyynl/ynl_gen_c.py
index 4aca51396a9e..a009a842fb36 100755
--- a/tools/net/ynl/pyynl/ynl_gen_c.py
+++ b/tools/net/ynl/pyynl/ynl_gen_c.py
@@ -3409,9 +3409,11 @@ def render_scoped_consts(family, cw, scope):
 def _render_user_ntf_entry(ri, op):
     if not ri.family.is_classic():
         ri.cw.block_start(line=f"[{op.enum_name}] = ")
-    else:
+    elif op.rsp_value in ri.family.req_by_value:
         crud_op = ri.family.req_by_value[op.rsp_value]
         ri.cw.block_start(line=f"[{crud_op.enum_name}] = ")
+    else:
+        ri.cw.block_start(line=f"[{op.rsp_value}] = ")
     ri.cw.p(f".alloc_sz\t= sizeof({type_name(ri, 'event')}),")
     ri.cw.p(f".cb\t\t= {op_prefix(ri, 'reply', deref=True)}_parse,")
     ri.cw.p(f".policy\t\t= &{ri.struct['reply'].render_name}_nest,")

-- 
2.53.0

