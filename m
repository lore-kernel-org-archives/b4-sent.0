From: Vincent Jardin <vjardin@free.fr>
Date: Sat, 28 Nov 2026 01:41:34 +0100
Subject: [PATCH net-next v2 2/5] netlink: specs: rt-link: add the lisp link
 type
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-for-upstream-lisp-v1-v2-2-68e8649c3ed2@free.fr>
References: <20261128-for-upstream-lisp-v1-v2-0-68e8649c3ed2@free.fr>
In-Reply-To: <20261128-for-upstream-lisp-v1-v2-0-68e8649c3ed2@free.fr>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Vincent Jardin <vjardin@free.fr>, Donald Hunter <donald.hunter@gmail.com>, 
 Nicolas Dichtel <nicolas.dichtel@6wind.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Shuah Khan <shuah@kernel.org>
Cc: linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 =?utf-8?q?Asbj=C3=B8rn_Sloth_T=C3=B8nnesen?= <ast@fiberby.net>, 
 Danielle Ratson <danieller@nvidia.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795826502; l=1837;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=/PetGQdaL3uGENm+cDP7KlWMMRtUNnnGqpSboQO7TLs=;
 b=FVkrzQEf9ZBeuUfbrMMS5YS3BhY5JO7XpAzuShXu3dALsVvpupce6vMPIlcY1RoHXjFuHW6bF
 jQtuMRO+9W+DH+4OIIYH8XSC1Y9Mdlt6YEEbXIftrJiPM+lZ3sw9rJF
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the attributes of the LISP devices.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 Documentation/netlink/specs/rt-link.yaml | 35 ++++++++++++++++++++++++++++++++
 1 file changed, 35 insertions(+)

diff --git a/Documentation/netlink/specs/rt-link.yaml b/Documentation/netlink/specs/rt-link.yaml
index 81b58633911d6..30a8e36c212f4 100644
--- a/Documentation/netlink/specs/rt-link.yaml
+++ b/Documentation/netlink/specs/rt-link.yaml
@@ -2368,6 +2368,38 @@ attribute-sets:
         name: mode
         type: u8
         enum: ovpn-mode
+  -
+    name: linkinfo-lisp-attrs
+    name-prefix: ifla-lisp-
+    attributes:
+      -
+        name: id
+        type: u32
+        doc: |
+          Instance ID of the packets that the device sends and receives,
+          24 bits.
+      -
+        name: collect-metadata
+        type: flag
+        doc: |
+          The device serves the instance IDs that have no device: it takes
+          the instance ID of a packet from its tunnel metadata, and
+          provides it when it receives.
+      -
+        name: local
+        type: u32
+        byte-order: big-endian
+        display-hint: ipv4
+        doc: |
+          Source address of the packets sent to an IPv4 RLOC, when the
+          tunnel metadata do not give it.
+      -
+        name: local6
+        type: binary
+        display-hint: ipv6
+        doc: |
+          Source address of the packets sent to an IPv6 RLOC, when the
+          tunnel metadata do not give it.
 
 sub-messages:
   -
@@ -2427,6 +2459,9 @@ sub-messages:
       -
         value: ovpn
         attribute-set: linkinfo-ovpn-attrs
+      -
+        value: lisp
+        attribute-set: linkinfo-lisp-attrs
   -
     name: linkinfo-member-data-msg
     formats:

-- 
2.43.0

