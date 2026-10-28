From: Usman Malik <usmanmalik@engineer.com>
Date: Wed, 28 Oct 2026 15:10:40 +0100
Subject: [PATCH ipsec] xfrm: use software GSO for inner tunnels without
 crypto offload
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261028-xfrm-inner-gso-v1-1-1908f0eb7313@engineer.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/yWMSwqDQBAFryK9tkEH/OUqwUUc35gOZJTuJAji3
 Z3osgqqNjKowOiWbaT4ickcE5R5Rv75iBNYxsTkCleXhWt4DfpmiRHKk80c2qGrao+2GytK0aI
 Isp7DO8li8NRf2r7DC/7zn9G+H1sOCA55AAAA
X-Change-ID: 20261027-xfrm-inner-gso-f8b956ce89d5
To: Steffen Klassert <steffen.klassert@secunet.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Cosmin Ratiu <cratiu@nvidia.com>, Leon Romanovsky <leon@kernel.org>, 
 stable@vger.kernel.org, Usman Malik <usmanmalik@engineer.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=8165;
 i=usmanmalik@engineer.com; h=from:subject:message-id;
 bh=mTypX1zNQGDPGclAGpw+WOJIpIe4eb8zZnLMHI6cuAM=;
 b=owEBbQKS/ZANAwAKATUQMBv7n6GlAcsmYgBq4gNKFIjTrzQPmHyXaPovwFr2zNieUmeCZWrvv
 i7jYzwhpLWJAjMEAAEKAB0WIQTkhh6bEhkO248PEok1EDAb+5+hpQUCauIDSgAKCRA1EDAb+5+h
 pfK9EACbjA4MOdXK6k6YcsMwM2+JE0Ur2DJOHVwEa83y1wKMkT0zAgOCyRL15jOurpeejtVIqBh
 o0AwSv6FJLjeIHOfCgBaRwdmnAdscUqa0YeBHaKqr9bkObfaUNSPMVBtSuagf/TiLdFit9lnw5P
 ESMsqHzbOGu8Lyb0wytmjb7FQ0Fw8qjQJJftewhgR32BR3dOQPYtlfRALBFJZHvWuWPrOHDepTI
 Qmj2k2zNwrxc86L+k7X4X9tj/ovy3bilgs93/zb84qamt2Fm3xJybMuj23S072zHJHoN7VDbBsT
 WUpgEylLN0utsqBvwQq4TKRbb6lU7UBif1hA+8M53JJcb6DDGDuLuYMga16Kv2/0Opcj5OJ+6Vb
 MthGyzXC38fFO6EsrjXclDgAujvAbG0X88JwNPA28Q0hYYNKAegtx+FgX+TFNa27THe2q/k87OR
 4B354bvoZ4IRNuyM/Yr0FoZ6xeiEUv224kNsTfamfrfu+sfvSohIqXZ17cXOa3ImqpkAntyUCkN
 /jrL/PuA8RgAm+5c6FoGMjK4Oxa0l2xal00+tx4HhRu8S4Eo4HvD1OG/z39QZHeJ3z9pns3Wcw2
 xV3dE9wAgOWqHBOCYfCqgpXAOxTkKSZCiY9NvAXn3Q1ljvJ1kZ5E0/j3hn9MMOyLrVbnKtKGeuh
 mGY+PWJah3AOtNg==
X-Developer-Key: i=usmanmalik@engineer.com; a=openpgp;
 fpr=E4861E9B12190EDB8F0F12893510301BFB9FA1A5
X-Endpoint-Received: by B4 Relay for usmanmalik@engineer.com/default with auth_id=1336
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 0aae2867aa60 ("xfrm_output: Force software GSO only in tunnel
mode") limits the software GSO of packets with skb->inner_protocol set
to tunnel mode. Its message says that packets with the crypto in
software still get software GSO in the else branch. That holds only
while no ESP GSO handler is registered. With esp4_offload or
esp6_offload loaded when the SA is created, x->type_offload is set and
xfrm_dev_offload_ok() returns true for an SA without an offload device.
A transport-mode SA with software crypto then sends such a packet down
the SKB_GSO_ESP path.

That path does not handle an inner IP tunnel. For an ipip or ip6tnl
packet, xfrm{4,6}_transport_gso_segment() pass the packet to
inet_gso_segment(), which leaves the transport header of each segment at
the inner TCP header. __xfrm_transport_prep() expects it right after the
ESP header and IV, so esp_xmit() and esp6_xmit() write the ESP header at
offset 4 of the inner IPv4 header and encrypt from the TCP header. The
first 4 bytes of the inner IPv4 header go out in clear, the receiver
drops the segment with XfrmInStateProtoError, and bulk TCP through the
tunnel falls to tens of Mbit/s. The v6.13 release does not show this,
v6.14 does, and so do the stable kernels that carry 0aae2867aa60
(measured on 5.4.293, 5.15.223 and 6.1.190).

Use software GSO for packets with skb->inner_protocol set when the SA
has no offload device, as before 0aae2867aa60. An SA with crypto offload
on a device keeps the SKB_GSO_ESP path in transport mode, which is what
that commit is for.

The transport GSO handlers themselves still do not handle an inner IP
tunnel. An SA with crypto offload that falls back to software
segmentation in validate_xmit_xfrm() takes the same path. That is a
separate change in xfrm{4,6}_transport_gso_segment() and is not part of
this patch, which restores the behaviour before 0aae2867aa60 for SAs
without an offload device.

Tested on v7.3 in a VM with two network namespaces on a veth, a
rfc4106(gcm(aes)) SA between the outer addresses, esp4_offload and
esp6_offload loaded, TSO on and 3 MB of bulk TCP per run, plus a 4 s
iperf3 run. Both test kernels also carried a local esp6_xmit() change
that builds the IV from the sequence number read before the increment,
as esp_xmit() does, so that the capture analysis could check nonces as
well. That change does not touch the path changed here. The sender
capture was decrypted with the SA keys. Without this patch, two ip6tnl
runs had 22 and 24 malformed packets at 36 Mbit/s, two ipip runs 18 and
36 at about 50 Mbit/s, and iperf3 over ip6tnl gave 195 Mbit/s with
XfrmInStateProtoError +358. With it, every ESP packet decrypts at offset
0, no inner header byte is in clear, XfrmInStateProtoError stays at +0,
the same runs reach 1.0 to 2.4 Gbit/s and iperf3 gives 2.62 Gbit/s. A
function profile shows these packets now go through xfrm_output_gso(),
while plain TCP over the same SA still goes through esp6_gso_segment().
vxlan and geneve over a transport-mode and a tunnel-mode SA were clean
before and after. In transport mode they now take the software GSO path
as well. Hardware ESP offload was not tested, as no such NIC was
available, and neither were BEET and IP-TFS mode, nor GRE over a
transport-mode SA, which this change also moves to software GSO.

The bug was found while measuring bulk TCP throughput through an ip6tnl
tunnel over a transport-mode ESP SA.

Fixes: 0aae2867aa60 ("xfrm_output: Force software GSO only in tunnel mode")
Cc: stable@vger.kernel.org
Assisted-by: LLM
Signed-off-by: Usman Malik <usmanmalik@engineer.com>
---
The malformed layout is visible without keys. On the sender,

  tcpdump -ni va 'ip6 proto 50 and ip6[56:2] = 0x4500 and ip6[60:4] = 0x1001'

lists exactly the malformed packets (22 of 22 in one v7.3 run, 0 with
this patch). For ipip the offsets are ip[36:2] and ip[40:4].

Reproducer for the ip6tnl case. It prints the sender rate and the
receiver's XfrmInStateProtoError delta with TSO on and off. Run as root
with iproute2, ethtool and iperf3. Rerun after "ip netns del a" and "ip
netns del b" if it stops early. On a plain v7.3 it printed 107 Mbit/s
and +366 with TSO on, 2.72 Gbit/s and +0 with TSO off. With this patch
it printed 2.62 Gbit/s and +0 with TSO on.

  #!/bin/sh
  set -e
  modprobe -a esp4_offload esp6_offload
  A="ip netns exec a"; B="ip netns exec b"
  ip netns add a; ip netns add b
  ip link add va type veth peer name vb
  ip link set va netns a; ip link set vb netns b
  $A ip link set lo up; $B ip link set lo up
  $A ip link set dev va mtu 9000 up; $B ip link set dev vb mtu 9000 up
  $A ip -6 addr add fd00:a::1/64 dev va nodad
  $B ip -6 addr add fd00:a::2/64 dev vb nodad
  $A ip -6 tunnel add t mode any local fd00:a::1 remote fd00:a::2 \
     encaplimit none hoplimit 64
  $B ip -6 tunnel add t mode any local fd00:a::2 remote fd00:a::1 \
     encaplimit none hoplimit 64
  $A ip link set dev t mtu 8926 up; $B ip link set dev t mtu 8926 up
  $A ip addr add 10.9.0.1/30 dev t; $B ip addr add 10.9.0.2/30 dev t
  key() { head -c 36 /dev/urandom | od -An -tx1 | tr -d ' \n'; }
  K1=0x$(key); K2=0x$(key)
  for n in a b; do
    ip netns exec $n ip xfrm state add src fd00:a::1 dst fd00:a::2 \
      proto esp spi 0x1001 reqid 1 mode transport replay-window 128 \
      aead 'rfc4106(gcm(aes))' $K1 128
    ip netns exec $n ip xfrm state add src fd00:a::2 dst fd00:a::1 \
      proto esp spi 0x1002 reqid 2 mode transport replay-window 128 \
      aead 'rfc4106(gcm(aes))' $K2 128
  done
  $A ip xfrm policy add src fd00:a::1/128 dst fd00:a::2/128 dir out \
     tmpl proto esp reqid 1 mode transport
  $A ip xfrm policy add src fd00:a::2/128 dst fd00:a::1/128 dir in \
     tmpl proto esp reqid 2 mode transport
  $B ip xfrm policy add src fd00:a::2/128 dst fd00:a::1/128 dir out \
     tmpl proto esp reqid 2 mode transport
  $B ip xfrm policy add src fd00:a::1/128 dst fd00:a::2/128 dir in \
     tmpl proto esp reqid 1 mode transport
  $B iperf3 -s -D
  err() { $B awk '$1=="XfrmInStateProtoError"{print $2}' \
          /proc/net/xfrm_stat; }
  run() { e0=$(err)
    $A iperf3 -c 10.9.0.2 -t 4 | awk '/sender/{print $7,$8,"retr",$9}'
    echo "XfrmInStateProtoError +$(( $(err) - e0 ))"; }
  echo "tso on";  run
  $A ethtool -K t tso off
  echo "tso off"; run
  pkill iperf3; ip netns del a; ip netns del b

The esp6_xmit() change in the test kernels does what Jeremy Jean's
"[PATCH ipsec 1/7] xfrm: esp6: use the current sequence number for the
IV" does, except that esp.seqno is built after the seq.hi update, as in
esp_xmit(). The two differ only at a seq.low wrap. This patch was not
run on a v7.3 without that change.
https://lore.kernel.org/netdev/20260930144523.435271-3-Jeremy.Jean@oss.cyber.gouv.fr/

Jeremy Jean's "[PATCH ipsec 6/7] xfrm: segment untrusted GSO packets
before sequence allocation", not applied yet, changes the same condition
in xfrm_output() and moves the skb->encapsulation line above it, so
whichever lands second needs a rebase. 6/7 adds SKB_GSO_DODGY packets to
the software GSO case. The packets here come from a local TCP socket and
are not DODGY, so 6/7 does not cover this case.
https://lore.kernel.org/netdev/20260930144523.435271-8-Jeremy.Jean@oss.cyber.gouv.fr/
---
 net/xfrm/xfrm_output.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/net/xfrm/xfrm_output.c b/net/xfrm/xfrm_output.c
index e305ba32e..c370d28a8 100644
--- a/net/xfrm/xfrm_output.c
+++ b/net/xfrm/xfrm_output.c
@@ -808,7 +808,8 @@ int xfrm_output(struct sock *sk, struct sk_buff *skb)
 		skb->encapsulation = 1;
 
 		if (skb_is_gso(skb)) {
-			if (skb->inner_protocol && x->props.mode == XFRM_MODE_TUNNEL)
+			if (skb->inner_protocol &&
+			    (x->props.mode == XFRM_MODE_TUNNEL || !x->xso.dev))
 				return xfrm_output_gso(net, sk, skb);
 
 			skb_shinfo(skb)->gso_type |= SKB_GSO_ESP;

---
base-commit: 835912998ca54a76b5c57f8c8459a86b1b45de40
change-id: 20261027-xfrm-inner-gso-f8b956ce89d5

Best regards,
--  
Usman Malik <usmanmalik@engineer.com>

